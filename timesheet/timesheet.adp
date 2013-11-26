<master src=index>

<if @admin@ eq 0>
  <formtemplate id=form_user>
  <TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0>
   <TR><TD ALIGN=RIGHT><formlabel id=user_id>: <formwidget id=user_id></TD></TR>
  </TABLE>
  </formtemplate>
</if>

<if @ossweb:cmd@ eq week>
   <formtemplate id=form_timesheet>
   <border border2=0>
   <rowfirst>
     <TD COLSPAN=7><%=[ossweb::html::form_title $week_title]%></TD>
   </rowfirst>
   <TR>
     <TD><formlabel id=user_name><BR><formwidget id=user_name></TD>
     <TD><formlabel id=department><BR><formwidget id=department></TD>
   </TR>
   <TR><TD COLSPAN=7>&nbsp;</TD></TR>
   <rowfirst>
      <TH>Day of Week</TH>
      <TH>Hour Code</TH>
      <TH>Job# /Sub Job#</TH>
      <TH>Cost Code</TH>
      <TH>Start</TH>
      <TH>Hours</TH>
   </rowfirst>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $sun_title]%></TD></rowlast>
   <list name=sun_list>
    <TR><TD>&nbsp;</TD>@sun_list:item@</TR>
   </list>
   <TR><TD COLSPAN=7><HR></TD></TR>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $mon_title]%></TD></rowlast>
   <list name=mon_list>
    <TR><TH>&nbsp;</TH>@mon_list:item@</TR>
   </list>
   <TR><TD COLSPAN=7><HR></TD></TR>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $tue_title]%></TD></rowlast>
   <list name=tue_list>
    <TR><TD>&nbsp;</TD>@tue_list:item@</TR>
   </list>
   <TR><TD COLSPAN=7><HR></TD></TR>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $wed_title]%></TD></rowlast>
   <list name=wed_list>
    <TR><TD>&nbsp;</TD>@wed_list:item@</TR>
   </list>
   <TR><TD COLSPAN=7><HR></TD></TR>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $thu_title]%></TD></rowlast>
   <list name=thu_list>
    <TR><TD>&nbsp;</TD>@thu_list:item@</TR>
   </list>
   <TR><TD COLSPAN=7><HR></TD></TR>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $fri_title]%></TD></rowlast>
   <list name=fri_list>
    <TR><TD>&nbsp;</TD>@fri_list:item@</TR>
   </list>
   <TR><TD COLSPAN=7><HR></TD></TR>
   <rowlast><TD COLSPAN=7><%=[ossweb::html::form_title $sat_title]%></TD></rowlast>
   <list name=sat_list>
    <TR><TD>&nbsp;</TD>@sat_list:item@</TR>
   </list>
   <TR><TD COLSPAN=4></TD><TD ALIGN=RIGHT><B>Total</B></TD><TD ALIGN=RIGHT><B>@total@</B></TD></TR>
   </border>
   </formtemplate>
   <return>
</if>

<SCRIPT LANGUAGE=JavaScript>
var tsList = new Array();
@ts_list@
function tsUpdate(form) {
   form.costcode_id.options.length = 0;
   val = tsList[form.job_id.options[form.job_id.selectedIndex].value];
   if(!val) return;
   val_list = val.split("&");
   for(i = 0;i < val_list.length;i++) {
     itm_list = val_list[i].split("|");
     form.costcode_id.options[i] = new Option(itm_list[1],itm_list[0]);
   }
}
</SCRIPT>

<formtemplate id=form_timesheet>
<CENTER><formerror id=form_timesheet></CENTER>
<FIELDSET>
<LEGEND><%=[ossweb::html::title $day_title]%></LEGEND>
<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP>
  <TD><formlabel id=user_name><BR><formwidget id=user_name></TD>
  <TD><formlabel id=department><BR><formwidget id=department></TD>
  <TD><formlabel id=week><BR><formwidget id=week></TD>
</TR>
<TR><TD COLSPAN=2>&nbsp;</TR>
</TABLE>
<P>
<CENTER><formerror id=form_hour></CENTER>
<border border1=0 border2=0>
<rowfirst>
  <TH>Hour Code<BR><formwidget id=hour_code></TH>
  <TH>Job #/Sub Job#<BR><formwidget id=job_id></TH>
  <TH>Cost code<BR><formwidget id=costcode_id></TH>
  <TH>Start<BR><formwidget id=ts_time></TH>
  <TH>Hours<BR><formwidget id=hours></TH>
  <TH><formwidget id=add></TH>
</rowfirst>
<if @ts_date@ ne "">
  <multirow name=timesheets>
  <row underline=1 type=plain>
    <TD>@timesheets.edit@&nbsp;@timesheets.type_name@</TD>
    <TD>@timesheets.job_name@</TD>
    <TD>@timesheets.costcode_name@</TD>
    <TD>@timesheets.ts_time@</TD>
    <TD COLSPAN=2>@timesheets.hours@</TD>
  </row>
  </multirow>
  <TR><TD COLSPAN=4><B>Total</B></TD><TD COLSPAN=2><B>@total@</B></TD></TR>
</if>
</border>
</FIELDSET>
</formtemplate>
