%wdcsv  ;ven/gpl-write dialog: csv processing ;2018-02-06T21:47Z
 ;;1.8;Mash;
 ;
 ; %wdcsv implements the Write Document Library's csv ppis & apis.
 ; These will eventually be moved to another Mash namespace, tbd.
 ; It is currently untested & in progress.
 ;
 quit  ; no entry from top
 ;
 ;
 ;
 ;@section 0 primary development
 ;
 ;
 ;
 ;@routine-credits
 ;@primary-dev: George P. Lilly (gpl)
 ; gpl@vistaexpertise.net
 ;@primary-dev-org: Vista Expertise Network (ven)
 ; http://vistaexpertise.net
 ;@copyright: 2017/2018, gpl, all rights reserved
 ;@license: Apache 2.0
 ; https://www.apache.org/licenses/LICENSE-2.0.html
 ;
 ;@last-updated: 2018-02-06T21:47Z
 ;@application: Mumps Advanced Shell (Mash)
 ;@module: Write Dialog - %wd
 ;@version: 1.8T04
 ;@release-date: not yet released
 ;@patch-list: none yet
 ;
 ;@additional-dev: Frederick D. S. Marshall (toad)
 ; toad@vistaexpertise.net
 ;
 ;@module-credits
 ;@primary-dev: George P. Lilly (gpl)
 ; gpl@vistaexpertise.net
 ;@project: VA Partnership to Increase Access to Lung Screening
 ; (VA-PALS)
 ; http://va-pals.org/
 ;@funding: 2017, gpl
 ;@funding: 2017, ven
 ;@funding: 2017/2018, Bristol-Myers Squibb Foundation (bmsf)
 ; https://www.bms.com/about-us/responsibility/bristol-myers-squibb-foundation.html
 ;@partner-org: Veterans Affairs Office of Rural health
 ; https://www.ruralhealth.va.gov/
 ;@partner-org: International Early Lung Cancer Action Program (I-ELCAP)
 ; http://ielcap.com/
 ;@partner-org: Paraxial Technologies
 ; http://paraxialtech.com/
 ;@partner-org: Open Source Electronic Health Record Alliance (OSEHRA)
 ; https://www.osehra.org/groups/va-pals-open-source-project-group
 ;
 ;@module-log
 ; 2017-09-24 ven/gpl %*1.8t01 %wdcsv: create routine to hold
 ; all csv methods.
 ;
 ; 2018-02-06 ven/toad %*1.8t04 %wdcsv: passim add white space &
 ; hdr comments, tag w/Apache license & attribution & to-do to shift
 ; to %sf later.
 ;
 ;@to-do
 ; %wd: convert entry points to ppi/api style
 ; r/all local calls w/calls through ^%wd
 ; break up into smaller routines & change branches from %wd
 ; renamespace under %sfg? under %sfh? research best choice
 ;
 ;@contents
 ; csv2graph: import csv file to graph
 ; $$prune = extrinsic removes extra quotes
 ; $$delim = figures out csv delimiter
 ; $$rename = extrinsic returns new name or old name if not found
 ; $$wellformed = extrinsic returns 1 if csv ary is well formed
 ;
 ;
 ;
 ;@section 1 code to implement ppis & apis
 ;
 ;
 ;
csv2graph(source,graph,noindex) ; import a csv file to a graph
 ;
 ; graph is optional, will default to csvGraph
 ; source is either a filename which will be found in seeGraph
 ; or a global passed by name usually loaded with FTG^%ZISH
 ; if noindex=1 an index will not be generated
 ;
 new %wary,%wi,%wgraph
 if $extract(source,1)="^" merge %wary=@$name(source)
 else  do getThis^%wdgraph("%wary",source)
 new delim s delim=$$delim(.%wary)
 if delim=-1 do  quit  ;
 . write !,"error, delimiter not found"
 . quit
 if '$$wellformed(.ary,delim) do  quit  ;
 . write !,"error, csv file not well formed delimiter="_delim
 . quit
 new %wgraph,%wcol,%wid ; place to store the graph and the id of the graph
 ; %wcol contains the column names in order
 set %wid=$$nameThis^%wdgraph(source) ; get the id from the context
 ; first get the column names from row 1
 ;for %wi=1:1:$length(%wary(1),delim) set %wcol(%wi)=$$rename($translate($$prune($piece(%wary(1),delim,%wi))," ","_"))
 for %wi=1:1:$length(%wary(1),delim) set %wcol(%wi)=$translate($$prune($piece(%wary(1),delim,%wi))," ","_")
 set %wi=1
 for  set %wi=$order(%wary(%wi)) quit:+%wi=0  do  ;
 . new %wj
 . ; write !,%wary(%wi)
 . for %wj=1:1:$length(%wary(%wi),delim) do  ;
 . . new %wval set %wval=$piece(%wary(%wi),delim,%wj)
 . . if %wval'="" set %wgraph(%wid,%wi,%wcol(%wj))=$$prune(%wval)
 . . quit
 . quit
 if $get(graph)="" set graph="csvGraph"
 merge %wgraph(%wid,"order")=%wcol
 new rpl set rpl=1
 do insert2graph^%wdgraph("%wgraph",graph,rpl)
 ;
 i $g(noindex)'=1 d  ; we want in index
 . n root s root=$$setroot^%wd(graph)
 . s groot=$na(@root@("graph",source))
 . d index(groot)
 . s @root@("index","root")=groot
 . 
 ;
 quit  ; end of csv2graph^%wd
 ;
 ;
 ;
