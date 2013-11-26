//  Author Vlad Seryakov vlad@crystalballinc.com
//  May 2006
//  $Id: ac.js 2873 2007-01-27 23:18:38Z vlad $
//  Based on autocomplete.js from Drupal.org

var acCache = new Array();

// Callback is function with 3 args func(input,label,value)
function varAutoComplete(obj, uri, callback)
{
  if ((obj = $(obj)) && !obj.acObj) {
    if (!acCache[uri]) acCache[uri] = new jsACDB(uri);
    // Prevents the form from submitting if the suggestions popup is open
    varListen(obj.form, 'submit', function() {var ac=$('osswebAutocomplete');if(ac){ac.acOwner.hidePopup();return false;}return true;});
    obj.acObj = new jsAC(obj, acCache[uri], callback);
  }
}

// An AutoComplete object
function jsAC(input, db, callback)
{
  var ac = this;
  this.db = db;
  this.input = input;
  this.callback = callback;
  if(!this.oldKeyDown) this.oldKeyDown = input.onkeydown;
  input.onkeydown = function (e) { if(this.oldKeyDown)this.oldKeyDown(e); return ac.onkeydown(this, e); };
  if(!this.oldKeyUp) this.oldKeyup = input.onkeyup;
  input.onkeyup = function (e) { if(this.oldKeyUp)this.oldKeyUp(e); return ac.onkeyup(this, e); };
  if(!this.oldBlur) this.oldBlur = this.input.onblur;
  input.onblur = function (e) { if(this.oldBlur)this.oldBlur(e); ac.hidePopup(); ac.db.cancel(); };
  this.popup = document.createElement('div');
  this.popup.id = 'osswebAutocomplete';
  this.popup.className = 'osswebAutocomplete';
  this.popup.acOwner = this;
};

// Puts the currently highlighted suggestion into the autocomplete field
jsAC.prototype.select = function (node)
{
  if (this.callback) this.callback(this.input, node.acObj);
  // Value did not change, assign label to it
  if (this.oldvalue == this.input.value) {
    this.input.value = node.acObj.name;
    this.oldvalue = null;
  }
  // Call onAutocomplete callback
  if (this.input.onAutocomplete) this.input.onAutocomplete(this.input);
}

// Highlights the next suggestion
jsAC.prototype.selectDown = function ()
{
  if (this.selected && this.selected.nextSibling) {
    this.highlight(this.selected.nextSibling);
  } else {
    var lis = this.popup.getElementsByTagName('li');
    if (lis.length > 0) this.highlight(lis[0]);
  }
}

// Highlights the previous suggestion
jsAC.prototype.selectUp = function ()
{
  if (this.selected && this.selected.previousSibling) {
    this.highlight(this.selected.previousSibling);
  }
}

// Highlights a suggestion
jsAC.prototype.highlight = function (node)
{
  varClassDel(this.selected, 'selected');
  varClassAdd(node, 'selected');
  this.selected = node;
}

// Unhighlights a suggestion
jsAC.prototype.unhighlight = function (node)
{
  varClassDel(node, 'selected');
  this.selected = false;
}

// Hides the autocomplete suggestions
jsAC.prototype.hidePopup = function (keycode)
{
  if (this.selected && (keycode == 13 || !keycode)) {
    this.select(this.selected);
  }
  if (this.popup.parentNode && this.popup.parentNode.tagName) {
     this.popup.parentNode.removeChild(this.popup);
  }
  this.selected = false;
  ddFrameHide(this.popup);
}

// Positions the suggestions popup and starts a search
jsAC.prototype.populatePopup = function ()
{
  var ac = this;
  var pos = varPos(this.input);
  this.oldvalue = this.input.value;
  this.selected = false;
  this.popup.style.top = (pos.y + this.input.offsetHeight) +'px';
  this.popup.style.left = pos.x +'px';
  if(this.narrow) this.popup.style.width = (this.input.offsetWidth - 4) +'px';
  this.db.acOwner = this;
  this.db.search(this.input.value);
}

