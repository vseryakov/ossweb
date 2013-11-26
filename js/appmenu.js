//  Author Vlad Seryakov vlad@crystalballinc.com
//  May 2002
//  $Id: appmenu.js 2559 2006-12-20 15:08:53Z vlad $

// Application menu and timeout
var appItems = new Array();
var appItemName = "app_submenu";
var appItemTimeout = 0;

function appItemNew(id,menu,ctx,url,image,title,target)
{
  var v = new Array();
  v[0] = id;
  v[1] = menu;
  v[2] = ctx;
  v[3] = url;
  v[4] = image;
  v[5] = title;
  v[6] = target;
  appItems[appItems.length] = v;
}

function appItemOver(obj)
{
   clearTimeout(appItemTimeout);
   obj.className='osswebAppItemOver';
}

function appItemOut(obj)
{
   obj.className='osswebAppItem';
   appItemTimeout = setTimeout('varSet(appItemName,"")',5000);
}

function appItemUrl(id,page,url,target)
{
  if(page != "" || url != "") {
    if(target && target != '')
      window.open(url,target);
    else
      window.location = url;
    return;
  }
  var v = '<TABLE BORDER=0 CELLSPACING=1 CELLPADDING=0><TR>';
  for(var i=0;i < appItems.length;i++) {
    if(appItems[i][0] != id) continue;
    v += '<TD NOWRAP CLASS=osswebAppItem onMouseOut="appItemOut(this)" onMouseOver="appItemOver(this)" '+
         'onClick="appItemUrl('+appItems[i][1]+','+"'"+appItems[i][2]+"','"+appItems[i][3]+"','"+appItems[i][6]+"')"+'">&nbsp;'+
         appItems[i][4]+' '+appItems[i][5]+'&nbsp;</TD>';
  }
  v += '</TR></TABLE>';
  varSet(appItemName,v);
  clearTimeout(appItemTimeout);
  appItemTimeout = setTimeout('varSet(appItemName,"")',5000);
}
