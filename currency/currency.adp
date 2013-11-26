<if @ossweb:cmd@ eq error>
  <B> <%=[ossweb::conn msg]%> </B>
  <return>
</if>



<if @ossweb:cmd@ in view lookup list>
   <master src=../index/index.title>
   <helptitle>ISO 4217 Currencies. Enter search criteria.</helptitle>
   <formtemplate id=form_currency>
   <border width="98%" >
   <TR>
     <TH>&nbsp;</TH>
     <TH NOWRAP>ISO alpha</TH>
     <TH NOWRAP>ISO numeric</TH>
     <TH>Currency</TH>
     <TH>Description</TH>
     <TH>Entity</TH>
   </TR>
   <TR>
     <TH>&nbsp;</TH>
     <TH><formwidget id=iso_code_alpha></TH>
     <TH><formwidget id=iso_code_num></TH>
     <TH><formwidget id=name></TH>
     <TH><formwidget id=description></TH>
     <TH NOWRAP><formwidget id=entity>&nbsp;&nbsp;&nbsp;
       <formwidget id=search>
       <formwidget id=reset>
       <formwidget id=close>
     </TH>
   </TR>
   <TR><TD COLSPAN=6 STYLE="border-bottom:1px solid black;">&nbsp;</TD></TR>

   <multirow name=currencies>
     <row type=plain underline=1>
       <TD NOWRAP VALIGN=TOP>
         <if @currencies.symbol_html@ ne "">
           @currencies.symbol_html@
         </if>&nbsp;
       </TD>
       <TD VALIGN=TOP>@currencies.iso_code_alpha@</TD>
       <TD VALIGN=TOP>@currencies.iso_code_num@</TD>
       <TD VALIGN=TOP>@currencies.name@</TD>
       <TD VALIGN=TOP STYLE="font-size:8pt;">@currencies.description@</TD>
       <TD VALIGN=TOP STYLE="font-size:8pt;">@currencies.entities@</TD>
     </row>
   </multirow>
   </border>
   </formtemplate>
   <return>
</if>
