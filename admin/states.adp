<master src="index">

<%=[ossweb::html::menu::admin -table t]%>

<if @ossweb:cmd@ ne edit>

<help_title>State Machine</help_title>

<border>
<rowfirst>
 <TH>@status:add@ Module</TH>
 <TH>ID</TH>
 <TH>Name</TH>
 <TH>Type/Group</TH>
 <TH>Next States</TH>
 <TH>Description</TH>
 <TH WIDTH=2% >Sort</TH>
</rowfirst>
<multirow name="status">
 <row onMouseOverClass=osswebRow3 url=@status.url@>
 <TD>@status.module@</TD>
 <TD>@status.status_id@</TD>
 <TD>@status.status_name@</TD>
 <TD>@status.type@</TD>
 <TD>@status.states@</TD>
 <TD>@status.description@</TD>
 <TD WIDTH=2% >@status.sort@</TD>
 </row>
</multirow>
</border>
<return>
</if>

<formtemplate id=form_status></formtemplate>

