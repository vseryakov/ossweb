<HEAD>
  <ossweb:header>
  <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
  <LINK REL=icon HREF=/favicon.ico TYPE=image/ico />
  <LINK REL="shortcut icon" HREF=/favicon.ico />
</HEAD>
<BODY BACKGROUND="<%=[ossweb::image_name [ossweb::project page_bg]]%>"
      BGCOLOR="<%=[ossweb::conn html:bgcolor]%>"
      STYLE="margin:<%=[ossweb::conn html:margin 5]%>;" >

<CENTER><ossweb:msg></CENTER>
<slave>
<ossweb:footer>
</BODY>
