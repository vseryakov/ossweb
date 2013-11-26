# Author Vlad Seryakov : vlad@crystalballinc.com
# May 2006

ossweb::conn::callback tracker_init {} {

   ns_log Notice tracker: $tracker_id: ${ossweb:cmd}: [ossweb::conn user_id]
   if { $tracker_id == "" || [ossweb::db::multivalue sql:calendar.tracker.read] } {
     error "OSS: Invalid tracker request, either url or event is invalid"
   }
   if { [ossweb::db::value sql:calendar.tracker.accepted] == 1 } {
     error "OSS: This event is already Accepted, no other actions are required. Thank you"
   }
}

ossweb::conn::callback tracker_redirect {} {

   # If specified, transfer user to the destination page
   if { $tracker_redirect != "" } {
     if { [string match http://* $tracker_redirect] } {
       ossweb::conn::redirect $tracker_redirect
     } else {
       eval ossweb::conn::next $tracker_redirect
     }
   }
}

ossweb::conn::callback tracker_accept {} {

   tracker_init
   ossweb::db::exec sql:calendar.tracker.update.status -vars {status Accepted}
   # Update all remaining records to close this tracker event
   ossweb::db::exec sql:calendar.tracker.update.unused
   ossweb::conn::set_msg "Event has been accepted. Thank you."
   tracker_redirect
}

ossweb::conn::callback tracker_reject {} {

   tracker_init
   ossweb::db::exec sql:calendar.tracker.update.status -vars {status Rejected}
   # Update precedence that next person will get email as soon as possible
   ossweb::db::exec sql:calendar.tracker.update.precedence
   ossweb::conn::set_msg "Event has been rejected/declined, we are sorry that you cannot accept this event. Thank you for your time."
}

set columns { tracker_id "" ""
              tracker_redirect const ""
              status const "" }

ossweb::conn::process -columns $columns \
                      -on_error { -cmd_name error } \
                      -eval {
                        accept {
                          -exec { tracker_accept }
                        }
                        reject {
                          -exec { tracker_reject }
                        }
                        error {
                        }
                        default {
                          -exec { ossweb::conn::set_msg "Invalid tracker request" }
                        }
                      }
