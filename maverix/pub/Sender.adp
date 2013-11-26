<master src=master>

<P>

<if @messages:rowcount@ eq 0>
   <TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
   <TR BGCOLOR=#CCCCCC><TD>You do not have any unverified recipients</TD></TR>
   </TABLE>
   <return>
</if>

You have recently sent an email message to address(es) specified below.
In order to have your message(s) delivered, click on <B>Verify</B> link
for each email address:<P>

<TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
<TR BGCOLOR=#CCCCCC>
   <TH WIDTH=1% >&nbsp;</TH>
   <TH>Recipient</TH>
</TR>
<multirow name=messages>
<TR VALIGN=TOP BGCOLOR=white>
   <TD><A HREF=@messages.rcpt_verify@>Verify</A></TD>
   <TD>@messages.user_email@</TD>
</TR>
</multirow>
</TABLE>

Once you have verified, your E-mail will be allowed to pass
through and you will be put on list of verified addresses and you will
not have to go through this process again.
