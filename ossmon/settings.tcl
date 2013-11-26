# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2003

ossweb::conn::callback settings_save {} {

    ossweb::db::begin
    set module OSSMON
    foreach rec [ossmon::property property:all] {
       foreach { id name description widget } $rec {}
       set properties($id) $description
    }
    foreach name [ossweb::form form_settings widgets] {
      set value [string trim [ns_queryget $name]]
      set description [ossweb::coalesce properties($name)]
      if { $value == "" } {
        if { [ossweb::db::exec sql:ossweb.config.delete] } {
          error "OSSWEB: Unable to save settings"
        }
      } else {
        if { [ossweb::db::exec sql:ossweb.config.update] } {
          error "OSSWEB: Unable to save settings"
        }
        if { [ossweb::db::rowcount] == 0 } {
          if { [ossweb::db::exec sql:ossweb.config.create] } {
            error "OSSWEB: Unable to save settings"
          }
        }
      }
    }
    ossweb::db::commit
    ossweb::conn::set_msg "Settings have been updated"
    ossweb::reset_config
}

ossweb::conn::callback settings_view {} {

    foreach name [ossweb::form form_settings widgets] {
      set $name [ossweb::config $name]
    }
    ossweb::form form_settings set_values
    ossweb::widget form_settings.version -value [ossmon::version]
}

ossweb::conn::callback create_form_settings {} {

     ossweb::form form_settings -title "OSSMON System Settings" \
          -border_style default

     ossweb::widget form_settings.version -type label -label "Version" \
          -nohidden

     foreach rec [ossmon::property property:all] {
       foreach { id name description widget } $rec {}
       # Do not show sensitive parameters to non-admin
       if { [ossmon::util::sensitive $id]  || [info exists widgets($id)] } {
         continue
       }
       set widgets($id) 1
       eval ossweb::widget form_settings.$id -type text -label "{${name} <SPAN CLASS=property_id>($id)</SPAN>}" \
                 -optional \
                 -empty -- \
                 -labelhelp "{$description}" \
                 $widget

       # Add help link
       ossweb::widget form_settings.$id \
            -info "[ossweb::widget form_settings.$id info]
                   [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#$id')"]"
       # Default text size
       if { [ossweb::widget form_settings.$id type] == "text" } {
         ossweb::widget form_settings.$id set_attr size 45
       }
     }

     ossweb::widget form_settings.update -type submit -name cmd -label Update
}

ossweb::conn::process \
         -forms { form_settings } \
         -on_error { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            update {
              -exec { settings_save }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            error {
            }
            default {
              -exec { settings_view }
              -on_error_set_cmd ""
            }
         }

