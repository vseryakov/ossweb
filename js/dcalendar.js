/*  Copyright Mihai Bazon, 2002  |  http://www.bazon.net/mishoo
 * ---------------------------------------------------------------------
 *
 * Feel free to use this script under the terms of the GNU Lesser General
 * Public License, as long as you do not remove or alter this notice.
 */

window.dcalendar = null;

DCalendar = function (dateStr, onSelected, onClose)
{
	this.activeDiv = null;
	this.currentDateEl = null;
	this.checkDisabled = null;
	this.timeout = null;
	this.onSelected = onSelected || null;
	this.onClose = onClose || null;
	this.dragging = false;
	this.hidden = false;
	this.minYear = 1950;
	this.maxYear = 2050;
	this.dateFormat = DCalendar._TT["DEF_DATE_FORMAT"];
	this.ttDateFormat = DCalendar._TT["TT_DATE_FORMAT"];
	this.isPopup = true;
	this.weekNumbers = true;
	this.mondayFirst = true;
	this.dateStr = dateStr;
	this.ar_days = null;
	this.table = null;
	this.element = null;
	this.tbody = null;
	this.firstdayname = null;
	this.monthsCombo = null;
	this.yearsCombo = null;
	this.hilitedMonth = null;
	this.activeMonth = null;
	this.hilitedYear = null;
	this.activeYear = null;
};

DCalendar.isRelated = function (el, evt)
{
	var related = evt.relatedTarget;
	if (!related) {
		var type = evt.type;
		if (type == "mouseover") {
			related = evt.fromElement;
		} else if (type == "mouseout") {
			related = evt.toElement;
		}
	}
	while (related) {
		if (related == el) {
			return true;
		}
		related = related.parentNode;
	}
	return false;
};

DCalendar.getElement = function(ev)
{
	if (DCalendar.is_ie) {
		return window.event.srcElement;
	} else {
		return ev.currentTarget;
	}
};

DCalendar.getTargetElement = function(ev)
{
	if (DCalendar.is_ie) {
		return window.event.srcElement;
	} else {
		return ev.target;
	}
};

DCalendar.stopEvent = function(ev)
{
	if (DCalendar.is_ie) {
		window.event.cancelBubble = true;
		window.event.returnValue = false;
	} else {
		ev.preventDefault();
		ev.stopPropagation();
	}
};

DCalendar.addEvent = function(el, evname, func)
{
	if (DCalendar.is_ie) {
		el.attachEvent("on" + evname, func);
	} else {
		el.addEventListener(evname, func, true);
	}
};

DCalendar.removeEvent = function(el, evname, func)
{
	if (DCalendar.is_ie) {
		el.detachEvent("on" + evname, func);
	} else {
		el.removeEventListener(evname, func, true);
	}
};

DCalendar.createElement = function(type, parent)
{
	var el = null;
	if (document.createElementNS) {
		el = document.createElementNS("http://www.w3.org/1999/xhtml", type);
	} else {
		el = document.createElement(type);
	}
	if (typeof parent != "undefined") {
		parent.appendChild(el);
	}
	return el;
};

DCalendar._add_evs = function(el)
{
	with (DCalendar) {
		addEvent(el, "mouseover", dayMouseOver);
		addEvent(el, "mousedown", dayMouseDown);
		addEvent(el, "mouseout", dayMouseOut);
		if (is_ie) {
			addEvent(el, "dblclick", dayMouseDblClick);
			el.setAttribute("unselectable", true);
		}
	}
};

DCalendar.findMonth = function(el)
{
	if (typeof el.month != "undefined") {
		return el;
	} else if (typeof el.parentNode.month != "undefined") {
		return el.parentNode;
	}
	return null;
};

DCalendar.findYear = function(el)
{
	if (typeof el.year != "undefined") {
		return el;
	} else if (typeof el.parentNode.year != "undefined") {
		return el.parentNode;
	}
	return null;
};

DCalendar.showMonthsCombo = function ()
{
	var cal = DCalendar._C;
	if (!cal) {
		return false;
	}
	var cal = cal;
	var cd = cal.activeDiv;
	var mc = cal.monthsCombo;
	if (cal.hilitedMonth) {
		varClassDel(cal.hilitedMonth, "hilite");
	}
	if (cal.activeMonth) {
		varClassDel(cal.activeMonth, "active");
	}
	var mon = cal.monthsCombo.getElementsByTagName("div")[cal.date.getMonth()];
	varClassAdd(mon, "active");
	cal.activeMonth = mon;
	mc.style.left = cd.offsetLeft + "px";
	mc.style.top = (cd.offsetTop + cd.offsetHeight) + "px";
	mc.style.display = "block";
};

