<master src="index">

<if @ossweb:cmd@ eq error><return></if>

<%=[ossweb::html::menu::admin -table t]%>

<if @ossweb:cmd@ eq edit>
  <formtemplate id=form_app></formtemplate>
  To create folder, fill in fileds marked by * only
  <return>
</if>

<help_title>Applications</help_title>

<border>
<rowfirst>
 <TH WIDTH=5% >@apps:add@ @apps:refresh@</TH>
 <TH>Title</TH>
 <TH>Project Name</TH>
 <TH>App Name</TH>
 <TH>App Context</TH>
 <TH>Sort</TH>
</rowfirst>
<multirow name="apps">
 <row>
 <TD NOWRAP>@apps.up@ @apps.down@</TD>
 <TD NOWRAP>@apps.image@ @apps.title@</TD>
 <TD>@apps.project_name@</TD>
 <TD>@apps.app_name@</TD>
 <TD>@apps.page_name@</TD>
 <TD>@apps.sort@</TD>
 </row>
</multirow>
</border>
