<HEAD>
 <%=[ossweb::conn html:head]%>
 <TITLE><%=[ossweb::nvl [ossweb::conn title] [ossweb::project name]]%></TITLE>
 <LINK REL=STYLESHEET TYPE="text/css" HREF="<%=[ossweb::conn::hostname]/css/[ossweb::project style ossweb]%>.css"/>
</HEAD>

<BODY>

<CENTER>
<TABLE WIDTH=95% CELLPADDING=0 CELLSPACING=0 BORDER=0 BGCOLOR=white>
<TR><TD COLSPAN=4 ALIGN=RIGHT NOWRAP>@cart_link@ @checkout_link@</TD></TR>
<TR><TD COLSPAN=4 CLASS=osswebMsg ALIGN=CENTER><%=[ossweb::conn -msg]%></TD></TR>
<TR><TD COLSPAN=4 ALIGN=CENTER><formtab id=form_tab></TD></TR>
<TR><TD COLSPAN=4 CLASS=osswebTabSelected ALIGN=RIGHT>
    <formtemplate id=form_search>
    <formwidget id=product_name> <formwidget id=search>
    </formtemplate>
    </TD>
</TR>
<TR><TD COLSPAN=4>&nbsp;</TD></TR>
<TR VALIGN=TOP>
    <TD WIDTH=1% >
    <if @menu:rowcount@ gt 0>
    <B>Browse</B><P><multirow name=menu>@menu.title@<BR></multirow>
    </if>
    </TD>
    <TD WIDTH=50>&nbsp;</TD>
    <TD><slave></TD>
    <TD WIDTH=50>&nbsp;</TD>
</TR>
</TABLE>
</CENTER>

<%=[ossweb::conn html:foot]%>

</BODY>
