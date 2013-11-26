# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001
#
# $Id: schedule.tcl 2781 2007-01-18 20:51:38Z vlad $

# Initialize scheduler
ossweb::register_init ossweb::schedule::init

# Initialize all scheduling routines
proc ossweb::schedule::init { { task_id "" } } {

    # Default schedules
    ns_schedule_proc -thread 3600 ossweb::schedule::hourly
    ns_schedule_daily -thread [ossweb::config schedule:daily:hour 1] 0 ossweb::schedule::daily
    ns_schedule_weekly -thread [ossweb::config schedule:weekly:day 0] [ossweb::config schedule:weekly:hour 1] 0 ossweb::schedule::weekly

    # Minute intervals
    foreach mins { 1 2 3 4 5 10 15 20 25 30 35 40 45 50 55 } {
      if { [set procs [eval namespace eval ::ossweb::schedule::minutely::$mins { info procs }]] != "" } {
        set schedule_id [eval "ns_schedule_proc -thread [expr $mins*60] {::ossweb::schedule::minutely $mins}"]
        ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling tasks '$procs' with proc ossweb::schedule::minutely every $mins minutes
      }
    }
    # Hour intervals
    foreach hrs { 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 21 23 } {
      if { [set procs [eval namespace eval ::ossweb::schedule::hourly::$hrs { info procs }]] != "" } {
        set schedule_id [eval "ns_schedule_proc -thread [expr $hrs*3600] {::ossweb::schedule::hourly $hrs}"]
        ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling tasks '$procs' with proc ossweb::schedule::hourly every $hrs hours
      }
    }
    # Daily intervals
    foreach day { 2 3 4 5 6 7 } {
      if { [set procs [eval namespace eval ::ossweb::schedule::daily::$day { info procs }]] != "" } {
        set schedule_id [eval "ns_schedule_proc -thread [expr $day*86400] {::ossweb::schedule::daily $day}"]
        ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling tasks '$procs' with proc ossweb::schedule::daily every $day days
      }
    }
    # Weekly intervals
    foreach day { 0 1 2 3 4 5 6 } {
      if { [set procs [eval namespace eval ::ossweb::schedule::weekly::$day { info procs }]] != "" } {
        set schedule_id [eval "ns_schedule_weekly -thread $day 3 0 {::ossweb::schedule::weekly $day}"]
        ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling tasks '$procs' with proc ossweb::schedule::weekly every $day of week
      }
    }
    # Monthly intervals
    foreach day { 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 21 23 24 25 26 27 28 29 30 31 } {
      if { [set procs [eval namespace eval ::ossweb::schedule::monthly::$day { info procs }]] != "" } {
        set schedule_id [eval "ns_schedule_dayly -thread 3 0 {::ossweb::schedule::monthly $day}"]
        ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling tasks '$procs' with proc ossweb::schedule::mnonthly on $day of every month
      }
    }

    # Database based schedules, if table does not exist just exit
    if { ![ossweb::true [ossweb::param server:scheduler 1]] || [ossweb::db::columns ossweb_schedule] == "" } {
      ns_log Notice ossweb::schedule::init: scheduling disabled
      return 0
    }

    set task_count 0
    ossweb::db::foreach sql:ossweb.schedule.list_enabled {
      # Run global procs or those assigned for this server only
      set servername [ns_info server]
      set hostname [ns_info hostname]
      if { $task_server != "" } {
        set flag 0
        foreach server $task_server {
          foreach { server host } [split $server "@"] {}
          if { "$server@[ossweb::nvl $host $hostname]" == "$servername@$hostname" } {
            incr flag
          }
        }
        if { $flag == 0 } {
          ns_log Notice ossweb::schedule::init: Incorrect server '$task_server' for '$task_proc'
          continue
        }
      }
      if { [namespace eval :: "info procs [lindex $task_proc 0]"] == "" &&
           [namespace eval :: "info command [lindex $task_proc 0]"] == "" } {
        ns_log Notice ossweb::schedule::init: Unknown proc '$task_proc'
        continue
      }
      set task_thread [ossweb::decode $task_thread "t" "-thread" ""]
      set task_once [ossweb::decode $task_once "t" "-once" ""]
      set schedule_id ""
      incr task_count
      if { $task_interval > 0 } {
        set schedule_id [eval "ns_schedule_proc $task_once $task_thread $task_interval {$task_proc $task_args}"]
        ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling task $task_name with proc $task_proc with interval $task_interval
      } else {
        if { $task_wday != "" || $task_mday != "" } {
          foreach time $task_time {
            foreach { task_hour task_minute } [split $time ":"] {}
            if { $task_hour == "" || $task_minute == "" } { continue }
            set schedule_id [eval "ns_schedule_daily $task_once $task_thread $task_hour $task_minute {ossweb::schedule::run {$task_proc $task_args} -weekdays {$task_wday} -monthdays {$task_mday}}"]
            ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling task $task_name with proc $task_proc every $task_wday day(s) of week/every $task_mday day(s) of month at $task_hour:$task_minute
          }
        } elseif { $task_time != "" } {
          foreach time $task_time {
            foreach { task_hour task_minute } [split $time ":"] {}
            if { $task_hour == "" || $task_minute == "" } { continue }
            set schedule_id [eval "ns_schedule_daily $task_once $task_thread $task_hour $task_minute {$task_proc $task_args}"]
            ns_log Notice ossweb::schedule::init: $schedule_id: Scheduling daily task $task_name with proc $task_proc every $task_hour:$task_minute
          }
        } else {
          ns_log Notice ossweb::schedule::init: Invalid interval/time for record '$task_proc'
        }
      }
    }
    return $task_count
}

