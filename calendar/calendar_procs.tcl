# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2001

namespace eval calendar {
  variable version "Calendar version 1.3"
  namespace eval schedule {}
  namespace eval reminder {}
}

namespace eval oss {
  namespace eval html {
    namespace eval toolbar {}
  }
}

# Link to calendar from the toolbar
proc ossweb::html::toolbar::calendar {} {

    if { [ossweb::conn::check_acl -acl *.calendar.calendar.view.*] } { return }
    append result [ossweb::html::link -image /img/toolbar/calendar.gif -mouseover /img/toolbar/calendar_o.gif -width "" -height "" -hspace 6 -alt Calendar -app_name calendar calendar]
    ossweb::widget c.r -type reminder -image /img/toolbar/remind.gif -mouseover /img/toolbar/remind_o.gif -htmleditor 1 -subject (hex):[ossweb::conn title]
    append result [ossweb::widget c.r html]
    return $result
}

# Runs periodically and checks for all ready reminders to be sent
proc ossweb::schedule::minutely::5::reminder {} {

    foreach item [ossweb::db::multilist sql:calendar.remind.list -array t] {
      foreach { key val } $item { set $key $val }
      ossweb::conn -set user_id $user_id
      if { $remind_proc == "" } {
        # Try specific template first, then generic
        if { [set data [ossweb::util::email_template calendar/reminder.$remind_type calendar/reminder]] != "" } {
          foreach { subject body content_type } $data {}
        } else {
          # Default email template
          set body "Calendar Reminder about event '$subject' on $cal_date at $cal_time\n\n$description"
          set subject "REMINDER: $subject"
          set content_type ""
        }
        ossweb::sendmail $user_email calendar $subject $body \
             -headers "Cc {$remind_email}" \
             -message_type $remind_type \
             -content_type $content_type
      } else {
        # Call reminder callback, pass all columns as name value pairs
        if { [namespace eval :: "info procs $remind_proc"] != "" } {
          ns_log Notice calendar::schedule::reminder: $cal_id: executing $remind_proc
          foreach { key val } $item { lappend remind_proc $key $val }
          foreach { key val } $remind_args { lappend remind_proc $key $val }
          if { [catch { eval $remind_proc } errmsg] } {
            ns_log Error calendar::schedule::reminder: $cal_id: $errmsg
          }
        }
      }
      ossweb::db::exec sql:calendar.remind.create
    }
}

# Create calendar entry
# cal_date is date in format yyyy-mm-dd
# cal_time is time in format hh24:mi
# subject is entry subject
# -duration is number of days this event relates to
# -users a list with user ids who will get the copy of this event in their calendars
# -groups a list of group ids all users of which will get the copy of this event
# -repeat repeatition mode, Daily, Monthly, Yearly
# -remind interval to be notified before the event
# -remind_type email or popup
# -remind_email email address of the person to be reminded too
# -remind_proc defines Tcl proc to be called on event
# -type event type, Normal, Public, Private
# -description body of the message
# -notify if Y, all additional users will get notification about the event
# -user_id user for the event, by default current logged in user
# -cal_id if not null, the event will be updated
# -prefix used in subject for email notifications
proc calendar::create { cal_date cal_time subject args } {

    ns_parseargs { {-duration ""}
                   {-users ""}
                   {-groups ""}
                   {-repeat None}
                   {-remind ""}
                   {-remind_email ""}
                   {-remind_type ""}
                   {-remind_proc ""}
                   {-remind_args ""}
                   {-type Normal}
                   {-description ""}
                   {-notify ""}
                   {-debug f}
                   {-skip_null f}
                   {-user_id {=$ossweb::conn user_id}}
                   {-prefix "CALENDAR: "}
                   {-cal_id ""} } $args

    if { $cal_date == "" || $cal_time == "" || $user_id == "" || [ossweb::db::value sql:ossweb.user.read_email] == ""} {
      ns_log Error calendar::create: $user_id/$cal_date/$cal_time: invalid user/date/time
      return -1
    }
    # Add days interval specification if just a number
    if { [string is integer -strict [string trim $duration]] } {
      append duration days
    }
    # Reminder type specific proc if defined
    if { $remind_type != "" && [info proc ::calendar::reminder::$remind_type] != "" } {
      set remind_proc ::calendar::reminder::$remind_type
    }
    set cal_user $user_id
    ossweb::db::begin
    # Update existing entry
    if { $cal_id > 0 } {
      if { [ossweb::db::exec sql:calendar.update -debug $debug] } {
        ossweb::db::rollback
        return -1
      }
      set cal_owner $cal_id
    } else {
      # Create new entry
      if { [ossweb::db::exec sql:calendar.create -debug $debug] } {
        ossweb::db::rollback
        return -1
      }
      set cal_owner [ossweb::db::currval ossweb_calendar]
    }
    # Add events to users/groups
    if { $groups != "" } {
      lappend users [ossweb::db::list sql:ossweb.user.group.read.by.id]
    }
    foreach user_id [lsort -unique [ossweb::convert::plain_list users]] {
      if { $user_id == $cal_user } { continue }
      if { [ossweb::db::exec sql:calendar.create] } {
        ossweb::db::rollback
        return -1
      }
      # Send notification
      if { $notify == "Y" } {
        if { [set email [ossweb::db::value sql:ossweb.user.read_email]] == "" } { continue }
        set body "[ossweb::conn full_name] has assigned calendar event for you:\n"
        append body "on $cal_date at $cal_time\n\n" $description
        ossweb::sendmail $email calendar "$prefix$subject" $body \
             -message_type $remind_type
      }
    }
    ossweb::db::commit
    return $cal_owner
}

