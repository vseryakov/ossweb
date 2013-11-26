<master mode=lookup>

<%=[ossweb::html::menu::admin -table t]%>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_group title="Group Details" info="@group_link@"></formtemplate>
   <if @group_id@ lt 0 or @group_id@ eq ""><return></if>
   <CENTER>

   <help_title page_name=acls>Access Permissions</help_title>
   <DIV STYLE="text-align:left;font-size:8pt;">
   Empty field means any value and will be replaced with *.<br>
   Action column contains link to the group the ACL belongs
   to or action icon if the the ACL belongs to the user directly.<br>
   Query may contain additional query parameters in form
   <B>name val name val ..</B> and will be applied for submitted query
   parameters.<BR>
   Handlers may contain proc handlers for query parameters in form
   <B>name proc name proc ...</B>. For each specified parameter proc function will be
   called with parameters name and value( proc { name value }),
   returning 0 for success or -1 on error.
   </DIV>
   <P>
   <formtemplate id=form_group_acls>
   <CENTER><formerror id=form_group_acls></CENTER>
   <border>
   <rowfirst>
   <th>Sort</th>
   <th>Project Name</th>
   <th>App Name</th>
   <th>Page Name</th>
   <th>Cmd Name</th>
   <th>Ctx Name</th>
   <th>Allow/Deny</th>
   <th>Query</th>
   <th>Handlers</th>
   <th>Action</th>
   </rowfirst>
   <rowlast valign=top>
   <td><formwidget id=precedence></td>
   <td><formwidget id=project_name></td>
   <td><formwidget id=app_name></td>
   <td><formwidget id=page_name></td>
   <td><formwidget id=cmd_name></td>
   <td><formwidget id=ctx_name></td>
   <td><formwidget id=value></td>
   <td><formwidget id=query></td>
   <td><formwidget id=handlers></td>
   <td align=right><formwidget id=cmd></td>
   </rowlast>
   <multirow name=acls>
   <row>
   <td>@acls.precedence@</td>
   <td>@acls.project_name@</td>
   <td>@acls.app_name@</td>
   <td>@acls.page_name@</td>
   <td>@acls.cmd_name@</td>
   <td>@acls.ctx_name@</td>
   <td>@acls.value@</td>
   <td>@acls.query@</td>
   <td>@acls.handlers@</td>
   <td align=right>@acls.remove@</td>
   </row>
   </multirow>
   </border>
   </formtemplate>
   <return>
</if>

<help_title>Groups</help_title>
<border>
<rowfirst>
  <TD>@groups:add@</TD>
  <TH>Group Name</TH>
  <TH>Short Name</TH>
  <TH>Description</TH>
</rowfirst>
<multirow name="groups">
<row onMouseOverClass=osswebRow3 url=@groups.url@ >
  <TD>@groups.precedence@</TD>
  <TD>@groups.group_name@</TD>
  <TD>@groups.short_name@</TD>
  <TD>@groups.description@</TD>
</row>
</multirow>
</border>
