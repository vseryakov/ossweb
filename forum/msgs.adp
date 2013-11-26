<if @ossweb:cmd@ eq error><master src=../index/index.title><return></if>

<case>
<when @ossweb:cmd@ eq topic and @format@ eq rss>
   <?xml version="1.0"?>
   <rss version="2.0">
   <channel><title>@forum_name@ @subject@</title>
   <link><%=[ns_quotehtml $html_url]%></link>
   <multirow name=msgs>
   <item>
     <title><%=[ns_striphtml [string range @msgs.body@ 0 64]]%></title>
     <description><%=[string trim [ns_striphtml @msgs.body@]]%></description>
     <pubDate>@msgs.create_date@</pubDate>
     <guid isPermaLink="true"><%=[ns_quotehtml [ossweb::conn::hostname]@msgs.url@]%></guid>
   </item>
   </multirow>
   </channel>
   </rss>
   <return>

<when @ossweb:cmd@ eq forum and @format@ eq rss>
   <?xml version="1.0"?>
   <rss version="2.0">
   <channel><title>@forum_name@</title>
   <link><%=[ns_quotehtml $html_url]%></link>
   <multirow name=topics>
   <item>
     <title><%=[ns_striphtml @topics.subject@]%></title>
     <description><%=[ns_striphtml "Created by @topics.user_name@, total messages @topics.msg_count@, last post on @topics.msg_timestamp@"]%></description>
     <pubDate>@topics.create_date@</pubDate>
     <guid isPermaLink="true"><%=[ns_quotehtml [ossweb::conn::hostname]@topics.url@]%></guid>
   </item>
   </multirow>
   </channel>
   </rss>
   <return>

<when @ossweb:cmd@ eq search and @format@ eq rss>
   <?xml version="1.0"?>
   <rss version="2.0">
   <channel><title>Search results for @body@ @ossweb:ctx@</title>
   <link><%=[ns_quotehtml $html_url]%></link>
   <multirow name=topics>
   <item>
     <title><%=[ns_striphtml @topics.subject@]%></title>
     <description><%=[string trim [ns_striphtml @topics.body@]]%></description>
     <pubDate>@topics.create_date@</pubDate>
     <guid isPermaLink="true"><%=[ns_quotehtml [ossweb::conn::hostname]@topics.url@]%></guid>
   </item>
   </multirow>
   </channel>
   </rss>
   <return>
</case>

<master mode=lookup>

<STYLE>
.forumPost {
  border: 1px dotted gray;
  margin: 10px;
  padding: 5px;
}
.forumLink {
  text-decoration: none;
  font-size: 8pt;
  color: #ABABAB;
}
.forumText {
  padding:10px;
  font-size: 10pt;
}
.forumQuote td {
  font-size: 8pt;
  color: black;
  padding: 10px;
}
.forumQuote table {
  background-color: #EEEEEE;
  border: 1px dotted gray;
  width: 70%;
}
</STYLE>

<if @ossweb:cmd@ eq sub>
   <formtemplate id=form_subscribe border_class=None border_style=white first_row=None last_row=None></formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq edit and @ossweb:ctx@ eq reply>
   <formtemplate id=form_reply title="Post a Reply to @subject@ in @forum_name@ Forum" border_class=None border_style=white first_row=None last_row=None></formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_post title="Post a Message to @forum_name@ Forum" border_class=None border_style=white first_row=None last_row=None></formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq topic>
   <formtemplate id=form_forum>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD><%=[ossweb::html::title "$forum_name: $subject"]%></TD></TR>
   <TR><TD>@rss_link@</TD>
       <TD ALIGN=RIGHT>
       <formwidget id=body> <formwidget id=search> <formwidget id=forum> <formwidget id=reply> <formwidget id=post>
       </TD>
   </TR>
   </TABLE>
   <P>
   <multirow name=msgs>
   <DIV CLASS=forumPost STYLE="margin-left:@msgs.padding@px;">
     <DIV CLASS=forumLink><A NAME=@msgs.msg_id@>@msgs.user_name@</A>, @msgs.create_date@</DIV>
     <DIV CLASS=forumText>@msgs.body@<BR></DIV>
     <DIV>@msgs.action@</DIV>
   </DIV>
   </multirow>
   <P>
   <if @msgs:rowcount@ gt 25>
   <TABLE BORDER=0>
   <TR><TD ALIGN=RIGHT><formwidget id=forum> <formwidget id=reply> <formwidget id=post></TD></TR>
   </TABLE>
   </if>
   </formtemplate>
   <return>
   <return>
