<HEAD>
  <ossweb:header>
  <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
  <LINK REL=icon HREF=/favicon.ico TYPE=image/ico />
  <LINK REL="shortcut icon" HREF=/favicon.ico />
</HEAD>
<BODY BACKGROUND=<%=[ossweb::image_name [ossweb::project page_bg]]%> >

<TABLE WIDTH=100% CELLPADDING=0 CELLSPACING=0 BORDER=0>
<TR CLASS=osswebToolbar>
   <TD STYLE="padding:3px;"><%=[ossweb::html::link -image [ossweb::project logo] -width "" -height "" -url [ossweb::project url]]%></TD>
   <TD><%=[ossweb::project name]%></TD>
   <TD STYLE="padding:3px;"ALIGN=RIGHT><DIV><%=[ossweb::project info]%></DIV></TD>
</TR>
<TR><TD COLSPAN=3><IMG SRC=/img/misc/blackline.gif WIDTH=100% HEIGHT=2></TD></TR>
<TR><TD COLSPAN=3 ALIGN=CENTER><ossweb:msg></TD></TR>
<TR><TD COLSPAN=3><slave></TD></TR>
<TR><TD COLSPAN=3 ALIGN=RIGHT CLASS=osswebMsg><%=[ossweb::project footer]%></TD></TR>
</TABLE>
<ossweb:footer>
</BODY>
