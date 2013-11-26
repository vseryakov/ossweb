/**************************************************************************
   Copyright (c) 2001 Geir Landrö (
   JavaScript Tree - www.destroydrop.com/hugi/javascript/tree/
   Version 0.96

   This script can be used freely as long as all copyright messages are intact.

   January 2002
   Vlad Seryakov vlad@crystalballinc.com
   Modified to use Array instead of string items

   March 2002
   Darren Ferguson darren@crystalballinc.com
   Modified to use string seperated by , to allow more than one node to be set open

   Example:

   <script language=javascript>
     var Tree = new Array;
     // nodeId, parentNodeId, nodeName, nodeUrl, urlParams, urlData
     Tree[0]  = new Array(1,0,'Page 1','');
     Tree[1]  = new Array(2,0,'Page 1','');
     Tree[2]  = new Array(3,1,'Page 1.1','');
     Tree[3]  = new Array(4,1,'Page 1.2','/page2','CLASS=page');
     Tree[4]  = new Array(5,1,'Page 1.3','/page3','CLASS=page','/img/trash.gif');
     Tree[5]  = new Array(6,1,'Page 1.4','/page3','CLASS=page','/img/trash.gif',' [info]');
   </script>

   <script language=javascript>
     createTree(Tree);
   </script>

**************************************************************************/

// Arrays for nodes and icons
var treeNodes  	= new Array();
var treeOpen	= new Array();
var treeIcons   = new Array(6);

// Loads all icons that are used in the tree
function preloadIcons()
{
   treeIcons[0] = new Image();
   treeIcons[0].src = "/img/tree/plus.gif";
   treeIcons[1] = new Image();
   treeIcons[1].src = "/img/tree/plusbottom.gif";
   treeIcons[2] = new Image();
   treeIcons[2].src = "/img/tree/minus.gif";
   treeIcons[3] = new Image();
   treeIcons[3].src = "/img/tree/minusbottom.gif";
   treeIcons[4] = new Image();
   treeIcons[4].src = "/img/tree/folder.gif";
   treeIcons[5] = new Image();
   treeIcons[5].src = "/img/tree/folderopen.gif";
}
// Create the tree
function createTree(arrName, startNode, openNodes, rootName, divName)
{
   treeNodes = arrName;
   if (treeNodes.length > 0) {
     preloadIcons();
     document.write("<div id=" + (divName ? divName : "tree") + ">");
     if (startNode == null) {
       startNode = 0;
     }
     openNode(openNodes);
     if (startNode > 0) {
       var root = treeNodes[getArrayId(startNode)];
       document.write("<img src=/img/tree/folderopen.gif align=absbottom border=0/>" + root[2] + "<br />");
     } else {
       document.write("<img src=/img/tree/base.gif align=absbottom border=0/> " + (rootName ? rootName : "Root") + "<br />");
     }
     var recursedNodes = new Array();
     addNode(startNode, recursedNodes);
     document.write('</div>');
   }
}
// Returns the position of a node in the array
function getArrayId(node)
{
   for (var i = 0; i < treeNodes.length; i++) {
     if (treeNodes[i][0] == node) {
       return i;
     }
   }
   return null;
}
// Puts in array nodes that will be open
function openNode(node)
{
   if(node == "all") {
     for (var i = 0; i < treeNodes.length; i++) {
       treeOpen.push(treeNodes[i][0]);
     }
     return;
   }
   // Open individual nodes
   if (typeof node == "string") {
     nodes = node.split(",");
     for (var i = 0; i < nodes.length; i++) {
       treeOpen.push(parseInt(nodes[i]));
     }
   } else {
     treeOpen.push(node);
   }
}
// Clears open node
function closeNode(node)
{
   var arr = new Array();
   for (var i = 0; i < treeOpen.length; i++) {
     if (treeOpen[i] != node) {
       arr[arr.length] = treeOpen[i];
     }
   }
   treeOpen = arr;
}

