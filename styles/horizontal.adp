<%
   foreach { name value } { title "" width "" border_style "" border1 "" border2 ""
                            color1 "" color2 "" first_row "" section_row "" last_row ""
                            background "" border_html "" border_title "" border_class osswebForm
                            horiz_cols 0 horiz_buttons 0 td_style "" td_html ""
                            cellspacing "" cellpadding "" } {
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
         html="@form_properties.border_html@" >

<~rowfirst VALIGN=TOP class="@form_properties.first_row@">
<multirow name=form_widgets>
  <if @form_widgets.type@ in hidden popupbutton submit button reset>
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
    </rowfirst>
    <~rowfirst VALIGN=TOP class=@form_properties.first_row@>
  </if>
</multirow>
</rowfirst>
<if @form_properties.horiz_buttons@ gt 0>
  <rowlast class=@form_properties.last_row@>
    <TD ALIGN=RIGHT COLSPAN=@form_properties.columns@>
    <multirow name=form_widgets>
      <if @form_widgets.type@ in popupbutton submit button reset><~formwidget id=@form_widgets.id@></if>
    </multirow>
    </TD>
  </rowlast>
</if>
</border>
