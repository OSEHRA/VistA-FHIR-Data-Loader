SYNFMED2	;ven/gpl - fhir loader utilities ; 2/20/18 4:11am
	;;1.0;fhirloader;;oct 19, 2017;Build 10
	;
	; Authored by George P. Lilly 2017-2018
	;
	q
	;
importMeds(rtn,ien,args)	; entry point for loading Medications for a patient
	; calls the intake Medications web service directly
	;
	n grtn
	n root s root=$$setroot^%wd("fhir-intake")
	d wsIntakeMeds(.args,,.grtn,ien)
	i $d(grtn) d  ; something was returned
	. k @root@(ien,"load","meds")
	. m @root@(ien,"load","meds")=grtn("meds")
	. if $g(args("debug"))=1 m rtn=grtn
	s rtn("conditionsStatus","status")=$g(grtn("status","status"))
	s rtn("conditionsStatus","loaded")=$g(grtn("status","loaded"))
	s rtn("conditionsStatus","errors")=$g(grtn("status","errors"))
	;b
	;
	;
	q
	;
wsIntakeMeds(args,body,result,ien)	; web service entry (post)
	; for intake of one or more Meds. input are fhir resources
	; result is json and summarizes what was done
	; args include patientId
	; ien is specified for internal calls, where the json is already in a graph
	n jtmp,json,jrslt,eval
	;i $g(ien)'="" if $$loadStatus("meds","",ien)=1 d  q  ;
	;. s result("medstatus","status")="alreadyLoaded"
	i $g(ien)'="" d  ; internal call
	. d getIntakeFhir^SYNFHIR("json",,"MedicationRequest",ien,1)
	e  d  ; 
	. merge jtmp=BODY
	. do DECODE^VPRJSON("jtmp","json")
	;
	;i '$d(json) d getRandomMeds(.json)
	;
	i '$d(json) q  ;
	m ^gpl("gjson")=json
	;
	; determine the patient
	;
	n dfn,eval
	if $g(ien)'="" d  ;
	. s dfn=$$ien2dfn^SYNFUTL(ien) ; look up dfn in the graph
	else  d  ;
	. s dfn=$g(args("dfn"))
	. i dfn="" d  ;
	. . n icn s icn=$g(args("icn"))
	. . i icn'="" s dfn=$$icn2dfn^SYNFUTL(icn)
	i $g(dfn)="" do  quit  ; need the patient
	. s result("meds",1,"log",1)="Error, patient not found.. terminating"
	;
	new zi s zi=0
	for  set zi=$order(json("entry",zi)) quit:+zi=0  do  ;
	. ;
	. ; define a place to log the processing of this entry
	. ;
	. new jlog set jlog=$name(eval("meds",zi))
	. ;
	. ; insure that the resourceType is MedsIntolerance
	. ;
	. new type set type=$get(json("entry",zi,"resource","resourceType"))
	. if type'="MedicationRequest" do  quit  ;
	. . set eval("meds",zi,"vars","resourceType")=type
	. . do log(jlog,"Resource type not MedicationReference, skipping entry")
	. set eval("meds",zi,"vars","resourceType")=type
	. ;
	. ; see if this resource has already been loaded. if so, skip it
	. ;
	. if $g(ien)'="" if $$loadStatus("meds",zi,ien)=1 do  quit  ;
	. . d log(jlog,"Meds already loaded, skipping")
	. ;
	. ; determine Meds rxnorm code, coding system, and display text
	. ;
	. n med,rxnorm,codesystem,drugname
	. d getEntry^SYNFHIR("med",ien,zi-1) ; meds are in the previous entry
	. n gmed s gmed=$na(med("entry",zi-1,"resource"))
	. q:$g(@gmed@("resourceType"))'="Medication"
	. s rxnorm=$g(@gmed@("code","coding",1,"code"))
	. q:rxnorm=""
	. s drugname=$g(@gmed@("code","coding",1,"display"))
	. s codesystem=$g(@gmed@("code","coding",1,"system"))
	. s codesystem=$re($p($re(codesystem),"/"))
	. ;
	. do log(jlog,"rxnorm code is: "_rxnorm)
	. set eval("meds",zi,"vars","rxnorm")=rxnorm
	. do log(jlog,"drug name is: "_drugname)
	. set eval("meds",zi,"vars","drugname")=drugname
	. ;
	. ;
	. do log(jlog,"code system is: "_codesystem)
	. set eval("meds",zi,"vars","codeSystem")=codesystem
	. ;
	. ; determine the order date and time
	. ;
	. new orderdate set orderdate=$get(json("entry",zi,"resource","authoredOn"))
	. do log(jlog,"orderdateTime is: "_orderdate)
	. set eval("meds",zi,"vars","orderdateTime")=orderdate
	. new fmOrderDateTime s fmOrderDateTime=$$fhirTfm^SYNFUTL(orderdate)
	. d log(jlog,"fileman orderdateTime is: "_fmOrderDateTime)
	. set eval("meds",zi,"vars","fmOrderdateTime")=fmOrderDateTime ;
	. new hl7OrderdateTime s hl7OrderdateTime=$$fhirThl7^SYNFUTL(orderdate)
	. d log(jlog,"hl7 orderdateTime is: "_hl7OrderdateTime)
	. set eval("meds",zi,"vars","hl7OrderdateTime")=hl7OrderdateTime ;
	. ;
	. ; determine clinical status (active vs inactive)
	. ;
	. n clinicalstatus set clinicalstatus=$get(json("entry",zi,"resource","verificationStatus"))
	. ;
	. ;
	. ; set up to call the data loader
	. ;
	. ;
	. if $g(args("load"))=1 d  ; only load if told to
	. . if $g(ien)'="" if $$loadStatus("meds",zi,ien)=1 do  quit  ;
	. . . d log(jlog,"Meds already loaded, skipping")
	. . d log(jlog,"Calling WRITERXRXN^SYNFMED to add meds")
	. . D WRITERXRXN^SYNFMED(dfn,rxnorm,fmOrderDateTime)
	. . ;m eval("meds",zi,"status")=RESTA
	. . d log(jlog,"Medication loaded: "_rxnorm_" "_drugname)
	. . do  ;
	. . . s eval("status","loaded")=$g(eval("status","loaded"))+1
	. . . s eval("meds",zi,"status","loadstatus")="loaded"
	. . ;else  d  ;
	. . ;. s eval("status","errors")=$g(eval("status","errors"))+1
	. . ;. s eval("meds",zi,"status","loadstatus")="notLoaded"
	. . ;. s eval("meds",zi,"status","loadMessage")=$g(RETSTA)
	. . n root s root=$$setroot^%wd("fhir-intake")
	. . k @root@(ien,"load","meds",zi)
	. . m @root@(ien,"load","meds",zi)=eval("meds",zi)
	;
	if $get(args("debug"))=1 do  ;
	. m jrslt("source")=json
	. m jrslt("args")=args
	. m jrslt("eval")=eval
	m jrslt("medsStatus")=eval("medsStatus")
	set jrslt("result","status")="ok"
	set jrslt("result","loaded")=$g(eval("status","loaded"))
	i $g(ien)'="" d  ; called internally
	. m result=eval
	. m result("status")=jrslt("result")
	. m result("dfn")=dfn
	. m result("ien")=ien
	. ;b
	e  d  ;
	. d ENCODE^VPRJSON("jrslt","result")
	. set HTTPRSP("mime")="application/json" 
	q
	;
