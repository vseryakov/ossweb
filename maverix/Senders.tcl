# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2003

ossweb::conn::callback senders_action {} {

    switch -exact ${ossweb:cmd} {
     update {
       if { [ns_queryget sender_type] != [ns_queryget sender_type_old] } {
         set sender_method "Admin"
       }
       if { [ossweb::db::exec sql:maverix.sender.update] } {
         error "OSS: Unable to update sender record"
       }
       maverix::cache::sender_set $user_email $sender_email $sender_type
       ossweb::conn::set_msg "Sender record has been updated"
     }

     delete {
       if { [ossweb::db::exec sql:maverix.sender.delete] } {
         error "OSS: Unable to delete sender record"
       }
       maverix::cache::sender_flush $user_email $sender_email
       ossweb::conn::set_msg "Sender record has been deleted"
       ossweb::form form_sender reset -vars t -skip user_email
     }
    }
    ns_log Notice admin:sender: ${ossweb:cmd}: u=$user_email, s=$sender_email
    # Flush multipage caches
    ossweb::sql::multipage senders -flush t
}

ossweb::conn::callback senders_edit {} {
 
    if { $sender_email == "" } { return }
    if { [ossweb::db::multivalue sql:maverix.sender.read] } {
      error "OSS: Record not found"
    }
    append digest_id " ($digest_update, $digest_count)"
    set sender_type_old $sender_type
    ossweb::widget form_sender.sender_type -data " (<B>$sender_method</B>)"
    set user_email_link [ossweb::html::link -text $user_email Users cmd edit user_email $user_email tab senders]
    ossweb::form form_sender set_values
}

ossweb::conn::callback senders_list {} {
    
    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property SENDER:FILTER "" -forms form_sender -global t -cache t
     }
     page {
       ossweb::conn::get_property SENDER:FILTER -skip page -columns t -global t -cache t
     }
     default {
       set senders:rowcount 0
       return
     }
    }
    ossweb::form form_sender set_values
    ossweb::db::multipage senders \
         sql:maverix.sender.search1 \
         sql:maverix.sender.search2 \
         -cmd_name page \
         -page $page \
         -force $force \
         -datatype str \
         -eval {
      set row(url) [ossweb::html::url cmd edit sender_email $row(sender_email) user_email $row(user_email)]
    }
}

ossweb::conn::callback create_form_sender {} {
    
    ossweb::form form_sender -title "Sender Details \[$sender_email\]"

    switch ${ossweb:cmd} {
     edit -
     update {
       ossweb::widget form_sender.user_email -type hidden
       ossweb::widget form_sender.sender_type_old -type hidden -optional
       ossweb::widget form_sender.sender_email -type label -label "Sender Email"
       ossweb::widget form_sender.user_email_link -type inform -label "User Email"
       ossweb::widget form_sender.sender_type -type radio -label "Type" \
            -options { { VRFY VRFY } { PASS PASS } { DROP DROP } } \
            -horizontal
       ossweb::widget form_sender.digest_id -type label -label "Digest" -nohidden
       ossweb::widget form_sender.sender_digest_flag -type radio -label "Sender Self-Verification" \
            -optional \
            -options { { Enabled t } { Disabled f } } \
            -horizontal
       ossweb::widget form_sender.update_date -type inform -label "Last Update"
       ossweb::widget form_sender.back -type button -label Back \
            -url [ossweb::html::url cmd view]
       ossweb::widget form_sender.update -type submit -name cmd -label Update
       ossweb::widget form_sender.delete -type button -label Delete \
            -url [ossweb::html::url cmd delete user_email $user_email sender_email $sender_email] \
            -confirm "confirm('Sender will be deleted, continue?')"
     }
     
     default {
       ossweb::widget form_sender.cmd -type hidden -value search -freeze
       ossweb::widget form_sender.sender_type -type multiselect -label "Sender Type" \
            -optional \
            -empty " --" \
            -options { { VRFY VRFY } { PASS PASS } { DROP DROP } }
       ossweb::widget form_sender.sender_email -type text -label "Sender Email" \
            -optional
       ossweb::widget form_sender.user_email -type text -label "User Email" \
            -optional
       ossweb::widget form_sender.reset -type reset -label Reset -clear
       ossweb::widget form_sender.search -type submit -label Search
     }
    }
}

ossweb::conn::process \
         -columns { sender_email "" ""
                    sender_type "" ""
                    user_email "" ""
                    page var 1
                    force var f } \
         -forms form_sender \
         -form_recreate t \
         -on_error_set_template { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            delete {
              -exec { senders_action }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name edit Users tab senders force t }
            }
            update {
              -exec { senders_action }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name edit }
            }
            edit {
              -exec { senders_edit }
            }
            error {
            }
            default {
              -exec { senders_list }
              -on_error_set_cmd ""
            }
         }

