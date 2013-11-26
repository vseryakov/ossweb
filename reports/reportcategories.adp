<master src=index>

<if @ossweb:cmd@ ne edit>

<helptitle>Categories</helptitle>

<border>
<rowfirst>
  <TH>@category:add@ ID</TH>
  <TH>Name</TH>
  <TH>Description</TH>
</rowfirst>
<multirow name="category">
  <row>
    <TD>@category.category_id@</TD>
    <TD>@category.category_name@</TD>
    <TD>@category.description@</TD>
  </row>
</multirow>
</border>

<else>

<formtemplate id=form_category title="Category"></formtemplate>

</if>
