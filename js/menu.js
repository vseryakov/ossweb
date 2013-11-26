//  Author Vlad Seryakov vlad@crystalballinc.com
//  May 2002
//  $Id: menu.js 2865 2007-01-26 05:58:39Z vlad $

var isDOM = (document.getElementById ? true : false);
var isIE4 = ((document.all && !isDOM) ? true : false);
var popTimer = 0;
var litNow = new Array();
var menu = Array();

function menuHideElement(tag)
{
   if(!isDOM || !document.all) return;
   for(i = 0; i < document.all.tags(tag).length; i++) {
     var obj = document.all.tags(tag)[i];
     if (!obj || !obj.offsetParent) continue;
     obj.style.visibility = "hidden";
     obj.menuHidden = 1;
   }
}

function menuShowElement(tag)
{
   if (!isDOM || !document.all) return;
   for(i = 0; i < document.all.tags(tag).length; i++) {
     var obj = document.all.tags(tag)[i];
     if(!obj || !obj.menuHidden) continue;
     obj.style.visibility = "";
   }
}

function menuOver(menuNum, itemNum)
{
   clearTimeout(popTimer);
   menuHideAll(menuNum);
   litNow = menuGetTree(menuNum, itemNum);
   menuBackground(true);
}

function menuOut(menuNum, itemNum)
{
   if ((menuNum == 0) && !menu[menuNum][itemNum].target)
     menuHideAll(0);
   else
     popTimer = setTimeout('menuHideAll(0)', 500);
}

function menuPopOver(menuNum, itemNum)
{
   clearTimeout(popTimer);
   menuHideAll(menuNum);
   litNow = menuGetTree(menuNum, itemNum);
   menuBackground(true);
   targetNum = menu[menuNum][itemNum].target;
   if(targetNum > 0 && menu[targetNum]) {
     thisX = parseInt(menu[menuNum][0].style.left)+parseInt(menu[menuNum][itemNum].style.left);
     thisY = parseInt(menu[menuNum][0].style.top)+parseInt(menu[menuNum][itemNum].style.top);
     with(menu[targetNum][0].style) {
       left = thisX+menu[targetNum][0].x;
       top = thisY+menu[targetNum][0].y;
       visibility = 'visible';
     }
     menuHideElement("SELECT");
   }
}

function menuPopOut(menuNum, itemNum)
{
   if((menuNum == 0) && !menu[menuNum][itemNum].target)
     menuHideAll(0);
   else
     popTimer = setTimeout('menuHideAll(0)', 500);
}

function menuPopClick(menuNum, itemNum)
{
   with (menu[menuNum][itemNum]) {
     switch (type) {
      case 'js:': { eval(href); break }
      case '': type = 'window';
      default: if (href) eval(type+'.location.href = "'+href+'"');
     }
   }
   menuHideAll(0);
}

function menuGetTree(menuNum, itemNum)
{
   itemArray = new Array(menu.length);
   while(1) {
     itemArray[menuNum] = itemNum;
     if (menuNum == 0) return itemArray;
     itemNum = menu[menuNum][0].parentItem;
     menuNum = menu[menuNum][0].parentMenu;
   }
}

function menuBackground(isOver)
{
   for(count = 0; count < litNow.length; count++) {
     if(litNow[count]) {
       with (menu[count][0]) with (menu[count][litNow[count]]) {
        if(isOver) {
          varClassAdd(div, overClass);
        } else {
          varClassDel(div, overClass);
        }
       }
     }
   }
}

function menuHideAll(menuNum)
{
   var keepMenus = menuGetTree(menuNum, 1);
   for(count = 0; count < menu.length; count++) {
     if(!keepMenus[count] && menu[count]) {
       menu[count][0].style.visibility = 'hidden';
     }
   }
   menuBackground(false);
   if(menuNum == 0) menuShowElement("SELECT");
}

