<if @ossweb:cmd@ eq message>
   <formtemplate id=form_message></formtemplate>
   <return>
</if>

<master mode=lookup>

<if @mode@ le 0>
<%=[ossweb::html::menu::admin -table t]%>
</if>

<if @ossweb:cmd@ eq edit>

   <formtab id=form_tab style=oval>
   <P>
   <formtemplate id=form_user title="User Details" info="@user_link@" class:over=osswebFocusedRow></formtemplate>

   <if @user_id@ lt 0 or @user_id@ eq ""><return></if>
   <CENTER>

   <if @tab@ eq acl>
      <p>
      <TABLE WIDTH=100% BORDER=0>
      <TR><TD><%=[ossweb::html::title "Access Permissions"]%></TD>
      <TD ALIGN=RIGHT><help_image page_name="acls"></TD></TR>
      </TABLE>
      <%=[ossweb::html::font -type msg "Empty field means any value and will be replaced with *.<br>
      Action column contains link to the group the ACL belongs
      to or action icon if the the ACL belongs to the user directly.<br>
      Query may contain additional query parameters in form
      <B>name val name val ...</B> and will be applied for submitted query
      parameters.<BR>
      Handlers may contain proc handlers for query parameters in form
      <B>name proc name proc ...</B>. For each specified parameter proc function will be
      called with parameters name and value( proc { name value }),
      returning 0 for success or -1 on error."]%>

      <formtemplate id=form_user_acls>

      <CENTER><formerror id=form_user_acls></CENTER>
      <border>
      <rowfirst>
      <th>Group</th>
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
      <td>&nbsp;</td>
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
      <td>@acls.group_name@</td>
      <td>@acls.precedence@</td>
      <td>@acls.project_name@</td>
      <td>@acls.app_name@</td>
      <td>@acls.page_name@</td>
      <td>@acls.cmd_name@</td>
      <td>@acls.ctx_name@</td>
      <td>@acls.value@</td>
      <td>@acls.query@</td>
      <td>@acls.handlers@</td>
      <td align=right>@acls.action@</td>
      </row>
      </multirow>
      </border>
      </formtemplate>
      <return>
   </if>

   <if @tab@ ne edit and @tab@ ne "">
      <border style=curved4>
      <formtemplate id=form_prefs border_style=none class:first=none class:last=none ></formtemplate>
      </border>
   </if>

   </CENTER>
   <return>
</if>

<help_title>Users</help_title>
<formtemplate id=form_user>
 <border>
 <rowlast VALIGN=TOP>
  <TD><formlabel id=user_id><BR><formwidget id=user_id></TD>
  <TD><formlabel id=user_name><BR><formwidget id=user_name></TD>
  <TD><formlabel id=user_type><BR><formwidget id=user_type></TD>
  <TD><formlabel id=groups><BR><formwidget id=groups></TD>
  <TD><formlabel id=status><BR><formwidget id=status></TD>
 </rowlast>
 <rowlast VALIGN=TOP>
  <TD><formlabel id=first_name><BR><formwidget id=first_name></TD>
  <TD><formlabel id=last_name><BR><formwidget id=last_name></TD>
  <TD><formlabel id=user_email><BR><formwidget id=user_email></TD>
  <TD COLSPAN=2 ALIGN=RIGHT VALIGN=BOTTOM>
     <formwidget id=search>
     <formwidget id=reset>
     <formwidget id=add>
     <formwidget id=message>
  </TD>
 </rowlast>
 </border>

<if @ossweb:cmd@ eq error><return></if>
<P>
<multipage name=users>
<border>
 <rowfirst>
 <TH><formwidget id=form_sorting.user_type></TH>
 <TH><formwidget id=form_sorting.user_name></TH>
 <TH><formwidget id=form_sorting.full_name></TH>
 <TH><formwidget id=form_sorting.user_email></TH>
 <if @mode@ le 0>
 <TH><formwidget id=form_sorting.access_time></TH>
 <TH>Groups</TH>
 </if>
 </rowfirst>
 <multirow name="users">
 <row VALIGN=TOP>
 <TD>@users.type_name@<if @users.status@ ne active><BR>@users.status@</if></TD>
 <TD>@users.user_name@</TD>
 <TD>@users.full_name@</TD>
 <TD>@users.user_email@</TD>
 <if @mode@ le 0>
 <TD CLASS=osswebSmallText>@users.access_time@</TD>
 <TD CLASS=osswebSmallText>@users.groups@</TD>
 </if>
 </row>
 </multirow>
</border>
<multipage name=users>

</formtemplate>

