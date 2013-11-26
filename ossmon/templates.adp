<master src="index">

<if @ossweb:cmd@ eq edit>
   <formtemplate id=form_template title="Template Details"></formtemplate>
   <if @rules:rowcount@ gt 0>
      Rules that use this template:
      <UL><multirow name=rules><LI>@rules.rule_name@ / @rules.action_type@</multirow></UL>
   </if>
   <return>
</if>

<help_title url=doc/manual.html#t46>Action Templates</help_title>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=2>
<row type=plain underline=1 colspan=2>
 <TH>@templates:add@ @templates:refresh@ Name</TH>
 <TH>Actions</TH>
</row>
<multirow name="templates">
  <row>
   <TD>@templates.template_name@</TD>
   <TD>@templates.template_actions@</TD>
  </row>
</multirow>
</border>