# Schedule task to run in the background as soon as the job queue is ready
proc ossweb::schedule::job { args } {

    ns_parseargs { {-jobid ""} {-exists f} args } $args

    if { $exists == "t" } {
      if { $jobid != "" } {
        return [ns_job exists __ossweb_jobs $jobid]
      }
      return 0
    }
    if { [catch { ns_job queue -detached -jobid $jobid __ossweb_jobs "$args" } errmsg] } {
      ns_log Error ossweb::schedule::job: $errmsg
    }
}

# Eval Tcl proc if current weekday is the same as specified
# week_days contains list with week days, where Sunday is 0
proc ossweb::schedule::run { proc_name args } {

    ns_parseargs { {-weekdays ""} {-monthdays ""} } $args

    set now [::clock seconds]
    set wday [ossweb::trim0 [::clock format $now -format "%w"]]
    set mday [ossweb::trim0 [::clock format $now -format "%d"]]
    set mon [ossweb::trim0 [::clock format $now -format "%m"]]

    # Verify day of the week
    if { $weekdays != "" && ![ossweb::lexists $weekdays $wday] } {
      ns_log Notice ossweb::schedule::run: $proc_name: $weekdays:$monthdays: ($wday:$mday/$mon) day ignored
      return
    }
    # Verify day of the month
    if { $monthdays != "" && ![ossweb::lexists $monthdays $mday] } {
      ns_log Notice ossweb::schedule::run: $proc_name: $weekdays:$monthdays: ($wday:$mday/$mon) day ignored
      return
    }
    # Verify holidays
    set holidays [ossweb::config server:holidays ""]
    if { [lsearch -exact $holidays "$mon/$mday"] >= 0 } {
      ns_log Notice ossweb::schedule::run: $proc_name: $weekdays:$monthdays: ($wday:$mday/$mon) holiday ignored
      return
    }
    return [eval $proc_name]
}

proc ossweb::schedule::weekly { args } {

    set day [lindex $args 0]
    set nm ::ossweb::schedule::weekly
    if { [string is integer -strict $day] } {
      append nm ::$day
    }
    ns_thread name ossweb:weekly$day

    foreach proc [lsort [eval "namespace eval $nm { info procs }"]] {
      ns_log Notice $nm: $proc
      if { [catch { ${nm}::$proc } errmsg] } {
        ns_log Error $nm: $proc: $errmsg
      }
    }
}

proc ossweb::schedule::monthly { args } {

    set day [lindex $args 0]
    set mday [ossweb::trim0 [clock format [clock seconds] -format "%d"]]
    # Run on specified day of month only
    if { $day != "" && $mday != $day } {
      return
    }
    set nm ::ossweb::schedule::monthly
    if { [string is integer -strict $day] } {
      append nm ::$day
    }
    ns_thread name ossweb:monthly$day

    foreach proc [lsort [eval "namespace eval $nm { info procs }"]] {
      ns_log Notice $nm: $proc
      if { [catch { ${nm}::$proc } errmsg] } {
        ns_log Error $nm: $proc: $errmsg
      }
    }
}

