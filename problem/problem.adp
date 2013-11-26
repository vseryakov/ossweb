<if @ossweb:cmd@ eq rss>
   <?xml version="1.0"?>
   <rss version="2.0">
   <channel>
   <title>Problem/Tasks</title>
   <link><%=[ns_quotehtml [ossweb::conn::hostname][ns_conn url]?[ossweb::conn::export_form]]%></link>
   <description>List of problem/tasks</description>
   <multirow name=tasks>
   <item>
     <title><%=[ns_striphtml "@tasks.project_name@: @tasks.title@"]%></title>
     <description><%=[ns_quotehtml @tasks.description@]%>
                  <if @tasks.last_note_text@ ne "">Last Note: <%=[ns_striphtml "@tasks.last_note_text@"]%></if>
     </description>
     <pubDate>@tasks.update_date@</pubDate>
     <guid isPermaLink="true"><%=[ns_quotehtml [ossweb::conn::hostname]@tasks.url@]%></guid>
   </item>
   </multirow>
   </channel>
   </rss>
   <return>
</if>

<template name=notes>
   <TR>
     <TD WIDTH=16><ossweb:image minus.gif -opacity 0.5 -title "Expand/Collapse All" -onClick "noteToggleAll(this)"></TD>
     <TH NOWRAP><formwidget id=form_nsort.created> &nbsp;
                <formwidget id=form_nsort.submitted>
     </TH>
     <TH NOWRAP><formwidget id=form_nsort.status_name></TH>
     <TH>Text</TH>
     <TH>File</TH>
     <TH WIDTH=1% NOWRAP><formwidget id=form_nsort.hours></TH>
     <TH WIDTH=16></TH>
   </TR>
   <multirow name=notes>
   <row VALIGN=TOP type=plain underline=1>
     <TD>
         <ossweb:image minus.gif -id it@notes.problem_note_id@ -opacity 0.5 -title "Expand/Collapse" -onClick "noteToggle('t@notes.problem_note_id@');">
     </TD>
     <TD WIDTH=1% CLASS=osswebSmallText>
         <A NAME=@problem_id@.@notes.problem_note_id@>@notes.create_date@</A> &nbsp;
         @notes.user_name@
     </TD>
     <TD WIDTH=1% NOWRAP >
         <FONT COLOR=darkred>@notes.status_name@</FONT>

         <if @notes.percent@ ne "">
           <BR><IMG SRC=/img/misc/bluepixel.gif HEIGHT=10 WIDTH=<%=[expr @notes.percent@/2]%>>@notes.percent@%
         </if>
     </TD>
     <TD>
         <DIV ID=t@notes.problem_note_id@>@notes.description@</DIV>
     </TD>
     <TD>@notes.files@

         <if @notes.svn_file@ ne "">
           <BR><SPAN CLASS=gray>SVN <if @notes.svn_revision@ ne "">Rev: @notes.svn_revision@</if> @notes.svn_file@</SPAN>
         </if>
     </TD>
     <TD NOWRAP CLASS=osswebSmallText><if @notes.hours@ ne "">@notes.hours@ hrs</if></TD>
     <TD NOWRAP>
         <if @ossweb:ctx@ ne info>
         <ossweb:link -image add.gif -opacity 0.5 -alt AddNotes -url "javascript:notesForm()">
         </if>

         <if @ossweb:user@ eq @notes.user_id@>
         <ossweb:link -image edit.gif -opacity 0.5 -alt UpdateNotes -url "javascript:notesEdit(@notes.problem_note_id@)">
         <ossweb:link -image trash.gif -opacity 0.5 -alt DeleteNotes -confirmtext "Note will be deleted, continue?" cmd delete.note problem_id @problem_id@ problem_note_id @notes.problem_note_id@>
         </if>
     </TD>
   </row>
   </multirow>
</template>

<if @ossweb:cmd@ eq file>
   <return>
</if>

<if @ossweb:cmd@ eq error>
   <master mode=title>
   <return>
</if>

<if @ossweb:cmd@ eq info>
   @description@
   <return>
</if>

