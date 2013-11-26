<master src="index">

<if @ossweb:cmd@ eq edit>
  <formtemplate id="form_model" title="Device Model Details"></formtemplate>
  <return>
</if>

<formtemplate id="form_search">
 <fieldset>
  <legend>Search Current Device Models</legend>
  <table width="100%" border="0" cellspacing="0" cellpadding="0">
   <tr>
    <td><formlabel id="device_model"><br><formwidget id="device_model"></td>
    <td><formlabel id="device_vendor"><br><formwidget id="device_vendor"></td>
    <td><formlabel id="device_type"><br><formwidget id="device_type"></td>
   <tr>
   <tr>
    <td colspan="3" align="right">
      <formwidget id="search"> <formwidget id="reset"> 
      <formwidget id="new"> <formwidget id="vendors">
    </td>
   </tr>
  </table>
 </fieldset>
</formtemplate>

<fieldset>
<legend>Device / Model List</legend>
<table width="100%" border="0" cellspacing="0" cellpadding="0">
 <rowfirst>
  <th>Model Name</th>
  <th>Device Vendor</th>
  <th>Device Type</th>
 </rowfirst>
 <multirow name="deviceModels">
  <row>
   <td>@deviceModels.device_model@</td>
   <td>@deviceModels.device_vendor_name@</td>
   <td>@deviceModels.device_type@</td>
  </row>
 </multirow>
</table>
</fieldset>
