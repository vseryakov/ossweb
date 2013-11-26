Subject: Maverix Anti-Spam: @messages:rowcount@ Message(s) pending verification
From: @maverix_email@
To: @user_email@
Errors-To: @maverix_email@
MIME-Version: 1.0
Content-Type: multipart/alternative; boundary="@boundary@"

<if 0 eq 1>
--@boundary@
Content-Type: text/plain

The following messages are awaiting your decision whether to permit or deny
their delivery.Use Pending Messages Inbox [@Url@/User.oss?c=c&u=@user_email@&d=@digest_id@]
to manage senders and/or messages.

<multirow name=messages>
-- @messages.create_date@ ----------------------------
From:        @messages.sender_email@: @messages.subject:text@
<if @messages.attachments@ ne "">
Attachments: @messages.attachments@
</if>
Text:        @messages.body:text@
</multirow>

--
Maverix Systems
http://www.maverixsystems.com

Preferences: @Url@/User.oss?c=p&u=@user_email@&d=@digest_id@
Pending Messages: @Url@/User.oss?c=v&u=@user_email@&d=@digest_id@
To request your Digest at any time: @Url@/index.oss
Maverix User Guide: http://www.maverixsystems.com/maverixuserguide.htm
</if>

--@boundary@
Content-Type: text/html


<HEAD>
<STYLE>
  body {
    font-size: 10pt;
  }
  td, th {
    font-size: 9pt;
    color: black;
  }
  a {
    font-size: 8pt;
    color: blue;
  }
  aa {
    font-size: 10pt;
    font-weight: bold;
    color: black;
  }
  input {
    font-size: 8pt;
    border-width: 1; 
    border-color: #DDDDDD; 
    background-color: #CCCCCC;
  }
  body {
    color: black;
  }
</STYLE>
</HEAD>
<BODY BGCOLOR=white>
The following messages are awaiting your decision whether to permit or deny
their delivery. 
Use <A HREF=@Url@/User.oss?c=c&u=@user_email@&d=@digest_id@ CLASS=aa TARGET=MVRX>Pending Messages Inbox</A>
to manage senders and/or messages.

<BR>&nbsp;
<FORM METHOD=POST ACTION=@Url@/User.oss TARGET=MRVX>
<INPUT TYPE=HIDDEN NAME=u VALUE=@user_email@>
<INPUT TYPE=HIDDEN NAME=d VALUE=@digest_id@>
<TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
<TR BGCOLOR=#CCCCCC>
   <TD WIDTH=1% >&nbsp;</TD>
   <TD><TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELPADDING=0>
       <TR><TH>Sender</TH>
           <TD ALIGN=RIGHT>
              <INPUT TYPE=SUBMIT NAME=c VALUE="Permit Checked"> &nbsp;
              <INPUT TYPE=SUBMIT NAME=c VALUE="Block Checked">
           </TD>
       </TR>
       </TABLE>
   </TD>
   <TD><TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELPADDING=0>
       <TR><TH>Subject</TH>
           <TD ALIGN=RIGHT>
              <INPUT TYPE=SUBMIT NAME=c VALUE="Forward Checked"> &nbsp;
              <INPUT TYPE=SUBMIT NAME=c VALUE="Drop Checked">
           </TD>
       </TR>
      </TABLE>
   </TD>
   <TH>Date</TH>
   <TD><TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELPADDING=0>
       <TR><TH>Text</TH>
           <TD ALIGN=RIGHT>
              <INPUT TYPE=SUBMIT NAME=c VALUE="View Pending Messages">
           </TD>
       </TR>
      </TABLE>
   </TD>
   <TD WIDTH=1% >SPAM Score</TD>
</TR>
<multirow name=messages>
<TR VALIGN=TOP BGCOLOR=white>
   <TD WIDTH=1% ><INPUT TYPE=checkbox NAME=i VALUE="@messages.sender_email@ @messages.msg_id@"></TD>
   <TD>@messages.sender@</TD>
   <TD>@messages.subject@</TD>
   <TD>@messages.create_date@</TD>
   <TD>@messages.body@
       <if @messages.attachments@ ne ""><BR><B>Attachments:</B> @messages.attachments@</if>
   </TD>
   <TD>@messages.spam_score@</TD>
</TR>
</multirow>
</TABLE>
</FORM>
<P>
--<BR>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR>
<TD>
Maverix Systems<BR>
http://www.maverixsystems.com
</TD>
<TD ALIGN=RIGHT>
<A HREF=@Url@/User.oss?c=p&u=@user_email@&d=@digest_id@ CLASS=aa TARGET=MVRX>Preferences</A><BR>
<A HREF=@Url@/User.oss?c=v&u=@user_email@&d=@digest_id@ CLASS=aa TARGET=MVRX>Pending Messages</A><BR>
<A HREF=http://www.maverixsystems.com/maverixuserguide.htm CLASS=aa TARGET=MVRX>Maverix User Guide</A><BR>
<A HREF=@Url@/index.oss CLASS=aa TARGET=MVRX>Request your Digest at any time</A>
</TD>
</TR>
</TABLE>
</BODY>
--@boundary@--
