# Author: Vlad Seryakov (vlad@crystalballinc.com)
# July 2002

ossweb::conn::callback report_search {} {

    # Fileds to be save permanently
    set columns { mask "" "" }
    ossweb::conn::set_property OSSMON:REPORT:FILTER "" -columns $columns -global t -cache t

    if { ${report:date} != "" } {
      set start_date [ossweb::date parse2 $chart_date]
      set end_date [ossweb::date -set $start_date hours 23 minutes 59 seconds 59]
    }
    set report:start [ossweb::date sql_date $start_date]
    set report:end [ossweb::date sql_date $end_date]
    set report:options(th.params) "ALIGN=LEFT"
    set report:title [ossmon::report::types $type]

    switch -regexp -- $type {
     dco_alarm {
       if { $daily == 1 || $totally == 1 } {
         append type .totally
       }
     }
    }
    # Local proc
    if { [info proc $type] != "" } {
      eval $type
      return
    }
    ossmon::report $type \
        -start_date $start_date \
        -end_date $end_date \
        -hourly $hourly \
        -daily $daily \
        -weekly $weekly \
        -monthly $monthly \
        -chart $chart \
        -obj_id $obj_id \
        -device_id $device_id \
        -debug f
    # Printer friendly version
    if { $print != "" } {
      set master ../index/index.title
    }
}

ossweb::conn::callback report_view  {} {

    ossweb::conn::get_property OSSMON:REPORT:FILTER -columns t -global t -cache t

    ossweb::form form_report set_values
}

ossweb::conn::callback create_form_report {} {

    ossweb::widget form_report.cmd -type hidden -value search -freeze
    ossweb::widget form_report.type -type select -label "Report Type" \
         -empty -- \
         -options [ossmon::report::types] \
         -html [list onChange "window.location='[ossweb::html::url cmd view]&type='+this.options\[this.selectedIndex].value" ] \
         -year_start 2000
    ossweb::widget form_report.start_date -type date -label "Start Date" \
         -calendar \
         -format "MON / DD / YYYY HH24 : MI" \
         -year_start 2000
    ossweb::widget form_report.end_date -type date -label "End Date" \
         -calendar \
         -format "MON / DD / YYYY HH24 : MI" \
         -year_start 2000
    ossweb::widget form_report.print -type checkbox -label "Printer Friendly" \
         -optional \
         -value 1 \
         -html [list [ossweb::decode $print 1 CHECKED ""] ""]

    switch -regexp -- $type {
     pbx_trunk_util {
         ossweb::widget form_report.daily -type checkbox -label Daily \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $daily 1 CHECKED ""] ""]
         ossweb::widget form_report.chart -type checkbox -label Chart \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $chart 1 CHECKED ""] ""]
     }

     pbx_call_stats {
         ossweb::widget form_report.obj_id -type multiselect -label "PBX(s)" \
              -options { { Lansdowne ld } { Corporate corp } } \
              -optional
         ossweb::widget form_report.hourly -type checkbox -label Hourly \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $hourly 1 CHECKED ""] ""]
         ossweb::widget form_report.daily -type checkbox -label Daily \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $daily 1 CHECKED ""] ""]
         ossweb::widget form_report.details -type checkbox -label "Call Details" \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $details 1 CHECKED ""] ""]
     }

     nat.records {
         ossweb::widget form_report.private_ip -type text -label "Private IP" \
              -optional
         ossweb::widget form_report.public_ip -type text -label "Public IP" \
              -optional
         ossweb::widget form_report.flows -type text -label "Flows" \
              -optional \
              -html { size 6 } \
              -datatype integer
     }

     mac.records {
         ossweb::widget form_report.ipaddr -type text -label "IP Address" \
              -optional
         ossweb::widget form_report.macaddr -type text -label "MAC Address" \
              -optional
         ossweb::widget form_report.discover_count -type text -label "Discover Count" \
              -optional \
              -html { size 6 } \
              -datatype integer
     }

     if_ {
         ossweb::widget form_report.start_date -optional
         ossweb::widget form_report.obj_id -type multiselect -label "Objects(s)" \
              -options [ossweb::db::multilist sql:ossmon.object.list.collect] \
              -html { size 10 }
         ossweb::widget form_report.monthly -type checkbox -label Monthly \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $monthly 1 CHECKED ""] ""]
         ossweb::widget form_report.weekly -type checkbox -label Weekly \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $weekly 1 CHECKED ""] ""]
     }

     ip_node {
         ossweb::widget form_report.device_id -type multiselect -label "Device(s)" \
              -options [ossweb::db::multilist sql:ossmon.device.list.collect] \
              -html { size 10 } \
              -optional
     }

     dhcpd_pools {
         ossweb::widget form_report.start_date -type none -optional
         ossweb::widget form_report.end_date -type none -optional
         ossweb::widget form_report.ipaddr -type text -label "IP Address" \
              -optional
         ossweb::widget form_report.port -type text -label "Switch Port" \
              -optional
     }

     dhct_macaddr {
         ossweb::widget form_report.start_date -type none -optional
         ossweb::widget form_report.end_date -type none -optional
         ossweb::widget form_report.macaddr -type text -label "MAC Address" \
              -optional
         ossweb::widget form_report.serialnum -type text -label "Serial #" \
              -optional
     }

     dco_alarm {
         ossweb::widget form_report.name -type text -label "Alarm Name" \
              -optional
         ossweb::widget form_report.log_severity -type text -label "Severity (* ** A A* CL )" \
              -optional \
              -html { size 2 }
         ossweb::widget form_report.log_type -type text -label "Alarm Type (XXX.9999)" \
              -optional \
              -html { size 9 }
         ossweb::widget form_report.mask -type text -label "Alarm Mask" \
              -optional
         ossweb::widget form_report.daily -type checkbox -label Daily \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $daily 1 CHECKED ""] ""]
         ossweb::widget form_report.totally -type checkbox -label Total \
              -optional \
              -value 1 \
              -html [list [ossweb::decode $totally 1 CHECKED ""] ""]
     }
    }
    ossweb::widget form_report.search -type submit -label Search
    ossweb::widget form_report.reset -type reset -label Reset -clear
}

ossweb::conn::process \
     -columns { type "" ""
                start_date date {[ossweb::date parse [ns_fmttime [ns_time] "%Y-%-m-%d 0:0"]]}
                end_date date {[ossweb::date now]}
                obj_id "" ""
                device_id "" ""
                print "" ""
                chart "" 1
                hourly "" ""
                daily "" ""
                weekly "" ""
                monthly "" ""
                totally "" ""
                details "" ""
                skip const ""
                debug const f
                report:date "" ""
                report:style const ""
                report:cellspacing const 0
                report:cellpadding const 2
                report:class1 const ossBorder1
                report:class2 const ossBorder2
                report:border1 const 0
                report:border2 const 0
                report:underline const 0
                report:norow const 0
                report:start const ""
                report:end const ""
                report:title const ""
                report:header const 1
                report:rowcount const 0
                report:columns const ""
                report:data const ""
                report:nodata const "No data available"
                report:width const 100%
                master const index } \
     -forms { form_report } \
     -form_recreate t \
     -on_error { index.index } \
     -eval {
       search {
         -exec { report_search }
         -on_error { -cmd_name view }
       }
       default {
         -exec { report_view }
         -on_error { -cmd_name view }
       }
     }
