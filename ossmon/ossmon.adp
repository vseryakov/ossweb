<HEAD>
<ossweb:header>
<TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
<LINK REL=STYLESHEET TYPE="text/css" HREF="<%=[ossweb::conn server:host:images]/css/[ossweb::project style ossweb]%>.css"/>
<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/ossmon2.css"/>
</HEAD>

<BODY BGCOLOR=white>

<TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
<TR BGCOLOR=white VALIGN=MIDDLE HEIGHT=20>
  <TD BACKGROUND=/img/bg/navbar.gif CLASS=osswebTitle>OSSMON: <%=[ossweb::project description]%></TD>
  <TD BACKGROUND=/img/bg/navbar.gif ALIGN=RIGHT><%=[ossweb::html::toolbar]%></TD>
</TR>
</TABLE>

<TABLE CELLSPACING=0 CELLPADDING=0 WIDTH=100% BORDER=0>
<TR BGCOLOR=#000000><TD VALIGN=BOTTOM><IMG SRC=/img/misc/pixel.gif WIDTH=1 HEIGHT=1 BORDER=0></TD></TR>
</TABLE>

<TABLE CLASS=MM CELLSPACING=0 CELLPADDING=2 WIDTH=100% BORDER=0>
<TR VALIGN=CENTER>

<%
   foreach { name url sep } \
           { Console console.oss |
             Devices devices.oss |
             Alerts alerts.oss |
             Reports reports.oss |
             AlertRules alertrules.oss |
             ActionRules actionrules.oss |
             Templates templates.oss |
             Maps maps.oss |
             DeviceTypes device_types.oss |
             DeviceModels device_models.oss |
             Settings settings.oss |
             Manual doc/manual.html "" } {
     set menu [ossweb::decode [string match *[ossweb::conn page_name]* $url] 1 MMO MM]
     ossweb::adp::Write "
         <TD WIDTH=50 ALIGN=RIGHT CLASS=$menu
             onMouseOver=\"this.className='MMO'\"
             onMouseOut=\"this.className='$menu'\"
             onClick=\"window.location='$url'\">$name&nbsp;$sep</TD>"
   }
%>
   <TD WIDTH=100% >&nbsp;</TD>
</TR>
</TABLE>
<DIV WIDTH=100% ALIGN=RIGHT STYLE="color:gray">
    <%=[ossweb::nvl [ossweb::conn full_name] "\[Not logged in\]"]%>,
    <%=[ns_fmttime [ns_time]]%>
</DIV>

<CENTER><%=[ossweb::conn -msg]%></CENTER>

<DIV STYLE="margin: 5">
<slave>
</DIV>

<ossweb:footer>
</BODY>
