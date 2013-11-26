# Author: Vlad Seryakov vlad@crystalballinc.com
# January 2002
#
# $Id: lookup.tcl 2858 2007-01-25 20:51:47Z vlad $

# Lookup protocol support
# mode:
#   1 - regular page replacement
#   2 - window popup
#   3 - window popup, redirect on return
#   4 - reserved
#   5 - DIV popup
#   6 - pagePopup mode

proc ossweb::lookup::mode {} {

    return [ns_queryget lookup:mode 0]
}

proc ossweb::lookup::master {} {

    switch -- [mode] {
     2 -
     3 -
     4 {
       return index.title
     }

     5 -
     6 {
       return
     }
    }
    return index
}

proc ossweb::lookup::url { args } {

    return [eval ossweb::html::url $args [ossweb::lookup::property url $args]]
}

proc ossweb::lookup::link { args } {

    return [eval ossweb::html::link $args [ossweb::lookup::property url $args]]
}

# Returns various properties of lookup component
proc ossweb::lookup::property { name args } {

    switch -- $name {
     winopts {
       return [ossweb::config lookup:winopts "width=[ossweb::conn window:width 940],height=[ossweb::conn window:height 760],scrollbars=1,menubar=0,location=0,resizable=1"]
     }

     url {
       set url [list]
       set args [join $args]
       foreach name { lookup:mode lookup:proc lookup:div lookup:map lookup:sep lookup:return } {
         if { [set value [ns_queryget $name]] != "" && ![ossweb::lexists $args $name] } {
           lappend url $name $value
         }
       }
       return $url
     }

     query {
       return [ossweb::convert::list_to_query [ossweb::lookup::property url]]
     }
    }
}

# To be used with multirow proc to build return url. Depending on mode it
# creates return url or Javascript code to fill parent form with row values.
#  -return t - returns list with HREF and onClick code as a Tcl list
proc ossweb::lookup::row { name args } {

    if { [set mode [mode]] < 1 } { return -1 }

    ns_parseargs { {-id ""} {-return f} {-script f} {-row_name row} {-field ""} } $args

    upvar $row_name row

    set varOp varSet
    set div [ns_queryget lookup:div]
    set divID [string map { . _ } $div]
    set map [ns_queryget lookup:map]
    set proc [ns_queryget lookup:proc]
    set append [ns_queryget lookup:append]

    # Lookup in separate window, build javascript url
    switch $mode {
     1 {
       # If id is present, on return transfer only record id otherwise transfer
       # the whole record array
       if { $id != "" } {
         if { $return == "t" } {
           return [list [ossweb::lookup::url cmd lookup.return $id $row($id)] ""]
         }
         set row($name) [ossweb::lookup::link -text $row($name) cmd lookup.return $id $row($id)]
       } else {
         if { $return == "t" } {
           return [list [ossweb::lookup::url cmd lookup.return lookup:row [array get row]] ""]
         }
         set row($name) [ossweb::lookup::link -text $row($name) cmd lookup.return lookup:row [array get row]]
       }
     }

     2 {
        foreach { field value } $map {
          if { $append != "" } {
            append code "formAppend(window.opener.document.$field,unescape('[ossweb::html::escape [ossweb::coalesce row($value)]]'),'$append');"
          } else {
            append code "formSet(window.opener.document.$field,unescape('[ossweb::html::escape [ossweb::coalesce row($value)]]'));"
          }
        }
        # In notext mode we should update DIV object
        if { $div != "" && $field != "" } {
          if { $append != "" } {
            append code "if(varGet('$divID',window.opener.document) != '')varAppend('$divID','$append',window.opener.document);"
            set varOp varAppend
          }
          append code "${varOp}('$divID',window.opener.document.$field.value,window.opener.document);"
        }
        append code "$proc;window.close();"
        if { $return == "t" } {
          return [list "javascript:;" $code]
        }
        append code "return false;"
        if { $script == "t" } {
          set row($name) $code
          return 0
        }
        set row($name) "<A HREF=\"javascript:;\" onClick=\"${code}\">$row($name)</A>"
     }

     5 {
        foreach { field value } $map {
          if { $append != "" } {
            append code "formAppend(document.$field,unescape('[ossweb::html::escape [ossweb::coalesce row($value)]]'),'$append');"
          } else {
            append code "formSet(document.$field,unescape('[ossweb::html::escape [ossweb::coalesce row($value)]]'));"
          }
        }
        # In notext mode we should update DIV object
        if { $div != "" && $field != "" } {
          if { $append != "" } {
            append code "if(varGet('$divID') != '')varAppend('$divID','$append');"
            set varOp varAppend
          }
          append code "${varOp}('$divID',document.$field.value);"
        }
        append code "$proc;pagePopupClose({name:'[ns_queryget lookup:popup]'});"
        if { $return == "t" } {
          return [list "javascript:;" $code]
        }
        append code "return false;"
        if { $script == "t" } {
          set row($name) $code
          return 0
        }
        set row($name) "<A HREF=\"javascript:;\" onClick=\"${code}\">$row($name)</A>"
     }
    }
    return 0
}

