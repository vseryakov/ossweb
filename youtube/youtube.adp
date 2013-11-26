<master src=index>

<STYLE>
.d {
  font-size: 10pt;
  color: gray;
}
</STYLE>


<TABLE WIDTH=100% BORDER=0>
<TR><TD><%=[ossweb::html::title YouTube]%></TD>
    <TD ALIGN=RIGHT><formwidget id=form_yt.category></TD>
</TR>
</TABLE>

<TABLE WIDTH=100% BORDER=0 CELLSPACING=5 CELLPADDING=0>
<multirow name=youtube>
<TR VALIGN=TOP>
   <TD ROWSPAN=2>
       <A HREF="javascript:;" onClick="window.open('@youtube.playurl@','YT','width=330,height=250,menubar=0,location=0');return false;"><IMG SRC=images/@youtube.id@.jpg></A>
   </TD>
   <TD><B>@youtube.title@</B><BR>
       @youtube.author@<BR>
       @youtube.create_time@<BR>
       @youtube.duration@ seconds<BR>
       @youtube.views@ views (@youtube.rating@ rating)
   </TD>
</TR>
<row type=plain underline=1 colspan=3 VALIGN=TOP>
   <TD COLSPAN=2 CLASS=d>@youtube.description@</TD>
</row>
</multirow>
</TABLE>
