# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback apps_action {} {

    switch -exact ${ossweb:cmd} {

     copy {
       if { [ossweb::db::exec sql:ossweb.admin.apps.copy] } {
         error "OSSWEB: Operation failed"
       }
       set app_id [ossweb::db::currval ossweb_apps]
       ossweb::conn::set_msg "Application has been copied to $app_id"
     }

     move {
       switch -exact ${ossweb:ctx} {
        up {
          ossweb::db::value sql:ossweb.admin.apps.move_up
        }
        down {
          ossweb::db::value sql:ossweb.admin.apps.move_down
        }
       }
     }
     open {
       set menu_state [ossweb::conn::get_property menuState -global t]
       append menu_state ":$app_id;"
       ossweb::conn::set_property menuState $menu_state -global t
     }

     close {
       set menu_state [split [ossweb::conn::get_property menuState -global t] ":"]
       set new_menu ""
       foreach item $menu_state {
        if { $item == "" || $item == "$app_id;" } { continue }
        append new_menu ":$item"
       }
       ossweb::conn::set_property menuState $new_menu -global t
     }

     refresh {
       ossweb::db::cache flush apps*
     }

     update {
       if { $app_id > 0 } {
         if { [ossweb::db::update ossweb_apps app_id $app_id] } {
           error "OSSWEB: Operation failed"
         }
       } else {
         if { [ossweb::db::insert ossweb_apps] } {
           error "OSSWEB: Operation failed"
         }
         set app_id [ossweb::db::currval ossweb_apps]
       }
       ossweb::conn::set_msg "Application has been updated"
     }

     delete {
       if { [ossweb::db::delete ossweb_apps app_id $app_id] } {
        error "OSSWEB: operation failed"
       }
       ossweb::conn::set_msg "Application has been deleted"
     }
    }
}

ossweb::conn::callback apps_list {} {

    set app_id ""
    set apps:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    set apps:refresh [ossweb::html::link -image refresh.gif -alt Refresh cmd refresh]

    ossweb::db::multirow apps sql:ossweb.apps.list -replace_null "&nbsp;" -eval {
        set level [expr [llength [split $row(tree_path) "/"]] - 3]
        set row(image) [ossweb::decode $row(image) "" "" [ossweb::html::image $row(image)]]
        set row(image) "[string repeat [ossweb::html::image b.gif] $level]$row(image)"
        set row(title) [ossweb::html::link -text $row(title) cmd edit app_id $row(app_id)]
        set row(up) [ossweb::html::link -image up.gif -alt "Move Up" -width 10 cmd move.up app_id $row(app_id)]
        set row(down) [ossweb::html::link -image down.gif -alt "Move Down" -width 10 cmd move.down app_id $row(app_id)]
    }
}

ossweb::conn::callback apps_edit {} {

    if { $app_id > 0 } {
      if { [ossweb::db::read ossweb_apps app_id $app_id] } {
        error "OSSWEB: Application with id $app_id not found"
      }
    }
    ossweb::widget form_app.group_id \
         -options [ossweb::db::multilist sql:ossweb.admin.apps.group_list]
    ossweb::form form_app set_values
}

ossweb::conn::callback create_form_app {} {

    ossweb::form form_app -title "Application Details #$app_id"
    ossweb::widget form_app.app_id -type hidden -optional
    ossweb::widget form_app.title -type text -label "Title *"
    ossweb::widget form_app.project_name -type text -label "Project Name *"
    ossweb::widget form_app.app_name -type text -label "App Name *" \
         -datatype name -optional
    ossweb::widget form_app.page_name -type text -label "App Context" \
         -datatype name -optional
    ossweb::widget form_app.url -type text -label "URL" -optional
    ossweb::widget form_app.image -type imageselect -label "Image" \
         -optional -show
    ossweb::widget form_app.path -type text -label "Directory Path" \
         -optional
    ossweb::widget form_app.target -type text -label "Target" \
         -optional
    ossweb::widget form_app.host_name -type text -label "Host" \
         -optional
    ossweb::widget form_app.group_id -type select -label "Group" \
         -optional -empty None
    ossweb::widget form_app.condition -type text -label "Condition" \
         -optional
    ossweb::widget form_app.sort -type text -label "Sort" \
         -datatype integer -html { size 5 } -optional
    ossweb::widget form_app.back -type button -label Back -url [ossweb::html::url cmd view]
    ossweb::widget form_app.update -type submit -name cmd -label Update
    ossweb::widget form_app.copy -type submit -name cmd -label Copy \
         -eval { if { $app_id == "" } { return } }
    ossweb::widget form_app.delete -type submit -name cmd -label Delete \
         -eval { if { $app_id == "" } { return } } \
         -html { onClick "return confirm('Record will be deleted, continue?')" }
}

# Table/form columns
set columns { app_id int ""
              title const ""
              project_name const ""
              app_name const ""
              page_name const ""
              url const ""
              image const ""
              path const ""
              target const ""
              group_id int ""
              sort int 0
              condition "" "" }

# Process request parameters
ossweb::conn::process -columns $columns \
           -forms form_app \
           -form_recreate t \
           -on_error { -cmd_name index } \
           -eval {
            close -
            open {
              -exec { apps_action }
              -next { -app_name index index }
              -on_error { -cmd_name error }
            }
            error {
            }
            copy {
              -exec { apps_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            move -
            refresh -
            update -
            delete {
              -exec { apps_action }
              -next { -cmd_name view }
              -on_error { -cmd_name edit }
            }
            edit {
              -exec { apps_edit }
              -on_error { -cmd_name view }
            }
            default {
              -exec { apps_list }
            }
           }