// Handler for the "keydown" event
jsAC.prototype.onkeydown = function (input, e)
{
  if (!e) e = window.event;
  e.cancelBubble = true;
  switch (e.keyCode) {
    case 40: // down arrow
      this.selectDown();
      return false;
    case 38: // up arrow
      this.selectUp();
      return false;
    case 13: // enter
      return false;
    default: // all other keys
      return true;
  }
}

// Handler for the "keyup" event
jsAC.prototype.onkeyup = function (input, e)
{
  if (!e) e = window.event;
  e.cancelBubble = true;
  switch (e.keyCode) {
    case 16: // shift
    case 17: // ctrl
    case 18: // alt
    case 20: // caps lock
    case 33: // page up
    case 34: // page down
    case 35: // end
    case 36: // home
    case 37: // left arrow
    case 38: // up arrow
    case 39: // right arrow
    case 40: // down arrow
      return true;
    case 9:  // tab
    case 13: // enter
    case 27: // esc
      this.hidePopup(e.keyCode);
      return false;
    default: // all other keys
      if (input.value.length > 0)
        this.populatePopup();
      else
        this.hidePopup(e.keyCode);
      return true;
  }
}

// Fills the suggestion popup with any matches received
jsAC.prototype.found = function (matches)
{
  while (this.popup.hasChildNodes()) {
    this.popup.removeChild(this.popup.childNodes[0]);
  }
  if (!this.popup.parentNode || !this.popup.parentNode.tagName) {
    document.getElementsByTagName('body')[0].appendChild(this.popup);
  }
  var ul = document.createElement('ul');
  var acObj, ac = this;
  for (key in matches) {
    acObj = null;
    if (matches[key] != '') eval('acObj=' + matches[key]);
    if(!acObj || !acObj.name) continue;
    var li = document.createElement('li');
    var div = document.createElement('div');
    li.acObj = acObj;
    div.innerHTML = (acObj.icon ? '<IMG SRC='+acObj.icon+'>'+acObj.name : acObj.name);
    li.appendChild(div);
    li.onmousedown = function() { ac.hidePopup(); };
    li.onmouseover = function() { ac.highlight(this); };
    li.onmouseout  = function() { ac.unhighlight(this); };
    ul.appendChild(li);
  }
  if (ul.childNodes.length > 0) {
    this.popup.appendChild(ul);
    ddFrameShow(this.popup);
  } else {
    this.hidePopup();
  }
  varClassDel(this.input, 'throbbing');
}

// An AutoComplete DataBase object
function jsACDB(uri)
{
  this.uri = uri;
  this.delay = 300;
  this.cache = {};
}

// HTTP callback function. Passes suggestions to the autocomplete object
// Data format(JSON): each line is javascript object, name element is required:
//  name:, value:, icon:
jsACDB.prototype.receive = function(string, opts)
{
  matches = string.split('\n');
  if (matches.length > 0) {
    opts.db.cache[opts.db.searchString] = matches;
    opts.db.acOwner.found(matches);
  }
}

// Performs a cached and delayed search
jsACDB.prototype.search = function(searchString)
{
  this.searchString = searchString;
  if (this.cache[searchString]) {
    return this.acOwner.found(this.cache[searchString]);
  }
  if (this.timer) clearTimeout(this.timer);
  var db = this;
  this.timer = setTimeout(function() {
     varClassAdd(db.acOwner.input, 'throbbing');
     db.transport = pagePopupSend(db.uri + escape(searchString), null, db.receive, {db:db});
  }, this.delay);
}

// Cancels the current autocomplete request
jsACDB.prototype.cancel = function()
{
  if (this.acOwner) varClassDel(this.acOwner.input, 'throbbing');
  if (this.timer) clearTimeout(this.timer);
  if (this.transport) {
    this.transport.onreadystatechange = function() {};
    this.transport.abort();
  }
}