proc ossweb::schedule::daily { args } {

    set day [lindex $args 0]
    set nm ::ossweb::schedule::daily
    if { [string is integer -strict $day] } {
      append nm ::$day
    }
    ns_thread name ossweb:daily$day

    foreach proc [lsort [eval "namespace eval $nm { info procs }"]] {
      ns_log Notice $nm: $proc
      if { [catch { ${nm}::$proc } errmsg] } {
        ns_log Error $nm: $proc: $errmsg
      }
    }
}

proc ossweb::schedule::hourly { args } {

    set hrs [lindex $args 0]
    set nm ::ossweb::schedule::hourly
    if { [string is integer -strict $hrs] } {
      append nm ::$hrs
    }
    ns_thread name ossweb:hourly$hrs

    foreach proc [lsort [eval "namespace eval $nm { info procs }"]] {
      ns_log Notice $nm: $proc
      if { [catch { ${nm}::$proc } errmsg] } {
        ns_log Error $nm: $proc: $errmsg
      }
    }
}

proc ossweb::schedule::minutely { args } {

    set mins [lindex $args 0]
    set nm ::ossweb::schedule::minutely
    if { [string is integer -strict $mins] } {
      append nm ::$mins
    }
    ns_thread name ossweb:minutely$mins

    foreach proc [lsort [eval namespace eval $nm { info procs }]] {
      if { [catch { ${nm}::$proc } errmsg] } {
        ns_log Error $nm: $proc: $errmsg
      }
    }
}

# Update full text search index
proc ossweb::schedule::hourly::tsearch {} {

    if { [ossweb::true [ossweb::config server:tsearch 1]] } {
      ossweb::schedule::job -jobid ossweb:tsearch ossweb::schedule::tsearch
    }
}

# Scheduler watcher
proc ossweb::schedule::hourly::watcher {} {

    if { [ossweb::config schedule:watcher] == "" } { return }

    # Check log file size, if too big then roll it
    if { [file size [ns_info log]] > 1024*1024*1024 } {
      ns_logroll
    }

    set text ""
    foreach task [ns_info schedule] {
      if { [lindex $task 3] != [lindex $task 4] && [lindex $task 3] < [ns_time] } {
        append text "ID: [lindex $task 0]\n"
        append text "Interval: [lindex $task 2]\n"
        append text "Last run: [ns_fmttime [lindex $task 4]]\n"
        append text "Next run: [ns_fmttime [lindex $task 3]]\n"
        append text "Proc: [lindex $task end]\n"
        append text "-------------------------------\n\n"
      }
    }
    if { $text == "" } { return }

    if { [set email [ossweb::config server:admin]] != "" } {
      ossweb::sendmail $email oss "OSSWEB: Schedule time problems" $text
    } else {
      ns_log Error ossweb::schedule::hourly::watcher: $text
    }
}

# Scans configured log files for error messages, if called without configuration
# it will scan current server's log file by default
proc ossweb::schedule::hourly::logwatcher {} {

    foreach { server log } [ossweb::config logwatcher:config "[ns_info server] [ns_info log]"] {
      ossweb::schedule::logwatcher $server $log
    }
    return
}

# Deletes expired properties, cleanup expired cache entries
proc ossweb::schedule::daily::sessioncleanup {} {

    ossweb::cache cleanup *

    if { ![ossweb::database] } {
       return
    }

    ossweb::db::exec sql:ossweb.user.property.cleanup
    ossweb::db::exec sql:ossweb.user.session.cleanup
    ns_db bouncepool [ns_db poolname [ossweb::db::handle]]
    
    return
}

