# Author: Vlad Seryakov vlad@crystalballinc.com
# January 2003
#
# $Id: toolbar.tcl 2863 2007-01-26 04:26:25Z vlad $


# Returns local user toolbat
proc ossweb::html::toolbar { args } {

    ns_parseargs { {-skip ""} {-toolbar ""} {-table t} } $args

    set prefs [ossweb::conn toolbar]
    set always [ossweb::config server:toolbar:always alert]
    foreach name [lsort [eval "namespace eval ::ossweb::html::toolbar { info procs }"]] {
      if { $skip != "" && [lsearch -exact $skip $name] > -1 } { continue }
      if { $prefs == "" ||
           [string index $name 0] == "_" ||
           [lsearch -exact $prefs $name] > -1 ||
           [lsearch -exact $always $name] > -1 } {
        # Generate toolbar icon
        set html [::ossweb::html::toolbar::$name]
        if { $html != "" } {
          lappend toolbar $html
        }
      }
    }
    if { $toolbar != "" } {
      switch -- $table {
       t {
         foreach t $toolbar {
           append td "<TD>$t</TD>"
         }
         set toolbar "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0><TR>$td</TR></TABLE>"
       }
       f {
         set toolbar [join $toolbar]
       }
      }
    }
    return $toolbar
}

# Preferences page for toolbar
proc ossweb::control::prefs::toolbar { type args } {

    switch -- $type {
     columns {
        return { toolbar {} {} }
     }

     form {
        ossweb::form form_prefs -section Toolbar
        # Icons to be displayed in the toolbar
        set options ""
        foreach name [lsort [eval "namespace eval ::ossweb::html::toolbar { info procs }"]] {
          if { [string index $name 0] == "_" } { continue }
          set tname [string trimleft $name 0123456789]
          set tname "${tname}&nbsp;[ossweb::html::image $tname.gif]"
          lappend options [list $tname $name]
        }
        ossweb::widget form_prefs.toolbar -type checkbox -label Icons \
             -values [ossweb::conn toolbar] \
             -freeze \
             -optional \
             -horizontal \
             -horizontal_cols 5 \
             -options $options
     }

     save {
        ossweb::admin::prefs set -obj_id [ossweb::conn user_id] \
             toolbar [ns_querygetall toolbar]
     }
    }
}

# Link to users page
proc ossweb::html::toolbar::users {} {

    if { [ossweb::conn::check_acl -acl *.admin.users.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/users.gif -width "" -height "" -hspace 6 -mouseover /img/toolbar/users_o.gif -alt Users -app_name admin users]
}

# Link to config page
proc ossweb::html::toolbar::config {} {

    if { [ossweb::conn::check_acl -acl *.admin.config.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/config.gif -width "" -height "" -hspace 6 -mouseover /img/toolbar/config_o.gif -alt Config -app_name admin config]
}

# Link to preferences page
proc ossweb::html::toolbar::prefs {} {

    if { [ossweb::conn::check_acl -acl *.main.prefs.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/prefs.gif -width "" -height "" -hspace 6 -mouseover /img/toolbar/prefs_o.gif -alt Prefs -app_name main prefs]
}

# Link to search page
proc ossweb::html::toolbar::search {} {

    if { [ossweb::conn::check_acl -acl *.main.search.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/search.gif -width "" -height "" -hspace 6 -mouseover /img/toolbar/search_o.gif -app_name main -alt Search -popup t -popupopts "width:500,top:5,left:400,dnd:1,topmove:20,close:1,focus:'q'" search cmd popup]
}

# Link to tracker page
proc ossweb::html::toolbar::tracker {} {

    if { [ossweb::conn::check_acl -acl *.main.tracker.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/tracker.gif -hspace 6 -mouseover /img/toolbar/tracker_o.gif -lookup t -alt UpdatesTracker -app_name main -window Tracker -winopts "location=0,menubar=0,width=700,height=700,scrollbars=1,resizable=1" tracker]
}

# Show popup message
proc ossweb::html::toolbar::_popup {} {

    if { [set popup [ossweb::admin::read_popup]] == "" } { return }
    set popup [string map { \n <BR> [ \\[ $ \\$ } $popup]
    regsub -all -nocase {\r|'|<SCRIPT|</SCRIPT|<EMBED|<IFRAME|</IFRAME>|<FRAME} $popup {} popup
    set height [expr 150+[string length $popup]/80*150]
    # Replace sound placeholder
    if { [regexp -nocase {@sound:([a-z0-9]+)@} $popup d sound] } {
      regsub -all -nocase {@sound:([a-z0-9]+)@} $popup {} popup
      set sound [ossweb::conn::hostname]/snd/$sound.wav
      switch -glob -- [ns_set iget [ns_conn headers] User-Agent] {
       *MSIE* {
          set popup "<BGSOUND SRC=$sound>$popup"
       }
       default {
         set popup "<EMBED SRC=$sound HIDDEN=TRUE AUTOSTART=TRUE>$popup"
       }
      }
    }
    return "<SCRIPT>var w=window.open('','Popup','menubar=0,location=0,width=300,height=$height,scrollbars=1');\
            w.document.write('<HEAD><TITLE>OSSWEB Message</TITLE></HEAD><BODY>$popup</BODY>');\
            w.document.close();</SCRIPT>"
}

# Developer panel, server restart and etc
proc ossweb::html::toolbar::reboot {} {

    if { [ossweb::conn::check_acl -acl *.admin.*.reboot.*] } { return }
    return [ossweb::html::link -image /img/toolbar/reboot.gif -width "" -height "" -hspace 6 -mouseover /img/toolbar/reboot_o.gif -alt Reboot -url /ossweb:handler?c=1 -window Reboot -winopts "width=300,height=50,menubar=0,location=0" cmd reboot]
}
