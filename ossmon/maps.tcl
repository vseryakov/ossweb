# Author: Vlad Seryakov vlad@crystalballinc.com
# September 2004

ossweb::conn::callback map_add {} {

    set map_image [ossweb::file::upload map_image -path maps]
    if { [ossweb::db::exec sql:ossmon.map.create] } {
      error "OSSWEB: Unable to create map"
    }
    ossweb::conn::set_msg "Map has been created"
}

ossweb::conn::callback map_update {} {

    set map_image [ossweb::file::upload map_image -path maps]
    if { [ossweb::db::exec sql:ossmon.map.update] } {
      error "OSSWEB: Unable to update map"
    }
    ossweb::conn::set_msg "Map has been updated"
}

ossweb::conn::callback map_delete {} {

    if { [ossweb::db::exec sql:ossmon.map.delete] } {
      error "OSSWEB: Unable to delete map"
    }
    set map_id ""
    ossweb::conn::set_msg "Map has been deleted"
}

ossweb::conn::callback map_save {} {

    if { $map_id == "" } { return }
    ossweb::db::begin
    if { [ossweb::db::exec sql:ossmon.map.device.delete] } {
      error "OSSWEB: Unable to update map devices"
    }
    foreach { device_id x y } [ns_queryget device_list] {
      if { [ossweb::db::exec sql:ossmon.map.device.create] } {
        error "OSSWEB: Unable to update map devices"
      }
    }
    set map_id ""
    set device_id ""
    ossweb::db::commit
}

ossweb::conn::callback map_view {} {

    if { $map_id == "" } { return }
    if { [ossweb::db::multivalue sql:ossmon.map.read] } {
      error "OSSWEB: Unable to read map"
    }
    ossweb::db::multirow devices sql:ossmon.map.device.list -eval {
      set row(visibility) [ossweb::decode $row(x) "" hidden visible]
      set row(x) [ossweb::nvl $row(x) $defX]
      set row(y) [ossweb::nvl $row(y) $defY]
      set row(image) [ossmon::device::icon $row(device_vendor) $row(device_type)]
      append deviceList "deviceList\[deviceList.length\] = new deviceNew($row(device_id),$row(x),$row(y));\n"
    }
    ossweb::form form_map set_values
}

ossweb::conn::callback create_form_map {} {

    ossweb::widget form_map.cmd -type hidden -optional
    ossweb::widget form_map.map_id -type hidden -optional
    ossweb::widget form_map.device_list -type hidden -optional
    ossweb::widget form_map.maps -type select -label "Existing Maps" \
         -sql sql:ossmon.map.list \
         -empty -- \
         -optional \
         -html [list onChange "window.location='[ossweb::html::url cmd view]&map_id='+this.options\[this.selectedIndex\].value"]
    ossweb::widget form_map.devs -type select -label Devices \
         -sql sql:ossmon.device.list \
         -empty -- \
         -optional \
         -eval { if { $map_id == "" } { return } } \
         -html { onChange "deviceView(this.options[this.selectedIndex].value)" }
    ossweb::widget form_map.map_name -type text -label "Map Name" \
         -optional
    ossweb::widget form_map.map_image -type file -label "Map Image" \
         -optional
    ossweb::widget form_map.add -type button -cmd_name add -label Add
    ossweb::widget form_map.update -type button -cmd_name update -label Update
    ossweb::widget form_map.delete -type button -cmd_name delete -label Delete
    ossweb::widget form_map.save -type button -label Save \
         -html { onClick "mapSave()" }
    ossweb::widget form_map.reset -type button -label Reset \
         -url [ossweb::html::url cmd view]
}

ossweb::conn::process \
         -columns { map_id int ""
                    map_name "" ""
                    map_image "" ""
                    device_id int ""
                    deviceList const ""
                    tags:rowcount const 0
                    defX const {[ossweb::config ossmon:console:x 20]}
                    defY const {[ossweb::config ossmon:console:y 120]} } \
         -forms { form_map } \
         -on_error { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            add {
              -exec { map_add }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            update {
              -exec { map_update }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            delete {
              -exec { map_delete }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            save {
              -exec { map_save }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            error {
            }
            default {
              -exec { map_view }
            }
         }

