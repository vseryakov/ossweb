<if @ossweb:cmd@ eq error><%=[ossweb::conn msg]%><return></if>

<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/ossmon2.css"/>

<if @ossweb:cmd@ in alert>
   <HEAD>
     <LINK REL=STYLESHEET TYPE="text/css" HREF="/css/<%=[ossweb::conn project_name]%>.css"/>
     <TITLE>@title@: @device_host@</TITLE>
   </HEAD>
   <BODY STYLE="margin:3;">
   <border border2=0>
     <rowfirst>
      <TD COLSPAN=5 NOWRAP><%=[ossweb::html::title "OSSMON Device Info"]%></TD>
     </rowfirst>
     <TR VALIGN=TOP>
       <TD><%=[ossweb::html::font -type column_title Host]%><BR>@device_host@</TD>
       <TD><%=[ossweb::html::font -type column_title Object]%><BR>@device_name@</TD>
       <TD><%=[ossweb::html::font -type column_title Object]%><BR>@device_type@</TD>
       <TD><%=[ossweb::html::font -type column_title Location]%><BR>@location_name@</TD>
     </TR>
   </border>
   <%=[ossweb::html::title $title]%><BR><%=[ossweb::conn msg]%>
   <P>
   @html@
   </BODY>
   <return>
</if>

<master mode=lookup>

<if @ossweb:cmd@ ne edit>
   <help_title url=doc/manual.html#t14>OSSMON Devices</help_title>
   <formtemplate id=form_device>
   <border class=osswebForm>
   <TR VALIGN=TOP>
      <TD><formlabel id=device_name><BR><formwidget id=device_name><BR>
          <formlabel id=device_model><BR><formwidget id=device_model>
      </TD>
      <TD><formlabel id=device_type><BR><formwidget id=device_type></TD>
      <TD><formlabel id=device_vendor><BR><formwidget id=device_vendor></TD>
      <TD><formlabel id=description><BR><formwidget id=description><BR>
          <formlabel id=location_name><BR><formwidget id=location_name>
      </TD>
      <TD><formlabel id=object_type><BR><formwidget id=object_type></TD>
      <TD><formlabel id=pagesize><BR><formwidget id=pagesize></TD>
      <TD NOWRAP><formwidget id=show_disable> <B>Show Disabled</B></TD>
   </TR>
   <TR><TD COLSPAN=7 ALIGN=RIGHT>
       <formwidget id=search>
       <formwidget id=new>
       <formwidget id=reset>
       </TD>
   </TR>
   </border>
   </formtemplate>
   <P>
   <multipage name=devices>
   <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=2>
   <row type=plain underline=1 colspan=6>
     <TD WIDTH=10></TD>
     <TH>Device</TH>
     <TH>Location</TH>
     <TH>Type</TH>
     <TH>Objects</TH>
     <if @lookup_mode@ le 0>
     <TH>Alerts</TH>
     </if>
   </row>
   <multirow name=devices>
   <row VALIGN=TOP>
     <TD WIDTH=20>@devices.alert_icon@</TD>
     <TD CLASS=@devices.alert_class@ NOWRAP>@devices.url@</TD>
     <TD CLASS=LST>@devices.device_location@</TD>
     <TD CLASS=TST>@devices.device_type@ @devices.device_vendor_name@</TD>
     <TD CLASS=MST NOWRAP>@devices.device_objects@</TD>
     <if @lookup_mode@ le 0>
     <TD>@devices.alert_name@</TD>
     </if>
   </row>
   </multirow>
   </TABLE>
   <multipage name=devices>
   <return>
</if>

<if @device_id@ ne "">
  <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
  <TR><TD><formtab id=form_tab style=oval width=20% bgcolor=#96a8b7 bgcolor2=#cbd2d8></TD>
      <TD WIDTH=1% ><IMG SRC=@device_icon@></TD>
  </TR>
  </TABLE>
</if>

<SCRIPT>
function deviceModelLoad()
{
  var name = document.form_device.device_vendor_name.value;
  if(name == '') return;
  var type = document.form_device.device_type.value;
  var url = '<%=[ossweb::html::url device_models cmd models]%>&device_vendor_name='+escape(name) + '&device_type='+escape(type);
  formComboboxUpdate('device_model',url);
}

function deviceVendorInfo()
{
  var id = '', name = document.form_device.device_vendor_name ? document.form_device.device_vendor_name.value : '';
  if(name == '') id = document.form_device.device_vendor.value;
  if(id == '' && name == '') return;
  var w = window.open('<%=[ossweb::html::url -app_name contact companies cmd edit lookup:mode 2]%>&company_id='+id+'&company_name='+escape(name),'Vendor','@winopts@');
  w.focus();
}
</SCRIPT>

