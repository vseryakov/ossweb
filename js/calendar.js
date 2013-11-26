var weekend = [0,6];
var weekendColor = "#e0e0e0";
var fontface = "Verdana";
var fontsize = 2;
var isNav = (navigator.appName.indexOf("Netscape") != -1) ? true : false;
var isIE = (navigator.appName.indexOf("Microsoft") != -1) ? true : false;
var gNow = new Date();
var gCal = null;

Calendar.DOMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
Calendar.lDOMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
Calendar.Months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

function Calendar(p_win, p_form, p_item, p_month, p_year, p_format, p_proc)
{
   if(p_month == null) p_month = new String(gNow.getMonth());
   if(p_year == null) p_year = new String(gNow.getFullYear().toString());
   if(p_format == null) p_format = "mm/dd/yyyy";
   this.gWinCal = p_win;
   this.gFormat = p_format;
   this.gBGColor = "white";
   this.gFGColor = "black";
   this.gTextColor = "black";
   this.gHeaderColor = "black";
   this.gReturnForm = p_form;
   this.gReturnItem = p_item;
   this.gProc = p_proc;
   this.gObj = $(p_item);
   this.set_date(p_month,p_year);
}

Calendar.prototype.hide = function()
{
   this.gWinCal.close();
}

Calendar.prototype.getForm = function()
{
   return this.gReturnForm;
}

Calendar.prototype.getObj = function()
{
   return this.gObj;
}

Calendar.prototype.getObjName = function()
{
   return this.gReturnItem;
}

Calendar.prototype.get_month = function(monthNo)
{
   return Calendar.Months[monthNo];
}

Calendar.prototype.get_month_days = function(monthNo, p_year)
{
   if((p_year % 4) == 0) {
     if((p_year % 100) == 0 && (p_year % 400) != 0) return Calendar.DOMonth[monthNo];
     return Calendar.lDOMonth[monthNo];
   }
   return Calendar.DOMonth[monthNo];
}

Calendar.prototype.calc_month_year = function(p_Month, p_Year, incr)
{
   var ret_arr = new Array();
   if(incr == -1) {
     // B A C K W A R D
     if(p_Month == 0) {
       ret_arr[0] = 11;
       ret_arr[1] = parseInt(p_Year) - 1;
     } else {
       ret_arr[0] = parseInt(p_Month) - 1;
       ret_arr[1] = parseInt(p_Year);
     }
   } else 
   if(incr == 1) {
     // F O R W A R D
     if(p_Month == 11) {
       ret_arr[0] = 0;
       ret_arr[1] = parseInt(p_Year) + 1;
     } else {
       ret_arr[0] = parseInt(p_Month) + 1;
       ret_arr[1] = parseInt(p_Year);
     }
   }
   return ret_arr;
}

Calendar.prototype.set_date = function(p_month,p_year)
{
   this.gMonthName = this.get_month(p_month);
   this.gMonth = new Number(p_month);
   this.gYear = p_year;
}