<if @ossweb:cmd@ eq svn and @ossweb:ctx@ in info list diff log view update>
   <master mode=title>
   <formtemplate id=form_svn>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD STYLE="padding-bottom:10px;font-weight:bold;font-size:12pt;color:green;">
       <%=[string map { / { /} } $title]%>
       </TD>
   </TR>
   <TR><TD NOWRAP STYLE="padding-bottom:10px;">
       <formwidget id=select> <formwidget id=info>
       <formwidget id=diff> <formwidget id=log>
       <formwidget id=view> <formwidget id=revisions>
       <formwidget id=update>
       </TD>
   </TR>
   <TR><TD NOWRAP STYLE="border-top: 1px solid gray;">
       <multirow name=info>@info.line@<BR></multirow>
       </TD>
   </TR>
   </TABLE>
   </formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq favorites>
   <master mode=title>
   <helptitle help=0>Task/Problem Favorite Filters</helptitle>
   <DIV STYLE="font-size:8pt;padding:2px;">Save current Tasks/Problem selection with name for further quick access</DIV>
   <HR>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD>Name: <formwidget id=form_favorites.name> (<formwidget id=form_favorites.global> Global)</TD>
       <TD ALIGN=RIGHT><formwidget id=form_favorites.save> <formwidget id=form_favorites.close></TD>
   </TR>
   </TABLE>
   <HR>
   <multirow name=favorites>
   &nbsp;@favorites.delete@&nbsp;&nbsp;@favorites.url@<BR>
   </multirow>
   <return>
</if>

<if @ossweb:cmd@ eq tree and @ossweb:ctx@ eq list>
   <return>
</if>

<master mode=lookup>

<STYLE>
#problemTbl th td {
  font-size: 8pt;
}
.percent {
  background-color: blue;
  border: 1px solid black;
}
.small {
  color: gray;
  font-size: 7pt;
}
.gray {
  color: gray;
  font-size: 7pt;
}
.last {
  font-size: 7pt;
  border-top: 1px solid #ddd;
}
#Notes div {
  overflow-x: hidden;
}
#Notes img {
  cursor: pointer;
}
#Problems span {
  color: gray;
  font-size: 7pt;
}
#Problems a {
  font-size: 7pt;
}
#Info td {
  font-size: 7pt;
}
.hidden {
  display: none;
}
#svn {
  color: gray;
  font-size: 8px;
  text-align: left;
}
</STYLE>

<SCRIPT>
function notesSubmit()
{
   return true;
}

function notesText(data)
{
   if(window.tinyMCE) {
     tinyMCE.setContent(data);
   } else {
     document.form_notes.description.value = data;
   }
}

function notesEdit(id)
{
   var data = pagePopupGet('<ossweb:url cmd info.noteDescr problem_id @problem_id@ problem_note_id js:id>',{sync:1});
   document.form_notes.problem_note_id.value = id;
   document.form_notes.update.value = 'Update';
   document.form_notes.exit.value = 'Update & Exit';
   notesText(data);
   notesForm();
}

function notesForm(parent)
{
  var bg, obj = $('formNote');
  if(parent) {
    varStyle('noteCancel','display','none');
    obj.style.backgroundColor = obj.bgcolor;
    obj.style.position = 'relative';
    obj.style.top = 0;
    obj.style.left = 0;
    notesText('');
  } else {
    noteExpand('noteForm',{empty:1});
    varStyle('noteCancel','display','inline');
    varStyle(obj,'position','absolute');
    obj.bgcolor = obj.style.backgroundColor;
    popupShow(obj,{left:20,top:70,dnd:1,bgcolor:'#FFFFE0'});
  }
}
function addFile()
{
  for(var i = 1; i <= 4;i++) {
    var obj = $('upload'+i+'_div');
    if(obj.style.display != 'block') {
      obj.style.display = 'block';
      return;
    }
  }
}
</SCRIPT>

<if @ossweb:cmd@ eq svn and @ossweb:ctx@ in tree file>
   <TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="5">
   <TR VALIGN=TOP>
      <TD ID=Tree  BGCOLOR=#F3F9FD WIDTH=40% NOWRAP>
      <SCRIPT LANGUAGE=javascript>
      var Tree = new Array();
      @tree_items@
      createTree(Tree,null,'@tree_open@','<FONT COLOR=#234c54><B>SVN Browser</B></FONT>','Problems');

      function sGet(file,ctx,rev)
      {
         if(!rev) rev='';
         if(!ctx) ctx='info';
         pagePopupGet('<ossweb:url -lookup t cmd svn ctx js:ctx title js:file rev js:rev std @std@>',{data:'Info'});
      }

      function sPut(file,rev)
      {
         var f = '';
         for(var i = 0;i < file.length;i++) {
            f += file.substr(i,1);
            if(i >= 32 && i % 32 == 0) f += '<br>';
         }
         var form = window.opener.document.form_notes;
         form.svn_file.value = file;
         varSet('svn_file',f,window.opener.document);
         form.svn_revision.value = rev;
         varSet('svn_revision','r'+rev,window.opener.document);
      }
      <if @ossweb:ctx@ eq file>
        sGet('@title@');
      </if>
      </SCRIPT>
      </TD>
      <TD ID=Info>&nbsp;</TD>
   </TR>
   </TABLE>
   <return>
