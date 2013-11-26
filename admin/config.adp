<if @ossweb:cmd@ eq error><%=[ossweb::conn -msg]%><return></if>

<if @ossweb:cmd@ eq viewlog>
  <FONT SIZE=1><PRE>@data@</PRE></FONT>
  <return>
</if>

<master src="index">

<SCRIPT LANGUAGE=JavaScript>
  function setConfigType(obj) {
    if(obj.selectedIndex == 0) return;
    window.location = '<%=[ossweb::html::url]%>&type='+obj.options[obj.selectedIndex].value;
  }
</SCRIPT>

<%=[ossweb::html::menu::admin -table t]%>

<formtemplate id=form_config>
<CENTER><formerror id=form_config></CENTER>
<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP><TD WIDTH=50% >
<FIELDSET>
<LEGEND>Configuration</LEGEND>
<TABLE WIDTH=100% BORDER=0 CELLPADDING=0 CELLSPACING=0>
<TR><TD COLSPAN=2 ALIGN=RIGHT><formlabel id=type> :<formwidget id=type></TD></TR>
<TR><TD><formlabel id=name><BR><formwidget id=name><P>
        <formlabel id=value><BR><formwidget id=value><P>
        <formlabel id=module><BR><formwidget id=module>
    </TD>
    <TD VALIGN=BOTTOM><formlabel id=description><BR><formwidget id=description></TD>
</TR>
<TR><TD COLSPAN=2 VALIGN=BOTTOM ALIGN=RIGHT><formwidget id=add></TD></TR>
</TABLE>
</FIELDSET>
</TD>
<TD>
<FIELDSET>
<LEGEND>Server</LEGEND>
<TABLE WIDTH=100% BORDER=0>
<TR><TD><formwidget id=info></TD></TR>
<TR><TD VALIGN=BOTTOM ALIGN=RIGHT>
    <formwidget id=reboot> <formwidget id=serverlog> <formwidget id=accesslog>
    </TD>
</TR>
</TABLE>
</FIELDSET>
</TD>
</TR>
</TABLE>
</formtemplate>
<formtemplate id=form_params title="Current Parameters"></formtemplate>

