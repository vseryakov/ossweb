# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback address_action {} {

    if { $address_id == "" } {
      if { $number != "" } {
        set address_id [ossweb::db::value sql:ossweb.location.update]
      }
    } else {
      if { [ossweb::db::exec sql:ossweb.location.update] } {
        error "OSS: Unable to update postal address"
      }
    }
    if { $address_id != "" } {
      if { [ossweb::db::exec sql:ossweb.location.update.params] } {
        error "OSS: Unable to update postal address"
      }
    }
    if { [ossweb::db::exec sql:ossmon.device.update.address] } {
      error "OSS: Unable to update device address"
    }
    ossweb::conn::set_msg "Address has been updated"
}

ossweb::conn::callback alert_action {} {

    switch ${ossweb:cmd} {
     update {
        if { [ossweb::db::exec sql:ossmon.alert.update.status] } {
          error "OSS: Could not update the status of the alert"
        }
        ossweb::conn::set_msg "The status has been changed in the system"
     }
     delete {
        if { [ossweb::db::exec sql:ossmon.alert.delete]} {
          error "OSS: Could not delete the status of the alert"
        }
        ossweb::conn::set_msg "The status has been deleted"
     }
    }
}

ossweb::conn::callback property_update {} {

    if { [ossweb::db::exec sql:ossmon.device.property.update] } {
      error "OSS: Could not update the device property"
    }
    if { [ossweb::db::rowcount] == 0 } {
      if { [ossweb::db::exec sql:ossmon.device.property.create] } {
        error "OSS: Could not insert the record"
      }
    }
    ossweb::conn::set_msg "The record has been updated"
}

ossweb::conn::callback property_delete { } {

    if { [ossweb::db::exec sql:ossmon.device.property.delete] } {
      error "OSS: Could not delete the record"
    }
    ossweb::conn::set_msg "The record has been removed"
}

ossweb::conn::callback device_action {} {

    set html ""
    set title ""
    switch -- ${ossweb:cmd} {
     alert {
        if { [ossweb::db::multivalue sql:ossmon.device.read] } {
          error "OSS: Device $device_id not found"
        }
        if { [ossweb::db::multivalue sql:ossmon.alert.read] } {
          error "OSS: Alert $alert_id not found"
        }
        set device_name [ossweb::lookup::link -text $device_name -alt Device devices cmd edit device_id $device_id]
        set title $alert_name
        set html "<B>$alert_name $alert_time</B><BR><PRE>$alert_data</PRE>"
     }
    }
}

ossweb::conn::callback device_clear {} {

    if { [ossweb::db::exec sql:ossmon.device.alert.clear] } {
      error "OSS: Could not clear the status of the alert"
    }
}

ossweb::conn::callback device_copy {} {

    ossweb::db::begin
    set new_device_id [ossweb::db::nextval ossmon_device]
    if { [ossweb::db::exec sql:ossmon.device.copy] ||
         [ossweb::db::exec sql:ossmon.device.copy.properties] } {
      error "OSS: Could not copy the device"
    }
    set device_id $new_device_id
    ossweb::db::commit
}

ossweb::conn::callback device_delete {} {

    if { [ossweb::db::exec sql:ossmon.device.delete] } {
      error "OSS: Unable to delete device"
    }
    ossweb::conn::set_msg "Device has been deleted"
    ossweb::db::multipage devices -flush t
    set device_id ""
}

