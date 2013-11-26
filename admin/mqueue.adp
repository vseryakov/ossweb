<master src="index">

<%=[ossweb::html::menu::admin -table t]%>

<if @ossweb:cmd@ ne edit>

<formtemplate id=form_mqueue>

<help_title>Message Queue</help_title>
<CENTER><formerror id=form_mqueue></CENTER>
<border>
<last_row VALIGN=TOP>
 <TD><%=[ossweb::html::font -type column_title "ID"]%><BR>
 <formwidget id=message_id></TD>
 <TD><%=[ossweb::html::font -type column_title "Type"]%><BR>
 <formwidget id=message_type></TD>
 <TD><%=[ossweb::html::font -type column_title "Sent Flag"]%><BR>
 <formwidget id=sent_flag></TD>
 <TD COLSPAN=2><%=[ossweb::html::font -type column_title "Created"]%><BR>
 <formwidget id=create_date></TD>
</last_row>
<last_row VALIGN=TOP>
 <TD><%=[ossweb::html::font -type column_title "To"]%><BR>
 <formwidget id=rcpt_to></TD>
 <TD><%=[ossweb::html::font -type column_title "From"]%><BR>
 <formwidget id=mail_from></TD>
 <TD><%=[ossweb::html::font -type column_title "Subject"]%><BR>
 <formwidget id=subject></TD>
 <TD><%=[ossweb::html::font -type column_title "Error Msg"]%><BR>
 <formwidget id=error_msg></TD>
 <TD ALIGN=RIGHT VALIGN=BOTTOM>
 <formwidget id=search> &nbsp;
 <formwidget id=reset></TD>
</last_row>
</border>
</formtemplate>

<if @ossweb:cmd@ eq error><return></if>

<multipage name=mqueue>
<border>
<rowfirst>
 <TH>ID</TH>
 <TH>Type</TH>
 <TH>Created</TH>
 <TH>Sent</TH>
 <TH>To</TH>
 <TH>From</TH>
 <TH>Subject</TH>
 <TH>Error</TH>
</rowfirst>
<multirow name=mqueue>
 <row VALIGN=TOP onMouseOverClass=osswebRow3 url=@mqueue.url@>
 <TD>@mqueue.message_id@</TD>
 <TD>@mqueue.message_type@</TD>
 <TD>@mqueue.create_date@</TD>
 <TD>@mqueue.sent_flag@</TD>
 <TD>@mqueue.rcpt_to@</TD>
 <TD>@mqueue.mail_from@</TD>
 <TD>@mqueue.subject@</TD>
 <TD>@mqueue.error_msg@</TD>
 </row>
</multirow>
</border>
<multipage name=mqueue>
<return>
</if>

<formtemplate id=form_mqueue title="Message Details"></formtemplate>
