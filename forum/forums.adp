<master src="index">

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_forum title="Forum Topic Details"></formtemplate>
   <return>
</if>

<helptitle>Forums</helptitle>

<border>
<rowfirst>
 <TH>@forums:add@ Name</TH>
 <TH>Status</TH>
 <TH>Description</TH>
</rowfirst> 
<multirow name=forums>
 <row VALIGN=TOP onMouseOverClass=osswebRow3 url=@forums.url@>
  <TD>@forums.forum_name@</TD>
  <TD>@forums.forum_type@ / @forums.forum_status@</TD>
  <TD>@forums.description@</TD>
 </row>
</multirow>
</border>
