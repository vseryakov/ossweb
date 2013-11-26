<if @ossweb:cmd@ eq file><return></if>
<if @ossweb:cmd@ eq error><master src=../index/index.title><return></if>

<if @ossweb:cmd@ eq abook2>
   <master src=../index/index.title>
   <SCRIPT LANGUAGE=JavaScript>
   function addrAdd(field,email)
   {
     eval("var field = window.opener.document.forms[0]."+field);
     if(field.value != "") field.value = field.value + ",";
     field.value = field.value + email;
   }
   </SCRIPT>
   <formtemplate id=form_abook></formtemplate>
   <border>
   <rowfirst></TH><TH>E-mail</TH><TH>Name</TH></rowfirst>
   <multirow name=abook>
     <row>
       <TD>@abook.email@</TD>
       <TD>@abook.name@</TD>
     </row>
   </multirow>
   </border>
   <return>
</if>

<master src=index>

<if @ossweb:cmd@ eq login>
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

<if @ossweb:cmd@ in prefs folders abook>
   <formtemplate id=form_view>
   <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
    <TR VALIGN=TOP BGCOLOR=white>
      <TD NOWRAP>
         <formwidget id=view>
         <formwidget id=compose>
         <formwidget id=abook>
         <formwidget id=folders>
         <formwidget id=prefs>
      </TD>
      <TD ALIGN=RIGHT NOWRAP>
         <formwidget id=folder>
         <formwidget id=goto>
         <formwidget id=logout>
       </TD>
     </TR>
   </TABLE>
   </formtemplate>
   <P>
   <if @ossweb:cmd@ eq prefs>
      <formtemplate id=form_prefs></formtemplate>
   </if>
   <if @ossweb:cmd@ eq folders>
      <formtemplate id=form_folders></formtemplate>
   </if>
   <if @ossweb:cmd@ eq abook>
      <formtemplate id=form_abook></formtemplate>
      <if @abook:rowcount@ gt 0>
      <border>
      <rowfirst><TH>E-mail</TH><TH>Name</TH></rowfirst>
      <multirow name=abook>
      <row>
         <TD>@abook.email@</TD>
         <TD>@abook.name@</TD>
      </row>
      </multirow>
      </border>
      </if>
   </if>
   <return>
</if>

<SCRIPT LANGUAGE=JavaScript>
 function toggle(form,name) {
  for(var i = 0;i < form.elements.length;i++)
    if(form.elements[i].type == "checkbox" && form.elements[i].name == name)
      form.elements[i].checked = form.elements[i].checked?false:true;
 }
</SCRIPT>

<if @ossweb:cmd@ eq compose>

   <formtemplate id=form_compose>
   <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
    <TR VALIGN=TOP BGCOLOR=white>
      <TD NOWRAP>
         <formwidget id=view>
         <formwidget id=compose>
         <formwidget id=send>
      </TD>
      <TD><formerror id=form_compose></TD>
      <TD ALIGN=RIGHT NOWRAP>
         <helpbutton>
      </TD>
    </TR>
   </TABLE>
   <P>
   <border border1=0>
    <TR CLASS=webmailLine>
      <TD COLSPAN=4>
        <TABLE BORDER=0 WIDTH=100% >
        <TR>
          <TD NOWRAP><B>Compose:</B> Current Mailbox: <%=[ossweb::html::title $mailbox]%></TD>
          <TD ALIGN=RIGHT>(@total_msgs@ messages, @recent_msgs@ recent)</TD>
        </TR>
        </TABLE>
      </TD>
    </TR>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >To:</TD>
       <TD COLSPAN=2><formwidget id=to>&nbsp;<formwidget id=abook_to></TD>
    </TR>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >CC:</TD>
       <TD COLSPAN=2><formwidget id=cc>&nbsp;<formwidget id=abook_cc></TD>
    </TR>
    <TR>
       <TD WIDTH=1% >&nbsp;</TD>
       <TD WIDTH=1% >BCC:</TD>
       <TD COLSPAN=2><formwidget id=bcc>&nbsp;<formwidget id=abook_bcc></TD>
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

<if @ossweb:cmd@ eq edit>

   <formtemplate id=form_edit>
   <TABLE BORDER=0 WIDTH=98% CELLSPACING=0 CELLPADDING=0>
    <TR VALIGN=TOP BGCOLOR=white>
      <TD NOWRAP>
         <formwidget id=view>
         <formwidget id=reply>
         <formwidget id=replyall>
         <formwidget id=forward>
         <formwidget id=delete>
         <formwidget id=prev>
         <formwidget id=next>
         <formwidget id=mark>
      </TD>
      <TD ALIGN=RIGHT NOWRAP>
         <formwidget id=folder>
         <formwidget id=goto>
         <formwidget id=move>
         <helpbutton>
      </TD>
    </TR>
   </TABLE>
   <P>
   <border border1=0>
    <TR CLASS=webmailLine>
      <TD COLSPAN=3>
        <TABLE BORDER=0 WIDTH=100% >
        <TR>
          <TD NOWRAP>Message: <B>@msg_id@</B>, Mailbox: <%=[ossweb::html::title $mailbox]%></TD>
          <TD ALIGN=RIGHT>(@total_msgs@ messages, @recent_msgs@ recent)</TD>
        </TR>
        </TABLE>
      </TD>
    </TR>
    <multirow name=hdrs>
      <TR CLASS=webmailLine VALIGN=TOP>
        <TD WIDTH=1% ><if @hdrs.rownum@ eq 1>@hdr_image@<else>&nbsp;</if></TD>
        <TD WIDTH=1% >@hdrs.name@:</TD>
        <TD ><B>@hdrs.value@</B></TD>
      </TR>
    </multirow>
    <TR><TD COLSPAN=3>&nbsp;</TD></TR>
    <TR VALIGN=TOP>
      <TD WIDTH=30>&nbsp;</TD>
      <TD COLSPAN=2>@body@</TD>
    </TR>
   </border>
   <if @body_size@ gt 1024>
   <HR>
   <TABLE BORDER=0 WIDTH=98% CELLSPACING=0 CELLPADDING=0>
    <TR VALIGN=TOP BGCOLOR=white>
      <TD NOWRAP>
         <formwidget id=view>
         <formwidget id=reply>
         <formwidget id=replyall>
         <formwidget id=forward>
         <formwidget id=delete>
         <formwidget id=prev>
         <formwidget id=next>
         <formwidget id=mark>
      </TD>
      <TD ALIGN=RIGHT NOWRAP>
         <helpbutton>
      </TD>
    </TR>
   </TABLE>
   </if>
   </formtemplate>
   <return>
