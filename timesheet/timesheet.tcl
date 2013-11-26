# Author: Vlad Seryakov vlad@crystalballinc.com 
# October 2001

ossweb::conn::callback timesheet_action {} {

    switch ${ossweb:cmd} {
     add {
        # If not full interval format assume hours
        if { [string first : $hours] == -1 } {
          append hours " hours"
        }
        if { [ossweb::db::exec sql:timesheet.create] } {
          error "OSSWEB: Unable to add new timesheet record"
        }
     }
     delete {
        if { [ossweb::db::exec sql:timesheet.delete] } {
          error "OSSWEB: Unable to delete timesheet record"
        }
     }
    }
}

# Day view
ossweb::conn::callback timesheet_view {} {

    ossweb::db::foreach sql:timesheet.costcode.list {
      lappend cost($_job_id) "$_costcode_id|$_costcode_name"
    } -prefix _
    foreach { name value } [array get cost] {
      append ts_list "tsList\['$name'\] = '[join $value "&"]';\n"
    }
    set day_title "Field/Service Timesheet for $ts_date"
    set week [ossweb::date weekArray $Day $Month $Year]
    set week "[lindex $week 0] to [lindex $week end]"
    set week [ossweb::html::link -text $week cmd week ts_date $ts_date]
    
    # Retrieve all hour records
    ossweb::db::multirow timesheets sql:timesheet.read.day -eval {
      set row(edit) [ossweb::html::link -image trash.gif -alt Delete cmd delete ts_date $ts_date ts_id $row(ts_id)]
      incr total $row(hours)
    }
    set job_id ""
    set hour_code R
    ossweb::form form_timesheet set_values
}

# Week view
ossweb::conn::callback timesheet_week {} {

    set week [ossweb::date weekArray $Day $Month $Year]
    set week_title "Week from [lindex $week 0] to [lindex $week end]"
    set sun_title [ossweb::html::link -text "Sunday [lindex $week 0]" cmd view ts_date [lindex $week 0] user_id $user_id]
    set mon_title [ossweb::html::link -text "Monday [lindex $week 1]" cmd view ts_date [lindex $week 1] user_id $user_id]
    set tue_title [ossweb::html::link -text "Tuesday [lindex $week 2]" cmd view ts_date [lindex $week 2] user_id $user_id]
    set wed_title [ossweb::html::link -text "Wednesday [lindex $week 3]" cmd view ts_date [lindex $week 3] user_id $user_id]
    set thu_title [ossweb::html::link -text "Thursday [lindex $week 4]" cmd view ts_date [lindex $week 4] user_id $user_id]
    set fri_title [ossweb::html::link -text "Friday [lindex $week 5]" cmd view ts_date [lindex $week 5] user_id $user_id]
    set sat_title [ossweb::html::link -text "Saturday [lindex $week 6]" cmd view ts_date [lindex $week 6] user_id $user_id]
    set dow_list { sun_list mon_list tue_list wed_list thu_list fri_list sat_list }
    foreach name $dow_list { set $name [list] }
    
    # Retrieve all hour records
    ossweb::db::multirow timesheets sql:timesheet.read.week -eval {
      incr total $row(hours)
      set name [lindex $dow_list $row(dow)]
      set item "<TD>$department</TD>
                <TD>$row(type_name)</TD>
                <TD>$row(job_name)</TD>
                <TD>$row(costcode_name)</TD>
                <TD>$row(ts_time)</TD>
                <TD>$row(hours)</TD>"
      lappend $name $item
    }
    ossweb::form form_timesheet set_values
}

