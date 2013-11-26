<master src="index">

<if @ossweb:cmd@ eq error><return></if>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_sender style=fieldset></formtemplate>
   <return>
</if>

<formtemplate id=form_sender>
<FIELDSET CLASS=osswebForm><LEGEND><%=[ossweb::html::title Senders]%></LEGEND>
<CENTER><formerror id=form_sender></CENTER>
<TABLE WIDTH=100% BORDER=0>
<rowlast VALIGN=TOP>
 <TD><formlabel id=sender_type><BR><formwidget id=sender_type></TD>
 <TD><formlabel id=sender_email><BR><formwidget id=sender_email></TD>
 <TD><formlabel id=user_email><BR><formwidget id=user_email></TD>
</rowlast>
<rowlast>
 <TD ALIGN=RIGHT VALIGN=BOTTOM COLSPAN=5>
    <formwidget id=search>
    <formwidget id=reset>
 </TD>
</rowlast>
</TABLE>
</formtemplate>

<if @ossweb:cmd@ eq error or @senders:rowcount@ eq 0>
   </FIELDSET>
   <return>
</if>
<P>
<multipage name=senders>
<border style=default class2=osswebBorder1 border1=0 border2=0 cellspacing=1 cellpadding=2>
<rowfirst>
 <TH>Type</TH>
 <TH>Email</TH>
 <TH>User</TH>
 <TH>Digest Date</TH>
 <TH>LastHit Date</TH>
</rowfirst> 
<multirow name=senders>
<row BGCOLOR=white VALIGN=TOP onMouseOverClass=osswebRow3 url=@senders.url@>
  <TD>@senders.sender_type@</TD>
  <TD>@senders.sender_email@</TD>
  <TD>@senders.user_email@</TD>
  <TD>@senders.digest_date@</TD>
  <TD>@senders.update_date@</TD>
</row>
</multirow>
</border>
<multipage name=senders>
</FIELDSET>
