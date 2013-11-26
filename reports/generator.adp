
<if @ossweb:cmd@ eq view>
   <master src="index">
   <SCRIPT SRC=/js/tree.js></SCRIPT>
   <SCRIPT LANGUAGE=javascript>
     var Tree = new Array();
     @tree@
     createTree(Tree,null,'@tree_open@','<FONT COLOR=#234c54><B>Report Tree</B></FONT>');
   </SCRIPT>
   <return>
</if>

<if @ossweb:cmd@ eq edit>
   <master src="index">
   <formtemplate id=form_report border_style=white></formtemplate>
   <return>
</if>

<master mode=logo>

<if @data_form@ ne 0>
  <SCRIPT LANGUAGE=JavaScript>
  function reportEmail(type)
  {
    document.form_report.repeat.value=type;
    document.form_report.cmd.value='email';
    document.form_report.submit();
    return false;
  }
  </SCRIPT>
  <formtemplate id=form_report border_style=white></formtemplate>
<else>
  <CENTER><B>@report_name@</B></CENTER>
</if>
<P>

<if @data:rowcount@ eq 0 and @data_body@ eq "">
  <CENTER>
    <FONT SIZE=+1>No information is available or no match for given search criteria</FONT>
  </CENTER>
  <return>
</if>

@data_title@

<if @data_border@ eq 1>
  <border id=report border1=0 style=@style@ width=@width@ cellspacing=@cellspacing@ cellpadding=@cellpadding@>
  @data_header@
  <multirow name=data norow=@norow@ underline=@underline@ header=@header@ options=data_opts></multirow>
  @data_footer@
  </border>
</if>
@data_body@
<if @data_rowcount@ gt 0 and @data_total@ ne 0>
   <FONT SIZE=-1><B>Total: @data_rowcount@</FONT>
</if>