ossweb::conn::callback device_update {} {

    # Resolve or create new type, vendor and model
    ossmon::device::type_add $device_type
    set device_vendor [ossweb::nvl [ossmon::device::vendor_add $device_vendor_name] NULL]
    set device_model [ossweb::nvl [ossmon::device::model_add $device_type $device_vendor $device_model_name] NULL]
    # Create or update device required columns
    if { $device_id == "" } {
      if { [ossweb::db::exec sql:ossmon.device.create] } {
        error "OSS: Unable to create device"
      }
      set device_id [ossweb::db::currval ossmon_device]
      # Create optional objects
      foreach obj_type [ns_querygetall objects] {
        ossweb::db::exec sql:ossmon.object.create
        set obj_id [ossweb::db::currval ossmon_device]
        ossmon::object mon -create obj:id $obj_id
        if { [set errmsg [ossmon::object mon -attrcheck]] != "" } {
          ossweb::conn::set_msg -color red "[ossmon::object mon type:name]: $errmsg"
        }
        ossmon::object mon -destroy
      }
      ossweb::form form_tab destroy
    } else {
      if { [ossweb::db::exec sql:ossmon.device.update.params] } {
        error "OSSWEB: Unable to update device"
      }
    }
    # Update/refresh hierarchy tree
    if { [ossweb::db::exec sql:ossmon.device.update.path] } {
      error "OSSWEB: Could not update device hierarchy path"
    }
    ossweb::sql::multipage devices -flush t
    ossweb::conn::set_msg "Device has been updated"
}

