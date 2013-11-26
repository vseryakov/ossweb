<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<master mode=lookup>

<if @ossweb:cmd@ eq panel>
  <formtemplate id=form_music>
  <TABLE WIDTH=100% BORDER=0 CELLSPACING=1 CELLPADDING=0>
  <TR><TD>&nbsp;</TD></TR>
  <TR><TD><B>Playing</B>:</TD><TD>@music:file@</TD></TR>
  <TR><TD><B>Size</B>:</TD><TD>@music:size@</TD></TR>
  <TR HEIGHT=1><TD COLSPAN=2><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1></TD></TR>
  <TR><TD COLSPAN=2><formwidget id=random> <formlabel id=random></TD></TR>
  <TR><TD COLSPAN=2 ALIGN=CENTER>
      <formwidget id=play> <formwidget id=stop> <formwidget id=next>
      </TD>
  </TR>
  </TABLE>
  </formtemplate>
  <return>
</if>

<help_title>Music</help_title>
<formtemplate id=form_music>
<border>
<rowlast VALIGN=TOP>
 <TD><formlabel id=filter><BR><formwidget id=filter> <formwidget id=search></TD>
 <TD ALIGN=RIGHT><B>Playing</B>: @music:file@<BR><formwidget id=random> <formlabel id=random></TD>
</rowlast>
<rowlast>
 <TD COLSPAN=2 ALIGN=RIGHT>
   <formwidget id=play>
   <formwidget id=stop>
   <formwidget id=next>
   <formwidget id=panel>
 </TD>
</rowlast>
</border>
</formtemplate>
<P>
<border>
<rowfirst>
 <TH>File</TH>
 <TH>Size</TH>
 <TH>Play</TH>
</rowfirst>
<multirow name=music>
<row VALIGN=TOP>
 <TD>@music.file@</TD>
 <TD>@music.size@</TD>
 <TD ALIGN=RIGHT>@music.play@</TD>
</row>
</multirow>
</border>
