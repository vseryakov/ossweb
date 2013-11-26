<HEAD>
<%=[ossweb::conn html:head]%>
<TITLE>Maverix: Mail Verification Exchange</TITLE>
<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/ossweb.css"/>
<STYLE>
  body {
    margin: 0;
    padding: 0;
  }
  td {
    font-size: 10pt;
  }
  a {
    font-size: 9pt;
  }
  input.text {
    font-size: 8pt; 
    font: Arial, Helvetica;
    border-width: 1; 
    border-color: #DDDDDD; 
    background-color: #CCCCCC;
  }
  .title {
    font-size: 10pt;
    font-weight: bold;
    color: #293854;
  }
  .field {
    font-size: 10pt;
    font-weight: bold;
    color: #293854;
  }
  .small {
    font-size: 9pt;
  }
</STYLE>
</HEAD>

<BODY BGCOLOR=white>

<TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
<TR VALIGN=MIDDLE BGCOLOR=#EEEEEE BACKGROUND=/img/bg/navbar.gif HEIGHT=20>
  <TD CLASS=title>Maverix Anti-Spam Digest</TD>
  <TD ALIGN=RIGHT><B><%=[ossweb::conn info]%></B></TD>
</TR>
</TABLE>

<CENTER>
<TABLE BORDER=0><TR><TD CLASS=field><%=[ossweb::conn -msg]%></TD></TR></TABLE>
</CENTER>

<if @cmd@ eq error><return></if>

<slave>
<%=[ossweb::conn html:foot]%>
</BODY>
