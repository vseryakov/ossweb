<master mode=lookup>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_project border_style=fieldset border_title="Project Details"></formtemplate>

   <if @project_id@ gt 0>
     <helptitle>People involved in the Project</helptitle>

     <formtemplate id=form_users>
     <TABLE CLASS=osswebTable>
     <if @ossweb:ctx@ ne info>
     <rowfirst>
      <TH>User Name: <formwidget id=user_id></TH>
      <TH>Precedence: <formwidget id=precedence></TH>
      <TH>Role: <formwidget id=role></TH>
      <TH> &nbsp; <formwidget id=cmd></TH>
     </rowfirst>
     </if>
     <multirow name=users>
     <row type=plain underline=1>
       <TD>@users.user_name@</TD>
       <TD>@users.precedence@</TD>
       <TD>@users.role@</TD>
       <if @ossweb:ctx@ ne info>
       <TD>@users.edit@</TD>
       </if>
     </row>
     </multirow>
     </table>
     </formtemplate>
   </if>
   <return>
</if>

<STYLE>
.r {
  font-weight: bold;
  font-size: 8pt;
}
</STYLE>

<helptitle>Task/Problem Projects</helptitle>

<formtemplate id=form_search>
<border>
<rowfirst>
 <TD><formlabel id=project_name><BR><formwidget id=project_name></TD>
 <TD><formlabel id=status><BR><formwidget id=status></TD>
 <TD><formlabel id=type><BR><formwidget id=type></TD>
 <TD><formlabel id=user_name><BR><formwidget id=user_name></TD>
 <TD ALIGN=RIGHT VALIGN=BOTTOM><formwidget id=search> <formwidget id=reset> <formwidget id=add></TD>
</rowfirst>
</border>
</formtemplate>
<P>
<border>
<rowfirst>
 <TH>Name</TH>
 <TH>Type</TH>
 <TH>Status</TH>
 <TH>Description</TH>
 <TH>Responsible</TH>
</rowfirst>
<multirow name=projects>
 <row VALIGN=TOP>
  <TD>@projects.project_name@</TD>
  <TD>@projects.type@</TD>
  <TD>@projects.status_name@</TD>
  <TD>@projects.description@</TD>
  <TD><if @projects.owner_name@ ne "&nbsp;">
        <B>@projects.owner_name@</B><BR>
      </if>
      <group name=projects column=project_id>
         @projects.user_name@ <if @projects.role@ ne ""><SPAN CLASS=r>(@projects.role@)</SPAN></if></BR>
      </group>
  </TD>
 </row>
</multirow>
</border>
