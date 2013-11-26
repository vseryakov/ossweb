# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback alert_action {} {

    switch ${ossweb:cmd} {
     info {
        if { [ossweb::db::multivalue sql:ossmon.alert.read] } {
          error "OSSWEB: Alert $alert_id not found"
        }
        set alert_name [ossweb::lookup::link -text $alert_name -alt "Alert Details" cmd edit alert_id $alert_id]
        set device_name [ossweb::lookup::link -text $device_name -alt "Device Details" devices cmd edit device_id $device_id]
        return
     }

     update {
        if { [ossweb::db::exec sql:ossmon.alert.update.status] } {
          error "OSS: Could not update the status of the alert"
        }
        ossweb::conn::set_msg "The status has been changed in the system"
     }

     closeall {
        set alert_status Closed
        if { [ossweb::db::exec sql:ossmon.alert.update.all]} {
          error "OSS: Could not update the status of the alert"
        }
        ossweb::conn::set_msg "All active alerts have been closed"
     }

     deleteall {
        if { [ossweb::db::exec sql:ossmon.alert.delete.all]} {
          error "OSS: Could not delete the alert"
        }
        ossweb::sql::multipage alerts -flush t
        ossweb::conn::set_msg "All active alerts have been deleted"
     }

     delete {
        if { [ossweb::db::exec sql:ossmon.alert.delete]} {
          error "OSS: Could not delete the status of the alert"
        }
        ossweb::conn::set_msg "The status has been deleted"
     }
    }
    # Clear this so the filter form will not pick up these values
    set device_name ""
    set alert_id ""
    ossweb::sql::multipage alerts -flush t
}

ossweb::conn::callback alert_edit { } {

    if { [ossweb::db::multivalue sql:ossmon.alert.read] } {
      error "OSS: Unable to read alert record"
    }
    switch ${ossweb:cmd} {
     refresh { set force t }
    }
    ossweb::form form_alert -info [ossweb::html::link -text "\[$alert_id\]" cmd edit alert_id $alert_id]
    # Related objects
    ossweb::db::foreach sql:ossmon.alert.objects {
      append device_objects "[ossweb::html::link -text "$obj_name ($obj_type)" objects cmd edit obj_id $obj_id] | "
    }
    append update_time " ($update_user)"
    append alert_name "/ $alert_type / $alert_level"
    append alert_time / $alert_count
    append alert_type / $alert_level
    append create_time / $update_time

    # Properties
    ossweb::db::multirow properties sql:ossmon.alert.property.read_all -eval {
      switch $row(property_id) {
       problem:id {
         set row(value) [ossweb::html::link -text $row(value) -app_name problem -window Task problem problem_id $row(value)]
         set row(property_id) "Task/Problem"
       }
      }
    }
    # Log entries
    ossweb::db::multipage log \
         sql:ossmon.alert.log.search1 \
         sql:ossmon.alert.log.search2 \
         -page $page \
         -pagesize 5 \
         -cmd_name edit \
         -force $force \
         -query "alert_id=$alert_id&[ossweb::lookup::property query]"
    # Update form fileds
    ossweb::form form_alert set_values
}

ossweb::conn::callback alert_list { } {

    switch -- ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property OSSMON:ALERT:FILTER "" -forms form_filter -global t -cache t
     }

     default {
       ossweb::conn::get_property OSSMON:ALERT:FILTER -skip page -columns t -global t -cache t
     }
    }

    ossweb::db::multipage alerts sql:ossmon.alert.search1 sql:ossmon.alert.search2 \
         -page $page \
         -force $force \
         -eval {
      set row(url) [ossweb::html::url cmd edit alert_id $row(alert_id)]
    }
    ossweb::form form_filter set_values
    # Refresh page every 5 minutes
    ossweb::conn -set html:head "<META HTTP-EQUIV=Refresh CONTENT=\"300' URL=[ossweb::html::url cmd view]\">"
}

ossweb::conn::callback create_forms { } {

    ossweb::widget form_alert.alert_id -type hidden
    ossweb::widget form_alert.device_name -type label -label "Device Name" -nohidden
    ossweb::widget form_alert.device_objects -type label -label "Device Objects" -nohidden
    ossweb::widget form_alert.device_location -type label -label "Location"  -nohidden
    ossweb::widget form_alert.alert_status -type select -label "Alert Status" \
         -options $status_list
    ossweb::widget form_alert.alert_type -type label -label "Alert Type/Level" -nohidden
    ossweb::widget form_alert.alert_name -type label -label "Alert Name" -nohidden
    ossweb::widget form_alert.alert_time -type label -label "Alert Time" -nohidden
    ossweb::widget form_alert.create_time -type label -label Created/Updated -nohidden
    ossweb::widget form_alert.back -type button -label Back \
         -url [ossweb::html::url cmd view]
    ossweb::widget form_alert.refresh -type button -label Refresh \
         -url [ossweb::html::url cmd refresh alert_id $alert_id]
    ossweb::widget form_alert.update -name cmd -type submit -label Update
    ossweb::widget form_alert.help -type helpbutton -url doc/manual.html#t47

    ossweb::widget form_filter.cmd -type hidden -value search -freeze
    ossweb::widget form_filter.device_name -type text -label "Device Name" \
         -optional
    ossweb::widget form_filter.alert_status -type multiselect -label "Alert Status" \
         -empty " --" -options $status_list -optional
    ossweb::widget form_filter.alert_name -type text -label "Alert Name" \
         -optional
    ossweb::widget form_filter.search -type submit -label Search
    ossweb::widget form_filter.closeall -type button -label CloseAll \
         -url [ossweb::html::url cmd closeall] \
         -help "Close all active alerts" \
         -confirm "confirm('Close all active alerts?')"
}

# Table/form columns
set columns { alert_id int ""
              alert_status "" "Active Pending"
              page var 1
              force var f }

set status_list { { Active Active } { Closed Closed } { Pending Pending } }

# Process request parameters takes columns and form name and calls the function to create the form
ossweb::conn::process -columns $columns \
           -forms { form_alert form_filter } \
           -form_create create_forms \
           -on_error_set_cmd "" \
           -eval {
             deleteall -
             closeall -
             delete -
             update {
               -exec { alert_action }
               -on_error { -cmd_name view }
               -next { -cmd_name view }
             }
             refresh -
             edit {
               -exec { alert_edit }
               -on_error { -cmd_name default }
             }
             info {
               -exec { alert_action }
               -on_error { -cmd_name error }
             }
             search -
	     default {
	       -exec { alert_list }
	     }
           }
