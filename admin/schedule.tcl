# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001


ossweb::conn::callback schedule_action {} {

   switch -exact ${ossweb:cmd} {

    stop {
       if { [set id [ns_queryget id]] != "" } {
         ns_unschedule_proc $id
         ossweb::conn::set_msg "Task has been unscheduled"
       }
    }

    start {
       if { [ossweb::schedule::init $task_id] > 0 } {
         ossweb::conn::set_msg "Task has been scheduled"
       } else {
         ossweb::conn::set_msg "Could not schedule the task"
       }
    }

    update {
       if { $task_interval != "" && $task_time != "" } {
         error "OSSWEB: Either Interval or Time(Day) should be specified only, not both"
       }
       if { $task_id == -1 } {
         if { [ossweb::db::exec sql:ossweb.schedule.create] } {
           error "OSSWEB: Operation failed"
         }
         set task_id [ossweb::db::currval ossweb_util]
       } else {
         if { [ossweb::db::exec sql:ossweb.schedule.update] } {
           error "OSSWEB: Operation failed"
         }
       }
       ossweb::conn::set_msg "Record updated"
    }

    delete {
       if { [ossweb::db::exec sql:ossweb.schedule.delete] } {
         error "OSSWEB: operation failed"
       }
       ossweb::conn::set_msg "Record deleted"
    }
   }
}

ossweb::conn::callback schedule_list {} {

    set task_id ""
    set schedule:add [ossweb::html::link -image add.gif -alt Add cmd edit task_id -1]
    set scheduled [ns_info scheduled]
    ossweb::db::multirow schedule sql:ossweb.schedule.list -eval {
       set row(url) [ossweb::html::url cmd edit task_id $row(task_id)]
       if { $row(task_interval) != "" } {
         set row(time) "Every [ossweb::date uptime $row(task_interval)]"
       } else {
         set row(time) ""
         if { $row(task_time) != "" } {
           set row(time) "At $row(task_time) o'clock"
         }
         if { $row(task_wday) != "" } {
           set days { Sun Mon Tue Wed Thu Fri Sat }
           append row(time) " On "
           foreach day $row(task_wday) {
             append row(time) "[lindex $days $day] "
           }
         }
         if { $row(task_mday) != "" } {
           append row(time) " Every "
           append row(time) " [join $row(task_mday) ,] of each month"
         }
       }
       set row(last) ""
       set row(scheduled) ""
       set proc [string trim "$row(task_proc) $row(task_args)"]
       foreach item $scheduled {
         set sproc [lindex $item 8]
         if { [lindex $sproc 0] == "ossweb::schedule::run" } {
           set sproc [lindex $sproc 1]
         }
         set sproc [string trim $sproc]
         if { $proc == $sproc } {
           set row(last) [ns_fmttime [lindex $item 4] "%m/%d/%y %H:%M:%S"]
           set row(scheduled) [ns_fmttime [lindex $item 3] "%m/%d/%y %H:%M:%S"]
           break
         }
       }
    }
}

ossweb::conn::callback schedule_edit {} {

    if { $task_id != -1 } {
      if { [ossweb::db::multivalue sql:ossweb.schedule.read] } {
         error "OSSWEB: Record not found"
      }
      # Hide run button if proc is not available for this server
      if { [info proc ::$task_proc] != "" } {
        set ttime ""
        foreach item [ns_info scheduled] {
          if { [string trim $task_proc] == [string trim [lindex $item 8]] } {
            set ttime [lindex $item 3]
            ossweb::widget form_task.scheduled -type inform -label "Next Run" \
                 -value [ns_fmttime $ttime "%m/%d/%y %H:%M:%S"]
            ossweb::widget form_task.stop -type button -label Stop \
                 -url [ossweb::html::url cmd stop task_id $task_id id [lindex $item 0]]
            break
          }
        }
        if { $ttime == "" } {
          ossweb::widget form_task.start -type button -label Start \
               -url [ossweb::html::url cmd start task_id $task_id]
        }
      } else {
        ossweb::widget form_task.run -type hidden
      }
    }
    if { ${ossweb:cmd} == "run" } {
      if { [catch { eval $task_proc $task_args} errMsg] } {
         error "OSSWEB: $errMsg"
      }
      ossweb::conn::set_msg "Procedure $task_proc $task_args has been run succesfully"
    }
    ossweb::form form_task set_values
}

ossweb::conn::callback create_form_task {} {

    ossweb::form form_task
    ossweb::widget form_task.task_id -type hidden
    ossweb::widget form_task.task_name -type text -label "Title"
    ossweb::widget form_task.task_proc -type text -label "Proc"
    ossweb::widget form_task.task_args -type text -label "Args" \
         -optional
    ossweb::widget form_task.task_interval -type intervalselect -label "Interval (secs)" \
         -optional \
         -empty --
    ossweb::widget form_task.task_wday -type multiselect \
         -label "Day(s) of Week" -optional \
         -html { size 4 } \
         -options { {Sunday 0}
                    {Monday 1}
                    {Tuesday 2}
                    {Wednesday 3}
                    {Thursday 4}
                    {Friday 5}
                    {Saturday 6} }
    ossweb::widget form_task.task_mday -type numberselect -label "Day(s) of Month" \
         -optional \
         -multiple \
         -end 31 \
         -html { size 4 }
    ossweb::widget form_task.task_time -type text -label "Time (HH:MI...)" \
         -optional
    ossweb::widget form_task.task_thread -type boolean -label "Thread"
    ossweb::widget form_task.task_once -type boolean -label "Once"
    ossweb::widget form_task.task_disabled -type boolean -label "Disabled"
    ossweb::widget form_task.task_server -type text -label "Server(s)" \
         -optional
    ossweb::widget form_task.description -type textarea -label Description \
         -html { rows 5 cols 60 } \
         -optional
    ossweb::widget form_task.back -type button -label Back \
         -url [ossweb::html::url cmd view]
    ossweb::widget form_task.update -type submit -name cmd -label Update
    ossweb::widget form_task.delete -type button -label Delete \
         -condition "@task_id@ gt 0" \
         -url [ossweb::html::url cmd delete task_id $task_id] \
         -confirm "confirm('Record will be deleted, continue?')"
    ossweb::widget form_task.run -type button -label Run \
         -condition "@task_id@ gt 0" \
         -url [ossweb::html::url cmd run task_id $task_id]
}

# Table/form columns
set columns { task_id int -2 \
              task_name "" "" \
              task_proc "" "" \
              task_wday list "" \
              task_mday list "" \
              task_time "" "" \
              task_interval int "" \
              task_thread "" "" \
              task_once "" "" \
              task_disabled "" "" \
              task_server "" "" \
              description "" "" }

# Process request parameters
ossweb::conn::process -columns $columns \
            -forms form_task \
            -eval {
               stop -
               start -
               update {
                 -exec { schedule_action }
                 -next { -cmd_name edit }
                 -on_error { -cmd_name edit }
               }
               delete {
                 -exec { schedule_action }
                 -next { -cmd_name view }
                 -on_error { -cmd_name view }
               }
               run -
               edit {
                 -exec { schedule_edit }
                 -on_error { -cmd_name view }
               }
               default {
                 -exec { schedule_list }
                 -on_error { index.index }
               }
            }
