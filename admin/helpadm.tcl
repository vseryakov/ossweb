# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback help_action {} {

    switch -exact ${ossweb:cmd} {
     update {
       if { $help_id == "" } {
         if { [ossweb::db::exec sql:ossweb.admin.help.create] } {
           error "OSSWEB: Operation failed"
         }
         set help_id [ossweb::db::currval ossweb_util]
       } else {
         if { [ossweb::db::exec sql:ossweb.admin.help.update] } {
           error "OSSWEB: Operation failed"
         }
       }
       ossweb::conn::set_msg "Record updated"
     }
     delete {
       if { [ossweb::db::exec sql:ossweb.admin.help.delete] } {
         error "OSSWEB: Operation failed"
       }
       ossweb::conn::set_msg "Record deleted"
     }
    }
}

ossweb::conn::callback help_list {} {

    set help:add [ossweb::lookup::link -image add.gif -alt Add cmd edit]
    ossweb::db::multirow help sql:ossweb.admin.help.read_all -eval {
      set row(url) [ossweb::lookup::url cmd edit help_id $row(help_id)]
    }
}

ossweb::conn::callback help_edit {} {

    if { $help_id != "" } {
      ossweb::db::multivalue sql:ossweb.help.read
    } else {
      ossweb::db::multivalue sql:ossweb.help.search
    }
    ossweb::form form_help set_values
}

ossweb::conn::callback create_form_help {} {

    ossweb::lookup::form form_help

    ossweb::widget form_help.help_id -type hidden -optional

    ossweb::widget form_help.project_name -type text -label "Project Name" \
         -optional

    ossweb::widget form_help.app_name -type text -label "App Name" \
         -optional

    ossweb::widget form_help.page_name -type text -label "App Context" \
         -optional

    ossweb::widget form_help.cmd_name -type text -label "Command Name" \
         -optional

    ossweb::widget form_help.ctx_name -type text -label "Command Context" \
         -optional

    ossweb::widget form_help.title -type text -label "Title" \
         -size 40

    ossweb::widget form_help.text -type textarea -label "Text" \
         -rows 15 -cols 80 \
         -rich

    ossweb::widget form_help.back -type button -label Back \
         -url [ossweb::lookup::url cmd view]

    ossweb::widget form_help.update -type submit  -name cmd -label Update

    ossweb::widget form_help.delete -type submit -name cmd -label Delete \
         -confirmtext "Record will be deleted, continue?'"
}

set cmd [ossweb::conn cmd_name]

set columns { help_id int ""
              title "" ""
              text "" ""
              project_name "" "unknown"
              app_name "" "unknown"
              page_name "" "unknown"
              cmd_name "" "unknown"
              ctx_name "" "unknown" }

ossweb::conn::process -columns $columns \
           -forms form_help \
           -on_error_set_cmd "" \
           -on_error { -cmd_name view } \
           -eval {
            update -
            delete {
             -exec { help_action }
             -on_error { -cmd_name edit }
             -next { -cmd_name view }
            }
            edit {
             -exec { help_edit }
            }
            default {
             -exec { help_list }
            }
           }

