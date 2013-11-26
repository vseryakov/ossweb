<if @format@ eq tcl>
  Conditions {<%=[weather::object $weather Weather]%> <%=[weather::object $weather Sky]%>}
  Temperature {<%=[weather::object $weather Temperature]%>}
  Wind {<%=[weather::object $weather Wind -default None]%>}
  Warning {<%=[weather::object $forecast forecast:warning]%>}
  Icon {<%=[weather::object $weather Icon]%>}
  <multirow name=days>
  Day:@days:rownum@ {@days.day@ @days.temp@ | @days.weather@ | @days.wind@ | @days.icon@}
  </multirow>
  <% ossweb::conn -set html:content_type text/plain %>
  <return>
</if>

<master src=index>

<formtemplate id=form_weather>
<TABLE WIDTH=100% BORDER=0>
<TR>
   <TD>
     <if @weather@ ne "">
       <%=[ossweb::html::title "Current Conditions for [weather::object $weather City]"]%>
     <else>
       <%=[ossweb::html::title "Enter Zipcode for Current Weather Conditions"]%>
     </if>
   </TD>
   <TD ALIGN=RIGHT NOWRAP>
     <formlabel id=zipcode>: <formwidget id=zipcode> <formwidget id=search>
   </TD>
</TR>
</TABLE>
</formtemplate>

<if @weather@ ne "">
<border width=0% color2=#EEF5FD>
<TR>
    <TD><%=[ossweb::html::image $imgdir/[weather::object $weather Icon].gif -width "" -height ""]%></TD>
    <TD><FONT SIZE=3><B><%=[weather::object $weather Temperature]%></B></FONT></TD>
</TR>
<TR><TD>&nbsp;</TD>
    <TD>
       <B><%=[weather::object $weather Weather]%> <%=[weather::object $weather Sky]%></B>
    </TD>
</TR>
<TR><TD>Wind:</TD>
    <TD><%=[weather::object $weather Wind -default None]%></TD>
</TR>
<TR><TD>Dew Point:</TD>
    <TD><%=[weather::object $weather Dew_Point -default "No data"]%></TD>
</TR>
<TR><TD>Pressure:</TD>
    <TD><%=[weather::object $weather Pressure -default "No data"]%></TD>
</TR>
<TR><TD>Humidity:</TD>
    <TD><%=[weather::object $weather Humidity -default "No data"]%></TD>
</TR>
<TR><TD>Visibility:</TD>
    <TD><%=[weather::object $weather Visibility -default Unlimited]%></TD>
</TR>
<TR><TD>Precipitation:</TD>
    <TD><%=[weather::object $weather Precipitation -default "No data"]%></TD>
</TR>
</border>
<P>
</if>

<if @days:rowcount@ gt 0>
<helptitle help=0>
Local forecast for <%=[weather::object $forecast forecast:city]%><BR>
<%=[weather::object $forecast forecast:center]%><BR>
<%=[weather::object $forecast forecast:date]%><P>
<FONT COLOR=RED><%=[weather::object $forecast forecast:warning]%></FONT>
</helptitle>
<border width=0% color2=#EEF5FD cellpadding=5>
<rowfirst>
  <TH>Day</TH>
  <TH COLSPAN=2>Conditions</TH>
  <TH>Wind</TH>
  <TH NOWRAP>Daytime High/<BR>Overnight Low(F)</TH>
</rowfirst>
<multirow name=days>
<row>
  <TD>@days.day@</TD>
  <TD>@days.image@</TD>
  <TD>@days.weather@</TD>
  <TD>@days.wind@</TD>
  <TD ALIGN=CENTER NOWRAP><B>@days.temp@</B></TD>
</row>
</multirow>
</border>
</if>
