<%
  # Window size
  set width 352
  set height 288
  # For how long to play video
  set duration 120
  # Video bitrate in bits/s
  set bitrate 204800
  
  # Current status
  set status [nsv_get ns:video status]
  set channel [nsv_get ns:video channel]

  switch -- [ns_queryget cmd] {
   stop {
     nsv_set ns:video status stop
     catch { exec killall -9 ffmpeg }
   }
  }   

%>

<HEAD>
<TITLE>Web Streamig Test</TITLE>

<SCRIPT SRC=/js/util.js></SCRIPT>
<SCRIPT SRC="ufo.js"></SCRIPT>

<STYLE>
#remote {
  border: 1px solid #000;
  -moz-border-radius: 4px;
}

.norm {
  background-color: #EEE;
  font-weight: bold;
  font-size: 8pt;
  text-align: center;
}

.selected {
  background-color: #AAA;
  font-weight: bold;
  font-size: 8pt;
  text-align: center;
}

</STYLE>
</HEAD>
<BODY BGCOLOR=white onLoad="doInit()">
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR VALIGN=BOTTOM>
    <TD WIDTH=70% NOWRAP>
    <B>SA Set Top Box Video Client</B><P>
    <INPUT TYPE=BUTTON VALUE=Refresh onClick="window.location='?cmd=refresh'" STYLE="font-size:8pt">
    <INPUT TYPE=BUTTON VALUE=Stop onClick="window.location='?cmd=stop'" STYLE="font-size:8pt">
    <if @status@ eq play>
      <P STYLE="font-size:8pt;color:red;">Video server is busy, please try again later or click on Stop button</P>
    </if>
    </TD>
    <TD ALIGN=RIGHT BGCOLOR=#EEEEEE>
    <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
    <TR HEIGHT=30><TD ID=loading></TD><TD ALIGN=RIGHT><FONT SIZE=1>Current Channel: @channel@</FONT></TR>
    </TABLE>
    <HR>
    <DIV ID=msg></DIV>
    </TD>
</TR>
</TABLE>
<HR>
<TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
<TR VALIGN=TOP>
    <TD ID=player ALIGN=CENTER>
    <OBJECT NAME="mediaplayer"
            ID="mediaplayer"
            DATA="mediaplayer.swf"
            TYPE="application/x-shockwave-flash"
            HEIGHT="@height@"
            WIDTH="@width@">
    </OBJECT>
    </TD>
    <TD ALIGN=RIGHT STYLE="padding-right: 20px;">
        <TABLE ID=remote BORDER=0 CELLSPACING=3 CELLPADDING=3>
        <TR><TD CLASS=norm onClick="doSend('power')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Power</TD>
            <TD CLASS=norm onClick="doSend('mute')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Mute</TD>
            <TD CLASS=norm onClick="doSend('menu')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Menu</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('live')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Live</TD>
            <TD CLASS=norm onClick="doSend('info')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Info</TD>
            <TD CLASS=norm onClick="doSend('guide')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Guide</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('play')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Play</TD>
            <TD CLASS=norm onClick="doSend('pause')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Pause</TD>
            <TD CLASS=norm onClick="doSend('stop')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Stop</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('rew')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Rew</TD>
            <TD CLASS=norm onClick="doSend('ff')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">FF</TD>
            <TD CLASS=norm onClick="doSend('rec')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Rec</TD>
        </TR>

        <TR><TD CLASS=norm onClick="doSend('ch_up')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Ch+</TD>
            <TD CLASS=norm></TD>
            <TD CLASS=norm onClick="doSend('vol_up')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Vol+</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('ch_dn')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Ch-</TD>
            <TD CLASS=norm></TD>
            <TD CLASS=norm onClick="doSend('vol_dn')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Vol-</TD>
        </TR>
        <TR><TD CLASS=norm></TD>
            <TD CLASS=norm onClick="doSend('up')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'"><IMG SRC=/img/up.png></TD>
            <TD CLASS=norm></TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('left')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'"><IMG SRC=/img/left.png></TD>
            <TD CLASS=norm onClick="doSend('select')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Select</TD>
            <TD CLASS=norm onClick="doSend('right')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'"><IMG SRC=/img/right.png></TD>
        </TR>
        <TR><TD CLASS=norm></TD>
            <TD CLASS=norm onClick="doSend('down')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'"><IMG SRC=/img/down.png></TD>
            <TD CLASS=norm></TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('page_up')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Page+</TD>
            <TD CLASS=norm onClick="doSend('exit')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Exit</TD>
            <TD CLASS=norm onClick="doSend('page_dn')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">Page-</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('A')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">A</TD>
            <TD CLASS=norm onClick="doSend('B')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">B</TD>
            <TD CLASS=norm onClick="doSend('C')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">C</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('1')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">1</TD>
            <TD CLASS=norm onClick="doSend('2')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">2</TD>
            <TD CLASS=norm onClick="doSend('3')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">3</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('4')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">4</TD>
            <TD CLASS=norm onClick="doSend('5')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">5</TD>
            <TD CLASS=norm onClick="doSend('6')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">6</TD>
        </TR>
        <TR><TD CLASS=norm onClick="doSend('7')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">7</TD>
            <TD CLASS=norm onClick="doSend('8')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">8</TD>
            <TD CLASS=norm onClick="doSend('9')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">9</TD>
        </TR>
        <TR>
            <TD CLASS=norm onClick="doSend('asterisk')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">*</TD>
            <TD CLASS=norm onClick="doSend('0')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">0</TD>
            <TD CLASS=norm onClick="doSend('pound')" onMouseOver="this.className='selected'" onMouseOut="this.className='norm'">#</TD>
        </TR>
        </TABLE>
    </TD>
</TR>
</TABLE>
</BODY>

<SCRIPT>

function doClear()
{
  varSet('loading','');
}

function doLoading()
{
  varSet('loading','<IMG SRC=/img/loading.gif>');
}

function doSend(ch,cmd)
{
  var e = cmd ? cmd : '';
  if (ch != '' && isNaN(parseInt(ch))) {
      e = ch;
      ch = '';
  }
  pagePopupGet("/video.ctl?&c="+ch+'&e='+escape(e),"name=msg,onstart=doLoading(),onclose=doClear(),onshow=doClear()");
}

function doInit()
{
  pagePopupGet('/video.ctl?&e=init&t=@duration@&s=@width@x@height@&r=@bitrate@','name=msg');
}

var FO = {
    movie: "mediaplayer.swf",
    id: "mediaplayer",
    name: "mediaplayer",
    width: "@width@",
    height: "@height@",
    majorversion: "8",
    build: "0",
    bgcolor: "#FFFFFF",
    allowfullscreen: "true",
    flashvars: "file=video.flv&enablejs=true&overstretch=false"
}

UFO.create(FO,'player');

</SCRIPT>
