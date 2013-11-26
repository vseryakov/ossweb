<master mode=lookup>

<if @ossweb:cmd@ eq edit>
   <if @ossweb:ctx@ eq import>
     <formtemplate id=form_import></formtemplate>
     <return>
   </if>
   <formtemplate id=form_bookmarks></formtemplate>
   <FONT SIZE=1 COLOR=gray>
   To create folder just leave the Url empty and fill in only the Title.
   </FONT>
   <return>
</if>

<SCRIPT LANGUAGE=JavaScript1.2>
function bmNew()
{
  var url = '@url@',title = '';
  try {
    title = (window.opener ? window.opener.document.title : '');
    url = (window.opener ? window.opener.location : '');
  }
  catch (e) {}
  window.location='<%=[ossweb::lookup::url cmd edit]%>'+'&url='+url+'&title='+title;
}
function bmUrl(url)
{
  try { 
    if(window.opener) {
      window.opener.location=url;
      window.opener.focus();
    } else {
      var w=window.open(url,'Bm');
      w.focus();
    }
  }
  catch(e) { 
    var w=window.open(url,'Bm');
    w.focus(); 
  }
}

</SCRIPT>

<helptitle>My Bookmarks</helptitle>
<border cellspacing=1 border1=0 class1=ossBorder1 style=default>
<formtemplate id=form_bookmarks>
<multirow name=bookmarks>
<TR BGCOLOR=white>
   <TD>@bookmarks.title@</TD>
   <TD ALIGN=RIGHT NOWRAP WIDTH=1% >@bookmarks.edit@ @bookmarks.delete@</TD>
   <TD WIDTH=1% CLASS=ossSmallText>@bookmarks.sort@</TD>
</TR>
</multirow>
<rowlast>
<TD COLSPAN=3 ALIGN=RIGHT>
   <formwidget id=add> 
   <formwidget id=import>
   <formwidget id=close>
</TD>
</rowlast>
</formtemplate>
</border>
