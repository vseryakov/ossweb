//  Author Vlad Seryakov vlad@crystalballinc.com
//  Aug 2006
//  $Id: webmail.js 2569 2006-12-21 00:03:03Z vlad $

var wmReq = null;
var wmMsgID = 0;
var wmFolderID = '';
var wmBaseUrl = '';
var wmRefresh = 0;
var wmBusy = 0;
var wmShowDeleted = 0;
var wmSearchTimer = 0;
var wmProgressTimer = 0;
var wmWinopts = 'width=950,height=800,location=0,menubar=0,scrollbars=1';

dndInit(/^wmSub/);

function dndOnSelect(obj,x,y)
{
  if(obj.id.match(/^wmSub/)) {
    div = dndCreateObj($('webmailMain'),'wmSub','/img/mail.gif',obj);
    div.wmMsgID = obj.id.substring(5);
    varClassAdd($('wmRow'+div.wmMsgID),'selected');
    return div;
  }
  return obj;
}

function dndOnDrag(obj,x,y)
{
  if(obj.id == 'wmSub') {
    var pos = varPos('webmailTop');
    var size = varSize('webmailTop');
    if(x <= 0 || x >= pos.x + obj.rowWidth) return false;
    if(y <= pos.y || y >= pos.y + size.height) return false;
  }
  return true;
}

function dndOnDrop(obj,x,y)
{
  if(obj.id == 'wmSub') {
    wmMsgID = obj.wmMsgID;
    varClassDel($('wmRow'+wmMsgID),'selected');
    setTimeout('wmOnDrop()',200);
  }
}

function wmOnDrop()
{
  var msgs = wmSelected();
  var obj = $('webmailTree');
  for (var i = 0; msgs.length && i < obj.childNodes.length; i++) {
    if(obj.childNodes[i].wmOver != null) {
      var tree = Tree[obj.childNodes[i].wmOver];
      if(tree && confirm('Move '+msgs.length+' message(s) into '+tree[2]+'?')) {
        wmReq = pagePopupGet(wmBaseUrl+'&cmd=move&folder='+tree[7]+'&msg_id='+escape(msgs.join(' ')),{req:1,data:'webmailStatus',onstart:'wmLoading()',onclose:'wmClear(-1)'});
        wmRowDelete(msgs);
      }
      break;
    }
  }
}

function wmToggleSelected()
{
  var obj, objs = document.getElementsByTagName('input');
  for (var i = 0; obj = objs[i]; ++i) {
    if(obj.type == 'checkbox' && obj.name == 'msg_id')
      obj.checked = obj.checked ? false : true;
  }
}

function wmSelected(cntFlag)
{
  var obj, msgs = new Array();
  var objs = document.getElementsByTagName('input');
  if(wmMsgID > 0) msgs[0] = wmMsgID;
  for (var i = 0; obj = objs[i]; ++i) {
    if(obj.type == 'checkbox' && obj.name == 'msg_id' && obj.checked && obj.value != wmMsgID) {
      msgs[msgs.length] = parseInt(obj.value);
    }
  }
  return cntFlag ? msgs.length : msgs;
}

function wmAlert(msg)
{
  varSet('webmailStatus',msg);
}

function wmClear(msg)
{
  wmBusy = 0;
  if(!msg) msg = varGet('webmailError');
  if(msg != -1) varSet('webmailStatus',msg);
}

function wmProgress()
{
  wmProgressTimer = 0;
  if(!wmBusy) return;
  var data = pagePopupGet(wmBaseUrl+'&cmd=progress',{sync:1});
  varSet('webmailStatus','<IMG SRC=/img/misc/loading.gif ALIGN=TOP> Loading... '+data);
  if(wmBusy) wmProgressTimer = setTimeout("wmProgress()",1000);
}

function wmLoading(progress)
{
  wmBusy = 1;
  varSet('webmailStatus','<IMG SRC=/img/misc/loading.gif ALIGN=TOP> Loading...');
  if(progress) setTimeout("wmProgress()",1000);
}

