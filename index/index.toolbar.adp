<HEAD>
  <ossweb:header>
  <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
  <LINK REL=icon HREF=/favicon.ico TYPE=image/ico />
  <LINK REL="shortcut icon" HREF=/favicon.ico />
</HEAD>
<BODY BACKGROUND=<%=[ossweb::image_name [ossweb::project page_bg]]%> >

<TABLE WIDTH=100% CELLPADDING=0 CELLSPACING=0 BORDER=0>
<TR CLASS=osswebToolbar>
   <TD COLSPAN=3 BACKGROUND=<%=[ossweb::image_name [ossweb::project logo_bg]]%>>
   <TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
   <TR><TD ALIGN=LEFT>
       <%=[ossweb::html::link -image [ossweb::project logo] -width "" -height 50 -url [ossweb::project url]]%>
       </TD>
       <TD ALIGN=CENTER CLASS=osswebLogoTitle><%=[ossweb::project title]%></TD>
       <TD ALIGN=RIGHT VALIGN=BOTTOM NOWRAP CLASS=osswebLogoInfo>
       <%=[ossweb::html::toolbar]%><P>
       <%=[ossweb::nvl [ossweb::conn full_name] "\[Not logged in\]"]%>
       <%=[ns_fmttime [ns_time]]%>
       </TD>
   </TR>
   </TABLE>
   </TD>
</TR>
<TR><TD COLSPAN=3><IMG SRC=/img/misc/blackline.gif WIDTH=100% HEIGHT=2></TD></TR>
<TR><TD COLSPAN=3 ALIGN=CENTER><ossweb:msg></TD></TR>
<TR><TD COLSPAN=3><slave></TD></TR>
<TR><TD COLSPAN=3 ALIGN=RIGHT CLASS=osswebMsg><%=[ossweb::project footer]%></TD></TR>
</TABLE>
<ossweb:footer>
</BODY>


