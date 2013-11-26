//  Author Vlad Seryakov vlad@crystalballinc.com
//  May 2002
//  $Id: ossweb.js 2927 2007-01-31 00:07:29Z vlad $

var agt = navigator.userAgent.toLowerCase();
var is_major = parseInt(navigator.appVersion);
var is_minor = parseFloat(navigator.appVersion);
var is_gecko = (agt.indexOf('gecko') != -1);
var is_opera = (agt.indexOf("opera") != -1);
var is_ie = (agt.indexOf("msie") != -1 && !is_opera);
var is_ie4 = (is_ie && is_major == 4 && agt.indexOf("msie 4") != -1);
var is_ie5up = (is_ie && is_major >= 4 && !is_ie4);

// Selected object to be moved
var dndObj = null;
// Regexp for dnd objects
var dndRegexp = null, dndNotRegexp = null;
// List of dragable objects
var dndDraggable = new Array();

// Dynamic popup object tracking
var pagePopupTime = null, pagePopupX = 0, pagePopupY = 0;
// Name and class for global pagePopup object
var pagePopupObj = 'pagePopupObj';
var pagePopupClass = 'osswebPopupObj';
var pagePopupCache = new Array();
// DnD position
var dndX = 0, dndY = 0;

// Initialize date arrays
Date.SECOND = 1000;
Date.MINUTE = 60 * Date.SECOND;
Date.HOUR = 60 * Date.MINUTE;
Date.DAY = 24 * Date.HOUR;
Date.WEEK =  7 * Date.DAY;
Date._MD = new Array(31,28,31,30,31,30,31,31,30,31,30,31);
Date._DN = new Array("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday");
Date._MN = new Array("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
Date._DN3 = new Array();
Date._MN3 = new Array();
for(var i = 8; i > 0;) Date._DN3[--i] = Date._DN[i].substr(0, 3);
for(var i = 12; i > 0;) Date._MN3[--i] = Date._MN[i].substr(0, 3);

// Address widget columns
var addressColumns = new Array("number","street","street_type","city","state","zip_code","unit","unit_type","country","address_notes","longitude","latitude","location_name","location_type");

Date.prototype.getMonthDays = function(month)
{
   var year = this.getFullYear();
   if(typeof month == "undefined") month = this.getMonth();
   if(((0 == (year%4)) && ( (0 != (year%100)) || (0 == (year%400)))) && month == 1) return 29;
   return Date._MD[month];
};

Date.prototype.getWeekNumber = function()
{
   var now = new Date(this.getFullYear(), this.getMonth(), this.getDate(), 0, 0, 0);
   var then = new Date(this.getFullYear(), 0, 1, 0, 0, 0);
   var time = now - then;
   var day = then.getDay();
   (day > 3) && (day -= 4) || (day += 3);
   return Math.round(((time / Date.DAY) + day) / 7);
};

Date.prototype.equalsTo = function(date)
{
   return (this.getFullYear() == date.getFullYear() && this.getMonth() == date.getMonth() && this.getDate() == date.getDate());
};

Date.prototype.print = function (frm)
{
   var str = new String(frm);
   var m = this.getMonth();
   var d = this.getDate();
   var y = this.getFullYear();
   var wn = this.getWeekNumber();
   var w = this.getDay();
   var s = new Array();
   s["d"] = d;
   s["dd"] = (d < 10) ? ("0" + d) : d;
   s["m"] = 1+m;
   s["mm"] = (m < 9) ? ("0" + (1+m)) : (1+m);
   s["y"] = y;
   s["yy"] = new String(y).substr(2, 2);
   s["yyyy"] = new String(y);
   s["w"] = wn;
   s["ww"] = (wn < 10) ? ("0" + wn) : wn;
   s["day"] = Date._DN3[w];
   s["dow"] = Date._DN[w];
   s["mon"] = Date._MN3[m];
   s["month"] = Date._MN[m];
   var re = /(.*)(\W|^)(d|dd|m|mm|y|yy|yyyy|w|ww|day|dow|mon|month)(\W|$)(.*)/;
   while (re.exec(str.toLowerCase()) != null) {
   	str = RegExp.$1 + RegExp.$2 + s[RegExp.$3] + RegExp.$4 + RegExp.$5;
   }
   return str;
};

String.prototype.substitute = function(was, becomes)
{
   return this.split(was).join(becomes);
}

// Wrapper around document.getElementById().
function $(id,doc)
{
   if(!doc) doc = document;
   if(typeof id == "string") return doc.getElementById(id);
   return id;
}

function sprintf()
{
   var a = arguments[0].split("%s"), s = a[0];
   for(var i = 1; i < arguments.length; i++) s += arguments[i] + a[i];
   return s;
}

// Initializes printing facility
function printInit()
{
}

// Prints page using ActiveX control or native print facility
function printPage()
{
   window.print();
}

// Show progress icon
function progressShow(title,options)
{
   pagePopupSet('<img src=/img/misc/searching.gif border=0>',options);
   return true;
}

// Disable progress icon
function progressHide(id)
{
   pagePopupClose({name:id});
}

// Progress indicator for the loading window
function progressLoading(url,win,winopts)
{
   var w = window.open('/js/loading.adp?url='+encodeURIComponent(url),win,winopts);
   w.focus();
}

// Removes leading chs
function strlTrim(str,ch)
{
   if(!ch) ch = ' \t\r\n';
   var rc = str + '';
   var c = rc.charAt(0);
   while (rc.length && ch.indexOf(c) >= 0) {
     rc = rc.substring(1,rc.length);
     c = rc.charAt(0);
   }
   return rc;
}

// Removes trailing chars
function strrTrim(str,ch)
{
   if(!ch) ch = ' \t\r\n';
   var rc = str + '';
   var c = rc.charAt(rc.length-1);
   while (rc.length && ch.indexOf(c) >= 0) {
     rc = rc.substring(0,rc.length-1);
     c = rc.charAt(rc.length-1);
   }
   return rc;
}

function strTrim(str,ch)
{
   return strrTrim(strlTrim(str,ch),ch);
}

function strStripHtml(str)
{
   return str.replace(/(<([^>]+)>|\&[a-z]+\;)/ig,'');
}

// Returns value of the specified param in the string, param
// is specified as name=value
function strParam(str,param,def)
{
  var i = 0,j,val = def;
  while (1) {
    if((i = str.indexOf(param,i)) > -1) {
      if(i > 0 && str.charAt(i-1) != ',' && str.charAt(i-1) != ' ') {
        i++;
        continue;
      }
      if(str.charAt(i+param.length) == '{') {
        if((j = str.indexOf('}',++i+param.length)) == -1) j = str.length;
      } else {
        if((j = str.indexOf(',',i)) == -1) j = str.length;
      }
      val = str.substring(i+param.length,j);
    }
    break;
  }
  return val;
}

// Returns integer value of the param
function strParamInt(str,param,def)
{
  var val = strParam(str,param);
  if(val) {
    val = parseInt(val);
    if(!isNaN(val)) return val;
  }
  return def;
}

// Submit on enter key
function formSubmitOnEnter(e,form)
{
  var c;
  if(e && e.which){
    c = e.which;
  } else {
    c = e.keyCode;
  }
  if(c == 13) {
    form.submit();
    return false;
  }
  return true;
}

// Submit form with specified command
function formSubmit(form,cmd,confirm)
{
  if(!form || (confirm && !eval(confirm))) return false;
  if(cmd && form.cmd) form.cmd.value=cmd;
  form.submit();
  return false;
}

// Clears all form elements
function formClear(form,match,skip)
{
  var obj;
  for(var j = 0; j < form.length; j++) {
    obj = form.elements[j];
    if(typeof skip == "string" && skip != '' && obj.name.match(skip)) continue;
    if(typeof match == "string" && match != '' && !obj.name.match(match)) continue;
    switch (obj.type) {
     case 'select':
     case 'select-one':
     case 'select-multiple':
       obj.selectedIndex = 0;
       for(var i = 0; i < obj.options.length; i++)
         obj.options[i].selected = false;
       break;
     case 'checkbox':
     case 'radio':
       obj.checked = false;
       break;
     case 'file':
     case 'text':
     case 'textarea':
       obj.value = '';
       break;
     case 'hidden':
       if(obj.osswebClear) obj.value = '';
       break;
    }
  }
  return false;
}

function formEscape(str)
{
  return encodeURIComponent(str).replace(/\+/,'%2b');
}

// Returns form values as query string
function formExport(form,match,skip)
{
  var str = "";
  if(typeof form == "string") form = document.forms[form];
  if(!form || !form.elements) return str;
  for(var j = 0; j < form.length; j++) {
    if(form.elements[j].name) {
      if(typeof skip == "string" && skip != '' && form.elements[j].name.match(skip)) continue;
      if(typeof match == "string" && match != '' && !form.elements[j].name.match(match)) continue;
    }
    switch(form.elements[j].type) {
     case 'select':
       if(form.elements[j].selectedIndex>=0)
         str = str+"&"+form.elements[j].name+"="+formEscape(form.elements[j].options[form.elements[j].selectedIndex].value);
       break;
     case 'select-multiple':
       for(var i = 0; i < form.elements[j].options.length; i++)
         if(form.elements[j].options[i].selected)
           str = str+"&"+form.elements[j].name+"="+formEscape(form.elements[j].options[i].value);
       break;
     case 'checkbox':
     case 'radio':
       if(form.elements[j].checked)
         str = str+"&"+form.elements[j].name+"="+formEscape(form.elements[j].value);
       break;
     case 'button':
     case 'submit':
     case 'reset':
       break;
     default:
       if(form.elements[j].value != "")
         str = str+"&"+form.elements[j].name+"="+formEscape(form.elements[j].value);
    }
  }
  return str;
}

// Auto advance focus to the next input element in the form
// Usage: <input onKeyUp="formAutoTab(this,3,event)" >
function formAutoTab(obj, len, event)
{
   var kfilter = [0,8,9,16,17,18,37,38,39,40,46];
   var ffilter = ["select","select-one","select-multiple","radio","checkbox","button","submit","reset","text","textarea","file"];
   if(!event || !isIn(kfilter,event.keyCode)) {
     if(!len || (obj.value && obj.value.length >= len)) {
       obj.form[getNext(obj) % obj.form.length].focus();
     }
   }
   function isIn(arr, item) {
     for(var i = 0; i < arr.length; i++) if(arr[i] == item) return true;
     return false;
   }
   function getNext(obj) {
     for(var i = 0, idx = -1; i < obj.form.length; i++) {
       if(idx != -1 && isIn(ffilter, obj.form[i].type)) return i;
       if(obj.form[i] == obj) idx = i;
     }
     return 0;
   }
   return true;
}

// Returns form element object
function formObj(form,name)
{
   if(typeof form == "string") form = document.forms[form];
   if(form) return form.elements[name];
}

// Builds options for specified form select object
// data string format: item|item|...
//   where item can be plain string or title^value list
function formBuildSelect(obj,values)
{
  obj.options.length = 0;
  var data = values.split('|');
  for(var i = 0;i < data.length;i++) {
    var item = data[i].split('^');
    var opt = (item.length == 1  ? new Option(item[0]) : new Option(item[0],item[1]));
    obj.options[obj.options.length] = opt;
  }
}

// Return form field value
function formGet(obj)
{
   if(!obj) return '';
   switch(obj.type) {
    case 'select':
       return obj.options[obj.selectedIndex].value;
    case 'select-multiple':
       rc = '';
       for(var i = 0; i < obj.options.length; i++)
         if(obj.options[i].selected) rc = rc + (i ? ' ' : '') + obj.options[i].value;
       return rc;
    case 'radio':
    case 'checkbox':
       if(!obj.checked) return '';
    default:
       return obj.value;
   }
}

// Sets value to specified form element
function formSet(obj,val)
{
   if(!(obj) || !(obj.name)) return;
   if(obj.type.substr(0,6) == 'select') {
     var val0 = parseInt(strlTrim(val,'0'));
     for(i = 0;i < obj.options.length;i++) {
       if((val0 != NaN && val0 == parseInt(strlTrim(obj.options[i].value,'0'))) || val == obj.options[i].value) {
         obj.selectedIndex = i;
         break;
       }
     }
   } else {
     obj.value = val;
   }
}

// Append value separated by sep, used in autocomplete or lookup
function formAppend(obj,val,sep,ac)
{
   if(!(obj) || !(obj.name)) return;
   if(obj.type.substr(0,6) == 'select') {
     formSet(obj,val);
   } else {
     var br = obj.value.lastIndexOf(sep);
     obj.value = obj.value.substring(0,br > 0 ? br : 0);
     if(obj.value != '') obj.value += sep;
     obj.value += val;
   }
}

// Sets date form element
function formSetDate(form,name,d,m,y)
{
   if(typeof form == "string") form = document.forms[form];
   formSet(form.elements[name+"_month"],m);
   formSet(form.elements[name+"_year"],y);
   formSet(form.elements[name+"_day"],d);
}

// Update date widget with date from the calendar callback
function formCalendarSetDate(obj,date,datestr)
{
   formSetDate(obj.getForm(),obj.getObjName(),date.getDate(),date.getMonth()+1,date.getFullYear());
   obj.hide();
}

function formHeightIncr(obj,add)
{
   if((newHeight = parseInt(obj.style.height) + add) < 3) newHeight = 3;
   obj.style.height = newHeight + "px";
}

function formCheckboxToggle(form,name)
{
   for(var i = 0;i < form.elements.length;i++)
     if(form.elements[i].type == "checkbox" && form.elements[i].name == name)
       form.elements[i].checked = form.elements[i].checked ? false : true;
}

function formComboboxUpdate(name,url,emptyOnly)
{
   if(emptyOnly && varGet(name+'_cb') != '') return;
   varSet(name+'_cb','');
   // Add combobox name to the url
   if(url.indexOf('?') == -1) url += '?';
   url += '&cb_name='+name;
   pagePopupSend(url,name+'_cb');
}

function formComboboxSet(name,value)
{
   var obj = $(name);
   if(obj) obj.value=value;
}

function formComboboxAppend(name,value,sep)
{
   var obj = $(name);
   if(obj) obj.value += (obj.value != "" ? (sep ? sep : ",") : "") + value;
}

function formDropdown(name,value,readonly)
{
   ddFrameHide(name+'_cb');
   $(name).value=value;
   varSet(name+"_id",value);
   varStyle(name+'_cb','display','none')
}

// Reset address widget
function formAddressReset(form,id,prefix)
{
   if(!prefix) prefix = '';
   form.elements[prefix + id].value = '';
   for(var i = 0;i < addressColumns.length; i++) {
     var name = prefix + addressColumns[i];
     if(!form.elements[name]) continue;
     form.elements[name].value = '';
     form.elements[name].selectedIndex=0;
   }
}

// Update address widget from the object
function formAddressSet(form,id,obj,prefix)
{
   if(!prefix) prefix = '';
   formAddressReset(form,id,prefix);
   form.elements[(prefix ? prefix : '') + id].value = obj.address_id;
   for(var i = 0;i < addressColumns.length; i++) {
     var name = prefix + addressColumns[i];
     if(!form.elements[name]) continue;
     var val = obj[addressColumns[i]];
     formSet(form.elements[name],val ? val : '');
   }
}

// Retrieve and set address widget
function formAddressGet(form,url,id,prefix)
{
   pagePopupSend(url,null,function(t,a){eval('var o='+t);formAddressSet(a.form,a.id,o,a.prefix);},{form:form,id:id,prefix:prefix});
}

// Returns query from address widget
function formAddressQuery(form,prefix)
{
   var query = '';
   if(!prefix) prefix = '';
   for(var i = 0;i < addressColumns.length; i++) {
     var name = prefix + addressColumns[i];
     var value = formGet(formObj(form,name));
     query += '&'+addressColumns[i]+'='+escape(value);
   }
   return query;
}

// Fire window with map
function formAddressMap(form,type,prefix)
{
  if(!prefix) prefix = '';
  switch(type) {
   case 0:
     if(form.elements[prefix+'city'].value == '') break;
     var url= escape(form.elements[prefix+'number'].value+' '+
                     form.elements[prefix+'street'].value+' '+
                     form.elements[prefix+'street_type'].value+' '+
                     form.elements[prefix+'city'].value+' '+
                     form.elements[prefix+'state'].value+' '+
                     form.elements[prefix+'zip_code'].value+' '+
                     form.elements[prefix+'country'].value);
     window.open('http://www.google.com/maphp?q='+url,'Map','width=1000,height=800,location=1,menubar=1,toolbar=0,scrollbars=1');
     break;
   case 1:
     if(form.elements[prefix+'latitude'].value == '' || form.elements[prefix+'longitude'].value == '') break;
     var url=form.elements[prefix+'latitude'].value+','+form.elements[prefix+'longitude'].value;
     window.open('http://www.google.com/maphp?spn=0.02,0.02&t=h&ll='+url,'Map','width=1000,height=800,location=1,menubar=1,toolbar=0,scrollbars=1');
     break;
  }
}

// Parses and returns shipping tracking url, default is FedEx
function formTrackingUrl(str)
{
  var url = "", id = str.toLowerCase().split(/[ ,]/);
  if(id[0] == "ups" && id[1] != "") url = "http://wwwapps.ups.com/tracking/tracking.cgi?type1=1&inquiry1="+id[1]; else
  if(id[0] == "usps" && id[1] != "") url = "http://trkcnfrm1.smi.usps.com/PTSInternetWeb/InterLabelInquiry.do?origTrackNum="+id[1]; else
  if(id[0] == "fedex" && id[1] != "") url = "http://www.fedex.com/Tracking?mps=y&language=english&cntry_code=us&tracknumber_list="+id[1]; else
  if(str != "") url = "http://www.fedex.com/Tracking?mps=y&template_type=print&tracknumber_list="+str;
  return url;
}

function formTracking(url)
{
  if(url && url != "") window.open(url,"Track","width=700,height=500,location=0,menubar=0,scrollbars=1");
  return false;
}

function formCursorPos(obj, pos, doc)
{
   if(!(obj = $(obj,doc))) return;
   if(obj.createTextRange) {
     var range = obj.createTextRange();
     range.move("character", pos);
     range.select();
   } else
   if(obj.selectionStart) {
     obj.focus();
     obj.setSelectionRange(pos, pos);
   }
}

// Convert obj into array if it is not already, optionally add another item
function varArray(obj,item)
{
   if(obj && obj.constructor && obj.constructor.toString().indexOf('Array') >= 0) {
     if(item) obj[obj.length] = item;
     return obj;
   }
   var a = new Array();
   if(obj) a[a.length] = obj;
   if(item) a[a.length] = item;
   return a;
}

// Evaluate object method(s)
function varCall(method,obj,opts)
{
   if(!method) return;
   var mlist = varArray(method);
   for(var i = 0;i < mlist.length;i++) {
     try { if(typeof mlist[i] == "function") mlist[i](obj,opts); else eval(mlist[i]); } catch(e) {}
   }
}

function varToggle(obj,value,doc)
{
   obj = $(obj,doc);
   if(obj) obj.innerHTML = (obj.innerHTML == value ? '' : value);
}

function varStyle(obj,style,value,doc)
{
   if(!(obj = $(obj,doc))) return;
   if(style == 'opacity') {
     if(value == 0 && obj.style.visibility != "hidden") obj.style.visibility = "hidden"; else
     if(obj.style.visibility != "visible") obj.style.visibility = "visible";
     if(window.ActiveXObject) obj.style.filter = "alpha(opacity=" + value*100 + ")";
   }
   obj.style[style]=value;
}

function varClass(obj,classname,doc)
{
   obj = $(obj,doc);
   if(obj) obj.className=classname;
}

function varClassToggle(obj, className)
{
   obj = $(obj);
   if(!varClassDel(obj, className) && !varClassAddObj(obj, className)) return false;
   return true;
}

function varClassExists(obj, className)
{
   if(!(obj = $(obj))) return;
   if(obj.className == className) return true;
   var reg = new RegExp('(^| )'+ className +'($| )')
   if(reg.test(obj.className)) return true;
   return false;
}

function varClassDel(obj, className)
{
   if(!(obj = $(obj))) return;
   var cls = obj.className.split(' ');
   var ar = new Array();
   for(var i = cls.length; i > 0;) {
     if(cls[--i] != className) ar[ar.length] = cls[i];
   }
   obj.className = ar.join(' ');
}

function varClassAdd(obj, className)
{
   obj = $(obj);
   if(!obj || varClassExists(obj, className)) return;
   obj.className += ' ' + className;
}

function varGet(obj,doc)
{
   obj = $(obj,doc);
   if(obj) return obj.innerHTML;
   return '';
}

function varSet(obj,text,doc)
{
   obj = $(obj,doc);
   if(obj) obj.innerHTML = text;
   return obj;
}

function varAppend(obj,text,doc)
{
   obj = $(obj,doc);
   if(obj) obj.innerHTML += text;
   return obj;
}

function varPos(obj,doc)
{
   if(!(obj = $(obj,doc))) return { obj: {}, x: 0, y: 0 };
   var r = { obj: obj, x: obj.offsetLeft, y: obj.offsetTop };
   if(obj.offsetParent) {
     var tmp = varPos(obj.offsetParent,doc);
     r.x += tmp.x;
     r.y += tmp.y;
   } else
   if(obj.parentNode && obj.parentNode != document) {
     var tmp = varPos(obj.parentNode,doc);
     r.x += tmp.x;
     r.y += tmp.y;
   }
   return r;
}

// Change visibility to render dimensions if display=none
function varSize(obj,doc)
{
   if(!(obj = $(obj,doc)) || !obj.style) return { width: 0, height: 0};
   var d = obj.style.display;
   if(d != null && d != 'none') return { obj: obj, width: obj.offsetWidth, height: obj.offsetHeight };
   var p = obj.style.position;
   var v = obj.style.visibility;
   obj.style.visibility = 'hidden';
   obj.style.position = 'absolute';
   obj.style.display = 'block';
   var w = obj.clientWidth;
   var h = obj.clientHeight;
   obj.style.display = d;
   obj.style.position = p;
   obj.style.visibility = v;
   if(!w) w = obj.offsetWidth;
   if(!h) h = obj.offsetHeight;
   return { obj: obj, width: w, height: h };
}

function varInside(obj,x,y,doc)
{
   if(!(obj = $(obj,doc))) return;
   var pos = varPos(obj,doc);
   var size = varSize(obj,doc);
   return x >= pos.x && x <= pos.x + size.width && y >= pos.y && y <= pos.y + size.height;
}

function varSound(name,sound,embed)
{
   if(embed || is_win)
     varSet(name,'<EMBED SRC=/snd/'+sound+' HIDDEN=true AUTOSTART=true VOLUME=200>');
   else
     varSet(name,'<IFRAME SRC=/snd/'+sound+' BORDER=0 FRAMEBORDER=0 WIDTH=1 HEIGHT=1></IFRAME>');
}

function varListen(obj,name,fn)
{
   if(!(obj = $(obj))) return;
   if(obj.addEventListener) {
     obj.addEventListener(name,fn,false);
   } else
   if(obj.attachEvent) {
     obj.attachEvent('on'+name,fn);
   } else {
     eval('var ofn=obj.on'+name+';obj.on'+name+'=function(e){if(ofn)ofn(e);return fn(e);}');
   }
}

function varUnlisten(obj,name,fn)
{
   if(!(obj = $(obj))) return;
   if(obj.removeEventListener) {
     obj.removeEventListener(name,fn,false);
   } else
   if(obj.detachEvent) {
     try { obj.detachEvent('on'+name,fn); } catch (e) {}
   }
}

function varDispatch(obj,name)
{
   if(!(obj = $(obj))) return;
   if(document.createEvent) {
     var evt = document.createEvent('MouseEvents');
     evt.initEvent(name,0,0);
     obj.dispatchEvent(evt);
   } else
   if(document.createEventObject) {
     obj.fireEvent('on'+name);
   }
}

function pageSize(win)
{
   if(!win) win = window;
   if(win.innerWidth) return { width: win.innerWidth, height: win.innerHeight };
   var o = win.document.documentElement;
   if(o && (o.clientWidth || o.clientHeight)) return { width: o.clientWidth, height: o.clientHeight };
   o = win.document.body;
   if(o && (o.clientWidth || o.clientHeight)) return { width: o.clientWidth, height: o.clientHeight };
   return { width: 0, height: 0 };
}

function pageOffset(win)
{
   if(!win) win = window;
   if(typeof win.pageYOffset == 'number')  return { y: win.pageYOffset, x: win.pageXOffset };
   var o = win.document.body;
   if(o && (o.scrollLeft || o.scrollTop)) return { y: o.scrollTop, x: o.scrollLeft };
   o = win.document.documentElement;
   if(o && (o.scrollLeft || o.scrollTop)) return { y: o.scrollTop, x: o.scrollLeft };
   return { y: 0, x: 0 };
}

function pageEvent(evt)
{
   if(!evt && !(evt = window.event)) return { event: null, obj: null, x: 0, y: 0 };
   var obj = { event: evt, obj: evt.srcElement ? evt.srcElement : evt.target, x: evt.pageX, y: evt.pageY };
   if(typeof evt.pageX != 'number') {
     var o = pageOffset();
     obj.x = evt.clientX + o.x;
     obj.y = evt.clientY + o.y;
   }
   return obj;
}

function pagePopupInit()
{
   document.onmousedown = pageMouseDown;
   document.onmouseover = pageMouseDown;
}

function pageMouseDown(evt)
{
   evt = pageEvent(evt);
   pagePopupX = evt.x;
   pagePopupY = evt.y;
   pagePopupTime = new Date();
}

// Send request, put result into varname or call given callback
function pagePopupSend(url,varname,callback,opts)
{
   var req, method = 'GET', data = null;
   // Create new request
   try { req = new XMLHttpRequest(); } catch(e) {
     try { req = new ActiveXObject('MSXML2.XMLHTTP.3.0'); } catch(e) {
       try { req = new ActiveXObject('Msxml2.XMLHTTP'); } catch (e) {
         try { req = new ActiveXObject('Microsoft.XMLHTTP'); } catch (e) {}
       }
     }
   }
   if(!req) return;
   if(!opts) opts = {};
   if(opts.post || url.length > 256) {
     var q = url.indexOf('?');
     if(q > 0) {
       data = url.substring(q+1);
       url = url.substring(0,q);
     }
     method = 'POST';
   }
   var async = varname || callback ? true : false;
   req.open(method, url, async);
   req.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
   // Not async, wait for response here
   if(!async) {
     req.send(data);
     return opts.xml ? req.responseXML : req.responseText;
   }
   req.onreadystatechange = function() {
     var ready = false;
     try { ready = (req.readyState == 4 && req.status == 200) } catch (e) {}
     if(ready) {
       if(varname) varSet(varname,req.responseText);
       if(callback) callback(opts.xml ? req.responseXML : req.responseText, opts);
       // Dereference the object
       setTimeout(function(){req=null},100);
     }
   }
   req.send(data);
   return req;
}

function pagePopupGet(url,pageOptions)
{
   var i,j;
   var opts = {
       post: 0, req: 0, local: 0, form: 0, formskip: 0, sync: 0, delay: 0, obj: null, post: 0, xml: 0,
       left: 0, top: 0, width: 0, height: 0, name: pagePopupObj, focus: 0, showat: 0, classname: 0,
       data: 0, bgcolor: 0, border: 0, timeout: 0, followcursor: 0, show: 1,
       onstart: 0, onshow: 0, onclose: 0, ondata: 0, onfinish: 0, onmouseout: 0, onmouseover: 0,
       hide: 0, close: 0, clear: 0, topmove: 0, error: 0, dnd: 0, onemptyhide: 1, cache: 0,
       offset: 16, dataobj: 0, background: 0, custom: 0, progress: 0
   };
   // Update default params with specified ones
   for(key in pageOptions) opts[key] = pageOptions[key];
   // Save current url
   opts.url = url;
   // Object which will show results
   var obj = $(opts.name);
   // Case when url is actual text, not the link
   if(opts.local) {
     if(url.substring(0,7) != 'http://' && url.charAt(0) != '/') {
       if(opts.delay) {
         popupTimerSet(obj, opts.delay, function(){varSet(opts.name,url)});
       } else {
         varSet(opts.name,url);
       }
       return;
     }
   }
   // Append form elements to the url, optionally skip some fields
   if(opts.form) {
     url += '&' + formExport(opts.form,0,opts.formskip);
   }
   // Progress object is given, add to onstart/onshow callbacks
   if(opts.progress) {
      opts.onstart = varArray(opts.onstart,function(){varStyle(opts.progress,'display','block')});
      opts.onfinish = varArray(opts.onfinish,function(){varStyle(opts.progress,'display','none')});
   }
   // Run callback(s) before starting request
   varCall(opts.onstart,obj,opts);
   // Non-async request, return the result or assign given object
   if(opts.sync) {
     var data = pagePopupSend(url);
     if(opts.data || opts.name != pagePopupObj) {
       pagePopupSet(data,opts);
       return;
     }
     varCall(opts.onfinish,obj,opts);
     return data;
   }
   // Cache enabled, check for local copy
   if(opts.cache) {
     if(pagePopupCache[url] != null) {
       pagePopupSet(pagePopupCache[url],opts);
       return;
     }
   }
   var req, delay = opts.delay;
   if(delay) {
     opts.delay = 0;
     popupTimerSet(obj, delay, function(){req = pagePopupSend(url, null, pagePopupSet, opts)});
   } else {
     req = pagePopupSend(url, null, pagePopupSet, opts);
   }
   // Return request object
   if(opts.returnflag) return req;
   // Return nothing to allow it in javascript: urls
   return;
}

function pagePopupSet(pageData,opts)
{
   var i, j, obj, html = '';

   // On data arrival handler, must return modified content back
   if(opts.ondata) {
     try { pageData = opts.ondata(pageData,opts); } catch(e) {}
   }

   // No object to display, do nothing
   if(!(obj = $(opts.name)) && !opts.data) {
     varCall(opts.onfinish,obj,opts);
     return;
   }

   // Standard toolbar with pre-defined actions
   if(opts.close) {
     html += '<DIV ALIGN=RIGHT CLASS=osswebPopupCloseLink onClick="javascript:pagePopupClose({name:\''+opts.name+'\'})"></DIV>';
   }
   // Save in local cache
   if(opts.cache) {
     pagePopupCache[opts.url] = pageData;
   }
   // Hide the popup and exit
   if(!opts.show) {
     pagePopupClose(opts);
     varCall(opts.onfinish,obj,opts);
     return;
   }
   // Just set data and exit
   if(opts.data) {
     varSet(opts.data,pageData);
     varCall(opts.onfinish,obj,opts);
     return;
   }
   // No pageData, exit
   if(typeof pageData != "string" || pageData == '') {
     if(opts.onemptyhide) pagePopupClose(opts);
     varCall(opts.onfinish,obj,opts);
     return;
   }
   html += pageData;
   // Re-route returned data to error object if data contains an exception
   if(opts.error && pageData.match(/^(OSSWEB:)/)) {
     opts.name = 'osswebMsg';
     html = pageData.substring(pageData.indexOf(':')+1);
   }
   opts.data = html;
   popupShow(opts.name,opts);
   varCall(opts.onfinish,obj,opts);
}

function pagePopupClose(pageOptions)
{
   var obj, opts = { clear: 0, obj: null, name: pagePopupObj };
   // Update defaults with specific params
   for(key in pageOptions) opts[key] = pageOptions[key];
   // Object should exist
   if(!(obj = $(opts.name))) return;
   // On close callback
   varCall(opts.onclose,obj,opts);
   // Clear previously assigned timer(s)
   popupTimerClear(obj);
   popupTimerClear(opts.obj);
   popupHide(obj,opts);
}

// Displays named object
// event is a pointer to the Event object passed when the event occurs
// name is the ID attribute of the element to show
// data if defined, set variable with this data before showing
// dataobj specified name of the object which contents should be displayed
// hide if defined , start auto-hide timer
// parent if defined, show popup under parent
function popupShow(obj,opts)
{
   if(!(obj = $(obj)) || !obj.style) return;
   if(!opts) opts = {};
   popupTimerClear(obj);
   var delay = opts.delay;
   if(delay) {
     opts.delay = 0;
     popupTimerSet(obj, delay, function(){popupShow(obj, opts)});
     return;
   }
   // Some required params
   if(!opts.x) opts.x = 0;
   if(!opts.y) opts.y = 0;
   if(!opts.offset) opts.offset = 16;
   // Offset by the owner
   if(obj.obj) opts.offset = varSize(obj.obj).height + 1;
   // Get contents from the given object
   if(opts.dataobj) opts.data = varGet(opts.dataobj);
   // Follow event
   if(opts.event) {
     var e = pageEvent(opts.event);
     opts.top = e.y;
     opts.left = e.x;
   } else
   // Show under parent
   if(opts.parent) {
     var pos = varPos(opts.parent);
     opts.top = pos.y;
     opts.left = pos.x;
     // Offset by the parent
     opts.offset = varSize(opts.parent).height + 1;
   } else
   // Follow the cursor
   if(opts.followcursor) {
      // Nothing given, follow the current position
      if(!opts.left && !opts.top) {
        opts.top = pagePopupY;
        opts.left = pagePopupX;
      } else {
        // Add page scrolling to given coordinates
        var o = pageOffset();
        if(opts.top) opts.top += o.y;
        if(opts.left) opts.left += o.x;
      }
   } else 
   if (opts.top || opts.left) {
       // Add page scrolling to given coordinates
       var o = pageOffset();
       opts.top += o.y;
       opts.left += o.x;
   }
   // Class to assign on show, reset bgcolor so it will be reassigned
   obj.style.backgroundColor = '';
   if(opts.background) obj.style.background = opts.background;
   if(opts.classname) varClass(obj,opts.classname); else
   if(opts.name == pagePopupObj) varClass(obj, pagePopupClass);
   if(opts.classes) varClassAdd(obj,opts.classes);
   if(opts.bgcolor) obj.style.backgroundColor = opts.bgcolor;
   if(opts.border) obj.style.border = opts.border;
   if(opts.zindex) obj.style.zIndex = opts.zindex;
   // Update size
   if(opts.followcursor) {
     if(opts.width) obj.style.width = opts.width+'px';
     if(opts.height) obj.style.height = opts.height+'px';
     if(opts.topmove) obj.dndTop = opts.topmove;
     varCall(popupPosition,obj,opts);
   }
   // Custom handlers, can change anything before displaying the popup
   varCall(opts.custom,obj,opts);
   // Assign coordinates, add optional x/y adjustments
   if(opts.left) obj.style.left = parseInt(opts.left) + opts.x;
   if(opts.top) obj.style.top = parseInt(opts.top) + opts.y + opts.offset;
   // Autohide after timeout
   if(opts.timeout) popupTimerSet(obj,opts.timeout,function(){popupHide(obj)});
   // onMouseOut timeout
   obj.onmouseout = opts.onmouseout ? opts.onmouseout : null;
   obj.onmouseover = opts.onmouseover ? opts.onmouseover : null;
   // Hide on mouse out
   if(opts.hide) {
     obj.popupTimeout = opts.hide > 1 ? opts.hide : opts.timeout ? opts.timeout : 100;
     obj.onmouseout = function(e){popupHide(obj,{delay:obj.popupTimeout})};
     obj.onmouseover = function(e){popupTimerClear(obj)};
   }
   // Enable drag and drop
   if(opts.dnd) {
     dndInit();
     dndAddObj(obj);
   } else {
     dndDelObj(obj);
   }
   // Update contents with given data
   if(opts.data) varSet(obj, opts.data);
   obj.style.display = "block";
   ddFrameShow(obj);
   // Focused object on show
   if(opts.focus) try { $(opts.focus).focus() } catch(e) {};
   // Call on show callback(s)
   varCall(opts.onshow,obj,opts);
}

// Shows menu popup object
function popupShowMenu(event,name)
{
  if(event.which == 2 || event.which == 3) {
    popupShow(name,{event:event});
    return false;
  }
  return true;
}

// Hides named object
function popupHide(obj,opts)
{
   if(!(obj = $(obj)) || !obj.style) return;
   if(!opts) opts = {};
   var delay = opts.delay;
   if(delay) {
     opts.delay = 0;
     popupTimerSet(obj, delay, function(){popupHide(obj, opts)});
   } else {
     ddFrameHide(obj);
     obj.style.display = 'none';
     if(opts.clear) obj.innerHTML = '';
     popupTimerClear(obj);
   }
}

// Toggles visibility for named object
function popupToggle(obj)
{
   if(!(obj = $(obj)) || !obj.style) return;
   if(obj.style.display == 'none') {
     obj.style.display = 'block';
     ddFrameShow(obj);
   } else {
     ddFrameHide(obj);
     obj.style.display = 'none';
   }
}

// Assign timer to the object
function popupTimerSet(obj,delay,proc)
{
   if((obj = $(obj))) {
     popupTimerClear(obj);
     obj.popupTimer = setTimeout(proc, delay);
   }
}

// Clear object timer
function popupTimerClear(obj)
{
   if((obj = $(obj)) && obj.popupTimer) {
     clearTimeout(obj.popupTimer);
     obj.popupTimer = null;
   }
}

// Calculate popup position
function popupPosition(obj,opts)
{
   var size = varSize(obj), win = pageSize(), off = pageOffset();
   opts.pos = (opts.top - off.y < win.height/2) ? 't' : 'b';
   if(!opts.offset) opts.offset = 16;
   if(opts.left - off.x < win.width/4) opts.pos += 'l'; else
   if(opts.left - off.x > (win.width*3/4)) opts.pos += 'r'; else opts.pos += 'm';
   switch(opts.pos) {
    case 'tl': opts.top += opts.offset; break;
    case 'tm': opts.left -= (size.width/2);opts.top += opts.offset; break;
    case 'tr': opts.left -= size.width; opts.top += opts.offset; break;
    case 'bl': opts.top -= (size.height + opts.offset/2);break;
    case 'bm': opts.left -= (size.width/2);opts.top -= (size.height + opts.offset/2);break;
    case 'br': opts.left -= size.width;opts.top -= (size.height + opts.offset/2);break;
   }
   opts.offset = 0;
}

// Show bubble image with arrows
function popupBubble(obj,opts)
{
   obj.style.width = 242;
   obj.style.height = 232;
   popupPosition(obj, opts);
   switch(opts.pos) {
    case 'tl': obj.style.topPadding = '42px';break;
    case 'tm': obj.style.topPadding = '42px';break;
    case 'tr': obj.style.topPadding = '42px';break;
   }
   obj.style.border = '0px';
   obj.style.padding = '0px';
   obj.style.background='url("/img/bg/bubble_'+opts.pos+'.png") '+(opts.pos.charAt(0)=='b'?'bottom':'top')+' left no-repeat';
}

// Initialize mouse capturing
pagePopupInit();

// Performs drag and rop initialization
function dndInit(allow,disallow)
{
   document.onmouseup = dndDrop;
   document.onmouseover = dndOver;
   document.onmousemove = dndDrag;
   document.onmousedown = dndSelect;
   if(allow) dndRegexp = allow;
   if(disallow) dndNotRegexp = ignore;
}

// Returns object if supposed to be dragged
function dndPtr(evt)
{
   var obj = pageEvent(evt).obj;
   if(!obj) return null;
   // Skip text nodes
   while(obj && (!obj.id || obj.nodeType == 3)) obj = obj.parentNode;
   if(!obj || !obj.style) return null;
   if(obj.style.cursor != 'move') obj.oldCursor = obj.style.cursor;
   if(!(dndNotRegexp && obj.id.match(dndNotRegexp))) {
     if(((dndDraggable[obj.id] || obj.id.indexOf(pagePopupObj) > -1) &&
         pagePopupY < parseInt(obj.style.top)+(obj.dndTop ? obj.dndTop : 30)) ||
        obj.id.indexOf("DND") > -1 ||
        (dndRegexp && obj.id.match(dndRegexp))) {
       obj.style.cursor = "move";
       return obj;
     }
   }
   if(obj.oldCursor) obj.style.cursor = obj.oldCursor;
   return null;
}

// Over handler to update css dunamically
function dndOver(evt)
{
   pageMouseDown(evt);
   var obj = dndPtr(evt);
   if(obj) {
     if(evt) evt.cancelBubble = true; else window.event.cancelBubble = true;
   }
}

// Determines the mouse cursor position relative to element
function dndSelect(evt)
{
   // Popup compatibility
   pageMouseDown(evt);
   dndObj = dndPtr(evt);
   if(dndObj) {
     if(evt) evt.cancelBubble = true; else window.event.cancelBubble = true;
     try {
       dndObj = dndOnSelect(dndObj,parseFloat(dndObj.style.left),parseFloat(dndObj.style.top));
     } catch(e) {}
     if(dndObj.dndOnSelect) {
       dndObj = dndObj.dndOnSelect(parseFloat(dndObj.style.left),parseFloat(dndObj.style.top));
     }
     dndX = parseInt(dndObj.style.left);
     dndY = parseInt(dndObj.style.top);
     if(isNaN(dndX)) dndX = pagePopupX;
     if(isNaN(dndY)) dndY = pagePopupY;
     dndX = pagePopupX - dndX;
     dndY = pagePopupY - dndY;
     dndObj.style.zIndex = 9000;
     dndObj.style.cursor = "move";
     ddFrameShow(dndObj);
     return false;
   }
   return true;
}

// Positions the dragging element
function dndDrag(evt)
{
   // Popup compatibility
   pageMouseDown(evt);
   if(dndObj) {
     var drag = true;
     if(evt) evt.cancelBubble = true; else window.event.cancelBubble = true;
     try {
       drag = dndOnDrag(dndObj,pagePopupX - dndX,pagePopupY - dndY);
     } catch(e) {}
     if(dndObj.dndOnDrag && drag) {
       drag = dndObj.dndOnDrag(pagePopupX - dndX,pagePopupY - dndY);
     }
     if(!drag) return false;
     dndObj.style.top = pagePopupY - dndY;
     dndObj.style.left = pagePopupX - dndX;
     ddFrameShow(dndObj);
   }
   return false;
}

// Releases the element, calles dndOnDrop function
function dndDrop(evt)
{
   if(dndObj) {
     if(dndObj.dndOnDrop) {
       dndObj.dndOnDrop(parseFloat(dndObj.style.left),parseFloat(dndObj.style.top));
     }
     try {
       dndOnDrop(dndObj,parseFloat(dndObj.style.left),parseFloat(dndObj.style.top));
     } catch(e) {}
     if(dndObj.dndParent) {
       dndObj.dndParent.removeChild(dndObj);
     }
     dndObj.style.cursor = dndObj.oldCursor ? dndObj.oldCursor : "default";
     dndObj = null;
     return false;
   }
   return true;
}

// Setup object as draggable
function dndAddObj(obj)
{
   if(obj && obj.id) dndDraggable[obj.id] = obj;
}

// Remove object from draggable list
function dndDelObj(obj)
{
   if(obj && obj.id) dndDraggable[obj.id] = null;
}

// Create DIV with icon for given object that will be moved instead of dragging
// the real object
function dndCreateObj(parent,name,text,obj)
{
   div = document.createElement('div');
   div.id = name;
   div.style.display = 'block';
   div.style.position = 'absolute';
   div.style.left = pagePopupX;
   div.style.top = pagePopupY;
   if(text.match(/\.(gif|png|jpg)$/)) {
     div.innerHTML = '<IMG SRC='+text+' BORDER=0>';
   } else {
     div.innerHTML = text;
   }
   div.rowWidth = varSize(obj).width;
   div.dndObj = obj;
   div.dndParent = parent;
   parent.appendChild(div);
   return div;
}

function ddKeep(obj)
{
  if(obj.ddHideTimer) window.clearTimeout(obj.ddHideTimer);
  obj.ddHideTimer = null;
}

function ddClear(obj)
{
  obj.ddHideTimer = window.setTimeout(function(){ddHide(obj)},500);
}

function ddShowMenu(id, owner, event)
{
  var obj = $(id);
  if(!obj || !obj.style) return;
  if(obj.ddHideTimer) {
    window.clearTimeout(obj.ddHideTimer);
    obj.ddHideTimer = null;
  }
  obj.ddShowTimer = window.setTimeout(function(){ddShow(obj)},100);
  obj.ddObj = $(owner);
}

function ddHideMenu(id, owner, event)
{
  var obj = $(id);
  if(!obj || !obj.style) return;
  if(obj.ddShowTimer) {
    window.clearTimeout(obj.ddShowTimer);
    obj.ddShowTimer = null;
  }
  obj.ddObj = $(owner);
  obj.ddHideTimer = window.setTimeout(function(){ddHide(obj)},500);
}

function ddToggle(id, owner, event)
{
  var obj = $(id);
  if(!obj || !obj.style) return;
  if(owner) obj.ddObj = $(owner);
  if(obj.style.display != 'block') {
    ddShow(obj.id);
  } else {
    ddHide(obj.id);
  }
}

function ddShow(id)
{
  var obj = $(id);
  if(!obj || !obj.style) return;
  var pos = varPos(obj.ddObj);
  if(pos) {
    pos.y += obj.ddObj.offsetHeight - 1;
    obj.style.top = pos.y;
    obj.style.left = pos.x;
    if(obj.ddObj.className.charAt(obj.ddObj.className.length-1) == '1') {
      obj.ddObj.className = obj.ddObj.className.substring(0,obj.ddObj.className.length-1) + '2';
    }
  }
  obj.style.zIndex = 2000;
  obj.style.display = "block";
  if(obj.ddObj) {
    if(obj.className != 'osswebPopupTable' && obj.offsetWidth < obj.ddObj.offsetWidth) obj.style.width = obj.ddObj.offsetWidth;
    ddFrameShow(obj);
  }
}

function ddHide(id)
{
  var obj = $(id);
  if(!obj || !obj.style) return;
  if(obj.ddObj) {
    if(obj.ddObj.className.charAt(obj.ddObj.className.length-1) == '2') {
      obj.ddObj.className = obj.ddObj.className.substring(0,obj.ddObj.className.length-1) + '1';
    }
  }
  ddFrameHide(obj);
  obj.style.display = 'none';
}

// Show iframe to hide elements under popup
function ddFrameShow(obj)
{
  if(!is_ie) return;
  obj = $(obj);
  if(!obj || !obj.style) return;
  var frame = $(obj.id+'f');
  if(frame) {
    frame.style.top = obj.style.top;
    frame.style.left = obj.style.left;
    frame.style.width = obj.offsetWidth;
    frame.style.height = obj.offsetHeight;
    frame.style.display = "block";
    frame.style.zIndex = 1999;
  }
}

function ddFrameHide(obj)
{
  if(!is_ie) return;
  obj = $(obj);
  if(!obj || !obj.style) return;
  var frame = $(obj.id+'f');
  if(frame) frame.style.display = "none";
}