ossweb::conn::callback device_edit {} {

    if { $device_id == "" && $device_name != "" } {
      set device_id [ossweb::db::value sql:ossmon.device.search.by.name]
    }
    if { $device_id == "" || $device_id <= 0 } {
      # Parent link
      if { $device_parent != "" } {
        set device_parent_name [ossweb::db::value sql:ossmon.device.name.parent]
        set device_parent_name [ossweb::lookup::link -text $device_parent_name cmd edit device_id $device_parent]
      }
      ossweb::form form_device set_values
      ossweb::widget form_device.objects -type checkbox -label "Device Objects" \
            -options [ossmon::object::get_types]
      ossweb::widget form_device.update -label Add
      return
    }
    if { [ossweb::db::multivalue sql:ossmon.device.read] } {
      error "OSS: Unable to read device record"
    }
    set device_descr $description
    # Determine list of device models
    ossweb::db::multirow models sql:ossmon.device.vendor.model.list -eval {
      lappend device_models [list $row(device_model) $row(device_model)]
    }
    ossweb::widget form_device.device_model_name -options $device_models
    # Device postal address
    if { $address_id > 0 } {
      ossweb::db::multivalue sql:ossweb.location.read
    }
    # Parent link
    if { $device_parent != "" } {
      set device_parent_name [ossweb::lookup::link -text $device_parent_name cmd edit device_id $device_parent]
    }
    # Device icon
    set device_icon [ossmon::device::icon $device_vendor $device_type -device_id $device_id]
    # Last device alert
    if { $device_alerts != "" } {
      foreach { alert_id alert_type alert_status alert_level alert_time alert_count alert_name } $device_alerts {
        append alert_info [ossmon::alert::html::info \
                               -alert_id $alert_id \
                               -alert_type $alert_type \
                               -alert_level $alert_level \
                               -alert_status $alert_status \
                               -alert_name $alert_name \
                               -alert_count $alert_count \
                               -alert_time [ns_fmttime $alert_time "%m/%d/%y %H:%M:%S"]]
      }
    }
    switch -- $tab {
     objects {
       ossweb::widget form_device.tools -type popupbutton -label "Tools..." \
         -leftside \
         -options [list \
                  [list Ping "" "var w=window.open('[ossweb::conn::hostname]/cgi-bin/ping?$device_host','Obj','$winopts');w.focus();return false"] \
                  [list Traceroute "" "var w=window.open('[ossweb::conn::hostname]/cgi-bin/traceroute?$device_host','Obj','$winopts');w.focus();return false"]]

       ossweb::widget form_device.object -type button -label "New Object" \
            -leftsisde \
            -url [ossweb::lookup::url objects cmd edit device_id $device_id]

       ossweb::db::multirow objects sql:ossmon.device.list.objects -eval {
         ossmon::object obj -create obj:type $row(obj_type)
         set row(type_name) [ossmon::object::get_title $row(obj_type)]
         # Use special default icon
         set icon [ossmon::object::get_icon $row(obj_type)]
         set row(test) [ossweb::html::link -text "<IMG SRC=$icon>" -alt Test -window Test -winopts $winopts objects cmd test obj_id $row(obj_id) lookup:mode 2]
         set row(type_name) [ossweb::lookup::link -text $row(type_name) objects cmd edit obj_id $row(obj_id)]
         if { $row(disable_flag) == "t" } { append row(obj_name) "(disabled)" }
         if { $row(alert_count) > 0 } {
           append row(alert_name) "($row(alert_type))<BR>$row(alert_time) (#$row(alert_count))"
         }
         set row(chart_type) [ossmon::object obj -info:charts]
         if { $row(chart_type) != "" } {
           set row(chart_type) [ossweb::html::link -image chart.gif -alt Charts -window Test -winopts $winopts objects cmd chart obj_id $row(obj_id) chart_type [lindex $row(chart_type) 0] chart_date [ns_time] lookup:mode 2]
         }
         if { [file exists [ns_info home]/modules/charts/$row(obj_id):1.png] } {
           set row(chart) "<IMG SRC=charts/$row(obj_id):1.png>"
         } else {
           set row(chart) ""
         }
       }
     }

     property {
       ossmon::object obj -create obj:type snmp

       ossweb::widget form_property.property \
            -options [ossmon::object::get_property obj property:options -all t -base t] \
            -value $property_id

       if { $property_id != "" } {
           set value [ossweb::db::value sql:ossmon.device.property.read]
           set rec [ossmon::object::get_property obj $property_id -base t]

           ossweb::widget form_property.value destroy

           eval ossweb::widget form_property.value -type text \
                     -label "{[lindex $rec 1]}" \
                     -value "{$value}" \
                     -freeze \
                     -html { TITLE {[lindex $rec 2]} } \
                     [lindex $rec end]

           ossweb::widget form_property.value \
               -info "[ossweb::widget form_property.value info]
                      [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#$property_id')"]"
       }
       ossweb::form form_property set_values
       ossweb::db::multirow properties sql:ossmon.device.property.list -eval {
          set row(edit) [ossweb::lookup::link -image trash.gif -alt Remove cmd delete.property device_id $device_id property_id $row(property_id)]
          set title [ossmon::object::get_property obj $row(property_id) -column title]
          if { $title != "" } {
            set row(property_id) "$title <FONT COLOR=gray>($row(property_id))</FONT>"
          }
       }
     }

     children {
       ossweb::db::multirow devices sql:ossmon.device.list.children -eval {
         set row(alert_name) ""
         set row(alert_icon) [ossweb::html::image squares/green.gif -width "" -height ""]
         set row(alert_class) [ossweb::decode $row(disable_flag) t DST TST]
         set level [expr ([llength [split $row(device_path) /]]-2)*3]
         set indent [string repeat "&nbsp;" $level]
         set row(url) "$indent $row(device_name) / $row(device_host)"
         if { [ossweb::lookup::row url -id device_id] } {
           set row(url) [ossweb::lookup::link -text $row(url) cmd edit device_id $row(device_id) page $page]
         }
         set objects ""
         foreach { time id type name } $row(device_objects) {
           append objects "$time [ossweb::html::link -text $type -alt Mon -window OSSMON -winopts $winopts objects cmd test obj_id $id lookup:mode 2]<BR>"
         }
         set row(device_objects) $objects
         if { $row(device_alerts) != "" && $row(disable_flag) == "f" } {
           # Take the first most recent aleet
           foreach { alert_id alert_type alert_status alert_level alert_time alert_count alert_name } $row(device_alerts) { break }
           switch -- $alert_level {
            Warning { set row(alert_icon) [ossweb::html::image squares/orange.gif -width "" -height "" ] }
            Critical { set row(alert_icon) [ossweb::html::image squares/pink.gif -width "" -height "" ] }
            Advise { set row(alert_icon) [ossweb::html::image squares/yellow.gif -width "" -height "" ] }
            default { set row(alert_icon) [ossweb::html::image squares/red.gif -width "" -height ""] }
           }
           set row(alert_name) [ossmon::alert::html::info \
                                    -alert_id $alert_id \
                                    -alert_type $alert_type \
                                    -alert_level $alert_level \
                                    -alert_status $alert_status \
                                    -alert_name $alert_name \
                                    -alert_count $alert_count \
                                    -alert_time [ns_fmttime $alert_time "%m/%d/%y %H:%M:%S"]]
         }
       }
     }

     alert {
       set alert_id [ns_queryget alert_id]
       set alert_status [ns_queryget alert_status]
       if { $alert_id == "" } {
         ossweb::db::multirow alerts sql:ossmon.device.alert.list -replace_null "&nbsp;" -eval {
           set row(alert_name) [ossweb::lookup::link -text $row(alert_name) cmd edit device_id $device_id alert_id $row(alert_id) tab alert]
         }
         ossweb::widget form_alert.alert_status -type select -label "Alert Status" \
              -empty " --" \
              -options $status_list \
              -html [list onChange "window.location='[ossweb::lookup::url cmd edit device_id $device_id tab alert alert_status ""]'+this.options\[this.selectedIndex\].value"]
       } else {
         set alert_status ""
         if { [ossweb::db::multivalue sql:ossmon.device.alert.list] } {
           error "OSS: Invalid information received by the system"
         }
         set alert_name "$device_type - $alert_name"
         ossweb::db::multirow properties sql:ossmon.alert.property.read_all
         ossweb::db::multipage log \
              sql:ossmon.alert.log.search1 \
              sql:ossmon.alert.log.search2 \
              -page $page \
              -pagesize 5 \
              -cmd_name edit \
              -query "device_id=$device_id&alert_id=$alert_id&tab=alert"
       }
       ossweb::form form_alert set_values
     }
    }
    set description $device_descr
    ossweb::form form_device set_values
    if { $tab != "edit" } {
      ossweb::form form_device readonly -skip "tools|object|clear|list"
    }
}

ossweb::conn::callback device_list {} {

    switch -- ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property OSSMON:DEVICE:FILTER "" -forms form_device -global t -cache t
     }

     default {
       ossweb::conn::get_property OSSMON:DEVICE:FILTER -skip page -columns t -global t -cache t
     }
    }
    switch -- [ossweb::coalesce show_disable f] {
     f { set disable_flag f }
    }
    # Search for devices
    ossweb::db::multipage devices \
         sql:ossmon.device.search1 \
         sql:ossmon.device.search2 \
         -page $page -debug f \
         -force $force \
         -pagesize [ossweb::nvl $pagesize 999] \
         -query [ossweb::lookup::property query] \
         -eval {
      set row(alert_name) ""
      set row(alert_icon) [ossweb::html::image squares/green.gif -width "" -height ""]
      set row(alert_class) [ossweb::decode $row(disable_flag) t DST ST]
      set level [expr ([llength [split $row(device_path) /]]-2)*3]
      set indent [string repeat "&nbsp;&nbsp;" $level]
      set row(device_type) "<IMG SRC=[ossmon::device::icon $row(device_vendor) $row(device_type)] ALIGN=TOP> $row(device_type)"
      set row(url) "$indent $row(device_name) / $row(device_host)"
      if { [ossweb::lookup::row url -id device_id] } {
        set row(url) [ossweb::lookup::link -text $row(url) cmd edit device_id $row(device_id) page $page]
      }
      set objects ""
      foreach { time id type name } $row(device_objects) {
        append objects "$time [ossweb::html::link -text [ossweb::nvl $name $type] -alt Test -window OSSMON -winopts $winopts objects cmd test obj_id $id lookup:mode 2]<BR>"
      }
      set row(device_objects) $objects
      if { $row(device_alerts) != "" && $row(disable_flag) == "f" } {
        # Take the first most recent alert
        foreach { alert_id alert_type alert_status alert_level alert_time alert_count alert_name } $row(device_alerts) { break }
        switch -- $alert_level {
         Warning { set row(alert_icon) [ossweb::html::image squares/orange.gif -width "" -height "" ] }
         Critical { set row(alert_icon) [ossweb::html::image squares/pink.gif -width "" -height "" ] }
         Advise { set row(alert_icon) [ossweb::html::image squares/yellow.gif -width "" -height "" ] }
         default { set row(alert_icon) [ossweb::html::image squares/red.gif -width "" -height ""] }
        }
        set row(alert_name) [ossmon::alert::html::info \
                                 -alert_id $alert_id \
                                 -alert_type $alert_type \
                                 -alert_level $alert_level \
                                 -alert_status $alert_status \
                                 -alert_name $alert_name \
                                 -alert_count $alert_count \
                                 -alert_time [ns_fmttime $alert_time "%m/%d/%y %H:%M:%S"]]
      }
      if { $row(disable_flag) == "t" } {
        set row(alert_icon) [ossweb::html::image squares/grey.gif -width "" -height "" ]
      }
    }
    ossweb::form form_device set_values
}