DCalendar.showYearsCombo = function (fwd)
{
	var cal = DCalendar._C;
	if (!cal) {
		return false;
	}
	var cal = cal;
	var cd = cal.activeDiv;
	var yc = cal.yearsCombo;
	if (cal.hilitedYear) {
		varClassDel(cal.hilitedYear, "hilite");
	}
	if (cal.activeYear) {
		varClassDel(cal.activeYear, "active");
	}
	cal.activeYear = null;
	var Y = cal.date.getFullYear() + (fwd ? 1 : -1);
	var yr = yc.firstChild;
	var show = false;
	for (var i = 12; i > 0; --i) {
		if (Y >= cal.minYear && Y <= cal.maxYear) {
			yr.firstChild.data = Y;
			yr.year = Y;
			yr.style.display = "block";
			show = true;
		} else {
			yr.style.display = "none";
		}
		yr = yr.nextSibling;
		Y += fwd ? 2 : -2;
	}
	if (show) {
		yc.style.left = cd.offsetLeft + "px";
		yc.style.top = (cd.offsetTop + cd.offsetHeight) + "px";
		yc.style.display = "block";
	}
};

DCalendar.tableMouseUp = function(ev)
{
	var cal = DCalendar._C;
	if (!cal) {
		return false;
	}
	if (cal.timeout) {
		clearTimeout(cal.timeout);
	}
	var el = cal.activeDiv;
	if (!el) {
		return false;
	}
	var target = DCalendar.getTargetElement(ev);
	varClassDel(el, "active");
	if (target == el || target.parentNode == el) {
		DCalendar.cellClick(el);
	}
	var mon = DCalendar.findMonth(target);
	var date = null;
	if (mon) {
		date = new Date(cal.date);
		if (mon.month != date.getMonth()) {
			date.setMonth(mon.month);
			cal.setDate(date);
		}
	} else {
		var year = DCalendar.findYear(target);
		if (year) {
			date = new Date(cal.date);
			if (year.year != date.getFullYear()) {
				date.setFullYear(year.year);
				cal.setDate(date);
			}
		}
	}
	with (DCalendar) {
		removeEvent(document, "mouseup", tableMouseUp);
		removeEvent(document, "mouseover", tableMouseOver);
		removeEvent(document, "mousemove", tableMouseOver);
		cal._hideCombos();
		stopEvent(ev);
		_C = null;
	}
};

DCalendar.tableMouseOver = function (ev)
{
	var cal = DCalendar._C;
	if (!cal) {
		return;
	}
	var el = cal.activeDiv;
	var target = DCalendar.getTargetElement(ev);
	if (target == el || target.parentNode == el) {
		varClassAdd(el, "hilite active");
		varClassAdd(el.parentNode, "rowhilite");
	} else {
		varClassDel(el, "active");
		varClassDel(el, "hilite");
		varClassDel(el.parentNode, "rowhilite");
	}
	var mon = DCalendar.findMonth(target);
	if (mon) {
		if (mon.month != cal.date.getMonth()) {
			if (cal.hilitedMonth) {
				varClassDel(cal.hilitedMonth, "hilite");
			}
			varClassAdd(mon, "hilite");
			cal.hilitedMonth = mon;
		} else if (cal.hilitedMonth) {
			varClassDel(cal.hilitedMonth, "hilite");
		}
	} else {
		var year = DCalendar.findYear(target);
		if (year) {
			if (year.year != cal.date.getFullYear()) {
				if (cal.hilitedYear) {
					varClassDel(cal.hilitedYear, "hilite");
				}
				varClassAdd(year, "hilite");
				cal.hilitedYear = year;
			} else if (cal.hilitedYear) {
				varClassDel(cal.hilitedYear, "hilite");
			}
		}
	}
	DCalendar.stopEvent(ev);
};

DCalendar.tableMouseDown = function (ev)
{
	if (DCalendar.getTargetElement(ev) == DCalendar.getElement(ev)) {
		DCalendar.stopEvent(ev);
	}
};

DCalendar.calDragIt = function (ev)
{
	var cal = DCalendar._C;
	if (!(cal && cal.dragging)) {
		return false;
	}
	var posX;
	var posY;
	if (DCalendar.is_ie) {
		posY = window.event.clientY + document.body.scrollTop;
		posX = window.event.clientX + document.body.scrollLeft;
	} else {
		posX = ev.pageX;
		posY = ev.pageY;
	}
	cal.hideShowCovered();
	var st = cal.element.style;
	st.left = (posX - cal.xOffs) + "px";
	st.top = (posY - cal.yOffs) + "px";
	DCalendar.stopEvent(ev);
};

DCalendar.calDragEnd = function (ev)
{
	var cal = DCalendar._C;
	if (!cal) {
		return false;
	}
	cal.dragging = false;
	with (DCalendar) {
		removeEvent(document, "mousemove", calDragIt);
		removeEvent(document, "mouseover", stopEvent);
		removeEvent(document, "mouseup", calDragEnd);
		tableMouseUp(ev);
	}
	cal.hideShowCovered();
};

DCalendar.dayMouseDown = function(ev)
{
	var el = DCalendar.getElement(ev);
	if (el.disabled) {
		return false;
	}
	var cal = el.dcalendar;
	cal.activeDiv = el;
	DCalendar._C = cal;
	if (el.navtype != 300) with (DCalendar) {
		varClassAdd(el, "hilite active");
		addEvent(document, "mouseover", tableMouseOver);
		addEvent(document, "mousemove", tableMouseOver);
		addEvent(document, "mouseup", tableMouseUp);
	} else if (cal.isPopup) {
		cal._dragStart(ev);
	}
	DCalendar.stopEvent(ev);
	if (el.navtype == -1 || el.navtype == 1) {
		cal.timeout = setTimeout("DCalendar.showMonthsCombo()", 250);
	} else if (el.navtype == -2 || el.navtype == 2) {
		cal.timeout = setTimeout((el.navtype > 0) ? "DCalendar.showYearsCombo(true)" : "DCalendar.showYearsCombo(false)", 250);
	} else {
		cal.timeout = null;
	}
};

