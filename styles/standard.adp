<%
   foreach { name value } { title "" width "" border_style "" border1 "" border2 ""
                            color1 "" color2 "" class:first "" class:section "" class:last ""
                            background "" nohelp "" width1 30% width2 70% class:over ""
                            no_first_row "" no_last_row "" border_title "" border_id ""
                            border_class osswebForm notitle "" cellspacing "" cellpadding "" } {
     if { ![info exists form_properties($name)] } { set form_properties($name) $value }
   }
   if { $form_properties(title) != "" } {
     if { [ossweb::conn title] == "" } {
       ossweb::conn -set title [ns_striphtml $form_properties(title)]
     }
     if { $form_properties(border_title) == "" } {
       set form_properties(border_title) [ossweb::conn title]
     }
   }
%>
<CENTER><~formerror id=@form_properties.id@></CENTER>

<~border id="@form_properties.border_id@"
         class="@form_properties.border_class@"
         style="@form_properties.border_style@"
         border1="@form_properties.border1@"
         border2="@form_properties.border2@"
         border_title="@form_properties.border_title@"
         cellspacing="@form_properties.cellspacing@"
         cellpadding="@form_properties.cellpadding@"
         color1="@form_properties.color1@"
         color2="@form_properties.color2@"
         width="@form_properties.width@" >

  <if @form_properties.notitle@ eq "" and @form_properties.no_first_row@ eq "">
  <rowfirst class=@form_properties.class:first@ VALIGN=TOP>
    <TD COLSPAN=2 background="@form_properties.background@">
      <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
       <TR>
         <TD NOWRAP CLASS=osswebFormTitle>@~form_properties.title@</TD>
         <TD ALIGN=RIGHT CLASS=osswebFormInfo>@~form_properties.info@&nbsp;</TD>
       </TR>
      </TABLE>
    </TD>
  </rowfirst>
  <TR><TD COLSPAN=2>&nbsp;</TD></TR>
  </if>

  <multirow name=form_widgets>

    <if @form_widgets.section@ not nil>
     <rowsection class=@form_properties.class:section@>
        <TD <if @form_widgets.section:info@ nil>COLSPAN=2</if>>@form_widgets.section@</TD>
        <if @form_widgets.section:info@ not nil><TD ALIGN=RIGHT>@form_widgets.section:info@</TD></if>
     </rowsection>
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
         <TD WIDTH=100% COLSPAN=2 ID=@form_widgets.id@_row >
         <TABLE ID=@form_widgets.id@_tbl WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
         <TR VALIGN=TOP>
         <if @form_widgets.no_label@ nil>
         <TD WIDTH=@form_properties.width1@ >
            <~formlabel id="@form_widgets.id@">
         </TD>
         </if>
         <TD WIDTH=1% ALIGN=RIGHT><if @form_widgets.prefix@ not nil>@form_widgets.prefix@</if></TD>
         <TD WIDTH=@form_properties.width2@ <if @form_widgets.class:cell@ not nil>CLASS=@form_widgets.class:cell@</if> >
         <if @form_widgets.info@ not nil>
            <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
            <TR VALIGN=TOP><TD>
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
                  <if @form_widgets.data@ not nil><TD>@form_widgets.data@</TD></if>
                  <TD><~formhelp id="@form_widgets.id@"></TD>
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

  <if @form_properties.no_last_row@ eq "">
  <rowlast class=@form_properties.class:last@>
     <TD COLSPAN=2>
     <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
     <TR>
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
       <if @form_widgets.leftside@ nil and @form_widgets.type@ in popupbutton helpbutton submit button reset>
         <if @form_widgets.condition@ not nil><~if @form_widgets.condition@></if>
         <~formwidget id=@form_widgets.id@>
         <if @form_widgets.condition@ not nil><~/if></if>
       </if>
     </multirow>
     </TD>
     </TR>
     </TABLE>
     </TD>
  </rowlast>
  </if>
</border>
