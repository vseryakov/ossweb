<if @ossweb:cmd@ eq error>
   <%=[ossweb::conn msg]%>
   <return>
</if>

<template name=form_calendar>
   <formtemplate id=form_calendar>
   <TABLE WIDTH=100% BORDER=0 CELLPADDING=3>
     <TR><TD><formlabel id=cal_date></TD>
         <TD COLSPAN=2><formwidget id=cal_date></TD>
     </TR>
     <TR><TD><formlabel id=cal_time></TD>
         <TD COLSPAN=2><formwidget id=cal_time></TD>
     </TR>
     <TR><TD><formlabel id=duration></TD>
         <TD COLSPAN=2><formwidget id=duration> <formwidget id=duration_type></TD>
     </TR>
     <TR><TD><formlabel id=subject></TD>
         <TD COLSPAN=2><formwidget id=subject></TD>
     </TR>
     <TR><TD><formlabel id=description></TD>
         <TD COLSPAN=2><formwidget id=description></TD>
     </TR>
     <TR><TD><formlabel id=repeat></TD>
         <TD COLSPAN=2><formwidget id=repeat></TD>
     </TR>
     <TR><TD><formlabel id=type></TD>
         <TD COLSPAN=2><formwidget id=type></TD>
     </TR>
     <TR HEIGHT=1><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1></TD></TR>
     <TR VALIGN=TOP>
        <TD><formlabel id=remind><BR><formwidget id=remind></TD>
        <TD><formlabel id=remind_email><BR><formwidget id=remind_email></TD>
        <TD><formlabel id=remind_type><BR><formwidget id=remind_type></TD>
     </TR>
     <TR HEIGHT=1><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1></TD></TR>
     <TR>
        <TD COLSPAN=3 ALIGN=RIGHT><formwidget id=notify><formlabel id=notify></TD>
     </TR>
     <TR VALIGN=TOP>
        <TD><formlabel id=users><BR><formwidget id=users></TD>
        <TD COLSPAN=2><formlabel id=groups><BR><formwidget id=groups></TD>
     </TR>
     <TR><TD COLSPAN=3 ALIGN=RIGHT NOWRAP>
          <if @cal_id@ ne ""><formwidget id=update><else><formwidget id=add></if>
          <formwidget id=delete>
          <if @cal_id@ ne ""><formwidget id=new></if>
          <formwidget id=close>
          <helpbutton>
         </TD>
     </TR>
   </TABLE>
   </formtemplate>
</template>

<if @ossweb:cmd@ eq show>
   <CENTER>
   <B>@user_name@<BR>@WeekDay@, @MonthName@ @Day@ @Year@ @cal_time@<BR>@subject@</B>
   </CENTER>
   <P>
   <TABLE BORDER=0 STYLE="border: 1px solid #000000" WIDTH=100% CELLSPACING=0>
   <TR><TD><PRE>@description@</PRE></TD></TR>
   </TABLE>
   <P>
   <FONT SIZE=1 COLOR=gray>
   <if @duration@ ne "">
      Duration @duration@<BR>
   </if>
   <if @type@ ne Normal>
     This event is <B>@type@</B><BR>
   </if>
   <if @remind_seconds@ ne "">
      <if @repeat@ ne None>@repeat@<else>@remind_type@</if> reminder will be sent before <%=[ossweb::date uptime $remind_seconds]%><BR>
   </if>
   <if @remind_email@ ne "">
      Send reminder also to <B>@remind_email@</B><BR>
   </if>
   <if @repeat@ ne None>
      Repeat event @repeat@<B><BR>
   </if>
   <if @update_user@ ne "" and @update_user@ ne @user_id@>
      Updated by <B>@update_user_name@</B> on <B>@update_time@</B><BR>
   </if>
   <if @remind_args@ ne "">
      <BR>Reminder parameters: <UL>@remind_args@</UL>
   </if>
   </FONT>
   <return>
</if>

<if @ossweb:cmd@ eq edit and @ossweb:ctx@ eq reminder>
   <CENTER><B>Reminder has been created</B></CENTER>
   <script>setTimeout('window.close()',2000)</script>
   <return>
</if>

<master mode=lookup>

<if @ossweb:cmd@ eq reminder>
    <formerror id=form_calendar>
    <FIELDSET CLASS=osswebForm>
    <LEGEND><ossweb:title>Calendar Reminder</ossweb:title></LEGEND>
    <include type=template name=form_calendar>
    </FIELDSET>
    <return>
</if>

<if @ossweb:cmd@ eq edit>
   <TABLE BORDER=0 WIDTH=100% >
   <TR>
     <TD><%=[ossweb::html::title "Calendar Details for $user_name, $WeekDay, [ossweb::date monthName $Month] $Day $Year"]%></B></TD>
     <TD ALIGN=RIGHT NOWRAP>
        <%=[ossweb::html::link -text Week cmd view type week date $date user_id $user_id]%> |
        <%=[ossweb::html::link -text Month cmd view type month date $date user_id $user_id]%>
     </TD>
   </TR>
   <TR><TD COLSPAN=2 ALIGN=CENTER><formerror id=form_calendar></TD></TR>
   <TR VALIGN=TOP>
     <TD WIDTH=50% >
       <TABLE WIDTH=100% BORDER=0>
       <multirow name=entries>
        <row type=plain underline=1>
          <TD WIDTH=1% >@entries.time@</TD>
          <TD>@entries.subject@</TD>
          <TD ALIGN=RIGHT>@entries.duration@ @entries.repeat@</TD>
        </row>
       </multirow>
       </TABLE>
       <if @entries:rowcount@ eq 0>No entries<HR></if>
     </TD>
     <TD WIDTH=10% >
        <FIELDSET CLASS=osswebForm>
        <LEGEND><ossweb:title>@form_calendar.title@</ossweb:title></LEGEND>
        <include type=template name=form_calendar>
        </FIELDSET>
     </TD>
   </TR>
   <TR><TD ALIGN=RIGHT COLSPAN=2><calendar small=1 selected=1 dayurl=@DayUrl@ moveurl=@DayUrl@ type=month date=@date@></TD></TR>
   </border>
   <return>
</if>

<formtemplate id=form_jump>
<TABLE BORDER=0 WIDTH=100% CELLSPACING=0>
<TR VALIGN=TOP>
  <TD WIDTH=1% ><formwidget id=date2></TD>
  <TD><formwidget id=cmd></TD>
  <TD ALIGN=RIGHT><formwidget id=user_id></TD>
</TR>
</TABLE>
</formtemplate>

<calendar date=@date@ dayurl=@DayUrl@ moveurl=@MoveUrl@ type=@type@ data=calendar>