DCalendar.dayMouseDblClick = function(ev)
{
	DCalendar.cellClick(DCalendar.getElement(ev));
	if (DCalendar.is_ie) {
		document.selection.empty();
	}
};

DCalendar.dayMouseOver = function(ev)
{
	var el = DCalendar.getElement(ev);
	if (DCalendar.isRelated(el, ev) || DCalendar._C || el.disabled) {
		return false;
	}
	if (el.ttip) {
		if (el.ttip.substr(0, 1) == "_") {
			var date = null;
			with (el.dcalendar.date) {
				date = new Date(getFullYear(), getMonth(), el.caldate);
			}
			el.ttip = date.print(el.dcalendar.ttDateFormat) + el.ttip.substr(1);
		}
		el.dcalendar.tooltips.firstChild.data = el.ttip;
	}
	if (el.navtype != 300) {
		varClassAdd(el, "hilite");
		if (el.caldate) {
			varClassAdd(el.parentNode, "rowhilite");
		}
	}
	DCalendar.stopEvent(ev);
};

DCalendar.dayMouseOut = function(ev)
{
	with (DCalendar) {
		var el = getElement(ev);
		if (isRelated(el, ev) || _C || el.disabled) {
			return false;
		}
		varClassDel(el, "hilite");
		if (el.caldate) {
			varClassDel(el.parentNode, "rowhilite");
		}
		el.dcalendar.tooltips.firstChild.data = _TT["SEL_DATE"];
		stopEvent(ev);
	}
};

DCalendar.cellClick = function(el)
{
	var cal = el.dcalendar;
	var closing = false;
	var newdate = false;
	var date = null;
	if (typeof el.navtype == "undefined") {
		varClassDel(cal.currentDateEl, "selected");
		varClassAdd(el, "selected");
		closing = (cal.currentDateEl == el);
		if (!closing) {
			cal.currentDateEl = el;
		}
		cal.date.setDate(el.caldate);
		date = cal.date;
		newdate = true;
	} else {
		if (el.navtype == 200) {
			varClassDel(el, "hilite");
			cal.callCloseHandler();
			return;
		}
		date = (el.navtype == 0) ? new Date() : new Date(cal.date);
		var year = date.getFullYear();
		var mon = date.getMonth();
		function setMonth(m) {
			var day = date.getDate();
			var max = date.getMonthDays(m);
			if (day > max) {
				date.setDate(max);
			}
			date.setMonth(m);
		};
		switch (el.navtype) {
		    case -2:
			if (year > cal.minYear) {
				date.setFullYear(year - 1);
			}
			break;
		    case -1:
			if (mon > 0) {
				setMonth(mon - 1);
			} else if (year-- > cal.minYear) {
				date.setFullYear(year);
				setMonth(11);
			}
			break;
		    case 1:
			if (mon < 11) {
				setMonth(mon + 1);
			} else if (year < cal.maxYear) {
				date.setFullYear(year + 1);
				setMonth(0);
			}
			break;
		    case 2:
			if (year < cal.maxYear) {
				date.setFullYear(year + 1);
			}
			break;
		    case 100:
			cal.setMondayFirst(!cal.mondayFirst);
			return;
		}
		if (!date.equalsTo(cal.date)) {
			cal.setDate(date);
			newdate = el.navtype == 0;
		}
	}
	if (newdate) {
		cal.callHandler();
	}
	if (closing) {
		varClassDel(el, "hilite");
		cal.callCloseHandler();
	}
};

