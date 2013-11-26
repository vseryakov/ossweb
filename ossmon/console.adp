<if @ossweb:cmd@ eq frame>
  <FRAMESET COL=100% ROWS="60%,40%">
    <FRAME SRC=<%=[ossweb::html::url tab browse logs 0 lookup:mode 2]%> FRAMEBORDER=0>
    <FRAME SRC=<%=[ossweb::html::url tab charts tabs 0 lookup:mode 2]%> FRAMEBORDER=0>
  </FRAMESET>
  <return>
</if>

<if @ossweb:cmd@ eq error><%=[ossweb::conn msg]%><return></if>

<LINK REL=STYLESHEET TYPE="text/css" HREF="<%=[ossweb::config server:host:images]%>/css/ossmon2.css"/>

<if @ossweb:cmd@ eq check>
   <HEAD><META HTTP-EQUIV=Refresh CONTENT="@refresh@"></HEAD>
   <SCRIPT>
   parent.Alerts = new Array();
   @script@
   </SCRIPT>
   <BODY BGCOLOR=white STYLE="margin: 5;font-size: 8pt;">@html@</BODY>
   <return>
</if>

<SCRIPT>
var Devices = new Array();
var Alerts = new Array();

function doAlert(device_id,device_path,device_name,alert_id,alert_name,alert_class)
{
   return new newAlert(device_id,device_path,device_name,alert_id,alert_name,alert_class);
}

function newAlert(device_id,device_path,device_name,alert_id,alert_name,alert_class)
{
   this.device_id = device_id;
   this.device_path = device_path;
   this.device_name = device_name;
   this.alert_id = alert_id;
   this.alert_name = alert_name;
   this.alert_class = alert_class;
   this.assigned = 0;
}
function newDevice(device_id,device_path)
{
   this.device_id = device_id;
   this.device_path = device_path;
   this.alert_id = 0;
}

function scanDevices(alerts,path,tab)
{
   var i,j,a,m,re,n = 0;
   for(i = Devices.length-1;i >= 0;i--) {
     switch(path) {
      case 1:
         re = new RegExp('^'+Devices[i].device_path, 'ig');
         for(j = 0;j < alerts.length;j++) {
           if(alerts[j].device_path.match(re)) break;
         }
         break;
      default:
         for(j = 0;j < alerts.length;j++) {
           if(Devices[i].device_id == alerts[j].device_id) break;
         }
         break;
     }
     if(j == alerts.length) {
       Devices[i].alert_id = 0;
       if(varGet('ma'+Devices[i].device_id) != '') {
         varSet('ma'+Devices[i].device_id,'');
         varClass('m'+Devices[i].device_id,'NST');
       }
       continue;
     }
     if(alerts[j].assigned) continue;
     if(Devices[i].alert != alerts[j].alert_id) n++;
     //alerts[j].assigned = 1;
     Devices[i].alert = alerts[j].alert_id;
     m = "Alert Info";
     if(Devices[i].device_id != alerts[j].device_id) {
       if(tab == 'maps') {
         m = alerts[j].alert_name + ': ' + alerts[j].device_name;
       } else {
         alerts[j].alert_name += ' from ' + alerts[j].device_name;
       }
     }
     a = '<A HREF=javascript:; TITLE="'+m+'" onClick="';
     a += "window.open('<%=[ossweb::html::url devices cmd alert lookup:mode 2]%>";
     a += '&alert_id='+alerts[j].alert_id;
     a += '&device_id='+alerts[j].device_id;
     a += "','INFO','@winopts@')";
     a += '">';
     a += alerts[j].alert_name;
     a += '</A>';
     varSet('ma'+Devices[i].device_id,a);
     varClass('m'+Devices[i].device_id,alerts[j].alert_class);
   }
   return n;
}

function scanCharts()
{
   var now = new Date();
   for(var i = 0;i < document.images.length;i++) {
     if(document.images[i].name.indexOf('ossmon') == -1) continue;
     document.images[i].src = document.images[i].src.split('?')[0]+'?'+now.getTime();
   }
   setTimeout("scanCharts()",60000);
}
setTimeout("scanCharts()",60000);
@script@
</SCRIPT>

