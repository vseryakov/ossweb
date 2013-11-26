# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback mqueue_action {} {

    switch -exact ${ossweb:cmd} {
     schedule {
       if { [ossweb::db::exec sql:ossweb.message_queue.update.resend] } {
          error "OSSWEB: Unable to schedule the message"
       }
     }
     delete {
       if { [ossweb::db::exec sql:ossweb.message_queue.delete] } {
          error "OSSWEB: Unable to delete the message"
       }
     }
    }
    # Flush cached search results
    ossweb::sql::multipage mqueue -flush t
}

ossweb::conn::callback mqueue_edit {} {

    if { $message_id != -1 } {
      if { [ossweb::db::multivalue sql:ossweb.message_queue.read] } {
        error "OSSWEB: Record not found"
      }
      set rcpt_to [ossweb::util::wrap_text $rcpt_to -size 40]
      set args [ossweb::util::wrap_text $args -size 40]
      # Put body between PRE only if it is plain text
      if { [string first text/html $args] == -1 } {
        set body "<PRE>$body</PRE>"
      }
    }
    ossweb::form form_mqueue set_values
    set ossweb:cmd edit
}

ossweb::conn::callback mqueue_list {} {

    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property MQUEUE:FILTER "" -forms form_mqueue -global t -cache t
     }
     error {
       return
     }
     default {
       ossweb::conn::get_property MQUEUE:FILTER -skip page -columns t -global t -cache t
     }
    }
    # Update form with current values
    ossweb::form form_mqueue set_values
    ossweb::db::multipage mqueue \
         sql:ossweb.message_queue.search1 \
         sql:ossweb.message_queue.search2 \
         -page $page \
         -timeout 120 \
         -force $force \
         -replace_null "&nbsp;" -eval {
      set row(url) [ossweb::html::url mqueue cmd edit message_id $row(message_id)]
      set row(rcpt_to) [ossweb::util::wrap_text $row(rcpt_to) -size 40]
    }
}

ossweb::conn::callback create_form_mqueue {} {

    ossweb::form form_mqueue

    switch ${ossweb:cmd} {
     edit -
     update {
       ossweb::widget form_mqueue.message_id -type label -label "Message ID"
       ossweb::widget form_mqueue.message_type -type label -label "Type"
       ossweb::widget form_mqueue.create_date -type label -label "Created" -nohidden
       ossweb::widget form_mqueue.sent_flag -type label -label "Sent Flag"  -nohidden
       ossweb::widget form_mqueue.rcpt_to -type label -label "To"  -nohidden
       ossweb::widget form_mqueue.mail_from -type label -label "From"  -nohidden
       ossweb::widget form_mqueue.subject -type label -label "Subject"  -nohidden
       ossweb::widget form_mqueue.body -type label -label "Body"  -nohidden
       ossweb::widget form_mqueue.args -type label -label "Parameters"  -nohidden
       ossweb::widget form_mqueue.try_count -type label -label "Try count"  -nohidden
       ossweb::widget form_mqueue.error_msg -type label -label "Error Message"  -nohidden
       ossweb::widget form_mqueue.back -type button -label Back -url [ossweb::html::url cmd view]
       ossweb::widget form_mqueue.delete -type button -label Delete \
            -url [ossweb::html::url cmd delete message_id $message_id] \
            -confirm "confirm('Message will be deleted, continue?')"
       ossweb::widget form_mqueue.schedule -type button -label Schedule \
            -url [ossweb::html::url cmd schedule message_id $message_id] \
            -confirm "confirm('Message will be scheduled for delivery, continue?')"
     }
     default {
       ossweb::widget form_mqueue.message_id -type text -datatype integer -optional -html { size 10 }
       ossweb::widget form_mqueue.message_type -type select -datatype name -optional \
            -empty " --"  -options { { Email email } }
       ossweb::widget form_mqueue.create_date -type date -datatype date -range \
            -format "DR MONTH YYYY" -optional
       ossweb::widget form_mqueue.sent_flag -type select -optional \
            -empty " --"  -options { { Yes Y } { No N } }
       ossweb::widget form_mqueue.error_msg -type text -optional -html { size 10 }
       ossweb::widget form_mqueue.rcpt_to -type text -optional -html { size 10 }
       ossweb::widget form_mqueue.mail_from -type text -optional -html { size 10 }
       ossweb::widget form_mqueue.subject -type text -optional -html { size 10 }
       ossweb::widget form_mqueue.cmd -type hidden -value search -freeze
       ossweb::widget form_mqueue.reset -type reset -label Reset -clear
       ossweb::widget form_mqueue.search -type submit -label Search
     }
    }
}

# Columns for mqueue table
set columns { message_id int ""
              page var 1
              force var f }

ossweb::conn::process \
         -columns $columns \
         -forms { form_mqueue } -form_recreate t \
         -on_error { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            delete {
              -validate { { message_id int "" } }
              -exec { mqueue_action }
              -next { -cmd_name view }
              -on_error { -cmd_name edit }
            }
            schedule {
              -validate { { message_id int "" } }
              -exec { mqueue_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            edit {
              -exec { mqueue_edit }
            }
            default {
              -exec { mqueue_list }
              -on_error_set_cmd ""
            }
         }

