# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2003

ossweb::conn::callback msg_action {} {

    switch -exact ${ossweb:cmd} {

     spam {
       ns_schedule_proc -once 0 "maverix::learnEmail $msg_id spam"
       ossweb::conn::set_msg "Message has been marked as SPAM"
     }
     
     delete {
       if { [ossweb::db::exec sql:maverix.message.delete] } {
         error "OSS: Unable to delete message"
       }
       ossweb::conn::set_msg "Message has been deleted"
     }
    }
    # Flush cached search results
    ossweb::sql::multipage messages "" -flush t
    set msg_id ""
}

ossweb::conn::callback msg_edit {} {

    if { $msg_id != "" } {
      if { ![ossweb::db::multivalue sql:maverix.message.read] } {
        set subject [maverix::decodeHdr $subject]
        regsub -all { +} $body { } body
        set body "<PRE>[ossweb::util::wrap_text [ns_quotehtml $body]]</PRE>"
        set users ""
        foreach user_email $user_email {
          append users [ossweb::html::link -text $user_email Users cmd edit user_email $user_email] "<BR>"
        }
        set user_email $users
      }
    }
    ossweb::form form_msg set_values
}

ossweb::conn::callback msg_list {} {
    
    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property USER:FILTER "" -forms form_msg -global t -cache t
     }
     error {
       return
     }
     default {
       ossweb::conn::get_property USER:FILTER -skip page -columns t -global t -cache t
     }
    }
    ossweb::form form_user set_values
    ossweb::db::multipage messages \
         sql:maverix.message.search1 \
         sql:maverix.message.search2 \
         -page $page \
         -force $force \
         -eval {
      set users ""
      foreach user_email $row(user_email) {
        append users [ossweb::html::link -text $user_email Users cmd edit user_email $user_email] "<BR>"
      }
      set row(user_email) $users
      set row(subject) [maverix::decodeHdr $row(subject)]
      set row(url) [ossweb::html::url cmd edit msg_id $row(msg_id)]
      set row(edit) ""
    }
}

ossweb::conn::callback create_form_msg {} {

    switch ${ossweb:cmd} {
     edit -
     update {
        ossweb::form form_msg -title "Message Details"
        ossweb::widget form_msg.msg_id -type hidden
        ossweb::widget form_msg.page -type hidden -optional
        ossweb::widget form_msg.user_email -type inform -label User(s)
        ossweb::widget form_msg.sender_email -type label -label From -nohidden
        ossweb::widget form_msg.subject -type label -label Subject -nohidden
        ossweb::widget form_msg.create_date -type label -label "Create Date" -nohidden
        ossweb::widget form_msg.signature -type label -label Signature -nohidden
        ossweb::widget form_msg.attachments -type label -label Attachments -nohidden
        ossweb::widget form_msg.virus_status -type label -label "Virus Status" -nohidden
        ossweb::widget form_msg.body -type label -label Text -nohidden
        ossweb::widget form_msg.back -type button -label Back \
             -url [ossweb::html::url cmd view page $page]
        ossweb::widget form_msg.delete -type button -label Drop \
             -url [ossweb::html::url cmd delete msg_id $msg_id] \
             -confirm "confirm('Message will be deleted, continue?')"
        ossweb::widget form_msg.spam -type button -label SPAM \
             -url [ossweb::html::url cmd spam msg_id $msg_id] \
             -confirm "confirm('Message will be marked as SPAM, continue?')"
     }
     default {
        ossweb::widget form_msg.msg_id -type text -label ID \
             -html { size 5 } \
             -optional
        ossweb::widget form_msg.sender_email -type text -label From \
             -optional
        ossweb::widget form_msg.user_email -type text -label To \
             -optional
        ossweb::widget form_msg.subject -type text -label Subject \
             -optional
        ossweb::widget form_msg.search -type submit -name cmd -label Search
        ossweb::widget form_msg.reset -type reset -label Reset -clear
     }
    }
}

ossweb::conn::process \
         -columns { msg_id int ""
                    page var 1
                    force var f } \
         -forms { form_msg } \
         -form_recreate t \
         -on_error_set_template { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            spam -
            delete {
              -exec { msg_action }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name view }
            }
            edit {
              -exec { msg_edit }
            }
            error {
            }
            default {
              -exec { msg_list }
              -on_error_set_cmd ""
            }
         }

