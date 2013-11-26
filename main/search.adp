<if @ossweb:cmd@ eq rss>
   <?xml version="1.0"?>
   <rss version="2.0">
   <channel>
   <title>@q@</title>
   <link><%=[ns_quotehtml [ossweb::conn -url -host t]]%></link>
   <description>Search Results for @q@</description>
   <multirow name=result>
   <item>
     <title>@result.tsearch_text@</title>
     <description>Type: @result.tsearch_type@, Rank: @result.tsearch_rank@</description>
     <guid isPermaLink="false"><%=[ns_quotehtml [ossweb::conn::hostname]@result.tsearch_url@]%></guid>
   </item>
   </multirow>
   </channel>
   </rss>
   <return>
</if>

<if @ossweb:cmd@ eq popup>
  <SPAN STYLE="font-weight:bold;color:green;text-decoration:underline;">Search</SPAN>
  <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
  <TR><TD ALIGN=CENTER>
      <formtemplate id=form_search>
      <formerror id=form_search><BR>
      <formwidget id=q> <formwidget id=cmd> in <formwidget id=t>
      </formtemplate>
      </TD>
  </TR>
  </TABLE>
  <return>
</if>

<master mode=lookup>

<STYLE>
.ts {
  font-size: 7pt;
  color: green;
}
</STYLE>

<CENTER>
<border style=curved6 width=80% title=Search>
<TR><TD ALIGN=CENTER>
    <formtemplate id=form_search>
    <formerror id=form_search><BR>
    <formwidget id=q> <formwidget id=cmd> in <formwidget id=t>
    </formtemplate>
    </TD>
    <TD NOWRAP WIDTH=10% STYLE="color:#868686;font-size:7pt;">
    Default search is for all words<BR>
    To search for at least one word, separate them by |<BR>
    </TD>
</TR>
</border>
</CENTER>
<P>
<if @ossweb:cmd@ in search page>
  <%=[ossweb::html::link -image feed.png -alt "RSS Feed" cmd rss q $q t $t]%>
  Found @found@ documents in @elapsed@ ms
  <multipage name=result>
  <UL>
  <multirow name=result>
  <LI>@result.tsearch_link@<BR>
      <SPAN CLASS=ts>Type: @result.tsearch_type@, Rank: @result.tsearch_rank@</SPAN>
  </multirow>
  </UL>
  <multipage name=result>
</if>

