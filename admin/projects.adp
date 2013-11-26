<master>

<%=[ossweb::html::menu::admin -table t]%>

<if @ossweb:cmd@ eq edit>
  <formtemplate id=form_project title="Project Details"></formtemplate>
  <return>
</if>

<help_title>Projects</help_title>

<border>
<rowfirst>
 <TH>@projects:add@ ID</TH>
 <TH>Project Name</TH>
 <TH>URL</TH>
 <TH>Logo</TH>
</rowfirst>
<multirow name="projects">
 <row WIDTH=5% VALIGN=TOP>
 <TD>@projects.project_id@</TD>
 <TD>@projects.project_name@</TD>
 <TD>@projects.project_url@</TD>
 <TD>@projects.project_logo@</TD>
 </row>
</multirow>
</border>
<return>
