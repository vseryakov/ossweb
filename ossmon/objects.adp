<if @ossweb:cmd@ eq error><%=[ossweb::conn msg]%><return></if>

<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/ossmon2.css"/>

<if @ossweb:cmd@ in mibs>
   <A HREF=javascript:; onClick="window.find()">Find</A> <A HREF=javascript:window.close()>Close</A><HR>
   <DIV STYLE="height:520;overflow:auto;overflow-x:visible;overflow-y:auto;">
   <multirow name=oids>
    <A HREF="javascript:window.opener.document.form_object.elements['PROP:ossmon:snmp:oid'].value='@oids.oid@';window.close()">@oids.oid@</A>: @oids.module@<BR>
   </multirow>
   <DIV>
   <return>
</if>

<if @ossweb:cmd@ in chart ps netstat tail test fix alert config showrun>
   <HEAD>
     <LINK REL=STYLESHEET TYPE="text/css" HREF="/css/<%=[ossweb::conn project_name]%>.css"/>
     <TITLE>@title@: @obj_host@</TITLE>
   </HEAD>
   <BODY STYLE="margin:3;">
   <border border2=0>
     <rowfirst>
      <TD COLSPAN=5 NOWRAP><%=[ossweb::html::title "OSSMON Object Info"]%></TD>
     </rowfirst>
     <TR VALIGN=TOP>
       <TD><%=[ossweb::html::font -type column_title Host]%><BR>@obj_host@</TD>
       <TD><%=[ossweb::html::font -type column_title Object]%><BR>@obj_name@</TD>
       <TD><%=[ossweb::html::font -type column_title Object]%><BR>@obj_type@</TD>
       <TD><%=[ossweb::html::font -type column_title Device]%><BR>@device_name@ (@device_type@)</TD>
       <TD><%=[ossweb::html::font -type column_title Location]%><BR>@location_name@</TD>
     </TR>
   </border>
   <BR><%=[ossweb::html::title $title]%><BR>
   <%=[ossweb::conn msg]%><BR>
   @html@
   </BODY>
   <return>
</if>

<master mode=lookup>

<SCRIPT>
  function helpWin(url) {
    window.open(url,'Help','width=600,height=500,location=0,menubar=0,scrollbars=1');
  }
  function setProp(obj) {
    if(obj.selectedIndex<=0) {
      obj.form.value.value='';
      obj.form.property_id.value='';
      return;
    }
    window.location='<%=[ossweb::lookup::url cmd edit obj_id $obj_id tab property]%>&property_id='+obj.options[obj.selectedIndex].value;
  }
  function doTest(form) {
    if(form.obj_type.options[form.obj_type.selectedIndex].value == 'none') {
      alert('Choose Monitor Type');
      return;
    }
    var w=window.open('<%=[ossweb::html::url objects cmd test obj_id $obj_id]%>&obj_type='+form.obj_type.options[form.obj_type.selectedIndex].value,'Obj','@winopts@');
    w.focus();
  }
  function changeForm(form) {
    window.location='<%=[ossweb::lookup::url cmd edit obj_id $obj_id]%>'+
                    '&obj_type='+form.obj_type.options[form.obj_type.selectedIndex].value+
                    '&obj_name='+escape(form.obj_name.value)+
                    '&obj_host='+escape(form.obj_host.value)+
                    '&device_id='+form.device_id.value;
  }
</SCRIPT>

<if @obj_id@ ne "">
  <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
  <TR><TD ALIGN=LEFT><formtab id=form_tab style=oval bgcolor=#96a8b7 bgcolor2=#DDDDDD></TD>
      <TD WIDTH=1% ><IMG SRC=@device_icon@></TD>
  </TR>
  </TABLE>
</if>

<formtemplate id=form_object>
<FIELDSET CLASS=osswebForm>
<LEGEND><%=[ossweb::html::title "OSSMON Device Object Details #$obj_id for $device_name"]%></LEGEND>
<TABLE BORDER=0 WIDTH=100% CELLSPACING=3 CELLPADDING=0>
<TR VALIGN=TOP>
  <TD><formlabel id=obj_type><BR><formwidget id=obj_type></TD>
  <TD><formlabel id=poll_time><BR><formwidget id=poll_time></TD>
  <TD ROWSPAN=3>
     <if @obj_id@ gt 0><formlabel id=alert_time><BR><formwidget id=alert_time></if><P>
     <formwidget id=obj_chart>
  </TD>
