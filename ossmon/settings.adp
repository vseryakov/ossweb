<master src="index">

<if @ossweb:cmd@ eq error><return></if>

<STYLE>
.property_id {
  font-weight: normal;
  font-size: 8pt;
  color: gray;
}
</STYLE>

<SCRIPT>
  function helpWin(url)
  {
    window.open(url,'Help','width=600,height=500,location=0,menubar=0,scrollbars=1');
  }
</SCRIPT>

<formtemplate id=form_settings></formtemplate>
