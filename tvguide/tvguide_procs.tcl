# Author: Vlad Seryakov vlad@crystalballinc.com
# June 2004

namespace eval tvguide {
  variable version "TV Guide version 1.0"
  namespace eval zap2it {}
  namespace eval parser {}
  namespace eval recorder {}
  variable file_map { ! _ | _ & and > _ < _ " " _ ` {} ' {} \" {} / - }; # remove "`s quotes
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
    namespace eval prefs {}
  }
}

ossweb::register_init tvguide::init

proc tvguide::init {} {

    set future_flag 1
    ossweb::db::foreach sql:tvguide.recorder.list {
      tvguide::recorder::schedule $recorder_id $start_time
    }
    ossweb::file::register_download_proc tvguide ::tvguide::download
    # Setup home directory
    env set HOME [ossweb::util::gethome tvguide:home]
    # X11 display for local playback
    env set DISPLAY ":0.0"
    ns_log Notice tvguide: initialized
}

# File download handler, used by ossweb::file::download for file download verification
proc tvguide::download { params } {

    # Show movie cover without restrictions
    if { [regexp {\.(gif|jpg)$} [ns_set get $params file:name]] } { return file_return }
    set recorder_id [ns_set get $params recorder_id]
    if { $recorder_id == "" } { return file_notfound }
    # Allow from local network only, otherwise should be logged in
    if { ![ossweb::conn::is_local_network] && [ossweb::conn session_id] == "" } {
      ns_log Notice tvguide::download: invalid session [ossweb::conn session_id], not local network: [ossweb::conn peeraddr]
      return file_accessdenied
    }
    # Update watch counter/time
    set watch_time NOW()
    set watch_count COALESCE(watch_count,0)+1
    ossweb::db::exec sql:tvguide.recorder.update
    if { ![ossweb::db::rowcount] } { return file_notfound }
    return file_return
}

