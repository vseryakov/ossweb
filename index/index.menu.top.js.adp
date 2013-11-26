<HEAD>
  <ossweb:header>
  <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
  <LINK REL=icon HREF=/favicon.ico TYPE=image/ico />
  <LINK REL="shortcut icon" HREF=/favicon.ico />
</HEAD>
<BODY BACKGROUND=<%=[ossweb::image_name [ossweb::project page_bg]]%>>

<TABLE WIDTH=100% HEIGHT=50 BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR CLASS=osswebToolbar HEIGHT=50 VALIGN=TOP>
  <TD BACKGROUND=<%=[ossweb::image_name [ossweb::project logo_bg]]%> >
    <TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
    <TR>
      <TD ALIGN=LEFT VALIGN=TOP>
        <%=[ossweb::html::link -image [ossweb::project logo] -width "" -height "" -url [ossweb::project url]]%>
      </TD>
      <TD ALIGN=CENTER VALIGN=TOP CLASS=osswebLogoTitle><%=[ossweb::project title]%></TD>
      <TD ALIGN=RIGHT NOWRAP VALIGN=TOP CLASS=osswebLogoInfo>
        <%=[ossweb::html::toolbar]%><BR>
        <%=[ossweb::nvl [ossweb::conn full_name] "\[Not logged in\]"]%><BR>
        <%=[ns_fmttime [ns_time]]%>
      </TD>
    </TR>
    </TABLE>
  </TD>
</TR>
</TABLE>
<DIV ID=osswebMenu CLASS=osswebMenuBar>
   <%=[ossweb::html::menu::js apps -parent osswebMenu]%>
</DIV>
<DIV HEIGHT=20><ossweb:msg></DIV>
<DIV STYLE="margin:5;"><slave></DIV>

<ossweb:footer>
</BODY>

