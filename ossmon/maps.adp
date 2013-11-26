<master src=index>

<formtemplate id=form_map>
<TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
<last_row VALIGN=TOP>
  <TD NOWRAP><formlabel id=devs><BR><formwidget id=devs></TD>
  <TD NOWRAP><formlabel id=maps><BR><formwidget id=maps></TD>
  <TD NOWRAP><formlabel id=map_name><BR><formwidget id=map_name></TD>
  <TD NOWRAP><formlabel id=map_image><BR><formwidget id=map_image></TD>
  <TD NOWRAP ALIGN=RIGHT VALIGN=BOTTOM>
     <formwidget id=add> <formwidget id=update> <formwidget id=delete>
     <formwidget id=save> <formwidget id=reset>
  </TD>
</last_row>
</formtemplate>
<if @map_id@ eq "" or @ossweb:cmd@ eq error><return></if>

<TR VALIGN=TOP>
   <TD><IMG NAME=mapImage SRC=maps/@map_image@ STYLE="position:absolute; top:@defY@; left:@defX@"></TD>
</TR>
</TABLE>
<STYLE>
.mapTag {
  font-size: 8pt;
  text-align: center;
  position: absolute;
  border: 1px solid #000000;
  background-color: lightgreen;
  z-index: 0;
}
</STYLE>
<multirow name=devices>
  <DIV ID=DND@devices.device_id@ CLASS=mapTag STYLE="left:@devices.x@;top:@devices.y@;visibility:@devices.visibility@;">
    <IMG tagName=DND@devices.device_id@ SRC=@devices.image@>
    <B>@devices.device_name@</B><BR>@devices.device_host@
  </DIV>
</multirow>
<SCRIPT LANGUAGE="JavaScript">
var deviceIndex = -1;
var deviceList = new Array();
@deviceList@

function deviceView(device_id)
{
   var obj;
   if(deviceIndex > -1 && deviceIndex < deviceList.length) {
     if(!deviceList[deviceIndex].z && (obj = $(deviceList[deviceIndex].name)))
       obj.style.visibility = "hidden";
   }
   deviceIndex = -1;
   for(i = 0; i < deviceList.length; i++) {
     if(deviceList[i].device_id != device_id) continue;
     if(!(obj = $(deviceList[i].name))) return;
     obj.style.visibility = "visible";
     deviceIndex = i;
     break;
   }
}

function deviceNew(device_id,x,y)
{
   this.device_id = device_id;
   this.name = 'DND'+device_id;
   this.x = x;
   this.y = y;
   this.z = (x > @defX@ && y > @defY@ ? 1 : 0);
}

function mapSave()
{
   var data = '';
   for(i = 0; i < deviceList.length; i++) {
     if(!deviceList[i].z) continue;
     data = data+deviceList[i].device_id+' '+deviceList[i].x+' '+deviceList[i].y+' ';
   }
   document.form_map.maps.selectedIndex = 0;
   document.form_map.devs.selectedIndex = 0;
   document.form_map.cmd.value = 'save';
   document.form_map.device_list.value = data;
   document.form_map.submit();
   return false;
}

function dndOnDrop(obj,x,y)
{
   for(i = 0; i < deviceList.length; i++)
     if(deviceList[i].name == obj.id) {
       if(x > @defX@ && y > @defY@) {
         deviceList[i].x = x;
         deviceList[i].y = y;
         deviceList[i].z = 1;
       } else {
         deviceList[i].x = @defX@;
         deviceList[i].y = @defY@;
         deviceList[i].z = 0;
         dndMove(@defX@,@defY@);
         dndObj.style.visibility = "hidden";
       }
       deviceIndex = -1;
       break;
     }
}
dndInit();
</SCRIPT>
