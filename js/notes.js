//  Author Vlad Seryakov vlad@crystalballinc.com
//  February 2007
//  $Id: ossweb.js 2927 2007-01-31 00:07:29Z vlad $

function noteToggleAll(obj,opts)
{
  opts = noteDefaults(opts);
  var notes = document.getElementsByTagName('DIV');
  for (var i = 0; notes[i]; ++i) {
    if(!notes[i].id.match(opts.match)) continue;
    if(obj.noteToggle) noteExpand(notes[i]); else noteCollapse(notes[i]);
  }
  obj.noteToggle = 1 - (obj.noteToggle ? obj.noteToggle : 0);
  if(obj.tagName == 'IMG') obj.src = obj.noteToggle ? opts.imgopen : opts.imgclose;
  if(obj.tagName == 'INPUT') obj.value = obj.noteToggle ? 'Expand All' : 'Collapse All';
}

function noteToggle(obj,opts)
{
  opts = noteDefaults(opts);
  if(!noteExpand(obj,opts)) noteCollapse(obj,opts);
}

// Set default values to  expand/collapse options
function noteDefaults(opts)
{
  if(!opts) opts = {};
  if(!opts.name) opts.name = 't';
  if(!opts.img) opts.img = 'i';
  if(!opts.match) opts.match = new RegExp('^'+opts.name+'[0-9]+$');;
  if(!opts.size) opts.size = 80;
  if(!opts.imgopen) opts.imgopen = '/img/plus.gif';
  if(!opts.imgclose) opts.imgclose = '/img/minus.gif';
  return opts;
}

// Expand one note if it is collapsed
function noteExpand(obj,opts)
{
  if(!(obj = $(obj)) || !obj.noteText) return 0;
  opts = noteDefaults(opts);
  varSet(obj,obj.noteText);
  obj.noteText = 0;
  var img = $(opts.img+obj.id);
  if(img) img.src = opts.imgclose;
  if(opts.onexpand) try { opts.onexpand(obj,opts) } catch(e) {}
  return 1;
}

// Collapse one note if big enough
function noteCollapse(obj,opts)
{
  if(!(obj = $(obj)) || obj.noteText) return 0;
  opts = noteDefaults(opts);
  obj.noteText = varGet(obj);
  var text = '';
  if(!opts.empty) text = strStripHtml(obj.noteText).substring(0,opts.size)+'...';
  varSet(obj,text);
  var img = $(opts.img +obj.id);
  if(img) img.src = opts.imgopen;
  if(opts.oncollapse) try { opts.oncollapse(obj,opts) } catch(e) {}
  return 1;
}