DCalendar._keyEvent = function(ev)
{
	if (!window.dcalendar) {
		return false;
	}
	(DCalendar.is_ie) && (ev = window.event);
	var cal = window.dcalendar;
	var act = (DCalendar.is_ie || ev.type == "keypress");
	if (ev.ctrlKey) {
		switch (ev.keyCode) {
		    case 37: // KEY left
			act && DCalendar.cellClick(cal._nav_pm);
			break;
		    case 38: // KEY up
			act && DCalendar.cellClick(cal._nav_py);
			break;
		    case 39: // KEY right
			act && DCalendar.cellClick(cal._nav_nm);
			break;
		    case 40: // KEY down
			act && DCalendar.cellClick(cal._nav_ny);
			break;
		    default:
			return false;
		}
	} else switch (ev.keyCode) {
	    case 32: // KEY space (now)
		DCalendar.cellClick(cal._nav_now);
		break;
	    case 27: // KEY esc
		act && cal.hide();
		break;
	    case 37: // KEY left
	    case 38: // KEY up
	    case 39: // KEY right
	    case 40: // KEY down
		if (act) {
			var date = cal.date.getDate() - 1;
			var el = cal.currentDateEl;
			var ne = null;
			var prev = (ev.keyCode == 37) || (ev.keyCode == 38);
			switch (ev.keyCode) {
			    case 37: // KEY left
				(--date >= 0) && (ne = cal.ar_days[date]);
				break;
			    case 38: // KEY up
				date -= 7;
				(date >= 0) && (ne = cal.ar_days[date]);
				break;
			    case 39: // KEY right
				(++date < cal.ar_days.length) && (ne = cal.ar_days[date]);
				break;
			    case 40: // KEY down
				date += 7;
				(date < cal.ar_days.length) && (ne = cal.ar_days[date]);
				break;
			}
			if (!ne) {
				if (prev) {
					DCalendar.cellClick(cal._nav_pm);
				} else {
					DCalendar.cellClick(cal._nav_nm);
				}
				date = (prev) ? cal.date.getMonthDays() : 1;
				el = cal.currentDateEl;
				ne = cal.ar_days[date - 1];
			}
			varClassDel(el, "selected");
			varClassAdd(ne, "selected");
			cal.date.setDate(ne.caldate);
			cal.currentDateEl = ne;
		}
		break;
	    case 13: // KEY enter
		if (act) {
			cal.callHandler();
			cal.hide();
		}
		break;
	    default:
		return false;
	}
	DCalendar.stopEvent(ev);
};

DCalendar._checkCalendar = function(ev)
{
	if (!window.dcalendar) {
		return false;
	}
	var el = DCalendar.is_ie ? DCalendar.getElement(ev) : DCalendar.getTargetElement(ev);
	for (; el != null && el != dcalendar.element; el = el.parentNode);
	if (el == null) {
		window.dcalendar.callCloseHandler();
		DCalendar.stopEvent(ev);
	}
};

DCalendar.prototype.create = function (_par)
{
	var parent = null;
	if (! _par) {
		parent = document.getElementsByTagName("body")[0];
		this.isPopup = true;
	} else {
		parent = _par;
		this.isPopup = false;
	}
	this.date = this.dateStr ? new Date(this.dateStr) : new Date();

	var table = DCalendar.createElement("table");
	this.table = table;
	table.cellSpacing = 0;
	table.cellPadding = 0;
	table.dcalendar = this;
	DCalendar.addEvent(table, "mousedown", DCalendar.tableMouseDown);

	var div = DCalendar.createElement("div");
	this.element = div;
	div.className = "dcalendar";
	if (this.isPopup) {
		div.style.position = "absolute";
		div.style.display = "none";
	}
	div.appendChild(table);

	var thead = DCalendar.createElement("thead", table);
	var cell = null;
	var row = null;

	var cal = this;
	var hh = function (text, cs, navtype) {
		cell = DCalendar.createElement("td", row);
		cell.colSpan = cs;
		cell.className = "button";
		DCalendar._add_evs(cell);
		cell.dcalendar = cal;
		cell.navtype = navtype;
		if (text.substr(0, 1) != "&") {
			cell.appendChild(document.createTextNode(text));
		}
		else {
			cell.innerHTML = text;
		}
		return cell;
	};

	row = DCalendar.createElement("tr", thead);
	var title_length = 6;
	(this.isPopup) && --title_length;
	(this.weekNumbers) && ++title_length;

	hh("-", 1, 100).ttip = DCalendar._TT["TOGGLE"];
	this.title = hh("", title_length, 300);
	this.title.className = "title";
	if (this.isPopup) {
		this.title.ttip = DCalendar._TT["DRAG_TO_MOVE"];
		this.title.style.cursor = "move";
		hh("&#x00d7;", 1, 200).ttip = DCalendar._TT["CLOSE"];
	}

	row = DCalendar.createElement("tr", thead);
	row.className = "headrow";

	this._nav_py = hh("&#x00ab;", 1, -2);
	this._nav_py.ttip = DCalendar._TT["PREV_YEAR"];

	this._nav_pm = hh("&#x2039;", 1, -1);
	this._nav_pm.ttip = DCalendar._TT["PREV_MONTH"];

	this._nav_now = hh(DCalendar._TT["TODAY"], this.weekNumbers ? 4 : 3, 0);
	this._nav_now.ttip = DCalendar._TT["GO_TODAY"];

	this._nav_nm = hh("&#x203a;", 1, 1);
	this._nav_nm.ttip = DCalendar._TT["NEXT_MONTH"];

	this._nav_ny = hh("&#x00bb;", 1, 2);
	this._nav_ny.ttip = DCalendar._TT["NEXT_YEAR"]

	row = DCalendar.createElement("tr", thead);
	row.className = "daynames";
	if (this.weekNumbers) {
		cell = DCalendar.createElement("td", row);
		cell.className = "name wn";
		cell.appendChild(document.createTextNode(DCalendar._TT["WK"]));
	}
	for (var i = 7; i > 0; --i) {
		cell = DCalendar.createElement("td", row);
		cell.appendChild(document.createTextNode(""));
		if (!i) {
			cell.navtype = 100;
			cell.dcalendar = this;
			DCalendar._add_evs(cell);
		}
	}
	this.firstdayname = (this.weekNumbers) ? row.firstChild.nextSibling : row.firstChild;
	this._displayWeekdays();

	var tbody = DCalendar.createElement("tbody", table);
	this.tbody = tbody;

	for (i = 6; i > 0; --i) {
		row = DCalendar.createElement("tr", tbody);
		if (this.weekNumbers) {
			cell = DCalendar.createElement("td", row);
			cell.appendChild(document.createTextNode(""));
		}
		for (var j = 7; j > 0; --j) {
			cell = DCalendar.createElement("td", row);
			cell.appendChild(document.createTextNode(""));
			cell.dcalendar = this;
			DCalendar._add_evs(cell);
		}
	}

	var tfoot = DCalendar.createElement("tfoot", table);

	row = DCalendar.createElement("tr", tfoot);
	row.className = "footrow";

	cell = hh(DCalendar._TT["SEL_DATE"], this.weekNumbers ? 8 : 7, 300);
	cell.className = "ttip";
	if (this.isPopup) {
		cell.ttip = DCalendar._TT["DRAG_TO_MOVE"];
		cell.style.cursor = "move";
	}
	this.tooltips = cell;

	div = DCalendar.createElement("div", this.element);
	this.monthsCombo = div;
	div.className = "dcombo";
	for (i = 0; i < Date._MN.length; ++i) {
		var mn = DCalendar.createElement("div");
		mn.className = "label";
		mn.month = i;
		mn.appendChild(document.createTextNode(Date._MN3[i]));
		div.appendChild(mn);
	}

	div = DCalendar.createElement("div", this.element);
	this.yearsCombo = div;
	div.className = "dcombo";
	for (i = 12; i > 0; --i) {
		var yr = DCalendar.createElement("div");
		yr.className = "label";
		yr.appendChild(document.createTextNode(""));
		div.appendChild(yr);
	}

	this._init(this.mondayFirst, this.date);
	parent.appendChild(this.element);
};

