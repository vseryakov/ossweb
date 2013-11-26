<HEAD><TITLE>@title@</TITLE></HEAD>
<BODY BGCOLOR=white>
<if @edit@ ne "">
  <TABLE BGCOLOR=#EEEEEE CELLSPACING=0 CELLPADING=0 WIDTH=100% BORDER=0>
   <TR>
      <TD ALIGN=RIGHT>
        <A HREF="javascript:;" onClick="window.open('@edit@','HelpEdit');window.close()">Edit</A> |
        <A HREF="javascript:window.close()">Close</A>
      </TD>
   </TR>
  </TABLE>
</if>
<CENTER><H3>@title@</H3></CENTER>
<HR>
@text@
</BODY>
