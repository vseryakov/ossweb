<master src="index">

<if @ossweb:cmd@ eq error><return></if>

<if @ossweb:cmd@ eq edit>
   <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
   <TR><TD ALIGN=RIGHT><formtab id=form_tab style=text width=20% bgcolor=gray bgcolor2=#DDDDDD></TD></TR>
   </TABLE>
   <formtemplate id=form_user style=fieldset></formtemplate>
   <if @tab@ in white black gray>
      <formtemplate id=form_sender>
      <TABLE WIDTH=100% BORDER=0>
      <TR><TD CLASS=osswebTitle>Senders</TD>
          <TD ALIGN=RIGHT>
          <TABLE BORDER=0>
          <TD NOWRAP>Email/Domain:</TD>
          <TD NOWRAP><formwidget id=sender_email> <formwidget id=search> <formwidget id=add></TD>
          </TABLE>
          </TD>
      </TR>
      </TABLE>
      <multipage name=senders>
      <border style=default class2=osswebBorder1 border1=0 border2=0 cellspacing=1 cellpadding=2>
      <first_row>
      <TH><TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
          <TR><TD><B>Email</B></TD>
          <TD ALIGN=RIGHT NOWRAP>
           <B>Sort by:</B> 
           <A HREF=<%=[ossweb::html::url cmd edit user_email $user_email tab $tab sort 0]%>>Email</A> |
           <A HREF=<%=[ossweb::html::url cmd edit user_email $user_email tab $tab sort 1]%>>Domain</A> |
           <if @tab@ eq black>
           <A HREF=<%=[ossweb::html::url cmd edit user_email $user_email tab $tab sort 2]%>>Last Hit</A> |
           </if>
          </TD>
          </TR>
          </TABLE>
      </TH>
      <if @tab@ eq black>
      <TH WIDTH=1% NOWRAP>Last Hit Date</TH>
      </if>
      <TH WIDTH=1% NOWRAP>Actions: <formwidget id=clear></TH>
      </first_row>
      <multirow name=senders>
      <row BGCOLOR=white VALIGN=TOP onMouseOverClass=osswebRow3 url=@senders.url@>
        <TD>@senders.sender_email@</TD>
        <if @tab@ eq black>
        <TD NOWRAP>@senders.update_date@</TD>
        </if>
        <TD CLASS=small NOWRAP>@senders.edit@</TD>
      </row>
      </multirow>
      </border>
      </formtemplate>
      <multipage name=senders>
   </if>
   <if @tab@ eq messages>
      <if @msg_id@ ne "">
         <formtemplate id=form_msg style=fieldset nohelp=1></formtemplate>
         <return>
      </if>
      <help_title>Messages</help_title>
      <multipage name=messages>
      <border style=default class2=osswebBorder1 border1=0 border2=0 cellspacing=1 cellpadding=2>
      <first_row>
      <TH>Status</TH>
      <TH>From</TH>
      <TH>Subject</TH>
      <TH>Date</TH>
      <TH>Score</TH>
      <TD WIDTH=1% ALIGN=RIGHT CLASS=osswebSmallText NOWRAP>
         <A HREF=<%=[ossweb::html::url cmd forward.msg user_email $user_email tab $tab msg_id $msg_list sort 0 page $page]%>>Forward</A>
         <A HREF=<%=[ossweb::html::url cmd delete.msg user_email $user_email tab $tab msg_id $msg_list sort 0 page $page]%>>Drop</A>
         <A HREF=<%=[ossweb::html::url cmd spam.msg user_email $user_email tab $tab msg_id $msg_list sort 0 page $page]%>>Spam</A>
      </TD>
      </first_row> 
      <multirow name=messages>
      <row BGCOLOR=white VALIGN=TOP onMouseOverClass=osswebRow3 url=@messages.url@>
        <TD>@messages.msg_status@</TD>
        <TD>@messages.sender_email@</TD>
        <TD>@messages.subject@</TD>
        <TD>@messages.create_date@</TD>
        <TD>@messages.spam_score@ @messages.spam_status@</TD>
        <TD WIDTH=1% ALIGN=RIGHT CLASS=osswebSmallText NOWRAP>
           <A HREF=@messages.forward@>Forward</A>
           <A HREF=@messages.drop@>Drop</A>
           <A HREF=@messages.spam@>Spam</A>
        </TD>
      </row>
      </multirow>
      </border>
      <multipage name=messages>
   </if>
   <if @tab@ eq aliases>
      <formtemplate id=form_alias>
      <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
      <TR><TD ALIGN=RIGHT>Alias: <formwidget id=alias_email> <formwidget id=add></TD></TR>
      </TABLE>
      </formtemplate>
      <border style=default class2=osswebBorder1 border1=0 border2=0 cellspacing=1 cellpadding=2>
      <first_row>
      <TH>Email</TH>
      <TH WIDTH=1% >&nbsp;</TH>
      </first_row> 
      <multirow name=aliases>
      <row BGCOLOR=white VALIGN=TOP>
        <TD>@aliases.alias_email@</TD>
        <TD ALIGN=RIGHT>@aliases.delete@</TD>
      </row>
      </multirow>
      </border>
   </if>
   <if @tab@ in log>
     <TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
     <TR BGCOLOR=#CCCCCC>
        <TH>Date</TH>
        <TH>Sender</TH>
        <TH>Subject</TH>
        <TH>Spam Score</TH>
        <TH>Virus</TH>
        <TH>Reason</TH>
     </TR>
     <multirow name=log>
     <TR VALIGN=TOP BGCOLOR=white>
        <TD>@log.create_date@</TD>
        <TD>@log.sender_email@</TD>
        <TD>@log.subject@</TD>
        <TD>@log.spam_score@</TD>
        <TD>@log.virus_status@</TD>
        <TD>Dropped/@log.reason@</TH>
     </TR>
     </multirow>
     </TABLE>
     <return>
   </if>
   <return>
</if>

<formtemplate id=form_user>
<FIELDSET CLASS=osswebForm><LEGEND><%=[ossweb::html::title Users]%></LEGEND>
<CENTER><formerror id=form_user></CENTER>
<TABLE BORDER=0 WIDTH=100% >
<rowlast VALIGN=TOP>
 <TD><formlabel id=user_type><BR><formwidget id=user_type></TD>
 <TD><formlabel id=user_email><BR><formwidget id=user_email></TD>
 <TD><formlabel id=sender_digest_flag><BR><formwidget id=sender_digest_flag><BR>
     <formlabel id=anti_virus_flag><BR><formwidget id=anti_virus_flag>
 </TD>
</rowlast>
<rowlast>
 <TD ALIGN=RIGHT VALIGN=BOTTOM COLSPAN=5>
    <formwidget id=search>
    <formwidget id=reset>
    <formwidget id=new>
 </TD>
</rowlast>
</TABLE>
</formtemplate>

<if @ossweb:cmd@ eq error or @users:rowcount@ eq 0>
   </FIELDSET>
   <return>
</if>
<P>
<multipage name=users>
<border style=default class2=osswebBorder1 border1=0 border2=0 cellspacing=1 cellpadding=2>
<rowfirst>
 <TH>Type</TH>
 <TH>Email</TH>
 <TH>Digest Date</TH>
</rowfirst> 
<multirow name=users>
<row BGCOLOR=white VALIGN=TOP onMouseOverClass=osswebRow3 url=@users.url@>
  <TD>@users.user_type@</TD>
  <TD>@users.user_email@</TD>
  <TD>@users.digest_date@</TD>
</row>
</multirow>
</border>
<multipage name=users>
</FIELDSET>
