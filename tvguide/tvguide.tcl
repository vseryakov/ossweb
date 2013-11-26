# Author: Vlad Seryakov vlad@crystalballinc.com
# June 2004

ossweb::conn::callback tvguide_recorder {} {

    switch -- ${ossweb:ctx} {
     unschedule {
       if { $allow == "" } { error "OSSWEB: Permission denied" }
       tvguide::recorder::unschedule $recorder_id -stop [ns_queryget stop]
       ossweb::conn::set_msg "Program recording has been unscheduled"
     }

     play {
       tvguide::recorder::play $recorder_id [ns_queryget file]
     }
    }
    set ipaddr [ns_conn peeraddr]
    set host [ns_addrbyhost [ns_info hostname]]
    set use_mstream [ossweb::conn tvguide_mstream]
    ossweb::db::multirow recorder sql:tvguide.recorder.list -eval {
      set title $row(program_title)
      if { $row(part_number) != "" } { append title " Part $row(part_number) " }
      if { $row(episode_number) != "" } { append title " Episode $row(episode_number)" }
      set row(program_title) [ossweb::html::link -text $title -window TV -winopts $winopts cmd show recorder_id $row(recorder_id) lookup:mode 2]
      foreach key { file_view file_size file_color action } { set row($key) "" }
      if { $allow != "" } {
        if { $row(file_status) == "Recording" } {
          append row(action) [ossweb::lookup::link -image stop.gif -alt Stop -confirm "confirm('Stop show recoding?')" cmd recorder.unschedule recorder_id $row(recorder_id) stop t] " "
        }
        append row(action) [ossweb::lookup::link -image trash.gif -alt Delete -confirm "confirm('Delete show recoding?')" cmd recorder.unschedule recorder_id $row(recorder_id)]
      }
      if { $row(file_name) != "" && [ossweb::file::exists $row(file_name) -path tvguide] } {
        if { $use_mstream == "t" } {
          set row(file_view) [ossweb::file::link tvguide $row(file_name) -text Play -alt Play -proto mstream:// -host t recorder_id $row(recorder_id)]
        } else {
          set row(file_view) [ossweb::file::link tvguide $row(file_name) -text Download recorder_id $row(recorder_id)]
        }
        if { $ipaddr == "127.0.0.1" || $ipaddr == $host } {
          append row(file_view) " " [ossweb::lookup::link -text Play cmd recorder.play file $row(file_name) recorder_id $row(recorder_id)]
        }
        set row(file_size) [expr abs([file size [ossweb::file::getname $row(file_name) -path tvguide]]/1024/1024)]
        incr disk_taken $row(file_size)
      }
      switch -- $row(file_status) {
       Recorded { set row(file_color) green }
       Recording { set row(file_color) red }
       Error { set row(file_color) red }
       default { set row(file_color) grey }
      }
    }
    ossweb::form form_record set_values
    # Availale space
    catch {
      array set fs [ns_sysstatfs [ossweb::file::getname "" -path tvguide]]
      set disk_avail [expr ($fs(f_frsize)/1024*$fs(f_bavail))/1024]
    }
}

ossweb::conn::callback tvguide_program {} {

    if { $recorder_id != "" } {
      if { [ossweb::db::multivalue sql:tvguide.recorder.read] } {
        error "OSSWEB: Invalid program record"
      }
      array set roles $program_crew
      set genre_list $program_genre
    } else {
      if { [ossweb::db::multivalue sql:tvguide.lineup.read] ||
           [ossweb::db::multivalue sql:tvguide.station.read] ||
           [ossweb::db::multivalue sql:tvguide.schedule.read] ||
           [ossweb::db::multivalue sql:tvguide.program.read] } {
        error "OSSWEB: Invalid program record"
      }
      ossweb::db::multivalue sql:tvguide.recorder.search
      ossweb::db::foreach sql:tvguide.crew.list { lappend roles($role) "$givenname $surname" }
      ossweb::db::foreach sql:tvguide.programGenre.list { lappend genre_list $genre }
    }

    switch -- ${ossweb:cmd} {
     schedule {
       set program_genre $genre_list
       set program_crew [array get roles]
       if { $allow == "" } { error "OSSWEB: Permission denied" }
       if { [ossweb::db::exec sql:tvguide.recorder.create] } {
         error "OSSWEB: Unable to schedule recording"
       }
       set recorder_id [ossweb::db::currval tvguide]
       tvguide::recorder::schedule $recorder_id $start_time
       ossweb::conn::set_msg "Program has been scheduled for recording"
     }

     movie -
     unschedule {
       if { $allow == "" } { error "OSSWEB: Permission denied" }
       if { ${ossweb:cmd} == "movie" } {
         set movie_title "$program_title $program_subtitle"
         set movie_lang English
         set movie_descr $description
         set movie_year [join $program_year]
         set movie_genre [join $program_genre]
         lappend movie_genre Movie
         ossweb::db::begin
         if { [ossweb::db::exec sql:movie.create] } {
           error "OSSWEB: Unable to save movie"
         }
         set movie_id [ossweb::db::currval movie]
         if { [ossweb::db::exec sql:movie.file.create] } {
           error "OSSWEB: Unable to save movie file"
         }
         # Move TV show movie file
         set file_path [ossweb::file::getname $file_name -path tvguide]
         if { [ossweb::file::rename $file_path $file_name -path movie] != 0 } {
           error "OSSWEB: Unable to save movie file"
         }
         # Move TV show cover snapshot as well
         if { [file exists [set jpgfile "[file rootname $file_path].jpg"]] } {
           ossweb::file::rename $jpgfile $movie_id.jpg -path cover
         }
         ossweb::db::commit
       }
       tvguide::recorder::unschedule $recorder_id -stop [ns_queryget stop]
       set recorder_id ""
       ossweb::conn::set_msg "Program recording has been unscheduled"
       append description "<SCRIPT>if(window.opener)setTimeout(\"window.close()\",2000)</SCRIPT>"
     }
    }

    foreach role [array names roles] { append crew_list "<B>$role</B>: [join $roles($role) ", "]<BR>" }
    set genre_list [join $genre_list ", "]

    if { [ossweb::file::exists [file rootname $file_name].jpg -path tvguide] } {
      set jpeg_name [file rootname $file_name].jpg
    }

    if { $allow == "" } { return }

    if { $recorder_id == "" } {
      if { $end_seconds > [ns_time] } {
        ossweb::widget form_program.schedule -type button -label "Record" \
             -confirm "confirm('Record this program?')" \
             -help "Schedule recording" \
             -url [ossweb::lookup::url cmd schedule channel_id $channel_id program_id $program_id lineup_id $lineup_id station_id $station_id start_time $start_time]
        if { [set conflict [ossweb::db::multilist sql:tvguide.recorder.conflict]] != "" } {
          # Check against devices we have available for recording
          if { [llength $conflict] >= [llength [ossweb::config tvguide:devices]] } {
            set msg "<FONT COLOR=red><B>Recording is not available, already scheduled programs:</B></FONT><P>"
            foreach m $conflict { append msg "&nbsp; " [string trim $m {{}}] "<BR>" }
            ossweb::widget form_program.schedule -type inform -value $msg
          }
        }
      }
    } else {
      if { $end_seconds > [ns_time] } {
        ossweb::widget form_program.unschedule -type button -label "Cancel" \
             -confirm "confirm('Cancel program recording?')" \
             -help "Cancel recording" \
             -url [ossweb::lookup::url cmd unschedule channel_id $channel_id program_id $program_id lineup_id $lineup_id station_id $station_id start_time $start_time recorder_id $recorder_id]
        if { $file_status == "Recording" } {
          ossweb::widget form_program.stop -type button -label "Stop" \
               -confirm "confirm('Stop program recording?')" \
               -help "Stop recording" \
               -url [ossweb::lookup::url cmd unschedule channel_id $channel_id program_id $program_id lineup_id $lineup_id station_id $station_id start_time $start_time recorder_id $recorder_id stop t]
        }
      }
      if { $file_status == "Recorded" && [info proc ::movie::play] != "" } {
        ossweb::widget form_program.movie -type button -label "Save to Movies" \
             -confirm "confirm('Save the recording in the Movies collection?')" \
             -help "Save recording into Movies collection" \
             -url [ossweb::lookup::url cmd movie channel_id $channel_id program_id $program_id lineup_id $lineup_id station_id $station_id start_time $start_time recorder_id $recorder_id]
      }
    }
}

ossweb::conn::callback tvguide_search {} {

    switch -- ${ossweb:cmd} {
     current {
       set current_flag 1
       ossweb::conn -set title "TV Guide Currently Playing"
     }
     search {
       ossweb::conn -set title "TV Guide Search Results"
     }
    }
    set now [ossweb::date parse2 [ossweb::date clock $now]]
    ossweb::db::multirow tvguide sql:tvguide.schedule.list -eval {
      set row(time) [lindex $row(start_time) 1]
      set row(genre) [join $row(genre) ", "]
      set row(url) [ossweb::html::link -text $row(program_title) -lookup t -window TV -winopts $winopts cmd show station_id $row(station_id) program_id $row(program_id) start_time $row(start_time) lineup_id $lineup_id channel_id $row(channel_id)]
    }
    ossweb::form form_lineup set_values
}

ossweb::conn::callback tvguide_list {} {

    set now [ossweb::date parse2 [ossweb::date clock $now]]
    set start_date [ossweb::date -expr $now -3600]
    set end_date [ossweb::date -expr $now +3600*3]
    foreach { key val } { i 1 hour1 "" hour2 "" hour3 "" hour4 "" } { set $key $val }
    ossweb::multirow create tvguide channel station line1 line12 line2 line22 line3 line32 line4 line42
    ossweb::db::foreach sql:tvguide.schedule.list {
      if { ![info exists tvmap($channel_id)] } {
        ossweb::multirow append tvguide $channel_id $station_label
        set tvmap($channel_id) [ossweb::multirow size tvguide]
      }
      set rowid $tvmap($channel_id)
      set title $program_title
      if { $part_number != "" } { append title " Part $part_number" }
      if { $episode_number != "" } { append title " Episode $episode_number" }
      append tvline($rowid) "$hour $minute {$title} $station_id $program_id $channel_id {$start_time} "
      if { ![info exists hours($hour)] } {
        set hours($hour) $time
        set times($time) $hour
      }
    }
    foreach time [lsort -integer [array names times]] {
      set hour $times($time)
      set hour$i $hour
      set nhour($hour) $i
      incr i
    }
    foreach { rowid line } [array get tvline] {
      foreach { hour minute name station_id program_id channel_id start_time } $line {
        set n $nhour($hour)
        if { $minute >= 30 } { append n 2 }
        set url [ossweb::html::link -text $name -lookup t -window TV -winopts $winopts cmd show cmd show station_id $station_id program_id $program_id start_time $start_time lineup_id $lineup_id channel_id $channel_id]
        ossweb::multirow set tvguide $rowid line$n $url
      }
    }
    ossweb::form form_lineup set_values
    ossweb::conn -set title "TV Guide Listing"
}

ossweb::conn::callback create_form_lineup {} {

    set lineups [ossweb::db::multilist sql:tvguide.lineup.list]
    if { $lineup_id == "" } { set lineup_id [lindex [lindex $lineups 0] 1] }

    ossweb::form form_lineup -html { onSubmit lineupSubmit(this) }
    ossweb::widget form_lineup.cmd -type hidden -optional -value ${ossweb:cmd}
    ossweb::widget form_lineup.search_text -type text -label Search \
         -optional
    ossweb::widget form_lineup.now -type date -label Date \
         -optional \
         -calendar \
         -format "MON / DD / YYYY HH24 : MI"
    ossweb::widget form_lineup.lineup_id -type select -label Lineups \
         -optional \
         -options $lineups
    ossweb::widget form_lineup.go -type submit -label Go
}

ossweb::conn::callback create_form_record {} {

    ossweb::widget form_record.cmd -type hidden -value recorder -freeze
    ossweb::widget form_record.start_date -type date -label Start \
         -format "MON / DD / YYYY" \
         -calendar \
         -optional
    ossweb::widget form_record.end_date -type date -label end \
         -format "MON / DD / YYYY" \
         -calendar \
         -optional
    ossweb::widget form_record.go -type submit -label Go
}

set columns { lineup_id "" {[ossweb::conn tvguide_lineup [ossweb::config tvguide:lineup]]}
              program_id "" ""
              station_id "" ""
              station_name "" ""
              schedule_id int ""
              affiliate "" ""
              channel_id "" ""
              start_time "" ""
              crew_list "" ""
              genre_list "" ""
              start_date "" ""
              end_date "" ""
              search_text "" ""
              recorder_id int ""
              duration const ""
	      jpeg_name "" ""
              file_name "" ""
              file_status const ""
              start_seconds const 0
              end_seconds const 0
              part_number const ""
              episode_number const ""
              disk_avail const 0
              disk_taken const 0
              now "" {[ossweb::date now]}
              allow const {[ossweb::admin::belong_group -group_name tvguide]}
              winopts const "width=600,height=500,menubar=0,location=0" }

# Process request parameters
ossweb::conn::process -columns $columns \
           -forms form_lineup \
           -on_error { index.index } \
           -eval {
            movie -
            unschedule -
            schedule -
            show {
              -exec { tvguide_program }
              -on_error { -cmd_name error }
            }
            recorder {
              -forms form_record
              -exec { tvguide_recorder }
              -on_error { -cmd_name view }
            }
            error {
            }
            search -
            current {
              -exec { tvguide_search }
            }
            default {
              -exec { tvguide_list }
            }
           }
