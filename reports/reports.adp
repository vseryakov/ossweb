<master src="index">

<if @ossweb:cmd@ ne edit>
  <helptitle>Report List</helptitle>
  <border>
  <rowfirst>
    <TH>@report:add@ Report Type</TH>
    <TH>Report Name</TH>
    <TH>XQL ID</TH>
    <TH>Version</TH>
  </rowfirst>
  <multirow name="reports">
   <row>
     <TD>@reports.report_type@</TD>
     <TD>@reports.report_name@</TD>
     <TD>@reports.xql_id@</TD>
     <TD>@reports.report_version@</TD>
   </row>
  </multirow>
  </border>
  <return>
</if>

<formtemplate id=form_report title="Report Details" info=@report_link@></formtemplate>

<if @report_id@ eq ""><return></if>

<formtab id=form_tab>

<P>

<if @tab@ eq summary>
  <H3>Form</H3><PRE>@form_script@</PRE><HR>
  <H3>Before Script</H3><PRE>@before_script@</PRE><HR>
  <H3>Eval Script</H3><PRE STYLE="background-color:#EEEEEE">@eval_script@</PRE><HR>
  <H3>After Script</H3><PRE>@after_script@</PRE>
</if>

<if @tab@ eq sql>
   <PRE>@before_script@</PRE>
   <return>
</if>

<if @tab@ in form before eval after>
   <formtemplate id=form_tcl notitle=1 no_first_row=1></formtemplate>
</if>