function Menu(isVert, popInd, x, y, width, pad, textClass, overClass, borderClass, showImages, parentID)
{
   this.isVert = isVert;
   this.popInd = popInd;
   this.x = x;
   this.y = y;
   this.width = width;
   this.pad = pad;
   this.textClass = textClass;
   this.overClass = overClass;
   this.borderClass = borderClass;
   this.showImages = showImages;
   this.parentID = parentID;
   this.parentMenu = null;
   this.parentItem = null;
   this.style = null;
   this.div = null;
}

function menuItem(text, href, type, length, spacing, target, image)
{
   this.text = text;
   this.href = href;
   this.type = type;
   this.length = length;
   this.spacing = spacing;
   this.target = target;
   this.image = image;
   this.style = null;
   this.div = null;
}

function menuCreate()
{
   if(!menu.length) return;
   var parent = $(menu[0][0].parentID);
   if(parent) {
     var pos = varPos(parent);
     menu[0][0].x = pos.x;
     menu[0][0].y = pos.y;
   }
   for(currMenu = 0; currMenu < menu.length; currMenu++) {
     if(menu[currMenu])
       with (menu[currMenu][0]) {
         var str = '', itemX = 0, itemY = 0;
         for(currItem = 1; currItem < menu[currMenu].length; currItem++) {
           with (menu[currMenu][currItem]) {
             var itemID = 'menu'+currMenu+'item'+currItem;
             var shrink = (borderClass && isDOM && !document.all ? 2 : 0)
             var w = (isVert ? width : length) - shrink + (showImages ? 16 : 0);
             var h = (isVert ? length : width) - shrink + (showImages ? 2 : 0);
             str += '<div id="'+itemID+'" style="position: absolute; left: '+itemX+'; top: '+itemY+'; width: '+w+'; height: '+h+'; visibility: inherit; ';
             str += '" ';
             if(parent.className) {
               borderClass += ' ' + parent.className;
             }
             if(borderClass) {
               str += 'class="'+borderClass+'" ';
             }
             if(currMenu == 0 && target > 0) {
              str += 'onMouseOver="menuOver('+currMenu+','+currItem+')" onMouseOut="menuOut('+currMenu+','+currItem+')" onClick="menuPopOver('+currMenu+','+currItem+')">';
             } else {
               str += 'onMouseOver="menuPopOver('+currMenu+','+currItem+')" onMouseOut="menuPopOut('+currMenu+','+currItem+')" onClick="menuPopClick('+currMenu+','+currItem+')">';
             }
             if(target > 0 && menu[target]) {
               menu[target][0].parentMenu = currMenu;
               menu[target][0].parentItem = currItem;
               if(popInd) {
                 str += '<div class="'+textClass+'" style="position: absolute; left: '+(w-15)+'; top: '+pad+'">'+popInd+'</div>';
               }
             }
             str += '<div class="'+textClass+'" style="position: absolute; left: '+pad+'; top: '+pad+'; width: '+(w-(2*pad))+'; height: '+(h-(2*pad))+'">'+(showImages && image?'<IMG SRC=/img/'+image+' ALIGN=ABSBOTTOM> ':'')+text+'</div>';
             str += '</div>';
             if(isVert) {
               itemY += length+spacing - 1;
             } else {
               itemX += length+spacing - 1 + (showImages ? 16 : 0);
             }
           }
         }
         div = document.createElement('div');
         document.body.appendChild(div);
         div.innerHTML = str;
         style = div.style;
         style.left = x;
         style.top = y;
         style.position = 'absolute';
         style.visibility = 'hidden';
         style.cursor = (document.all ? 'hand' : 'pointer');
         if(!document.all) {
           style.zIndex = 1000;
         }
         for(currItem = 1; currItem < menu[currMenu].length; currItem++) {
           itemName = 'menu'+currMenu+'item'+currItem;
           menu[currMenu][currItem].div = $(itemName);
           menu[currMenu][currItem].style = $(itemName).style;
         }
     }
   }
   menu[0][0].style.visibility = 'visible';
}

varListen(window,'load',menuCreate);
