<if @ossweb:cmd@ eq rss>
   <?xml version="1.0"?>
   <rss version="2.0">
   <channel>
   <title>@tracker_title@</title>
   <link><%=[ns_quotehtml $tracker_link]%></link>
   <description>Update Tracker for @tracker_title@</description>
   <multirow name=result>
   <item>
     <title><%=[ns_quotehtml [ns_striphtml @result.subject@]]%></title>
     <description><%=[ns_quotehtml @result.text@]%></description>
     <pubDate>@result.time@</pubDate>
     <guid isPermaLink="true"><%=[ns_quotehtml [ossweb::conn::hostname]@result.url@]%></guid>
   </item>
   </multirow>
   </channel>
   </rss>
   <return>
</if>

<master mode=lookup>

<formtab id=form_tab style=square>

<if @result:rowcount@ eq 0>
   <return>
</if>

<STYLE>
 #tracker th td {
   font-size: 8pt;
 }
 #tracker span {
   font-size: 7pt;
   color: gray;
 }
</STYLE>
<TABLE WIDTH=100% BORDER=0>
<TR><TD><ossweb:title>@tracker_title@</ossweb:title></TD>
    <TD ALIGN=RIGHT><%=[ns_fmttime [ns_time]]%> @tracker_rss@ </TD>
</TABLE>
<BR>
<border id=tracker style=white>
<multirow name=result>
<row VALIGN=TOP type=plain colspan=3 underline=1>
  <TD><SPAN>@result.link@</SPAN><TD>
  <TD>@result.text@<BR>
     <SPAN>@result.age@ ago</SPAN>
  </TD>
</row>
</multirow>
</border>