# Notification about unsent messages
proc ossweb::schedule::daily::mqueuewatcher {} {

    if { ![ossweb::database] } {
       return
    }

    set text ""
    ossweb::db::foreach sql:ossweb.message_queue.list.unsent.yesterday {
      append text "ID: $message_id\n"
      append text "Date: $create_date\n"
      append text "From: $mail_from\n"
      append text "To: $rcpt_to\n"
      append text "Subject: $subject\n"
      append text "Args: $args\n"
      append text "Text: [string range $body 0 50]\n"
      append text "-------------------------------\n\n"
    }
    if { $text == "" } { return }

    if { [set email [ossweb::config server:admin]] != "" } {
      ossweb::sendmail $email oss "OSSWEB: Unsent messages for [ns_fmttime [expr [ns_time]-86400] "%m/%d/%Y"]" $text
    } else {
      ns_log Error ossweb::schedule::daily::mqueuematcher: $text
    }
}

# Run mail delivery every 1 minute
proc ossweb::schedule::minutely::1::mqueue { args } {

    if { ![ossweb::database] } {
       return
    }

    ossweb::schedule::job -jobid ossweb:mqueue ossweb::schedule::mqueue
}

# Perform mail deliver from the mail queue
proc ossweb::schedule::mqueue { args } {

    variable mqueue_lock

    if { [ossweb::db::columns ossweb_message_queue] == "" } { return }
    if { [ns_mutex trylock $mqueue_lock] } { return }

    if { [catch {
      foreach rec [ossweb::db::multilist sql:ossweb.message_queue.list] {
        foreach { message_id message_type rcpt_to mail_from subject body args } $rec {}
        set errmsg ""
        set sent_flag Y
        set delivery_type ""
        switch -exact $message_type {
         popup {
           set body "From: $mail_from<BR>Subject: $subject<P>$body"
           set user_email [ossweb::convert::string_to_list $rcpt_to -separator ","]
           foreach user_id [ossweb::db::list sql:ossweb.user.search] {
             ossweb::admin::send_popup $body -user_id $user_id
           }
         }

         default {
           set cc ""
           set bcc ""
           # args are SMTP headers
           set hdrs [ns_set new]
           foreach { name value } $args {
             set name [string trim [string tolower $name]]
             set value [string trim [string tolower $value]]
             if { $value == "" || $name == "" } { continue }
             switch $name {
              cc {
                 append cc ,$value
              }
              bcc {
                 append bcc ,$value
              }
              x-delivery-type {
                 set delivery_type $value
              }
              default {
                 ns_set update $hdrs $name $value
              }
             }
           }
           set cc [ossweb::convert::string_to_list $cc -separator ","]
           set bcc [ossweb::convert::string_to_list $bcc -separator ","]
           set rcpt_to [ossweb::convert::string_to_list $rcpt_to -separator ","]
           # Delivery method
           switch -- $delivery_type {
            individual {
              set count 0
              set error_count 0
              foreach email [lsort -unique [string tolower "$rcpt_to $cc $bcc"]] {
                if { [catch { ns_sendmail $email $mail_from $subject $body $hdrs } errmsg] } {
                  ns_log Error ossweb::mqueue::schedule: $message_id: $email: $mail_from: $subject: $errmsg
                  incr error_count
                }
                incr count
              }
              if { $count == $error_count } { set sent_flag N }
            }

            hidden {
              set bcc [join [lsort -unique [string tolower "$rcpt_to $cc $bcc"]] ,]
              if { [catch { ns_sendmail $mail_from $mail_from $subject $body $hdrs $bcc } errmsg] } {
                ns_log Error ossweb::mqueue::schedule: $message_id: $bcc: $mail_from: $subject: $errmsg
                set sent_flag N
              }
            }

            default {
              set cc [join $cc ,]
              set bcc [join $bcc ,]
              set rcpt_to [join $rcpt_to ,]
              if { [catch { ns_sendmail $rcpt_to $mail_from $subject $body $hdrs $bcc $cc } errmsg] } {
                ns_log Error ossweb::mqueue::schedule: $message_id: $rcpt_to: $mail_from: $subject: $errmsg
                set sent_flag N
              }
            }
           }
           ns_set free $hdrs
         }
        }
        ossweb::db::exec sql:ossweb.message_queue.update.try_count
      }
    } errmsg] } {
      ns_log Error ossweb::schedule::mqueue: $errmsg
    }
    ns_mutex unlock $mqueue_lock
    return
}

