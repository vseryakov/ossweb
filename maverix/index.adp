<HEAD>
<%=[ossweb::conn html:head]%>
<TITLE>Maverix: Mail Verification Exchange</TITLE>
<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/maverix.css"/>
<STYLE>
.menuOver {
  background-color: white;
  color: #293854;
  font-size: 12pt; 
  font-weight: bold;
  font-family: Verdana, Tahoma, Arial, Helvetica, sans-serif;
}
.menu {
  background-color: #DDEEFF;
  color: #293854;
  font-size: 12pt; 
  font-weight: bold;
  font-family: Verdana, Tahoma, Arial, Helvetica, sans-serif;
}
</STYLE>
</HEAD>

<BODY BGCOLOR=white>

<TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
<TR VALIGN=MIDDLE BGCOLOR=#EEEEEE BACKGROUND=/img/bg/navbar.gif HEIGHT=20>
  <TD CLASS=osswebTitle>Maverix: Mail Verification Exchange</TD>
  <TD ALIGN=RIGHT><%=[ossweb::html::toolbar]%></TD>
</TR>
</TABLE>
<TABLE CELLSPACING=0 CELLPADDING=0 WIDTH=100% BORDER=0>
<TR BGCOLOR=#6F6F6F>
  <TD VALIGN=BOTTOM><IMG SRC=/img/misc/pixel.gif WIDTH=1 HEIGHT=1 BORDER=0></TD>
</TR>
</TABLE>
<TABLE CELLSPACING=0 CELLPADDING=5 WIDTH=100% BORDER=0>
<TR BGCOLOR=#DDEEFF VALIGN=CENTER>
  <TD WIDTH=40% >&nbsp;</TD>
  <TD WIDTH=50
      ALIGN=RIGHT
      CLASS=menu 
      onMouseOver="this.className='menuOver'" 
      onMouseOut="this.className='menu'"
      onClick="window.location='Users.oss'">
    Users&nbsp;|
  </TD>
  <TD WIDTH=50 
      CLASS=menu 
      onMouseOver="this.className='menuOver'" 
      onMouseOut="this.className='menu'"
      onClick="window.location='Senders.oss'">
    Senders&nbsp;|
  </TD>
  <TD WIDTH=50 
      CLASS=menu 
      onMouseOver="this.className='menuOver'" 
      onMouseOut="this.className='menu'"
      onClick="window.location='Messages.oss'">
    Messages&nbsp;|
  </TD>
  <TD WIDTH=50 
      CLASS=menu 
      onMouseOver="this.className='menuOver'" 
      onMouseOut="this.className='menu'"
      onClick="window.location='Settings.oss'">
    Settings
  </TD>
  <TD ALIGN=RIGHT>
    <%=[ossweb::nvl [ossweb::conn full_name] "\[Not logged in\]"]%><BR>
    <%=[ns_fmttime [ns_time]]%>
  </TD>
</TR>
</TABLE>
<TABLE CELLSPACING=0 CELLPADDING=0 WIDTH=100% BORDER=0>
<TR BGCOLOR=#6F6F6F>
  <TD VALIGN=BOTTOM><IMG SRC=/img/misc/pixel.gif WIDTH=1 HEIGHT=1 BORDER=0></TD>
</TR>
</TABLE>

<CENTER>
<TABLE BORDER=0><TR><TD><%=[ossweb::conn -msg]%></TD></TR></TABLE>
</CENTER>

<slave>

<%=[ossweb::conn html:foot]%>