</TR>
<TR VALIGN=TOP>
  <TD></TD>
</TR>
<TR VALIGN=TOP>
  <TD WIDTH=70% COLSPAN=2>
    <TABLE BORDER=0 WIDTH=90% HEIGHT=100%><TR><TD>
    <FIELDSET>
    <LEGEND><B>Attributes</B></LEGEND>
    <TABLE BORDER=0 WIDTH=100% HEIGHT=100% CELLSPACING=1 CELLPADDING=0>
    <TR><TD><formlabel id=obj_host></TD>
        <TD WIDTH=50>&nbsp;</TD>
        <TD><formwidget id=obj_host></TD>
        <TD ALIGN=RIGHT><formwidget id=obj_host name=info></TD>
    </TR>
    <TR><TD><formlabel id=obj_name></TD>
        <TD WIDTH=50>&nbsp;</TD>
        <TD><formwidget id=obj_name></TD>
        <TD ALIGN=RIGHT><formwidget id=obj_name name=info></TD>
    </TR>
    <TR><TD><formlabel id=priority></TD>
        <TD WIDTH=50>&nbsp;</TD>
        <TD><formwidget id=priority></TD>
        <TD ALIGN=RIGHT><formwidget id=priority name=info></TD>
    </TR>
    <TR><TD><formlabel id=disable_flag></TD>
        <TD WIDTH=50>&nbsp;</TD>
        <TD><formwidget id=disable_flag></TD>
        <TD ALIGN=RIGHT><formwidget id=disable_flag name=info></TD>
    </TR>
    <TR><TD><formlabel id=charts_flag></TD>
        <TD WIDTH=50>&nbsp;</TD>
        <TD><formwidget id=charts_flag></TD>
        <TD ALIGN=RIGHT><formwidget id=charts_flag name=info></TD>
    </TR>
    <formwidgets id=form_object pattern=PROP:>
    <if @tab@ ne edit and @widget.value@ eq "">
    <else>
    <TR>
      <TD><formlabel id=@widget.widget:id@></TD>
      <TD WIDTH=50>&nbsp;</TD>
      <TD><formwidget id=@widget.widget:id@></TD>
      <TD ALIGN=RIGHT><formwidget id=@widget.widget:id@ name=info></TD>
    </TR>
    </if>
    </formwidgets>
    </TABLE>
    </FIELDSET>
    </TD></TR></TABLE>
  </TD>
</TR>
<TR><TD COLSPAN=3>&nbsp;</TD></TR>
<TR>
  <TD COLSPAN=3>
  <TABLE WIDTH=100% BORDER=0>
  <TR><TD>
      <formwidget id=test>
      <formwidget id=tools>
      <formwidget id=chart>
      </TD>
      <TD ALIGN=RIGHT>
      <formwidget id=back>
      <formwidget id=update>
      <formwidget id=delete>
      <formwidget id=copy>
      <formwidget id=clear>
      <formwidget id=help>
      </TD>
  </TR>
  </TABLE>
  </TD>
</TR>
</TABLE>
</FIELDSET>
</formtemplate>

<if @obj_id@ eq ""><return></if>

<if @tab@ eq property>
  <help_title url=doc/manual.html#t51>Object Properties</help_title>
  <formtemplate id=form_property>
  <border border1=0>
  <rowfirst>
   <TH>Property ID</TH>
   <TH COLSPAN=2>Property Value</TH>
  </rowfirst>
  <TR>
   <TD NOWRAP><formwidget id=property>&nbsp;&nbsp;<formwidget id=property_id></TD>
   <TD NOWRAP><formwidget id=value> <formwidget id=value name=info></TD>
   <TD WIDTH=1% ><formwidget id=add></TD>
  </TR>
  <multirow name="properties">
    <row type=plain underline=1>
     <TD>@properties.property_id@</TD>
     <TD><B>@properties.value@</B></TD>
     <TD>@properties.edit@</TD>
    </row>
  </multirow>
  </border>
  </formtemplate>
</if>

