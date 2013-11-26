<if @ossweb:cmd@ eq chart>
   @html@
   <return>
</if>

<master src="index">

<SCRIPT>
function chartSubmit(form,date) {
  document.forms[0].chart_date.value=date;
  var w = window.open('<%=[ossweb::html::url cmd chart]%>'+formExport(form),'Obj','@winopts@');
  w.focus();
}
function daySubmit(date,type) {
  chartSubmit(document.forms[0],date);
}
</SCRIPT>

<formtemplate id=form_chart>
<CENTER><formerror id=form_chart></formerror></CENTER>
<FIELDSET>
<LEGEND CLASS=osstitle>OSSMON Charts</LEGEND>
<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP>
  <TD>
    <formlabel id=start_date><BR><formwidget id=start_date><BR>
    <formlabel id=end_date><BR><formwidget id=end_date>
  </TD>
  <TD ALIGN=RIGHT>
    <calendar date=@chart_date@ datename=chart_date small=1 dayurltype=javascript dayurl=daySubmit>
  </TD>
</TR>
<TR><TD WIDTH=100% COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1 BORDER=0></TD></TR>
<TR VALIGN=TOP>
  <TD><formlabel id=type><BR><formwidget id=type></TD>
  <TD><formlabel id=objects><BR><formwidget id=objects></TD>
</TR>
<TR VALIGN=TOP>
  <TD COLSPAN=2><formlabel id=filter><BR><formwidget id=filter></TD>
</TR>
<TR>
  <TD COLSPAN=3 ALIGN=RIGHT>
    <formwidget id=cmd>
    <help_button>
  </TD>
</TR>
</TABLE>
</FIELDSET>
</formtemplate>

