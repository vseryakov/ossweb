<master src=master>

<if @ossweb:cmd@ eq shipping>
   <formtemplate id=form_shipping></formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq billing>
   <formtemplate id=form_billing>
   <CENTER><formerror id=form_billing></CENTER>
   <border>
   <TR><TD COLSPAN=2 CLASS=osswebFormTitle><%=[ossweb::form form_billing title]%></TD></TR>
   <TR><TD WIDTH=30% CLASS=osswebFormLabel>Name</TD><TD>@first_name@ @last_name@</TD></TR>
   <TR><TD CLASS=osswebFormLabel>Email</TD><TD>@email@</TD></TR>
   <TR><TD CLASS=osswebFormLabel>Phone</TD><TD>@phone@</TD></TR>
   <TR><TD CLASS=osswebFormLabel>Shipping To</TD>
       <TD>@shipping_number@ @shipping_street@ @shipping_city@ @shipping_state@ @shipping_zip_code@</TD>
   </TR>
   <TR><TD CLASS=osswebFormLabel>Shipping Method</TD><TD>@shipping_method@</TD></TR>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <TR><TD COLSPAN=2>
       <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
       <TR><TH>Product</TH><TH>Price</TH><TH>Quantity</TH><TH>Total</TH></TR>
       <multirow name=products>
       <TR><TD>@products.product_name@</TD>
           <TD>$@products.price@</TD>
           <TD>@products.quantity@</TD>
           <TD>$@products.total@</TD>
       </TR>
       </multirow>
       <TR><TD COLSPAN>&nbsp;</TD></TR>
       <TR><TD COLSPAN=2></TD><TD><B>Tax:</B></TD><TD>@billing_tax@</TD></TR>
       <TR><TD COLSPAN=2></TD><TD><B>Shipping:</B></TD><TD>@shipping_price@</TD></TR>
       <if @charge_name@ ne "" and @charge_price@ gt 0>
       <TR><TD COLSPAN=2></TD><TD><B>@charge_name@:</B></TD><TD>@charge_price@</TD></TR>
       </if>
       <TR><TD COLSPAN=2></TD><TD><B>TOTAL:</B></TD><TD>@total@</TD></TR>
       </TABLE>
       </TD>
   </TR>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <TR><TD CLASS=osswebFormLabel>Credit Card Information</TD><TD><HR></TD></TR>
   <TR><TD>&nbsp;&nbsp;<I><formlabel id=billing_card_name></I></TD><TD><formwidget id=billing_card_name></TD></TR>
   <TR><TD>&nbsp;&nbsp;<I><formlabel id=billing_card_num></I></TD><TD><formwidget id=billing_card_num></TD></TR>
   <TR><TD>&nbsp;&nbsp;<I><formlabel id=billing_card_type></I></TD><TD><formwidget id=billing_card_type></TD></TR>
   <TR><TD>&nbsp;&nbsp;<I><formlabel id=billing_card_exp></I></TD><TD><formwidget id=billing_card_exp></TD></TR>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <TR><TD CLASS=osswebFormLabel>Billing Address</TD><TD><HR></TD></TR>
   <TR VALIGN=TOP>
      <TD><I><FONT SIZE=1 COLOR=gray>Leave empty if same as shipping</FONT></I></TD>
      <TD><formwidget id=billing_address></TD>
   </TR>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <TR><TD><formlabel id=notes></TD><TD><formwidget id=notes></TD></TR>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <TR><TD><formwidget id=back></TD>
       <TD ALIGN=RIGHT><formwidget id=submit></TD>
   </TR>
   </border>
   </formtemplate>
   <return>
</if>

<if @ossweb:cmd@ eq submit>
   Thank you<P>
   You order number is @cart_id@
   <return>
</if>

<if @ossweb:cmd@ eq cart>
   <helptitle>Shopping Cart</helptitle>
   
   <if @products:rowcount@ eq 0>
      Shopping cart is empty
      <return>
   </if>
   <formtemplate id=form_cart>
   <border>
   <rowfirst>
     <TH WIDTH=1% ></TH>
     <TH>Name</TH>
     <TH>Price</TH>
     <TH>Quantity</TH>
     <TH>Total</TH>
     <TH WIDTH=1% ></TH>
   </rowfirst>
   <multirow name=products>
   <row type=plain underline=1 VALIGN=TOP>
     <TD>@products.icon@</TD>
     <TD>@products.product_name@</TD>
     <TD>$@products.price@</TD>
     <TD>@products.quantity@</TD>
     <TD>$@products.total@</TD>
     <TD>@products.delete@</TD>
   </row>
   </multirow>
   <rowlast>
     <TD ALIGN=RIGHT COLSPAN=6>
       <formwidget id=update>
       <formwidget id=shipping>
       <formwidget id=empty>
     </TD>
   </rowlast>
   </border>
   </formtemplate>
</if>

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_product>
   <TABLE BORDER=0 CELLSPACING=5>
   <TR VALIGN=TOP>
     <TD WIDTH=1% ><if @image@ ne ""><IMG SRC=img/@image@ BORDER=0></if></TD>
     <TD><B>@product_name@</B><P>
         Regular Price: $@price@<BR>
         <if @sale_price@ ne "">Sale Price: $@sale_price@</if>
         <P>
         <if @quantity@ gt 0>
         <formwidget id=buy>
         <else>
         <B>Out of Stock</B>
         </if>
     </TD>
   </TR>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <if @properties:rowcount@ gt 0>
   <multirow name=properties>
   <TR><TD COLSPAN=2><B>@properties.name@: @properties.value@</TD></TR>
   </multirow>
   </if>
   <TR><TD COLSPAN=2>&nbsp;</TD></TR>
   <TR><TD COLSPAN=2>@description@</TD></TR>
   </TABLE>
   </formtemplate>
</if>

<if @ossweb:cmd@ eq view>
   <multipage name=products>
   <border>
   <multirow name=products>
   <row VALIGN=TOP>
     <TD WIDTH=1% >@products.icon@</TD>
     <TD>@products.url@</TD>
     <TD>@products.category_name@</TD>
     <TD>$@products.price@</TD>
   </row>
   </multirow>
   </border>
   <multipage name=products>
</if>