</if>

<formtemplate id=form_view>
<TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
  <TR VALIGN=TOP BGCOLOR=white>
    <TD NOWRAP>
       <formwidget id=view>
       <formwidget id=compose>
       <formwidget id=abook>
       <formwidget id=folders>
       <formwidget id=prefs>
       <formwidget id=delete>
       <formwidget id=mark>
    </TD>
    <TD ALIGN=RIGHT NOWRAP>
       <formwidget id=folder>
       <formwidget id=goto>
       <formwidget id=move>
       <formwidget id=logout>
       <helpbutton>
    </TD>
  </TR>
  <TR>
    <TD COLSPAN=2 ALIGN=CENTER NOWRAP>
       <BR><multipage name=pages images=0 width=1% >
    </TD>
  </TR>
</TABLE>
<P>

<border style=default class2=osswebBorder1 border1=0 cellspacing=1 cellpadding=2>
  <TR CLASS=webmailLine>
    <TD COLSPAN=6>
     <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
     <TR>
       <TD>Mailbox: <%=[ossweb::html::title "[string totitle ${ossweb:page}]: $title"]%></TD>
       <TD ALIGN=RIGHT>(@total_msgs@ messages, @recent_msgs@ recent@range_msgs@)</TD>
     </TR>
     </TABLE>
    </TD>
  </TR>
  <rowfirst>
    <TH WIDTH=1% ><A HREF="javascript:var i" onClick="toggle(document.form_view,'msg_id')"><IMG SRC=<%=[ossweb::image_name mark.gif]%> BORDER=0></TH>
    <TH>
       <TABLE BORDER=0 CELLSPACING=0 CELLPADING=0 WIDTH=100% >
       <TR>
          <TH>Subject</TH>
          <TD ALIGN=RIGHT NOWRAP>
             <%=[ossweb::html::link -image up3.gif -alt "Descending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 0subject page $page]%>&nbsp;
             <%=[ossweb::html::link -image down3.gif -alt "Ascending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 1subject page $page]%>
          </TD>
       </TR>
       </TABLE>
    </TH>
    <TH WIDTH=1% >Flags</TH>
    <TH>
       <TABLE BORDER=0 CELLSPACING=0 CELLPADING=0 WIDTH=100% >
       <TR>
          <TH>From</TH>
          <TD ALIGN=RIGHT NOWRAP>
             <%=[ossweb::html::link -image up3.gif -alt "Descending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 0from page $page]%>&nbsp;
             <%=[ossweb::html::link -image down3.gif -alt "Ascending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 1from page $page]%>
          </TD>
       </TR>
       </TABLE>
    </TH>
    <TH WIDTH=1% >
       <TABLE BORDER=0 CELLSPACING=0 CELLPADING=0 WIDTH=100% >
       <TR>
          <TH>Date&nbsp;</TH>
          <TD ALIGN=RIGHT NOWRAP>
             <%=[ossweb::html::link -image up3.gif -alt "Descending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 0date page $page]%>&nbsp;
             <%=[ossweb::html::link -image down3.gif -alt "Ascending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 1date page $page]%>
          </TD>
       </TR>
       </TABLE>
    </TH>
    <TH WIDTH=1% >
       <TABLE BORDER=0 CELLSPACING=0 CELLPADING=0 WIDTH=100% >
       <TR>
          <TH>Size&nbsp;</TH>
          <TD ALIGN=RIGHT NOWRAP>
             <%=[ossweb::html::link -image up3.gif -alt "Descending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 0size page $page]%>&nbsp;
             <%=[ossweb::html::link -image down3.gif -alt "Ascending Sort" -width "" -height "" cmd view conn_id $conn_id mailbox $mailbox sort 1size page $page]%>
          </TD>
       </TR>
       </TABLE>
    </TH>
  </rowfirst>
  <multirow name=mlist>
    <row>
      <TD>@mlist.msg@</TD>
      <TD>@mlist.subject@</TD>
      <TD><B>@mlist.flags@</B></TH>
      <TD>@mlist.from@</TD>
      <TD NOWRAP>@mlist.date@</TD>
      <TD NOWRAP>@mlist.size@</TD>
    </row>
  </multirow>
</border>
</formtemplate>
