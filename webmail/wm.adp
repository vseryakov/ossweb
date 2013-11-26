<if @ossweb:cmd@ eq error>
   <%=[ossweb::conn msg]%>
   <return>
</if>

<if @ossweb:cmd@ eq login>
   <master mode=lookup>
   <CENTER>
   <TABLE BORDER=0 WIDTH=250>
   <TR><TD><formtemplate id=form_login></formtemplate></TD></TR>
   </TABLE>
   <SCRIPT>
     document.form_login.user.focus();
   </SCRIPT>
   </CENTER>
   <return>
</if>

<if @ossweb:cmd@ in prefs folders contacts>
   <master mode=title>
   <formtemplate id=form_view>
   <DIV ID=webmailToolbar><formwidget id=contacts> <formwidget id=folders> <formwidget id=prefs> <formwidget id=close></DIV>
   </formtemplate>
   <P>
   <if @ossweb:cmd@ eq prefs>
      <formtemplate id=form_prefs border_style=white></formtemplate>
   </if>
   <if @ossweb:cmd@ eq folders>
      <formtemplate id=form_folders border_style=white></formtemplate>
   </if>
   <if @ossweb:cmd@ eq contacts>
      <SCRIPT LANGUAGE=JavaScript>
      function wmContact(field,email)
      {
        eval("var field = window.opener.document.forms[0]."+field);
        if(field.value != "") field.value = field.value + ",";
        field.value = field.value + email;
      }
      </SCRIPT>
      <formtemplate id=form_contacts border_style=white></formtemplate>
      <if @contacts:rowcount@ gt 0>
      <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
      <rowfirst><TH>E-mail</TH><TH>Name</TH></rowfirst>
      <multirow name=contacts>
      <row type=plain underline=1>
         <TD>@contacts.email@</TD>
         <TD>@contacts.name@</TD>
      </row>
      </multirow>
      </TABLE>
      </if>
   </if>
   <return>
</if>

<if @ossweb:cmd@ eq send>
   Messages has been sent
   <SCRIPT>setTimeout('window.close()',1000);</SCRIPT>
   <return>
</if>

<if @ossweb:cmd@ eq compose>
   <master mode=title>
   <formerror id=form_compose>
   <formtemplate id=form_compose>
   <DIV ID=webmailToolbar><formwidget id=send><formwidget id=compose><formwidget id=close></DIV><P>
   <border style=white>
    <rowlast><TD COLSPAN=4><%=[ossweb::html::title "Compose a Message"]%></TD></rowlast>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >To:</TD>
       <TD COLSPAN=2><formwidget id=to>&nbsp;<formwidget id=contacts_to></TD>
    </TR>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >CC:</TD>
       <TD COLSPAN=2><formwidget id=cc>&nbsp;<formwidget id=contacts_cc></TD>
    </TR>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >BCC:</TD>
       <TD COLSPAN=2><formwidget id=bcc>&nbsp;<formwidget id=contacts_bcc></TD>
    </TR>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >Subject:</TD>
       <TD><formwidget id=subject></TD>
       <TD><formwidget id=rr><formlabel id=rr></TD>
    </TR>
    <rowlast><TD COLSPAN=4><B>Message Text</B></TD></rowlast>
    <TR VALIGN=TOP><TD WIDTH=30>&nbsp;</TD><TD COLSPAN=2><formwidget id=body></TD></TR>
    <rowlast><TD COLSPAN=4><B>Attachments</B></TD></rowlast>
    <TR><TD WIDTH=1% >&nbsp;</TD>
        <TD COLSPAN=3>
           <formwidget id=upload>
           <formwidget id=attach>
           <formwidget id=clear>
           <formwidget id=toggle>
        </TD>
    </TR>
    <multirow name=files>
     <TR><TD WIDTH=1% >&nbsp;</TD><TD COLSPAN=3>@files.name@</TD></TR>
    </multirow>
   </border>
   </formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq read>
   <DIV ID=webmailHeaders>
     <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
     <TR><TH>
         <%=[ossweb::html::link -image plus.gif -alt "Toggle full/brief headers" -url "javascript:wmToggleHeaders();"]%>
         </TH>
         <TD ALIGN=RIGHT>@mailfiles@</TD>
         <TD ALIGN=RIGHT>
            ID: <B>@msg_id@</B> &nbsp;
            Size: <B><%=[ossweb::util::size @msg_size@]%></B> &nbsp;
            Flags: <DIV ID=webmailFlags>@msg_flags@ &nbsp;
            <%=[ossweb::html::link -image close.gif -alt "Close Message" -url "javascript:;" -html "onClick=\"varSet('webmailBottom','');\""]%>
            </DIV>
         </TD>
     </TR>
     </TABLE>
     <TABLE BORDER=0 CELLSPACING=0>
     <multirow name=headers>
     <TR CLASS="@headers.class@" ID=wmHdr@headers.id@>
       <TD ID=wmHdrNm@headers.id@>@headers.name@:</TD>
       <TH ID=wmHdrVl@headers.id@>@headers.value@</TH>
     </TR>
     </multirow>
     </TABLE>
   </DIV>

   <DIV ID=webmailBody>
   @body@
   </DIV>
   <return>
