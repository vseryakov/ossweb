<%
set format [ns_queryget format]
set element [ns_queryget element]

%>
<HTML>
<HEAD>

<SCRIPT LANGUAGE=JavaScript>
function setColor(value) {
  if('@format@' != '') {
    var v = '@format@'.replace(new RegExp('(%s)','g'),value);
    opener.document.@element@.value+=v;
  } else
    opener.document.@element@.value+=value;
  window.close();
}
</SCRIPT>

<TITLE>Color Picker</TITLE>  
</HEAD>

<BODY BGCOLOR=#DADADA onLoad="setTimeout('window.close()',10000)">

<MAP NAME="colors">    
<AREA COORDS="2,2,18,18" HREF="javascript:setColor('330000')" >
<AREA COORDS="18,2,34,18"   HREF="javascript:setColor('333300')" >
<AREA COORDS="34,2,50,18"   HREF="javascript:setColor('336600')" >
<AREA COORDS="50,2,66,18"   HREF="javascript:setColor('339900')" >
<AREA COORDS="66,2,82,18"   HREF="javascript:setColor('33CC00')" >
<AREA COORDS="82,2,98,18"   HREF="javascript:setColor('33FF00')" >
   
<AREA COORDS="98,2,114,18"  HREF="javascript:setColor('66FF00')" >
<AREA COORDS="114,2,130,18" HREF="javascript:setColor('66CC00')" >
<AREA COORDS="130,2,146,18" HREF="javascript:setColor('669900')" >
<AREA COORDS="146,2,162,18" HREF="javascript:setColor('666600')" >
<AREA COORDS="162,2,178,18" HREF="javascript:setColor('663300')" >
<AREA COORDS="178,2,194,18" HREF="javascript:setColor('660000')" >
   
<AREA COORDS="194,2,210,18" HREF="javascript:setColor('FF0000')" >
<AREA COORDS="210,2,226,18" HREF="javascript:setColor('FF3300')" >
<AREA COORDS="226,2,242,18" HREF="javascript:setColor('FF6600')" >
<AREA COORDS="242,2,258,18" HREF="javascript:setColor('FF9900')" >
<AREA COORDS="258,2,274,18" HREF="javascript:setColor('FFCC00')" >
<AREA COORDS="274,2,290,18" HREF="javascript:setColor('FFFF00')" >
   
<AREA COORDS="2,18,18,34"   HREF="javascript:setColor('330033')" >
<AREA COORDS="18,18,34,34"  HREF="javascript:setColor('333333')" >
<AREA COORDS="34,18,50,34"  HREF="javascript:setColor('336633')" >
<AREA COORDS="50,18,66,34"  HREF="javascript:setColor('339933')" >
<AREA COORDS="66,18,82,34"  HREF="javascript:setColor('33CC33')" >
<AREA COORDS="82,18,98,34"  HREF="javascript:setColor('33FF33')" >
   
<AREA COORDS="98,18,114,34" HREF="javascript:setColor('66FF33')" >
<AREA COORDS="114,18,130,34"HREF="javascript:setColor('66CC33')" >
<AREA COORDS="130,18,146,34"HREF="javascript:setColor('669933')" >
<AREA COORDS="146,18,162,34"HREF="javascript:setColor('666633')" >
<AREA COORDS="162,18,178,34"HREF="javascript:setColor('663333')" >
<AREA COORDS="178,18,194,34"HREF="javascript:setColor('660033')" >
   
<AREA COORDS="194,18,210,34"HREF="javascript:setColor('FF0033')" >
<AREA COORDS="210,18,226,34"HREF="javascript:setColor('FF3333')" >
<AREA COORDS="226,18,242,34"HREF="javascript:setColor('FF6633')" >
<AREA COORDS="242,18,258,34"HREF="javascript:setColor('FF9933')" >
<AREA COORDS="258,18,274,34"HREF="javascript:setColor('FFCC33')" >
<AREA COORDS="274,18,290,34"HREF="javascript:setColor('FFFF33')" >
   
