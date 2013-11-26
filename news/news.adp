<master src=index>

<STYLE>
.n {
  font-size: 12pt;
  font-weight: bold;
}
.s {
  color: gray;
  font-size: 8pt;
}
</STYLE>

<TABLE WIDTH=100% BORDER=0>
<TR><TD><%=[ossweb::html::title News]%></TD></TR>
</TABLE>

<TABLE WIDTH=100% BORDER=0 CELLSPACING=5 CELLPADDING=0>
<multirow name=news>
<if @category@ ne @news.category@>
</TABLE><P>
<if @category@ ne "">&nbsp;<P></if>
<% set category @news.category@ %>
<A NAME=@category@></A>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR VALIGN=TOP>
  <TD NOWRAP BGCOLOR=#EFEFEF><B>@category@</B></TD>
  <TD NOWRAP BGCOLOR=#EFEFEF ALIGN=RIGHT>
     <A HREF=#GENERAL>Top Stories</A> |
     <A HREF=#WORLD>World</A> |
     <A HREF=#REGION>Region(<%=[string toupper [ossweb::config news:country us]]%>)</A> |
     <A HREF=#BUSINESS>Business</A> |
     <A HREF=#TECH>Sci/Tech</A> |
     <A HREF=#SPORTS>Sports</A> |
     <A HREF=#ENTERTAINMENT>Entertainment</A> |
     <A HREF=#HEALTH>Health</A>
  </TD>
</TR>
</TABLE>
<P>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=5 CELLPADDING=0>
</if>

<TR VALIGN=TOP>
   <TD><A HREF=@news.link@ CLASS=n TARGET=n>@news.title@</A></TD>
   <TD CLASS=s NOWRAP ALIGN=RIGHT>
      @news.pubdate@
      <if @news.old_flag@ eq ""><IMG SRC=/img/new.gif BORDER=0></if>
   </TD>
</TR>
<row type=plain underline=1 VALIGN=TOP>
    <TD>@news.description@</TD>
    <TD CLASS=s ALIGN=RIGHT VALIGN=BOTTOM>@news.category@</TD>
</row>
</multirow>
</TABLE>
