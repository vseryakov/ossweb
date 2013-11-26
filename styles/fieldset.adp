<%
   foreach { name value } { border_id "" title ""
                            fieldset_class osswebForm
                            legend_class osswebFormTitle
                            class osswebForm width 100%
                            class:last "" class:over "" nohelp "" width1 30% width2 70% } {
     if { ![info exists form_properties($name)] } { set form_properties($name) $value }
   }
   if { [ossweb::conn title] == "" && $form_properties(title) != "" } {
     ossweb::conn -set title [ns_striphtml $form_properties(title)]
   }
%>

<CENTER><~formerror id=@form_properties.id@></CENTER>

<FIELDSET CLASS=@form_properties.fieldset_class@>
<LEGEND CLASS=@form_properties.legend_class@>@~form_properties.title@</LEGEND>

<TABLE BORDER=0 WIDTH=@form_properties.width@ CLASS=@form_properties.class@ ID=@form_properties.border_id@>

  <multirow name=form_widgets>

    <if @form_widgets.section@ not nil>
       <TR><TD COLSPAN=2>&nbsp;</TD></TR>
       <TR><TD COLSPAN=2>
           <TABLE BORDER=0 WIDTH=100% CELLSAPCING=0 CELLPADDING=0>
           <TR>
           <TD WIDTH=50% ><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1 BORDER=0></TD>
           <TD WIDTH=1% NOWRAP><B>@form_widgets.section@</B>&nbsp;</TD>
           <TD WIDTH=50% ><IMG SRC=/img/misc/graypixel.gif WIDTH=100% HEIGHT=1 BORDER=0></TD>
           </TR>
           </TABLE>
           </TD>
       </TR>
    </if>

    <group name=form_widgets column=section>

    <if @form_widgets.type@ not in popupbutton helpbutton submit button reset none>

      <if @form_widgets.condition@ not nil><~if @form_widgets.condition@></if>

      <if @form_properties.class:over@ ne "">
         <~% ossweb::widget @form_widgets.widget:id@ \
                  -onFocus "varClassAdd('@form_widgets.id@_row','@form_properties.class:over@')" \
                  -onBlur "varClassDel('@form_widgets.id@_row','@form_properties.class:over@')"
         %>
      </if>

      <if @form_widgets.separator@ not nil>
       <TR HEIGHT=1><TD COLSPAN=2 WIDTH=100% HEIGHT=1><IMG SRC=@form_widgets.separator@ BORDER=0 WIDTH=100% HEIGHT=1></TD></TR>
      </if>

      <TR VALIGN=TOP <if @form_widgets.class:row@ not nil>CLASS=@form_widgets.class:row@</if> >
         <TD WIDTH=100% COLSPAN=2 ID=@form_widgets.id@_row>
         <TABLE ID=@form_widgets.id@_tbl WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
         <TR VALIGN=TOP>
         <TD WIDTH=1>&nbsp;&nbsp;</TD>
         <TD WIDTH=@form_properties.width1@ >
            <~formlabel id=@form_widgets.id@>
         </TD>
         <TD WIDTH=1% ALIGN=RIGHT><if @form_widgets.prefix@ not nil>@form_widgets.prefix@</if></TD>
         <TD WIDTH=@form_properties.width2@ >
         <if @form_widgets.info@ not nil>
            <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
            <TR VALIGN=TOP><TD <if @form_widgets.class:cell@ not nil>CLASS=@form_widgets.class:cell@</if> >
         </if>
         <if @form_widgets.options@ ne "" and @form_widgets.type@ in radio checkbox>
            <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
            <if @form_widgets.horizontal@ not nil and @form_widgets.vertical@ nil>
            <TR><TD>
                <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
                <TR VALIGN=TOP>
                <~formgroup id=@form_widgets.id@>
                  <TD <if @form_widgets.class:cell@ not nil>CLASS=@form_widgets.class:cell@</if> >
                    @~formgroup.widget@&nbsp;@~formgroup.label@&nbsp;&nbsp;
                  </TD>
                  <if @form_widgets.horizontal_cols@ not nil>
                    <~if @~formgroup.rownum@ not mod @form_widgets.horizontal_cols@></TR><TR><~/if>
                  </if>
                </formgroup>
                </TR>
                </TABLE>
                </TD>
                <if @form_widgets.data@ not nil><TD>@form_widgets.data@</TD></if>
            </TR>
            <else>
            <TR VALIGN=TOP>
               <TD>
               <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
               <~formgroup id=@form_widgets.id@>
               <TR><TD>@~formgroup.widget@</TD>
                   <TD <if @form_widgets.class:cell@ not nil>CLASS=@form_widgets.class:cell@</if> >@~formgroup.label@</TD></TR>
               </formgroup>
               </TABLE>
               </TD>
               <if @form_widgets.data@ not nil><TD>@form_widgets.data@</TD></if>
            </TR>
            </if>
            </TABLE>
         <else>
            <if @form_widgets.help@ not nil>
               <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
               <TR VALIGN=TOP>
                  <TD <if @form_widgets.class:cell@ not nil>CLASS=@form_widgets.class:cell@</if> >
                    <~formwidget id="@form_widgets.id@">
                  </TD>
                  <TD><~formhelp id="@form_widgets.id@"></TD>
                  <if @form_widgets.data@ not nil><TD>@form_widgets.data@</TD></if>
               </TR>
               </TABLE>
            <else>
               <~formwidget id="@form_widgets.id@">
               <if @form_widgets.data@ not nil>@form_widgets.data@</if>
            </if>
         </if>
         <if @form_widgets.info@ not nil>
            </TD>
            <TD ALIGN=RIGHT CLASS=osswebFormInfo>@form_widgets.info@</TD>
            </TR>
            </TABLE>
         </if>
         </TD>

         </TR>
         </TABLE>
         </TD>
      </TR>
      <if @form_widgets.condition@ not nil><~/if></if>
    </if>
    </group>

  </multirow>
  <TR CLASS=@form_properties.class:last@>
     <TD NOWRAP>
     <multirow name=form_widgets>
       <if @form_widgets.leftside@ not nil and @form_widgets.type@ in popupbutton helpbutton submit button reset>
         <if @form_widgets.condition@ not nil><~if @form_widgets.condition@></if>
         <~formwidget id=@form_widgets.id@>
         <if @form_widgets.condition@ not nil><~/if></if>
       </if>
     </multirow>
     </TD>
     <TD ALIGN=RIGHT NOWRAP>
     <multirow name=form_widgets>
       <if @form_widgets.leftside@ nil and @form_widgets.type@ in helpbutton popupbutton submit button reset>
         <if @form_widgets.condition@ not nil><~if @form_widgets.condition@></if>
         <~formwidget id=@form_widgets.id@>
         <if @form_widgets.condition@ not nil><~/if></if>
       </if>
     </multirow>
     </TD>
  </TR>

</TABLE>
</FIELDSET>