<master mode=lookup>

<TABLE WIDTH=100% BORDER=0 BGCOLOR=#EEEEEE CELLSPACING=0 CELLPADDING=0>
<if @tabs@ eq 1>
<TR BGCOLOR=white>
    <TD WIDTH=5% NOWRAP><%=[ossweb::html::title "OSSMON Console"]%></TD>
    <TD ALIGN=CENTER><formtab id=form_tab width=200 style=oval></TD>
    <TD WIDTH=5% ALIGN=RIGHT NOWRAP>
       <formtemplate id=form_filter>
       <formlabel id=form_filter.filter> <formwidget id=form_filter.filter> <formwidget id=form_filter.go>
       </formtemplate>
    </TD>
</TR>
</if>

<if @tab@ eq maps>
<TR><TD COLSPAN=3><formtemplate id=form_map><formwidget id=map_id></formtemplate></TD></TR>
<if @map_id@ ne "">
<TR VALIGN=TOP>
   <TD COLSPAN=3><IMG NAME=mapImage SRC=maps/@map_image@ STYLE="position:absolute; top:@defY@; left:@defX@"></TD>
</TR>
</TABLE>

<multirow name=devices>
  <DIV ID=m@devices.device_id@ CLASS=NST STYLE="text-align:center;z-index:0;position:absolute;left:@devices.x@;top:@devices.y@;">
    @devices.image@ @devices.url@<BR>
    <DIV ID=ma@devices.device_id@ STYLE="font-size:6pt;"></DIV>
  </DIV>
</multirow>
<IFRAME SRC=console.oss?cmd=check&tab=@tab@ BORDER=0 FRAMEBORDER=0 WIDTH=0 HEIGHT=0></IFRAME>
</if>
</if>

<if @tab@ ne maps>
<TR><TD COLSPAN=2 ALIGN=CENTER>
    <TABLE BORDER=0 CELLSPACING=10 CELLPADDING=5 BGCOLOR=#EEEEEE><TR>
    <multirow name=devices>
    <TD ID=m@devices.device_id@ CLASS=@devices.class@ WIDTH=100 VALIGN=TOP>
      <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADING=0>
      <TR VALIGN=TOP>
         <TD>
         <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
         <TR VALIGN=TOP>
            <TD ALIGN=CENTER>@devices.url@</TD>
            <TD ALIGN=RIGHT NOWRAP>@devices.browse@</TD>
         </TR>
         </TABLE>
         </TD>
      </TR>
      <TR><TD ALIGN=CENTER ID=ma@devices.device_id@ STYLE="font-size:6pt;"></TD></TR>
      <TR><TD ALIGN=CENTER>@devices.objects@</TD></TR>
      </TABLE>
    </TD>
    <if @devices.break@ eq 0></TR><TR></if>
    </multirow>
    </TABLE>
    </TD>
</TR>
<if @logs@ eq 1>
<TR><TD COLSPAN=2>&nbsp;</TD></TR>
<TR><TD COLSPAN=2>
    <FIELDSET>
    <LEGEND><B>Alert Log</B></LEGEND>
    <IFRAME SRC=console.oss?cmd=check&tab=@tab@ BORDER=0 FRAMEBORDER=0 WIDTH=100% HEIGHT=50></IFRAME>
    </FIELDSET>
    </TD>
</TR>
<else>
<TR><TD COLSPAN=2>
    <IFRAME SRC=console.oss?cmd=check&tab=@tab@ BORDER=0 FRAMEBORDER=0 WIDTH=0 HEIGHT=0></IFRAME>
    </TD>
</TR>
</if>
</TABLE>

<DIV STYLE="font-size:6pt;padding:5px">
  <DIV CLASS=AST STYLE="display:inline;">Advise</DIV>
  <DIV CLASS=WST STYLE="display:inline;">Warning</DIV>
  <DIV CLASS=RST STYLE="display:inline;">Critical</DIV>
  <DIV CLASS=EST STYLE="display:inline;">Error</DIV>
</DIV>

</if>

<DIV ID=alert CLASS=osswebPopupObj></DIV>
