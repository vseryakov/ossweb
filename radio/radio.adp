<if @format@ eq tcl>
  <multirow name=radio>{@radio.radio_url@} {@radio.radio_title@} {@radio.radio_genre@}
  </multirow>
  <% ossweb::conn -set html:content_type text/plain %>
  <return>
</if>

<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<master mode=lookup>

<if @ossweb:cmd@ eq panel>
  <formtemplate id=form_radio>
  <TABLE WIDTH=100% BORDER=0 CELLSPACING=1 CELLPADDING=0>
  <TR><TD>&nbsp;</TD></TR>
  <TR><TD><B>Playing</B>:</TD><TD>@radio:station@</TD></TR>
  <TR HEIGHT=1><TD COLSPAN=2><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1></TD></TR>
  <TR><TD COLSPAN=2 ALIGN=CENTER>
      <formwidget id=play> <formwidget id=stop> <formwidget id=next>
      </TD>
  </TR>
  </TABLE>
  </formtemplate>
  <return>
</if>

<help_title>Shoutcast Radio Stations</help_title>
<formtemplate id=form_radio>
<border>
<rowlast VALIGN=TOP>
 <TD ALIGN=RIGHT><B>Playing</B>: @radio:station@</TD>
</rowlast>
<rowlast>
 <TD ALIGN=RIGHT>
   <formwidget id=play>
   <formwidget id=stop>
   <formwidget id=next>
   <formwidget id=panel>
   <formwidget id=refresh>
 </TD>
</rowlast>
</border>
</formtemplate>
<P>
<border>
<rowfirst>
 <TH>Station</TH>
 <TH>Genre</TH>
 <TH>Play</TH>
</rowfirst>
<multirow name=radio>
<row VALIGN=TOP>
 <TD>@radio.radio_title@</TD>
 <TD>@radio.radio_genre@</TD>
 <TD ALIGN=RIGHT>@radio.play@</TD>
</row>
</multirow>
</border>