ossweb::conn::callback device_init {} {

    set lookup_mode [ossweb::lookup::mode]
}

ossweb::conn::callback create_form_device {} {

    switch -- ${ossweb:cmd} {
     update -
     edit {
       ossweb::lookup::form form_device -select [ossweb::decode $device_id "" f t]

       ossweb::form form_device -title "Device Details #$device_id"

       ossweb::widget form_device.device_id -type hidden -optional

       ossweb::widget form_device.address_id -type hidden -optional


       ossweb::widget form_device.device_name -type text -label Name

       ossweb::widget form_device.device_parent -type lookup -label Parent \
            -title_name device_parent_name \
            -url [ossweb::html::url devices cmd search] \
            -mode 2 \
            -optional \
            -map { form_device.device_parent device_id form_device.device_parent_name device_name }

       ossweb::widget form_device.device_type -type combobox -label Type \
            -sql sql:ossmon.device.type.list \
            -onChange "deviceModelLoad()" \
            -width 100

       ossweb::widget form_device.device_vendor -type company_lookup -label Vendor \
          -autocomplete [ossweb::html::url -app_name contact companies cmd ac company_name ""] \
          -text \
          -size 15 \
          -autotab \
          -optional \
          -icons \
          -data {<A HREF="javascript:deviceVendorInfo()" TITLE="Vendor Info"><IMG SRC=/img/details.gif></A>}

       ossweb::widget form_device.device_model_name -type combobox -label Model \
            -optional \
            -width 150

       ossweb::widget form_device.device_software -type text -label "Software Version" \
            -optional


       ossweb::widget form_device.device_serialnum -type text -label Serial# \
            -optional \
            -html { size 25 }

       ossweb::widget form_device.priority -type text -label Priority \
            -optional \
            -datatype integer \
            -html { size 5 }

       ossweb::widget form_device.disable_flag -type boolean -label "Disabled" \
            -optional

       ossweb::widget form_device.description -type textarea -label Description \
            -html { rows 2 cols 30 } \
            -optional

       ossweb::widget form_device.device_host -type text -label "IP Address" \
            -html { size 15 } \
            -optional

       ossweb::widget form_device.alert_info -type label -label "Alert Info" \
            -nohidden

       ossweb::widget form_device.device_address -type label -label Address \
            -nohidden

       ossweb::widget form_device.list -type button -label Back \
            -url [ossweb::lookup::url cmd list page $page]

       ossweb::widget form_device.update -type submit -name cmd -label Update

       ossweb::widget form_device.delete -type button -label "Delete" \
            -eval { if { $device_id == "" } break } \
            -confirm "confirm('Are you sure?')" \
            -url [ossweb::lookup::url cmd delete device_id $device_id]

       ossweb::widget form_device.copy -type button -label "Copy" \
            -eval { if { $device_id == "" } break } \
            -url [ossweb::lookup::url cmd copy device_id $device_id] \
            -confirm "confirm('Device will be copied, continue?')"

       ossweb::widget form_device.clear -type button -label "Clear" \
            -eval { if { $device_id == "" } break } \
            -url [ossweb::lookup::url cmd clear device_id $device_id] \
            -confirm "confirm('Last Alert status will be cleared, continue?')"

       ossweb::widget form_device.help -type helpbutton -url doc/manual.html#t14
     }

     default {
       ossweb::lookup::form form_device

       ossweb::widget form_device.device_name -type text -label Name/Host \
            -html { size 10 } \
            -optional

       ossweb::widget form_device.device_vendor -type multiselect -label Vendor \
            -sql sql:company.list.select \
            -html { size 3 } \
            -optional

       ossweb::widget form_device.device_model -type text -label Model \
            -html { size 10 } \
            -optional

       ossweb::widget form_device.location_name -type text -label Location \
            -html { size 10 } \
            -optional

       ossweb::widget form_device.device_type -type multiselect -label DeviceType \
            -optional \
            -html { size 3 } \
            -sql sql:ossmon.device.type.list

       ossweb::widget form_device.object_type -type multiselect -label ObjectType \
            -optional \
            -html { size 3 } \
            -options [ossmon::object::get_types]

       ossweb::widget form_device.description -type text -label Description \
            -html { size 10 } \
            -optional

       ossweb::widget form_device.pagesize -type text -label Pagesize \
            -html { size 3 } \
            -optional

       ossweb::widget form_device.show_disable -type checkbox -label "Show Disabled" \
            -optional \
            -value t

       ossweb::widget form_device.search -type submit -name cmd -label Search

       ossweb::widget form_device.new -type button -label New \
            -help "Create new device" \
            -url [ossweb::lookup::url cmd edit]

       ossweb::widget form_device.reset -type reset -label Reset -clear
     }
    }
}

