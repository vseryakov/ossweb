<master mode=lookup>

<STYLE>
.preview {
  font-size: 8pt;
  padding: 2px;
  background-color: #FFFFFF;
}

.part {
  display:none;
  margin: 0px;
}

.code {
  background-color: #EEEEEE;
  padding: 0px;
  margin: 0px;
}

</STYLE>

<SCRIPT>
function crm(id)
{
  var obj = $(id);
  if(!obj) return;
  document.form_generator.table_skip.value += id + ' ';
  obj.parentNode.removeChild(obj);
}
</SCRIPT>

<%=[ossweb::html::menu::admin -table t]%>

<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR VALIGN=TOP>
  <TD><formtemplate id=form_generator style=fieldset class:last=None></formtemplate></TD>
  <TD WIDTH=20% >
      <DIV ID=PreviewTable CLASS=preview>@preview_table@</DIV>
      <DIV ID=PreviewDepend CLASS=preview>@preview_depend@</DIV>
      <DIV ID=PreviewBorder CLASS=preview>@preview_border@</DIV>
      <DIV ID=PreviewFormtab CLASS=preview>@preview_formtab@</DIV>
  </TD>
</TR>
</TABLE>

<if @ossweb:cmd@ eq generate>
   The following files have been created:<P>
   <UL>
   <LI>@adp@
   <LI>@tcl@
   <LI>@xql@
   </UL>
   Link to the application: <A HREF=@link@>@link@</A>
   <return>
</if>

<if @ossweb:cmd@ eq preview>
   <formtab id=form_tab style=oval>
   <TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0><TR><TD ID=Code CLASS=code></TD></TR></TABLE>

   <DIV ID=ADP CLASS=part><PRE>@adp@</PRE></DIV>
   <DIV ID=Tcl CLASS=part><PRE>@tcl@</PRE></DIV>
   <DIV ID=XQL CLASS=part><PRE>@xql@</PRE></DIV>
   <SCRIPT>varSet('Code', varGet('ADP'))</SCRIPT>
</if>
