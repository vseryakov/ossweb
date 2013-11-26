<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<master mode=lookup>

<if @ossweb:cmd@ in recorder>
   <formtemplate id=form_record>
   <formerror id=form_record>
   <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
   <TR VALIGN=TOP>
      <TD STYLE="font-weight:bold;">
      <%=[ossweb::html::title "TV Guide Recorded Shows"]%><BR>
      <%=[ossweb::lookup::link -text "View TV Guide Listing" cmd view lineup_id $lineup_id now $now]%><BR>
      <%=[ossweb::lookup::link -text "View Currently Playing" cmd current lineup_id $lineup_id]%>
      </TD>
      <TD ALIGN=RIGHT>
        <TABLE BORDER=0>
        <TR><TD>Start:</TD><TD><formwidget id=start_date></TD>
            <TD>End:</TD><TD><formwidget id=end_date></TD>
            <TD><formwidget id=go></TD>
        </TR>
        </TABLE>
        Total Recorded: <B>@disk_taken@ Mb</B>, Free Space: <B>@disk_avail@ Mb</B>
      </TD>
   </TR>
   </TABLE>
   </formtemplate>
   <P>
   <border>
   <rowfirst>
    <TH>Channel</TH>
    <TH>Start Time</TH>
    <TH>Duration</TH>
    <TH>Program</TH>
    <TH>Status</TH>
    <TH>Watch</TH>
    <TH>Size</TH>
    <TH>Statistics</TH>
    <TD WIDTH=1%></TD>
   </rowfirst>
   <multirow name=recorder>
   <row VALIGN=TOP>
    <TD>@recorder.channel_id@ @recorder.station_label@</TD>
    <TD>@recorder.start_time@</TD>
    <TD>@recorder.duration@</TD>
    <TD>@recorder.program_title@</TD>
    <TD STYLE="color: @recorder.file_color@">@recorder.file_status@</TD>
    <TD NOWRAP>@recorder.file_view@</TD>
    <TD><if @recorder.file_size@ ne "">@recorder.file_size@ Mb</if></TD>
    <TD STYLE="font-family:times;font-size: 6pt;color:grey;">
       <if @recorder.watch_count@ ne "">Watched: @recorder.watch_count@, Last: @recorder.watch_time@</if>
    </TD>
    <TD ALIGN=RIGHT NOWRAP>@recorder.action@</TD>
    <TD></TD>
   </row>
   </multirow>
   </border>
   <return>
</if>

<if @ossweb:cmd@ in show schedule unschedule movie>
   <formtemplate id=form_program>
   <%=[ossweb::html::title $program_title]%> <if @program_year@ ne "">(@program_year@)</if><BR>
   <B>@program_subtitle@
   <if @part_number@ ne "">Part @part_number@</if> 
   <if @episode_number@ ne "">Episode @episode_number@</if>
   @mpaarating@ @tvrating@ @starrating@ @stereo@ @closecaptioned@
   <BR>
   @channel_id@/@station_name@ @affiliate@, @start_time@, @duration@<BR>
   @genre_list@</B><P>
   @description@<P>
   @crew_list@<P>
   <if @jpeg_name@ ne "">
     <IMG SRC=<%=[ossweb::file::url tvguide $jpeg_name]%> WIDTH=100 HEIGHT=140 BORDER=0>
   </if>
   <P>&nbsp;<P>
   <TABLE WIDTH=100% BORDER=0>
   <TR><TD HEIGHT=1><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1></TD></TR>
   <TR><TD><formwidget id=schedule> <formwidget id=unschedule> 
           <formwidget id=stop> <formwidget id=movie>
       </TD>
   </TR>
   </TABLE>
   </formtemplate>
   <return>
</if>

<SCRIPT>
function lineupSubmit(form)
{
   if(form.search_text.value != "") form.cmd.value="search";
   return true;
}
</SCRIPT>

