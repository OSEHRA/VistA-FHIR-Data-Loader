SYNFHIR	;ven/gpl - fhir loader utilities ; 2/24/18 8:23pm
	;;1.0;fhirloader;;oct 19, 2017;Build 12
	;
	; Authored by George P. Lilly 2017-2018
	;
	q
	;
wsPostFHIR(ARGS,BODY,RESULT)	; recieve from addpatient
	;
	s U="^"
	;
	new json,ien,root,gr,id,return
	set root=$$setroot^%wd("fhir-intake")
	set id=$get(ARGS("id"))
	;
	set ien=$order(@root@(" "),-1)+1
	set gr=$name(@root@(ien,"json"))
	merge json=BODY
	do DECODE^VPRJSON("json",gr)
	do indexFhir(ien)
	;
	if id'="" do  ;
	. set @root@("B",id,ien)=""
	else  do  ;
	. ;
	;
	if $get(ARGS("returngraph"))=1 do  ;
	. merge return("graph")=@root@(ien,"graph")
	set return("status")="ok"
	set return("id")=id
	set return("ien")=ien
	;
	do importPatient^SYNFPAT(.return,ien)
	;
	new rdfn set rdfn=$get(return("dfn"))
	if rdfn'="" set @root@("DFN",rdfn,ien)=""
	;
	if rdfn'="" do  ; patient creation was successful
	. if $g(ARGS("load"))="" s ARGS("load")=1
	. do importVitals^SYNFVIT(.return,ien,.ARGS)
	. do importEncounters^SYNFENC(.return,ien,.ARGS)
	. do importImmu^SYNFIMM(.return,ien,.ARGS)
	. do importConditions^SYNFPRB(.return,ien,.ARGS)
	. do importAllergies^SYNFALG(.return,ien,.ARGS)
	. do importAppointments^SYNFAPT(.return,ien,.ARGS)
	;
	do ENCODE^VPRJSON("return","RESULT")
	set HTTPRSP("mime")="application/json"
	;
	quit 1
	;
indexFhir(ien)	; generate indexes for parsed fhir json
	;
	new root set root=$$setroot^%wd("fhir-intake")
	if $get(ien)="" quit  ;
	;
	new jroot set jroot=$name(@root@(ien,"json","entry")) ; root of the json
	if '$data(@jroot) quit  ; can't find the json to index
	;
	new jindex set jindex=$name(@root@(ien)) ; root of the index
	d clearIndexes(jindex)
	;
	new %wi s %wi=0
	for  set %wi=$order(@jroot@(%wi)) quit:+%wi=0  do  ;
	. new type
	. set type=$get(@jroot@(%wi,"resource","resourceType"))
	. if type="" do  quit  ;
	. . w !,"error resource type not found ien= ",ien," entry= ",%wi
	. set @jindex@("type",type,%wi)=""
	. d triples(jindex,$na(@jroot@(%wi)),%wi)
	quit
	;
triples(index,ary,%wi)	; index and array are passed by name
	;
	i type="Patient" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	i type="Encounter" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	. n sdate s sdate=$g(@ary@("resource","period","start")) q:sdate=""
	. n hl7date s hl7date=$$fhirThl7^SYNFUTL(sdate)
	. d setIndex(index,purl,"dateTime",sdate)
	. d setIndex(index,purl,"hl7dateTime",hl7date)
	. n class s class=$g(@ary@("resource","class","code")) q:class=""
	. d setIndex(index,purl,"class",class)
	i type="Condition" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	. n enc s enc=$g(@ary@("resource","context","reference")) q:enc=""
	. d setIndex(index,purl,"encounterReference",enc)
	. n pat s pat=$g(@ary@("resource","subject","reference")) q:pat=""
	. d setIndex(index,purl,"patientReference",pat)
	i type="Observation" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	. n enc s enc=$g(@ary@("resource","context","reference")) q:enc=""
	. d setIndex(index,purl,"encounterReference",enc)
	. n pat s pat=$g(@ary@("resource","subject","reference")) q:pat=""
	. d setIndex(index,purl,"patientReference",pat)
	i type="Medication" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	i type="medicationReference" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	. n enc s enc=$g(@ary@("resource","context","reference")) q:enc=""
	. d setIndex(index,purl,"encounterReference",enc)
	. n pat s pat=$g(@ary@("resource","subject","reference")) q:pat=""
	. d setIndex(index,purl,"patientReference",pat)
	i type="Immunizationi" d  q  ;
	. n purl s purl=$g(@ary@("fullUrl"))
	. i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	. i $e(purl,$l(purl))="/" s purl=purl_%wi
	. d setIndex(index,purl,"type",type)
	. d setIndex(index,purl,"rien",%wi)
	. n enc s enc=$g(@ary@("resource","encounter","reference")) q:enc=""
	. d setIndex(index,purl,"encounterReference",enc)
	. n pat s pat=$g(@ary@("resource","patient","reference")) q:pat=""
	. d setIndex(index,purl,"patientReference",pat)
	n purl s purl=$g(@ary@("fullUrl"))
	i purl="" s purl=type_"/"_$g(@ary@("resource","id"))
	i $e(purl,$l(purl))="/" s purl=purl_%wi
	d setIndex(index,purl,"type",type)
	d setIndex(index,purl,"rien",%wi)
	n enc s enc=$g(@ary@("resource","context","reference")) q:enc=""
	d setIndex(index,purl,"encounterReference",enc)
	n pat s pat=$g(@ary@("resource","subject","reference")) q:pat=""
	d setIndex(index,purl,"patientReference",pat)
	q
	;
