# Author: Vlad Seryakov vlad@crystalballinc.com
# October 2001

ossweb::conn::callback calendar_update {} {

    # Replace date with current date
    set cal_date [ossweb::date date [ossweb::nvl $cal_date $Date]]
    set cal_time [ossweb::date time $cal_time]
    if { $duration > 0 } {
      set duration "$duration $duration_type"
    }

    if { [calendar::create $cal_date $cal_time $subject \
                 -cal_id $cal_id \
                 -duration $duration \
                 -remind $remind \
                 -remind_email $remind_email \
                 -remind_type $remind_type \
                 -remind_args $remind_args \
                 -description $description \
                 -repeat $repeat \
                 -notify $notify \
                 -users $users \
                 -groups $groups \
                 -skip_null t \
                 -type $type] == -1 } {
      error "OSSWEB: Unable to create calendar entry"
    }
    ossweb::form form_calendar reset
}

ossweb::conn::callback calendar_delete {} {

    if { [ossweb::db::exec sql:calendar.delete.user] } {
      error "OSSWEB: Unable to delete record"
    }
    set cal_id ""
    ossweb::form form_calendar reset
}

ossweb::conn::callback calendar_show {} {

    if { [ossweb::db::multivalue sql:calendar.read] } {
      error "OSSWEB: Unable to read calendar record"
    }
    set remind_type [string totitle $remind_type]
    if { $remind_args != "" } {
      foreach { k v } $remind_args { append params "<LI>$k=$v" }
      set remind_args $params
    }
    set description [ossweb::util::wrap_text $description -size 60 -break <BR>]
}

ossweb::conn::callback calendar_reminder {} {

    if { $cal_date == "" } {
      set cal_date $Date
    }
    if { $cal_time == "" } {
      set cal_time $Date
    }
    if { $htmleditor } {
      ossweb::widget form_calendar.description -htmleditor -rows 10
    }
    ossweb::widget form_calendar.ctx -type hidden -value reminder -freeze
    ossweb::widget form_calendar.close -type button -label Close \
         -url "javascript:window.close()"
    ossweb::form form_calendar set_values
}

ossweb::conn::callback calendar_edit {} {

    set user_name [ossweb::db::value sql:ossweb.user.read_name]
    if { $cal_id != "" } {
      if { [ossweb::db::multivalue sql:calendar.read] } {
        error "OSSWEB: Unable to read calendar record"
      }
      set duration_type [lindex $duration 1]
      set duration [lindex $duration 0]
      if { [string index $duration_type end] != "s" } { append duration_type s }
      if { $update_user != $user_id } {
        ossweb::form form_calendar -info "<FONT SIZE=1 COLOR=gray>Updated by $update_user_name</FONT>"
      }
    }
    if { $cal_date == "" } {
      set cal_date $Date
    }
    if { $cal_time == "" } {
      set cal_time $Date
    }
    ossweb::form form_calendar set_values
    ossweb::db::multirow entries sql:calendar.read.day -eval {
      if { $row(cal_id) == $cal_id } {
        set html "STYLE=\"color: red\" "
      } else {
        set html ""
      }
      append html [ossweb::html::popup_handlers C$row(cal_id)]
      set row(subject) [ossweb::html::link -text $row(subject) -html $html calendar cmd edit date $row(cal_date) cal_id $row(cal_id)]
      ossweb::conn -append html:foot [ossweb::html::popup_object C$row(cal_id) $row(description)]
    }
}

