<HEAD>
  <ossweb:header>
  <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
  <LINK REL=icon HREF=/favicon.ico TYPE=image/ico />
  <LINK REL="shortcut icon" HREF=/favicon.ico />
</HEAD>
<BODY BACKGROUND=<%=[ossweb::image_name [ossweb::project page_bg]]%>>

<TABLE WIDTH=100% BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR CLASS=osswebToolbar>
  <TD COLSPAN=2 BACKGROUND=<%=[ossweb::image_name [ossweb::project logo_bg]]%>>
    <TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
    <TR>
      <TD ALIGN=LEFT>
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
<TR BGCOLOR=black>
   <TD COLSPAN=2 HEIGHT=1><IMG SRC=/img/misc/pixel.gif WIDTH=100% HEIGHT=1 BORDER=0></TD>
</TR>
<TR>
  <TD WIDTH=5% VALIGN=TOP>
     <% ossweb::html::menu app_menu %>
     <TABLE CELLPADDING=1 CELLSPACING=1 BORDER=0 CLASS=osswebMenuBg>
     <multirow name="app_menu">
     <TR <if @app_menu.selected@ eq 1>
         CLASS=osswebMenuItemSelected onMouseOut="this.className='osswebMenuItemSelected';popupHide('@app_menu.id@');"
         <else>
         CLASS=osswebMenuItem onMouseOut="this.className='osswebMenuItem';popupHide('@app_menu.id@');"
         </if>
         onMouseOver="this.className='osswebMenuItemSelected';popupShow('@app_menu.id@',{event:event});"
         <if @app_menu.target@ ne "">onClick="window.open('@app_menu.url@','@app_menu.target@')"</if>
         <if @app_menu.target@ eq "">onClick="window.location='@app_menu.url@'"</if> >
     <TD NOWRAP CLASS=osswebMenuTitle>@app_menu.image@ @app_menu.title@</TD>
     </TR>
     </multirow>
     </TABLE>
  </TD>
  <TD WIDTH=95% VALIGN=TOP>
    <TABLE WIDTH=100% CELLPADDING=5 CELLSPACING=5 BORDER=0>
      <TR HEIGHT=5><TD><ossweb:msg></TD></TR>
      <TR>
        <TD><slave></TD>
      </TR>
    </TABLE>
  </TD>
</TR>
</TABLE>
<ossweb:footer>
<TABLE WIDTH=100% >
<TR><TD ALIGN=RIGHT CLASS=osswebFooter><%=[ossweb::project footer]%></TD></TR>
</TABLE>
</BODY>