</if>

<if @ossweb:cmd@ in list sort>
  <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
  <TR CLASS=webmailLine>
      <TD COLSPAN=4 CLASS=osswebTitle><%=[string totitle ${ossweb:page}]%>: <DIV ID=webmailMailbox>@mailbox@</DIV></TD>
      <TD COLSPAN=3 ALIGN=RIGHT NOWRAP>
         (<DIV ID=webmailNewMsgs>@msg_new@</DIV> new, <DIV ID=webmailTotalMsgs>@msg_total@</DIV> total, @msg_recent@ recent)
      </TD>
  </TR>
  <TR><TH><A HREF="javascript:wmToggleSelected()"><IMG SRC=<%=[ossweb::image_name mark.gif]%>></TH>
      <TH><%=[ossweb::html::link -text Subject -alt "Sort by subject" -class webmailLink -url "javascript:wmSort('subject')"]%>
          <if @sort@ eq 1subject><IMG SRC=/img/up5.gif></if>
          <if @sort@ eq 0subject><IMG SRC=/img/down5.gif></if>
      </TH>
      <TH COLSPAN=2>&nbsp;</TH>
      <TH><%=[ossweb::html::link -text From -alt "Sort by from" -class webmailLink -url "javascript:wmSort('from');"]%>
          <if @sort@ eq 1from><IMG SRC=/img/up5.gif></if>
          <if @sort@ eq 0from><IMG SRC=/img/down5.gif></if>
      </TH>
      <TH><%=[ossweb::html::link -text Date -alt "Sort by date" -class webmailLink -url "javascript:wmSort('date');"]%>
          <if @sort@ eq 1date><IMG SRC=/img/up5.gif></if>
          <if @sort@ eq 0date><IMG SRC=/img/down5.gif></if>
      </TH>
  </TR>
  <tbody ID=webmailMessages>
  <multirow name=messages>
  <TR ID=wmRow@messages.msg_id@ <if @messages.class@ ne "">CLASS=@messages.class@</if>>
    <TD WIDTH=10>@messages.checkbox@</TD>
    <TD ID=wmSub@messages.msg_id@>@messages.subject@</TD>
    <TD NOWRAP ID=wmFlg@messages.msg_id@>@messages.flags@</TD>
    <TD NOWRAP WIDTH=16>@messages.attach@</TD>
    <TD NOWRAP>@messages.from@</TD>
    <TD NOWRAP>@messages.date@</TD>
  </TR>
  </multirow>
  </tbody>
  </TABLE>
  <DIV ID=webmailError STYLE="display:none"><%=[ossweb::conn msg]%></DIV>
  <return>
</if>

<master mode=lookup>
<formtemplate id=form_view>
<TABLE ID=webmailToolbar BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
  <TR VALIGN=MIDDLE HEIGHT=30>
    <TD NOWRAP>
       <formwidget id=refresh>
       <formwidget id=stop>
       <formwidget id=compose>
       <formwidget id=contacts>
       <formwidget id=folders>
       <formwidget id=prefs>
       <formwidget id=reply>
       <formwidget id=replyall>
       <formwidget id=forward>
       <formwidget id=delete>
       <formwidget id=actions>
       <formwidget id=logout>
       <formwidget id=search>
    </TD>
    <TD ID=webmailStatus></TD>
    <TD ID=webmailSearch></TD>
  </TR>
</TABLE>
</formtemplate>
<TABLE ID=webmailMain WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR VALIGN=TOP>

<TD ID=webmailFolders>
  <SCRIPT LANGUAGE=javascript>
    var Tree = new Array();
    @mailfolders@
  </SCRIPT>
</TD>

<TD ID=webmailContent>
  <DIV ID=webmailTop></DIV>
  <DIV ID=webmailBottom></DIV>
</TD>
</TR>
</TABLE>

