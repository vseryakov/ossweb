<master src="index">

<LINK REL=STYLESHEET TYPE="text/css" HREF="/css/ossmon2.css"/>

<if @ossweb:cmd@ eq edit>

   <formtemplate id="form_rule" title="Alert Rule Detals" info="@rule_link@"></formtemplate>

   <if @rule_id@ ne "">
     <help_title>Rule Conditions/Actions</help_title>
     <formerror id=form_match><formerror id=form_run>
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
       <TD WIDTH=5>&nbsp;</TD>
       <TD>
          <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
          <rowfirst>
            <TH>Type</TH>
            <TH COLSPAN=2>Template</TH>
          </rowfirst>
          <last_row>
            <formtemplate id=form_run>
            <TD><formwidget id=action_type></TD>
            <TD><formwidget id=template_id></TD>
            <TD><formwidget id=cmd></TD>
            </formtemplate>
          </last_row>
          <multirow name="run">
            <row>
              <TD>@run.type_name@</TD>
              <TD>@run.template_name@</TD>
              <TD>@run.delete@</TD>
            </row>
          </multirow>
          </TABLE>
       </TD>
     </TR>
     </border>
   </if>
   <return>
</if>

<help_title>OSSMON Alert Rules</help_title>
<border>
<rowfirst>
  <TD WIDTH=10></TD>
  <TH>@rules:add@ @rules:refresh@ Rule Name</TH>
  <TH>Level</TH>
  <TH>Threshold</TH>
  <TH>Interval</TH>
  <TH>Mode</TH>
  <TH>Priority</TH>
  <TH>Alerts</TH>
</rowfirst>
<multirow name=rules>
  <row>
    <TD WIDTH=10>
       <if @rules.level@ eq Critical><IMG SRC=/img/squares/pink.gif BORDER=0></if>
       <if @rules.level@ eq Warning><IMG SRC=/img/squares/orange.gif BORDER=0></if>
       <if @rules.level@ eq Advise><IMG SRC=/img/squares/yellow.gif BORDER=0></if>
       <if @rules.level@ eq Error><IMG SRC=/img/squares/red.gif BORDER=0></if>
    </TD>
    <TD>@rules.rule_name@</TD>
    <TD>@rules.level@</TD>
    <TD>@rules.threshold@</TD>
    <TD>@rules.interval@</TD>
    <TD>@rules.mode@</TD>
    <TD>@rules.precedence@</TD>
    <TD>@rules.alerts@</TD>
  </row>
</multirow>
</border>