<AREA COORDS="2,34,18,50"   HREF="javascript:setColor('330066')" >
<AREA COORDS="18,34,34,50"  HREF="javascript:setColor('333366')" >
<AREA COORDS="34,34,50,50"  HREF="javascript:setColor('336666')" >
<AREA COORDS="50,34,66,50"  HREF="javascript:setColor('339966')" >
<AREA COORDS="66,34,82,50"  HREF="javascript:setColor('33CC66')" >
<AREA COORDS="82,34,98,50"  HREF="javascript:setColor('33FF66')" >
   
<AREA COORDS="98,34,114,50" HREF="javascript:setColor('66FF66')" >
<AREA COORDS="114,34,130,50"HREF="javascript:setColor('66CC66')" >
<AREA COORDS="130,34,146,50"HREF="javascript:setColor('669966')" >
<AREA COORDS="146,34,162,50"HREF="javascript:setColor('666666')" >
<AREA COORDS="162,34,178,50"HREF="javascript:setColor('663366')" >
<AREA COORDS="178,34,194,50"HREF="javascript:setColor('660066')" >
   
<AREA COORDS="194,34,210,50"HREF="javascript:setColor('FF0066')" >
<AREA COORDS="210,34,226,50"HREF="javascript:setColor('FF3366')" >
<AREA COORDS="226,34,242,50"HREF="javascript:setColor('FF6666')" >
<AREA COORDS="242,34,258,50"HREF="javascript:setColor('FF9966')" >
<AREA COORDS="258,34,274,50"HREF="javascript:setColor('FFCC66')" >
<AREA COORDS="274,34,290,50"HREF="javascript:setColor('FFFF66')" >
   
<AREA COORDS="2,50,18,66"   HREF="javascript:setColor('330099')" >
<AREA COORDS="18,50,34,66"  HREF="javascript:setColor('333399')" >
<AREA COORDS="34,50,50,66"  HREF="javascript:setColor('336699')" >
<AREA COORDS="50,50,66,66"  HREF="javascript:setColor('339999')" >
<AREA COORDS="66,50,82,66"  HREF="javascript:setColor('33CC99')" >
<AREA COORDS="82,50,98,66"  HREF="javascript:setColor('33FF99')" >
   
<AREA COORDS="98,50,114,66" HREF="javascript:setColor('66FF99')" >
<AREA COORDS="114,50,130,66"HREF="javascript:setColor('66CC99')" >
<AREA COORDS="130,50,146,66"HREF="javascript:setColor('669999')" >
<AREA COORDS="146,50,162,66"HREF="javascript:setColor('666699')" >
<AREA COORDS="162,50,178,66"HREF="javascript:setColor('663399')" >
<AREA COORDS="178,50,194,66"HREF="javascript:setColor('660099')" >
   
<AREA COORDS="194,50,210,66"HREF="javascript:setColor('FF0099')" >
<AREA COORDS="210,50,226,66"HREF="javascript:setColor('FF3399')" >
<AREA COORDS="226,50,242,66"HREF="javascript:setColor('FF6699')" >
<AREA COORDS="242,50,258,66"HREF="javascript:setColor('FF9999')" >
<AREA COORDS="258,50,274,66"HREF="javascript:setColor('FFCC99')" >
<AREA COORDS="274,50,290,66"HREF="javascript:setColor('FFFF99')" >
   
<AREA COORDS="2,66,18,82"   HREF="javascript:setColor('3300CC')" >
<AREA COORDS="18,66,34,82"  HREF="javascript:setColor('3333CC')" >
<AREA COORDS="34,66,50,82"  HREF="javascript:setColor('3366CC')" >
<AREA COORDS="50,66,66,82"  HREF="javascript:setColor('3399CC')" >
<AREA COORDS="66,66,82,82"  HREF="javascript:setColor('33CCCC')" >
<AREA COORDS="82,66,98,82"  HREF="javascript:setColor('33FFCC')" >
   
<AREA COORDS="98,66,114,82" HREF="javascript:setColor('66FFCC')" >
<AREA COORDS="114,66,130,82"HREF="javascript:setColor('66CCCC')" >
<AREA COORDS="130,66,146,82"HREF="javascript:setColor('6699CC')" >
<AREA COORDS="146,66,162,82"HREF="javascript:setColor('6666CC')" >
<AREA COORDS="162,66,178,82"HREF="javascript:setColor('6633CC')" >
<AREA COORDS="178,66,194,82"HREF="javascript:setColor('6600CC')" >
   
