<master src="index">

<%=[ossweb::html::menu::admin -table t]%>

<if @ossweb:cmd@ ne edit>

<help_title>@ref_title@</help_title>

<border>
<rowfirst>
  <TH>
     <ossweb:link -image add.gif -alt Add cmd edit>
     <if @ref_refresh@ ne "">
        <ossweb:link -image refresh.gif -alt Refresh cmd refresh>
     </if>
     ID
 </TH>
 <TH>Name</TH>
 <TH>Description</TH>
 <if @ref_extra_name2 ne "">
    <TH>@ref_extra_label2@</TH>
 </if>
</rowfirst>
<multirow name="reftable">
 <row onMouseOverClass=osswebRow3 url=@reftable.url@>
 <TD>@reftable.id@</TD>
 <TD>@reftable.name@</TD>
 <TD>@reftable.description@</TD>
 <if @ref_extra_name2@ ne "">
    <TD>@reftable.extra_name2@</TD>
 </if>
 </row>
</multirow>
</border>
<return>
</if>

<formtemplate id=form_reftable></formtemplate>