</if>

<if @ossweb:cmd@ eq tree>
   <TABLE WIDTH="100%" BORDER="0" CELLPADDING="0" CELLSPACING="5">
   <TR VALIGN=TOP>
      <TD ID=Tree  BGCOLOR=#F3F9FD WIDTH=40% NOWRAP>
      <SCRIPT LANGUAGE=javascript>
      var Tree = new Array();
      @tree_items@
      createTree(Tree,null,'@tree_open@','<FONT COLOR=#234c54><B>Tasks/Problems</B></FONT>','Problems');

      function pInfo(id,type)
      {
        if(type)
          pagePopupGet('<ossweb:url -lookup t cmd edit.info problem_id js:id>',{data:'Info'});
        else
          pagePopupGet('<ossweb:url -lookup t projects cmd edit.info project_id js:id>',{data:'Info'});
      }
      </SCRIPT>
      </TD>
      <TD ID=Info>&nbsp;</TD>
   </TR>
   </TABLE>
   <return>
</if>

<if @ossweb:cmd@ eq edit>

   <if @problem_id@ eq "">
     <formtemplate id=form_problem style=fieldset></formtemplate>
     <return>
   </if>

   <A NAME=top></A>
   <formtemplate id=form_problem>
   <CENTER><formerror id=form_problem></CENTER>

   <FIELDSET STYLE="background-color: #f3f1f1;">
   <LEGEND CLASS=osswebTitle>
     @problem_icon@Task/Problem Details (@problem_status_name@<if @percent_completed@ ne "">/@percent_completed@%</if>) @problem_link@
   </LEGEND>
   <TABLE WIDTH=100% BORDER=0 CELLPADDING=2>
   <TR VALIGN=TOP>
     <TD><formlabel id=project_id><BR><formwidget id=project_id><BR><BR>
         <formlabel id=problem_type><BR><formwidget id=problem_type><BR><BR>
         <formlabel id=priority><BR><formwidget id=priority><BR><BR>
         <formlabel id=severity><BR><formwidget id=severity>
     </TD>
     <TD><formlabel id=user_name><BR><formwidget id=user_name><BR><BR>
         <formlabel id=owner_id><BR><formwidget id=owner_id><BR><BR>
         <formlabel id=problem_cc><BR><formwidget id=problem_cc>
     </TD>
     <TD><formlabel id=create_date><BR><formwidget id=create_date><BR><BR>
         <formlabel id=due_date><BR><formwidget id=due_date><BR><BR>
         <formlabel id=hours_required><BR><formwidget id=hours_required>
     </TD>
     <TD ROWSPAN=2 WIDTH="45%">
         <formlabel id=title><BR><formwidget id=title><BR>
         <formlabel id=description> <ossweb:link -image zoom2.gif -width "" -height "" -alt "Show Description" -window Info -winopts "width=900,location=0,resizable=1,scrollbars=1,menubar=1" cmd info.description problem_id @problem_id@><BR>
         <DIV STYLE="border:1px dashed #cccccc;background-color:#eee;;height:@descr_height@;overflow:auto;overflow-x:visible;overflow-y:auto;">
         <formwidget id=description>
         </DIV>
     </TD>
   </TR>
   <TR VALIGN=TOP>
     <TD COLSPAN=2>
        <if @files@ ne "">
        <formlabel id=files><BR>
        <DIV STYLE="border:1px dashed #cccccc;background-color:#eee;font-size:7pt;height:@files_height@;overflow:auto;overflow-x:visible;overflow-y:auto;">
        <TABLE WIDTH=100% BORDER=0 CELLSAPCING=0 CELLPADDING=0>
        <formwidget id=files>
        </TABLE>
        </DIV>
        </if>
     </TD>
     <TD NOWRAP VALIGN=BOTTOM>
        <formwidget id=alert_on_complete> <formlabel id=alert_on_complete><BR>
        <formwidget id=close_on_complete> <formlabel id=close_on_complete>
     </TD>
   </TR>
   <if @ossweb:ctx@ ne info>
   <TR>
     <TD COLSPAN=2 VALIGN=BOTTOM>
        <SPAN CLASS=osswebFormLabel>Hours Worked</SPAN>: @hours_worked@
        <if @cal_date@ ne "" >
        | <SPAN CLASS=osswebFormLabel>Reopen Date</SPAN>: @cal_date@ @cal_repeat@
        </if>
        | <formlabel id=problem_tags> <formwidget id=problem_tags>
     </TD>
     <TD COLSPAN=2 ALIGN=RIGHT>
        <formwidget id=update> <formwidget id=delete> <formwidget id=back>
        <formwidget id=tree> <formwidget id=new> <formwidget id=svnTree>
        <help_button>
     </TD>
   </TR>
   </if>
   </TABLE>
   </FIELDSET>
   </formtemplate>

   <P ID=formSeparator>

   <if @ossweb:ctx@ ne info>
   <DIV ID=formNote>
   <FIELDSET>
   <LEGEND CLASS=osswebTitle>
     <ossweb:image minus.gif -id inoteForm -opacity 0.5 -title "Expand/Collapse Form" -onClick "noteToggle('noteForm',{empty:1});">
     Follow Ups
   </LEGEND>
   <formtemplate id=form_notes>
   <CENTER><formerror id=form_notes></CENTER>
   <TABLE ID=noteForm WIDTH=100% BORDER=0>
   <TR VALIGN=TOP>
     <TD ROWSPAN=2>
         <formlabel id=description><BR>
         <formwidget id=description>
     </TD>
     <TD NOWRAP STYLE="border: 1px dotted #EEEEEE;">
         <TABLE BORDER=0 CELLPADDING=2 CELLSPACING=3>
         <TR><TD><formlabel id=owner_id></TD>
             <TD COLSPAN=2><formwidget id=owner_id></TD>
         </TR>
         <TR><TD><formlabel id=upload></TD>
             <TD COLSPAN=2><formwidget id=upload name=html:data>
                           <formwidget id=upload1 name=html:data>
                           <formwidget id=upload2 name=html:data>
                           <formwidget id=upload3 name=html:data>
                           <formwidget id=upload4 name=html:data>
             </TD>
         </TR>
         <TR><TD><formlabel id=notes_cc></TD>
             <TD COLSPAN=2><formwidget id=notes_cc></TD>
         </TR>
         <TR><TD><formlabel id=merge_id></TD>
             <TD COLSPAN=2><formwidget id=merge_id></TD>
         </TR>
         <TR><TD><formlabel id=hours></TD>
             <TD COLSPAN=2><formwidget id=hours>hrs</TD>
         </TR>
         <TR><TD><formlabel id=percent></TD>
             <TD COLSPAN=2><formwidget id=percent>%</TD>
         </TR>
         <TR><TD><formlabel id=cal_date></TD>
             <TD COLSPAN=2><TABLE BORDER=0 CELLLSPACING=0>
                           <TR><TD><formwidget id=cal_date></TD>
                               <TD><formwidget id=cal_repeat></TD>
                           </TR>
                           </TABLE>
         </TR>
         <TR>
         </TR>
         </TABLE>
     </TD>
     <TD NOWRAP STYLE="padding-left:50px;font-weight:bold;color:green;">
        <formlabel id=problem_status><BR>
        <formgroup id=problem_status>
        @formgroup.widget@ @formgroup.label@<BR>
        </formgroup>
        <BR>
        <SPAN ID=svn>
        <formlabel id=svn_file><BR>
        <formwidget id=svn_file><BR>
        <formwidget id=svn_revision>
        </SPAN>
     </TD>
   </TR>
   <TR><TD VALIGN=MIDDLE NOWRAP>
         <formwidget id=owner_flag> <formlabel id=owner_flag append="&nbsp;">
         <formwidget id=html_flag> <formlabel id=html_flag append="&nbsp;">
         <formwidget id=quiet_flag> <formlabel id=quiet_flag append="&nbsp;">
         <formwidget id=email_flag> <formlabel id=email_flag append="&nbsp;">
       </TD>
       <TD NOWRAP ALIGN=RIGHT>
         <formwidget id=update>
         <formwidget id=exit>
         <formwidget id=noteCancel>
       </TD>
   </TR>
   </TABLE>
   </formtemplate>
   </FIELDSET>
   </DIV>
   </if>

   <P>

   <if @notes:rowcount@ gt 0>
     <if @ossweb:ctx@ eq info>
     <border style=class id=Notes cellpadding=3><include type=template name=notes></border>
     <else>
     <border style=white id=Notes cellpadding=3><include type=template name=notes></border>
     </if>
   </if>
   <return>
