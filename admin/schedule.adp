<master src="index">

<%=[ossweb::html::menu::admin -table t]%>

<if @task_id@ eq "">

<help_title>Task Schedule</help_title>

<border>
<rowfirst>
 <TH>@schedule:add@ Title</TH>
 <TH>Proc Name</TH>
 <TH>Server</TH>
 <TH>Time</TH>
 <TH>Last Run</TH>
 <TH>Next Run</TH>
</rowfirst>
<multirow name="schedule">
 <row onMouseOverClass=osswebRow3 url=@schedule.url@>
 <TD>@schedule.task_name@</TD>
 <TD>@schedule.task_proc@</TD>
 <TD>@schedule.task_server@</TD>
 <TD>@schedule.time@</TD>
 <TD>@schedule.last@</TD>
 <TD>@schedule.scheduled@</TD>
 </row>
</multirow>
</border>
<return>
</if>

<formtemplate id=form_task title="Task Schedule Details"></formtemplate>