function wmToggleHeaders()
{
  var hdrs = document.getElementsByTagName('tr');
  for (var i = 0; hdr = hdrs[i]; ++i) {
    if(!hdr.id.match(/^wmHdr[0-9]+a$/)) continue;
    hdr.className = hdr.className == 'hidden' ? 'visible' : 'hidden';
  }
}

function wmHeader(name)
{
  var re = new RegExp(name+":", "i")
  var hdr, hdrs = document.getElementsByTagName('td');
  for (var i = 0; hdr = hdrs[i]; ++i) {
    if(hdr.id.match(/^wmHdrNm[0-9]+$/) && varGet(hdr.id).match(re))
      return varGet('wmHdrVl'+hdr.id.substring(7));
  }
  return '';
}

function wmSort(sort)
{
  if(wmBusy) return;
  wmReq = pagePopupGet(wmBaseUrl+'&cmd=list.sort&msg_sort='+sort,{req:1,data:'webmailTop',onstart:'wmLoading()',onclose:'wmNewMessages()'});
}

function wmSearch()
{
  if(wmBusy) return;
  if(wmSearchTimer) clearTimeout(wmSearchTimer);
  wmSearchTimer = setTimeout(function() {
    varClassAdd($('webmailSearch'), 'throbbing');
    wmList();
  }, 500);
}

function wmSearchContact(obj,val)
{
  var comma = obj.value.lastIndexOf(',');
  if(comma == -1) comma = 1;
  obj.value = obj.value.substring(0,comma-1);
  if(obj.value != '') obj.value += ',';
  obj.value += val.name;
}

function wmList(conn_id,folder)
{
  if(wmBusy) return;
  if(!folder) folder = wmFolderID;
  var url = wmBaseUrl+'&cmd=list&mailbox='+folder;
  if(conn_id) url += '&conn_id='+conn_id;
  if($('webmailSearch').value != '') url += '&filter='+$('webmailSearch').value;
  wmFolderID = folder;
  varSet('webmailBottom','');
  wmReq = pagePopupGet(url,{req:1,data:'webmailTop',onstart:'wmLoading(1)',onclose:'wmNewMessages()'});
}

function wmStop()
{
  if(wmReq) wmReq.abort();
  wmClear('Operation cancelled');
}

function wmRead(id)
{
  if(wmBusy) return;
  if (wmMsgID > 0) {
    varClassDel($('wmRow'+wmMsgID),'selected');
  }
  var msgs = new Array(''+id);
  wmMsgFlagClear(msgs,'U');
  wmRowClassClear(msgs,'unread');
  wmRowClassSet(msgs,'selected');
  wmMsgID = id;
  wmReq = pagePopupGet(wmBaseUrl+'&cmd=read&msg_id='+id,{req:1,data:'webmailBottom',onstart:'wmLoading()',onclose:'wmClear()'});
}

function wmDelete()
{
  if(wmBusy) return;
  var msgs = wmSelected();
  if(msgs.length && confirm(msgs.length+' Message(s) will be deleted. Continue?')) {
    wmReq = pagePopupGet(wmBaseUrl+'&cmd=delete&msg_id='+escape(msgs.join(' ')),{req:1,data:'webmailStatus',onstart:'wmLoading()',onclose:'wmClear(-1)'});
    wmRowDelete(msgs);
  }
}

function wmReply()
{
  if(wmBusy || !wmMsgID) return;
  window.open(wmBaseUrl+'&cmd=reply&msg_id='+wmMsgID,'Msg',wmWinopts);
}

function wmReplyAll()
{
  if(wmBusy || !wmMsgID) return;
  window.open(wmBaseUrl+'&cmd=replyall&msg_id='+wmMsgID,'Msg',wmWinopts);
}

function wmForward()
{
  if(wmBusy || !wmMsgID) return;
  window.open(wmBaseUrl+'&cmd=forward&msg_id='+wmMsgID,'Msg',wmWinopts);
}