</if>

<formtemplate id=form_search>
<CENTER><formerror id=form_problem></CENTER>
<FIELDSET STYLE="background-color: #f3f1f1;">
<LEGEND CLASS=osswebTitle>Task/Problem List</LEGEND>
<TABLE BORDER=0 WIDTH=100% >
<TR VALIGN=TOP>
 <TD ROWSPAN=2><formlabel id=project_id><BR><formwidget id=project_id></TD>
 <TD><formlabel id=problem_id><BR><formwidget id=problem_id></TD>
 <TD><formlabel id=user_id><BR><formwidget id=user_id></TD>
 <TD><formlabel id=create_date><BR><formwidget id=create_date></TD>
 <TD><formlabel id=priority><BR><formwidget id=priority><BR>
     <formlabel id=severity><BR><formwidget id=severity>
 </TD>
</TR>
<TR VALIGN=TOP>
 <TD><formlabel id=title><BR><formwidget id=title><P>
     <formlabel id=description><BR><formwidget id=description><P>
     <formlabel id=problem_tags><BR><formwidget id=problem_tags>
     </TD>
 <TD><formlabel id=owner_id><BR><formwidget id=owner_id><BR>
     <formlabel id=belong_id><BR><formwidget id=belong_id>
 </TD>
 <TD><formlabel id=due_date><BR><formwidget id=due_date><BR>
     <formlabel id=problem_type><BR><formwidget id=problem_type>
 </TD>
 <TD><formlabel id=problem_status><BR><formwidget id=problem_status><P>
     <FONT SIZE=1>
     <formwidget id=unassigned_flag> <formwidget id=unassigned_flag name=label><BR>
     <formwidget id=projectgroup_flag> <formwidget id=projectgroup_flag name=label><BR>
     </FONT>
 </TD>
