<master src=master>

<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR><TD ALIGN=RIGHT><formtab id=form_tab tab=cmd style=text width=20% bgcolor=gray bgcolor2=#DDDDDD></TD></TR>
<TR><TD HEIGHT=1 BGCOLOR=black><IMG SRC=/img/misc/pixel.gif BORDER=0 WIDTH=100% HEIGHT=1></TD></TR>
</TABLE>
<P>
<if @cmd@ in p pu>
   <FIELDSET>
   <LEGEND CLASS=osswebFormTitle>Maverix Preferences</LEGEND>
   <formtemplate id=form_prefs>
   <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=1>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Email:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=user_email></TD>
   </TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Maverix Account Type:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formgroup id=user_type>@formgroup.widget@ @formgroup.label@<BR></formgroup></TD>
   </TR>
   <TR><TD COLSPAN=3 ALIGN=RIGHT>
       <FONT COLOR=gray>
       Default: <%=[ossweb::decode [ossweb::config maverix:user:type] VRFY Hold Pass]%>
       </FONT>
       </TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Digest with unverified messages/senders will be sent every:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=digest_interval></TD>
   </TR>
   <TD><TD COLSPAN=3 ALIGN=RIGHT>
       <FONT COLOR=gray>
       Default: <%=[ossweb::date uptime [ossweb::config maverix:user:interval]]%>
       </FONT>
       </TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Digest will be sent within this period of day:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD>From (HH:MM): <formwidget id=digest_start> 
           To (HH:MM):<formwidget id=digest_end>
       </TD>
   </TR>
   <TR><TD COLSPAN=3 ALIGN=RIGHT>
       <FONT COLOR=gray>
       Default: <%=[ossweb::config maverix:digest:start]%> - 
                <%=[ossweb::config maverix:digest:end]%>
       </FONT>
       </TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Sender Self-Verification:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formgroup id=sender_digest_flag>@formgroup.widget@ @formgroup.label@<BR></formgroup></TD>
   </TR>
   <TR><TD COLSPAN=3 ALIGN=RIGHT>
       <FONT COLOR=gray> Default: <%=[ossweb::decode [ossweb::config maverix:sender:self] t Yes No]%></FONT>
       </TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Anti-Virus Verification:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formgroup id=anti_virus_flag>@formgroup.widget@ @formgroup.label@<BR></formgroup></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Number of Emails per page to show in White/Black/Gray lists:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=page_size></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Size of the body preview text in the digest:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=body_size></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Message Spam Options:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formgroup id=spam_status>@formgroup.widget@ @formgroup.label@<BR></formgroup></TD>
   </TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>&nbsp;</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formgroup id=spam_autolearn_flag>@formgroup.widget@ @formgroup.label@<BR></formgroup></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Automatically forward message if SA score is below:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=spam_score_white></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Automatically drop message if SA score is above:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=spam_score_black></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>Automatically drop message if subject matches regexp:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><formwidget id=spam_subject></TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD WIDTH=1% NOWRAP CLASS=field>User name and password for logging into Maverix at any time:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD>User Name:<BR><formwidget id=user_name><BR>
           Password:<BR><formwidget id=password>
       </TD>
   </TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR><TD COLSPAN=3 HEIGHT=1><IMG SRC=/img/misc/dottedline.gif HEIGHT=1 WIDTH=100% BORDER=0></TD></TR>
   <TR><TD COLSPAN=3>&nbsp;</TD></TR>
   <TR>
       <TD><formwidget id=logout></TD>
       <TD ALIGN=RIGHT COLSPAN=2><formwidget id=update> <formwidget id=help></TD>
   </TR>
   </TABLE>
   </formtemplate>
   </FIELDSET>
   <return>
</if>