DCalendar.prototype._init = function (mondayFirst, date)
{
	var today = new Date();
	var year = date.getFullYear();
	if (year < this.minYear) {
		year = this.minYear;
		date.setFullYear(year);
	} else if (year > this.maxYear) {
		year = this.maxYear;
		date.setFullYear(year);
	}
	this.mondayFirst = mondayFirst;
	this.date = new Date(date);
	var month = date.getMonth();
	var mday = date.getDate();
	var no_days = date.getMonthDays();
	date.setDate(1);
	var wday = date.getDay();
	var MON = mondayFirst ? 1 : 0;
	var SAT = mondayFirst ? 5 : 6;
	var SUN = mondayFirst ? 6 : 0;
	if (mondayFirst) {
		wday = (wday > 0) ? (wday - 1) : 6;
	}
	var iday = 1;
	var row = this.tbody.firstChild;
	var MN = Date._MN3[month];
	var hasToday = ((today.getFullYear() == year) && (today.getMonth() == month));
	var todayDate = today.getDate();
	var week_number = date.getWeekNumber();
	var ar_days = new Array();
	for (var i = 0; i < 6; ++i) {
		if (iday > no_days) {
			row.className = "emptyrow";
			row = row.nextSibling;
			continue;
		}
		var cell = row.firstChild;
		if (this.weekNumbers) {
			cell.className = "day wn";
			cell.firstChild.data = week_number;
			cell = cell.nextSibling;
		}
		++week_number;
		row.className = "daysrow";
		for (var j = 0; j < 7; ++j) {
			cell.className = "day";
			if ((!i && j < wday) || iday > no_days) {
				cell.innerHTML = "&nbsp;";
				cell.disabled = true;
				cell = cell.nextSibling;
				continue;
			}
			cell.disabled = false;
			cell.firstChild.data = iday;
			if (typeof this.checkDisabled == "function") {
				date.setDate(iday);
				if (this.checkDisabled(date)) {
					cell.className += " disabled";
					cell.disabled = true;
				}
			}
			if (!cell.disabled) {
				ar_days[ar_days.length] = cell;
				cell.caldate = iday;
				cell.ttip = "_";
				if (iday == mday) {
					cell.className += " selected";
					this.currentDateEl = cell;
				}
				if (hasToday && (iday == todayDate)) {
					cell.className += " today";
					cell.ttip += DCalendar._TT["PART_TODAY"];
				}
				if (wday == SAT || wday == SUN) {
					cell.className += " weekend";
				}
			}
			++iday;
			((++wday) ^ 7) || (wday = 0);
			cell = cell.nextSibling;
		}
		row = row.nextSibling;
	}
	this.ar_days = ar_days;
	this.title.firstChild.data = Date._MN[month] + ", " + year;
};

DCalendar.prototype.setDate = function (date)
{
	if (!date.equalsTo(this.date)) {
		this._init(this.mondayFirst, date);
	}
};

DCalendar.prototype.setMondayFirst = function (mondayFirst)
{
	this._init(mondayFirst, this.date);
	this._displayWeekdays();
};

DCalendar.prototype.setDisabledHandler = function (unaryFunction)
{
	this.checkDisabled = unaryFunction;
};

