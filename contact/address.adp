<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<if @ossweb:cmd@ eq take>
   <B>Address @address2@ has @not@ been replaced with @address1@</B>
   <return>
</if>

<master mode=lookup>

<if @ossweb:cmd@ eq edit>
  <formtemplate id=form_address></formtemplate>
  <if @owners:rowcount@ gt 0>
     <FIELDSET><LEGEND CLASS=osswebTitle>Owners of this location:</LEGEND>
     <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
     <multirow name=owners><TR><TD>@owners.name@</TD></TR></multirow>
     </TABLE>
     </FIELDSET>
  </if>
  <return>
</if>

<formtemplate id=form_search>
<formerror id=form_address>
<FIELDSET><LEGEND CLASS=osswebTitle><%=[ossweb::html::title "Locations"]%></LEGEND>
<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP>
  <TD><formlabel id=number><BR><formwidget id=number></TD>
  <TD><formlabel id=street><BR><formwidget id=street> <formwidget id=street_type></TD>
  <TD><%=[ossweb::html::font -type column_title Unit]%><BR>
      <formwidget id=unit_type> <formwidget id=unit>
  </TD>
  <TD ROWSPAN=2><formlabel id=location_type><BR><formwidget id=location_type></TD>
</TR>
<TR VALIGN=TOP>
  <TD><formlabel id=city><BR><formwidget id=city><BR>&nbsp;<BR>
      <formlabel id=location_name><BR><formwidget id=location_name>
  </TD>
  <TD><formlabel id=state><BR><formwidget id=state>&nbsp;&nbsp;
    <formlabel id=zip_code>&nbsp;<formwidget id=zip_code><BR>&nbsp;<BR>
    <formlabel id=address_notes><BR><formwidget id=address_notes>
  </TD>
  <TD>
    <formlabel id=country><BR><formwidget id=country>
  </TD>
</TR>
<TR>
  <TD VALIGN=BOTTON ALIGN=RIGHT COLSPAN=5>
    <formwidget id=search>
    <formwidget id=reset>
    <formwidget id=new>
  </TD>
</TR>
</TABLE>
</FIELDSET>
</formtemplate>

<multipage name=address>
<border>
<rowfirst>
  <TH>#</TH>
  <TH>Street</TH>
  <TH>Unit</TH>
  <TH>City;</TH>
  <TH>State</TH>
  <TH>Zip</TH>
  <TH>Country</TH>
  <TH>Name</TH>
</rowfirst>
<multirow name="address">
  <row VALIGN=TOP onMouseOverClass=osswebRow3 url="@address.url@">
    <TD>@address.number@</TD>
    <TD>@address.street@ @address.street_type@</TD>
    <TD>@address.unit_name@ @address.unit@</TD>
    <TD>@address.city@</TD>
    <TD>@address.state@</TD>
    <TD>@address.zip_code@</TD>
    <TD>@address.country_name@</TD>
    <TD>@address.location_type@
      <if @address.location_name@ ne "">/<B>@address.location_name@</B></if>
      <if @address.address_notes@ ne ""><BR>@address.address_notes@</if>
    </TD>
  </row>
</multirow>
</border>
<multipage name=address>
