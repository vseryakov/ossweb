<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<master src=index>

<if @ossweb:cmd@ eq edit and @ossweb:ctx@ eq photo>
  <formtab id=form_tab style=square><BR>
  <TABLE WIDTH=600>
  <TR><TD><formtemplate id=form_photo border_style=white border_class=None first_row=None last_row=None></formtemplate></TD>
      <TD><IMG SRC=@thumbnail_url@ BORDER=0 WIDTH=@width@ HEIGHT=@height@></TD>
  </TR>
  </TABLE>
  <P><IMG SRC=@image_url@ BORDER=0>
  <return>
</if>

<if @ossweb:cmd@ eq edit>
  <formtab id=form_tab style=square><BR>
  <if @tab@ eq edit>
    <formtemplate id=form_album border_style=white border_class=None class:first=None class:last=None></formtemplate>
  </if>
  <if @tab@ eq upload>
    <formtemplate id=form_upload border_style=white border_class=None class:first=None class:last=None></formtemplate>
  </if>
  <if @tab@ eq photos>
    <multipage name=photos>
    <TABLE BORDER=0 WIDTH=100% ><TR>
    <multirow name=photos>
    <TD>@photos.image@<BR>@photos.file_name@: @photos.description@</TD>
    <if @photos.break@ eq 0></TR><TR></if>
    </multirow>
    </TABLE>
    <multipage name=photos>
  </if>
  <return>
</if>

<if @ossweb:cmd@ eq album>
   <%=[ossweb::html::title "Album: $album_name"]%><P>
   <multipage name=photos>
   <TABLE BORDER=0 WIDTH=100% ><TR>
   <multirow name=photos>
   <TD>@photos.image@<BR>@photos.description@</TD>
   <if @photos.break@ eq 0></TR><TR></if>
   </multirow>
   </TABLE>
   <multipage name=photos>
   <return>
</if>

<helptitle>Albums</helptitle>
<border>
<rowfirst>
  <TH>@album:add@ Name</TH>
  <TH>Description</TH>
  <TH>Photos</TH>
  <TH>Last Update</TH>
  <TH WIDTH=1% ></TH>
</rowfirst>
<multirow name=albums>
<row VALIGN=TOP>
   <TD>@albums.album_name@</TD>
   <TD>@albums.description@</TD>
   <TD>@albums.photo_count@</TD>
   <TD>@albums.update_date@</TD>
   <TD ALIGN=RIGHT>@albums.edit@</TD>
</row>
</multirow>
</border>
<return>


