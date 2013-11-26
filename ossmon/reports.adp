<master src=@master@>

<if @print@ eq "">
   <help_title>Reports</help_title>
   <formtemplate id=form_report>
   <border>
   <last_row VALIGN=TOP>
     <TD><formlabel id=type><BR><formwidget id=type><P>
         <formlabel id=start_date append="&lt;BR&gt;" ><formwidget id=start_date append="&lt;BR&gt;" >
         <formlabel id=end_date append="&lt;BR&gt;" ><formwidget id=end_date append="&lt;BR&gt;" >
     </TD>
     <TD>
         <formlabel id=obj_id append="&lt;BR&gt;" ><formwidget id=obj_id append="&lt;BR&gt;" >
         <formlabel id=device_id append="&lt;BR&gt;" ><formwidget id=device_id append="&lt;BR&gt;" >
     </TD>
     <TD NOWRAP>
       <formlabel id=name append="&lt;BR&gt;" ><formwidget id=name append="&lt;BR&gt;" >
       <formlabel id=log_severity append="&lt;BR&gt;" ><formwidget id=log_severity append="&lt;BR&gt;" >
       <formlabel id=log_type append="&lt;BR&gt;" ><formwidget id=log_type append="&lt;BR&gt;" >
       <formlabel id=log_data append="&lt;BR&gt;" ><formwidget id=log_data append="&lt;BR&gt;" >
       <formlabel id=mask append="&lt;BR&gt;" ><formwidget id=mask append="&lt;BR&gt;" >
       <formlabel id=port append="&lt;BR&gt;" ><formwidget id=port append="&lt;BR&gt;" >
       <formlabel id=ipaddr append="&lt;BR&gt;" ><formwidget id=ipaddr append="&lt;BR&gt;" >
       <formlabel id=macaddr append="&lt;BR&gt;" ><formwidget id=macaddr append="&lt;BR&gt;" >
       <formlabel id=serialnum append="&lt;BR&gt;" ><formwidget id=serialnum append="&lt;BR&gt;" >
       <formlabel id=discover_count append="&lt;BR&gt;" ><formwidget id=discover_count append="&lt;BR&gt;" >
       <formlabel id=private_ip append="&lt;BR&gt;" ><formwidget id=private_ip append="&lt;BR&gt;" >
       <formlabel id=public_ip append="&lt;BR&gt;" ><formwidget id=public_ip append="&lt;BR&gt;" >
       <formlabel id=flows append="&lt;BR&gt;" ><formwidget id=flows append="&lt;BR&gt;" >
       <formlabel id=interval append="&lt;BR&gt;" ><formwidget id=interval append="&lt;BR&gt;" >
       <formwidget id=chart append="&nbsp;" ><formlabel id=chart append="&lt;BR&gt;" >
       <formwidget id=hourly append="&nbsp;" ><formlabel id=hourly append="&lt;BR&gt;" >
       <formwidget id=daily append="&nbsp;" ><formlabel id=daily append="&lt;BR&gt;" >
       <formwidget id=weekly append="&nbsp;" ><formlabel id=weekly append="&lt;BR&gt;" >
       <formwidget id=monthly append="&nbsp;" ><formlabel id=monthly append="&lt;BR&gt;" >
       <formwidget id=totally append="&nbsp;" ><formlabel id=totally append="&lt;BR&gt;" >
       <formwidget id=print append="&nbsp;" ><formlabel id=print append="&lt;BR&gt;" >
       <formwidget id=details append="&nbsp;" ><formlabel id=details append="&lt;BR&gt;" >
     </TD>
   </last_row>
   <last_row>
     <TD ALIGN=RIGHT COLSPAN=3>
       <formwidget id=search>
       <formwidget id=reset>
     </TD>
   </last_row>
   </border>
   </formtemplate>
<else>
   <CENTER>
   <SPAN CLASS=ossTitle>@report:title@ for @report:start@ - @report:end@</SPAN>
   </CENTER>
   <BR>
</if>

<if @ossweb:cmd@ eq search>
   <if @report:rowcount@ le 0 and @report:data@ eq "">
      <B>@report:nodata@</B>
      <return>
   </if>
   <if @report:rowcount@ gt 0>
   <if @report:style@ eq table>
   <border style=table class1=@report:class1@ class2=@report:class2@ cellspacing=@report:cellspacing@ cellpadding=@report:cellpadding@ border1=@report:border1@ border2=@report:border2@ width=@report:width@ >
   <multirow name=report header=@report:header@ norow=@report:norow@ underline=@report:underline@></multirow>
   </border>
   <else>
   <border border2=0 class1=@report:class1@ class2=@report:class2@ cellspacing=@report:cellspacing@ cellpadding=@report:cellpadding@ border1=@report:border1@ border2=@report:border2@ width=@report:width@ >
   <multirow name=report header=@report:header@ norow=@report:norow@ underline=@report:underline@></multirow>
   </border>
   </if>
   </if>
   @report:data@
</if>