function wmFolderManage()
{
  if(wmBusy) return;
  window.open(wmBaseUrl+'&cmd=folders','Folders',wmWinopts);
}

function wmFolderRefresh()
{
  if(wmBusy) return;
  if(confirm('This may take a long time to re-read all messages from the server, continue?')) {
    wmReq = pagePopupGet(wmBaseUrl+'&cmd=list.refresh&mailbox='+wmFolderID,{req:1,data:'webmailTop',onstart:'wmLoading()',onclose:'wmClear()'});
  }
}

function wmFolderMarkRead()
{
  if(wmBusy) return;
  wmReq = pagePopupGet(wmBaseUrl+'&cmd=list.markread&mailbox='+wmFolderID,{req:1,data:'webmailTop',onstart:'wmLoading()',onclose:'wmClear()'});
}

function wmFolderCompact()
{
  if(wmBusy) return;
  wmReq = pagePopupGet(wmBaseUrl+'&cmd=list.compact&mailbox='+wmFolderID,{req:1,data:'webmailTop',onstart:'wmLoading()',onclose:'wmNewMessages()'});
}

function wmRowDelete(msgs)
{
  if(wmShowDeleted) {
    wmMsgFlagSet(msgs,'D');
    return;
  }
  var tbody = $('webmailMessages');
  for(var i = 0; msgs && i < msgs.length; i++) {
    var row = $('wmRow'+msgs[i]);
    if(row) {
      tbody.removeChild(row);
      varSet('webmailBottom','');
    }
  }
}

function wmRowClassClear(msgs,class)
{
  for(var i = 0; msgs && i < msgs.length; i++) {
    var row = $('wmRow'+msgs[i]);
    if(row) varClassDel(row,class);
  }
}

function wmRowClassSet(msgs,class)
{
  for(var i = 0; msgs && i < msgs.length; i++) {
    var row = $('wmRow'+msgs[i]);
    if(row) varClassAdd(row,class);
  }
}

function wmMsgFlagSet(msgs,flag)
{
  for(var i = 0; msgs && i < msgs.length; i++) {
    var flags = varGet('wmFlg'+msgs[i]);
    if(flags.indexOf(flag) < 0) {
      varAppend('wmFlg'+msgs[i],flag);
    }
  }
}

function wmMsgFlagClear(msgs,flag)
{
  for(var i = 0; msgs && i < msgs.length; i++) {
    var flags = varGet('wmFlg'+msgs[i]);
    varSet('wmFlg'+msgs[i],flags.substitute(flag,' '));
  }
}

function wmReturnReceipt()
{
  if(wmMsgID > 0 && varGet('webmailFlags').match(/[NU]/) && wmHeader('Disposition-Notification-To') != '') {
    if(confirm('Message contains Desposition Notification request.Do you want to send Return Receipt?')) {
      wmReq = pagePopupGet(wmBaseUrl+'&cmd=returnreceipt&msg_id='+wmMsgID,{req:1,show:0});
    }
  }
}

function wmNewMessages()
{
  wmClear();
  varClassDel($('webmailSearch'), 'throbbing');
  var mbox = varGet('webmailMailbox');
  var nmsgs = varGet('webmailNewMsgs');
  if(mbox.match(/INBOX/i) && nmsgs > 0) {
    wmAlert('You have new mail');
  }
  document.title = mbox;
  if (nmsgs > 0) document.title += ' (' + nmsgs + ')';
}

function wmScheduler()
{
  if(wmRefresh > 0) {
    var now = new Date();
    var folder = varGet('webmailMailbox');
    if(wmBusy == 0 && folder.match(/INBOX/i) && now.getTime()/1000 - pagePopupTime.getTime()/1000 > wmRefresh) {
      wmList(folder);
    }
    setTimeout('wmScheduler()',wmRefresh*1000);
  }
}