# Watches individual log file for error messages and sends them to admin
proc ossweb::schedule::logwatcher { server log } {

    if { $server == "" || $log == "" } { return }

    set server "$server@[ns_info hostname]"
    set email [ossweb::config logwatcher:email]
    if { $email == "" } {
      ns_log Error "ossweb::log::watcher: $server: Email address is not specified as 'logwatcher:email'"
      return
    }

    if { [catch {
         set size [file size $log]
         set FD [open $log r]
       } errmsg] } {
      ns_log Notice "ossweb::log::watcher: $server: $errmsg"
      return
    }
    set position [ossweb::conn::get_property logwatcher:position:$server -user_id 0 -global t -default 0]
    if { $size < $position } {
      set $position 0
    }
    if { [expr $size - $position] > 1000000 } {
      set position [expr $size - 1000000]
    }
    # Read log file contents
    seek $FD $position
    set chunk [read $FD]
    close $FD

    set ignore [ossweb::config logwatcher:ignore]
    set errors {}
    set lines [split $chunk "\n"]
    set count [llength $lines]
    for { set index 0 } { $index < $count } { incr index } {
      set line [lindex $lines $index]
      # Identify error line
      if { [regexp {^(\[[^]]*\])(\[[^]]*\])(\[[^]]*\]) Error: (.*)$} $line match date process thread error_string] } {
        # Handle multiple lines error message, append all lines which don't begin with date
	    set index2 0
	    while { $index2 < 1 } {
      	  incr index
	      if { $index >= $count } { break }
	      set line2 [lindex $lines $index]
	      if { [regexp {^\[[0-9][0-9]/[A-Z][a-z][a-z]/[0-9][0-9][0-9][0-9]:[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\]\[[0-9a-f.]+\]\[[^]]+\]} $line2] } {
	        incr index2
	      }
	      if { $index2 < 1 } {
	        append line "\n$line2"
	      } else {
	        incr index -1
	      }
	    }
        # Check ignore list
        if { $ignore != "" && [regexp $ignore $error_string] } { continue }
        lappend errors $line
      }
    }
    if { $errors != "" } {
      set body "The following [llength $errors] errors have been found\nin log file $server:$log:\n\n"
      foreach error $errors {
        append body "---------------\n$error\n\n"
      }
      if { [ossweb::sendmail $email logwatcher "LOGWATCHER: $server: Error messages" $body -direct t] == -1 } {
        return
      }
      ns_log Notice "ossweb::log::watcher: $server: found [llength $errors] errors in $log"
    }
    # Save current position
    ossweb::conn::set_property logwatcher:position:$server $size -user_id 0 -global t
    return
}

# Full text search robot
proc ossweb::schedule::tsearch { args } {

    ns_parseargs { {-types ""} {-iterations 1} {-sleep 5} {-empty ""} {-hours {09 12 15 18 21}} } $args

    # Run on specified hours only, this is hourly handler
    if { $hours != "" && [lsearch -exact $hours [ns_fmttime [ns_time] %H]] == -1 } { return }

    ns_log Notice ossweb::schedule::tsearch: started

    foreach name [namespace eval ::ossweb::tsearch { info procs }] {
      if { $types != "" && [lsearch -exact $types $name] == -1 } {
        continue
      }
      set count 0
      while { $count < $iterations } {
         set tsearch_list [::ossweb::tsearch::$name get]
         if { [llength $tsearch_list] == 0 } {
           break
         }
         ns_log Notice ossweb::schedule::tsearch: $name: found [llength $tsearch_list] records
         foreach tsearch_row $tsearch_list {
           foreach { tsearch_op tsearch_type tsearch_id tsearch_text tsearch_data tsearch_value } $tsearch_row {}
           if { $tsearch_id == "" || $tsearch_type == "" } {
             continue
           }
           if { $tsearch_op == "D" } {
             ossweb::db::exec sql:ossweb.tsearch.delete
             continue
           }
           set tsearch_text [ossweb::nvl [string trim [ns_striphtml $tsearch_text]] $empty]
           if { $tsearch_op == "U" } {
             ossweb::db::exec sql:ossweb.tsearch.update
             if { [ossweb::db::rowcount] } {
               continue
             }
           }
           ossweb::db::exec sql:ossweb.tsearch.create
         }
         incr count
      }
      ns_sleep $sleep
    }
    ns_log Notice ossweb::schedule::tsearch: finished
}