<AREA COORDS="194,66,210,82"HREF="javascript:setColor('FF00CC')" >
<AREA COORDS="210,66,226,82"HREF="javascript:setColor('FF33CC')" >
<AREA COORDS="226,66,242,82"HREF="javascript:setColor('FF66CC')" >
<AREA COORDS="242,66,258,82"HREF="javascript:setColor('FF99CC')" >
<AREA COORDS="258,66,274,82"HREF="javascript:setColor('FFCCCC')" >
<AREA COORDS="274,66,290,82"HREF="javascript:setColor('FFFFCC')" >
   
<AREA COORDS="2,82,18,98"   HREF="javascript:setColor('3300FF')" >
<AREA COORDS="18,82,34,98"  HREF="javascript:setColor('3333FF')" >
<AREA COORDS="34,82,50,98"  HREF="javascript:setColor('3366FF')" >
<AREA COORDS="50,82,66,98"  HREF="javascript:setColor('3399FF')" >
<AREA COORDS="66,82,82,98"  HREF="javascript:setColor('33CCFF')" >
<AREA COORDS="82,82,98,98"  HREF="javascript:setColor('33FFFF')" >
   
<AREA COORDS="98,82,114,98" HREF="javascript:setColor('66FFFF')" >
<AREA COORDS="114,82,130,98"HREF="javascript:setColor('66CCFF')" >
<AREA COORDS="130,82,146,98"HREF="javascript:setColor('6699FF')" >
<AREA COORDS="146,82,162,98"HREF="javascript:setColor('6666FF')" >
<AREA COORDS="162,82,178,98"HREF="javascript:setColor('6633FF')" >
<AREA COORDS="178,82,194,98"HREF="javascript:setColor('6600FF')" >
   
<AREA COORDS="194,82,210,98"HREF="javascript:setColor('FF00FF')" >
<AREA COORDS="210,82,226,98"HREF="javascript:setColor('FF33FF')" >
<AREA COORDS="226,82,242,98"HREF="javascript:setColor('FF66FF')" >
<AREA COORDS="242,82,258,98"HREF="javascript:setColor('FF99FF')" >
<AREA COORDS="258,82,274,98"HREF="javascript:setColor('FFCCFF')" >
<AREA COORDS="274,82,290,98"HREF="javascript:setColor('FFFFFF')" >
   
<AREA COORDS="2,98,18,114"  HREF="javascript:setColor('0000FF')" >
<AREA COORDS="18,98,34,114" HREF="javascript:setColor('0033FF')" >
<AREA COORDS="34,98,50,114" HREF="javascript:setColor('0066FF')" >
<AREA COORDS="50,98,66,114" HREF="javascript:setColor('0099FF')" >
<AREA COORDS="66,98,82,114" HREF="javascript:setColor('00CCFF')" >
<AREA COORDS="82,98,98,114" HREF="javascript:setColor('00FFFF')" >
   
<AREA COORDS="98,98,114,114"HREF="javascript:setColor('99FFFF')" >
<AREA COORDS="114,98,130,114"  HREF="javascript:setColor('99CCFF')" >
<AREA COORDS="130,98,146,114"  HREF="javascript:setColor('9999FF')" >
<AREA COORDS="146,98,162,114"  HREF="javascript:setColor('9966FF')" >
<AREA COORDS="162,98,178,114"  HREF="javascript:setColor('9933FF')" >
<AREA COORDS="178,98,194,114"  HREF="javascript:setColor('9900FF')" >
   
<AREA COORDS="194,98,210,114"  HREF="javascript:setColor('CC00FF')" >
<AREA COORDS="210,98,226,114"  HREF="javascript:setColor('CC33FF')" >
<AREA COORDS="226,98,242,114"  HREF="javascript:setColor('CC66FF')" >
<AREA COORDS="242,98,258,114"  HREF="javascript:setColor('CC99FF')" >
<AREA COORDS="258,98,274,114"  HREF="javascript:setColor('CCCCFF')" >
<AREA COORDS="274,98,290,114"  HREF="javascript:setColor('CCFFFF')" >
   
