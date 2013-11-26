<%=[ossweb::html::menu::admin -table t]%><P>

<master mode=lookup>

<if @cmd@ eq view>
 <help_title>Help Topic List</help_title>
 <border>
 <rowfirst>
 <TH>@help:add@ Title</TH>
 <TH>Project</TH>
 <TH>App Name</TH>
 <TH>App Context</TH>
 <TH>Cmd Name</TH>
 <TH>Cmd Context</TH>
 </rowfirst>
 <multirow name="help">
 <row onMouseOverClass=osswebRow3 url=@help.url@>
 <TD>@help.title@</TD>
 <TD>@help.project_name@</TD>
 <TD>@help.app_name@</TD>
 <TD>@help.page_name@</TD>
 <TD>@help.cmd_name@</TD>
 <TD>@help.ctx_name@</TD>
 </row>
 </multirow>
 </border>
</if>

<if @cmd@ eq edit>
 <formtemplate id=form_help title="Help Topic Details"></formtemplate>
 <FONT SIZE=1 COLOR=gray>
  For cross links special proc [ossweb::html::help_link title args] may be used. It accepts
  the folowing arguments:<BR>
    -image, -project_name, -app_name, -page_name, -cmd_name, -ctx_name
 </FONT>
 <SCRIPT>window.focus()</SCRIPT>
</if>