<formtemplate id=form_device style=fieldset>
<FIELDSET CLASS=osswebForm>
<LEGEND><%=[ossweb::html::title "Device Details #$device_id"]%></B></LEGEND>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=2>
<TR VALIGN=TOP>
   <TD><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=2>
       <TR><TD><formlabel id=device_name><BR><formwidget id=device_name></TD></TR>
       <TR><TD><formlabel id=description><BR><formwidget id=description></TD></TR>
       <TR><TD><formlabel id=device_serialnum><BR><formwidget id=device_serialnum></TD></TR>
   </TABLE>
   </TD>
   <TD><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=2>
       <TR><TD><formlabel id=device_type><BR><formwidget id=device_type></TD></TR>
       <TR><TD><formlabel id=device_vendor><BR>
           <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
           <TR><TD><formwidget id=device_vendor></TD><TD><formwidget id=device_vendor name=data></TD></TR>
           </TABLE>
           </TD>
       </TR>
       <TR><TD><formlabel id=device_model_name><BR><formwidget id=device_model_name></TD></TR>
       </TABLE>
   </TD>
   <TD><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=2>
       <TR><TD><formlabel id=device_host><BR><formwidget id=device_host></TD></TR>
       <TR><TD><formlabel id=device_software><BR><formwidget id=device_software></TD></TR>
       <TR><TD><formlabel id=priority><BR><formwidget id=priority></TD></TR>
       </TABLE>
   </TD>
   <TD><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=2>
       <TR><TD><formlabel id=device_address><BR><formwidget id=device_address></TD></TR>
       <TR><TD><formlabel id=device_parent><BR><formwidget id=device_parent></TD></TR>
       <TR><TD><formlabel id=disable_flag><BR><formwidget id=disable_flag></TD></TR>
       <if @alert_info@ ne "">
          <TR><TD><formlabel id=alert_info><BR><formwidget id=alert_info></TD></TR>
       </if>
       </TABLE>
    </TD>
</TR>
<if @device_id@ eq "">
<TR VALIGN=TOP>
   <TD COLSPAN=4>
      <formlabel id=objects><HR>
      <TABLE WIDTH=100% BORDER=0><TR>
      <formgroup id=objects>
      <TD>@formgroup.widget@ @formgroup.label@</TD>
      <if @formgroup.rownum@ not mod 10></TR><TR></if>
      </formgroup>
      </TR></TABLE>
   </TD>
</TR>
</if>
<if @tab@ in edit objects>
<TR VALIGN=BOTTOM>
   <TD COLSPAN=2><BR>
      <formwidget id=tools> <formwidget id=object>
      <formwidget id=lookup:select>
   </TD>
   <TD COLSPAN=2 ALIGN=RIGHT>
      <formwidget id=list>
      <formwidget id=update>
      <formwidget id=delete>
      <formwidget id=copy>
      <formwidget id=clear>
   </TD>
</TR>
</if>
<if @device_id@ gt 0 and @objects:rowcount@ gt 0>
<TR><TD COLSPAN=4>&nbsp;</TD></TR>
<TR CLASS=osswebSectionRow>
  <TD COLSPAN=4><SPAN CLASS=osswebFormLabel>Device Objects</SPAN></TD>
</TR>
<TR VALIGN=TOP>
   <TD COLSPAN=4>
     <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=2>
     <multirow name=objects>
     <row type=plain underline=1 VALIGN=TOP>
       <TD CLASS=ST NOWRAP>@objects.test@ @objects.chart_type@</TD>
       <TD CLASS=ST>@objects.type_name@</TD>
       <TD CLASS=ST>@objects.obj_name@ @objects.obj_stats@</TD>
       <TD CLASS=ST>@objects.poll_time@</TD>
       <TD>@objects.alert_name@</TD>
       <TD ALIGN=RIGHT>@objects.chart@</TD>
     </row>
     </multirow>
     </TABLE>
   </TD>
</TR>
</if>
</TABLE>
</FIELDSET>
</formtemplate>

<if @device_id@ eq ""><return></if>

<if @tab@ eq address>
   <formtemplate id=form_address></formtemplate>
   <return>
</if>

<if @tab@ eq property>
   <SCRIPT>
   function helpWin(url) {
      window.open(url,'Help','width=600,height=500,location=0,menubar=0,scrollbars=1');
   }
   function setProp(obj) {
     if(obj.selectedIndex <=0) {
       obj.form.value.value='';
       obj.form.property_id.value='';
       return;
     }
     window.location='<%=[ossweb::lookup::url cmd edit device_id $device_id tab property]%>&property_id='+obj.options[obj.selectedIndex].value;
   }
   </SCRIPT>
   <help_title url=doc/manual.html#t51>Device Properties</help_title>
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
   <multirow name=properties>
     <row type=plain underline=1>
      <TD>@properties.property_id@</TD>
      <TD><B>@properties.value@</B></TD>
      <TD>@properties.edit@</TD>
     </row>
   </multirow>
   </border>
   </formtemplate>
</if>

<if @tab@ eq children>
   <help_title url=doc/manual.html#t14>SubDevices</help_title>
   <border>
   <rowfirst underline=1 colspan=6>
     <TD WIDTH=10></TD>
     <TH>Device</TH>
     <TH>Location</TH>
     <TH>Type</TH>
     <TH>Monitors</TH>
     <TH>Alerts</TH>
   </rowfirst>
   <multirow name=devices>
   <row VALIGN=TOP>
     <TD WIDTH=20>@devices.alert_icon@</TD>
     <TD CLASS=@devices.alert_class@ NOWRAP>@devices.url@</TD>
     <TD CLASS=LST>@devices.device_location@</TD>
     <TD CLASS=TST>@devices.device_type@</TD>
     <TD CLASS=MST NOWRAP>@devices.device_objects@</TD>
     <TD>@devices.alert_name@</TD>
   </row>
   </multirow>
   </border>
</if>

<if @tab@ eq alert>
   <formtemplate id=form_alert>
    <if @alert_id@ eq "">
      <TABLE WIDTH=100% >
      <TR><TD><%=[ossweb::html::title "Device Alerts"]%></TD><TD COLSPAN=9 ALIGN=RIGHT><formwidget id=alert_status></TR>
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