setIndex(gn,sub,pred,obj)	; set the graph indexices
	;n gn s gn=$$setroot^%wd("fhir-intake")
	q:sub=""
	q:pred=""
	q:obj=""
	s @gn@("SPO",sub,pred,obj)=""
	s @gn@("POS",pred,obj,sub)=""
	s @gn@("PSO",pred,sub,obj)=""
	s @gn@("OPS",obj,pred,sub)=""
	q
	;
clearIndexes(gn)	; kill the indexes
	k @gn@("SPO")
	k @gn@("POS")
	k @gn@("PSO")
	k @gn@("OPS")
	q
	;
wsShow(rtn,filter)	; web service to show the fhir
	new ien set ien=$g(filter("ien"))
	if ien="" quit  ;
	new type set type=$get(filter("type"))
	new root set root=$$setroot^%wd("fhir-intake")
	new jroot set jroot=$name(@root@(ien,"json"))
	;
	new jtmp,juse
	set juse=jroot
	if type'="" do  ;
	. do getIntakeFhir("jtmp",,type,ien,1)
	. set juse="jtmp"
	do ENCODE^VPRJSON(juse,"rtn")
	s HTTPRSP("mime")="application/json" 
	quit
	;
getIntakeFhir(rtn,id,type,ien,plain)	; returns fhir vars for patient id resourceType type
	; id is optional
	; if id is not specified, ien can be passed instead. 
	; if id and ien are passed, only ien is used
	; rtn passed by name. it will overlay results in @rtn, so is additive
	; if plain is 1 then the array is returned without the type as the first 
	;    element of each node
	;
	new root set root=$$setroot^%wd("fhir-intake")
	if $g(ien)="" set ien=$order(@root@("B",id,""))
	if ien="" quit  ;
	;
	if $get(type)="" set type="all"
	kill @rtn
	;
	if type'="all" do  quit  ;
	. do get1FhirType(rtn,root,ien,type,$get(plain))
	;
	new jindex set jindex=$name(@root@(ien))
	new %wj set %wj=""
	for  set %wj=$order(@jindex@("type",%wj)) quit:%wj=""  do  ;
	. ;w !,"type ",%wj
	. do get1FhirType(rtn,root,ien,%wj,$get(plain))
	;
	quit
	;
get1FhirType(rtn,root,ien,type,plain)	; get one resourceType from the json
	new %wi set %wi=0
	new jindex set jindex=$name(@root@(ien))
	if '$data(@jindex@("type",type)) quit  ;
	for  s %wi=$order(@jindex@("type",type,%wi)) quit:+%wi=0  do  ;
	. if $get(plain)=1 merge @rtn@("entry",%wi)=@root@(ien,"json","entry",%wi)
	. else  merge @rtn@(type,"entry",%wi)=@root@(ien,"json","entry",%wi)
	quit
	;
fhir2graph(in,out)	; transforms fhir to a graph
	; in and out are passed by name
	; detects if json parser has been run and will run it if not
	;
	new json
	if $ql($q(@in@("")))<2 do DECODE^VPRJSON(in,"json") set in="json"
	;
	new rootj
	set rootj=$na(@in@("entry"))
	new i,cnt
	for i=1:1:$order(@rootj@(" "),-1) do  ;
	. new rname
	. set rname=$get(@rootj@(i,"resource","resourceType"))
	. if rname="" do  quit  ;
	. . w !,"error no resourceType in entry: ",i
	. . zwr @rootj@(i,*)
	. . b
	. if '$data(@out@(rname)) set cnt=1
	. else  set cnt=$order(@out@(rname,""),-1)+1
	. merge @out@(rname,cnt)=@rootj@(i,"resource")
	quit
	;
getEntry(ary,ien,rien) ; returns one entry in ary, passed by name
 n root s root=$$setroot^%wd("fhir-intake")
 i '$d(@root@(ien,"json","entry",rien)) q  ;
 m @ary@("entry",rien)=@root@(ien,"json","entry",rien)
 q
 ;
