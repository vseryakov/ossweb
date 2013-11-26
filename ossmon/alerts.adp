<master mode=lookup>

<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/ossmon2.css"/>

<if @ossweb:cmd@ eq info>
   <HEAD>
     <LINK REL=STYLESHEET TYPE="text/css" HREF="/css/<%=[ossweb::conn project_name]%>.css"/>
     <TITLE>#@alert_id@: @alert_name@</TITLE>
   </HEAD>
   <BODY>
   <border border2=0>
   <rowfirst>
     <TD COLSPAN=5 NOWRAP><%=[ossweb::html::title "Alert Info"]%></TD>
   </rowfirst>
   <TR VALIGN=TOP>
     <TD><%=[ossweb::html::font -type column_title Host]%><BR>@device_host@</TD>
     <TD><%=[ossweb::html::font -type column_title Device]%><BR>@device_name@</TD>
     <TD><%=[ossweb::html::font -type column_title Type]%><BR>@device_type@</TD>
     <TD><%=[ossweb::html::font -type column_title Location]%><BR>@device_location@</TD>
   </TR>
   </border>
   <BR><%=[ossweb::conn msg]%><BR>
   <B>@alert_time@: @alert_name@</B><BR>
   <PRE>@alert_data@</PRE>
   </BODY>
   <return>
</if>

<if @ossweb:cmd@ in edit refresh>
   <formtemplate id=form_alert title="Alert Details"></formtemplate>
   <if @properties:rowcount@ gt 0>
     <help_title>Properties</help_title>
     <border>
     <rowfirst>
       <TH>Name</TH>
       <TH>Value</TH>
     </rowfirst>
     <multirow name=properties>
       <row VALIGN=TOP>
         <TD>@properties.property_id@</TD>
         <TD CLASS=ossSmallText><PRE>@properties.value@</PRE></TD>
       </row>
     </multirow>
     </border>
   </if>
   <help_title>History</help_title>
   <multipage name=log>
   <border>
   <rowfirst>
     <TH>Date</TH>
     <TH>Type</TH>
   </rowfirst>
   <multirow name=log>
     <row VALIGN=TOP>
       <TD>@log.log_date@</TD>
       <TD CLASS=ossSmallText><PRE>@log.log_data@</PRE></TD>
     </row>
   </multirow>
   </border>
   <return>
</if>

<help_title url=doc/manual.html#t47>OSSMON Alerts</help_title>
<formtemplate id="form_filter">
<border>
 <last_row>
   <TD><formlabel id=device_name><BR><formwidget id=device_name></TD>
   <TD><formlabel id=alert_status><BR><formwidget id=alert_status></TD>
   <TD><formlabel id=alert_name><BR><formwidget id=alert_name></TD>
   <TD ALIGN=RIGHT><formwidget id=search>
                   <formwidget id=closeall>
                   <formwidget id=deleteall>
   </TD>
 </last_row>
</border>
</formtemplate>
<multipage name=alerts>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=2>
<row type=plain underline=1 colspan=10>
  <TD WIDTH=10></TD>
  <TH>Device</TH>
  <TH>Status</TH>
  <TH>Name</TH>
  <TH>Type</TH>
  <TH>Level</TH>
  <TH>Created</TH>
  <TH>Last Updated</TH>
  <TH>Alert Time</TH>
  <TH>Alert Count</TH>
</row>
<multirow name=alerts>
<row onMouseOverClass=osswebRow3 url=@alerts.url@ VALIGN=TOP>
  <TD WIDTH=10>
     <if @alerts.alert_count@ gt 0>
     <if @alerts.alert_level@ eq Warning><IMG SRC=/img/squares/orange.gif BORDER=0></if>
     <if @alerts.alert_level@ eq Critical><IMG SRC=/img/squares/pink.gif BORDER=0></if>
     <if @alerts.alert_level@ eq Advise><IMG SRC=/img/squares/yellow.gif BORDER=0></if>
     <if @alerts.alert_level@ eq Error><IMG SRC=/img/squares/red.gif BORDER=0></if>
     </if>
  </TD>
  <TD CLASS=ossSmallText>@alerts.device_name@</TD>
  <TD CLASS=ossSmallText>@alerts.alert_status@</TD>
  <TD><SPAN <if @alerts.alert_level@ eq Error>CLASS=AEST</if>
            <if @alerts.alert_level@ eq Critical>CLASS=ARST</if>
            <if @alerts.alert_level@ eq Advise>CLASS=AAST</if>
            <if @alerts.alert_level@ eq Warning>CLASS=AWST</if> >
     @alerts.alert_name@
     </SPAN>
  </TD>
  <TD CLASS=ossSmallText>@alerts.alert_type@</TD>
  <TD CLASS=ossSmallText>@alerts.alert_level@</TD>
  <TD CLASS=ossSmallText>@alerts.create_time@</TD>
  <TD CLASS=ossSmallText>@alerts.update_time@</TD>
  <TD CLASS=ossSmallText>@alerts.alert_time@</TD>
  <TD CLASS=ossSmallText>@alerts.alert_count@</TD>
</row>
</multirow>
</TABLE>
<multipage name=alerts>
