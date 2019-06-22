SYNDHP91 ;DHP/fjf -  Write  to VistA ;2019-02-07  3:35 PM
 ;;0.2;VISTA SYN DATA LOADER;;Feb 07, 2019;Build 3
 ;
 ;
 QUIT
 ;
 ;*//Input:
 ; a. Classification
 ; b. Activities SNOMED CT
 ; c. Goals - text and ptr to PL
 ; Status - fhir CODE
 ; Date
 ; 1.	Use data2pce to ingest careplans, activities & goals
 ; a.	Encounter
 ; b.	CarePlan points to encounter and the goals
 ; i.	V standard codes (SNOMED CT) - classification
 ; c.	Goals - has text goal - points to condition/problems (reason for goal)
 ; i.	Use Healthfactors
 ; ii.	Create goals HF category - config - add to configuration utility this will be for problem
 ; iii.	For each goal create a health factor if doesn't already exist (laygo) (text from c above)
 ; iv.	Code which references the problem list
 ; v.	Entire text of goal goes in comment and say that goal addresses this problem  -> add SCT + desc code in there too
 ; d.
 ; Signature:
 ;Visit IEN
 ;Goals (array) text & code <- problem list code (SNOMED CT & or ICD)
 ;Activities (array) SNOMED code^status
 ;Classification SNOMED CT code
 ;CarePlan Status from FHIR set
 ;Generate TIU note for careplan and associate with encounter.
 ;//*
 ; HF for cat for careplan
 ; HF for careplan (use healthfactor manager
 ; HF for activity
 ; pass to DATA2PCE
 ;
 ;
 ; -------- Create Care Plan for Patient
 ;
CPLUPDT(RETSTA,DHPPAT,DHPVST,DHPCAT,DHPACT,DHPGOL,DHPSCT,DHPSDT,DHPEDT) ;  update
 ;
 ; Input:
 ;   DHPPAT   - Patient ICN
 ;   DHPVST   - Visit ID
 ;   DHPCAT   - Category ID (SCT code. text, and FHIR status - active, completed, etc)
 ;   DHPACT   - List of Activities (SCT code, text, and FHIR status - in-progress, etc)
 ;   DHPGOL   - List of Goals
 ;   DHPSCT   - Reason for CarePlan (SCT code) (ignore for time being)
 ;   DHPSDT   - CarePlan Period start
 ;   DHPEDT   - CarePlan period end
 ;
 ;
 ; Output:   RETSTA
 ;  1 - success
 ; -1 - failure -1^message
 ;
 I '$D(^DPT("AFICN",DHPPAT)) S RETSTA="-1^Patient not recognised" Q
 ;
 ;I $G(DHPSCT)="" S RETSTA="-1^SNOMED CT code is required" Q
 I $G(DHPVST)="" S RETSTA="-1^Visit IEN is required" Q
 I '$D(^AUPNVSIT(DHPVST)) S RETSTA="-1^Visit not found" Q
 ;
 ;
 ;
 S U="^",T="~"
 ;
 S DHPGOL=$G(DHPGOL)
 S DHPDCT=$G(DHPSCT)
 S DHPSDT=$P($$HL7TFM^XLFDT(DHPSDT),".",1)
 S DHPEDT=$P($$HL7TFM^XLFDT(DHPEDT),".",1)
 ;
 S VISIT=DHPVST
 S PATIEN=$O(^DPT("AFICN",DHPPAT,""),-1)
 S PACKAGE=$$FIND1^DIC(9.4,,"","?")
 S SOURCE="DHP DATA INGEST"
 S USER=$$DUZ^SYNDHP69
 S ERRDISP=""
 I $G(DEBUG)=1 S ERRDISP=1
 S CATCD=$P(DHPCAT,T)
 S CATTX=$P(DHPCAT,T,2)
 S CATST=$P(DHPCAT,T,3)
 ; Call HF manager and retrieve HF for careplan category data or
 ;   add category HF and return data if it doesn't already exist
 S CATDAT=$$HFCPCAT^SYNFHF(CATCD,CATTX)
 ; Call HF manager and retrieve HF for careplan
 ;   add careplan HF if it doesn't already exist
 S HFCAP=$$HFCP^SYNFHF(CATCD,CATTX,CATDAT)
 ; create encounter array
 K ENCDATA
 ;
 ; parse action string
 ;
 S ENCDATA("HEALTH FACTOR",1,"HEALTH FACTOR")=+HFCAP
 S ENCDATA("HEALTH FACTOR",1,"EVENT D/T")=DHPSDT
 S ENCDATA("HEALTH FACTOR",1,"COMMENT")="Start: "_DHPSDT_" End: "_DHPEDT_" Status: "_CATST
 F I=1:1:$L(DHPACT,U) D
 .S ACTS=$P(DHPACT,U,I)
 .S ACTSCT=$P(ACTS,T)
 .S ACTTXT=$P(ACTS,T,2)
 .S ACTSTA=$P(ACTS,T,3)
 .S HFACT=$$HFACT^SYNFHF(ACTSCT,ACTTXT,+CATDAT)
 .S ENCDATA("HEALTH FACTOR",I+1,"HEALTH FACTOR")=+HFACT
 .S ENCDATA("HEALTH FACTOR",I+1,"EVENT D/T")=DHPSDT
 .S ENCDATA("HEALTH FACTOR",I+1,"COMMENT")="Start: "_DHPSDT_" End: "_DHPEDT
 ;
 S RETSTA=$$DATA2PCE^PXAI("ENCDATA",PACKAGE,SOURCE,.VISIT,USER,$G(ERRDISP),.ZZERR,$G(PPEDIT),.ZZERDESC,.ACCOUNT)
 D EVARS
 M RETSTA=ENCDATA
 Q
 ;
 ;
T1 ;
 ;
 D VARS
 D CPLUPDT(.ZXC,DHPPAT,DHPVST,DHPCAT,DHPACT,DHPGOL,DHPSCT,DHPSDT,DHPEDT)
 Q
 ;
 ;s q=""""
 ;
 ;w q
 ;
 ;F I=1:1:7 s @$p(a(I),q,8)=$p(a(I),"=",2)
 ;
 ;a(1)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPACT")=409002~Food allergy diet~in-progress^58332002~Allergy education~in-progress"
 ;a(2)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPCAT")=326051000000105~Self care~active"
 ;a(3)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPEDT")="
 ;a(4)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPPAT")=1435855215V947437"
 ;a(5)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPSCT")="
 ;a(6)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPSDT")=2760829"
 ;a(7)="^SYNGRAF(17.040801,1,1227,"load","careplan",12,"parms","DHPVST")=34818"
 ;
VARS ;
 S DHPACT="409002~Food allergy diet~in-progress^58332002~Allergy education~in-progress"
 S DHPCAT="326051000000105~Self care~active"
 S DHPEDT=""
 S DHPPAT="1435855215V947437"
 S DHPSCT=""
 S DHPSDT="19760829"
 S DHPVST="34818"
 S DHPGOL=""
 Q
EVARS ;
 S ENCDATA("IVARS","DHPACT")=DHPACT
 S ENCDATA("IVARS","DHPCAT")=DHPCAT
 S ENCDATA("IVARS","DHPEDT")=DHPEDT
 S ENCDATA("IVARS","DHPPAT")=DHPPAT
 S ENCDATA("IVARS","DHPSCT")=DHPSCT
 S ENCDATA("IVARS","DHPSDT")=DHPSDT
 S ENCDATA("IVARS","DHPVST")=DHPVST
 S ENCDATA("IVARS","DHPGOL")=DHPGOL
 Q