ossweb::conn::callback create_form_tab {} {

    set url [ossweb::lookup::url cmd edit device_id $device_id]
    ossweb::widget form_tab.objects -type link -label Objects -value $url
    ossweb::widget form_tab.edit -type link -label Details -value $url
    ossweb::widget form_tab.property -type link -label Properties -value $url
    ossweb::widget form_tab.address -type link -label Address -value $url
    ossweb::widget form_tab.alert -type link -label Alerts -value $url
    ossweb::widget form_tab.children -type link -label SubDevices -value $url
}

ossweb::conn::callback create_form_property {} {

    ossweb::lookup::form form_property
    ossweb::widget form_property.device_id -type hidden
    ossweb::widget form_property.ctx -type hidden -value property -freeze
    ossweb::widget form_property.property_id -type text -label "Property"
    ossweb::widget form_property.property -type select -optional \
         -empty "--" \
         -html { onChange setProp(this) }
    ossweb::widget form_property.value -type text -label "Value"
    ossweb::widget form_property.add -type submit -name cmd -label "Add"
}

ossweb::conn::callback create_form_address {} {

    ossweb::lookup::form form_address
    ossweb::widget form_address.device_id -type hidden
    ossweb::widget form_address.ctx -type hidden -value address -freeze
    ossweb::widget form_address.address_id -type address -label "Postal Address" \
         -country \
         -lot \
         -gps \
         -optional
    ossweb::widget form_address.add -type submit -name cmd -label "Update"
}