<AREA COORDS="2,114,18,130" HREF="javascript:setColor('0000CC')" >
<AREA COORDS="18,114,34,130"HREF="javascript:setColor('0033CC')" >
<AREA COORDS="34,114,50,130"HREF="javascript:setColor('0066CC')" >
<AREA COORDS="50,114,66,130"HREF="javascript:setColor('0099CC')" >
<AREA COORDS="66,114,82,130"HREF="javascript:setColor('00CCCC')" >
<AREA COORDS="82,114,98,130"HREF="javascript:setColor('00FFCC')" >
   
<AREA COORDS="98,114,114,130"  HREF="javascript:setColor('99FFCC')" >
<AREA COORDS="114,114,130,130" HREF="javascript:setColor('99CCCC')" >
<AREA COORDS="130,114,146,130" HREF="javascript:setColor('9999CC')" >
<AREA COORDS="146,114,162,130" HREF="javascript:setColor('9966CC')" >
<AREA COORDS="162,114,178,130" HREF="javascript:setColor('9933CC')" >
<AREA COORDS="178,114,194,130" HREF="javascript:setColor('9900CC')" >
   
<AREA COORDS="194,114,210,130" HREF="javascript:setColor('CC00CC')" >
<AREA COORDS="210,114,226,130" HREF="javascript:setColor('CC33CC')" >
<AREA COORDS="226,114,242,130" HREF="javascript:setColor('CC66CC')" >
<AREA COORDS="242,114,258,130" HREF="javascript:setColor('CC99CC')" >
<AREA COORDS="258,114,274,130" HREF="javascript:setColor('CCCCCC')" >
<AREA COORDS="274,114,290,130" HREF="javascript:setColor('CCFFCC')" >
   
<AREA COORDS="2,130,18,146" HREF="javascript:setColor('000099')" >
<AREA COORDS="18,130,34,146"HREF="javascript:setColor('003399')" >
<AREA COORDS="34,130,50,146"HREF="javascript:setColor('006699')" >
<AREA COORDS="50,130,66,146"HREF="javascript:setColor('009999')" >
<AREA COORDS="66,130,82,146"HREF="javascript:setColor('00CC99')" >
<AREA COORDS="82,130,98,146"HREF="javascript:setColor('00FF99')" >
   
<AREA COORDS="98,130,114,146"  HREF="javascript:setColor('99FF99')" >
<AREA COORDS="114,130,130,146" HREF="javascript:setColor('99CC99')" >
<AREA COORDS="130,130,146,146" HREF="javascript:setColor('999999')" >
<AREA COORDS="146,130,162,146" HREF="javascript:setColor('996699')" >
<AREA COORDS="162,130,178,146" HREF="javascript:setColor('993399')" >
<AREA COORDS="178,130,194,146" HREF="javascript:setColor('990099')" >
   
<AREA COORDS="194,130,210,146" HREF="javascript:setColor('CC0099')" >
<AREA COORDS="210,130,226,146" HREF="javascript:setColor('CC3399')" >
<AREA COORDS="226,130,242,146" HREF="javascript:setColor('CC6699')" >
<AREA COORDS="242,130,258,146" HREF="javascript:setColor('CC9999')" >
<AREA COORDS="258,130,274,146" HREF="javascript:setColor('CCCC99')" >
<AREA COORDS="274,130,290,146" HREF="javascript:setColor('CCFF99')" >
   
<AREA COORDS="2,146,18,162" HREF="javascript:setColor('000066')" >
<AREA COORDS="18,146,34,162"HREF="javascript:setColor('003366')" >
<AREA COORDS="34,146,50,162"HREF="javascript:setColor('006666')" >
<AREA COORDS="50,146,66,162"HREF="javascript:setColor('009966')" >
<AREA COORDS="66,146,82,162"HREF="javascript:setColor('00CC66')" >
<AREA COORDS="82,146,98,162"HREF="javascript:setColor('00FF66')" >
   
<AREA COORDS="98,146,114,162"  HREF="javascript:setColor('99FF66')" >
<AREA COORDS="114,146,130,162" HREF="javascript:setColor('99CC66')" >
<AREA COORDS="130,146,146,162" HREF="javascript:setColor('999966')" >
<AREA COORDS="146,146,162,162" HREF="javascript:setColor('996666')" >
<AREA COORDS="162,146,178,162" HREF="javascript:setColor('993366')" >
<AREA COORDS="178,146,194,162" HREF="javascript:setColor('990066')" >
   