Calendar.prototype.show = function()
{
   var prevMMYYYY = this.calc_month_year(this.gMonth, this.gYear, -1);
   var prevMM = prevMMYYYY[0];
   var prevYYYY = prevMMYYYY[1];
   var nextMMYYYY = this.calc_month_year(this.gMonth, this.gYear, 1);
   var nextMM = nextMMYYYY[0];
   var nextYYYY = nextMMYYYY[1];
   var vDate = new Date();	
   vDate.setDate(1);
   vDate.setMonth(this.gMonth);
   vDate.setFullYear(this.gYear);
   var vFirstDay=vDate.getDay();
   var vDay=1;
   var vLastDay=this.get_month_days(this.gMonth, this.gYear);
   var vOnLastDay=0;

   this.gWinCal.document.open();
   this.wwrite(
      "<HTML><HEAD><TITLE>Calendar</TITLE>"+
      "<STYLE TYPE=TEXT/CSS>"+
      ".calHdr { "+
      " background-color: #e0e0e0;"+
      " text-align: right;"+
      " text-decoration: none;"+
      " font-size: 10pt;"+
      " font-family: Arial, Helvetica; }"+
      ".calText { "+
      " text-align: right;"+
      " text-decoration: none;"+
      " font-size: 10pt;"+
      " font-family:: Arial, Helvetica; }"+
      ".calMon { "+
      " color: blue;"+
      " text-align: right;"+
      " text-decoration: none;"+
      " font-weight: bold;"+
      " font-size: 10pt;"+
      " font-family:: Arial, Helvetica; }"+
      ".calFake { "+
      " color: gray;"+
      " text-align: right;"+
      " text-decoration: none;"+
      " font-size: 10pt;"+
      " font-family:: Arial, Helvetica; }"+
      "</STYLE>"+
      "</HEAD><BODY LINK=BLACK VLINK=BLACK ALINK=BLACK TEXT=BLACK>"+
      "<TABLE WIDTH='100%' BORDER=0 CELLSPACING=1 CELLPADDING=0 BGCOLOR=white>"+
      "<TR CLASS=calHdr>"+
      "<TD ALIGN=center><A CLASS=calText HREF=\""+"javascript:window.opener.calendarChange('"+this.gMonth+"','"+(parseInt(this.gYear)-1)+"');"+"\"><B><<</B><\/A></TD>"+
      "<TD ALIGN=center><A CLASS=calText HREF=\""+"javascript:window.opener.calendarChange('"+prevMM+"','"+prevYYYY+"');"+"\"><B><</B><\/A></TD>"+
      "<TD COLSPAN=3 ALIGN=center NOWRAP><B>"+this.gMonthName + " " + this.gYear+"</B></TD>"+
      "<TD ALIGN=center><A CLASS=calText HREF=\""+"javascript:window.opener.calendarChange('"+nextMM+"','"+nextYYYY+"');"+"\"><B>></B><\/A></TD>"+
      "<TD ALIGN=center><A CLASS=calText HREF=\""+"javascript:window.opener.calendarChange('"+this.gMonth+"','"+(parseInt(this.gYear)+1)+"');"+"\"><B>>></B><\/A></TD>"+
      "</TR>"+
      "<TR CLASS=calMon>"+
      "<TD WIDTH='14%'>Sun</TD>"+
      "<TD WIDTH='14%'>Mon</TD>"+
      "<TD WIDTH='14%'>Tue</TD>"+
      "<TD WIDTH='14%'>Wed</TD>"+
      "<TD WIDTH='14%'>Thu</TD>"+
      "<TD WIDTH='14%'>Fri</TD>"+
      "<TD WIDTH='16%'>Sat</TD>"+
      "</TR>"+
      "<TR><TD COLSPAN=7><IMG SRC=/img/misc/graypixel.gif BORDER=0 WIDTH=100% HEIGHT=1></TD></TR>"+
      "<TR>");

   for(i=0; i<vFirstDay; i++) this.wwrite("<TD WIDTH='14%'>&nbsp;</TD>");
   for(j=vFirstDay; j<7; j++) {
     this.wwrite("<TD CLASS=calText WIDTH='14%'><A HREF='#' CLASS=calText onClick=\"self.opener.calendarClose('"+this.format_data(vDay)+"')\">"+this.format_day(vDay)+"</A>"+"</TD>");
     vDay=vDay+1;
   }
   this.wwrite("</TR>");
   for(k=2; k<7; k++) {
     this.wwrite("<TR>");
     for(j=0; j<7; j++) {
       this.wwrite("<TD CLASS=calText WIDTH='14%'><A HREF='#' CLASS=calText onClick=\"self.opener.calendarClose('"+this.format_data(vDay)+"')\">"+this.format_day(vDay)+"</A>"+"</TD>");
       vDay=vDay+1;
       if(vDay > vLastDay) {
	 vOnLastDay = 1;
	 break;
       }
     }
     if(j == 6) this.wwrite("</TR>");
     if(vOnLastDay == 1) break;
   }
   for(m=1; m<(7-j); m++) {
     this.wwrite("<TD CLASS=calFake WIDTH='14%'>"+m+"</TD>");
   }
   this.wwrite("<TR><TD COLSPAN=7><IMG SRC=/img/misc/graypixel.gif BORDER=0 WIDTH=100% HEIGHT=1></TD></TR></TABLE></BODY></HTML>");
   this.gWinCal.document.close();
}

Calendar.prototype.wwrite = function(wtext)
{
   this.gWinCal.document.writeln(wtext);
}

Calendar.prototype.wwriteA = function(wtext)
{
   this.gWinCal.document.write(wtext);
}

Calendar.prototype.format_day = function(vday)
{
   var vNowDay = gNow.getDate();
   var vNowMonth = gNow.getMonth();
   var vNowYear = gNow.getFullYear();
   if(vday == vNowDay && this.gMonth == vNowMonth && this.gYear == vNowYear) return ("<FONT COLOR=\"RED\"><B>"+vday+"</B></FONT>");
   return (vday);
}

Calendar.prototype.format_data = function(p_day,p_fmt)
{
   var vMon = this.gMonth + 1;
   vMon = (vMon.toString().length < 2) ? "0"+vMon : vMon;
   var vYear = new String(this.gYear);
   var vDay = (p_day.toString().length < 2) ? "0"+p_day : p_day;
   return  vYear+'-'+vMon+"-"+vDay;
}

function calendarChange(p_month,p_year)
{
   gCal.set_date(p_month,p_year);
   gCal.show();
}

function calendarClose(datestr)
{
   var arr = datestr.split("-");
   var date = new Date(parseInt(arr[0]), parseInt(arr[1])-1, parseInt(arr[2]));
   datestr = date.print(gCal.gFormat);
   if(gCal.gProc != null) {
     gCal.gProc(gCal,date,datestr);
   } else {
     eval("document."+gCal.gReturnForm+".elements['"+gCal.gReturnItem+"'].value='"+datestr+"'");
     hide();
   }
}

function calendarShow(p_form,p_item,p_month,p_year,p_format,p_proc)
{
   var win = window.open("","Calendar","width=230,height=180,status=no,resizable=yes,top=200,left=200");
   win.opener = self;
   win.focus();
   gCal = new Calendar(win,p_form,p_item,p_month,p_year,p_format,p_proc);
   gCal.show();
}