ossweb::conn::callback calendar_view {} {

    ossweb::db::foreach sql:calendar.read.month {
      if { $duration <= 0 } { set duration 1 }
      # Repeat for each day according to the duration
      for { set days 1 } { $days <= $duration } { incr days } {
        foreach { month day year } [split $cal_date "/"] {}
        switch $repeat {
         Daily {
            for { set i 1 } { $i <= $Days } { incr i } {
              set dow [ossweb::date dayOfWeek $i $Month $Year]
              if { $dow != 0 && $dow != 6 && $i >= $day } {
                set cal_date "$Month/[ossweb::pad0 $i 2]/$Year"
                append calendar($cal_date) "$cal_time&nbsp;[ossweb::html::link -text $subject -window cal -winopts $winoptions cmd show date $cal_date cal_id $cal_id] <BR>"
              }
            }
         }
         Weekly {
            set dow [ossweb::date dayOfWeek $day $month $year]
            for { set i 1 } { $i <= $Days } { incr i } {
              if { [ossweb::date dayOfWeek $i $Month $Year] == $dow &&
                   (($month >= $Month && $i >= $day) || ($month < $Month))} {
                set cal_date "$Month/[ossweb::pad0 $i 2]/$Year"
                append calendar($cal_date) "$cal_time&nbsp;[ossweb::html::link -text $subject -window cal -winopts $winoptions -onMouseOver "pagePopupGet('[ossweb::html::url cmd show date $cal_date cal_id $cal_id]')" -onMouseOut "pagePopupClose()" cmd show date $cal_date cal_id $cal_id] <BR>"
              }
            }
         }
         Yearly -
         Monthly {
            set cal_date "$Month/$day/$Year"
            append calendar($cal_date) "$cal_time&nbsp;[ossweb::html::link -text $subject -window cal -winopts $winoptions cmd show date $cal_date cal_id $cal_id] <BR>"
         }
         default {
            append calendar($cal_date) "$cal_time&nbsp;[ossweb::html::link -text $subject -window cal -winopts $winoptions cmd show date $cal_date cal_id $cal_id] <BR>"
         }
        }
        # Shift to the next date
        set cal_date [ns_fmttime [ossweb::date nextDay $day $month $year] "%m/%d/%Y"]
      }
    }
    # Update Go form
    ossweb::widget form_jump.user_id -value $user_id
    ossweb::widget form_jump.date2 -value $Date
}

ossweb::conn::callback create_form_jump {} {

    ossweb::form form_jump -action [ossweb::html::url calendar]

    ossweb::widget form_jump.user_id -type multiselect -label User \
         -optional \
         -resize \
         -size 2 \
         -options [ossweb::db::multilist sql:ossweb.user.select.read]

    ossweb::widget form_jump.date2 -type date -label Date \
         -format "MONTH YYYY" \
         -optional \
         -year_start 2000

    ossweb::widget form_jump.cmd -type submit -label Go
}

ossweb::conn::callback create_form_calendar {} {

    # Dynamically discover possible reminder callbacks
    set remind_types { { Email email } }
    foreach name [namespace eval ::calendar::reminder info procs] {
      lappend remind_types [list [string totitle $name] $name]
    }
    ossweb::form form_calendar -title "Calendar Entry for $Month / $Day / $Year" \
         -action [ossweb::html::url calendar]

    ossweb::widget form_calendar.date -type hidden -value $date -freeze

    ossweb::widget form_calendar.remind_args -type hidden -optional

    ossweb::widget form_calendar.user_id -type hidden -value $user_id -freeze

    ossweb::widget form_calendar.cal_id -type hidden -datatype integer \
         -optional

    ossweb::widget form_calendar.cal_date -type date -label "Date" \
         -format "MM / DD / YYYY" \
         -calendar \
         -optional

    ossweb::widget form_calendar.cal_time -type date -label "Time" \
         -format "HH24 : MI" \
         -minutes_step 5

    ossweb::widget form_calendar.duration -type select -label "Duration" \
         -options [ossweb::option_list 1 60 1] \
         -optional

    ossweb::widget form_calendar.duration_type -type select -label "Duration Type" \
         -empty -- \
         -options { { Minutes minutes }
                    { Hours hours }
                    { Days days }
                    { Weeks weeks }
                    { Months months } } \
         -optional

    ossweb::widget form_calendar.subject -label "Subject" \
         -html { size 40 }

    ossweb::widget form_calendar.description -type textarea -label "Description" \
         -rows 5 \
         -cols 50 \
         -resize \
         -optional

    ossweb::widget form_calendar.owner -type label -label "Owner" \
         -eval { if { $owner == "" } { return } }

    ossweb::widget form_calendar.remind -type select -label "Send Before" \
         -optional \
         -options { { None "" }
                    { "5 Minutes" "00:05:00" }
                    { "10 Minutes" "00:10:00" }
                    { "15 Minutes" "00:15:00" }
                    { "20 Minutes" "00:20:00" }
                    { "25 Minutes" "00:25:00" }
                    { "30 Minutes" "00:30:00" }
                    { "35 Minutes" "00:35:00" }
                    { "45 Minutes" "00:45:00" }
                    { "50 Minutes" "00:50:00" }
                    { "1 Hour" "01:00:00" }
                    { "2 Hours" "02:00:00" }
                    { "3 Hours" "03:00:00" }
                    { "4 Hours" "04:00:00" }
                    { "5 Hours" "05:00:00" }
                    { "6 Hours" "06:00:00" }
                    { "8 Hours" "08:00:00" }
                    { "12 Hours" "12:00:00" }
                    { "1 Day" "1 day" }
                    { "2 Days" "2 days" }
                    { "3 Days" "3 days" }
                    { "4 Days" "4 days" }
                    { "5 Days" "5 days" }
                    { "6 Days" "6 days" }
                    { "7 Days" "7 days" }
                    { "10 Days" "10 days" }
                    { "14 Days" "14 days" }
                    { "1 Month" "1 mon" }
                    { "2 Months" "2 mons" }
                    { "3 Months" "3 mons" }
                    { "1 Year" "1 year" }
                  }

    ossweb::widget form_calendar.remind_email -type text -label "Send Also To (email)" \
         -optional

    ossweb::widget form_calendar.remind_type -type select -label "Type" \
         -optional \
         -options $remind_types

    ossweb::widget form_calendar.repeat -type select -label "Repeat Event" \
         -optional \
         -options { { None None }
                    { Daily Daily }
                    { Weekly Weekly }
                    { Monthly Monthly }
                    { Yearly Yearly } }

    ossweb::widget form_calendar.type -type select -label "Event Type" \
         -options { { Normal Normal }
                    { Private Private }
                    { Public Public } }

    ossweb::widget form_calendar.users -type multiselect -label "Assign To Users" \
         -optional \
         -html { size 3 } \
         -options [ossweb::db::multilist sql:ossweb.user.select.read]

    ossweb::widget form_calendar.groups -type multiselect -label "Assign To Group" \
         -optional \
         -html { size 3 } \
         -options [ossweb::db::multilist sql:ossweb.group.select.read]

    ossweb::widget form_calendar.notify -type checkbox -label "Notify Users" \
         -optional \
         -value Y \
         -labelhelp "Send email about calendar event for everybody"

    ossweb::widget form_calendar.add -name cmd -type submit -label Add \
         -eval { if { $user_id != [ossweb::conn user_id] } { return } }

    ossweb::widget form_calendar.update -name cmd -type submit -label Update \
         -eval { if { $user_id != [ossweb::conn user_id] } { return } }

    ossweb::widget form_calendar.new -name cmd -type button -label New \
         -url [ossweb::html::url cmd edit date $date]

    ossweb::widget form_calendar.delete -name cmd -type button -label Delete \
         -eval { if { $cal_id == {} || $user_id != [ossweb::conn user_id] } { return } } \
         -confirm { confirm('Record will be deleted, continue?') } \
         -url [ossweb::html::url cmd delete cal_id $cal_id date $date]
}