# Creates hidden fields in given form to carry special lookup parameters.
# -select t creates Select button to be used in form to select this object and return into caller.
# -close creates button for closing window in mode 2
proc ossweb::lookup::form { form args } {

    if { [set mode [mode]] < 1 } { return }

    ns_parseargs { {-select f} {-close f} } $args

    if { $form == "" } { error "ossweb::lookup::form: form is required" }
    ossweb::widget $form.lookup:mode -type hidden -value [mode] -freeze
    foreach key { div proc map append return } {
      if { [ns_queryexists lookup:$key] } {
        ossweb::widget $form.lookup:$key -type hidden -optional -value [ns_queryget lookup:$key] -freeze
      }
    }

    if { $select == "t" } {
      switch -- $mode {
       1 {
         set onClick "this.value='Lookup.Return';this.form.submit()"
       }

       2 {
         foreach { field value } [ns_queryget lookup:map] {
           append onClick "formSet(window.opener.document.$field,document.$form.$value.value);"
         }
         # In notext mode we should update DIV object
         set div [ns_queryget lookup:div]
         if { $div != "" } {
           append onClick "varSet('[string map { . _ } $div]',window.opener.document.$div.value,window.opener.document);"
         }
         append onClick "[ns_queryget lookup:proc];window.close()"
       }

       5 {
         foreach { field value } [ns_queryget lookup:map] {
           append onClick "document.$field.value=document.$form.$value.value;"
         }
         # In notext mode we should update DIV object
         set div [ns_queryget lookup:div]
         if { $div != "" } {
           append onClick "varSet('[string map { . _ } $div]',document.$div.value);"
         }
         append onClick "[ns_queryget lookup:proc];pagePopupClose()"
       }
      }
      ossweb::widget $form.lookup:select -type button -label Select \
           -leftside \
           -onClick $onClick
    }

    if { $close == "t" } {
      switch -- $mode {
       1 {
       }

       2 {
         ossweb::widget $form.lookup:close -type button -label Close \
              -onClick "window.close();"
       }

       5 {
         ossweb::widget $form.lookup:close -type button -label Close \
              -onClick "pagePopupClose();"
       }
      }
    }
}

# Starts lookup processing, saves special hidden parameters and
# proceeds with given lookup page
proc ossweb::lookup::start { return args } {

    if { [mode] < 1 } {
      return
    }

    ns_parseargs { {-page_name ""}
                   {-cmd_name ""}
                   {-ctx_name ""}
                   {-app_name ""}
                   {-project_name ""}
                   {-mode 1}
                   {-div ""}
                   {-proc ""} } $args

    if { $return == "" } {
      error "ossweb::lookup::goto: return is required"
    }
    set form [ns_getform]
    ns_set update $form lookup:return $return
    ns_set update $form lookup:mode $mode
    ns_set update $form lookup:div $div
    ns_set update $form lookup:proc $proc
    ossweb::conn::next \
         -project_name $project_name \
         -app_name $app_name \
         -page_name $page_name \
         -cmd_name lookup
}

# Performs lookup completion, switch to caller template with variables filled with values
# from found record.
proc ossweb::lookup::stop { args } {

    if { [set mode [mode]] < 1 } { return }

    ns_parseargs { {-level 1} {-sql ""} {-row ""} {-return "-cmd_name view"} } $args

    # Retrieve saved form elements
    set form [ossweb::conn::get_property LOOKUP:[ossweb::conn page_name]]

    switch $mode {
     3 {
       # If record row is specified setup local vars from the record
       foreach { name value } $row {
         upvar $level $name var
         append form "&$name=[ossweb::html::escape $value]"
       }
       # If SQL is specified, retrieve the record
       if { $sql != "" && [ossweb::db::multivalue $sql -prefix LKP_] } {
         error "OSSWEB: Record not found"
       }
       foreach name [info vars LKP_*] {
         append form "&[string range $name 4 end]=[ossweb::html::escape [set $value]]"
       }
       # We should use redirect instead of inmemory switch
       set url [eval ossweb::html::url $return]
       append url $form
       ossweb::conn::redirect $url
     }

     default {
       ossweb::convert::query_to_vars $form -level $level
       # If record row is specified setup local vars from the record
       foreach { name value } $row {
         upvar $level $name var
         set var $value
       }
       # If SQL is specified, retrieve the record
       if { $sql != "" && [uplevel $level "ossweb::db::multivalue \"$sql\""] } {
         error "OSSWEB: Record not found"
       }
       # Inmemory template switch (same server only)
       eval ossweb::conn::next $return
     }
    }
}

# Top level execution proc to be used in -eval of process_request
proc ossweb::lookup::exec { args } {

    if { [set mode [mode]] < 1 || [ossweb::conn cmd_name] != "lookup" } { return }

    ns_parseargs { {-sql ""} } $args

    switch -- [ossweb::conn ctx_name] {
     return {
        ossweb::lookup::stop \
             -level 2 \
             -row [ns_queryget lookup:row] \
             -return [ns_queryget lookup:return] \
             -sql $sql
     }

     default {
        if { [ns_queryget lookup:return] != "" } {
          # By default use full-screen lookup mode
          if { $mode == "" } {
            ns_set update [ns_getform] lookup:mode 1
          }
          ossweb::conn::set_property LOOKUP:[ossweb::conn page_name] [ossweb::conn::export_form]
        }
        ossweb::conn::next -cmd_name [ns_queryget lookup:start search]
     }
    }
}

# To be used for javascript handlers only when only one row
# has been found. Window closes and executes javascript returing code
# as it was clicked from the browser
proc ossweb::lookup::onereturn { name column args } {

    if { [ossweb::lookup::mode] <= 0 } { return }

    ns_parseargs { {-return t} {-row_name row} {-eval ""} } $args

    upvar $name:rowcount rowcount $name:1 $row_name
    if { $rowcount != 1 } { return }
    if { $eval != "" } { eval $eval }
    # Use the same script as in normal row select
    set code [ossweb::lookup::row $column -return t]
    set script "<script language=javascript src=/js/ossweb.js></script>"
    append script "<script language=javascript>[lindex $code 1];</script>"
    if { $return == "t" } {
      ns_return 200 text/html $script
      ossweb::adp::Exit
    }
    return $script
}