DCalendar.prototype.setRange = function (a, z)
{
	this.minYear = a;
	this.maxYear = z;
};

DCalendar.prototype.callHandler = function ()
{
	if (this.onSelected) {
            this.onSelected(this, this.date, this.date.print(this.dateFormat));
	} else {
            this.obj.value = this.date.print(this.dateFormat);
            this.callCloseHandler();
        }
};

DCalendar.prototype.callCloseHandler = function ()
{
	if (this.onClose) {
		this.onClose(this);
	} else {
                this.hide();
        }
	this.hideShowCovered();
};

DCalendar.prototype.destroy = function ()
{
	var el = this.element.parentNode;
	el.removeChild(this.element);
	DCalendar._C = null;
	delete el;
};

DCalendar.prototype.reparent = function (new_parent)
{
	var el = this.element;
	el.parentNode.removeChild(el);
	new_parent.appendChild(el);
};

DCalendar.prototype.globalCaptureEvents = function ()
{
	if (this.isPopup) {
		window.dcalendar = this;
		DCalendar.addEvent(document, "keydown", DCalendar._keyEvent);
		DCalendar.addEvent(document, "keypress", DCalendar._keyEvent);
		DCalendar.addEvent(document, "mousedown", DCalendar._checkCalendar);
	}
};

DCalendar.prototype.globalClearEvents = function ()
{
	if (this.isPopup) {
		DCalendar.removeEvent(document, "keydown", DCalendar._keyEvent);
		DCalendar.removeEvent(document, "keypress", DCalendar._keyEvent);
		DCalendar.removeEvent(document, "mousedown", DCalendar._checkCalendar);
	}
}

DCalendar.prototype.show = function ()
{
	var rows = this.table.getElementsByTagName("tr");
	for (var i = rows.length; i > 0;) {
		var row = rows[--i];
		varClassDel(row, "rowhilite");
		var cells = row.getElementsByTagName("td");
		for (var j = cells.length; j > 0;) {
			var cell = cells[--j];
			varClassDel(cell, "hilite");
			varClassDel(cell, "active");
		}
	}
	this.element.style.display = "block";
        this.element.style.zIndex = 9000;
	this.hidden = false;
	this.hideShowCovered();
        this.globalCaptureEvents();
}

DCalendar.prototype.hide = function ()
{
        this.globalClearEvents();
	this.element.style.display = "none";
	this.hidden = true;
	this.hideShowCovered();
};

DCalendar.prototype.showAt = function (x, y)
{
	var s = this.element.style;
	s.left = x + "px";
	s.top = y + "px";
	this.show();
};

DCalendar.prototype.showAtElement = function (el)
{
	var p = varPos(el);
	this.showAt(p.x, p.y);
};

DCalendar.prototype.showUnderElement = function (el)
{
	var p = varPos(el);
        if (!el.value) p.x -= 100;
	this.showAt(p.x, p.y + el.offsetHeight + 5);
};

DCalendar.prototype.setDateFormat = function (str)
{
        if (str) {
   	    this.dateFormat = str;
        }
};

DCalendar.prototype.setTtDateFormat = function (str)
{
        if (str) {
            this.ttDateFormat = str;
        }
};

DCalendar.prototype.parseDate = function (str, fmt)
{
	var y = 0;
	var m = -1;
	var d = 0;
	var a = str.split(/\W+/);
	if (!fmt) {
		fmt = this.dateFormat;
	}
	var b = fmt.split(/\W+/);
	var i = 0, j = 0;
	for (i = 0; i < a.length; ++i) {
		if (b[i] == "D" || b[i] == "DD") {
			continue;
		}
		if (b[i] == "d" || b[i] == "dd") {
			d = parseInt(a[i], 10);
		}
		if (b[i] == "m" || b[i] == "mm") {
			m = parseInt(a[i], 10) - 1;
		}
		if (b[i] == "y") {
			y = parseInt(a[i], 10);
		}
		if (b[i] == "yy") {
			y = parseInt(a[i], 10) + 1900;
		}
		if (b[i] == "M" || b[i] == "MM") {
			for (j = 0; j < 12; ++j) {
				if (Date._MN[j].substr(0, a[i].length).toLowerCase() == a[i].toLowerCase()) { m = j; break; }
			}
		}
	}
	if (y != 0 && m != -1 && d != 0) {
		this.setDate(new Date(y, m, d));
		return;
	}
	y = 0; m = -1; d = 0;
	for (i = 0; i < a.length; ++i) {
		if (a[i].search(/[a-zA-Z]+/) != -1) {
			var t = -1;
			for (j = 0; j < 12; ++j) {
				if (Date._MN[j].substr(0, a[i].length).toLowerCase() == a[i].toLowerCase()) { t = j; break; }
			}
			if (t != -1) {
				if (m != -1) {
					d = m+1;
				}
				m = t;
			}
		} else if (parseInt(a[i], 10) <= 12 && m == -1) {
			m = a[i]-1;
		} else if (parseInt(a[i], 10) > 31 && y == 0) {
			y = a[i];
		} else if (d == 0) {
			d = a[i];
		}
	}
	if (y == 0) {
		var today = new Date();
		y = today.getFullYear();
	}
	if (m != -1 && d != 0) {
		this.setDate(new Date(y, m, d));
	}
};