ossweb::conn::callback create_form_alert {} {

    ossweb::lookup::form form_alert
    ossweb::form form_alert -title "Alert Info"
    if { $alert_id != "" } {
      ossweb::widget form_alert.alert_id -type hidden
      ossweb::widget form_alert.alert_status -type label -label "Status" -nohidden
      ossweb::widget form_alert.alert_name -type label -label "Name" -nohidden
      ossweb::widget form_alert.alert_type -type label -label "Type" -nohidden
      ossweb::widget form_alert.alert_level -type label -label "Level" -nohidden

      ossweb::widget form_alert.create_time -type label -label "Created" -nohidden
      ossweb::widget form_alert.update_time -type label -label "Last Updated" -nohidden
      ossweb::widget form_alert.alert_time -type label -label "Last Alert" -nohidden
      ossweb::widget form_alert.alert_count -type label -label "Count" -nohidden
      ossweb::widget form_alert.back -type button -label "Back" \
           -url [ossweb::lookup::url cmd edit device_id $device_id tab alert alert_status $alert_status]
      ossweb::widget form_alert.update -name cmd -type popupbutton -label "Change To..." \
           -options [list [list Active [ossweb::lookup::url cmd update.alert device_id $device_id alert_id $alert_id alert_status Active tab alert]] \
                          [list Closed [ossweb::lookup::url cmd update.alert device_id $device_id alert_id $alert_id alert_status Closed tab alert]] \
                          [list Pending [ossweb::lookup::url cmd update.alert device_id $device_id alert_id $alert_id alert_status Pending tab alert]]]
      ossweb::widget form_alert.delete -name cmd -type button -label "Delete" \
           -confirm "confirm('Are you sure?')" \
           -url [ossweb::lookup::url cmd delete.alert device_id $device_id alert_id $alert_id tab alert]
    }
}

