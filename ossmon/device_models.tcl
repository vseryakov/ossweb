# Author Darren Ferguson darren@crystalballinc.com
# June 2005

proc device_type_add { type_id } {

    if { $type_id != "" && [ossweb::db::value sql:ossmon.device.type.read] == "" } {
      set type_name $type_id
      ossweb::db::exec sql:ossmon.device.type.create
    }
}

ossweb::conn::callback deviceModelUpdate { } {

   switch -- ${ossweb:cmd} {
    update {
       # Resolve or create newvendor company
       set device_vendor [ossweb::db::value sql:ossmon.device.vendor.create]
       device_type_add $device_type
       if { $model_id == "" } {
         if { [ossweb::db::exec sql:ossmon.device.vendor.model.create] } {
           error "OSS: Could not create the new relationship in the system"
         }
       } else {
         if { [ossweb::db::exec sql:ossmon.device.vendor.model.update] } {
           set model_id ""
           error "OSS: Could not update existing Device / Model relationship"
         }
       }
       ossweb::conn::set_msg "Device / Model relationship updated"
    }

    delete {
       if { [ossweb::db::exec sql:ossmon.device.vendor.model.delete] } {
         error "OSS: Could not remove the relationship from the system"
       }
       ossweb::conn::set_msg "Device / Model relationship removed"
    }
   }
}

ossweb::conn::callback deviceModelList {} {

    set options ""
    ossweb::db::foreach sql:ossmon.device.vendor.model.list {
      lappend options [list $device_model $device_model]
    }
    ns_return 200 text/html [ossweb::html::combobox_menu device_model $options]
    ossweb::adp::Exit
}

ossweb::conn::callback deviceModelDescr { } {

     ossweb::db::foreach sql:ossmon.device.vendor.model.list {}
     ns_return 200 text/plain $description
     ossweb::adp::Exit
}

ossweb::conn::callback deviceModelEdit { } {

     if { $model_id != "" && [ossweb::db::multivalue sql:ossmon.device.vendor.model.read] } {
       error "OSS: Invalid model id received by the system"
     }
     ossweb::form form_model set_values
}

ossweb::conn::callback deviceModelView { } {

   ossweb::db::multirow deviceModels sql:ossmon.device.vendor.model.list -eval {
      set row(device_model) [ossweb::html::link -text $row(device_model) cmd edit model_id $row(model_id)]
   }
}

ossweb::conn::callback create_form_model { } {

   ossweb::widget form_model.model_id -type hidden -optional
   ossweb::widget form_model.device_model -type text -label "Model Name"
   ossweb::widget form_model.device_vendor_name -type combobox -label "Device Vendor" \
        -sql sql:ossmon.device.vendor.list
   ossweb::widget form_model.device_type -type select -label "Device Type" \
        -sql sql:ossmon.device.type.list
   ossweb::widget form_model.description -type textarea -label "Description" \
        -html [list rows 3 cols 40] \
        -optional
   ossweb::widget form_model.update -type submit -name cmd -label "Update"
   ossweb::widget form_model.delete -type button -label "Delete" \
        -eval { if { $model_id == "" } { return } } \
        -confirm "confirm('Are you sure?')" \
        -url [ossweb::html::url cmd delete model_id $model_id device_vendor $device_vendor]
   ossweb::widget form_model.list -type button -label "Back" \
        -url [ossweb::html::url cmd view]
}

ossweb::conn::callback create_form_search { } {

   ossweb::widget form_search.cmd -type hidden -value "search" -freeze
   ossweb::widget form_search.device_model -type text -label "Model Name" \
        -optional
   ossweb::widget form_search.device_vendor -type select -label "Device Vendor" \
        -optional \
        -empty -- \
        -sql sql:company.list.select
   ossweb::widget form_search.device_type -type select -label "Device Type" \
        -optional \
        -empty -- \
        -sql sql:ossmon.device.type.list
   ossweb::widget form_search.reset -type reset -label "Reset" -clear
   ossweb::widget form_search.search -type submit -label "Search"
   ossweb::widget form_search.new -type button -label "New" \
      -url [ossweb::html::url cmd edit]
}

set columns { model_id "" ""
              device_model "" ""
              device_type "" ""
              device_vendor "" ""
              device_vendor_name "" ""
              description "" "" }

ossweb::conn::process -columns $columns \
                      -forms { form_search form_model } \
                      -eval {
                         delete {
                            -exec { deviceModelUpdate }
                            -on_error { -cmd_name edit }
                            -next { -cmd_name edit device_vendors vendor_id $device_vendor }
                         }
                         update {
                            -exec { deviceModelUpdate }
                            -on_error { -cmd_name edit }
                            -next { -cmd_name edit }
                         }
                         edit {
                            -exec { deviceModelEdit }
                            -on_error { -cmd_name default }
                         }
                         models {
                            -exec { deviceModelList }
                            -on_error { -cmd_name error }
                         }
                         descr {
                            -exec { deviceModelDescr }
                            -on_error { -cmd_name error }
                         }
                         default {
                            -exec { deviceModelView }
                            -on_error { index.index }
                         }
                      }
