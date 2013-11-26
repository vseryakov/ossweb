<%
set format [ns_queryget format]
set element [ns_queryget element]
%>
<HTML>
<HEAD>

<SCRIPT LANGUAGE=JavaScript>
function setSmile(value) {
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

<TABLE WIDTH=100% BORDER=1 CELLSPACING=0 CELLPADDING=2 BGCOLOR=white>
<TR>
    <TD>:-) <A HREF="javascript:setSmile(':-)')"><IMG SRC=/img/smilies/happy.png BORDER=0></A></TD>
    <TD>:-> <A HREF="javascript:setSmile(':->')"><IMG SRC=/img/smilies/happy.png BORDER=0></A></TD>
    <TD>;-) <A HREF="javascript:setSmile(';-)')"><IMG SRC=/img/smilies/wink.png BORDER=0></A>
    <TD>;-> <A HREF="javascript:setSmile(';->')"><IMG SRC=/img/smilies/wink.png BORDER=0></A>
    <TD>;-( <A HREF="javascript:setSmile(';-(')"><IMG SRC=/img/smilies/sad.png BORDER=0></A>
    <TD>;-< <A HREF="javascript:setSmile(';-<')"><IMG SRC=/img/smilies/sad.png BORDER=0></A>
    <TD>:-( <A HREF="javascript:setSmile(':-(')"><IMG SRC=/img/smilies/sad.png BORDER=0></A>
</TR>
<TR>
    <TD>:-< <A HREF="javascript:setSmile(':-<')"><IMG SRC=/img/smilies/sad.png BORDER=0></A>
    <TD>>:-) <A HREF="javascript:setSmile('>:-)')"><IMG SRC=/img/smilies/devil.png BORDER=0></A>
    <TD>>:) <A HREF="javascript:setSmile('>:)')"><IMG SRC=/img/smilies/devil.png BORDER=0></A>
    <TD>>;-) <A HREF="javascript:setSmile('>;-)')"><IMG SRC=/img/smilies/devil.png BORDER=0></A>
    <TD>8-) <A HREF="javascript:setSmile('8-)')"><IMG SRC=/img/smilies/grin.png BORDER=0></A>
    <TD>8-> <A HREF="javascript:setSmile('8->')"><IMG SRC=/img/smilies/grin.png BORDER=0></A>
    <TD>:-D <A HREF="javascript:setSmile(':-D')"><IMG SRC=/img/smilies/grin.png BORDER=0></A>
</TR>
<TR>
    <TD>;-D <A HREF="javascript:setSmile(';-D')"><IMG SRC=/img/smilies/grin.png BORDER=0></A>
    <TD>8-D <A HREF="javascript:setSmile('8-D')"><IMG SRC=/img/smilies/grin.png BORDER=0></A>
    <TD>:-d <A HREF="javascript:setSmile(':-d')"><IMG SRC=/img/smilies/tasty.png BORDER=0></A>
    <TD>;-d <A HREF="javascript:setSmile(';-d')"><IMG SRC=/img/smilies/tasty.png BORDER=0></A>
    <TD>8-d <A HREF="javascript:setSmile('8-d')"><IMG SRC=/img/smilies/tasty.png BORDER=0></A>
    <TD>:-P <A HREF="javascript:setSmile(':-P')"><IMG SRC=/img/smilies/nyah.png BORDER=0></A>
    <TD>;-P <A HREF="javascript:setSmile(';-P')"><IMG SRC=/img/smilies/nyah.png BORDER=0></A>
</TR>
<TR>
    <TD>8-P <A HREF="javascript:setSmile('8-P')"><IMG SRC=/img/smilies/nyah.png BORDER=0></A>
    <TD>:-p <A HREF="javascript:setSmile(':-p')"><IMG SRC=/img/smilies/nyah.png BORDER=0></A>
    <TD>;-p <A HREF="javascript:setSmile(';-p')"><IMG SRC=/img/smilies/nyah.png BORDER=0></A>
    <TD>8-p <A HREF="javascript:setSmile('8-p')"><IMG SRC=/img/smilies/nyah.png BORDER=0></A>
    <TD>:-O <A HREF="javascript:setSmile(':-O')"><IMG SRC=/img/smilies/scare.png BORDER=0></A>
    <TD>;-O <A HREF="javascript:setSmile(';-O')"><IMG SRC=/img/smilies/scare.png BORDER=0></A>
    <TD>8-O <A HREF="javascript:setSmile('8-O')"><IMG SRC=/img/smilies/scare.png BORDER=0></A>
</TR>
<TR>
    <TD>:-o <A HREF="javascript:setSmile(':-o')"><IMG SRC=/img/smilies/scare.png BORDER=0></A>
    <TD>;-o <A HREF="javascript:setSmile(';-o')"><IMG SRC=/img/smilies/scare.png BORDER=0></A>
    <TD>8-o <A HREF="javascript:setSmile('8-o')"><IMG SRC=/img/smilies/scare.png BORDER=0></A>
    <TD>:-/ <A HREF="javascript:setSmile(':-/')"><IMG SRC=/img/smilies/ironic.png BORDER=0></A>
    <TD>;-/ <A HREF="javascript:setSmile(';-/')"><IMG SRC=/img/smilies/ironic.png BORDER=0></A>
    <TD>8-/ <A HREF="javascript:setSmile('8-/')"><IMG SRC=/img/smilies/ironic.png BORDER=0></A>
    <TD>:-\\ <A HREF="javascript:setSmile(':-\\')"><IMG SRC=/img/smilies/ironic.png BORDER=0></A>
</TR>
<TR>
    <TD>;-\\ <A HREF="javascript:setSmile(';-\\')"><IMG SRC=/img/smilies/ironic.png BORDER=0></A>
    <TD>8-\\ <A HREF="javascript:setSmile('8-\\')"><IMG SRC=/img/smilies/ironic.png BORDER=0></A>
    <TD>:-| <A HREF="javascript:setSmile(':-|')"><IMG SRC=/img/smilies/plain.png BORDER=0></A>
    <TD>;-| <A HREF="javascript:setSmile(';-|')"><IMG SRC=/img/smilies/wry.png BORDER=0></A>
    <TD>8-| <A HREF="javascript:setSmile('8-|')"><IMG SRC=/img/smilies/koed.png BORDER=0></A>
    <TD>:-X <A HREF="javascript:setSmile(':-X')"><IMG SRC=/img/smilies/yukky.png BORDER=0></A>
    <TD>;-X <A HREF="javascript:setSmile(';-X')"><IMG SRC=/img/smilies/yukky.png BORDER=0></A>
</TR>
<TABLE>
</BODY>
</HTML>
