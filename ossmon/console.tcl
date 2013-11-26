# Author Vlad Seryakov : vlad@crystalballinc.com
# May 2004

ossweb::conn::callback device_check {} {

    ossweb::db::foreach sql:ossmon.alert.list.active {
      switch -glob -- $tab.$alert_level {
       error.Error {}
       error.* { continue }
       warning.Critical -
       warning.Warning -
       warning.Advise {}
       warning.* { continue }
      }
      switch -- $alert_level {
       Critical { set class RST }
       Warning { set class WST }
       Advise { set class AST }
       default { set class EST }
      }
      append script "parent.Alerts\[parent.Alerts.length] = parent.doAlert($device_id,'$device_path','$device_name/ $device_host',$alert_id,'$alert_name','$class');\n"
    }
    append script "var snd = parent.scanDevices(parent.Alerts,[ossweb::decode $tab browse 1 maps 1 0],'$tab');\n"
    if { $sound != "" } {
      append script "if(snd) parent.varSound('alert','$sound');\n"
    }
    switch -- $tab {
     maps { return }
     charts { set script "" }
    }
    # Last entries from alert log
    ossweb::db::foreach sql:ossmon.alert.log.list {
      switch -- $alert_level {
       Warning { set icon [ossweb::html::image squares/orange.gif -width "" -height ""] }
       Critical { set icon [ossweb::html::image squares/pink.gif -width "" -height ""] }
       Advise { set icon [ossweb::html::image squares/yellow.gif -width "" -height ""] }
       default { set icon [ossweb::html::image squares/red.gif -width "" -height ""] }
      }
      append html "$icon $alert_time: $alert_type: $device_name: $alert_name $alert_status: $alert_data<BR>"
    } -on_empty {
      append html "No alerts"
    }
}

ossweb::conn::callback device_list {} {

    switch -- $tab {
     all {
       if { [ns_queryexists filter] } {
         ossweb::conn::set_property OSSMON:CONSOLE:FILTER $filter -global t
       }
       set filter [ossweb::conn::get_property OSSMON:CONSOLE:FILTER -global t]
       ossweb::form form_filter -hidden:tab -hidden:tabs -hidden:logs
       ossweb::widget form_filter.filter -type text -label Filter \
            -optional \
            -size 10 \
            -value $filter
       ossweb::widget form_filter.go -type submit -label Go
     }

     browse {
       if { $device_parent == "" } { set device_parent NULL }
     }

     maps {
       set defX [ossweb::config ossmon:console:x 20]
       set defY [ossweb::config ossmon:console:y 120]
       if { [set maps [ossweb::db::multilist sql:ossmon.map.list]] == "" } { return }
       if { $map_id == "" } { set map_id [lindex [lindex $maps 0] 1] }
       if { [ossweb::db::multivalue sql:ossmon.map.read] } {
         error "OSSWEB: Unable to read map"
       }
       ossweb::widget form_map.map_id -type select -label Maps \
            -options $maps \
            -value $map_id \
            -optional \
            -html [list onChange "window.location='[ossweb::lookup::url cmd view tab maps tabs $tabs logs $logs]&map_id='+this.options\[this.selectedIndex\].value"]
       ossweb::db::multirow devices sql:ossmon.map.device.list.active -eval {
         set row(image) ""
         append script "Devices\[Devices.length] = new newDevice($row(device_id),'$row(device_path)');\n"
         if { [ossweb::true $icons] } {
           set row(image) "<IMG SRC=[ossmon::device::icon $row(device_vendor) $row(device_type)] BORDER=0>"
           set row(image) [ossweb::html::link -text $row(image) -alt "Device Details" -window OSSMON -winopts $winopts devices cmd edit device_id $row(device_id) lookup:mode 2]
         }
         set row(url) "$row(device_name)<BR>$row(device_host)"
         set row(url) [ossweb::lookup::link -text $row(url) -alt "Device Subdevices" -window OSSMON -winopts $winopts device_parent $row(device_id) tab browse tabs 0 logs 0 cols 5 lookup:mode 2]
       }
       return
     }
    }
    ossweb::db::multirow devices sql:ossmon.device.list.active -eval {
      set row(browse) ""
      set row(objects) ""
      set row(class) NST
      set image "<IMG SRC=[ossmon::device::icon $row(device_vendor) $row(device_type)] ALIGN=TOP>"
      if { $row(device_count) > 0 } { append image " ($row(device_count))" }
      foreach { time id type name } $row(device_objects) {
        append row(objects) "[ossweb::html::link -text $type -alt "Test $type" -class UST -window TEST -winopts $winopts objects cmd test obj_id $id lookup:mode 2] "
      }
      set row(url) "$image<BR>$row(device_name)"
      if { $row(device_host) != "" } {
        append row(url) "/ $row(device_host)"
      }
      switch -- $tab {
       browse {
         if { $row(device_id) == $device_parent } {
           append row(browse) [ossweb::lookup::link -image up3.gif -width "" -height "" -align top -alt "Parent Device" device_parent $row(device_parent) tab $tab tabs $tabs logs $logs] " "
         }
         if { $row(device_count) > 0 } {
           append row(browse) [ossweb::lookup::link -image down3.gif -width "" -height "" -align top -alt SubDevices device_parent $row(device_id) tab $tab tabs $tabs logs $logs] " "
         }
       }
       error -
       warning {
         set ok 0
         foreach { alert_id alert_type alert_status alert_level alert_time alert_count alert_name } $row(device_alerts) {
           switch -- $tab.$alert_level.$alert_status {
            error.Error.Active { set ok 1 }
            warning.Warning.Active -
            warning.Critical.Active -
            warning.Advise.Active { set ok 1 }
           }
         }
         if { $ok == 0 } { continue }
       }
       charts {
         set ok 0
         set cols 4
         set row(class) CST
         set row(objects) ""
         set row(url) "$row(device_name) / $row(device_host)"
         foreach { time id type name } $row(device_objects) {
           if { [file exists [ns_info home]/modules/charts/$id:1.png] } {
             append row(objects) "<IMG NAME=ossmon$id SRC=charts/$id:1.png>"
             incr ok
           }
         }
         switch $ok {
          0 { continue }
          1 {}
          default {
            set row(objects) "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0><TR><TD NOWRAP>$row(objects)</TD></TR></TABLE>"
          }
         }
       }
      }
      set row(url) [ossweb::html::link -text $row(url) -alt "Device Details" -html "STYLE=\"color:black;\"" -window OSSMON -winopts $winopts devices cmd edit device_id $row(device_id) lookup:mode 2]
      set row(break) [expr ${devices:rowcount} % $cols]
      append script "Devices\[Devices.length] = new newDevice($row(device_id),'$row(device_path)');\n"
    }
}