# Link to tvguide from the toolbar
proc ossweb::html::toolbar::tvguide {} {

    if { [ossweb::conn::check_acl -acl *.tvguide.tvguide.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/tv.gif -mouseover /img/toolbar/tv_o.gif -hspace 6 -status TVGuide -alt TVGuide -app_name tvguide tvguide]
}

# Preferences for problem/task
proc ossweb::control::prefs::tvguide { type args } {

    switch -- $type {
     columns {
       return { tvguide_lineup "" ""
                tvguide_mstream int "" }
     }

     form {
       if { [set lineups [ossweb::db::multilist sql:tvguide.lineup.list]] == "" } { return }
       ossweb::form form_prefs -section "TV Guide"
       ossweb::widget form_prefs.tvguide_lineup -type select -label "Default Lineup" \
            -optional \
            -value [ossweb::conn tvguide_lineup] \
            -freeze \
            -options $lineups
       ossweb::widget form_prefs.tvguide_mstream -type checkbox \
            -label "Use MStream Mozilla Extension: (<A HREF=/js/mstream.xpi>Install</A> | <A HREF=\"javascript:;\" onClick=\"window.open('[ossweb::html::url help app_name main page_name prefs cmd_name mstream]','Help','location=0,menubar=0,width=600,height=600')\">Help</A>)" \
            -optional \
            -horizontal \
            -value [ossweb::conn tvguide_mstream] \
            -options { { Yes t } { No f} }
     }

     save {
       ossweb::admin::prefs set -obj_id [ossweb::conn user_id] \
            tvguide_lineup [ns_querygetall tvguide_lineup] \
            tvguide_mstream [ns_querygetall tvguide_mstream]
     }
    }
}

# TV Guide retrieval
proc ossweb::schedule::daily::tvguide { args } {

    ossweb::schedule::job tvguide::schedule
    ossweb::schedule::job tvguide::alerts
}

# Refresh current channel lineups
proc tvguide::schedule {} {

    if { [ossweb::db::value sql:tvguide.needs.refresh] == "f" } {
      return
    }
    if { [set file [tvguide::zap2it::retrieve]] == "" } {
      return
    }
    if { [catch { tvguide::zap2it::parser $file } errmsg] } {
      ns_log Error tvguide::schedule: $errmsg
      return
    }
    tvguide::cleanup
}

# Search for scheduled alerts and send emails
proc tvguide::alerts { args } {

    ns_parseargs { -lineup_id -start_date -end_date } $args

    set now [ossweb::date now]
    set search_limit 15
    # Take first one if not specified
    if { ![info exists lineup_id] } {
      set lineup_id [lindex [ossweb::db::list sql:tvguide.lineup.list -colname lineup_id] 0]
    }
    if { ![info exists start_date] } {
      set start_date [ossweb::date -expr $now]
    }
    if { ![info exists end_date] } {
      set end_date [ossweb::date -expr $now +86400]
    }
    foreach alert [ossweb::db::multilist sql:tvguide.alert.list] {
      foreach { alert_id search_text search_actor email } $alert {}
      ossweb::db::multirow alerts sql:tvguide.schedule.search
      if { ${alerts:rowcount} == 0 ||
           [set template [ossweb::util::email_template tvguide/alerts]] == "" } {
        continue
      }
      foreach { subject body content_type } $template {}
      if { $subject != "" && $body != "" } {
        ossweb::sendmail $email tvguide $subject $body -content_type $content_type
      }
    }
}

# Cleanup tvguide tables
proc tvguide::cleanup {} {

    ossweb::db::exec sql:tvguide.schedule.cleanup
    ossweb::db::exec sql:tvguide.program.cleanup
}

proc tvguide::export {} {

    set data ""
    set current_flag 1
    set ossweb:cmd current
    set now [ossweb::date parse2 [ossweb::date clock [ns_time]]]
    if { [set lineup_id [ossweb::config tvguide:lineup]] == "" } { return }
    ossweb::db::multirow tvguide sql:tvguide.schedule.list -eval {
      set row(genre) [join $row(genre) ", "]
      append data "$row(channel_id) $row(station_label)|$row(start_time), $row(duration)|$row(program_title) $row(program_subtitle)|$row(genre)|\n"
    }
    set file [ossweb::file::getname tvguide_playing.txt -path tvguide]
    ossweb::write_file $file $data

    set data ""
    ossweb::db::multirow recorder sql:tvguide.recorder.list -eval {
      append data "$row(channel_id) $row(station_label)|$row(start_time), $row(duration)|$row(program_title)|$row(file_status)|$row(file_name)\n"
    }
    set file [ossweb::file::getname tvguide_recording.txt -path tvguide]
    ossweb::write_file $file $data
}

# Retrieve channels from zap2it.com, returns filename with XML data
proc tvguide::zap2it::retrieve { args } {

    ns_parseargs { {-start ""}
                   {-end {=$expr [ns_time]+86400*7}}
                   {-mode wget}
                   {-soapaction "SOAPAction: urn:TMSWebServices:xtvdWebService#download"}
                   {-url http://datadirect.webservices.zap2it.com/tvlistings/xtvdService}
                   {-xmlfile /tmp/tvguide.xml}
                   {-tmpfile /tmp/tvguide.soap}
                   {-user {=$ossweb::config tvguide:user}}
                   {-passwd {=$ossweb::config tvguide:passwd}} } $args

    if { $user == "" || $passwd == "" } {
      ns_log Notice tvguide::zap2it::retrieve: user/password should be specified
      return
    }
    if { $start != "" } {
      set start [ns_fmttime $start "%Y-%m-%dT%H:%M:%SZ"]
    }
    if { $end != "" } {
      set end [ns_fmttime $end "%Y-%m-%dT%H:%M:%SZ"]
    }

    set body "<?xml version='1.0' encoding='utf-8'?><SOAP-ENV:Envelope xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/'> <SOAP-ENV:Body><tms:download xmlns:tms='urn:TMSWebServices'><startTime xsi:type='tms:dateTime'>$start</startTime><endTime xsi:type='tms:dateTime'>$end</endTime></tms:download></SOAP-ENV:Body></SOAP-ENV:Envelope>"

    switch -- $mode {
     curl {
       set errbuf ""
       set errmsg ""
       if { [catch {
         package require TclCurl
         curl::transfer \
            -verbose $debug \
            -url http://datadirect.webservices.zap2it.com/tvlistings/xtvdService \
            -httpheader [list "SOAPAction: urn:TMSWebServices:xtvdWebService#download"] \
            -file $xmlfile \
            -nosignal 1 \
            -encoding all \
            -httpauth digest \
            -errorbuffer errbuf \
            -userpwd $user:$passwd \
            -postfields $body } errmsg] || $errbuf != "" } {
         ns_log Error tvguide::zap2it::schedule: $errmsg $errbuf
       }
     }

     wget {
       ossweb::write_file $tmpfile $body
       if { [catch {
         file delete -force -- $xmlfile
         exec wget -q -O - --http-user $user --http-passwd $passwd --post-file $tmpfile --header $soapaction --header "Accept-Encoding: gzip" $url | gzip -d > $xmlfile
       } errmsg] } {
         ns_log Error tvguide::zap2it::schedule: $errmsg
         return
       }
     }
    }
    return $xmlfile
}

proc tvguide::zap2it::parser { file } {

    tvguide::parser::reset
    set parser [expat zap2it -final yes \
                             -elementstartcommand {tvguide::parser::element start} \
                             -elementendcommand {tvguide::parser::element end} \
                             -characterdatacommand {tvguide::parser::element data}]

    if { [catch { $parser parsefile $file } errmsg] } {
      ns_log Error tvguide::zap2it::parser: $errmsg: $::errorInfo
    }
    $parser free
}

proc tvguide::parser::reset {} {

    nsv_array reset tvguide { top "" name "" id "" data "" }
}

proc tvguide::parser::element { tag name { attrs "" } } {

    set top [nsv_get tvguide top]
    switch -- $tag {
     start {
       switch -- $top$name {
        station {
          nsv_set tvguide top station
          foreach { name value } $attrs {
            switch -- $name {
             id { set name station_id }
            }
            nsv_lappend tvguide data $name $value
          }
        }

        lineup {
          nsv_set tvguide top lineup
          foreach { name value } $attrs {
            switch -- $name {
             id {
               set name lineup_id
               nsv_set tvguide id $value
             }
             name - type - device - location { set name lineup_$name }
             postalCode { set nale lineup_zipcode }
            }
            set $name $value
          }
          if { [ossweb::db::value sql:tvguide.lineup.read] == "" } {
            ossweb::db::exec sql:tvguide.lineup.create
          }
        }

        lineupmap {
          set lineup_id [nsv_get tvguide id]
          foreach { name value } $attrs {
            switch -- $name {
             station - channel { set ${name}_id $value }
             from { set start_date $value }
            }
          }
          if { [ossweb::db::value sql:tvguide.channel.read] == "" &&
               [ossweb::db::value sql:tvguide.station.read] != "" } {
            ossweb::db::exec sql:tvguide.channel.create
          }
        }

        schedule {
          nsv_set tvguide top schedule
          foreach { name value } $attrs {
            switch -- $name {
             station - program { set name ${name}_id }
             duration { set value [string map { T {} P {} H : M {} } $value] }
             time { set name start_time; set value [string map { T { } Z { UTC} } $value] }
            }
            nsv_lappend tvguide data $name $value
          }
        }

        schedulepart {
          foreach { key value } $attrs {
            nsv_lappend tvguide data part_$key $value
          }
        }

        crew -
        program -
        programGenre {
          nsv_set tvguide top $name
          foreach { key value } $attrs {
            switch -- $key {
             id - program { set key program_id }
            }
            nsv_lappend tvguide data $key $value
          }
        }

        crewrole -
        crewgivenname -
        crewsurname -
        programGenreclass -
        programGenrerelevance -
        programtitle -
        programsubtitle -
        programdescription -
        programshowType -
        programseries -
        programsyndicatedEpisodeNumber -
        programoriginalAirDate -
        programrunTime -
        programmpaaRating -
        programstarRating -
        programyear -
        programcolorCode -
        programadvisory -
        stationname -
        stationcallSign -
        stationaffiliate -
        stationfccChannelNumber {
          nsv_set tvguide name [ossweb::decode $name \
                                     title program_title \
                                     subtitle program_subtitle \
                                     originalAirDate program_date \
                                     syndicatedEpisodeNumber episode_number \
                                     showType program_type \
                                     runTime runtime_id \
                                     series series_id \
                                     year program_year \
                                     class genre \
                                     advisory genre \
                                     name station_name \
                                     callSign station_label \
                                     fccChannelNumber channel_id]
        }
        default {
          nsv_set tvguide name $name
        }
       }
     }

     end {
       switch -- $top.$name {
        station.station -
        program.program -
        schedule.schedule {
          foreach { key value } [nsv_get tvguide data] {
            append [string tolower $key] $value
          }
          if { [ossweb::db::value sql:tvguide.$top.read] == "" } {
            ossweb::db::exec sql:tvguide.$top.create
          }
          tvguide::parser::reset
        }

        crew.member -
        programGenre.genre {
          foreach { key value } [nsv_get tvguide data] {
            append [string tolower $key] $value
          }
          if { [ossweb::db::value sql:tvguide.[nsv_get tvguide top].read] == "" } {
            ossweb::db::exec sql:tvguide.[nsv_get tvguide top].create
          }
          nsv_set tvguide data "program_id $program_id"
        }

        crew.crew -
        programGenre.programGenre {
          tvguide::parser::reset
        }

        lineup.lineup {
          tvguide::parser::reset
        }

        station.name -
        station.callSign -
        station.affiliate -
        station.fccChannelNumber {
          nsv_set tvguide name ""
        }
       }
     }

     data {
       if { [set data [string trim $name "\n\r\t"]] == "" } {
         return
       }
       switch -- $top {
        programGenre -
        program -
        station -
        crew {
          nsv_lappend tvguide data [nsv_get tvguide name] $data
        }
       }
     }
    }
}

# Device properties
proc tvguide::recorder::device { device { name "" } } {

    set dev [split $device :]
    set device [lindex $dev 0]
    set adevice [ossweb::nvl [lindex $dev 1] /dev/dsp0]
    switch -- $name {
     adevice { return $adevice }
     list { return "$device $adevice" }
     default { return $device }
    }
}

# First available device
proc tvguide::recorder::device_avail {} {

    foreach device [ossweb::config tvguide:devices] {
      set device_name [tvguide::recorder::device $device]
      if { [ossweb::resource::check video $device_name] == 0 } { return $device }
    }
    return
}

proc tvguide::recorder { recorder_id } {

    variable file_map

    if { [ossweb::db::multivalue sql:tvguide.recorder.read] } {
      ns_log Error tvguide::recorder: $recorder_id: Invalid record
      return
    }
    set rcs_id 0
    set rcs_start [ns_time]
    # Lock video and audio devices
    while { $rcs_id <= 0 } {
      foreach device [ossweb::config tvguide:devices] {
        foreach { device_name adevice } [tvguide::recorder::device $device list] {}
        set rcs_id [ossweb::resource::trylock video $device_name]
        if { $rcs_id > 0 } { break }
      }
      if { $rcs_id <= 0 } {
        if { [ns_time] - $rcs_start > 60 } { break }
        ns_sleep 1
      }
    }
    if { $rcs_id <= 0 } {
      ns_log Error tvguide::recorder: $recorder_id: no devices available
      return
    }
    # Adjust duration if program has been started already
    if { $start_seconds < [ns_time] } {
      set duration [ossweb::date interval [expr $end_seconds-[ns_time]]]
    }
    # Build file name
    set file_name [string map $file_map $start_time-$channel_id-$program_title.avi]
    set file [ossweb::file::getname $file_name -path tvguide -create t]
    set file_status Recording
    ossweb::db::exec sql:tvguide.recorder.update
    # Command line of the recorder
    set cmd [string map [list @adevice@ $adevice @device@ $device_name @duration@ $duration @file@ $file @channel@ $channel_id] [ossweb::config tvguide:recorder]]
    # Start recording
    ns_log Notice tvguide::recorder: $recorder_id: started: $cmd
    catch { eval exec $cmd } file_log
    # Release video device
    ossweb::resource::unlock video $device_name
    # Update recorder status
    if { [file exists $file] } {
      set file_status Recorded
    } else {
      set file_status Error
    }
    ossweb::db::exec sql:tvguide.recorder.update
    ns_log Notice tvguide::recorder: $recorder_id: stopped: $cmd
    if { ![file exists $file] } { return }
    # Produce frame snapshot, mplayer is hardcoded b/c no other tool can do this yet
    set jpgfile [file rootname $file].jpg
    if { [file exists $jpgfile] } { return }
    catch { exec mplayer -really-quiet -zoom -x 200 -y 280 -ss 10 -frames 1 -ao null -vo jpeg -jpeg outdir=/tmp $file }
    catch { file rename -force -- /tmp/00000002.jpg $jpgfile }
}

# Plays video on local X11 display
proc tvguide::recorder::play { recorder_id file } {

    if { ![ossweb::file::exists $file -path tvguide] } {
      ns_log Error tvguide::recorder::play: $file does not exist
      return
    }
    # Update watch counter/time
    set watch_time NOW()
    set watch_count COALESCE(watch_count,0)+1
    ossweb::db::exec sql:tvguide.recorder.update
    if { ![ossweb::db::rowcount] } { return }
    # Setup environment
    set file [ossweb::file::getname $file -path tvguide]
    set cmd [string map [list @file@ $file] [ossweb::config tvguide:player]]
    # Run media player
    ns_log Notice tvguide::recorder::play: $recorder_id: $cmd
    if { $cmd != "" && [catch { exec sh -c "$cmd >> [ns_info log] 2>&1 &" } errmsg] } {
      ns_log Notice tvguide::recorder::play: $file: $errmsg
    }
}

proc tvguide::recorder::schedule { recorder_id start_time } {

    if { [set interval [expr [clock scan $start_time]-[ns_time]]] < 0 } { set interval 0 }
    ns_schedule_proc -thread -once $interval "tvguide::recorder $recorder_id"
    ns_log Notice tvguide::recorder::schedule: [ossweb::conn user_id 0]: $interval: $recorder_id
    return 0
}

proc tvguide::recorder::unschedule { recorder_id args } {

    ns_parseargs { {-stop f} } $args

    if { [ossweb::db::multivalue sql:tvguide.recorder.read] } { return }
    # Unschedule proc
    set prog "tvguide::recorder $recorder_id"
    foreach sched [ns_info schedule] {
      if { [lindex $sched 8] != $prog } { continue }
      ns_unschedule_proc [lindex $sched 0]
      ns_log Notice tvguide::recorder::unschedule: [lindex $sched 0]: $recorder_id
      break
    }
    ns_log Notice tvguide::recorder::unschedule: [ossweb::conn user_id 0]: $recorder_id: $file_name
    # Kill recording process
    catch { set pid [exec sh -c "ps agx|grep $file_name|grep -v grep|awk '{print \$2}'"] }
    catch { ns_kill $pid 15; ns_sleep 1;ns_kill $pid 9 }
    # Release video device
    ossweb::resource::unlock video $device_name
    # Just stop recording, keep the file and the record
    if { $stop == "t" } {
      set file_status Recorded
      ossweb::db::exec sql:tvguide.recorder.update
      return
    }
    # Delete file
    if { $file_name != "" } {
      ossweb::file::delete $file_name -path tvguide
      ossweb::file::delete [file rootname $file_name].jpg -path tvguide
    }
    # Delete the record
    ossweb::db::exec sql:tvguide.recorder.delete
}

proc tvguide::recorder::running {} {

    if { [ossweb::db::list sql:tvguide.recorder.list.recording] == "" } { return 0 }
    return 1
}

# Full text search provider for movie records
proc ossweb::tsearch::tvguide { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type tvguide
       set tsearch_id schedule_id::TEXT
       set tsearch_data program_id
       set tsearch_table tvguide_schedules
       set tsearch_noupdate 1
       set tsearch_text "tvguide_schedule_info(schedule_id)"
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     url {
       # Returns full url to the record
       return [ossweb::html::url tvguide.tvguide cmd search schedule_id [lindex $args 0] program_id [lindex $args 1]]
     }
    }
}