# Table/form columns
set columns { device_id "" ""
              device_type "" ""
              device_name "" ""
              device_host "" ""
              device_descr "" ""
              device_parent int ""
              device_vendor "" ""
              device_vendor_name "" ""
              device_model_name "" ""
              device_filter const ""
              device_models const ""
              alert_id "" ""
              alert_info "" ""
              alert_status "" ""
              alert_level "" ""
              address_id "" ""
              property_id "" ""
              number "" ""
              obj_type "" ""
              objects:rowcount const 0
              tab "" objects
              page var 1
              pagesize int ""
              force const f
              lookup_mode const 0
              winopts const "menubar=0,width=800,height=600,location=0,scrollbars=1"
              status_list const { { Active Active } { Closed Closed } { Pending Pending } } }

ossweb::conn::process -columns $columns \
           -forms { form_tab form_device form_property form_address form_alert } \
           -form_recreate t \
           -on_error { index.index } \
           -exec { device_init } \
           -eval {
             delete.property {
              -exec { property_delete }
              -on_error { -cmd_name edit tab property }
              -next { -cmd_name edit tab property }
             }
             add.property {
              -exec { property_update }
              -on_error { -cmd_name edit tab property }
              -next { -cmd_name edit tab property }
             }
             update.address {
              -exec { address_action }
              -on_error { -cmd_name edit tab address }
              -next { -cmd_name edit tab address }
             }
             update.alert {
              -exec { alert_action }
              -on_error { -cmd_name edit tab alert }
              -next { -cmd_name edit tab alert }
             }
             add -
             update {
              -exec { device_update }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             delete {
              -exec { device_delete }
              -on_error { -cmd_name edit }
              -next { -cmd_name view }
             }
             copy {
              -exec { device_copy }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             clear {
              -exec { device_clear }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             edit {
              -exec { device_edit }
              -on_error { -cmd_name view }
             }
             alert {
              -exec { device_action }
              -on_error { -cmd_name error }
             }
             ping -
             traceroute {
              -exec { device_action }
              -on_error { -cmd_name error }
             }
             error {
             }
             default {
              -exec { device_list }
             }
           }