</if>

<if @ossweb:cmd@ eq forum>
   <helptitle>@forum_name@</helptitle>
   <P>
   <formtemplate id=form_forum>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD>@rss_link@</TD>
       <TD ALIGN=RIGHT>
       <formwidget id=body> <formwidget id=search> <formwidget id=top> <formwidget id=post>
       <formwidget id=unseen> <formwidget id=recent> <formwidget id=sub>
       </TD>
   </TR>
   </TABLE>
   <P>
   <multipage name=topics>
   <border style=white>
   <TR><TH>Topic</TH>
       <TH>Post Date</TH>
       <TH>Created By</TH>
       <TH>Total Messages</TH>
       <TH>Last Post</TH>
       <TD></TD>
   </TR>
   <multirow name=topics>
    <row VALIGN=TOP type=plain underline=1>
     <TD>@topics.link@</TD>
     <TD>@topics.create_date@</TD>
     <TD>@topics.user_name@</TD>
     <TD>@topics.msg_count@</TD>
     <TD>@topics.msg_timestamp@</TD>
     <TD ID=forumActions WIDTH=1% ALIGN=RIGHT>@topics.action@</TD>
    </row>
   </multirow>
   </border>
   <multipage name=topics>
   <P>
   <if @topics:rowcount@ gt 25>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD ALIGN=RIGHT>
       <formwidget id=top> <formwidget id=post> <formwidget id=recent> <formwidget id=sub>
       </TD>
   </TR>
   </TABLE>
   </if>
   </formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq search>
   <helptitle>Forums Search Results</helptitle>
   <formtemplate id=form_search>
     <TABLE WIDTH=100% BORDER=0>
     <TR><TD>@rss_link@</TD>
         <TD ALIGN=RIGHT>
         <formwidget id=body> <formwidget id=search> <formwidget id=top> <formwidget id=unseen> <formwidget id=recent>
         </TD>
     </TR>
     </TABLE>
   </formtemplate>
   <border style=white>
   <TR><TH>Forum</TH>
       <TH>Subject</TH>
       <TH>Text</TH>
       <TH>Date</TH>
   </TR>
   <multirow name=topics>
   <row VALIGN=TOP type=plain underline=1>
    <TD>@topics.forum_name@</TD>
    <TD>@topics.link@</TD>
    <TD>@topics.body@</TD>
    <TD>@topics.create_date@</TD>
   </row>
   </multirow>
   </border>
   <return>
</if>

<helptitle>Forums</helptitle>

<formtemplate id=form_search>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD ALIGN=RIGHT>
       <formwidget id=body> <formwidget id=search> <formwidget id=unseen> <formwidget id=recent>
       </TD>
   </TR>
   </TABLE>
</formtemplate>

<border style=white>
<TR><TH>Forum</TH>
    <TH>Description</TH>
    <TH>Total Topics</TH>
    <TH>Last Post</TH>
</TR>
<multirow name=forums>
 <row VALIGN=TOP type=plain underline=1>
  <TD>@forums.forum_name@</TD>
  <TD>@forums.description@</TD>
  <TD>@forums.msg_count@</TD>
  <TD>@forums.msg_timestamp@</TD>
 </row>
</multirow>
</border>

