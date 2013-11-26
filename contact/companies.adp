<if @ossweb:cmd@ eq file><return></if>

<master mode=lookup>

<if @ossweb:cmd@ eq edit>
   <STYLE>
    .gray {
       color: gray;
       text-decoration: underline;
    }
   </STYLE>
   <formtemplate id=form_company style=fieldset>
   <formerror id=form_company>
   <border style=white cellspacing=1 cellpadding=1>
   <TR VALIGN=TOP>
      <TD><TABLE WIDTH=100% BORDER=0 CELLSPACING=2 CELLPADDING=0>
          <TR><TD><formlabel id=company_name></TD>
              <TD><formlabel id=company_url></TD>
              <TD><formlabel id=access_type></TD>
              <TD><formlabel id=description></TD>
              <TD><formlabel id=company_icon></TD>
              <TD VALIGN=TOP ALIGN=RIGHT><B><%=[ossweb::html::link -text #$company_id cmd edit company_id $company_id]%></B></TD>
          </TR>
          <TR VALIGN=TOP>
              <TD STYLE="padding-right: 35;"><formwidget id=company_name></TD>
              <TD STYLE="padding-right: 35;"><formwidget id=company_url></TD>
              <TD STYLE="padding-right: 35;"><formwidget id=access_type></TD>
              <TD><formwidget id=description></TD>
              <TD colspan=2><formwidget id=company_icon name=html:data></TD>
          </TR>
          </TABLE>
      </TD>
   </TR>
   <TR><TD NOWRAP COLSPAN=2>
       <if @ossweb:ctx@ eq edit>
       <formwidget id=back> <formwidget id=update> <formwidget id=delete>
       <else>
       <formwidget id=search> |
       <if @company_id@ ne "">
       <%=[ossweb::lookup::link -text View -alt Refresh cmd edit company_id $company_id page $page]%>  |
       </if>
       <formwidget id=edit> | <formwidget id=address> |
       <formwidget id=entry> | <formwidget id=back>
       </if>
       </TD>
   </TR>
   </border>
   </formtemplate>
   
   <if @company_id@ eq "" or @ossweb:ctx@ eq edit><return></if>

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
<FIELDSET>
<LEGEND CLASS=osswebTitle>Company Search</LEGEND>
<TABLE BORDER=0 WIDTH=100% >
<TR VALIGN=TOP>
  <TD>
     <formlabel id=company_name><BR><formwidget id=company_name><BR>
     <formlabel id=company_url><BR><formwidget id=company_url><BR>
  </TD>
  <TD NOWRAP>
     <formlabel id=entry_name><BR><formwidget id=entry_name><BR>
     <formlabel id=description><BR><formwidget id=description>
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
     <formwidget id=lookup:close>
  </TD>
</TR>
</TABLE>
</FIELDSET>
</formtemplate>

<multipage name=companies>
<border>
<rowfirst>
   <TD WIDTH=1% ></TD>
   <TH>Name</TH>
   <TH>Url</TH>
   <TH>Description</TH>
</rowfirst>
<multirow name=companies>
<row VALIGN=TOP>
   <TD>@companies.icon@</TD>
   <TD>@companies.company_name@</TD>
   <TD>@companies.company_url@</TD>
   <TD>@companies.description@</TD>
</row>
</multirow>
</border>
<multipage name=companies>