prune(txt) ; extrinsic removes extra quotes
 ;
 ;if txt'["""" quit  ; no extra quotes 
 if txt'["""" quit txt  ; no extra quotes - fix by gpl 
 new %w1,%return set %return=""
 for %w1=1:1:$length(txt,"""") do  ;
 . set %return=%return_$piece(txt,"""",%w1)
 . quit
 ;
 quit %return ; end of prune^%wd
 ;
 ;
 ;
delim(ary) ; figures out the csv delimiter
 ;
 ; return -1 if there not found
 ; ary is passed by reference
 ; returns the delimiter
 ;
 new %wdlim,%wfound,%return set %wfound=0
 for %wdlim=$char(9),",","|" quit:%wfound  do  ; for each common delimiter
 . new %count set %count=$length(ary(1),%wdlim) ; how many in line 1
 . if %count<2 quit  ;
 . if $length(ary(2),%wdlim)=%count s %wfound=1 s %return=%wdlim
 . if $data(ary(3)) if $length(ary(3),%wdlim)='%count set %wfound=0 kill %return
 . if $data(ary(4)) if $length(ary(4),%wdlim)='%count set %wfound=0 kill %return
 . quit
 if %wfound=0 quit -1
 ;
 quit %return ; end of $$delim^%wd
 ;
 ;
 ;
rename(name) ; extrinsic returns new name or old name if not found
 q  ; this routine needs to be rewritten - gpl
 ;
 ; this is a temporary routine until the csv files are updated
 ;
 new nam
 set nam("Sub._#")="sub#"
 set nam("Field_Name")="fieldName"
 set nam("Title")="fieldTitle"
 set nam("Data_Type")="dataType"
 set nam("Value")="value"
 set nam("Definition")="definition"
 set nam("m-class-#")="mClass#"
 set nam("m-prop-#")="mProp#"
 set nam("m-prop-name")="mPropName"
 set nam("m-prop-title")="mPropTitle"
 set nam("m-prop-loc")="mPropLoc"
 set nam("m-prop-type")="mPropType"
 set nam("m-prop-det")="mPropDet"
 set nam("m-delim-check")="mDlimCheck"
 new namtmp set namtmp=$get(nam(name))
 if namtmp="" set namtmp=name
 ;
 quit namtmp ; end of $$rename^%wd
 ;
 ;
 ;
wellformed(ary,delim) ; extrinsic returns 1 if csv ary is well formed
 ;
 ; checks to see that the count of the delimiter is the same
 ; on every line
 ; ary is passed by reference
 ;
 new %wi,%count,%result set %wi=0 set %result=1
 for  set %wi=$order(ary(%wi)) quit:+%wi=0  do  ;
 . if '$data(%count) set %count=$length(ary(%wi),delmin) quit  ;
 . if $length(ary(%wi))'=%count set %result=0
 . quit
 ;
 quit %result ; end of $$wellformed^%wd
 ;
 ;
index(zgraph) ; will create a pos and ops index at the place pointed to by graph
 ; zgraph is passed by name
 ; 
 i $d(@zgraph@("pos")) k @zgraph@("pos")
 i $d(@zgraph@("ops")) k @zgraph@("ops")
 n zi s zi=0
 f  s zi=$o(@zgraph@(zi)) q:+zi=0  d  ;
 . n zj,zv
 . s zj=""
 . f  s zj=$o(@zgraph@(zi,zj)) q:zj=""  d  ;
 . . s zv=$g(@zgraph@(zi,zj))
 . . q:zv=""
 . . s @zgraph@("pos",zj,zv,zi)=""
 . . s @zgraph@("ops",zv,zj,zi)=""
 q
 ;
 ;
eor ; end of routine %wdcsv