ossweb::conn::callback create_form_timesheet {} {

    ossweb::form form_timesheet -title "Field/Service Timesheet"
    ossweb::widget form_timesheet.user_name -type inform -label "User Name"
    ossweb::widget form_timesheet.department -type inform -label "Department"
    ossweb::widget form_timesheet.week -type inform -label "Week View"
    ossweb::widget form_timesheet.ts_id -type hidden -optional
    ossweb::widget form_timesheet.ts_date -type hidden
    ossweb::widget form_timesheet.cmd -type hidden -value add -freeze
    ossweb::widget form_timesheet.hour_code -type select -label "Hour Code" \
         -options [ossweb::db::multilist sql:timesheet.hour_type.list]
    ossweb::widget form_timesheet.job_id -type select -label "Job#/Sub Job#" \
         -empty "Select One" \
         -html { onChange tsUpdate(this.form) } \
         -options [ossweb::db::multilist sql:timesheet.job.list]
    ossweb::widget form_timesheet.costcode_id -type select -label "Cost Code" \
         -options {}
    ossweb::widget form_timesheet.ts_time -type select -label "Start Time" \
         -optional \
         -options { { 00:00 00:00 }
                    { 00:30 00:30 }
                    { 01:00 01:00 }
                    { 01:30 01:30 }
                    { 02:00 02:00 }
                    { 02:30 02:30 }
                    { 03:00 03:00 }
                    { 03:30 03:30 }
                    { 04:00 04:00 }
                    { 04:30 04:30 }
                    { 05:00 05:00 }
                    { 05:30 05:30 }
                    { 06:00 06:00 }
                    { 06:30 06:30 }
                    { 07:00 07:00 }
                    { 00:30 07:30 }
                    { 08:00 08:00 }
                    { 08:30 08:30 }
                    { 09:00 09:00 }
                    { 09:30 09:30 }
                    { 10:00 10:00 }
                    { 10:30 10:30 }
                    { 11:00 11:00 }
                    { 11:30 11:30 }
                    { 12:00 12:00 }
                    { 12:30 12:30 }
                    { 13:00 13:00 }
                    { 13:30 13:30 }
                    { 14:00 14:00 }
                    { 14:30 14:30 }
                    { 15:00 15:00 }
                    { 15:30 15:30 }
                    { 16:00 16:00 }
                    { 16:30 16:30 }
                    { 17:00 17:00 }
                    { 17:30 17:30 }
                    { 18:00 18:00 }
                    { 18:30 18:30 }
                    { 19:00 19:00 }
                    { 19:30 19:30 }
                    { 20:00 20:00 }
                    { 20:30 20:30 }
                    { 21:00 21:00 }
                    { 21:30 21:30 }
                    { 22:00 22:00 }
                    { 22:30 22:30 }
                    { 23:00 23:00 }
                    { 23:30 23:30 } }
    ossweb::widget form_timesheet.hours -type text -label "Hours" \
         -datatype integer -html { size 5 maxlength 5 }
    ossweb::widget form_timesheet.add -type submit -label Add
}

ossweb::conn::callback timesheet_user {} {

    # Admin has rights to see timesheets of other users
    set admin [ossweb::conn::check_acl -acl "*.timesheet.admin"]
    if { $admin || $user_id == "" } { set user_id [ossweb::conn user_id] }
    ossweb::db::multivalue sql:timesheet.read.user
    if { !$admin } {
      # Create admin form for choosing users
      ossweb::form form_user -title "Employees"
      ossweb::widget form_user.cmd -type hidden
      ossweb::widget form_user.user_id -type select -label "Employee" \
                  -options [ossweb::db::multilist sql:ossweb.user.select.read] \
                  -html { onChange "this.form.submit()" } \
                  -value $user_id
    }
    # Parse date
    if { ![regexp {([0-9]+)-([0-9]+)-([0-9]+)} $ts_date d Year Month Day] &&
         ![regexp {([0-9]+)/([0-9]+)/([0-9]+)} $ts_date d Month Day Year] } {
      error "OSSWEB:Invalid date format $ts_date"
    }
}

set columns { ts_id int ""
              ts_list const ""
              ts_date "" {[ns_fmttime [ns_time] "%Y-%m-%d"]}
              total const 0
              user_id int ""
              department const "" }

ossweb::conn::process -columns $columns \
                   -exec { timesheet_user } \
                   -on_error index  \
                   -forms { form_timesheet } \
                   -eval {
                     delete -
                     update -
                     add {
                       -exec { timesheet_action }
                       -on_error { -cmd_name view }
                       -next { -cmd_name view }
                     }
                     week {
                       -exec { timesheet_week }
                     }
                     default {
                       -exec { timesheet_view }
                     }
                   }