<if @tab@ eq chart>
   <help_title>Performance Charts</help_title>
   <SCRIPT>
     function chartSubmit(form,date) {
       document.forms[1].chart_date.value=date;
       var w = window.open('<%=[ossweb::html::url cmd chart]%>'+formExport(form),'Obj','@winopts@');
       w.focus();
     }
     function daySubmit(date,type) {
       chartSubmit(document.forms[1],date);
     }
   </SCRIPT>
   <formtemplate id=form_chart>
   <CENTER><formerror id=form_chart></formerror></CENTER>
   <border>
   <last_row VALIGN=TOP>
    <TD><formlabel id=start_date><BR><formwidget id=start_date><BR>
        <formlabel id=end_date><BR><formwidget id=end_date><BR>
        <formwidget id=trend> <formlabel id=trend> &nbsp;&nbsp;
        <formwidget id=hide> <formlabel id=hide>
    </TD>
    <TD><formlabel id=chart_type><BR><formwidget id=chart_type><P>
        <formlabel id=filter><BR><formwidget id=filter>
    </TD>
    <TD><calendar date=@chart_date@ datename=chart_date small=1 dayurltype=javascript dayurl=daySubmit moveurl=@chart_url@></TD>
   </last_row>
   <last_row><TD ALIGN=RIGHT COLSPAN=3><formwidget id=chart></TD></last_row>
   </border>
   </formtemplate>
</if>

<if @tab@ eq alert>
   <formtemplate id=form_alert>
   <if @alert_id@ eq "">
     <TABLE WIDTH=100% >
     <TR><TD><%=[ossweb::html::title "Object Alerts"]%></TD><TD COLSPAN=9 ALIGN=RIGHT><formwidget id=alert_status></TR>
     <TABLE>
     <border>
     <rowfirst>
       <TH>Name</TH>
       <TH>Type</TH>
       <TH>Level</TH>
       <TH>Status</TH>
       <TH>Created</TH>
       <TH>Last Updated</TH>
       <TH>Alert Time</TH>
       <TH>Count</TH>
     </rowfirst>
     <multirow name=alerts>
     <row>
       <TD>@alerts.alert_name@</TD>
       <TD>@alerts.alert_type@</TD>
       <TD>@alerts.alert_level@</TD>
       <TD>@alerts.alert_status@</TD>
       <TD>@alerts.create_time@</TD>
       <TD>@alerts.update_time@</TD>
       <TD>@alerts.alert_time@</TD>
       <TD>@alerts.alert_count@</TD>
     </row>
     </multirow>
     </border>
   <else>
     <TABLE WIDTH=100% BORDER=0>
     <TR><TD COLSPAN=2><%=[ossweb::html::title "Alert Info"]%></TD></TR>
     <TR>
       <TD>
         <TABLE BORDER=0 WIDTH=100% CELLSPACING=0>
         <TR><TD><formlabel id=alert_status></TD><TD><formwidget id=alert_status></TD></TR>
         <TR><TD><formlabel id=alert_type></TD><TD><formwidget id=alert_type></TD></TR>
         <TR><TD><formlabel id=alert_level></TD><TD><formwidget id=alert_level></TD></TR>
         <TR><TD><formlabel id=alert_name></TD><TD><formwidget id=alert_name></TD></TR>
         <TR><TD><formlabel id=create_time></TD><TD><formwidget id=create_time></TD></TR>
         <TR><TD><formlabel id=update_time></TD><TD><formwidget id=update_time></TD></TR>
         <TR><TD><formlabel id=alert_time></TD><TD><formwidget id=alert_time></TD></TR>
         <TR><TD><formlabel id=alert_count></TD><TD><formwidget id=alert_count></TD></TR>
         </TABLE>
       </TD>
       <TD VALIGN=TOP>
         <TABLE BORDER=0 WIDTH=100% CELLSPACING=0>
         <TR><TD COLSPAN=2><%=[ossweb::html::font -type column_title "Properties"]%></TD></TR>
         <multirow name=properties>
         <row VALIGN=TOP>
           <TD>@properties.property_id@</TD>
           <TD><PRE>@properties.value@</PRE></TD>
         </row>
         </multirow>
         </TABLE>
       </TD>
     </TR>
     <last_row>
       <TD><formwidget id=back></TD>
       <TD ALIGN=RIGHT><formwidget id=update> <formwidget id=delete></TD>
     </last_row>
     </TABLE>
     <help_title>History</help_title>
     <multipage name=log>
     <border>
     <rowfirst><TH>Date</TH><TH>Type</TH><TH>Log</TH></rowfirst>
     <multirow name=log>
     <row VALIGN=TOP>
       <TD>@log.log_date@</TD>
       <TD CLASS=ossSmallText><PRE>@log.log_data@</PRE></TD>
     </row>
     </multirow>
     </border>
   </if>
   </formtemplate>
</if>
