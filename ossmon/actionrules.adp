<master src="index">

<if @ossweb:cmd@ eq edit>

   <formtemplate id="form_rule" title="Action Rule Detals" info="@rule_link@"></formtemplate>

   <if @rule_id@ ne "">
     <help_title>Rule Conditions/Actions</help_title>
     <formerror id=form_match>
     <formerror id=form_script>
     <border border2=0>
     <TR VALIGN=TOP>
       <TD>
          <formtemplate id=form_match>
          <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
          <rowfirst>
            <TH>Mode</TH>
            <TH>Name</TH>
            <TH>Operator</TH>
            <TH COLSPAN=2>Value</TH>
          </rowfirst>
          <last_row>
            <TD><formwidget id=mode></TD>
            <TD><formwidget id=name></TD>
            <TD><formwidget id=operator></TD>
            <TD><formwidget id=value></TD>
            <TD><formwidget id=cmd></TD>
          </last_row>
          <multirow name="match">
            <row>
              <TD>@match.mode@</TD>
              <TD>@match.name@</TD>
              <TD>@match.operator@</TD>
              <TD>@match.value@</TD>
              <TD>@match.edit@</TD>
            </row>
          </multirow>
          </TABLE>
          </formtemplate>
       </TD>
       <TD>
          <formtemplate id=form_script>
          <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
          <rowfirst>
            <TD COLSPAN=2>
            <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
            <TR><TD><B>Script</B></TD>
                <TD ALIGN=RIGHT>Functions: <formwidget id=func></TD>
            </TR>
            </TABLE>
            </TD>
          </rowfirst>
          <last_row VALIGN=TOP>
            <TD><formwidget id=value></TD>
            <TD><formwidget id=cmd></TD>
          </last_row>
          <multirow name="script">
          <row>
            <TD>@script.value@</TD>
            <TD>@script.edit@ @script.delete@</TD>
          </row>
          </multirow>
          </TABLE>
          </formtemplate>
       </TD>
     </TR>
     </border>
   </if>
   <return>
</if>

<help_title url=doc/manual.html#t48>OSSMON Action Rules</help_title>
<border>
<rowfirst>
  <TH>@rules:add@ Rule Name</TH>
  <TH>Status</TH>
  <TH>Mode</TH>
  <TH>Priority</TH>
</rowfirst>
<multirow name=rules>
  <row>
    <TD>@rules.rule_name@</TD>
    <TD>@rules.status@</TD>
    <TD>@rules.mode@</TD>
    <TD>@rules.precedence@</TD>
  </row>
</multirow>
</border>
