<%
   foreach { name value } { title "" width "" color1 "" color2 "" row "" last_row "" last_colspan 1
                            background "" horiz_cols 0 horiz_buttons 0 border_html ""
                            border1 "" border2 "" border_style "" border_title "" border_class ""
                            cellspacing "" cellpadding "" buttons_break "<BR>" nobuttons 0
                            tr_html "" tr_style "" td_html "" td_style "" } {
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

<~border class="@form_properties.border_class@"
         style="@form_properties.border_style@"
         border1="@form_properties.border1@"
         border2="@form_properties.border2@"
         border_title="@form_properties.border_title@"
         cellspacing="@form_properties.cellspacing@"
         cellpadding="@form_properties.cellpadding@"
         color1="@form_properties.color1@"
         color2="@form_properties.color2@"
         width="@form_properties.width@"
         html="@form_properties.border_html@">

<TR VALIGN=TOP CLASS="@form_properties.row@" STYLE="@form_properties.tr_style@" @form_properties.tr_html@>
<multirow name=form_widgets>
  <if @form_widgets.type@ in popupbutton submit button reset>
    <% incr form_properties(horiz_buttons) %>
    <continue>
  </if>
  <TD NOWRAP STYLE="@form_properties.td_style@" @form_properties.td_html@>
    <~formlabel id=@form_widgets.id@><BR>
    <if @form_widgets.options@ ne "" and @form_widgets.type@ in radio checkbox>
      <~formgroup id=@form_widgets.id@>@~formgroup.widget@&nbsp;@~formgroup.label@&nbsp;&nbsp;<BR></formgroup>
    <else>
      <~formwidget id=@form_widgets.id@>
    </if>
    <if @form_widgets.data@ not nil>@form_widgets.data@</if>
  </TD>
  <% incr form_properties(horiz_cols) %>
  <if @form_properties.horiz_cols@ not mod @form_properties.columns@>
    </TR>
    <TR VALIGN=TOP CLASS="@form_properties.row@" STYLE="@form_properties.tr_style@" @form_properties.tr_html@>
  </if>
</multirow>
<if @form_properties.horiz_buttons@ gt 0 and @form_properties.nobuttons@ eq 0>
    <TD ALIGN=RIGHT VALIGN=MIDDLE COLSPAN="@form_properties.last_colspan@" STYLE="@form_properties.tr_style@" @form_properties.td_html@>
    <multirow name=form_widgets>
      <if @form_widgets.type@ in popupbutton submit button reset><~formwidget id=@form_widgets.id@>@form_properties.buttons_break@</if>
    </multirow>
    </TD>
</if>
</TR>
</border>
