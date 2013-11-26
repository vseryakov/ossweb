//  Author Vlad Seryakov vlad@crystalballinc.com
//  May 2006
//  $Id: resizable.js 2569 2006-12-21 00:03:03Z vlad $
//  Based on textarea.js from Drupal.org

function varResizable(obj,options)
{
  if (typeof obj == 'undefined') {
    // Attach to all visible textareas.
    var objs = document.getElementsByTagName('textarea');
  } else {
    var objs = new Array();
    objs[0] = $(obj);
  }
  for (var i = 0; obj = objs[i]; ++i) {
    if (obj.offsetWidth) new Resizable(obj,options);
  }
}

function Resizable(element, options)
{
  var ta = this;
  this.element = element;
  this.resize_width = options && options.indexOf('width=0') > -1 ? 0 : 1;
  this.resize_height = options && options.indexOf('height=0') > -1 ? 0 : 1;
  this.parent = this.element.parentNode;
  this.dimensions = varSize(element);

  // Prepare wrapper
  this.wrapper = document.createElement('div');
  this.wrapper.className = 'osswebContent';
  this.parent.insertBefore(this.wrapper, this.element);

  // Add grippie and measure it
  this.grippie = document.createElement('div');
  this.grippie.className = 'osswebGrippie';
  if (!this.resize_width) this.grippie.style.cursor = 's-resize';
  if (!this.resize_height) this.grippie.style.cursor = 'e-resize';
  this.wrapper.appendChild(this.grippie);
  this.grippie.dimensions = varSize(this.grippie);
  this.grippie.onmousedown = function (e) { ta.beginDrag(e); };

  // Set wrapper and textarea dimensions
  this.wrapper.style.width = this.dimensions.width;
  this.wrapper.style.height = this.dimensions.height + this.grippie.dimensions.height + 1 +'px';
  this.element.style.marginBottom = '0px';
  this.element.style.height = this.dimensions.height +'px';

  // Wrap textarea
  if (this.element.parentNode) this.element.parentNode.removeChild(this.element);
  this.wrapper.insertBefore(this.element, this.grippie);

  // Measure difference between desired and actual textarea dimensions to account for padding/borders
  this.widthOffset = varSize(this.wrapper).width - this.dimensions.width;

  // Make the grippie line up in various browsers
  if (window.opera) {
    // Opera
    this.grippie.style.marginRight = '4px';
  }
  if (document.all && !window.opera) {
    // IE
    this.grippie.style.paddingLeft = '2px';
  }
  // Mozilla
  this.element.style.MozBoxSizing = 'border-box';
  this.heightOffset = varPos(this.grippie).y - varPos(this.element).y - this.dimensions.height;
  this.widthOffset = varPos(this.grippie).x - varPos(this.element).x - this.dimensions.width;
}

Resizable.prototype.beginDrag = function (event)
{
  var cp = this;
  if (document.isDragging) return;
  document.isDragging = true;
  event = event || window.event;
  this.oldMoveHandler = document.onmousemove;
  document.onmousemove = function(e) { cp.handleDrag(e); };
  this.oldUpHandler = document.onmouseup;
  document.onmouseup = function(e) { cp.endDrag(e); };
  // Store drag offset from grippie top
  var pos = varPos(this.grippie);
  this.dragYOffset = event.clientY - pos.y;
  this.dragXOffset = event.clientX - pos.x;
  // Make transparent
  this.element.style.opacity = 0.5;
  this.handleDrag(event);
}

Resizable.prototype.handleDrag = function (event)
{
  event = event || window.event;
  // Get coordinates relative to text area
  var pos = varPos(this.element);
  var y = event.clientY - pos.y;
  var x = event.clientX - pos.x;
  // Set new dimensions
  if (this.resize_height) {
    var height = Math.max(32, y - this.dragYOffset - this.heightOffset);
    this.wrapper.style.height = height + this.grippie.dimensions.height + 1 + 'px';
    this.element.style.height = height + 'px';
  }
  if (this.resize_width) {
    var width = Math.max(32, x - this.dragXOffset - this.widthOffset);
    this.wrapper.style.width = width + 'px';
    this.element.style.width = width + 'px';
  }
  // Avoid text selection
  event.cancelBubble = true;
}

Resizable.prototype.endDrag = function (event)
{
  // Uncapture mouse
  document.onmousemove = this.oldMoveHandler;
  document.onmouseup = this.oldUpHandler;
  // Restore opacity
  this.element.style.opacity = 1.0;
  document.isDragging = false;
}

