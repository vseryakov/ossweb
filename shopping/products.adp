<master mode=lookup>

<if @ossweb:cmd@ eq error><return></if>

<if @ossweb:cmd@ eq edit>
  <formtemplate id=form_product></formtemplate>
  <if @product_id@ eq ""><return></if>
  <P>
  <help_title>Product Properties</help_title>
  <formerror id=form_property>
  <formtemplate id=form_property>
  <border border1=0>
  <rowfirst><TH>Name</TH><TH>Value</TH><TH></TH></rowfirst>
  <TR>
   <TD><formwidget id=name></TD>
   <TD><formwidget id=value></TD>
   <TD WIDTH=1% ><formwidget id=add></TD>
  </TR>
  <multirow name=properties>
  <row type=plain underline=1>
   <TD>@properties.name@</TD>
   <TD>@properties.value@</TD>
   <TD>@properties.delete@</TD>
  </row>
  </multirow>
  </border>
  </formtemplate>
  <return>
</if>

<help_title>Shopping Products</help_title>

<formtemplate id=form_search>
<border>
<TR VALIGN=TOP>
  <TD><formlabel id=product_id><BR><formwidget id=product_id></TD>
  <TD><formlabel id=product_name><BR><formwidget id=product_name></TD>
  <TD><formlabel id=category_id><BR><formwidget id=category_id></TD>
</TR>
<TR>
  <TD COLSPAN=5 ALIGN=RIGHT>
    <formwidget id=search>
    <formwidget id=reset>
    <formwidget id=new>
  </TD>
</TR>
</border>
<P>
<border>
<rowfirst>
 <TH>ID</TH> 
 <TH>Name</TH>
 <TH>Category</TH>
 <TH>Price</TH>
 <TH>Quantity</TH>
</rowfirst> 
<multirow name=products>
<row onMouseOverClass=osswebRow3 url=@products.url@>
  <TD>@products.product_id@</TD>
  <TD>@products.product_name@</TD>
  <TD>@products.category_name@</TD>
  <TD>$@products.price@ <if @products.sale_price@ ne "">/ $@products.sale_price@</if></TD>
  <TD>@products.quantity@</TD>
</row>
</multirow>
</border>
</formtemplate>
