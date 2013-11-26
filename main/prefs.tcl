# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback prefs_update {} {

    if { $password != $password2 } {
      ossweb::form form_prefs -error "Passwords mismatch"
      return
    }
    set args ""
    foreach name { password first_name last_name user_email start_page } {
      if { [set value [ossweb::coalesce $name]] == "" && $name != "password" } {
        set value NULL
      }
      lappend args $name $value
    }
    if { [eval ossweb::admin::update_user $args] } {
      error "OSSWEB: Error occured during updating preferences"
    }
    # Now save each module's prefs
    ossweb::control::prefs save
    ossweb::conn::set_msg "Preferences have been updated"
}

proc create_form_prefs {} {

    ossweb::form form_prefs -title "Main Preferences"
    ossweb::widget form_prefs.password -type password -label Password -optional
    ossweb::widget form_prefs.password2 -type password -label "Re-type password" \
         -optional
    ossweb::widget form_prefs.first_name -type text -datatype name -label "First Name"
    ossweb::widget form_prefs.last_name -type text -datatype name -label "Last Name"
    ossweb::widget form_prefs.user_email -type text -datatype email -label "Email"
    ossweb::widget form_prefs.start_page -type text -label "Start Page" \
         -optional \
         -info "This URL will be used as a start page after login"
    # Custom/module specific preferences
    ossweb::control::prefs form
    ossweb::widget form_prefs.cmd -type submit -label Update
}

ossweb::conn::process \
           -columns { user_id const {[ossweb::conn user_id]} } \
           -form_recreate t \
           -forms form_prefs \
           -on_error { index.index } \
           -eval {
             update {
               -exec { prefs_update }
               -on_error { -cmd_name view }
               -next { -cmd_name view }
             }
             default {
               -exec {
                  ossweb::db::multivalue sql:ossweb.user.read
                  set password ""
                  set password2 ""
                  ossweb::form form_prefs set_values
               }
             }
           }