# Calendar feature for tracking specific events by multiple
# responsible people one by one. The idea is to send reminder to
# all parties and let them accept or reject responsibility for the event.
# Emails are sent not all at once but every specified interval, usually
# several minutes so the person can review email and decide what to do.
# Once somebody clicked on accept link, reminders will not be sent anymore
# for that event. If nobody accepted all reminders will be in the database with
# status Sent and report can be generated to see how many events have been missed.
#
# The obvious application for this is trouble ticketing system and callbacks, when
# call center needs to call the customer on some specified date/time. Whoever will be
# available needs to call the customer. The system will send reminders in the following
# order: person who created callback, TT assigned person, then all others.
proc calendar::reminder::tracker { args } {

    foreach { key val } $args { set $key $val }

    # Call checker proc first
    if { [info exists tracker_proc] && [info proc ::$tracker_proc] != "" } {
      catch { eval $tracker_proc $args } rc
      if { $rc != "" } {
        ns_log Notice calendar::reminder::tracker: $rc
        return
      }
    }
    # New tracker record for each user
    set precedence 0
    set tracker_time "$cal_date $cal_time"
    foreach user_id [ossweb::coalesce tracker_users] {
      set tracker_id [ns_sha1 "$cal_id$user_id$cal_date$cal_time"]
      ossweb::db::exec sql:calendar.tracker.create
      incr precedence
    }
}

# Scans for new tracker notifications and send emails
proc calendar::schedule::tracker {} {

    foreach item [ossweb::db::multilist sql:calendar.tracker.list -array t] {
      foreach { key val } $item { set $key $val }
      if { [info exists tracker($cal_id)] } { continue }
      set tracker($cal_id) 1
      # Mark record as sent
      ossweb::db::exec sql:calendar.tracker.update.status -vars {status Sent}
      # Build tracker email
      set accept_url [ossweb::html::url -host t -app_name calendar tracker cmd accept tracker_id $tracker_id]
      set reject_url [ossweb::html::url -host t -app_name calendar tracker cmd reject tracker_id $tracker_id]
      set accept_link [ossweb::html::link -text Accept -url $accept_url]
      set reject_link [ossweb::html::link -text Reject -url $reject_url]
      # Try specific template first, then generic
      if { [set data [ossweb::util::email_template calendar/tracker.[ossweb::coalesce tracker_type] calendar/tracker]] != "" } {
        foreach { subject body content_type } $data {}
      } else {
        # Default email template
        set subject "REMINDER/$precedence: $subject"
        set body "This event needs an action to be performed."
        append body "To accept it, please click on <B>$accept_link</B>."
        append body "To reject/decline, please click on <B>$reject_link</B>"
        append body "<HR><PRE><B>$subject</B><BR>$description</PRE><HR>"
        append body "<FONT SIZE=1>Accept url: $accept_url</FONT><BR>"
        append body "<FONT SIZE=1>Reject url: $reject_url</FONT>"
        set content_type "text/html"
      }
      ns_log Notice calendar::schedule::tracker: $cal_id: $tracker_id/$precedence, sending to $user_email/$user_id
      ossweb::sendmail $user_email calendar $subject $body \
           -content_type $content_type \
           -direct t
    }
}
