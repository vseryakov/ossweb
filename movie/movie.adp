<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<if @ossweb:cmd@ eq info>
  <DIV STYLE="width:300px;">
  <B>@movie_title@</B> @movie_year@
  <P>
  @movie_genre@
  <P>
  <TABLE>
  <TR VALIGN=TOP>
     <TD><if @image@ ne ""><IMG SRC=@image@ WIDTH=96 HEIGHT=140></if></TD>
     <TD STYLE="color:#4e5557;font-size:7pt;">@movie_info@</TD>
  </TR>
  </TABLE>
  <P>
  <if @imdb_id@ ne ""><A HREF=http://www.imdb.com/title/tt@imdb_id@ TARGET=IMDB>IMDB Info</A><P></if>
  </DIV>
  <return>
</if>

<master mode=lookup>

<if @ossweb:cmd@ eq disks>
  <TABLE WIDTH=100%% BORDER=0 CELLSPACING=0 CELLPADDING=5>
  <TR><TD><ossweb:title><ossweb:link -lookup t -text "Disks Report" cmd disks></ossweb:title></TD>
      <TD ALIGN=CENTER>Max: <B>@disk_max@<B></TD>
      <TD ALIGN=RIGHT NOWRAP>
         <formtemplate id=form_disk>
          Search: <formwidget id=disk_id>
         </formtemplate>
      </TD>
  </TR>
  </TABLE>
  <P>
  <border>
  <rowfirst><TH>Disk</TH><TH>File</TH><TH>Size</TH></rowfirst>
  <multirow name=disks>
  <row><TD>@disks.disk_id@</TD><TD>@disks.file_name@</TD><TD>@disks.size@</TD></row>
  </multirow>
  </border>

  <if @disk_id@ ne "">
  <P>
  <ossweb:title>#@disk_id@ Files List</ossweb:title>
  <DIV STYLE="font-size:5pt;color:gray;">
  <multirow name=disks>@disks.file_name@ </multirow>
  </DIV>
  </if>
  <return>
</if>

<if @ossweb:cmd@ eq edit>
  <formtemplate id=form_movie style=fieldset>
  <CENTER><formerror id=form_movie></CENTER>
  <border style=white>
  <TR><TD CLASS=osswebFormTitle>Movie Details #<%=[ossweb::html::link -text $movie_id cmd edit movie_id $movie_id page $page]%></TD></TR>
  <TR><TD><formlabel id=movie_title></TD>
      <TD><formwidget id=movie_title> <formwidget id=movie_title name=info></TD>
      <TD ALIGN=RIGHT>
         <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
         <TR><TD><formlabel id=create_time>: </TD><TD><formwidget id=create_time></TD></TR>
         <TR><TD><formlabel id=update_time>: </TD><TD><formwidget id=update_time></TD></TR>
         </TABLE>
      </TD>
  </TR>
  <TR><TD><formlabel id=movie_descr></TD>
      <TD><formwidget id=movie_descr></TD>
      <TD ALIGN=RIGHT ROWSPAN=5><formwidget id=movie_descr name=info></TD>
  </TR>
  <TR><TD><formlabel id=movie_age></TD><TD><formwidget id=movie_age></TD></TR>
  <TR><TD><formlabel id=movie_genre></TD><TD><formwidget id=movie_genre></TD></TR>
  <TR><TD><formlabel id=movie_lang></TD><TD><formwidget id=movie_lang></TD></TR>
  <TR><TD><formlabel id=movie_year></TD><TD><formwidget id=movie_year></TD></TR>
  <TR><TD><formlabel id=imdb_id></TD>
      <TD><formwidget id=imdb_id> <formwidget id=imdb_id name=info></TD>
  </TR>
  <TR><TD><formlabel id=image_name></TD><TD><formwidget id=image_name></TD></TR>
  <TR>
    <TD ALIGN=RIGHT COLSPAN=3>
      <formwidget id=update> <formwidget id=update2>
      <formwidget id=delete> <formwidget id=new> <formwidget id=back>
    </TD>
  </TR>
  </border>
  </formtemplate>
  <P>
  <if @movie_id@ ne "">
    <help_title>Movie Files</help_title>
    <formtemplate id=form_file>
    <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=5>
    <rowfirst><TH>Disk</TH>
              <TH>File Name</TH>
              <TH>Size</TH>
              <TH>Info</TH>
              <TD ALIGN=RIGHT>
                 <if @allow@ eq 0>
                 <formlabel id=file_name>: <formwidget id=file_name> &nbsp;&nbsp;
                 <formlabel id=disk_id>: <formwidget id=disk_id>
                 </if>
              </TD>
              <TD WIDTH=1% ALIGN=CENTER><formwidget id=add></TD>
    </rowfirst>
    <multirow name=files>
    <row type=plain underline=1 colspan=6>
      <TD>@files.disk_id@</TD>
      <TD>@files.file_path@ @files.file_params@</TD>
      <TD NOWRAP>@files.size@ Mb</TD>
      <TD COLSPAN=2>@files.file_info@</TD>
      <if @allow@ eq 0><TD ALIGN=RIGHT NOWRAP>@files.edit@</TD></if>
    </row>
    </multirow>
    </TABLE>
    </formtemplate>
  </if>
  <return>