log(ary,txt)	; adds a text line to @ary@("log")
	s @ary@("log",$o(@ary@("log",""),-1)+1)=$g(txt)
	w:$G(DEBUG) !,"      ",$G(txt)
	q
	;
loadStatus(typ,zx,zien)	; extrinsic return 1 if resource was loaded
	n root s root=$$setroot^%wd("fhir-intake")
	n rt s rt=0
	i $g(zx)="" i $d(@root@(zien,"load",typ)) s rt=1 q rt
	i $get(@root@(zien,"load",typ,zx,"status","loadstatus"))="loaded" s rt=1
	q rt
	;
testall	; run the meds import on all imported patients
	new root s root=$$setroot^%wd("fhir-intake")
	new indx s indx=$na(@root@("POS","DFN"))
	n dfn,ien,filter,reslt
	s dfn=0
	f  s dfn=$o(@indx@(dfn)) q:+dfn=0  d  ;
	. s ien=$o(@indx@(dfn,""))
	. q:ien=""
	. s filter("dfn")=dfn
	. k reslt
	. d wsIntakeMeds(.filter,,.reslt,ien)
	q
	;
testone(reslt,doload)	; run the meds import on one imported patient
	new root s root=$$setroot^%wd("fhir-intake")
	new indx s indx=$na(@root@("POS","DFN"))
	n dfn,ien,filter
	n done s done=0
	s dfn=0
	f  s dfn=$o(@indx@(dfn)) q:+dfn=0  q:done   d  ;
	. s ien=$o(@indx@(dfn,""))
	. q:ien=""
	. q:$d(@root@(ien,"load","meds"))
	. s filter("dfn")=dfn
	. s filter("debug")=1
	. i $g(doload)=1 s filter("load")=1
	. k reslt
	. d wsIntakeMeds(.filter,,.reslt,ien)
	. s done=1
	q
	;
getRandomMeds(ary) ; make a web service call to get random allergies
 n srvr
 s srvr="http://postfhir.vistaplex.org:9080/"
 i srvr["postfhir.vistaplex.org" s srvr="http://138.197.70.229:9080/"
 i $g(^%WURL)["http://postfhir.vistaplex.org:9080" d  q  ;
 . s srvr="localhost:9080/"
 . n url
 . s url=srvr_"randommeds"
 . n ok,r1
 . s ok=$$%^%WC(.r1,"GET",url)
 . i '$d(r1) q  ;
 . d DECODE^VPRJSON("r1","ary")
 n url
 s url=srvr_"randommeds"
 n ret,json,jtmp
 s ret=$$GETURL^XTHC10(url,,"jtmp")
 d assemble^SYNFPUL("jtmp","json")
 i '$d(json) q  ;
 d DECODE^VPRJSON("json","ary")
 q
 ;
medsum ; search all loaded patients and catelog the procedure codes
 n root,json,ien,table
 s root=$$setroot^%wd("fhir-intake")
 s ien=0
 f  s ien=$o(@root@(ien)) q:+ien=0  d  ;
 . k json
 . d getIntakeFhir^SYNFHIR("json",,"MedicationRequest",ien,1)
 . n cde,txt,rien
 . s rien=0
 . f  s rien=$o(json("entry",rien)) q:+rien=0  d  ;
 . . n med
 . . d getEntry^SYNFHIR("med",ien,rien-1) ; meds are in the previous entry
 . . n gmed s gmed=$na(med("entry",rien-1,"resource"))
 . . q:$g(@gmed@("resourceType"))'="Medication"
 . . s cde=$g(@gmed@("code","coding",1,"code"))
 . . q:cde=""
 . . s txt=$g(@gmed@("code","coding",1,"display"))
 . . n sys s sys=$g(@gmed@("code","coding",1,"system"))
 . . s sys=$re($p($re(sys),"/"))
 . . s txt=txt_" - "_sys
 . . i '$d(table(cde_" "_txt)) s table(cde_" "_txt)=1 q  ;
 . . s table(cde_" "_txt)=$g(table(cde_" "_txt))+1
 zwr table
 q
 ;
