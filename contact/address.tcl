# Author: Vlad Seryakov vlad@crystalballinc.com
# May 2002

ossweb::conn::callback address_update {} {

    set skip_null f
    set old_address $address_id
    if { $location_type == "" } {
      error "OSSWEB: Please select Location Type"
    }
    ossweb::db::begin
    set address_id [ossweb::db::value sql:ossweb.location.update]
    if { $address_id == "" } {
      set address_id $old_address
      error "OSSWEB: Unable to update address record"
    }
    if { [ossweb::db::exec sql:ossweb.location.update.params] } {
      error "OSSWEB: Unable to update address record"
    }
    ossweb::db::commit
    ossweb::conn::set_msg "Location record has been updated"
    ossweb::sql::multipage address -flush t -user_id [ossweb::conn user_id]
}

ossweb::conn::callback address_delete {} {

    if { [ossweb::db::exec sql:ossweb.location.delete] } {
      error "OSSWEB: Unable to delete address record"
    }
    ossweb::conn::set_msg "Address record has been deleted"
    ossweb::sql::multipage address -flush t -user_id [ossweb::conn user_id]
}

ossweb::conn::callback address_edit {} {

    if { $address_id != "" } {
      if { [ossweb::db::multivalue sql:ossweb.location.read] } {
        error "OSSWEB: Unable to read address record $address_id"
      }

      # Info about who/when this record was updated
      if { $update_user_name != "" || $update_date != "" } {
        if { $update_date != "" } { append info "Updated: $update_date" }
        if { $update_user_name != "" } { append info " by: $update_user_name" }
        ossweb::widget form_address.address_id -info $info
      }

      #  See if we have owners for this address
      if { [info proc ::contact::location::owners] != "" } {
        contact::location::owners owners $address_id
      }
    }
    ossweb::form form_address set_values
}

ossweb::conn::callback address_view {} {

    switch ${ossweb:cmd} {
     search {
        # Save submitted values into user properties
        ossweb::conn::set_property ADDRESS:FILTER "" -forms form_search -global t -cache t
        set force t
     }
     ac {
        # Autocomplete search
        set data ""
        switch -- ${ossweb:ctx} {
         a {
           set data [ossweb::db::list sql:ossweb.location.list.js]
         }
         s {
           ossweb::db::foreach sql:ossweb.location.list.street {
             lappend data "{name:'$street'}"
           } -map { ' "" }
         }
         c {
           ossweb::db::foreach sql:ossweb.location.list.city {
             lappend data "{name:'$city'}"
           } -map { ' "" }
         }
         default {
           ossweb::db::foreach sql:ossweb.location.list {
             lappend data "{name:'$address_name',value:$address_id,location_name:'$location_name'}"
           } -map { ' "" }
         }
        }
        ossweb::adp::Exit [join $data "\n"]
     }
    }
    ossweb::conn::get_property ADDRESS:FILTER -columns t -global t -cache t
    ossweb::db::multipage address \
         sql:ossweb.location.search1 \
         sql:ossweb.location.search2 \
         -page $page \
         -cmd_name page \
         -query [ossweb::lookup::property query] \
         -force $force \
         -eval {
      set row(section) ""
      if { [ossweb::lookup::row url -script t] } {
        set row(url) [ossweb::lookup::url cmd edit address_id $row(address_id) page $page]
      }
    }
    ossweb::form form_search set_values
}

ossweb::conn::callback create_form_search {} {

    ossweb::lookup::form form_search

    ossweb::widget form_search.cmd -type hidden -value search -freeze

    ossweb::widget form_search.address_id -type hidden -optional

    ossweb::widget form_search.number -type text -label "Number" \
         -optional \
         -size 10

    ossweb::widget form_search.street -type text -label "Street" \
         -optional \
         -size 20

    ossweb::widget form_search.street_type -type select -label "Street Type" \
         -optional \
         -empty "--" \
         -options [ossweb::db::multilist sql:ossweb.address.street.type.list.select]

    ossweb::widget form_search.unit_type -type select -label "Unit Type" \
         -optional \
         -empty "--" \
         -sql sql:ossweb.address.unit.list.select

    ossweb::widget form_search.unit -type text -label "Unit #" \
         -optional \
         -html { size 4 }

    ossweb::widget form_search.city -type text -label "City" \
         -optional \
         -size 20

    ossweb::widget form_search.state -type select -label "State/Province" \
         -optional \
         -empty "--" \
         -options [ossweb::db::multilist sql:ossweb.address.state.list.select]

    ossweb::widget form_search.zip_code -type text -label "Zip:" \
         -optional \
         -size 6

    ossweb::widget form_search.country -type select -label "Country" \
         -optional \
         -css { width 160 } \
         -empty "--" \
         -options [ossweb::db::multilist sql:ossweb.address.country.list.select]

    ossweb::widget form_search.address_notes -type text -label "Notes" \
         -optional \
         -size 30

    ossweb::widget form_search.location_name -type text -label Name \
         -optional \
         -size 20

    ossweb::widget form_search.location_type -type multiselect -label Type \
         -optional \
         -empty -- \
         -sql sql:ossweb.location.type.list.select

    ossweb::widget form_search.search -type submit -label Search

    ossweb::widget form_search.reset -type reset -label Reset -clear

    ossweb::widget form_search.new -type button -label New \
         -url [ ossweb::lookup::url cmd edit]
}

ossweb::conn::callback create_form_address {} {

    ossweb::form form_address \
         -title "Location #[ossweb::lookup::link -text $address_id cmd edit address_id $address_id]"

    ossweb::widget form_address.page -type hidden -value $page -optional
    ossweb::widget form_address.back_action -type hidden -optional
    ossweb::lookup::form form_address
    ossweb::widget form_address.address_id -type address -label "Address" \
         -country \
         -gps \
         -descr \
         -autocomplete_street \
         -autocomplete_city \
         -optional \
         -notes

    if { $back_action == "close" } {
      ossweb::widget form_address.back -type button -label Close \
         -url "javascript:window.close()"
    } else {
      ossweb::widget form_address.back -type button -label Back \
         -url [ossweb::lookup::url cmd page page $page]
    }
    ossweb::widget form_address.update -type submit -name cmd -label Update

    ossweb::widget form_address.delete -type button -label Delete \
         -eval { if { $address_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete address_id $address_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"
}

set columns { address_id int ""
              number "" ""
              street "" ""
              street_type "" ""
              unit_type "" ""
              unit "" ""
              city "" ""
              state "" ""
              zip_code "" ""
              longitude "" ""
              latitude "" ""
              address_notes "" ""
              country "" ""
              address_notes "" ""
              location_name "" ""
              location_type "" ""
              back_action "" ""
              owners:rowcount const 0
              page var 1
              update_user_name const ""
              update_date const ""
              force var f }

ossweb::conn::process -columns $columns \
                   -form_recreate t \
                   -forms form_search \
                   -on_error { cmd error } \
                   -eval {
                     lookup {
                       -exec { ossweb::lookup::exec }
                     }
                     update {
                       -forms form_address
                       -exec { address_update }
                       -on_error { -cmd_name edit }
                       -next { -cmd_name edit }
                     }
                     delete {
                       -exec { address_delete }
                       -on_error { -cmd_name edit }
                       -next { -cmd_name view }
                     }
                     edit {
                       -forms form_address
                       -exec { address_edit }
                       -on_error { -cmd_name view }
                     }
                     default {
                       -exec { address_view }
                       -on_error { cmd view }
                       -on_error_set_cmd ""
                     }
                   }
