<master src=index>

<STYLE>
.webcamButton {
  width: 50;
  border: 1px solid #000000;
  background-color: #CCCCCC;
}
</STYLE>

<TABLE WIDTH=100% BORDER=0>
<TR VALIGN=TOP>

<multirow name=devices>
<TD>
<SCRIPT LANGUAGE=JavaScript>
var imgTmp@devices:rownum@ = new Image;
var imgTimeout@devices:rownum@;

function imgUpdate@devices:rownum@()
{
  var dt = new Date();
  document.imgObj@devices:rownum@.src = imgTmp@devices:rownum@.src;
  document.getElementById("imgDate@devices:rownum@").innerHTML = dt.toString();
}
function imgRefresh@devices:rownum@(grab)
{
  var dt = new Date();
  clearTimeout(imgTimeout@devices:rownum@);
  imgTmp@devices:rownum@.onload = imgUpdate@devices:rownum@;
  imgTmp@devices:rownum@.src = 'webcam.oss?cmd=image&tm='+dt.getTime()+'&grab='+grab+'&device=@devices.device@';
  imgTimeout@devices:rownum@ = setTimeout('imgRefresh@devices:rownum@(0)',@refresh@*1000);
}
imgRefresh@devices:rownum@(0);
</SCRIPT>

<TABLE BORDER=0>
<TR><TD ID=imgDate@devices:rownum@>Loading...</TD>
    <TD CLASS=webcamButton onClick="imgRefresh@devices:rownum@(1);" TITLE="Grab image from the camera now">Grab</TD>
</TR>
<TR><TD COLSPAN=2><IMG NAME=imgObj@devices:rownum@ SRC=/img/misc/progress.gif BORDER=0></TD></TR>
</TABLE>
</TD>
<if @devices:rownum@ mod 1></TR><TR VALIGN=TOP></if>
</multirow>

</TABLE>