</if>

<SCRIPT>
function movieOver(id)
{
   var obj = $('Movie'+id);
   obj.style.textDecoration = 'underline';
   obj.style.cursor = 'help';
   var url = "pagePopupGet('<%=[ossweb::html::url cmd info movie_id ""]%>"+id+"',{hide:1,bgcolor:'#eee',custom:popupPosition})";
   obj.timer = setTimeout(url,1000);
}
function movieOut(id)
{
   var obj = $('Movie'+id);
   if(obj.timer) clearTimeout(obj.timer);
   obj.style.textDecoration = 'none';
   obj.style.cursor = 'default';
}
</SCRIPT>

<help_title>Movies</help_title>
<formtemplate id=form_movie>
<border style=white>
<TR VALIGN=TOP>
 <TD><formlabel id=movie_title><BR><formwidget id=movie_title><P>
     <formlabel id=create_time><BR><formwidget id=create_time>
 </TD>
 <TD NOWRAP>
    <formlabel id=movie_descr><BR><formwidget id=movie_descr><P>
 </TD>
 <TD><formlabel id=movie_genre><BR><formwidget id=movie_genre></TD>
 <TD><formlabel id=movie_lang><BR><formwidget id=movie_lang><P>
     <formlabel id=movie_age><BR><formwidget id=movie_age></TD>
 <TD><formlabel id=movie_year><BR><formwidget id=movie_year></TD>
 <TD><formlabel id=imdb_id><BR><formwidget id=imdb_id><P>
     <formlabel id=disk_id><BR><formwidget id=disk_id>
 </TD>
</TR>
<TR>
 <TD COLSPAN=6 ALIGN=RIGHT>
   <formwidget id=search> <formwidget id=reset> <formwidget id=new> <formwidget id=disks> <formwidget id=export>
 </TD>
</TR>
</border>
</formtemplate>
<P>
<multipage name=movies>
<border style=curved4>
<rowfirst>
 <TD WIDTH=1% ></TD>
 <TH>Title</TH>
 <TH>Description</TH>
 <TH>Year</TH>
 <TH>Genre</TH>
 <TH>Language</TH>
 <if @allow@ eq 0><TH>Play</TH></if>
</rowfirst>
<multirow name=movies>
<row VALIGN=TOP type=plain underline=1>
 <TD ID=Movie@movies.movie_id@ onMouseOver="movieOver(@movies.movie_id@)" onMouseOut="movieOut(@movies.movie_id@)">
   <if @movies.image@ ne ""><IMG SRC=@movies.image@ WIDTH=45 HEIGHT=55></if>
 </TD>
 <TD>@movies.movie_title@</TD>
 <TD>@movies.movie_descr@</TD>
 <TD>@movies.movie_year@</TD>
 <TD>@movies.movie_genre@</TD>
 <TD>@movies.movie_lang@</TD>
 <if @allow@ eq 0><TD WIDTH=5% >@movies.edit@</TD></if>
</row>
</multirow>
</border>
<multipage name=movies>