DCalendar.prototype.hideShowCovered = function ()
{
	var tags = new Array("applet", "iframe", "select");
	var el = this.element;

	var p = varPos(el);
	var EX1 = p.x;
	var EX2 = el.offsetWidth + EX1;
	var EY1 = p.y;
	var EY2 = el.offsetHeight + EY1;
	for (var k = tags.length; k > 0; ) {
		var ar = document.getElementsByTagName(tags[--k]);
		var cc = null;
		for (var i = ar.length; i > 0;) {
			cc = ar[--i];
			p = varPos(cc);
			var CX1 = p.x;
			var CX2 = cc.offsetWidth + CX1;
			var CY1 = p.y;
			var CY2 = cc.offsetHeight + CY1;
			if (this.hidden || (CX1 > EX2) || (CX2 < EX1) || (CY1 > EY2) || (CY2 < EY1)) {
                            if (cc.dcalendar_hide) {
				cc.style.visibility = "visible";
                                cc.dcalendar_hide = 0;
                            }
			} else {
                            if (cc.style.visibility != "hidden") {
				cc.style.visibility = "hidden";
                                cc.dcalendar_hide = 1;
                            }
			}
		}
	}
};

DCalendar.prototype._displayWeekdays = function ()
{
	var MON = this.mondayFirst ? 0 : 1;
	var SUN = this.mondayFirst ? 6 : 0;
	var SAT = this.mondayFirst ? 5 : 6;
	var cell = this.firstdayname;
	for (var i = 0; i < 7; ++i) {
		cell.className = "day name";
		if (!i) {
			cell.ttip = this.mondayFirst ? DCalendar._TT["SUN_FIRST"] : DCalendar._TT["MON_FIRST"];
			cell.navtype = 100;
			cell.dcalendar = this;
			DCalendar._add_evs(cell);
		}
		if (i == SUN || i == SAT) {
			varClassAdd(cell, "weekend");
		}
		cell.firstChild.data = Date._DN3[i + 1 - MON];
		cell = cell.nextSibling;
	}
};

DCalendar.prototype._hideCombos = function ()
{
	this.monthsCombo.style.display = "none";
	this.yearsCombo.style.display = "none";
};

DCalendar.prototype._dragStart = function (ev)
{
	if (this.dragging) {
		return;
	}
	this.dragging = true;
	var posX;
	var posY;
	if (DCalendar.is_ie) {
		posY = window.event.clientY + document.body.scrollTop;
		posX = window.event.clientX + document.body.scrollLeft;
	} else {
		posY = ev.clientY + window.scrollY;
		posX = ev.clientX + window.scrollX;
	}
	var st = this.element.style;
	this.xOffs = posX - parseInt(st.left);
	this.yOffs = posY - parseInt(st.top);
	with (DCalendar) {
		addEvent(document, "mousemove", calDragIt);
		addEvent(document, "mouseover", stopEvent);
		addEvent(document, "mouseup", calDragEnd);
	}
};

DCalendar.prototype.getForm = function()
{
        return this.form;
}

DCalendar.prototype.getObj = function()
{
        return this.obj;
}

DCalendar.prototype.getObjName = function()
{
        return this.objname;
}

DCalendar._C = null;
DCalendar._TT = {};
DCalendar.is_ie = (navigator.userAgent.toLowerCase().indexOf("msie") != -1 && navigator.userAgent.toLowerCase().indexOf("opera") == -1);
DCalendar._TT["TOGGLE"] = "Toggle first day of week";
DCalendar._TT["PREV_YEAR"] = "Prev. year (hold for menu)";
DCalendar._TT["PREV_MONTH"] = "Prev. month (hold for menu)";
DCalendar._TT["GO_TODAY"] = "Go Today";
DCalendar._TT["NEXT_MONTH"] = "Next month (hold for menu)";
DCalendar._TT["NEXT_YEAR"] = "Next year (hold for menu)";
DCalendar._TT["SEL_DATE"] = "Select date";
DCalendar._TT["DRAG_TO_MOVE"] = "Drag to move";
DCalendar._TT["PART_TODAY"] = " (today)";
DCalendar._TT["MON_FIRST"] = "Display Monday first";
DCalendar._TT["SUN_FIRST"] = "Display Sunday first";
DCalendar._TT["CLOSE"] = "Close";
DCalendar._TT["TODAY"] = "Today";
DCalendar._TT["DEF_DATE_FORMAT"] = "mm/dd/y";
DCalendar._TT["TT_DATE_FORMAT"] = "D, M d";
DCalendar._TT["WK"] = "wk";

function dCalendarShow(form, id, format, selectproc, closeproc, x, y, data)
{
  if (dcalendar != null) {
    dcalendar.hide();
  } else {
    dcalendar = new DCalendar(null, selectproc, closeproc);
    dcalendar.create();
  }
  if (format) dcalendar.setDateFormat(format);
  obj = formObj(form,id);
  if (!obj) obj = $(id);
  dcalendar.form = form;
  dcalendar.obj = obj;
  dcalendar.objname = id;
  dcalendar.data = data;
  if (obj) {
    if (obj.value) {
      dcalendar.parseDate(obj.value);
      dcalendar.showUnderElement(obj);
    } else {
      dcalendar.showAtElement(obj);
    }
  } else {
    if (x && y) dcalendar.showAt(x, y);
  }
  return false;
}

