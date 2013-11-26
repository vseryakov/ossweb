# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001
#
# $Id: form.tcl 2937 2007-01-31 16:56:06Z vlad $

# Form object processor. Can be called any time for existent or non-existent
# form. Each subsequent call will overwrite previous values, form will be create
# if doesn't exist. Each form object is a Tcl array with some special columns.
# Access to forms may be done using native Tcl array tools. The only difference that
# form objects are created at specific level which is [ossweb::adp::Level].
#
# Available methods:
#   submitted - returns t if the form is in submitted state
#   exists - returns 1 if form does exist
#   reset - reset form's widgets, calls widget::reset method for each widget
#   save - saves contents of the form into user properties
#   restore - restores the form from user properties table
#   widgets - returns list with widget names according to optional pattern.
#   vaidate - performs form validation by calling all widget's validation method
#   destroy - removes the form from the memory
#   get_values - updates/creates local variables with values from the form, optional -level
#                parameters can be specified to create variables at specific level.
#   set_values - updates the form with values from local variables, optional widget list may be
#                specified to update only subset of widgets. Local variables should match
#                widget's id in order to use variable's value.
#   html - generates HTML code for the form, calles html method for each widget, all hidden
#          fields will be generated automatically
#   template - given template name, generates form HTML code from it.
#
# All other usage is considered as form parameters set, all names which begin with dash (-)
# will be set with corresponding value. For example:
#   ossweb::form form_name -title "Form1"
# will set title for the form form_name.
#
# Form special fields:
#   section - form may be divided on sections and widgets can belong to one of these
#             sections. All new widgets takes current section name from the form
#             and will be displayed in (grouped by) this section during HTML rendering.
#   id - this is form id or name
#   submitted - t or f
#   widgets - contains form's widget list
#   action - form action URL
#   html - orbitrary HTML code to use during HTML rendering
#   title - form title for form templates
#   info - right-side info to be put in form template's header
#   error - if non-empty, error text to display
#
proc ossweb::form { id { command "" } args } {

    set adp_level [ossweb::adp::Level]
    upvar #$adp_level $id form

    switch -exact -- $command {

     dump {
        append result [array get form] "\n"
        foreach widget_id $form(widgets) {
          upvar #$adp_level $widget_id widget
          append result $widget_id: [array get widget] "\n"
        }
        return $result
     }

     exists {
        return [array exists form]
     }

     save {
        if { ![array exists form] } {
          return
        }
        set values [list]
        foreach widget_id $form(widgets) {
          lappend values $widget_id [ossweb::widget $widget_id save]
        }
        ossweb::conn::set_property FORM:$id $values
     }

     restore {
        if { ![array exists form] } {
          return
        }
        foreach { widget_id value } [ossweb::conn::get_property FORM:$id] {
          ossweb::widget $widget_id restore $value
        }
     }

     widgets {
        if { ![array exists form] } {
          return
        }
        ns_parseargs { {-pattern ""} {-columns f} {-eval ""} } $args

        set list [list]
        foreach widget_id $form(widgets) {
          upvar #$adp_level $widget_id widget
          if { $pattern != "" && ![regexp $pattern $widget(name)] } {
            continue
          }
          lappend list $widget(id)
          if { $columns == "t" } {
            lappend list {} {}
          }
          if { $eval != "" } {
            upvar 1 widget widget
            set widget $widget_id
            if { [catch { uplevel 1 eval $eval } errmsg] } {
              ns_log Error ossweb::form: foreach: $widget: $errmsg
            }
          }
        }
        return $list
     }

     readonly {
        if { ![array exists form] } {
          return
        }
        ns_parseargs { {-null "&lt;not set&gt;"} {-skip_null f} {-buttons t} {-skip ""} {-hide f} } $args

        foreach widget_id $form(widgets) {
          if { $skip != "" && [regexp $skip $widget_id] } {
            continue
          }
          upvar #$adp_level $widget_id widget
          if { $skip_null == "t" && $widget(value) == "" } {
            set widget(type) none
            continue
          }
          switch -- $widget(type) {
           none -
           hidden {
             continue
           }
          }
          if { $hide == "t" } {
            switch -- $widget(type) {
             button -
             submit -
             popupbutton {
               set widget(type) none
             }
             default {
               set widget(type) inform
               set widget(value) ""
             }
            }
            continue
          }
          ossweb::widget $widget_id -readonly t -null $null -buttons $buttons
          ossweb::widget $widget_id readonly
        }
     }

     optional {
        if { ![array exists form] } {
          return
        }
        ns_parseargs { {-skip ""} } $args

        foreach widget_id $form(widgets) {
          if { $skip != "" && [regexp $skip $widget_id] } {
            continue
          }
          upvar #$adp_level $widget_id widget
          ossweb::widget $widget_id optional
        }
     }

     validate {
        if { ![array exists form] || $form(validate) == "f" } {
          return 0
        }
        # Widget dependencies, set widget as non-optional if
        # at least one widget from each group has value
        if { [info exists form(widget:requires)] } {
          foreach widget_id $form(widgets) {
            upvar #$adp_level $widget_id widget
            if { [info exists widget(requires)] && ($widget(value) != "" || $widget(values) != "") } {
              foreach w $widget(requires) {
                upvar #$adp_level $id.$w w2
                catch { unset w2(optional) }
              }
            }
          }
        }
        # Call widget validation routine for every form widget.
        foreach widget_id $form(widgets) {
          ossweb::widget $widget_id validate
        }
        if { $form(error) == "" } {
          return 0
        }
        ns_log Notice ossweb::form::validate: $id: $form(error)
        return 1
     }

     destroy {
        if { ![array exists form] } {
          return
        }
        # Destroy all form widgets
        foreach widget_id $form(widgets) {
          upvar #$adp_level $widget_id widget
          if { [info exists widget] } {
            unset widget
          }
        }
        unset form
     }

     find {
        # Widget count by property name/value
        if { ![array exists form] } {
          return
        }
        set count 0
        set name [lindex $args 0]
        set value [lindex $args 1]
        foreach widget_id $form(widgets) {
          if { [regexp -nocase $value [ossweb::widget $widget_id $name]] } {
            incr count
          }
        }
        return $count
     }

     reset {
        if { ![array exists form] } {
          return
        }
        ns_parseargs { {-vars t} {-skip ""} {-level {[expr [info level]-1]}} } $args

        foreach widget_id $form(widgets) {
          if { $skip != "" && ![regexp $skip $widget_id] } {
            ossweb::widget $widget_id reset -vars $vars -level $level
          }
        }
     }

     refresh_values {
        set level [expr [info level]-1]
        ossweb::form $id set_values -level $level
        ossweb::form $id get_values -level $level
     }

     get_values {
        if { ![array exists form] || $form(get_values) == "f" } {
          return 0
        }
        ns_parseargs { {-level {[expr [info level]-1]}} {-array ""} {-null f} -- args } $args

        foreach widget_id $form(widgets) {
          ossweb::widget $widget_id get_value -level $level -array $array -null $null
        }
     }

     set_values {
        # Update value sin all widgets
        if { ![array exists form] || $form(set_values) == "f" } {
          return 0
        }
        ns_parseargs { {-level {[expr [info level]-1]}} {-array ""} -- args } $args

        set columns [lindex $args 0]
        if { $columns != "" } {
          foreach name $columns {
            ossweb::widget $id.$name set_value -level $level -array $array
          }
        } else {
          foreach widget_id $form(widgets) {
            ossweb::widget $widget_id set_value -level $level -array $array
          }
        }
     }

     set_properties {
        # Update properties in all widgets
        if { ![array exists form] } {
          return 0
        }
        ns_parseargs { {-widgets ""} -- args } $args
        foreach widget_id $form(widgets) {
          if { $widgets != "" && [regexp -nocase $widgets [ossweb::widget $widget_id type]] } {
            continue
          }
          foreach { name value } $args {
            ossweb::widget $widget_id -$name $value
          }
        }
     }

     script {
        # Generate Javascript in the HEAD
        foreach widget_id $form(widgets) {
          ossweb::widget $widget_id script
        }
     }

     html {
        if { ![info exists form(widgets)] } {
          ns_log Notice ossweb::form: html: $id: incomplete form
          return
        }
        switch -- $form(action) {
         "" {
            # Not canonical path, use relative url
            if { [ossweb::conn app_name] == "unknown" || [ossweb::conn project_name] == "unknown" } {
              set form(action) [file tail [ns_conn url]]
            } else {
              # Use full path to the page
              set form(action) [ossweb::html::url [ossweb::conn page_name]]
            }
         }

         1 {
            # Use current page name when just -action is specified
            set form(action) [file tail [ns_conn url]]
         }

         "#*" -
         /* -
         http://* -
         https://* {
           # Regular url
         }

         default {
           # ossweb::html::url format
           set form(action) [eval ossweb::lookup::url $form(action)]
         }
        }

        set method [ossweb::coalesce form(method) POST]
        # Upload field check
        if { [ossweb::form $id find type file] } {
          set method POST
          if { [lsearch -nocase form(html) enctype] == -1 } {
             lappend form(html) ENCTYPE multipart/form-data
          }
        }
        if { [info exists form(noSubmit)] } {
          lappend form(html) onSubmit "return false;"
        } elseif { [info exists form(onSubmit)] } {
          lappend form(html) onSubmit "$form(onSubmit);"
        }

        if { [info exists form(target)] } {
          lappend form(html) target $form(target)
        }
        set output "<FORM NAME=\"$id\" method=$method ACTION=\"$form(action)\" [::ossweb::convert::list_to_attributes $form(html)]>\n"
        append output "<INPUT TYPE=HIDDEN NAME=\"form:id\" VALUE=\"$id\">\n"

        # Automatic request tracking
        if { [ossweb::true [ossweb::coalesce form(tracking) 1]] && [set tracking_id [ossweb::conn form:track:id]] != "" } {
          append output "<INPUT TYPE=HIDDEN NAME=\"form:track:id\" VALUE=\"$tracking_id\">\n"
        }
        # Perform pre-HTML check of the form
        foreach widget_id $form(widgets) {
          ossweb::widget $widget_id check
        }
        # Render all hidden fields
        foreach widget_id $form(widgets) {
          upvar #$adp_level $widget_id widget
          if { $widget(type) == "hidden" } {
            append output "<INPUT TYPE=HIDDEN NAME=\"$widget(name)\" ID=\"$widget(name)\" VALUE=\"[ossweb::html::quote $widget(value)]\">\n"
            set widget(rendered) t
          }
        }
        return $output
     }

     template {
        if { ![array exists form] } {
          return 0
        }
        set style [ossweb::nvl [lindex $args 0] standard]
        ossweb::adp::Buffer init
        uplevel #$adp_level "upvar 0 $id form_properties"
        upvar #$adp_level form_widgets:rowcount rowcount
        set rowcount 0
        foreach widget_id $form(widgets) {
          upvar #$adp_level $widget_id widget
          if { [lsearch -exact {hidden} $widget(type)] == -1 && $widget(rendered) != "t" } {
            incr rowcount
            set widget(rownum) $rowcount
            uplevel #$adp_level "upvar 0 {$widget_id} form_widgets:$rowcount"
          }
        }
        set file [ossweb::config server:path:styles "[ns_info home]/styles"]/$style
        ossweb::adp::Cache adp $file
        set output [string map { <~ < } [ossweb::adp::Buffer get output]]
        if { [ossweb::conn ossweb:debug] > 1 } {
          ossweb::conn::log Debug form:template $code
        }
        ossweb::adp::Buffer reset
        set code [ossweb::adp::Compile $output]
        if { [ossweb::conn ossweb:debug] > 2 } {
          ossweb::conn::log Notice form::template $code
        }
        ossweb::adp::Buffer reset
        uplevel #$adp_level $code
        set output [ossweb::adp::Buffer get output]
        ossweb::adp::Buffer clear
        return $output
     }

     default {
        variable ::ossweb::form::defaults
        if { ![array exists form] } {
          array set form $defaults
          set form(id) $id
          if { $id == [ns_queryget form:id] } {
            set form(submitted) t
          }
        }
        # Shortcut for returning single parameter
        if { [string index $command 0] != "-" && [llength $args] == 0 } {
          return [ossweb::coalesce form($command)]
        }
        # Process all parameters
        set args [eval list $command $args -end:form:list]
        for { set i 0 } { $i < [llength $args] } {} {
          set name [lindex $args $i]
          if { [string index $name 0] != "-" || $name == "-end:form:list" } {
            break
          }
          set name [string range $name 1 end]
          set value [lindex $args [incr i]]
          if { [string index $value 0] != "-" && $value != "-end:form:list" } {
            switch -glob -- $name {
             widgets {
               foreach widget $value {
                 uplevel ossweb::widget $id.[string trim $widget]
               }
             }
             cmd {
               ossweb::widget $id.cmd -type hidden -optional -value $value -freeze
             }
             ctx {
               ossweb::widget $id.ctx -type hidden -optional -value $value -freeze
             }
             hidden:* {
               if { [regexp {hidden:([^:]+):?(.+)?} $name d wname wtype] } {
                 ossweb::widget $id.$wname -type hidden -optional -value $value -freeze
                 # Optional datatype for validation
                 if { $wtype != "" } {
                   ossweb::widget $id.$wname -datatype $wtype
                 }
               }
             }
             default {
               set form($name) $value
             }
            }
            if { $value == "{}" && [lsearch -exact $defaults $name] == -1 } {
              unset widget($name)
            }
            incr i
          } else {
            switch -glob -- $name {
             cmd {
               ossweb::widget $id.cmd -type hidden -optional
             }
             ctx {
               ossweb::widget $id.ctx -type hidden -optional -value [ossweb::conn ctx_name]
             }
             hidden:* {
               if { [regexp {hidden:([^:]+):?(.+)?} $name d wname wtype] } {
                 ossweb::widget $id.$wname -type hidden -optional
                 # Optional datatype for validation
                 if { $wtype != "" } {
                   ossweb::widget $id.$wname -datatype $wtype
                 }
               }
             }
             lookup {
               ossweb::lookup::form $id
             }
             default {
               set form($name) 1
             }
            }
          }
        }
        # Return requested property
        if { [string index $command 0] != "-" && [info exists form($command)] } {
          return $form($command)
        }
     }
    }
    return
}

# Widget object processor. As with form, widget is Tcl array with special columns.
# It can be extended by setting new or updating existing fields as regular Tcl aray.
# Widgets are created at the same level [ossweb::adp::Level] as the forms.
# Widget name is combination of form name and widget name contcatenated by comma ".".
# For example form1.widget1 tells us that widget1 belongs to form form1. Widget name itself
# is allowed to contain commas. This proc basically is a wrapper around specific
# widget implementation, it calles widget driver for specific actions and performs
# some common operations as well. All methods marked with (driver) call widget
# driver implementation.
#
# Available methods:
#  exists - returns 1 if the widget exists
#  html - generates HTML code according to widget type (driver)
#  save - returns text string with widget value to be saved (driver)
#  restore - restores widget's value (driver)
#  validate - validates form value according to widget type and datatype (driver)
#  reset - clears or performs some widget specific resetting (driver)
#  set_value - sets widget value from local variable with the same name as widget's id (driver)
#  get_value - creates local variable with the same name and widget's value (driver)
#  formgroup - creates datasource formgroup with widget's options for
#              rendering checkbox/radio HTML fields
#
# All other usage considered as widget parameters set/inquire. All names which begin with dash (-)
# will be set to corresponding values. If widget called with name which doesn't begin with dash,
# value of the requested field will be retunred.
# For example:
#    ossweb::widget form1.wid1 -label "Name" -type text
#    set name [ossweb::widget form1.wid1 label]
#
# Special fields:
#  form:id - name of the form widget belongs to
#  widget:id - full name of the widget
#  id - name of the widget
#  name - name to be displayed in HTML code
#  label - label to be displayed, otherwise name will be used
#  section - form section the widget belongs to
#  type - widget type such as text, select, button ...
#  datatype - data type of the widget value such as integer, name, email, text ...
#  value - widget's value
#  html - orbitrary HTML text to put during HTML rendering
#  rendered - t or f
#  options - options list for multivalue widgets
#  acl - security check, if fails widget will not product html output
#
proc ossweb::widget { id command args } {

    global errorInfo
    set adp_level [ossweb::adp::Level]
    upvar #$adp_level $id widget

    switch -exact -- $command {

     setfocus {
        if { ![array exists widget] } {
          return
        }
        if { [::ossweb::widget::$widget(type) widget setfocus] == "" } {
          return "try {document.$widget(form:id).$widget(name).focus();} catch(e){};"
        }
     }

     setresizable {
        if { [info exists widget(htmleditor)] } {
          ossweb::html::include $widget(name) -mode widget -type tiny_mce -styles all
        } elseif { [info exists widget(resize)] } {
          ossweb::html::include "javascript:varResizable('$widget(name)','$widget(resize)');"
          ossweb::html::include /js/resizable.js -mode widget
        }
     }

     setautocomplete {
        # Setup autcomplete attributes

        # Do not generate autocomplete events more than once
        if { [info exists widget(autocomplete:done)] } {
          return
        }
        set widget(autocomplete:done) 1

        set acurl [ossweb::coalesce widget(autocomplete)]
        if { $acurl != "" } {
          switch -glob -- $acurl {
           /* -
           http://* -
           https://* {
             # Regular url
           }

           default {
             # ossweb::html::url format
             set acurl [eval ossweb::html::url $acurl]
           }
          }
          set acproc [ossweb::coalesce widget(autocomplete_proc) null]
          set acvalue [ossweb::coalesce widget(autocomplete_value)]
          set acfields [ossweb::coalesce widget(autocomplete_fields)]

          # Automatically assign value to specified widget
          if { $acvalue != "" } {
            set acproc "function(o,v){if(v.value)o.form.$acvalue.value=v.value;[ossweb::decode $acproc null "" "var f=$acproc;f(o,v);"]}"
          }
          # Assign list of values to the given fields
          if { $acfields != "" } {
            set fields ""
            foreach field $acfields {
              append fields "if(v.$field)o.form.$field.value=v.$field;"
            }
            set acproc "function(o,v){[ossweb::decode $acproc null "" "var f=$acproc;f(o,v);"]$fields}"
          }
          ossweb::widget $widget(widget:id) append_attr onFocus "varAutoComplete(this,'$acurl',$acproc);"
          ossweb::html::include /js/ac.js -mode widget
        }
        if { [info exists widget(autotab)] } {
          if { $widget(autotab) > 1 } {
            ossweb::widget $widget(widget:id) append_attr onKeyUp "formAutoTab(this,$widget(autotab),event);"
          }
          if { $acurl != "" } {
            ossweb::widget $widget(widget:id) append_attr onFocus "this.onAutocomplete=function(o){formAutoTab(o)};"
          }
        }
     }

     event:url {
        set url [ossweb::coalesce widget(url)]
        # Use current url if none supplied
        if { $url == "" } {
          set skip [list]
          # Skip parameters we are about to add later
          foreach { key val } $args { lappend skip $key }
          set url [ossweb::conn url]?[ossweb::conn::export_form -skip [join $skip |]]
        }
        set aflag 1
        switch -glob -- $url {
         "#*" -
         /* -
         http://* -
         https://* {
           # Regular url
         }

         js:* -
         javascript:* {
           # Javascript code as is
           set aflag 0
         }

         default {
           # ossweb::html::url format
           set url [eval ossweb::lookup::url $url]
         }
        }
        if { $aflag } {
          if { [string first ? $url] == -1 } {
            append $url ?
          }
          # Addinitonal parameters
          foreach { key val } $args {
            append url "&$key=[ossweb::html::quote $val]"
          }
        }
        return $url
     }

     event:link {
        # Build url for javascript callback
        ns_parseargs { {-url ""} {-urlargs ""} {-popupopts ""} } $args

        # Additinal javascript to be added to the url
        if { $urlargs != "" } {
          set urlargs "+$urlargs"
        }
        # HTML to be put into open window on open
        if { [info exists widget(window)] } {
          if { [info exists widget(windata)] } {
            append code "w=window.open('','$widget(window)','[ossweb::coalesce widget(winopts)]');w.focus();";
            append code "w.document.write('$widget(windata)');w.window.location='$url'$urlargs;"
          } elseif { [info exists widget(loading)] } {
            append code "progressLoading('$url'$urlargs,'$widget(window)','[ossweb::coalesce widget(winopts)]');"
          } else {
            append code "w=window.open('$url'$urlargs,'$widget(window)','[ossweb::coalesce widget(winopts)]');w.focus();";
          }
          append code "return false;"
        } elseif { [info exists widget(popup)] } {
          append code "pagePopupGet('$url'$urlargs,{[string trim $popupopts ,]});"
        } else {
          append code "window.location='$url'$urlargs;"
        }
        return $code
     }

     setevent {
        # Optional handler name can be passed, if not use onClick
        ns_parseargs { {-name onClick} {-html f} } $args

        # Do not generate events with already prepared handler
        if { [info exists widget($name:event)] } {
          return $widget($name)
        }
        set widget($name:event) 1

        set popupname [ossweb::coalesce widget(popupname) pagePopupObj]
        set popuptext [ossweb::coalesce widget(popuptext) -1]
        if { $popuptext != "-1" } {
          append code "varSet('$popupname','$popuptext');"
        }

        # Existing javascript code
        append code "[ossweb::coalesce widget($name)];[ossweb::widget $widget(widget:id) get_attr $name];"
        ossweb::widget $widget(widget:id) del_attr $name

        # Javascript popup options
        set popupopts [ossweb::coalesce widget(popupopts)]
        if { [info exists widget(popupposition)] } { append popupopts ",custom:popupPosition" }
        if { [info exists widget(popuponemptyhide)] } { append popupopts ",onemptyhide:[ossweb::true $widget(popuponemptyhide)]" }
        if { [info exists widget(popupdnd)] } { append popupopts ",dnd:[ossweb::true $widget(popupdnd)]" }
        if { [info exists widget(popupfollowcursor)] } { append popupopts ",followcursor:[ossweb::true $widget(popupfollowcursor)]" }
        if { [info exists widget(popupsync)] } { append popupopts ",sync:[ossweb::true $widget(popupsync)]" }
        if { [info exists widget(popupname)] } { append popupopts ",name:'$widget(popupname)'" }
        if { [info exists widget(popuprefreshwin)] } { append popupopts ",onclose:'window.location.reload()'" }
        if { [info exists widget(popupclasses)] } { append popupopts ",classes:'$widget(popupclasses)'" }
        if { [info exists widget(popupclose)] } { append popupopts ",close:1" }
        if { [info exists widget(popuppost)] } { append popupopts ",post:1" }
        if { [info exists widget(popuponclose)] } { append popupopts ",onclose:[ossweb::decode [regexp {^[ ]*function} $widget(popuponclose)] 1 $widget(popuponclose) '$widget(popuponclose)']" }
        if { [info exists widget(popuponstart)] } { append popupopts ",onstart:[ossweb::decode [regexp {^[ ]*function} $widget(popuponstart)] 1 $widget(popuponstart) '$widget(popuponstart)']" }
        if { [info exists widget(popuponfinish)] } { append popupopts ",onfinish:[ossweb::decode [regexp {^[ ]*function} $widget(popuponclose)] 1 $widget(popuponclose) '$widget(popuponfinish)']" }
        if { [info exists widget(popupdata)] } { append popupopts ",data:'$widget(popupdata')" }
        if { [info exists widget(popupdataobj)] } { append popupopts ",dataobj:'$widget(popupdataobj')" }
        if { [info exists widget(popuptop)] } { append popupopts ",top:$widget(popuptop)" }
        if { [info exists widget(popupleft)] } { append popupopts ",left:$widget(popupleft)" }
        if { [info exists widget(popupwidth)] } { append popupopts ",width:'$widget(popupwidth)'" }
        if { [info exists widget(popupheight)] } { append popupopts ",height:'$widget(popupheight)'" }
        if { [info exists widget(popupbgcolor)] } { append popupopts ",bgcolor:'$widget(popupbgcolor)'" }
        if { [info exists widget(popupborder)] } { append popupopts ",border:'$widget(popupborder)'" }
        if { [info exists widget(popupform)] } {
          append popupopts ",form:'[ossweb::decode [ossweb::true $widget(popupform)] 1 $widget(form:id) $widget(popupform)]'"
        }
        set popupopts [string trim $popupopts ,]

        # Confirmation popup
        set confirm [ossweb::coalesce widget(confirm)]
        set confirmtext [ossweb::coalesce widget(confirmtext)]
        set submit [ossweb::coalesce widget(submit) "this.form.submit();"]

        # Command name to send on click
        if { [set cmd_name [ossweb::coalesce widget(cmd_name)]] != "" } {
          if { $cmd_name == "1" } {
            set cmd_name $widget(label)
          }
          append code "this.form.cmd.value='$cmd_name';$submit"
        }

        # Url to call on click
        if { [info exists widget(url)] } {
          set url $widget(url)
          switch -glob -- $url {
           "#*" -
           /* -
           http://* -
           https://* {
              # Regular url
              append code [ossweb::widget $widget(widget:id) event:link \
                                -url $url \
                                -urlargs [ossweb::coalesce widget(urlargs)] \
                                -popupopts $popupopts]
           }

           js:* -
           javascript:* {
              # Javascript code as is
              append code "[string range $url 11 end];"
           }

           default {
              # ossweb::html::url format
              set url [eval ossweb::lookup::url $url]
              append code [ossweb::widget $widget(widget:id) event:link \
                                -url $url \
                                -urlargs [ossweb::coalesce widget(urlargs)] \
                                -popupopts $popupopts]
           }
          }
        }

        # Object to show on click
        if { [set popupshow [ossweb::coalesce widget(popupshow)]] != "" } {
          append code "popupShow('$popupshow',{$popupopts})"
        }

        # Name of the popup object to hide
        if { [set popupcloseobj [ossweb::coalesce widget(popupcloseobj)]] != "" } {
          if { $popupcloseobj == 1 } {
            set popupcloseobj ""
          } else {
            set popupcloseobj "name:'$popupcloseobj'"
          }
          append code "pagePopupClose({$popupcloseobj});"
        }
        # Post script after the actual click logic
        set after [ossweb::coalesce widget($name:after)]
        if { $after != "" } {
          append code "$after;"
        }
        # Confirmation text
        if { $confirm != "" || $confirmtext != "" } {
          if { $code != "" } {
            set code "if(!([ossweb::decode $confirm "" "confirm('$confirmtext')" $confirm]))return false;$code"
          } else {
            set code "return [ossweb::decode $confirm "" "confirm('$confirmtext')" $confirm]"
          }
        }
        # Remove excessive semicolons
        set code [string trim $code ";"]

        # Return complete HTML code for javascript handler if requested
        # otherwise just return Javascript code only
        if { $code != "" } {
          if { $html == "f" } {
            set code "$name=\"$code\""
          }
          # Assign HTML tag with new javascript code
          if { $html == "t" } {
            ossweb::widget $widget(widget:id) set_attr $name $code
          }
        }
        set widget($name) $code
        return $code
     }

     setenter {
        if { [info exists widget(onEnter)] } {
          ossweb::widget $widget(widget:id) append_attr onKeyUp "if(event.keyCode==13){$widget(onEnter);return false;}"
        }
     }

     setfocusblur {
        if { [info exists widget(onFocus)] } {
          ossweb::widget $widget(widget:id) append_attr onFocus "$widget(onFocus);"
        }
        if { [info exists widget(onBlur)] } {
          ossweb::widget $widget(widget:id) append_attr onBlur "$widget(onBlur);"
        }
     }

     setmouseoverout {
        if { [info exists widget(onMouseOver)] } {
          ossweb::widget $widget(widget:id) append_attr onMouseOver "$widget(onMouseOver);"
        }
        if { [info exists widget(onMouseOut)] } {
          ossweb::widget $widget(widget:id) append_attr onMouseOut "$widget(onMouseOut);"
        }
     }

     setoptions {
        if { ![array exists widget] } {
          return
        }
        if { [ossweb::coalesce widget(sql_table)] != "" &&
             [ossweb::coalesce widget(sql_columns)] != "" } {
          set widget(sql) "SELECT $widget(sql_columns) FROM $widget(sql_table) ORDER BY [ossweb::coalesce widget(sql_sort) 1]"
        }

        if { [ossweb::coalesce widget(sql)] != "" } {
           foreach item [ossweb::db::multilist $widget(sql) \
                              -colcount 2 \
                              -level [expr [info level]-2] \
                              -vars [ossweb::coalesce widget(sql_vars)] \
                              -timeout [ossweb::coalesce widget(sql_timeout)] \
                              -cache [ossweb::coalesce widget(sql_cache)]] {
             lappend widget(options) $item
           }
        }
     }

     destroy {
        if { ![array exists widget] } {
          return
        }
        upvar #$adp_level $widget(form:id) form
        if { [set index [lsearch -exact $form(widgets) $id]] > -1 } {
          set form(widgets) [lreplace $form(widgets) $index $index]
          unset widget
        }
     }

     exists {
        return [array exists widget]
     }

     array {
        return [array get widget]
     }

     html {
        if { ![array exists widget] } {
          return
        }
        if { [info exists widget(acl)] && [ossweb:::acl $widget(acl)] } {
          return
        }
        set widget(rendered) t
        # Object ID is assigned automatically to all widgets
        ossweb::widget $widget(widget:id) set_attr ID $widget(name)
        # Widget handlers for focus/blue events
        ossweb::widget $widget(widget:id) setfocusblur
        # Widget handlers for mouse over/out events
        ossweb::widget $widget(widget:id) setmouseoverout
        # Convert CSS style params
        if { [info exists widget(css)] } {
          set css ""
          foreach { key val } [ossweb::coalesce widget(css)] {
            append css "$key:$val;"
          }
          ossweb::widget $widget(widget:id) append_attr STYLE $css
        }
        # HTML tips
        if { [set help [ossweb::coalesce widget(help)]] != "" } {
          ossweb::widget $widget(widget:id) set_attr TITLE $help
          unset widget(help)
        }
        # Widget local Tcl script
        if { [info exists widget(eval)] } {
          switch [catch { uplevel #$adp_level $widget(eval) } errmsg] {
           0 {}
           4 - 2 - 3 { return }
           default {
              ns_log Error ossweb::widget::html: $id: $errmsg: $errorInfo
              return
           }
          }
        }
        # Generate HTML text
        if { [catch { set result [ossweb::widget::$widget(type) widget html] } errmsg] } {
          ns_log Error ossweb::widget::html: $id: $errmsg: $errorInfo
          return
        }
        # Additional HTML
        append result [lindex $args 0]
        # Set focus on form load
        if { [info exists widget(focus)] } {
          ossweb::html::include "javascript:[ossweb::widget $widget(widget:id) setfocus]"
        }
        # Initialize custom javascript object properties
        set js_prop ""
        foreach { key val } [ossweb::coalesce widget(js:property)] {
          append js_prop "if((obj = formObj('$widget(form:id)','$widget(name)')))obj.$key=$val;"
        }
        if { $js_prop != "" } {
          ossweb::html::include "javascript:$js_prop"
        }
        return $result
     }

     html:data {
        if { ![array exists widget] } {
          return
        }
        # Two columns for widget and its data
        if { [info exists widget(acl)] && [ossweb::acl $widget(acl)] } {
          return
        }
        return "<DIV ID=$widget(name)_div NOWRAP CLASS=\"osswebContent [ossweb::coalesce widget(class:data)]\">
                <DIV CLASS=osswebBlock>[ossweb::widget $id html]</DIV>&nbsp;
                <DIV CLASS=osswebBlock>[ossweb::widget $id data]</DIV>
                </DIV>"
     }

     html:label {
        if { ![array exists widget] } {
          return
        }
        if { [info exists widget(acl)] && [ossweb::acl $widget(acl)] } {
          return
        }
        if { ![info exists widget(label)] || $widget(type) == "none" } {
          return
        }
        # Generate custom label
        set result [ossweb::widget::$widget(type) widget html:label]
        if { $result == "" } {
          set result "<LABEL FOR=$widget(name) ID=$widget(name)_lbl CLASS=[ossweb::coalesce widget(class:label) osswebFormLabel]>$widget(label)</LABEL>"
        }
        # Tooltip over widget label
        if { [info exists widget(labelhelp)] } {
          set result "<A NAME=I_$widget(id) [ossweb::html::popup_handlers H_$widget(id) -popupopts "delay:1000"]>$result</A>"
          append result [ossweb::html::popup_object H_$widget(id) $widget(labelhelp) -iframe t]
        }
        append result [lindex $args 0]
        return $result
     }

     save {
        if { ![array exists widget] } {
          return
        }
        set value [::ossweb::widget::$widget(type) widget save]
        if { $value == "" } {
          set value $widget(value)
        }
        return $value
     }

     restore {
        if { ![array exists widget] } {
          return
        }
        if { [::ossweb::widget::$widget(type) widget restore [join $args]] == "" } {
          set widget(value) [join $args]
        }
     }

     validate {
        # Initialize widget's error message list
        set label ""
        set errmsg ""
        set value [ossweb::nvl $widget(value) $widget(values)]
        # Execute widget validation routine first
        if { [set rc [::ossweb::widget::$widget(type) widget validate]] != "" } {
          lappend errmsg $rc
        }
        # Check for required widget
        if { ![info exists widget(optional)] && [string equal $value {}] } {
          lappend errmsg [::ossweb::coalesce widget(error) "can not be empty"]
        }
        # Datatype may have its own validation proc
        if { $value != "" &&
             [set proc [info procs ::ossweb::datatype::$widget(datatype)]] != "" &&
             [set rc [$proc $value]] != "" } {
          lappend errmsg $rc
        }
        # Run custom validation code
        foreach { code message } $widget(validate) {
          if { ![expr $code] } {
            lappend errmsg [subst $message]
          }
        }
        if { $value != "" } {
          # SQL table value check, assumes that key is widget name
          if { [info exists widget(validate_sql_table)] } {
            set column [ossweb::coalesce widget(validate_sql_column) $widget(name)]
            set sql "SELECT 1 FROM $widget(validate_sql_table) WHERE $column=[ossweb::sql::quote $value] LIMIT 1"
            if { [ossweb::db::value $sql] == "" } {
              lappend errmsg [::ossweb::coalesce widget(error:sql) "unknown or unsupported value"]
            }
          }
        }
        # SQL statement, works same way as regular sql/xql with access to widget attributes
        if { [info exists widget(validate_sql)] } {
          ossweb::db::xql widget(validate_sql) [info level]
          set sql [subst $widget(validate_sql)]
          if { [ossweb::db::value $sql] == "" } {
            lappend errmsg [::ossweb::coalesce widget(error:sql) "unknown or unsupported value"]
          }
        }
        # Update form error messages
        if { $errmsg != {} } {
          upvar #$adp_level $widget(form:id) form
          # set a label for use in the template if no custom error
          if { ![info exists widget(error)] } {
            set label [ossweb::nvl $widget(label) $widget(name)]
          }
          # Separator between error messages
          set break [ossweb::coalesce form(error:break) "<BR>"]
          if { $form(error) != "" } {
            append form(error) $break
          }
          set widget(error) [join $errmsg $break]
          append form(error) "[ossweb::coalesce widget(error:prefix)] $label " $widget(error)
        }
     }

     reset {
        if { ![array exists widget] || [info exists widget(freeze)] } {
          return
        }
        ns_parseargs { {-vars t} {-level {[expr [info level]-1]}} } $args

        if { [eval ::ossweb::widget::$widget(type) widget reset] == "" } {
          set widget(value) [ossweb::coalesce widget(default)]
          upvar #$level $widget(name) var
          if { $vars == "t" && [info exists var] } {
            set var ""
          }
        }
     }

     script {
        if { ![array exists widget] } {
          return
        }
        return [::ossweb::widget::$widget(type) widget script]
     }

     readonly {
        if { ![array exists widget] } {
          return
        }
        if { [::ossweb::widget::$widget(type) widget readonly] == "" } {
          set widget(type) inform
        }
     }

     optional {
        if { ![array exists widget] } {
          return
        }
        set widget(optional) 1
        ::ossweb::widget::$widget(type) widget optional
     }

     check {
        if { ![array exists widget] } {
          return
        }
        ::ossweb::widget::$widget(type) widget check
     }

     set_value {
        if { ![array exists widget] || [info exists widget(freeze)] } {
          return
        }
        if { [catch {
          if { [eval ::ossweb::widget::$widget(type) widget set_value $args] == "" } {

            ns_parseargs { {-level {[expr [info level]-1]}} {-array ""} -- args } $args

            if { $array != "" } {
              upvar #$level ${array}($widget(name)) var
            } else {
              upvar #$level $widget(name) var
            }
            if { [array exists var] } {
              array unset var
            }
            if { [info exists var] } {
              set widget(value) $var
            }
          }
        } errmsg] } {
          ns_log Error ossweb::widget::set_value: $id: $errmsg: $errorInfo
        }
     }

     get_value {
        if { ![array exists widget]  || $widget(type) == "none" } {
          return
        }
        if { [catch { set value [eval ::ossweb::widget::$widget(type) widget get_value $args] } errmsg] } {
          ns_log Error ossweb::widget::get_value: $id: $errmsg: $errorInfo
          return
        }
        if { $value != "" } {
          return $value
        }
        ns_parseargs { {-level {[expr [info level]-1]}} {-return f} {-array ""} {-null f} -- args } $args

        set value $widget(value)
        
        # Convert empty into null
        if { $null == "t" && $value == "" && $widget(type) != "inform" } {
            set value null
        }
        
        if { $return == "t" } {
          return $value
        }
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) var
        } else {
          upvar #$level $widget(name) var
        }
        if { [array exists var] } {
          array unset var
        }
        set var $value
     }

     get_attr {
        if { ![array exists widget] } {
          return
        }
        foreach { key val } $widget(html) {
          if { [string equal -nocase $key $args] } { return $val }
        }
     }

     set_attr {
        # Update attribute in widget(html) property
        if { ![array exists widget] } {
          return
        }
        set html ""
        foreach { key val } $widget(html) {
          foreach { nkey nval } $args {
            if { [string equal -nocase $key $nkey] } {
              set val $nval
              set seen($nkey) 1
              break
            }
          }
          lappend html $key $val
        }
        # Now add new items
        foreach { nkey nval } $args {
          if { ![info exists seen($nkey)] } {
            lappend html $nkey $nval
          }
        }
        set widget(html) $html
     }

     del_attr {
        # Remove attribute
        if { ![array exists widget] } {
          return
        }
        set html ""
        foreach arg $args {
          foreach { key val } $widget(html) {
            if { ![string equal -nocase $key $arg] } {
              lappend html $key $val
            }
          }
        }
        set widget(html) $html
     }

     update_attr {
        # Update attribute if it is null, otherwise do nothing
        if { ![array exists widget] } {
          return
        }
        foreach { name value } $args {
          set attr [ossweb::widget $widget(widget:id) get_attr $name]
          if { $attr == "" } {
            ossweb::widget $widget(widget:id) set_attr $name $value
          }
        }
     }

     append_attr -
     prepend_attr {
        # Append/prepend attribute in widget(html) property with given value
        if { ![array exists widget] } {
          return
        }
        set name [lindex $args 0]
        set args [join [lrange $args 1 end] ""]
        set value [ossweb::widget $widget(widget:id) get_attr $name]
        switch -- [string index $command 0] {
         a { append value $args }
         p { set value "$args$value" }
        }
        ossweb::widget $widget(widget:id) set_attr $name $value
     }

     formgroup {
        if { ![array exists widget] } {
          return
        }
        set widget(rendered) t
        # Generate handlers and options once before
        # processing every item for formgroup tag
        ossweb::widget $widget(widget:id) setoptions
        ossweb::widget $widget(widget:id) setevent -html t
        set values [ossweb::coalesce widget(values)]
        lappend values $widget(value)
        ossweb::convert::list_to_array $values varray
        # The data source is named formgroup by convention
        upvar #$adp_level formgroup:rowcount rowcount
        set html $widget(html)
        set rowcount 0
        foreach item $widget(options) {
          set widget(value) [lindex $item 1]
          set widget(checked) [info exists varray($widget(value))]
          upvar #$adp_level formgroup:[incr rowcount] formgroup
          set formgroup(rownum) $rowcount
          set formgroup(label) [lindex $item 0]
          set formgroup(value) [lindex $item 1]
          # Arbitrary data for each option
          set formgroup(data) [lindex $item 2]
          # Additional html tags for each option
          set widget(html) "$html [lindex $item 3]"
          # Items for manual widget generation
          set formgroup(name) $widget(name)
          set formgroup(id) $widget(widget:id)
          set formgroup(html) [ossweb::convert::list_to_attributes $widget(html)]
          set formgroup(widget) [ossweb::widget $widget(widget:id) html]
        }
        set widget(html) $html
     }

     default {
        variable ::ossweb::widget::defaults
        variable ::ossweb::widget::reserved
        # Return requested property
        if { [string index $command 0] != "-" } {
          return [ossweb::coalesce widget($command)]
        }
        if { ![array exists widget] } {
          array set widget $defaults
          set name [split $id "."]
          set form_id [lindex $name 0]
          set widget_id [join [lrange $name 1 end] "."]
          upvar #$adp_level $form_id form
          # Create the form if doesn't exist yet
          if { ![array exists form] } {
            ::ossweb::form $form_id
          }
          lappend form(widgets) $id
          set widget(form:id) $form_id
          set widget(form) $form_id
          set widget(widget:id) $id
          set widget(id) $widget_id
          set widget(name) $widget_id
          set widget(label) $widget_id
          set widget(section) $form(section)
          set widget(section:info) [ossweb::coalesce form(section:info)]
          set widget:new 1
        }
        # Widget parameters
        if { [string index $command 0] == "-" } {
          set args [eval list $command $args -end:widget:list]
          for { set i 0 } { $i < [expr [llength $args]-1] } {} {
            set name [lindex $args $i]
            if { [string index $name 0] != "-" || $name == "-end:widget:list" } {
              break
            }
            set name [string range $name 1 end]
            set value [lindex $args [incr i]]
            set old [ossweb::coalesce widget($name)]
            if { [string index $value 0] != "-" || [string range $value 0 1] == "--" } {
              set widget($name) $value
              if { $value == "{}" && [lsearch -exact $defaults $name] == -1 } {
                unset widget($name)
              }
              incr i
            } else {
              set widget($name) 1
            }
            # Special handlers
            switch -- $name {
             type {
               # Need to call handler to properly initialize widget on type change
               if { $value != $old } {
                 set widget:type 1
               }
             }

             requires {
               # Mark the form that we have widget dependencies
               set form(widget:requires) 1
             }
            }
          }
        }
        if { [catch {
          # First time called
          if { [info exists widget:new] } {
            # Get the value from query, skip reserved and frozen widgets
            if { [::ossweb::widget::$widget(type) widget create] == "" &&
                 ![info exists widget(freeze)] &&
                 [ns_queryexists $widget(name)] &&
                 [lsearch -exact $reserved $widget(name)] == -1 } {
              set widget(value) [ns_queryget $widget(name)]
            }
            # Scan properties and auto include javascript files
            foreach { p f } { autocomplete /js/ac.js resize /js/resizable.js } {
              if { [info exists widget($p)] } {
                ossweb::html::include $f
              }
            }
          } elseif { [info exists widget:type] } {
            ::ossweb::widget::$widget(type) widget create
          }
        } errmsg] } {
          ns_log Error ossweb::widget::create: $id: $errmsg: $errorInfo
        }
     }
    }
    return
}

# Dummy widget
proc ossweb::widget::none { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     create {
        set widget(optional) 1
     }
    }
    return
}

# Create a date entry widget according to a format string
# The format string should contain the following fields, separated by space
# YYYY       4-digit year
# YY         2-digit year
# MM         2-digit month
# MON        month name like "Jan"
# MONTH      month name like "January"
# DD         day of month
# HH12       12-hour hour
# HH or HH24 24-hour hour
# MI         minutes
# SS         seconds
# AM         am/pm flag
# DR         day range, includes days from 1 to 31 and some additional ranges
# Any format field may be followed by "t", in which case a text
# widget will be used to represent the field, or by "l",
# in which case text label will be used for the field.
# Appending 'o' to the end of the format field means this field may be optional.
proc ossweb::widget::date { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {

     create {
        set widget_id $widget(name)
        set date ""
        foreach field { year month day hours minutes seconds ampm } {
          set value [ns_queryget "${widget_id}_$field"]
          if { $value == "" } {
            continue
          }
          switch $field {
           day {
              set day [split $value "."]
              set date [ossweb::date -set $date day [lindex $day 0] day2 [lindex $day 1]]
           }
           default {
              set date [ossweb::date -set $date $field $value]
           }
          }
        }
        if { $date != "" } {
          set widget(value) $date
          return 1
        } elseif { $widget(value) != "" } {
          set widget(value) [ossweb::date parse2 $widget(value)]
        }
        if { $widget(format) == "TEXT" } {
          set widget(value) [ns_queryget $widget_id]
        }
        # Let calendar widget to do its internal setup
        if { [ossweb::coalesce widget(calendar) 1] } {
          ossweb::widget::calendar widget create
        }
        return 0
     }

     set_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-array ""} -- args } $args
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) var
        } else {
          upvar #$level $widget(name) var
        }
        if { [info exists var] } {
          if { $var != "" } {
            set widget(value) [ossweb::date parse2 $var]
          } else {
            set widget(value) ""
          }
        }
        return 1
     }

     validate {
        set date $widget(value)
        set range [info exists widget(range)]
        set format [ossweb::coalesce widget(format) "MON / DD / YYYY"]
        set optional [ossweb::coalesce widget(optional) 0]
        foreach { field mask } { year (YY|YYYY)(o)?
                                 month (MM|MON|MONTH)(o)?
                                 day (DD|DR)(o)?
                                 hours (HH|HH24|HH12)(o)?
                                 minutes (MI)(o)?
                                 seconds (SS)(o)? } {
          if { ![regexp $mask $format d fmt opt] } {
            continue
          }
          set value [ossweb::trim0 [ossweb::date $field $date]]
          if { $value == "" } {
            if { !$optional && !$range && $opt != "o" } {
              return "No value supplied for $field"
            }
            continue
          }
          if { ![string is integer $value] || [ossweb::negative $value] } {
            return "The $field must be positive integer"
          }
          switch $field {
           month {
             if { $value < 1 || $value > 12 } {
               return "Month must be between 1 and 12"
             }
           }
           day {
             if { $value < 1 || $value > 31 } {
               return "Day must be between 1 and 31"
             }
             set mon [ossweb::date month $date]
             if { !$range && $mon != "" } {
               set max [ossweb::date daysInMonth $mon [ossweb::date year $date]]
               if { $value < 1 || $value > $max } {
                 return "The day must be between 1 and $max for [ossweb::date monthName $mon]"
               }
             }
           }
           hours {
             if { $value < 0 || $value > 23 } {
               return "Hours must be between 0 and 23"
             }
           }
           seconds -
           minutes {
             if { $value < 0 || $value > 59 } {
               return "$field must be between 0 and 59"
             }
           }
          }
        }
     }

     readonly {
        set format ""
        set widget(format) [ossweb::coalesce widget(format) "MON / DD / YYYY"]
        foreach field $widget(format) {
          switch -- [string index $field end] {
           l {}
           t {
             set field "[string range $field 0 end-1]l"
           }
           default {
             if { [regexp {[0-9A-Za-z]+} $field] } {
               append field l
             }
           }
          }
          lappend format $field
        }
        set widget(calendar) ""
        set widget(format) [join $format]
        return 1
     }

     html {
        if { [info exists widget(readonly)] && $widget(value) == "" } {
          return
        }
        set flag 0
        set widget(format) [ossweb::coalesce widget(format) "MON / DD / YYYY"]
        set widget(format) [string map { - { - } / { / } : { : } . { . } } $widget(format)]
        set output "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0><TR>\n"
        set class [ossweb::coalesce widget(class) osswebInput]
        set class:select [ossweb::coalesce widget(class:select) osswebSelect]
        foreach field $widget(format) {
          append output "<TD NOWRAP>"
          switch -- $field {
           YYYYt {
              set flag 1
              set value [ossweb::date year $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_$field SIZE=4 MAXLENGTH=4 VALUE=\"$value\">"
           }
           YYYYl {
              append output "<B>" [ossweb::date year $widget(value)] "</B>"
           }
           YYYY {
              set flag 1
              set value [ossweb::date year $widget(value)]
              set options [ossweb::option_list [ossweb::coalesce widget(year_start) 1990] [ossweb::coalesce widget(year_end) 2020] 1 4]
              append output [ossweb::html::select "$widget(name)_year" $options $value "class ${class:select}"]
           }
           YYl {
              append output "<B>" [ossweb::date short_year $widget(value)] "</B>"
           }
           YYt {
              set flag 1
              set value [ossweb::date short_year $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_$field SIZE=2 MAXLENGTH=2 VALUE=\"$value\">"
           }
           YY {
              set flag 1
              set value [ossweb::date short_year $widget(value)]
              set options [ossweb::option_list 0 20 1 2]
              append output [ossweb::html::select "$widget(name)_year" $options $value]
           }
           MMt {
              set flag 1
              set value [ossweb::date month $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_$field SIZE=2 MAXLENGTH=2 VALUE=\"$value\">"
           }
           MMl {
              append output "<B>" [ossweb::date month $widget(value)] "</B>"
           }
           MM {
              set flag 1
              set value [ossweb::pad0 [ossweb::date month $widget(value)] 2]
              set options [ossweb::option_list 1 12 1 2]
              append output [ossweb::html::select "$widget(name)_month" $options $value "class ${class:select}"]
           }
           MONl {
              set value [ossweb::date month $widget(value)]
              append output "<B>" [ossweb::date monthName $value 1] "</B>"
           }
           MON {
              set flag 1
              set value [ossweb::pad0 [ossweb::date month $widget(value)] 2]
              set options [list [list "--" {}]]
              for { set i 1 } { $i <= 12 } { incr i } {
                lappend options [list [ossweb::date monthName $i 1] [ossweb::pad0 $i 2]]
              }
              append output [ossweb::html::select "$widget(name)_month" $options $value "class ${class:select}"]
           }
           MONTHl {
              set value [ossweb::date month $widget(value)]
              append output "<B>" [ossweb::date monthName $value] "</B>"
           }
           MONTH {
              set flag 1
              set value [ossweb::pad0 [ossweb::date month $widget(value)] 2]
              set options [list [list "--" {}]]
              for { set i 1 } { $i <= 12 } { incr i } {
                lappend options [list [ossweb::date monthName $i] [ossweb::pad0 $i 2]]
              }
              append output [ossweb::html::select "$widget(name)_month" $options $value "class ${class:select}"]
           }
           DDt {
              set flag 1
              set value [ossweb::date day $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_day SIZE=2 MAXLENGTH=2 VALUE=\"$value\">"
           }
           DDl {
              append output "<B>" [ossweb::date day $widget(value)] "</B>"
           }
           DD {
              set flag 1
              set value [ossweb::pad0 [ossweb::date day $widget(value)] 2]
              set options [ossweb::option_list 1 31 1 2]
              append output [ossweb::html::select "$widget(name)_day" $options $value "class ${class:select}"]
           }
           HHt {
              set flag 1
              set value [ossweb::date day $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_hours SIZE=4 MAXLENGTH=4 VALUE=\"$value\">"
           }
           HHl -
           HH12l -
           HH24l {
              append output "<B>" [ossweb::date hours $widget(value)] "</B>"
           }
           HH12 {
              set flag 1
              set value [ossweb::pad0 [ossweb::date short_hours $widget(value)] 2]
              set options [ossweb::option_list 0 12 [ossweb::coalesce widget(hours_step) 1] 2]
              append output [ossweb::html::select "$widget(name)_hours" $options $value "class ${class:select}"]
           }
           HH -
           HH24 {
              set flag 1
              set value [ossweb::pad0 [ossweb::date hours $widget(value)] 2]
              set options [ossweb::option_list 0 23 [ossweb::coalesce widget(hours_step) 1] 2]
              append output [ossweb::html::select "$widget(name)_hours" $options $value "class ${class:select}"]
           }
           MIt {
              set flag 1
              set value [ossweb::date minutes $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_minutes SIZE=2 MAXLENGTH=2 VALUE=\"$value\">"
           }
           MIl {
              append output "<B>" [ossweb::date minutes $widget(value)] "</B>"
           }
           MI {
              set flag 1
              set value [ossweb::pad0 [ossweb::date minutes $widget(value)] 2]
              set options [ossweb::option_list 0 59 [ossweb::coalesce widget(minutes_step) 1] 2]
              append output [ossweb::html::select "$widget(name)_minutes" $options $value "class ${class:select}"]
           }
           SSt {
              set value [ossweb::date seconds $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name)_seconds SIZE=2 MAXLENGTH=2 VALUE=\"$value\">"
           }
           SSl {
              append output "<B>" [ossweb::date seconds $widget(value)] "</B>"
           }
           SS {
              set value [ossweb::pad0 [ossweb::date seconds $widget(value)] 2]
              set options [ossweb::option_list 0 59 [ossweb::coalesce widget(seconds_step) 1] 2]
              append output [ossweb::html::select "$widget(name)_seconds" $options $value "class ${class:select}"]
           }
           PMl -
           AMl -
           AMPMl -
           PM -
           AM -
           AMPM {
              set value [ossweb::date ampm $widget(value)]
              append output [ossweb::html::select "$widget(name)_ampm" {{A.M. am} {P.M. pm}} $value "class ${class:select}"]
           }
           DR {
              set flag 1
              set value [ossweb::pad0 [ossweb::date day $widget(value)] 2]
              set options [list [list "--" {}] \
                                [list Today [clock format [clock seconds] -format "%d"]] \
                                [list 1-10 1.10] \
                                [list 10-20 10.20] \
                                [list 20-31 20.31]]
              eval lappend options [ossweb::option_list 1 31 1 2]
              append output [ossweb::html::select "$widget(name)_day" $options $value "class ${class:select}"]
           }
           TEXT {
              set flag 2
              set value [ossweb::date pretty_date $widget(value)]
              append output "<INPUT TYPE=TEXT CLASS=$class NAME=$widget(name) SIZE=15 VALUE=\"$value\">"
           }
           TEXTl {
              append output "<B>" [ossweb::date pretty_date $widget(value)] "</B>"
           }
           default {
              append output $field
           }
          }
          append output "</TD>"
        }
        if { $flag && [info exists widget(calendar)] } {
          set widget(notext) 1
          if { $flag != 2 } {
            set widget(proc) formCalendarSetDate
          }
          append output "<TD>" [ossweb::widget::calendar widget html] "</TD>"
        }
        append output "</TR></TABLE>\n"
        return $output
     }
    }
    return
}

proc ossweb::widget::calendar { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        if { [ns_queryexists $widget(name)] } {
          set widget(value) [ns_querygetall $widget(name)]
        }
        if { [string equal $widget(values) {{}}] } {
          set widget(values) ""
        }
        ossweb::widget::calendar widget include:js
        return 1
     }

     readonly {
        set widget(type) inform
        return 1
     }

     include:js {
        # Because of different js files and using popups we may need to generate include
        # early on widget create and sometimes when using in tags to include js file on
        # html output, so we call this twice, on create and on html
        set inline [ossweb::decode [info exists widget(inline)] 1 t f]
        switch -- [ossweb::coalesce widget(style) [ossweb::config calendar:style dcalendar]] {
         calendar {
           return [ossweb::html::include /js/calendar.js -return $inline]
         }

         default {
           return [ossweb::html::include /js/dcalendar.js -return $inline]
         }
        }
     }

     html {
        set slave [ossweb::coalesce widget(slave)]
        set name [ossweb::coalesce widget(object) $widget(name)]
        set proc [ossweb::coalesce widget(proc) null]
        switch -- [ossweb::coalesce widget(style) [ossweb::config calendar:style dcalendar]] {
         calendar {
           set output [ossweb::html::link -image calendar.gif -alt Calendar \
                            -url "javascript:calendarShow('$widget(form:id)','$name',null,null,null,$proc);"]
         }

         default {
           set output [ossweb::html::link -image calendar.gif -alt Calendar \
                            -url "javascript:;" -html "ID=$name onClick=\"dCalendarShow('$widget(form:id)','$name',null,$proc)\""]
         }
        }
        if { ![info exists widget(notext)] } {
          set output "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
                      <TR><TD><INPUT TYPE=TEXT CLASS=[ossweb::coalesce widget(class) osswebInput] NAME=\"$widget(name)\" VALUE=\"[ossweb::html::quote $widget(value)]\" [ossweb::convert::list_to_attributes $widget(html)]></TD>
                          <TD>&nbsp;$output</TD>
                      </TR></TABLE>"
        }
        append output [ossweb::widget::calendar widget include:js]
        return $output
     }
    }
    return
}

# A static information widget that does not submit any data
proc ossweb::widget::inform { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
     }

     html {
        set result $widget(value)

        # Strip off timezone from PostgreSQL dates, everything is in local time
        if { [info exists widget(date)] } {
          regsub {(\:[0-9][0-9])(\+[0-9][0-9])$} $result {\1} result
          regsub {(\.[0-9]+-[0-9][0-9])$} $result {} result
          regsub {(\:[0-9][0-9])(-[0-9][0-9])$} $result {\1} result
        }

        set class [ossweb::coalesce widget(class) osswebInform]
        if { [info exists widget(bold)] } {
          set result "<B>$result</B>"
        }
        return "<SPAN CLASS=$class [ossweb::convert::list_to_attributes $widget(html)]>$result</SPAN>"
     }
    }
    return
}

proc ossweb::widget::readonly { widget_id command args } {

    upvar $widget_id widget
    return [uplevel ossweb::widget::inform widget $command $args]
}

# A static information widget that consists of hidden input from value
# and static text from label parameter.
proc ossweb::widget::label { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
     }
     readonly {
        if { $widget(value) == "" } {
          set widget(value) [ossweb::coalesce widget(null)]
        }
        return 1
     }
     html {
        if { ![info exists widget(nohidden)] } {
          set output "<INPUT TYPE=HIDDEN NAME=$widget(name) VALUE=\"[ossweb::html::quote $widget(value)]\">"
        }
        set value [ossweb::coalesce widget(title) $widget(value)]
        append output "<SPAN CLASS=[ossweb::coalesce widget(class) osswebLabel] [ossweb::convert::list_to_attributes $widget(html)]>$value</SPAN>"
        return $output
     }
    }
    return
}

# Link widget for tabbed panels and other links in forms
# Special parameters:
# -notab tells not to add tab=id to the end of url,
#        otherwise it is added.tab.adp template style
#        uses tab variable to decide which tab is currently
#        selected.
# -pad specifies padding between url label
# -html can be used for url javascript handlers
proc ossweb::widget::link { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
     }

     readonly {
        return 1
     }

     html {
        if { [info exists widget(disabled)] } {
          return
        }
        set widget(url) [ossweb::coalesce widget(url) $widget(value)]
        # Append tab switch
        if { ![info exists widget(notab)] } {
          lappend args tab $widget(name)
        }
        # Use context as well
        if { [info exists widget(ctx)] } {
          lappend args ctx $widget(name)
        }
        # Construct url
        set url [eval ossweb::widget $widget(widget:id) event:url $args]

        # Padding between link label
        if { [info exists widget(pad)] } {
          append output [string repeat "&nbsp;" $widget(pad)]
        }
        append output [ossweb::html::link \
                            -url $url \
                            -text $widget(label) \
                            -lookup [ossweb::coalesce widget(lookup)] \
                            -image [ossweb::coalesce widget(image)] \
                            -html [ossweb::convert::list_to_attributes $widget(html)] \
                            -onClick [ossweb::coalesce widget(onClick)] \
                            -onMouseOver [ossweb::coalesce widget(onMouseOver)] \
                            -onMouseOut [ossweb::coalesce widget(onMouseOut)] \
                            -confirm [ossweb::coalesce widget(confirm)] \
                            -confirmtext [ossweb::coalesce widget(confirmtext)] \
                            -popup [ossweb::decode [info exists widget(popup)] 1 t f] \
                            -popupopts [ossweb::coalesce widget(popupopts)] \
                            -popuprefreshwin [ossweb::coalesce widget(popuprefreshwin)] \
                            -popupclasses [ossweb::coalesce widget(popupclasses)] \
                            -popuponemptyhide [ossweb::coalesce widget(popuponemptyhide)] \
                            -popupposition [ossweb::coalesce widget(popupposition)] \
                            -popupname [ossweb::coalesce widget(popupname)] \
                            -popupclose [ossweb::coalesce widget(popupclose)] \
                            -popuppost [ossweb::coalesce widget(popuppost)] \
                            -popupfollowcursor [ossweb::coalesce widget(popupfollowcursor)] \
                            -popuponclose [ossweb::coalesce widget(popuponclose)] \
                            -popupshow [ossweb::coalesce widget(popupshow)] \
                            -popupdata [ossweb::coalesce widget(popupdata)] \
                            -popupdataobj [ossweb::coalesce widget(popupdataobj)] \
                            -popuptop [ossweb::coalesce widget(popuptop)] \
                            -popupleft [ossweb::coalesce widget(popupleft)] \
                            -popupwidth [ossweb::coalesce widget(popupwidth)] \
                            -popupheight [ossweb::coalesce widget(popupheight)] \
                            -popupdnd [ossweb::coalesce widget(popupdnd)] \
                            -popupsync [ossweb::coalesce widget(popupsync)] \
                            -popupbgcolor [ossweb::coalesce widget(popupbgcolor)] \
                            -class [ossweb::coalesce widget(class) osswebLink]]
        if { [info exists widget(pad)] } {
          append output [string repeat "&nbsp;" $widget(pad)]
        }
        return $output
     }
    }
    return
}

# Link widget for performing sorting on the columns
proc ossweb::widget::sorting { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(notab) 1
        set widget(optional) 1
        set widget(sort) [ns_queryget sort]
        set widget(desc) [ns_queryget desc]
     }

     readonly {
        return 1
     }

     get_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-return f} {-array ""} -- args } $args

        if { $return == "t" } {
          return
        }

        # Map is the variable that will hold sorting order, if only one value supplied,
        # use widget name as sorting column otherwise second field is real column name
        set map [ossweb::coalesce widget(map)]
        if { $map != "" && ($widget(name) == $widget(sort) || [info exists widget(default)]) } {
          if { $array != "" } {
            upvar #$level ${array}([lindex $map 0]) var
          } else {
            upvar #$level [lindex $map 0] var
          }
          set var "[ossweb::nvl [lindex $map 1] $widget(name)] $widget(desc)"
          # Default should be the first widget so actual widget will overwrite the map later
          ossweb::form $widget(form:id) -[lindex $map 0] $widget(name)
        }
        return 1
     }

     set_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-array ""} -- args } $args

        if { $array != "" } {
          upvar #$level ${array}(sort) vsort ${array}(desc) vdesc
        } else {
          upvar #$level sort vsort desc vdesc
        }
        # All sorting widgets will hold the same sorting criteria
        set widget(sort) [ossweb::coalesce vsort]
        set widget(desc) [ossweb::coalesce vdesc]
        return 1
     }

     html {
        if { [info exists widget(disabled)] } {
          return $widget(label)
        }
        # Default is command sort
        if { ![info exists widget(url)] } {
          set widget(url) [ossweb::html::url cmd sort]
        }
        if { ![info exists widget(class)] } {
          set widget(class) osswebSorting
        }
        # Toggle ascending/descending order
        set desc [ossweb::decode $widget(desc) "" desc ""]
        # Construct url with sorting parameters
        set output [ossweb::widget::link widget html sort $widget(name) desc $desc]
        # Add icon if we are currently selected
        set map [ossweb::form $widget(form:id) [lindex [ossweb::coalesce widget(map)] 0]]
        if { $widget(name) == $map } {
          append output [ossweb::html::image [ossweb::decode $widget(desc) "" up5.gif down5.gif]]
        }
        return $output
     }
    }
    return
}

proc ossweb::widget::text { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     readonly {
        set widget(type) inform
        if { $widget(value) == "" } {
          set widget(value) [ossweb::coalesce widget(null)]
        }
     }
     html {
        if { [info exists widget(resize)] } {
          append widget(resize) ",height=0"
          ossweb::widget $widget(widget:id) setresizable
        }
        ossweb::widget $widget(widget:id) setenter
        ossweb::widget $widget(widget:id) setautocomplete
        ossweb::widget $widget(widget:id) update_attr size [ossweb::coalesce widget(size) 25]
        set output "<INPUT TYPE=TEXT
                           CLASS=[ossweb::coalesce widget(class) osswebInput]
                           NAME=\"$widget(name)\"
                           VALUE=\"[ossweb::html::quote $widget(value)]\"
                           [ossweb::convert::list_to_attributes $widget(html)]>"
        if { [info exists widget(old)] } {
          append output "<INPUT TYPE=HIDDEN NAME=\"$widget(name):old\" VALUE=\"[ossweb::html::quote $widget(value)]\">"
        }
        return $output
     }
    }
    return
}

foreach type { integer float money ipaddr phone email } {
  eval "
  proc ossweb::widget::$type { widget_id command args } {
      upvar \$widget_id widget
      set widget(datatype) $type
      return \[uplevel ossweb::widget::text widget \$command \$args\]
  }"
}

proc ossweb::widget::popuptext { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     html:label {
       return [ossweb::html::link \
                    -image [ossweb::coalesce widget(image)] \
                    -width "" \
                    -height "" \
                    -align absbottom \
                    -text $widget(label) \
                    -class osswebFormLabel \
                    -css { text-decoration underline } \
                    -title "Edit $widget(label)" \
                    -url "javascript:popupShow('$widget(name)_popup',{focus:'$widget(name)'})"]
     }

     html {
        if { [info exists widget(resize)] } {
          append widget(resize) ",height=0"
          ossweb::widget $widget(widget:id) setresizable
        }
        ossweb::widget $widget(widget:id) setenter
        ossweb::widget $widget(widget:id) setautocomplete
        ossweb::widget $widget(widget:id) update_attr size [ossweb::coalesce widget(size) 25]
        set url [ossweb::widget $widget(widget:id) event:url]

        ossweb::widget $widget(widget:id) append_attr onKeyDown "if(event.keyCode==13){$widget(name)_proc(this);return false;}"
        ossweb::widget $widget(widget:id) append_attr onBlur "$widget(name)_proc(this)"


        return "<SPAN ID=$widget(name)_info CLASS=[ossweb::coalesce widget(class:info)]>$widget(value)</SPAN>

                <DIV ID=$widget(name)_popup CLASS=[ossweb::coalesce widget(class:popup) osswebPopupObj]>
                <DIV CLASS=osswebFormLabel STYLE=\"display:inline;\">Edit $widget(label)</DIV>
                <DIV STYLE=\"padding-left:5px;display:inline;\" onClick=\"javascript:pagePopupClose({name:'$widget(name)_popup'})\"><IMG SRC=/img/close2.gif TITLE=Close></DIV>
                <BR><BR>
                <SCRIPT>
                function $widget(name)_proc(obj)
                {
                   var opts = {show:0,name:'$widget(name)_popup'};
                   if(obj.value != varGet('$widget(name)_info')) {
                     varSet('$widget(name)_info',obj.value);
                     pagePopupGet('$url&$widget(name)='+escape(obj.value),opts)
                   }
                   pagePopupClose(opts)
                }
                </SCRIPT>
                <INPUT TYPE=TEXT
                       CLASS=[ossweb::coalesce widget(class) osswebInput]
                       NAME=\"$widget(name)\"
                       VALUE=\"[ossweb::html::quote $widget(value)]\"
                       [ossweb::convert::list_to_attributes $widget(html)]>
                </DIV>"
     }
    }
    return
}


proc ossweb::widget::textarea { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
     }

     readonly {
        ossweb::widget::text $widget_id $command
        return 1
     }

     html {
        switch [ossweb::coalesce widget(onenter)] {
         submit {
           ossweb::widget $widget(widget:id) append_attr onKeyPress "formSubmitOnEnter(event,this.form)"
         }
        }
        set class [ossweb::coalesce widget(class) osswebTextarea]
        if { [ossweb::coalesce widget(rich) 0] == 1 } {
          lappend class [ossweb::coalesce widget(class:rich) osswebRichEditor]
          ossweb::html::include "" -type tiny_mce -styles all -mode widget
        } else {
          ossweb::widget $widget(widget:id) setresizable
        }
        if { [info exists widget(wrap)] } {
          ossweb::widget $widget(widget:id) update_attr wrap $widget(wrap)
        }
        ossweb::widget $widget(widget:id) setautocomplete
        ossweb::widget $widget(widget:id) update_attr cols [ossweb::coalesce widget(cols) 30]
        ossweb::widget $widget(widget:id) update_attr rows [ossweb::coalesce widget(rows) 2]
        return "<TEXTAREA CLASS=\"$class\"
                          NAME=$widget(name)
                          [ossweb::convert::list_to_attributes $widget(html)]>[ossweb::html::quote $widget(value)]</TEXTAREA>"
     }
    }
    return
}

proc ossweb::widget::file { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
     }

     readonly {
        set widget(type) none
        return 1
     }

     script {
        # Progress report
        if { [info exists widget(progress)] } {
           set timeout [ossweb::coalesce progress:timeout 1000]
           set url [eval ossweb::html::url [ossweb::coalesce widget(progress:url)]]
           if { $url == "" } {
              set url [ossweb::html::url cmd progress]
           }

           set script "
               function onsubmit_$widget(name)(form) {
                 form.action += '[ossweb::coalesce widget(progress:key)]';
                 setTimeout($widget(name)_progress,$timeout);
                 return true;
               }
               function $widget(name)_progress() {
                 var now = new Date();
                 var a = document.createElement('a');
                 a.href = document.$widget(form:id).action;
                 pagePopupSend('$url&key='+escape(a.pathname+a.search)+'&t='+now.getTime(),0,function(data) {
                   if(data!='') {
                     varSet('percent_$widget(name)',data+'%');
                     varStyle('bar_$widget(name)','width',parseInt(data)+'%');
                     varStyle('bar_$widget(name)','height',20);
                     varStyle('bar_$widget(name)','border','1px solid #efefef');
                     setTimeout($widget(name)_progress,$timeout);
                   }
                 });
               }"

           ossweb::form $widget(form:id) -html [list onsubmit "return onsubmit_$widget(name)(this);" ]
           ossweb::html::include javascript:$script

        }
     }

     html {
        if { [ossweb::widget $widget(widget:id) get_attr size] == "" } {
           ossweb::widget $widget(widget:id) set_attr size [ossweb::coalesce widget(size) 30]
        }

        return "<INPUT TYPE=FILE \
                       NAME=\"$widget(name)\" \
                       VALUE=\"[ossweb::html::quote $widget(value)]\" \
                       CLASS=[ossweb::coalesce widget(class) osswebInput] \
                       [ossweb::convert::list_to_attributes $widget(html)]> \
                       <DIV ID=bar_$widget(name) STYLE=\"margin-top:5px;height:0;width:0;background-color:#000000;\">
                       <DIV ID=percent_$widget(name) STYLE=\"color:#fff;float:right;\"></DIV>
                       </DIV>"
     }
    }
    return
}

proc ossweb::widget::filelink { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        if { [ns_queryexists $widget(name)] } {
          set widget(value) [ns_queryget $widget(name)]
        }
        if { $widget(value) == "" } {
          set widget(value) [ns_queryget $widget(name).oldfile]
        }
        return 1
     }

     html {
        set value [ossweb::file::name $widget(value)]
        if { [info exists widget(url)] } {
          set value "<A HREF=\"$widget(url)\" CLASS=[ossweb::coalesce widget(class) osswebLink] [ossweb::convert::list_to_attributes [ossweb::coalesce widget(html2)]] style=\"text-decoration: none;\">$value</A>"
        }
        append value "<INPUT TYPE=HIDDEN NAME=\"$widget(name).oldfile\" VALUE=\"$widget(value)\">"
        if { ![info exists widget(noupload)] } {
          set class [ossweb::coalesce widget(class) osswebButton]
          return "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
                  <TR><TD><B>$value</B></TD></TR>
                  <TR><TD><INPUT TYPE=FILE \
                                 NAME=\"$widget(name)\" \
                                 CLASS=$class \
                                 [ossweb::convert::list_to_attributes $widget(html)] \
                                 onMouseOver=\"this.className='${class}Over'\" \
                                 onMouseOut=\"this.className='$class'\" ></TD></TR>
                  </TABLE>"
        } else {
          return "<B>$value</B>"
        }
     }
    }
    return
}

proc ossweb::widget::hidden { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     html {
        return "<INPUT TYPE=HIDDEN NAME=\"$widget(name)\" VALUE=\"[ossweb::html::quote $widget(value)]\">"
     }
    }
    return
}

proc ossweb::widget::password { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
     }
     readonly {
        set widget(type) inform
        set widget(value) ***
        return 1
     }
     html {
        if { [info exists widget(autotab)] && $widget(autotab) > 1} {
          ossweb::widget $widget(widget:id) append_attr onKeyUp "formAutoTab(this,$widget(autotab),event);"
        }
        ossweb::widget $widget(widget:id) update_attr size [ossweb::coalesce widget(size) 25]
        set output "<INPUT TYPE=PASSWORD CLASS=[ossweb::coalesce widget(class) osswebInput] NAME=\"$widget(name)\" VALUE=\"[ossweb::html::quote $widget(value)]\" [ossweb::convert::list_to_attributes $widget(html)]>"
        if { [info exists widget(old)] } {
          append output "<INPUT TYPE=HIDDEN NAME=\"$widget(name):old\" VALUE=\"[ossweb::html::quote $widget(value)]\">"
        }
        return $output
     }
    }
    return
}

# Widget for HTML image form widget
proc ossweb::widget::image { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
        return 1
     }

     html {
        if { [ossweb::widget $widget(widget:id) set_attr border] == "" } {
          ossweb::widget $widget(widget:id) set_attr border 0
        }
        set value [ossweb::image_name $widget(value)]
        set over [ossweb::image_name [ossweb::coalesce widget(over)]]
        if { $over != "" } {
          ossweb::widget $widget(widget:id) set_attr onMouseOver "this.src='$over'"
          ossweb::widget $widget(widget:id) set_attr onMouseOut "this.src='$value'"
        }
        set onClick [ossweb::widget $widget(widget:id) setevent]
        set output "<INPUT TYPE=IMAGE \
                           CLASS=[ossweb::coalesce widget(class) osswebImage] \
                           NAME=\"$widget(name)\" \
                           SRC=\"$value\" [ossweb::convert::list_to_attributes $widget(html)] \
                           $onClick>"
        # If title is given, show it above the image
        if { [set title [ossweb::coalesce widget(title)]] != "" } {
          set class [ossweb::coalesce widget(title_class) osswebContent]
          set output "<DIV CLASS=$class>$title<BR>$output</DIV>"
        }
        return $output
     }
    }
    return
}

proc ossweb::widget::button { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
     }

     readonly {
       if { [ossweb::coalesce widget(buttons)] == "t" } {
         set widget(type) none
       }
       return 1
     }

     check {
        # Check if we have hidden field cmd declared already, if not add it
        if { [info exists widget(cmd_name)] && ![ossweb::widget $widget(form:id).cmd exists] } {
          ossweb::widget $widget(form:id).cmd -type hidden -optional
        }
     }

     html {
        if { [info exists widget(small)] } {
          set class osswebSmallButton
        } else {
          set class [ossweb::coalesce widget(class) osswebButton]
        }
        set onClick [ossweb::widget $widget(widget:id) setevent]
        ossweb::widget $widget(widget:id) append_attr onMouseOver "this.className='${class}Over';"
        ossweb::widget $widget(widget:id) append_attr onMouseOut "this.className='$class';"
        return "<INPUT TYPE=[ossweb::coalesce widget(type:html) $widget(type)]
                       NAME=\"$widget(name)\" \
                       VALUE=\"[ossweb::html::quote $widget(label)]\" \
                       CLASS=$class \
                       [ossweb::convert::list_to_attributes $widget(html)] \
                       [ossweb::convert::list_to_attributes $args] \
                       $onClick>&nbsp;"
     }
    }
    return
}

proc ossweb::widget::submit { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
        # To prevent double submits in case of -cmd_name present
        set widget(submit) ";"
     }

     default {
        return [uplevel ossweb::widget::button $widget_id $command $args]
     }
    }
}

proc ossweb::widget::reset { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
     }

     readonly {
       if { [ossweb::coalesce widget(buttons)] == "t" } {
         set widget(type) none
       }
       return 1
     }

     html {
        set html ""
        if { [info exists widget(clear)] } {
          set skip [ossweb::coalesce widget(skip)]
          set match [ossweb::coalesce widget(match)]
          set html "onClick=\"return formClear(this.form,'$match','$skip')\""
        }
        if { [info exists widget(small)] } {
          set class osswebSmallButton
        } else {
          set class [ossweb::coalesce widget(class) osswebButton]
        }
        return "<INPUT TYPE=RESET NAME=\"$widget(name)\" \
                       VALUE=\"[ossweb::html::quote $widget(label)]\" \
                       [ossweb::convert::list_to_attributes $widget(html)] \
                       onMouseOver=\"this.className='${class}Over'\" \
                       onMouseOut=\"this.className='$class'\" \
                       CLASS=$class \
                       $html>&nbsp;"
     }
    }
    return
}

proc ossweb::widget::checkbox { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        if { [ns_queryexists $widget(name)] } {
          set widget(values) [ns_querygetall $widget(name)]
        }
        if { [string equal $widget(values) {{}}] } {
          set widget(values) ""
        }
        # Autocheck on create
        if { $widget(value) != "" && $widget(value) == $widget(values) } {
          set widget(checked) 1
        }
        return 1
     }

     readonly {
        ossweb::widget $widget(widget:id) setoptions
        set optsize [llength $widget(options)]
        if { [info exists widget(labelselect)] } {
          set widget(type) labelselect
        } else {
          set widget(type) inform
          if { [ossweb::true [ossweb::coalesce widget(checked)]] && $optsize <= 1 } {
            set widget(value) [ossweb::html::image checked.gif -width "" -height ""]
          } else {
            set widget(value) ""
            for { set i 0 } { $i < $optsize } { incr i } {
              set option [lindex $widget(options) $i]
              if { [lsearch -exact $widget(values) [lindex $option 1]] > -1 } {
                lappend widget(value) [lindex $option 0]
              }
            }
            if { $widget(value) == "" } {
              set widget(type) none
            }
          }
        }
        return 1
     }

     set_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-array ""} -- args } $args
        upvar #$level $widget(name) value
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) var
        } else {
          upvar #$level $widget(name) var
        }
        if { [info exists var] } {
          if { $widget(value) == $var } {
            set widget(checked) 1
          }
          set widget(values) $var
        }
        return 1
     }

     get_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-return f} {-array ""} -- args } $args
        if { $return == "t" } {
          return $widget(values)
        }
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) var
        } else {
          upvar #$level $widget(name) var
        }
        set var $widget(values)
        return 1
     }

     html {
        if { [info exists widget(onChange)] } {
          ossweb::widget $widget(widget:id) set_attr onChange $widget(onChange)
        }
        # Process javascript handlers
        ossweb::widget $widget(widget:id) setevent -html t

        if { [info exists widget(autotab)] } {
          ossweb::widget $widget(widget:id) append_attr onClick "formAutoTab(this);"
        }
        ossweb::widget $widget(widget:id) setoptions
        set output "<INPUT TYPE=CHECKBOX
                           CLASS=[ossweb::coalesce widget(class) osswebCheckbox]
                           NAME=\"$widget(name)\"
                           [ossweb::convert::list_to_attributes $widget(html)]"
        # Already checked or runtime check has been requested
        if { [ossweb::coalesce widget(checked)] == 1 ||
             ([info exists widget(check)] && $widget(value) eq $widget(values)) } {
          append output " CHECKED "
        }
        append output " VALUE=\"[ossweb::html::quote $widget(value)]\" >"
        return $output
     }
    }
    return
}

proc ossweb::widget::radio { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        if { [ns_queryexists $widget(name)] } {
          set widget(values) [ns_querygetall $widget(name)]
        }
        if { [string equal $widget(values) {{}}] } {
          set widget(values) ""
        }
        # Autocheck on create
        if { $widget(value) != "" && $widget(value) == $widget(values) } {
          set widget(checked) 1
        }
        return 1
     }

     readonly {
        ossweb::widget $widget(widget:id) setoptions
        if { [info exists widget(labelselect)] } {
          set widget(type) labelselect
        } else {
          if { [ossweb::true [ossweb::coalesce widget(checked)] && [llength $widget(options)] <= 1] } {
            set widget(type) inform
            set widget(value) [ossweb::html::image checked.gif -width "" -height ""]
          } else {
            foreach options $widget(options) {
              if { [lsearch -exact $widget(value) [lindex $option 1]] > -1 } {
                set widget(type) inform
                set widget(value) [lindex $option 0]
                return
              }
            }
            set widget(type) none
          }
        }
        return 1
     }

     get_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-return f} {-array ""} -- args } $args
        if { $return == "t" } {
          return $widget(values)
        }
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) var
        } else {
          upvar #$level $widget(name) var
        }
        set var $widget(values)
        return 1
     }

     set_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-array ""} -- args } $args
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) var
        } else {
          upvar #$level $widget(name) var
        }
        if { [info exists var] } {
          if { $widget(value) == $var } {
            set widget(checked) 1
          }
          set widget(values) $var
        }
        return 1
     }

     html {
        if { [info exists widget(onChange)] } {
          ossweb::widget $widget(widget:id) set_attr onChange $widget(onChange)
        }
        # Process javascript handlers
        ossweb::widget $widget(widget:id) setevent -html t

        if { [info exists widget(autotab)] } {
          ossweb::widget $widget(widget:id) append_attr onClick "formAutoTab(this);"
        }
        ossweb::widget $widget(widget:id) setoptions
        set output "<INPUT TYPE=RADIO
                           CLASS=[ossweb::coalesce widget(class) osswebRadio]
                           NAME=\"$widget(name)\"
                           [ossweb::convert::list_to_attributes $widget(html)]"
        # Already checked or runtime check has been requested
        if { [ossweb::coalesce widget(checked)] == 1 ||
             ([info exists widget(check)] && $widget(value) eq $widget(values)) } {
          append output " CHECKED "
        }
        append output " VALUE=\"[ossweb::html::quote $widget(value)]\" >"
        return $output
     }
    }
    return
}

proc ossweb::widget::boolean { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        # Put special empty value at the first position
        if { [info exists widget(empty)] } {
          set widget(options) [linsert $widget(options) 0 [list $widget(empty) ""]]
        }
     }

     readonly {
        if { [ossweb::true $widget(value)] } {
          set widget(value) Yes
        } else {
          set widget(value) No
        }
        set widget(type) inform
        return 1
     }
     html {
        set widget(options) { { No f N F FALSE 0 } { Yes t Y T TRUE 1 } }
        set widget(value) [string toupper $widget(value)]
        return [eval select widget $command $args]
     }
    }
}

proc ossweb::widget::yesno { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     readonly {
        return [eval boolean widget $command $args]
     }

     html {
        if { [info exists widget(onChange)] } {
          ossweb::widget $widget(widget:id) set_attr onChange $widget(onChange)
        }
        # Process javascript handlers
        ossweb::widget $widget(widget:id) setevent -html t

        set output "<INPUT TYPE=RADIO
                           CLASS=[ossweb::coalesce widget(class) osswebRadio]
                           NAME=\"$widget(name)\"
                           [ossweb::convert::list_to_attributes $widget(html)]
                           [ossweb::decode [ossweb::coalesce widget(value)] t CHECKED ""]
                           VALUE=\"t\" > Yes
                    <INPUT TYPE=RADIO
                           CLASS=[ossweb::coalesce widget(class) osswebRadio]
                           NAME=\"$widget(name)\"
                           [ossweb::convert::list_to_attributes $widget(html)]
                           [ossweb::decode [ossweb::coalesce widget(value)] t "" CHECKED]
                           VALUE=\"f\" > No"
        return $output
     }
    }
}

proc ossweb::widget::howto { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
     }

     html {
        set js ""
        set result ""
        set prefix [ossweb::coalesce widget(prefix)]
        set suffix [ossweb::coalesce widget(br) "<BR>"]
        set div [ossweb::coalesce widget(div) pagePopupObj]
        set close [ossweb::coalesce widget(close) 1]
        set rewrite [ossweb::coalesce widget(rewrite)]
        set params [ossweb::coalesce widget(params) show:1]
        set class [ossweb::coalesce widget(class) osswebLink]
        for { set idx 0 } { $idx < [llength $widget(options)] } { incr idx } {
          set rec [lindex $widget(options) $idx]
          set title [lindex $rec 0]
          set text [lindex $rec 1]
          set type [lindex $rec 2]
          set data [string map { "\r" {} "\n" {} ' {} } $text]
          # Convert pure url into proxy requests
          if { [regexp {^/|^https?://} $data] } {
            set data [ossweb::html::proxy_url $data -type $type -rewrite $rewrite]
          }
          append js "HowTo_$widget(id)\[$idx\] = '$data';\n"
          append result "$prefix<A HREF=\"javascript:;\" onClick=\"pagePopupGet(HowTo_$widget(id)\[$idx\],{name:'$div',local:1,close:$close,$params});\">$title</A>$suffix"
        }
        append result "<SCRIPT>var HowTo_$widget(id) = new Array();\n$js</SCRIPT>"
        return $result
     }
    }
    return
}

proc ossweb::widget::select { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     readonly {
        set widget(force) 1
        ossweb::widget $widget(widget:id) setoptions
        set widget(type) labelselect
        return 1
     }

     optional {
        set widget(empty) [ossweb::nvl $args "--"]
        return 1
     }

     html {
        ossweb::widget $widget(widget:id) setresizable
        ossweb::widget $widget(widget:id) setoptions
        # Put special empty value at the first position
        if { [info exists widget(empty)] } {
          set options [linsert $widget(options) 0 [list $widget(empty) ""]]
        } else {
          set options $widget(options)
        }
        # Process javascript handlers
        ossweb::widget $widget(widget:id) setevent -name onChange -html t

        if { [info exists widget(autotab)] } {
          ossweb::widget $widget(widget:id) append_attr onChange "formAutoTab(this);"
        }
        ossweb::widget $widget(widget:id) update_attr size [ossweb::coalesce widget(size) 1]
        ossweb::widget $widget(widget:id) update_attr class [ossweb::coalesce widget(class) osswebSelect]
        set output [ossweb::html::select $widget(name) $options [list $widget(value)] $widget(html)]
        if { [info exists widget(old)] } {
          append output "<INPUT TYPE=HIDDEN NAME=\"$widget(name):old\" VALUE=\"[ossweb::html::quote $widget(value)]\">"
        }
        return $output
     }
    }
    return
}

proc ossweb::widget::combobox { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     readonly {
        ossweb::widget::text widget $command
        return 1
     }
     html {
        ossweb::widget $widget(widget:id) setoptions
        set onClick [ossweb::coalesce widget(onClick)]
        set onChange [ossweb::coalesce widget(onChange)]
        set class [ossweb::coalesce widget(class:options) osswebCombobox]
        set textwidget [ossweb::coalesce widget(textwidget) text]
        ossweb::widget $widget(widget:id) append_attr onFocus "ddHideMenu('$widget(name)_cb',this,event);"
        # This is combobox value setter
        set comboSet formComboboxSet
        if { [info exists widget(append)] } {
          set comboSet formComboboxAppend
        }
        # Special case for dynamically updated comboboxes, url will be called
        # on icon click and will submit specified url for data
        set url [ossweb::coalesce widget(url)]
        if { $url != "" } {
          set empty [info exists widget(empty)]
          append onClick ";formComboboxUpdate('$widget(name)','$url',$empty);"
        }
        if { [info exists widget(autotab)] } {
          append onChange ";formAutoTab(document.forms\[$widget(form:id)\].elements\[$widget(name)\]);"
        }
        set html ""
        # Explicit width of the widget and popup table
        if { [set width [ossweb::coalesce widget(width)]] != "" } {
          lappend widget(html) style "width:$width;"
          append html "STYLE=\"width:$width;\""
        }
        append onClick "ddToggle('$widget(name)_cb','$widget(name)',event);"
        append output "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>"
        append output "<TR><TD>[ossweb::widget::$textwidget widget html]</TD>"
        append output "<TD><IMG SRC=/img/[ossweb::coalesce widget(image) down4.gif] BORDER=0 ALIGN=BOTTOM onClick=\"$onClick;\"></TD>"
        append output "</TR></TABLE>"
        append output [ossweb::html::combobox_menu $widget(name) $widget(options) -iframe t -class $class -onClick $comboSet -onChange $onChange -html $html]
        return $output
     }
    }
    return
}

proc ossweb::widget::popupbutton { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
        set widget(type:html) button
        return [ossweb::widget::button widget create]
     }

     readonly {
       if { [ossweb::coalesce widget(buttons)] == "t" } {
         set widget(type) none
       }
       return 1
     }

     html {
        set name $widget(name)_popup
        set class [ossweb::coalesce widget(class:options) osswebPopup]
        ossweb::widget $widget(widget:id) set_attr onClick "ddShowMenu('${name}_pp',this,event);" \
                                                   onMouseOver "ddKeep(\$('${name}_pp'));" \
                                                   onMouseOut "ddHideMenu('${name}_pp',this,event);"
        if { [info exists widget(auto)] } {
          ossweb::widget $widget(widget:id) set_attr onMouseOver "ddShowMenu('${name}_pp',this,event);"
        }
        set output [ossweb::widget::button widget html]
        append output [ossweb::html::popup_menu $name $widget(options) -class $class]
        return $output
     }
    }
    return
}

proc ossweb::widget::helpbutton { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        set widget(optional) 1
        if { $widget(name) == $widget(label) } { set widget(label) Help }
     }
     readonly {
       if { [ossweb::coalesce widget(buttons)] == "t" } {
         set widget(type) none
       }
       return 1
     }
     html {
       set class [ossweb::coalesce widget(class) osswebButton]
       set width [ossweb::coalesce widget(class) 600]
       set height [ossweb::coalesce widget(class) 500]
       set winopts [ossweb::coalesce widget(winopts) "width=$width,height=$height,toolbar=0,menubar=0,scrollbars=1,resizable=1"]
       if { [set url [ossweb::coalesce widget(url)]] == "" } {
         set url [ossweb::html::url -app_name main help \
                       project_name [ossweb::conn project_name] \
                       app_name [ossweb::conn app_name] \
                       page_name [ossweb::coalesce widget(page_name) [ossweb::conn page_name]] \
                       cmd_name [ossweb::coalesce widget(cmd_name) [ossweb::conn cmd_name]] \
                       ctx_name [ossweb::coalesce widget(ctx_name) [ossweb::conn ctx_name]]]
       }
       return "<INPUT TYPE=BUTTON
                      NAME=\"$widget(name)\"
                      TITLE=\"Show popup window with help\" \
                      VALUE=\"[ossweb::html::quote $widget(label)]\" \
                      CLASS=$class \
                      onMouseOver=\"this.className='${class}Over'\" \
                      onMouseOut=\"this.className='$class'\" \
                      onClick=\"window.open('$url','HelpWin','$winopts')\">"
     }
    }
    return
}

proc ossweb::widget::multiselect { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     create {
        if { [ns_queryexists $widget(name)] } {
          set widget(value) [ns_querygetall $widget(name)]
        }
        if { [string equal $widget(values) {{}}] } { set widget(values) "" }
        return 1
     }
     readonly {
        set widget(type) labelselect
        return 1
     }
     html {
        ossweb::widget $widget(widget:id) setresizable
        ossweb::widget $widget(widget:id) setoptions
        lappend widget(html) multiple ""

        # Process javascript handlers
        ossweb::widget $widget(widget:id) setevent -name onChange -html t

        # Determine the size automatically for a multiselect
        if { [ossweb::widget $widget(widget:id) get_attr size] == "" } {
          set size [llength $widget(options)]
          if { $size > 8 } {
            set size 8
          }
          ossweb::widget $widget(widget:id) set_attr size [ossweb::coalesce widget(size) $size]
        }
        lappend widget(html) class [ossweb::coalesce widget(class) osswebSelect]
        return [ossweb::html::select $widget(name) $widget(options) $widget(value) $widget(html)]
     }
    }
    return
}

# Converts select widget into label widget if value is selected or
# converts select widget into label widget if there is only one option
# and this option is equal to the value ( -only_one specified )
proc ossweb::widget::labelselect { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     html {
        ossweb::widget $widget(widget:id) setoptions
        if { [set value $widget(value)] != "" } {
          foreach item $widget(options) {
            if { $value == [lindex $item 1] } {
              set widget(title) [lindex $item 0]
            }
          }
        } else {
          if { [info exists widget(empty)] } {
            set widget(title) $widget(empty)
          }
        }
        if { ([info exists widget(only_one)] && [llength $widget(options)] == 1) ||
             [info exists widget(force)] ||
             [info exists widget(title)] } {
          return [eval ossweb::widget::label widget $command $args]
        }
        return [eval ossweb::widget::select widget $command $args]
     }
    }
    return
}

proc ossweb::widget::lookup { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     readonly {
        set widget(value) $widget(title)
        set widget(js:property) {osswebClear 1}
        ossweb::widget::text widget $command
        return 1
     }

     create {
        if { ![info exists widget(title_name)] } {
          set widget(title_name) $widget(name)_title
        }
        if { [ns_queryexists $widget(name)] } {
          set widget(value) [string trim [ns_queryget $widget(name)]]
        }
        if { ![info exists widget(title)] } {
          set widget(title) ""
        }
        if { [ns_queryexists $widget(title_name)] } {
          set widget(title) [string trim [ns_queryget $widget(title_name)]]
        }
        if { [ossweb::coalesce widget(title)] == "" && $widget(value) != "" } {
          set widget(title) $widget(value)
        }
        return 1
     }

     save {
        return [list $widget(value) $widget(title)]
     }

     restore {
        set widget(value) [lindex $args 0]
        set widget(title) [lindex $args 1]
        return 1
     }

     reset {
        set widget(value) ""
        set widget(title) ""
     }

     set_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-array ""} -- args } $args
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) value ${array}($widget(title_name)) title
        } else {
          upvar #$level $widget(name) value $widget(title_name) title
        }
        if { [info exists value] } {
          set widget(value) $value
        }
        if { [info exists title] } {
          set widget(title) $title
        }
        return 1
     }

     get_value {
        ns_parseargs { {-level {[expr [info level]-2]}} {-array ""} -- args } $args
        if { $array != "" } {
          upvar #$level ${array}($widget(name)) value ${array}($widget(title_name)) title
        } else {
          upvar #$level $widget(name) value $widget(title_name) title
        }
        set value $widget(value)
        set title $widget(title)
        return 1
     }

     validate {
        if { [info exists widget(title_required)] && $widget(title) == "" } {
          return "value is required"
        }
        if { ![info exists widget(optional)] && $widget(value) == [ossweb::coalesce widget(null) NULL] } {
          return "value is required"
        }
     }

     html {
        set name $widget(name)
        set value $widget(value)
        set title_name $widget(title_name)
        set search_name [ossweb::coalesce widget(search_name) $title_name]
        set search_text [ossweb::coalesce widget(search_text) $title_name]
        set title [ossweb::coalesce widget(title) $value]
        set url [eval ossweb::widget $widget(widget:id) event:url $args]
        set mode [ossweb::coalesce widget(mode) 1]
        set null NULL
        if { [info exists widget(null)] } {
          set null $widget(null)
        }
        set id "$widget(form:id)_$title_name"
        # Table width
        if { [set width [ossweb::widget $widget(widget:id) get_attr size]] != "" } {
          set width [expr $width*4]
        } else {
          set width [expr 30*4]
        }
        set output "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0><TR VALIGN=TOP><TD>\n"
        if { $name != $title_name } {
          append output "<INPUT TYPE=HIDDEN NAME=$name ID=$name VALUE=\"[ossweb::html::quote $value]\">"
        }
        # Object ID should be as title name
        ossweb::widget $widget(widget:id) set_attr ID $title_name
        # What kind of widget control to use
        foreach type { div readonly text select multiselect "" } {
          if { [info exists widget($type)] } {
            break
          }
        }
        switch $type {
         text {
            # Automatically assign value to lookup hidden field
            if { [info exists widget(autocomplete)] &&
                 ![info exists widget(autocomplete_value)] &&
                 ![info exists widget(autocomplete_fields)] } {
              set widget(autocomplete_value) $name
            }
            set widget(name) $title_name
            set widget(value) $title
            append output [$type $widget_id html]
            set widget(value) $value
            set widget(name) $name
         }
         select -
         multiselect {
            set widget(name) $title_name
            append output [$type $widget_id html]
            set widget(name) $name
         }
         readonly {
            return "<B>[ossweb::nvl $title &nbsp;]</B>"
         }
         default {
            append output "<INPUT TYPE=HIDDEN NAME=$title_name ID=$title_name VALUE=\"[ossweb::html::quote $title]\">\n
                           <TABLE BORDER=1 CELLSPACING=0 CELLPADDING=0 HEIGHT=12 WIDTH=$width CLASS=[ossweb::coalesce widget(class) osswebInput]>
                           <TR><TD><DIV HEIGHT=12 WIDTH=$width ID=$id>[ossweb::nvl $title]</DIV></TD></TR>
                           </TABLE>\n"
         }
        }
        append output "</TD><TD NOWRAP>"
        if { [info exists widget(cmd_name)] } {
          set url "this.form.cmd.value='$widget(cmd_name)';this.form.submit()"
        }
        # if it is not plain url, then we do not support internal lookup,
        # developer is trying to use the widget in it own way
        if { [regexp {^/|^http.://} $url] } {
          append url "&lookup:mode=$mode"
          switch $mode {
           2 {
             if { [info exists widget(autotab)] } {
               append widget(proc) ";window.opener.formAutoTab(window.opener.document.$widget(form:id).$title_name);"
             }
             foreach key { map proc append } {
               if { [info exists widget($key)] } {
                 append url "&lookup:$key=[ossweb::html::escape $widget($key)]"
               }
             }
             # Add text field value for search
             switch $type {
              text {
                append url "&$search_name='+escape(formGet(document.$widget(form:id).$search_text))+'"
              }
              "" {
                append url "&lookup:div=[ossweb::html::escape $id]"
              }
             }
             set url "var w=window.open('$url','Lookup$name','[ossweb::lookup::property winopts]');w.focus()"
           }

           5 {
             append url "&lookup:popup=${id}_pp"
             if { [info exists widget(autotab)] } {
               append widget(proc) ";formAutoTab(document.$widget(form:id).$search_text);"
             }
             foreach key { map proc append } {
               if { [info exists widget($key)] } {
                 append url "&lookup:$key=[ossweb::html::escape $widget($key)]"
               }
             }
             # Add text field value for search
             switch $type {
              text {
                append url "&$search_name='+escape(formGet(document.$widget(form:id).$search_text))+'"
              }
              "" {
                append url "&lookup:div=[ossweb::html::escape $id]"
              }
             }
             set popupopts [ossweb::coalesce widget(popupopts)]
             if { [info exists widget(popupdnd)] } { append popupopts "dnd:$widget(popupdnd)" }
             if { [info exists widget(popupname)] } { append popupopts "name:'$widget(popupname')" }
             if { [info exists widget(popupdata)] } { append popupopts "data:'$widget(popupdata')" }
             if { [info exists widget(popuptop)] } { append popupopts "top:$widget(popuptop)" }
             if { [info exists widget(popupleft)] } { append popupopts "left:$widget(popupleft)" }
             if { [info exists widget(popupwidth)] } { append popupopts "width:'$widget(popupwidth)'" }
             if { [info exists widget(popupheight)] } { append popupopts "width:'$widget(popupheight)'" }
             if { [info exists widget(popupbgcolor)] } { append popupopts "bgcolor:'$widget(popupbgcolor)'" }
             append popupopts ",parent:'$id',close:1,name:'${id}_pp'"

             set url "pagePopupGet('$url',{[string trim $popupopts ,]})"
             append output "<DIV ID=${id}_pp CLASS=osswebPopupObj></DIV>"
           }

           default {
             if { [info exists widget(redirect)] } {
               set mode 3
             }
             if { [info exists widget(start)] } {
               append url "&lookup:start=[ossweb::html::escape $widget(start)]"
             }
             set return [ossweb::coalesce widget(return) [ossweb::conn page_name]]
             append url "&lookup:return=[ossweb::html::escape $return]"
             # Add text field value for search
             switch $type {
              text {
                set url "'$url&$search_name='+escape(formGet(document.$widget(form:id).$title_name))"
              }
              default {
                set url "'$url'"
              }
             }
             set url "window.location=$url;return false;"
           }
          }
        }
        set class [ossweb::coalesce widget(class) osswebSmallButton]
        if { ![ossweb::coalesce widget(nofindbutton) 0] } {
          if { [info exists widget(icons)] || [info exists widget(image)] } {
            set image [ossweb::image_name [ossweb::coalesce widget(image) search.gif]]
            append output "<A HREF=javascript:; \
                              TITLE=\"Find new value\" \
                              onClick=\"this.form=document.$widget(form:id);$url\" \
                              NAME=${name}_find><IMG SRC=\"$image\" CLASS=[ossweb::coalesce widget(class) osswebImage]></A>"
          } else {
            append output "<INPUT TYPE=BUTTON \
                                  CLASS=$class \
                                  NAME=\"${name}_find\" \
                                  TITLE=\"Find new value\" \
                                  onMouseOver=\"this.className='${class}Over'\" \
                                  onMouseOut=\"this.className='$class'\" \
                                  VALUE=\"Find\" \
                                  onClick=\"$url\">"
          }
        }
        if { ![ossweb::coalesce widget(noclearbutton) 0] } {
          if { [info exists widget(icons)] || [info exists widget(clear_image)] } {
            set image [ossweb::image_name [ossweb::coalesce widget(clear_image) clear.gif]]
            append output "<A HREF=javascript:; \
                              TITLE=\"Clear current value\" \
                              onClick=\"this.form=document.$widget(form:id);this.form.$name.value='$null';this.form.$title_name.value='';varSet('$widget(form:id)_$title_name','')\" \
                              NAME=${name}_clear><IMG SRC=\"$image\" CLASS=[ossweb::coalesce widget(class) osswebImage]></A>"
          } else {
            append output "<INPUT TYPE=BUTTON \
                                  CLASS=$class \
                                  NAME=\"${name}_clear\" \
                                  TITLE=\"Clear current value\" \
                                  onMouseOver=\"this.className='${class}Over'\" \
                                  onMouseOut=\"this.className='$class'\" \
                                  VALUE=\"Clear\" \
                                  onClick=\"this.form.$name.value='$null';this.form.$title_name.value='';varSet('$widget(form:id)_$title_name','')\">"
            }
        }
        append output "</TD></TR></TABLE>\n"
        return $output
     }
    }
    return
}

# User lookup widget
proc ossweb::widget::user_lookup { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     readonly {
       set widget(type) label
       return 1
     }

     create {
       set app_name [ossweb::coalesce widget(app_name) users]
       if { ![info exists widget(title_name)] } {
         set widget(title_name) [regsub {_id$} $widget(name) {}]_name
       }
       set widget(search_name) full_name
       set widget(mode) 2
       set widget(map) "$widget(form:id).$widget(name) user_id $widget(form:id).$widget(title_name) full_name"
       set widget(url) [eval ossweb::html::url -app_name admin $app_name cmd search [ossweb::coalesce widget(url_params)]]
       if { [ossweb::coalesce widget(autocomplete)] == 1 } {
         set widget(autocomplete) [ossweb::html::url -app_name admin $app_name cmd ac full_name ""]
         set widget(autocomplete_value) $widget(name)
       }
     }
    }
    return [uplevel ossweb::widget::lookup widget $command $args]
}

# User email lookup widget
proc ossweb::widget::email_lookup { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     readonly {
       set widget(type) label
       return 1
     }

     create {
       set app_name [ossweb::coalesce widget(app_name) users]
       set widget(title_name) $widget(name)
       set widget(search_name) email_search
       set widget(mode) 2
       set widget(append) ","
       set widget(map) "$widget(form:id).$widget(name) user_email"
       set widget(url) [eval ossweb::html::url -app_name admin $app_name cmd search [ossweb::coalesce widget(url_params)]]
       if { [ossweb::coalesce widget(autocomplete)] == 1 } {
         set widget(autocomplete) [ossweb::html::url -app_name admin $app_name cmd ac ac:email 1 email_search ""]
         set widget(autocomplete_proc) "function(o,v){formAppend(o,v.value,',',1)}"
       }
     }

     html {
       ossweb::widget $widget(widget:id) setautocomplete
     }
    }
    return [uplevel ossweb::widget::lookup widget $command $args]
}

# Employee lookup widget
proc ossweb::widget::employee_lookup { widget_id command args } {

    upvar $widget_id widget

    set widget(app_name) employees
    return [uplevel ossweb::widget::user_lookup widget $command $args]
}

# Select box with images and optional runtime image rendering
proc ossweb::widget::imageselect { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     html {
        set path [ossweb::coalesce widget(path)]
        set widget(options) [ossweb::html::images $path]
        if { [info exists widget(show)] } {
          set img $widget(id)_img
          set width [ossweb::coalesce widget(width)]
          set height [ossweb::coalesce widget(height)]
          lappend widget(html) onChange "document.images\['$img'\].src=(this.selectedIndex>0 && document.images\['$img'\]) ? '[ossweb::nvl $path [ossweb::config server:path:images /img]]/'+this.options\[this.selectedIndex\].value : '/img/b.gif';"
          set output "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0><TR VALIGN=TOP>"
          append output "<TD>[ossweb::widget::select widget $command $args]</TD>"
          append output "<TD WIDTH=20>&nbsp;</TD>"
          append output "<TD>[ossweb::html::image [ossweb::nvl $widget(value) b.gif] -name "$img" -width $width -height $height]</TD>"
          append output "</TR></TABLE>"
          return $output
        } else {
          return [ossweb::widget::select widget $command $args]
        }
     }
    }
    return
}

# Select box with sound files and button to test it
proc ossweb::widget::soundselect { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     readonly {
        set widget(type) inform
        return 1
     }
     html {
        set widget(options) [ossweb::html::sounds [ossweb::coalesce widget(path)]]
        set output "
        <SCRIPT LANGUAGE=JavaScript>
        function doSound() {
          if(document.$widget(form:id).$widget(name).selectedIndex > 0)
            window.open('[ossweb::conn::hostname][ossweb::config server:path:sound "/snd"]/'+document.$widget(form:id).$widget(name).options\[document.$widget(form:id).$widget(name).selectedIndex\].value,'soundFrame');
          return false;
        }
        </SCRIPT>\n"
        append output "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0><TR VALIGN=TOP>"
        append output "<TD>[ossweb::widget::select widget $command $args]</TD>"
        append output "<TD WIDTH=20><IFRAME NAME=soundFrame FRAMEBORDER=0 WIDTH=10 HEIGHT=10></IFRAME></TD>"
        append output "<TD>" [ossweb::html::link -image speaker.gif -url "javascript:;" -html "onClick=\"return doSound()\""] "</TD>"
        append output "</TR></TABLE>"
        return $output
     }
    }
    return
}

# Calendar reminder
proc ossweb::widget::reminder { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     create {
        set widget(optional) 1
        set widget(type:html) button
        return 1
     }
     readonly {
        set widget(type) none
        return 1
     }
     html {
        set repeat [ossweb::coalesce widget(repeat)]
        set subject [ossweb::coalesce widget(subject)]
        set alt [ossweb::coalesce widget(alt) "Calendar Reminder"]
        set htmleditor [ossweb::coalesce widget(htmleditor) 0]
        set remind_args [ossweb::coalesce widget(remind_args)]
        if { $remind_args != "" } {
          set remind_args (hex):[ossweb::crypt $remind_args]
        }
        set winopts "width=850,height=750,menubar=0,location=0,scrollbars=1,resizable=1"
        if { [info exists widget(image)] } {
          return [ossweb::html::link -image $widget(image) -alt $alt -align top -window Reminder -winopts $winopts -lookup t -app_name calendar calendar cmd reminder subject $subject repeat $repeat remind_args $remind_args htmleditor $htmleditor]
        } else {
          set widget(window) Reminder
          set widget(winopts) $winopts
          set widget(url) [ossweb::html::url -lookup t -app_name calendar calendar cmd reminder subject $subject repeat $repeat remind_args $remind_args htmleditor $htmleditor]
          return [ossweb::widget::button widget $command $args]
        }
     }
    }
}

proc ossweb::widget::webtracking { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     readonly {
        return 1
     }

     html {
        set widget(help) "Webtracking. Format: fedex|ups|usps #ID"
        ossweb::widget $widget(widget:id) set_attr title $widget(help)
        ossweb::widget $widget(widget:id) update_attr size 16
        # Read only label
        if { [info exists widget(readonly)] } {
          if { $widget(value) == "" } {
            return
          }
          return "$widget(value)&nbsp;[ossweb::html::link -url f \
                                           -image tracking.gif -width "" -height "" \
                                           -onClick "formTracking(formTrackingUrl('$widget(value)'))" \
                                           -align middle \
                                           -alt $widget(help)]"
        }
        # Regular widget
        set widget(data) [ossweb::html::link -url f \
                               -image tracking.gif -width "" -height "" \
                               -onClick "formTracking(formTrackingUrl(document.$widget(form:id).$widget(name).value))" \
                               -alt $widget(help)]
        set widget(type) text
        return [ossweb::widget $widget(widget:id) html:data]
     }
    }
    return
}

# User selection
proc ossweb::widget::userselect { widget_id command args } {

    upvar $widget_id widget
    set widget(widget:type) select
    if { [info exists widget(multiple)] } {
      set widget(widget:type) multiselect
    }
    if { [info exists widget(combo)] } {
      set widget(widget:type) combobox
    }
    switch -exact $command {
     html {
         set widget(sql) sql:ossweb.user.select.read
         # Customize select box
         foreach key { email all } {
           if { [info exists widget($key)] } {
             append widget(sql) .$key
           }
         }
         set widget(sql_cache) userselect:cache:$widget(sql)
         return [ossweb::widget::$widget(widget:type) widget $command $args]
     }

     default {
        return [ossweb::widget::$widget(widget:type) widget $command $args]
     }
    }
    return
}

# Group selection
proc ossweb::widget::groupselect { widget_id command args } {

    upvar $widget_id widget
    set widget(widget:type) [ossweb::decode [info exists widget(multiple)] 1 multiselect select]
    switch -exact $command {
     html {
         set widget(sql) sql:ossweb.group.select.read
         set widget(sql_cache) groupselect:cache:$widget(sql)
         return [ossweb::widget::$widget(widget:type) widget $command $args]
     }

     default {
        return [ossweb::widget::$widget(widget:type) widget $command $args]
     }
    }
    return
}

# Category selection
proc ossweb::widget::categoryselect { widget_id command args } {

    upvar $widget_id widget
    set widget(widget:type) [ossweb::decode [info exists widget(multiple)] 1 multiselect select]
    switch -exact $command {
     html {
         set widget(sql) sql:ossweb.category.select.list
         set widget(sql_cache) categoryselect:cache:$widget(sql)
         # Special module to show only
         if { [set module [ossweb::coalesce widget(module)]] != "" } {
           set widget(sql_vars) "module {$module}"
         }
         return [ossweb::widget::$widget(widget:type) widget $command $args]
     }

     default {
        return [ossweb::widget::$widget(widget:type) widget $command $args]
     }
    }
    return
}

# Number selection
proc ossweb::widget::numberselect { widget_id command args } {

    upvar $widget_id widget
    set widget(widget:type) [ossweb::decode [info exists widget(multiple)] 1 multiselect select]
    switch -exact $command {
     html {
         set widget(options) [ossweb::number_list [ossweb::coalesce widget(end) 10] [ossweb::coalesce widget(start) 0]]
         return [ossweb::widget::$widget(widget:type) widget $command $args]
     }

     default {
        return [ossweb::widget::$widget(widget:type) widget $command $args]
     }
    }
    return
}

# Interval selection
proc ossweb::widget::intervalselect { widget_id command args } {

    upvar $widget_id widget
    set widget(widget:type) [ossweb::decode [info exists widget(multiple)] 1 multiselect select]
    switch -exact $command {
     html {
         # Seconds
         lappend widget(options) [list [ossweb::date uptime 1] 1]
         for { set i 5 } { $i < 60 } { incr i 5 } {
            lappend widget(options) [list [ossweb::date uptime $i] $i]
         }
         # Minutes
         for { set i 60 } { $i < 3600 } { incr i 60 } {
            lappend widget(options) [list [ossweb::date uptime $i] $i]
         }
         # Hours
         for { set i 3600 } { $i < 86400 } { incr i 3600 } {
            lappend widget(options) [list [ossweb::date uptime $i] $i]
         }
         # Days
         for { set i 86400 } { $i < 1209600 } { incr i 86400 } {
            lappend widget(options) [list [ossweb::date uptime $i] $i]
         }
         # Weeks
         for { set i 1209600 } { $i <= 2419200 } { incr i 604800 } {
            lappend widget(options) [list [ossweb::date uptime $i] $i]
         }
         # Months
         for { set i 2592000 } { $i <= 31104000 } { incr i 2592000 } {
            lappend widget(options) [list [ossweb::date uptime $i] $i]
         }
         return [ossweb::widget::$widget(widget:type) widget $command $args]
     }

     default {
         return [ossweb::widget::$widget(widget:type) widget $command $args]
     }
    }
    return
}

# Color selection component
proc ossweb::widget::colorselect { widget_id command args } {

    upvar $widget_id widget
    switch -exact $command {
     html {
        set url [ossweb::html::url -app_name main colors element "$widget(form:id).$widget(name)"]
        return "<TABLE BORDER=0>
                <TR>
                  <TD><INPUT TYPE=TEXT NAME=$widget(name) VALUE=\"[ossweb::html::quote $widget(value)]\" [ossweb::convert::list_to_attributes $widget(html)]></TD>
                  <TD>[ossweb::html::link -image color.gif -url "javascript:;" \
                        -html "onClick=\"window.open('$url','ColorSelect','alwaysRaised=yes,resizable=no,height=210,width=310,top=400,left=400,screenX=400,screenY=400,dependent=true')\""]
                  </TD>
                </TR>
                </TABLE>"
     }
    }
    return
}