<formtemplate id=form_lineup>
<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP>
   <TD WIDTH=30% STYLE="font-weight:bold;">
     <%=[ossweb::lookup::link -text "TV Guide Listing" cmd view]%><BR>
     <%=[ossweb::lookup::link -text "View Recorded Shows" cmd recorder lineup_id $lineup_id now $now]%><BR>
     <%=[ossweb::lookup::link -text "View Currently Playing" cmd current lineup_id $lineup_id]%>
   </TD>
   <TD><TABLE WIDTH=100% BORDER=0 CELLSAPCING=0 CELLPADDING=0>
       <TR><TD><formlabel id=lineup_id>:</TD><TD><formwidget id=lineup_id></TD></TR>
       <TR><TD><formlabel id=search_text>:</TD><TD><formwidget id=search_text></TD></TR>
       </TABLE>
   </TD>
   <TD ALIGN=RIGHT><formwidget id=now></TD><TD><formwidget id=go></TD>
</TR>
</TABLE>
</formtemplate>
<P>

<if @tvguide:rowcount@ eq 0><return></if>

<if @ossweb:cmd@ in current search>
   <border border2=1>
   <TR BGCOLOR=#CCCCCC>
     <TH WIDTH=1% >Channel</TH>
     <TH>Time, Duration</TH>
     <TH>Program</TH>
     <TH>Rating</TH>
     <TH>Genre</TH>
   </TR>
   <multirow name=tvguide>
   <TR VALIGN=TOP>
   <TD WIDTH=1% NOWRAP STYLE="background-color:#ced8ef;color:#23314f;"><B>@tvguide.channel_id@ @tvguide.station_label@</B></TD>
   <TD>@tvguide.start_time@, @tvguide.duration@</TD>
   <TD>@tvguide.url@ @tvguide.program_subtitle@
       <if @tvguide.part_number@ ne "">Part @tvguide.part_number@</if> 
       <if @tvguide.episode_number@ ne "">Episode @tvguide.episode_number@</if>
        @tvguide.stereo@ @tvguide.closecaptioned@
   </TD>
   <TD>@tvguide.mpaarating@ @tvguide.tvrating@ @tvguide.starrating@&nbsp;</TD>
   <TD>@tvguide.genre@&nbsp;</TD>
   </TR>
   </multirow>
   </border>

<else>

<border border2=1>
<TR BGCOLOR=#CCCCCC>
 <TH WIDTH=1% >Channel</TH>
 <TD NOWRAP><B><%=[ossweb::html::link -text "&lt;&lt;" cmd view lineup_id $lineup_id now [ossweb::date -expr $now -3600*2]]%> &nbsp;<if @hour1@ ne "">@hour1@:00</if></B></TD>
 <TH><if @hour1@ ne "">@hour1@:30</if></TH>
 <TH><if @hour2@ ne "">@hour2@:00</if></TH>
 <TH><if @hour2@ ne "">@hour2@:30</if></TH>
 <TH><if @hour3@ ne "">@hour3@:00</if></TH>
 <TH><if @hour3@ ne "">@hour3@:30</if></TH>
 <TH><if @hour4@ ne "">@hour4@:00</if></TH>
 <TD ALIGN=RIGHT NOWRAP><B><if @hour4@ ne "">@hour4@:30</if> &nbsp;<%=[ossweb::html::link -text "&gt;&gt;" cmd view lineup_id $lineup_id now [ossweb::date -expr $now +3600*3]]%></B></TD>