set columns { cal_id int ""
              cal_date "" ""
              cal_time "" ""
              subject "" ""
              repeat "" ""
              remind "" ""
              remind_type "" ""
              remind_args crypt ""
              htmleditor int 0
              type "" ""
              date "" {[ns_time]}
              user_id ilist {[ossweb::conn user_id]}
              winoptions const "menubar=0,location=0,scrollbars=1,width=550,height=500"
            }

ossweb::conn::process -columns $columns \
           -on_error { -cmd_name index } \
           -exec {
              set Date [ossweb::date parse2 $date]
              # Get date from the Go form
              if { [set Month [ns_queryget date2_month]] != "" } {
                set Date [ossweb::date -set $Date month $Month day 1]
                set date [ossweb::date clock $Date]
              }
              if { [set Year [ns_queryget date2_year]] != "" } {
                set Date [ossweb::date -set $Date year $Year day 1]
                set date [ossweb::date clock $Date]
              }
              set Day [ossweb::date day $Date]
              set Month [ossweb::date month $Date]
              set Year [ossweb::date year $Date]
              set Dow [ossweb::date dow $Date]
              set WeekDay [ossweb::date weekDayName $Dow]
              set Days [ossweb::date daysInMonth $Month]
              set MonthName [ossweb::date monthName $Month]
              set DayUrl [ossweb::html::url cmd edit.calendar user_id $user_id]
              set MoveUrl [ossweb::html::url cmd calendar user_id $user_id]
           } \
           -eval {
               error {
               }
               add -
               update {
                 -forms form_calendar
                 -exec { calendar_update }
                 -next { -cmd_name edit }
                 -on_error { -cmd_name edit }
               }
               delete {
                 -forms form_calendar
                 -exec { calendar_delete }
                 -next { -cmd_name edit }
                 -on_error { -cmd_name edit }
               }
               show {
                 -exec { calendar_show }
                 -on_error { -cmd_name error }
               }
               reminder {
                 -forms form_calendar
                 -exec { calendar_reminder }
               }
               edit.reminder {
               }
               edit {
                 -forms form_calendar
                 -exec { calendar_edit }
               }
               default {
                 -forms form_jump
                 -exec { calendar_view }
               }
             }