window.document.open();
window.document.writeln("<STYLE TYPE=TEXT/CSS>");
window.document.writeln(".dcalendar {position:relative;display:none;border-top:2px solid #fff;border-right:2px solid #000;border-bottom:2px solid #000;border-left:2px solid #fff;font-size:11px;color:#000;cursor:default;background:#d4d0c8;font-family:tahoma,verdana,sans-serif;}");
window.document.writeln(".dcalendar table {border-top:1px solid #000;border-right:1px solid #fff;border-bottom:1px solid #fff;border-left:1px solid #000;font-size:11px;color:#000;cursor:default;background:#d4d0c8;font-family:tahoma,verdana,sans-serif;}");
window.document.writeln(".dcalendar .button {text-align:center;padding:1px;border-top:1px solid #fff;border-right:1px solid #000;border-bottom:1px solid #000;border-left:1px solid #fff;}");
window.document.writeln(".dcalendar thead .title {font-weight:bold;padding:1px;border:1px solid #000;background:#848078;color:#fff;text-align:center;}");
window.document.writeln(".dcalendar thead .headrow {}");
window.document.writeln(".dcalendar thead .daynames {}");
window.document.writeln(".dcalendar thead .name {border-bottom:1px solid #000;padding:2px;text-align:center;background:#f4f0e8;}");
window.document.writeln(".dcalendar thead .weekend {color:#f00;}");
window.document.writeln(".dcalendar thead .hilite {border-top:2px solid #fff;border-right:2px solid #000;border-bottom:2px solid #000;border-left:2px solid #fff;padding:0px;background:#e4e0d8;}");
window.document.writeln(".dcalendar thead .active {padding:2px 0px 0px 2px;border-top:1px solid #000;border-right:1px solid #fff;border-bottom:1px solid #fff;border-left:1px solid #000;background:#c4c0b8;}");
window.document.writeln(".dcalendar tbody .day {width:2em;text-align:right;padding:2px 4px 2px 2px;}");
window.document.writeln(".dcalendar table .wn {padding:2px 3px 2px 2px;border-right:1px solid #000;background:#f4f0e8;}");
window.document.writeln(".dcalendar tbody .rowhilite td {background:#e4e0d8;}");
window.document.writeln(".dcalendar tbody .rowhilite td.wn {background:#d4d0c8;}");
window.document.writeln(".dcalendar tbody td.hilite {padding:1px 3px 1px 1px;border-top:1px solid #fff;border-right:1px solid #000;border-bottom:1px solid #000;border-left:1px solid #fff;}");
window.document.writeln(".dcalendar tbody td.active {padding:2px 2px 0px 2px;border-top:1px solid #000;border-right:1px solid #fff;border-bottom:1px solid #fff;border-left:1px solid #000;}");
window.document.writeln(".dcalendar tbody td.selected {font-weight:bold;border-top:1px solid #000;border-right:1px solid #fff;border-bottom:1px solid #fff;border-left:1px solid #000;padding:2px 2px 0px 2px;background:#e4e0d8;}");
window.document.writeln(".dcalendar tbody td.weekend {color:#f00;}");
window.document.writeln(".dcalendar tbody td.today {font-weight:bold;color:#00f;}");
window.document.writeln(".dcalendar tbody .disabled { color:#999;}");
window.document.writeln(".dcalendar tbody .emptycell {visibility:hidden;}");
window.document.writeln(".dcalendar tbody .emptyrow {display:none;}");
window.document.writeln(".dcalendar tfoot .footrow {}");
window.document.writeln(".dcalendar tfoot .ttip {background:#f4f0e8;padding:1px;border:1px solid #000;background:#848078;color:#fff;text-align:center;}");
window.document.writeln(".dcalendar tfoot .hilite {border-top:1px solid #fff;border-right:1px solid #000;border-bottom:1px solid #000;border-left:1px solid #fff;padding:1px;background:#e4e0d8;}");
window.document.writeln(".dcalendar tfoot .active {padding:2px 0px 0px 2px;border-top:1px solid #000;border-right:1px solid #fff;border-bottom:1px solid #fff;border-left:1px solid #000;}");
window.document.writeln(".dcombo {position:absolute;display:none;width:4em;top:0px;left:0px;cursor:default;border-top:1px solid #fff;border-right:1px solid #000;border-bottom:1px solid #000;border-left:1px solid #fff;background:#e4e0d8;font-size:smaller;padding:1px;}");
window.document.writeln(".dcombo .active {background:#c4c0b8;padding:0px;border-top:1px solid #000;border-right:1px solid #fff;border-bottom:1px solid #fff;border-left:1px solid #000;}");
window.document.writeln(".dcombo .hilite {background:#048;color:#fea;}");
window.document.writeln(".dcombo .label {text-align:center;padding:1px;}");
window.document.writeln("</STYLE>");
window.document.close();