</TR>
<multirow name=tvguide>
 <TR VALIGN=TOP>
 <TD NOWRAP STYLE="background-color:#ced8ef;color:#23314f;"><B>@tvguide.channel@ @tvguide.station@</B></TD>
 <TD>@tvguide.line1@&nbsp;</TD>
 <TD>@tvguide.line12@&nbsp;</TD>
 <TD>@tvguide.line2@&nbsp;</TD>
 <TD>@tvguide.line22@&nbsp;</TD>
 <TD>@tvguide.line3@&nbsp;</TD>
 <TD>@tvguide.line32@&nbsp;</TD>
 <TD>@tvguide.line4@&nbsp;</TD>
 <TD>@tvguide.line42@&nbsp;</TD>
 </TR>
 <if @tvguide:rownum@ in 30 60 90 120 150 180 210 240 270 300 330 360 390 420 450 480 510 540 570 600 630 660 690 720 750 780 810 840 870 900 930 960 990>
 <TR BGCOLOR=#CCCCCC>
 <TH WIDTH=1% ><A NAME=@tvguide:rownum@>&nbsp;</A></TH>
 <TD NOWRAP><B><%=[ossweb::html::link -hash @tvguide:rownum@ -text "&lt;&lt;" cmd view lineup_id $lineup_id now [ossweb::date -expr $now -3600*2]]%> &nbsp;<if @hour1@ ne "">@hour1@:00</if></B></TD>
 <TH><if @hour1@ ne "">@hour1@:30</if></TH>
 <TH><if @hour2@ ne "">@hour2@:00</if></TH>
 <TH><if @hour2@ ne "">@hour2@:30</if></TH>
 <TH><if @hour3@ ne "">@hour3@:00</if></TH>
 <TH><if @hour3@ ne "">@hour3@:30</if></TH>
 <TH><if @hour4@ ne "">@hour4@:00</if></TH>
 <TD ALIGN=RIGHT NOWRAP><B><if @hour4@ ne "">@hour4@:30</if> &nbsp;<%=[ossweb::html::link -hash @tvguide:rownum@ -text "&gt;&gt;" cmd view lineup_id $lineup_id now [ossweb::date -expr $now +3600*3]]%></B></TD>
 </TR>
 </if>
</multirow>
<TR BGCOLOR=#CCCCCC>
 <TH WIDTH=1% ><A NAME=end>Channel</A></TH>
 <TD NOWRAP><B><%=[ossweb::html::link -hash end -text "&lt;&lt;" cmd view lineup_id $lineup_id now [ossweb::date -expr $now -3600*2]]%> &nbsp;<if @hour1@ ne "">@hour1@:00</if></B></TD>
 <TH><if @hour1@ ne "">@hour1@:30</if></TH>
 <TH><if @hour2@ ne "">@hour2@:00</if></TH>
 <TH><if @hour2@ ne "">@hour2@:30</if></TH>
 <TH><if @hour3@ ne "">@hour3@:00</if></TH>
 <TH><if @hour3@ ne "">@hour3@:30</if></TH>
 <TH><if @hour4@ ne "">@hour4@:00</if></TH>
 <TD ALIGN=RIGHT NOWRAP><B><if @hour4@ ne "">@hour4@:30</if> &nbsp;<%=[ossweb::html::link -hash end -text "&gt;&gt;" cmd view lineup_id $lineup_id now [ossweb::date -expr $now +3600*3]]%></B></TD>
</TR>
</border>

</if>

<P>
<formtemplate id=form_lineup>
<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP>
   <TD WIDTH=30% STYLE="font-weight:bold;">
      <%=[ossweb::lookup::link -text "TV Guide Listing" cmd view]%><BR>
      <%=[ossweb::lookup::link -text "View Recorded Shows" cmd recorder lineup_id $lineup_id now $now]%><BR>
      <%=[ossweb::lookup::link -text "View Currently Playing" cmd current lineup_id $lineup_id]%>
   </TD>
   <TD><TABLE WIDTH=100% BORDER=0 CELLSAPCING=0 CELLPADDING=0>
       <TR><TD><formlabel id=lineup_id>:</TD><TD><formwidget id=lineup_id></TD></TR>
       <TR><TD><formlabel id=search_text>:</TD><TD><formwidget id=search_text></TD></TR>
       </TABLE>
   </TD>
   <TD ALIGN=RIGHT><formwidget id=now></TD><TD><formwidget id=go></TD>
</TR>
</TABLE>
</formtemplate>