</TR>
<TR>
 <TD><ossweb:link -image feed.png -alt "RSS Feed" -query [problem_filter] cmd rss></TD>
 <TD COLSPAN=4 ALIGN=RIGHT VALIGN=BOTTOM>
   <formwidget id=search>
   <formwidget id=tree>
   <formwidget id=list>
   <formwidget id=close>
   <formwidget id=add>
   <formwidget id=tracker>
   <formwidget id=favorites>
   <formwidget id=svnTree>
   <formwidget id=reset>
 </TD>
</TR>
</TABLE>
</FIELDSET>
</formtemplate>

<multipage name=tasks>
<border id=problemTbl style=white>
<TR VALIGN=TOP>
 <TH>ID</TH>
 <TH><formwidget id=form_psort.project_name></TH>
 <TH><formwidget id=form_psort.title></TH>
 <TH><formwidget id=form_psort.type_name></TH>
 <TH><formwidget id=form_psort.status_name>/<BR> <formwidget id=form_psort.priority></TH>
 <TH><formwidget id=form_psort.severity></TH>
 <TH><formwidget id=form_psort.create_date>/<BR> <formwidget id=form_psort.due_date></TH>
 <TH><formwidget id=form_psort.last_name>/<BR> Assigned</TH>
 <TH><formwidget id=form_psort.update_date></TH>
 <TH>Notes#</TH>
 <TH></TH>
</TR>
<multirow name=tasks>
 <row VALIGN=TOP type=plain underline=1>
  <TD>@tasks.problem_id@</TD>
  <TD>@tasks.project_name@</TD>
  <TD>@tasks.link@
      <if @tasks.last_note_text@ ne "">
      <BR>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;@tasks.last_note_text@
      </if>
  </TD>
  <TD CLASS=small>@tasks.problem_type_name@
      <if @tasks.problem_tags@ ne "">
         @tasks.problem_tags@
      </if>
      <if @tasks.percent_completed@ ne "">
      <BR><IMG SRC=/img/misc/bluepixel.gif HEIGHT=10 WIDTH=<%=[expr @tasks.percent_completed@/2]%>>@tasks.percent_completed@%
      </if>
  </TD>
  <TD>@tasks.icon@ @tasks.problem_status_name@ (@tasks.priority_name@)
      <if @tasks.cal_id@ ne "">
      <ossweb:image calendar3.gif -title "@tasks.cal_date@ @tasks.cal_repeat@">
      </if>
  </TD>
  <TD>@tasks.severity_name@</TD>
  <TD>@tasks.create_date@<BR><FONT COLOR=darkred>@tasks.due_date@</FONT></TD>
  <TD>@tasks.user_name@<BR><FONT COLOR=darkred>@tasks.owner_name@</FONT></TD>
  <TD>@tasks.update_date@
      <if @tasks.update_time@ ne "">
      <SPAN CLASS=small><BR>@tasks.update_time@ ago</SPAN>
      </if>
  </TD>
  <TD>@tasks.count@</TD>
  <TD ALIGN=RIGHT>@tasks.icons@</TD>
 </row>
</multirow>
</border>
<multipage name=tasks>