<AREA COORDS="194,146,210,162" HREF="javascript:setColor('CC0066')" >
<AREA COORDS="210,146,226,162" HREF="javascript:setColor('CC3366')" >
<AREA COORDS="226,146,242,162" HREF="javascript:setColor('CC6666')" >
<AREA COORDS="242,146,258,162" HREF="javascript:setColor('CC9966')" >
<AREA COORDS="258,146,274,162" HREF="javascript:setColor('CCCC66')" >
<AREA COORDS="274,146,290,162" HREF="javascript:setColor('CCFF66')" >
   
<AREA COORDS="2,162,18,178" HREF="javascript:setColor('000033')" >
<AREA COORDS="18,162,34,178"HREF="javascript:setColor('003333')" >
<AREA COORDS="34,162,50,178"HREF="javascript:setColor('006633')" >
<AREA COORDS="50,162,66,178"HREF="javascript:setColor('009933')" >
<AREA COORDS="66,162,82,178"HREF="javascript:setColor('00CC33')" >
<AREA COORDS="82,162,98,178"HREF="javascript:setColor('00FF33')" >
   
<AREA COORDS="98,162,114,178"  HREF="javascript:setColor('99FF33')" >
<AREA COORDS="114,162,130,178" HREF="javascript:setColor('99CC33')" >
<AREA COORDS="130,162,146,178" HREF="javascript:setColor('999933')" >
<AREA COORDS="146,162,162,178" HREF="javascript:setColor('996633')" >
<AREA COORDS="162,162,178,178" HREF="javascript:setColor('993333')" >
<AREA COORDS="178,162,194,178" HREF="javascript:setColor('990033')" >
   
<AREA COORDS="194,162,210,178" HREF="javascript:setColor('CC0033')" >
<AREA COORDS="210,162,226,178" HREF="javascript:setColor('CC3333')" >
<AREA COORDS="226,162,242,178" HREF="javascript:setColor('CC6633')" >
<AREA COORDS="242,162,258,178" HREF="javascript:setColor('CC9933')" >
<AREA COORDS="258,162,274,178" HREF="javascript:setColor('CCCC33')" >
<AREA COORDS="274,162,290,178" HREF="javascript:setColor('CCFF33')" >
   
<AREA COORDS="2,178,18,194" HREF="javascript:setColor('000000')" >
<AREA COORDS="18,178,34,194"HREF="javascript:setColor('003300')" >
<AREA COORDS="34,178,50,194"HREF="javascript:setColor('006600')" >
<AREA COORDS="50,178,66,194"HREF="javascript:setColor('009900')" >
<AREA COORDS="66,178,82,194"HREF="javascript:setColor('00CC00')" >
<AREA COORDS="82,178,98,194"HREF="javascript:setColor('00FF00')" >
   
<AREA COORDS="98,178,114,194"  HREF="javascript:setColor('99FF00')" >
<AREA COORDS="114,178,130,194" HREF="javascript:setColor('99CC00')" >
<AREA COORDS="130,178,146,194" HREF="javascript:setColor('999900')" >
<AREA COORDS="146,178,162,194" HREF="javascript:setColor('996600')" >
<AREA COORDS="162,178,178,194" HREF="javascript:setColor('993300')" >
<AREA COORDS="178,178,194,194" HREF="javascript:setColor('990000')" >
   
<AREA COORDS="194,178,210,194" HREF="javascript:setColor('CC0000')" >
<AREA COORDS="210,178,226,194" HREF="javascript:setColor('CC3300')" >
<AREA COORDS="226,178,242,194" HREF="javascript:setColor('CC6600')" >
<AREA COORDS="242,178,258,194" HREF="javascript:setColor('CC9900')" >
<AREA COORDS="258,178,274,194" HREF="javascript:setColor('CCCC00')" >
<AREA COORDS="274,178,290,194" HREF="javascript:setColor('CCFF00')" >
</MAP>

<IMG SRC="/img/misc/colors.gif" WIDTH="292" HEIGHT="196" BORDER="0" ALT="" USEMAP="#colors">

</BODY>
</HTML>
