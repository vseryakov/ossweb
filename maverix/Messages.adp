<master src="index">

<if @ossweb:cmd@ eq error><return></if>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_msg style=fieldset nohelp=1></formtemplate>
   <return>
</if>

<formtemplate id=form_msg>
<FIELDSET CLASS=osswebForm>
<LEGEND><%=[ossweb::html::title Messages]%></LEGEND>
<CENTER><formerror id=form_user></CENTER>
<TABLE WIDTH=100% BORDER=0>
<rowlast VALIGN=TOP>
 <TD><formlabel id=msg_id><BR><formwidget id=msg_id></TD>
 <TD><formlabel id=user_email><BR><formwidget id=user_email></TD>
 <TD><formlabel id=sender_email><BR><formwidget id=sender_email></TD>
 <TD><formlabel id=subject><BR><formwidget id=subject></TD>
</rowlast>
<rowlast>
 <TD ALIGN=RIGHT VALIGN=BOTTOM COLSPAN=4>
    <formwidget id=search>
    <formwidget id=reset>
 </TD>
</rowlast>
</TABLE>
</formtemplate>

<if @ossweb:cmd@ eq error or @messages:rowcount@ eq 0>
   </FIELDSET>
   <return>
</if>
<P>
<multipage name=messages>
<border style=default class2=osswebBorder1 border1=0 border2=0 cellspacing=1 cellpadding=2>
<rowfirst>
 <TH>From</TH>
 <TH>To</TH>
 <TH>Subject</TH>
 <TH>Date</TH>
</rowfirst> 
<multirow name=messages>
<row BGCOLOR=white VALIGN=TOP onMouseOverClass=osswebRow3 url=@messages.url@>
   <TD>@messages.sender_email@</TD>
   <TD>@messages.user_email@</TD>
   <TD>@messages.subject@</TD>
   <TD>@messages.create_date@</TD>
</row>
</multirow>
</border>
<multipage name=messages>
</FIELDSET>