ossweb::conn::callback device_init {} {

    # Optional device filter
    set device_filter [ossweb::conn::get_property ossmon:device:filter -global t -cache t]
    if { $device_filter != "" &&
         $device_id != "" &&
         [lsearch -exact $device_filter $device_id] == -1 } {
      error "OSSWEB: Access to the device is denied"
    }
}

ossweb::conn::callback create_form_tab {} {

    set url [ossweb::lookup::url cmd view tabs $tabs logs $logs]
    ossweb::widget form_tab.browse -type link -label Browse -value $url
    ossweb::widget form_tab.all -type link -label "All Devices" -value $url
    ossweb::widget form_tab.error -type link -label Errors -value $url
    ossweb::widget form_tab.warning -type link -label Warnings -value $url
    ossweb::widget form_tab.charts -type link -label Charts -value $url
    ossweb::widget form_tab.maps -type link -label Maps -value $url
    ossweb::widget form_tab.console -type link -label Panel \
         -html { target top } \
         -value [ossweb::lookup::url cmd frame tab console]
}

set columns { device_id "" ""
              device_parent int ""
              devices:rowcount const 0
              tab "" browse
              logs "" 1
              tabs "" 1
              filter "" ""
              map_id int ""
              html const ""
              script const ""
              cols int {[ossweb::config ossmon:console:width 7]}
              icons const {[ossweb::config ossmon:console:icons 1]}
              sound const {[ossweb::config ossmon:console:sound]}
              refresh const {[ossweb::config ossmon:console:refresh 30]}
              winopts const "menubar=0,width=900,height=700,location=0,scrollbars=1" }

ossweb::conn::process \
           -columns $columns \
           -forms { form_tab } \
           -on_error { index.index } \
           -exec { device_init } \
           -eval {
             error {
             }
             check {
               -exec { device_check }
               -on_error { -cmd_name error }
             }
             default {
               -exec { device_list }
             }
           }
