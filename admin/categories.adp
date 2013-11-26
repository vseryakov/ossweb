<master mode=lookup>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_category></formtemplate>
   <return>
</if>

<%=[ossweb::html::menu::admin -table t]%>

<formtemplate id=form_category>
<help_title>Categories</help_title>
<border>
<rowfirst>
  <TD></TD>
  <TD><B>Module</B> <formwidget id=module></TD>
  <TD><B>Name</B> <formwidget id=category_name></TD>
  <TH>Description</TH>
  <TD ALIGN=RIGHT><formwidget id=search> <formwidget id=reset> <formwidget id=add></TD>
</rowfirst>
<multirow name=categories>
  <row onMouseOverClass=osswebRow3 url=@categories.url@>
    <TD WIDTH=10 <if @categories.bgcolor@ ne "">BGCOLOR=@categories.bgcolor@</if>></TD>
    <TD>@categories.module@</TD>
    <TD NOWRAP>@categories.category_name@</TD>
    <TD STYLE="font-size: 7;">@categories.description@</TD>
    <TD ALIGN=RIGHT>@categories.sort@</TD>
  </row>
</multirow>
</border>
</formtemplate>

