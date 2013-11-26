<HEAD>
<TITLE>Maverix Error</TITLE>
<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/maverix.css"/>
</HEAD>

<BODY BGCOLOR=white>

<TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
<TR VALIGN=MIDDLE BGCOLOR=#EEEEEE BACKGROUND=/img/bg/navbar.gif HEIGHT=20>
  <TD CLASS=osswebTitle>Maverix: Mail Verification Exchange</TD>
</TR>
</TABLE>
<TABLE CELLSPACING=0 CELLPADDING=0 WIDTH=100% BORDER=0>
<TR BGCOLOR=#6F6F6F>
  <TD VALIGN=BOTTOM><IMG SRC=/img/misc/pixel.gif WIDTH=1 HEIGHT=1 BORDER=0></TD>
</TR>
</TABLE>

<CENTER>
<FONT COLOR=red>
<%=[ossweb::util::nvl [ossweb::conn -msg] "Internal Error"]%>
</FONT>
</CENTER>

