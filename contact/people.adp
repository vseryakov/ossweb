<if @ossweb:cmd@ eq file><return></if>

<master src=@master@>

<if @ossweb:cmd@ eq edit>
   <STYLE>
    .gray {
      color: gray;
      text-decoration: underline;
    }
   </STYLE>
   <formtemplate id=form_people style=fieldset>
   <formerror id=form_people>
   <border style=white cellspacing=1 cellpadding=1>
   <TR VALIGN=TOP>
      <TD><TABLE WIDTH=100% BORDER=0 CELLSPACING=2 CELLPADDING=0>
          <TR><TD><formlabel id=salutation></TD>
              <TD><formlabel id=first_name></TD>
              <TD><formlabel id=middle_name></TD>
              <TD><formlabel id=last_name></TD>
              <TD><formlabel id=suffix></TD>
          </TR>
          <TR><TD><formwidget id=salutation></TD>
              <TD><formwidget id=first_name></TD>
              <TD><formwidget id=middle_name></TD>
              <TD><formwidget id=last_name></TD>
              <TD><formwidget id=suffix></TD>
          </TR>
          </TABLE>
      </TD>
      <TD WIDTH=15% ALIGN=CENTER ROWSPAN=3>
         <FIELDSET><LEGEND><B>Picture</B></LEGEND>
         <if @picture@ eq ""><DIV STYLE="width:100;height:100;">No picture available</DIV></if>
         @picture@<P><formwidget id=picture>
         </FIELDSET>
      </TD>
   </TR>
   <TR><TD HEIGHT=1><IMG SRC=/img/misc/graypixel.gif BORDER=0 HEIGHT=1 WIDTH=100% ></TD>
   <TR VALIGN=BOTTOM>
      <TD><TABLE WIDTH=100% BORDER=0 CELLSPACING=2 CELLPADDING=0>
          <TR><TD><formlabel id=birthday></TD>
              <TD><formlabel id=access_type></TD>
              <TD><formlabel id=company_id></TD>
              <TD><formlabel id=description></TD>
          </TR>
          <TR VALIGN=TOP>
              <TD STYLE="padding-right: 25;"><formwidget id=birthday></TD>
              <TD STYLE="padding-right: 25;"><formwidget id=access_type></TD>
              <TD STYLE="padding-right: 35;" NOWRAP><formwidget id=company_id></TD>
              <TD ROWSPAN=2><formwidget id=description></TD>
          </TR>
          </TABLE>
          <if @ossweb:ctx@ ne edit>
          <P>
          <formwidget id=search> |
          <if @people_id@ ne "">
          <%=[ossweb::lookup::link -text View -alt Refresh cmd edit people_id $people_id page $page]%>  |
          </if>
          <formwidget id=edit> | <formwidget id=address> |
          <formwidget id=entry | <formwidget id=back>
          </if>
      </TD>
   </TR>
   <if @ossweb:ctx@ eq edit>
   <TR><TD NOWRAP COLSPAN=2>
       <formwidget id=back> <formwidget id=update> <formwidget id=delete>
       </TD>
   </TR>
   </if>
   </border>
   </formtemplate>

   <if @people_id@ eq "" or @ossweb:ctx@ eq edit><return></if>

   <if @ossweb:ctx@ eq address>
      <formtemplate id=form_address style=fieldset></formtemplate>
      <return>
   </if>

   <if @ossweb:ctx@ eq entry>
      <formtemplate id=form_entry style=fieldset></formtemplate>
      <return>
   </if>

   <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
   <if @addresses:rowcount@ gt 0>
   <TR VALIGN=TOP>
      <TD>
         <FIELDSET STYLE="border-bottom:0px;border-right:0px;border-left:0px;">
         <LEGEND><B>Address Log</B></LEGEND>
         <TABLE WIDTH=100% BORDER=0 CELLSPACING=0>
         <multirow name=addresses>
         <TR VALIGN=TOP><TD>@addresses.name@</TD><TD>@addresses.description@</TD></TR>
         </multirow>
         </TABLE>
         </FIELDSET>
      </TD>
   </TR>
   </if>
   <TR VALIGN=TOP>
      <TD>
         <FIELDSET STYLE="border-bottom:0px;border-right:0px;border-left:0px;">
         <LEGEND><B>Contact Log</B></LEGEND>
         <TABLE WIDTH=100% BORDER=0 CELLSPACING=0>
         <TR><TD COLSPAN=5 ALIGN=RIGHT STYLE="font-size:8pt;">
             <formtemplate id=form_filter>
             <formlabel id=entry_sort>: <formwidget id=entry_sort> &nbsp;&nbsp;
             <formlabel id=entry_filter>: <formwidget id=entry_filter>
             <formwidget id=go>
             </formtemplate>
             </TD></TR>
         <multirow name=entries>
         <TR VALIGN=TOP>
            <TD>@entries.entry_name@</TD>
            <TD>@entries.entry_value@</TD>
            <TD>@entries.entry_date@ <if @entries.entry_notify@ ne "">(@entries.entry_notify@)</if></TD>
            <TD>@entries.entry_file@</TD>
            <TD CLASS=osswebSmallText ALIGN=RIGHT NOWRAP>@entries.update_user_name@ @entries.update_date@</TD>
         </TR>
         <TR HEIGHT=1><TD COLSPAN=5 NOWRAP><IMG SRC=/img/misc/dottedline2.gif HEIGHT=1 WIDTH=100% ></TD>
         </TR>
         </multirow>
         </TABLE>
         </FIELDSET>
      </TD>
   </TR>
   </TABLE>
   <return>
</if>

<formtemplate id=form_search>
<formerror id=form_search>
<FIELDSET>
<LEGEND CLASS=osswebTitle>People Search</LEGEND>
<TABLE BORDER=0 WIDTH=100% >
<TR VALIGN=TOP>
  <TD>
     <formlabel id=first_name><BR><formwidget id=first_name><BR>
     <formlabel id=last_name><BR><formwidget id=last_name><BR>
     <formlabel id=birthday><BR><formwidget id=birthday>
  </TD>
  <TD NOWRAP>
     <formlabel id=entry_name><BR><formwidget id=entry_name><BR>
     <formlabel id=company_name><BR><formwidget id=company_name>
  </TD>
  <TD NOWRAP>
     <SPAN CLASS=osswebFormLabel>Address</SPAN><BR>
     <formwidget id=number> <formwidget id=street><BR>
     <formwidget id=unit_type> <formwidget id=unit><BR>
     <formwidget id=city><BR>
     <formwidget id=state> <formwidget id=zip_code>
  </TD>
</TR>
<TR>
  <TD COLSPAN=3 ALIGN=RIGHT>
     <formwidget id=search>
     <formwidget id=reset>
     <formwidget id=add>
     <formwidget id=export>
  </TD>
</TR>
</TABLE>
</FIELDSET>
</formtemplate>

<multipage name=people>
<border>
<rowfirst>
   <TH>Name</TH>
   <TH>Phone</TH>
   <TH>Email</TH>
   <TH>Company</TH>
   <TH>Birthday</TH>
   <TH>Notes</TH>
   <TD ALIGN=RIGHT></TD>
</rowfirst>
<multirow name=people>
<row VALIGN=TOP>
   <TD>@people.name@</TD>
   <TD>@people.phone@</TD>
   <TD>@people.email@</TD>
   <TD>@people.company_name@</TD>
   <TD>@people.birthday@</TD>
   <TD>@people.description@</TD>
   <TD ALIGN=RIGHT>@people.picture@</TD>
</row>
</multirow>
</border>
<multipage name=people>