// Checks if a node is open
function isNodeOpen(node)
{
   for (var i = 0; i < treeOpen.length; i++) {
     if (treeOpen[i] == node) {
       return 1;
     }
   }
   return 0;
}
// Checks if a node has any children
function hasChildNode(parentNode)
{
   for (var i = 0; i < treeNodes.length; i++) {
      if (treeNodes[i][1] == parentNode) {
        return 1;
      }
   }
   return 0;
}
// Checks if a node is the last sibling
function lastSibling(node, parentNode)
{
   var lastChild = 0;
   for (i = 0; i < treeNodes.length; i++) {
      if (treeNodes[i][1] == parentNode) {
        lastChild = treeNodes[i][0];
      }
   }
   return lastChild == node ? 1 : 0;
}
// Adds a new node in the tree
function addNode(parentNode, recursedNodes)
{
   for (var i = 0; i < treeNodes.length; i++) {
      var Item = treeNodes[i];
      if (Item[1] != parentNode) {
        continue;
      }
      var ls = lastSibling(Item[0], Item[1]);
      var hcn = hasChildNode(Item[0]);
      var ino = isNodeOpen(Item[0]);

      // Write out line & empty icons
      for (g = 0; g < recursedNodes.length; g++) {
        document.write("<img src=/img/tree/" + (recursedNodes[g] == 1 ? "empty" : "line") + ".gif align=absbottom border=0/>");
      }

      // put in array line & empty icons
      recursedNodes.push(ls);

      // Write out join icons
      if (hcn) {
        document.write("<a href=\"javascript: oc("+Item[0]+", " + ls + ");\">");
        document.write("<img id=join"+Item[0]+" src=/img/tree/" + (ino ? "minus" : "plus") + (ls ? "bottom" : "") + ".gif align=absbottom border=0/></a>");
      } else {
        document.write("<img src=/img/tree/join" + (ls ? "" : "bottom") + ".gif align=absbottom border=0/>");
      }

      // Start link
      if (Item[3] != '') {
        document.write("<a href=\""+Item[3]+"\" " + (Item[4] != null ? Item[4] : "") + ">");
      }
      // Write out folder & page icons
      if (hcn) {
        document.write("<img id=icon"+Item[0]+" src=/img/tree/folder" + (ino ? "open" : "") + ".gif align=absbottom border=0/>");
      } else {
        document.write("<img id=icon"+Item[0]+" src=" + (Item[5] != null && Item[5] != '' ? Item[5] : "/img/tree/page.gif") + " align=absbottom border=0/>");
      }
      // Write out node name
      document.write(" " + Item[2] + " ");

      // End link
      document.write("</a>");

      // Additional text
      if (Item[6] != null) {
        document.write(Item[6]);
      }

      // End line
      document.write("<br/>");

      // If node has children write out divs and go deeper
      if (hcn) {
        document.write("<div id=div" + Item[0] + (!ino ? " style=\"display: none;\"" : "") + ">");
        addNode(Item[0], recursedNodes);
        document.write("</div>");
      }

      // remove last line or empty icon
      recursedNodes.pop();
   }
}
// Opens or closes a node
function oc(node, bottom)
{
   var div = document.getElementById("div"+node);
   if (div) {
     var join = document.getElementById("join"+node);
     var icon = document.getElementById("icon"+node);
     if (div.style.display == 'none') {
       join.src = treeIcons[bottom+2].src;
       icon.src = treeIcons[5].src;
       div.style.display = '';
       treeOpen.push(node);
     } else {
       join.src = treeIcons[bottom].src;
       icon.src = treeIcons[4].src;
       div.style.display = 'none';
       closeNode(node);
     }
   }
}

// Push and pop not implemented
if(!Array.prototype.push)
{
   Array.prototype.push = function () {
     for(var i = 0; i < arguments.length; i++) this[this.length] = arguments[i];
     return this.length;
   }
}

if(!Array.prototype.pop)
{
   Array.prototype.pop = function () {
     lastElement = this[this.length - 1];
     this.length = Math.max(this.length - 1,0);
     return lastElement;
   }
}