<if @cmd@ in w b g>
   <formtemplate id=form_sender>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD ALIGN=RIGHT>
       <TABLE BORDER=0>
       <TD NOWRAP <%=[ossweb::html::popup_handlers New]%>>Email/Domain:</TD>
       <TD NOWRAP><formwidget id=s> <formwidget id=search> <formwidget id=add> <formwidget id=help></TD>
       </TABLE>
       </TD>
   </TR>
   </TABLE>
   <%=[ossweb::html::popup_object New "Enter full email address or just domain
                                    part in order to @sender_list@ List the whole domain,
                                    domain should NOT contain any pattern matching symbols like *"]%>
   <multipage name=senders>
   <TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
   <TR BGCOLOR=#CCCCCC>
      <TH NOWRAP>
      <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
      <TR><TD><B>Senders in the @sender_list@ List.</B></TD>
          <TD ALIGN=RIGHT>
           <B>Sort by:</B> <A HREF=@_url@&c=@cmd@>Email</A>, <A HREF=@_url@&c=@cmd@&st=1>Domain</A>
          </TD>
      </TR>
      </TABLE>
      </TH>
      <TH WIDTH=1% NOWRAP>Actions: <formwidget id=clear></TH>
   </TR>
   <multirow name=senders>
   <TR VALIGN=TOP BGCOLOR=white>
      <TD>@senders.sender_email@</TD>
      <TD CLASS=small NOWRAP>@senders.edit@</TD>
   </TR>
   </multirow>
   </TABLE>
   <multipage name=senders>
   </formtemplate>
   <return>
</if>

<if @cmd@ in l>
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
      <TD>@log.spam_score@ @log.spam_status@</TD>
      <TD>@log.virus_status@</TD>
      <TD>Dropped/@log.reason@</TH>
   </TR>
   </multirow>
   </TABLE>
   <return>
</if>

<if @cmd@ in v>
   <STYLE>
    input.text {
      font-size: 5pt; 
      border-width: 1; 
      border-color: #DDDDDD; 
      background-color: #CCCCCC;
    }
   </STYLE>
   <SCRIPT>
    function toggleAll()
    {
      var form = document.forms[0];
      for(var i = 0;i < form.elements.length;i++)
        if(form.elements[i].type == "checkbox" && form.elements[i].name == "i")
          form.elements[i].checked = (form.elements[i].checked ? false : true);
    }
   </SCRIPT>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD>The following messages are awaiting your decision 
           whether to permit or deny their delivery.
       </TD>
       <TD WIDTH=1% ALIGN=RIGHT>
          <A HREF="javascript:;" onClick="window.open('http://www.maverixsystems.com/maverixuserguide.htm','MavHelp','width=800,height=600,menubar=0,scrollbars=1,location=0')"><IMG SRC=/img/help.gif ALT=Help BORDER=0></A>
       </TD>
   </TR>
   </TABLE>
   <P>
   <if @messages:rowcount@ eq 0>
      <TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
      <TR BGCOLOR=#CCCCCC><TD>You do not have any unverified messages</TD></TR>
      </TABLE>
      <return>
   </if>
   <formtemplate id=form_user>
   <TABLE WIDTH=100% BORDER=0 BGCOLOR=black CELLSPACING=1 CELLPADDING=2>
   <TR BGCOLOR=#CCCCCC>
      <TD WIDTH=1% ><A HREF=javascript:; onClick="toggleAll()">All</A></TD>
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
      <TH>Text</TH>
      <TH WIDTH=1% >Spam Score</TH>
   </TR>
   <multirow name=messages>
   <TR VALIGN=TOP BGCOLOR=white>
      <TD WIDTH=1% ><INPUT TYPE=checkbox NAME=i VALUE="@messages.sender_email@ @messages.msg_id@"></TD>
      <TD>
         <A HREF="@messages.sender_verify@" TITLE="Allow this sender to always send email">Permit</A> |
         <A HREF="@messages.sender_block@" TITLE="Deny all email from this sender">Block</A> |
         <A HREF="@messages.domain_block@" TITLE="Deny all email from this domain">Block Domain</A><P>
         @messages.sender@
      </TD>
      <TD>
         <A HREF="@messages.message_forward@" TITLE="Forward only this message">Forward</A> |
         <A HREF="@messages.message_drop@" TITLE="Drop only this message">Drop</A><P>
         @messages.subject@
      </TD>
      <TD>@messages.create_date@</TD>
      <TD>@messages.body@<BR>@messages.attachments@</TD>
      <TD>@messages.spam_score@</TD>
   </TR>
   </multirow>
   <TR BGCOLOR=#CCCCCC>
      <TD WIDTH=1% ><A HREF=javascript:; onClick="toggleAll()">All</A></TD>
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
      <TH>Text</TH>
      <TH WIDTH=1% >Spam Score</TH>
   </TR>
   </TABLE>
   </formtemplate>
   <return>
</if>

<if @cmd@ eq login>
   <CENTER>
   <TABLE WIDTH=300>
   <TR><TD>
   <FIELDSET WIDTH=300>
   <LEGEND CLASS=osswebFormTitle>Maverix Login</LEGEND>
   <FORM ACTION=User.oss METHOD=POST>
   <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=1>
   <TR><TD NOWRAP CLASS=field>User name:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><INPUT TYPE=text NAME=u></TD>
   </TR>
   <TR><TD NOWRAP CLASS=field>Password:</TD>
       <TD WIDTH=20>&nbsp;</TD>
       <TD><INPUT TYPE=password NAME=p></TD>
   </TR>
   <TR><TD COLSPAN=3 ALIGN=RIGHT><INPUT TYPE=submit NAME=c VALUE=Login></TD></TR>
   </TABLE>
   </FORM>
   </FIELDSET>
   </TD></TR>
   </TABLE>
   </CENTER>
</if>
