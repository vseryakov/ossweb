
<if @ossweb:cmd@ eq error>
   <ossweb:msg>
   <return>
</if>

<master mode=lookup>

<if @ossweb:cmd@ eq edit>

   <formtemplate id=form_type></formtemplate>

   <return>
</if>

<ossweb:title>Location Types</ossweb:title>
<BR>

<DIV ALIGN=RIGHT><ossweb:link -text "Create new record" -class osswebSmallText cmd edit></DIV>

<border style=white>
<multirow name=types></multirow>
</border>

