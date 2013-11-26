<HEAD>
  <ossweb:header>
  <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
  <LINK REL=icon HREF=/favicon.ico TYPE=image/ico />
  <LINK REL="shortcut icon" HREF=/favicon.ico />
  <SCRIPT SRC=/js/appmenu.js></SCRIPT>
</HEAD>
<BODY BACKGROUND=<%=[ossweb::image_name [ossweb::project page_bg]]%>>

<% ossweb::html::menu app_menu -all t -tree f %>

<TABLE WIDTH=100% BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR CLASS=osswebToolbar>
  <TD BACKGROUND=<%=[ossweb::image_name [ossweb::project logo_bg]]%> >
    <TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
    <TR>
      <TD ALIGN=LEFT>
        <%=[ossweb::html::link -image [ossweb::project logo] -width "" -height "" -url [ossweb::project url]]%>
      </TD>
      <TD ALIGN=CENTER CLASS=osswebLogoTitle><%=[ossweb::project name]%></TD>
      <TD ALIGN=RIGHT VALIGN=TOP CLASS=osswebLogoInfo>
        <%=[ossweb::html::toolbar]%><BR>
        <%=[ossweb::nvl [ossweb::conn full_name] "\[Not logged in\]"]%><BR>
        <%=[ns_fmttime [ns_time]]%>
      </TD>
    </TR>
    </TABLE>
  </TD>
</TR>
</TABLE>
<TABLE WIDTH=100% BORDER=0 CELLPADDING=2 CELLSPACING=0 BGCOLOR=#bec6d3>
<TR HEIGHT=20><TD><TABLE BORDER=0 CELLSPACING=1 CELLPADDING=0><TR>
<multirow name="app_menu">
<if @app_menu.level@ ne 0><% append submenu_list "appItemNew(@app_menu.group_id@,@app_menu.id@,'@app_menu.page_name@','@app_menu.url@','@app_menu.image@','@app_menu.title@','@app_menu.target@');\n" %><else>
<TD NOWRAP CLASS=osswebApp onMouseOut="this.className='osswebApp'" onMouseOver="this.className='osswebAppOver'"
    onClick="appItemUrl(@app_menu.id@,'@app_menu.page_name@','@app_menu.url@','@app_menu.target@')">@app_menu.image@ @app_menu.title@</TD>
<TD>|</TD>
</if>
</multirow>
</TR></TABLE></TD>
</TR>
</TABLE>
<SCRIPT>@submenu_list@</SCRIPT>
<TABLE WIDTH=100% BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR BGCOLOR=black><TD HEIGHT=1><IMG SRC=/img/misc/pixel.gif WIDTH=100% HEIGHT=1 BORDER=0></TD></TR>
</TABLE>
<TABLE WIDTH=100% BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR HEIGHT=20><TD ALIGN=CENTER ID=app_submenu></TD></TR>
<TR BGCOLOR=black><TD HEIGHT=1><IMG SRC=/img/misc/pixel.gif WIDTH=100% HEIGHT=1 BORDER=0></TD></TR>
</TABLE>
<ossweb:msg><P>
<DIV STYLE="margin:5;"><slave></DIV><P>
<ossweb:footer>
<TABLE WIDTH=100% >
<TR><TD ALIGN=RIGHT CLASS=osswebFooter><%=[ossweb::project footer]%></TD></TR>
</TABLE>
</BODY>
