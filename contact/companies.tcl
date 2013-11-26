# Author: Vlad Seryakov vlad@crystalballinc.com
# January 2002

ossweb::conn::callback address_update {} {

    if { [ossweb::db::value sql:company.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    ossweb::db::begin
    if { $address_id == "" } {
      set address_id [ossweb::db::value sql:ossweb.location.update]
      if { $address_id == "" || [ossweb::db::exec sql:company.address.create] } {
        set address_id ""
        error "OSSWEB: Operation failed"
      }
    } else {
      if { [ossweb::db::exec sql:ossweb.location.update] } {
        error "OSSWEB: Operation failed"
      }
      if { [ossweb::db::exec sql:company.address.update] ||
           ([ossweb::db::rowcount] == 0 && [ossweb::db::exec sql:company.address.create]) } {
         error "OSSWEB: Operation failed"
      }
    }
    ossweb::db::commit
    ossweb::conn::set_msg "Record updated"
}

ossweb::conn::callback address_delete {} {

    if { [ossweb::db::value sql:company.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::exec sql:company.address.delete] } {
      error "OSSWEB: Operation failed"
    }
    ossweb::conn::set_msg "Address has been deleted"
}

ossweb::conn::callback entry_update {} {

    if { [ossweb::db::value sql:company.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    set entry_file [ossweb::file::upload entry_file -path contact -unique t]
    if { $entry_id == "" } {
      if { [ossweb::db::exec sql:company.entry.create] } {
        error "OSSWEB: Unable to create the record"
      }
    } else {
      if { [ossweb::db::exec sql:company.entry.update] } {
        error "OSSWEB: Unable to update the record"
      }
    }
    ossweb::conn::set_msg "Record has been updated"
}

ossweb::conn::callback entry_delete {} {

    if { [ossweb::db::value sql:company.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::exec sql:company.entry.delete] } {
      error "OSSWEB: Unable to delete the record"
    }
    ossweb::conn::set_msg "Record has been deleted"
}

ossweb::conn::callback company_update {} {

    set company_name [string map { ' {} " {} " {} \n {} \r {} \t {} } $company_name]
    if { $company_id == "" } {
      if { [ossweb::db::exec sql:company.create] } {
        error "OSSWEB: Unable to create the record"
      }
      ossweb::form form_company destroy
      set company_id [ossweb::db::currval ossweb_company]
    } else {
      if { [ossweb::db::value sql:company.access.update] != 1 } {
        error "OSSWEB: Access to the record denied"
      }
      if { [ossweb::db::exec sql:company.update] } {
        error "OSSWEB: Unable to update the record"
      }
    }
    if { $company_icon != "" } {
      set ext [string map {.jpeg .jpg} [string tolower [file extension $company_icon]]]
      set imgname $company_id$ext
      ns_log Notice $imgname: [ossweb::file::upload company_icon -path companies -newname $imgname]
    }
    ossweb::conn::set_msg "Record has been updated"
    ossweb::sql::multipage companies -flush t
}

ossweb::conn::callback company_delete {} {

    if { [ossweb::db::value sql:company.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::exec sql:company.delete] } {
      error "OSSWEB: Unable to delete the record"
    }
    ossweb::conn::set_msg "Record has been deleted"
    ossweb::sql::multipage companies -flush t
}

ossweb::conn::callback company_edit {} {

    # If just name given, resolve company id
    if { $company_id == "" && $company_name != "" } {
      set company_id [ossweb::db::value sql:company.read.name]
    }
    if { $company_id == "" } {
      ossweb::widget form_company.back -type button -label Back
      return
    }
    # Check access permissions
    if { [ossweb::db::value sql:company.access] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    # Read record by id
    if { [ossweb::db::multivalue sql:company.read] } {
      error "OSSWEB: Record not found"
    }
    ossweb::form form_company set_values
    if { $company_url != "" } { set company_url "<A HREF=\"$company_url\">$company_url</A>" }
    # Icon or logo
    if { [set company_icon [contact::company::icon $company_id $company_name]] != "" } {
      set company_icon [ossweb::html::image $company_icon]
    }

    ossweb::conn -set title $company_name

    switch -- ${ossweb:ctx} {
     edit {
       ossweb::widget form_company.back -type button -label Back
       ossweb::widget form_company.company_icon -type file -data $company_icon
       return
     }

     address {
       set description ""
       if { $address_id != "" } {
         ossweb::db::multivalue sql:company.address.read
       }
       ossweb::form form_address set_values
     }

     entry {
       if { $entry_id != "" } {
         ossweb::db::multivalue sql:company.entry.read
       }
       ossweb::form form_entry set_values
       ossweb::widget form_entry.entry_name focus
     }

     default {
       ossweb::db::multirow addresses sql:company.address.list -eval {
         set name "$row(number) $row(street) $row(street_type) $row(unit) $row(city) $row(state) $row(zip_code) $row(country_name)"
         set row(name) [ossweb::lookup::link -text $name cmd edit.address company_id $company_id address_id $row(address_id) page $page]
       }
       if { $entry_sort == "" } {
         ossweb::conn::get_property COMPANY:ENTRY:FILTER -skip "company_id page" -columns t -global t -cache t
       } else {
         ossweb::conn::set_property COMPANY:ENTRY:FILTER "" -skip "company_id page" -forms form_filter -global t -cache t
       }
       ossweb::form form_filter set_values
       set entry_sort [ossweb::decode $entry_sort 1 "update_date desc" 2 entry_name 2 entry_value ""]
       ossweb::db::multirow entries sql:company.entry.list -eval {
         if { $row(entry_file) != "" } {
           set row(entry_file) [ossweb::file::link contact $row(entry_file) company_id $company_id]
         }
         set row(entry_name) [ossweb::lookup::link -text $row(entry_name) cmd edit.entry company_id $company_id entry_id $row(entry_id) page $page]
       }
     }
    }
    ossweb::form form_company set_values
    ossweb::form form_company readonly -null ""
    ossweb::form form_company set_properties class:label gray
}

ossweb::conn::callback company_list {} {

    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property COMPANY:FILTER "" -skip page -forms form_search -global t -cache t
     }

     ac {
       # Autocomplete search
       set data ""
       set acid [ns_queryget ac:id 1]
       set company_limit 15
       ossweb::db::foreach sql:company.search1 {
         set rec "{name:'$company_name'}"
         # Company icon
         if { [set icon [contact::company::icon $company_id]] != "" } {
           lappend rec "icon:'$icon'"
         }
         # Id is not disabled
         if { $acid != 0 } {
           lappend rec value:$company_id
         }
         lappend data "{[join $rec ,]}"
       } -map { ' "" }
       # Stop template processing
       ossweb::adp::Exit [join $data "\n"]
     }

     default {
       ossweb::conn::get_property COMPANY:FILTER -skip page -columns t -global t -cache t
     }
    }
    ossweb::form form_search set_values
    ossweb::conn -set title "Company Search"

    ossweb::db::multipage companies sql:company.search1 sql:company.search2 \
         -page $page \
         -pagesize $pagesize \
         -force $force \
         -query [ossweb::lookup::property query] -eval {
      if { [ossweb::lookup::row company_name -id company_id] } {
        set row(company_name) [ossweb::lookup::link -text $row(company_name) cmd edit company_id $row(company_id) page $page]
      }
      if { [set row(icon) [contact::company::icon $row(company_id) $row(company_name)]] != "" } {
        set row(icon) [ossweb::html::image $row(icon)]
      }
    }
}

ossweb::conn::callback create_form_company {} {

    ossweb::lookup::form form_company
    ossweb::lookup::form form_company -select [ossweb::decode $company_id "" f t]
    ossweb::widget form_company.page -type hidden -optional
    ossweb::widget form_company.company_id -type hidden -optional
    ossweb::widget form_company.access_type -type select -label "Access" \
         -optional \
         -options { {Open Open} {Group Group} {Public Public} {Private Private} }
    ossweb::widget form_company.company_name -label "Company Name"
    ossweb::widget form_company.company_url -label "URL" -optional
    ossweb::widget form_company.description -type textarea -label "Notes" \
         -html { cols 35 rows 3 } \
         -optional
    ossweb::widget form_company.company_icon -type inform -label "Icon" \
         -size 15 \
         -optional
    ossweb::widget form_company.update -type submit -name cmd -label Update
    ossweb::widget form_company.back -type link -label Back \
         -url [ossweb::lookup::url cmd [ossweb::decode $company_id "" view edit] company_id $company_id page $page]
    ossweb::widget form_company.delete -type button -label Delete \
         -eval { if { $company_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete company_id $company_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"

    ossweb::widget form_company.search -type link -label Search \
         -url [ossweb::lookup::url cmd view page $page]
    ossweb::widget form_company.edit -type link -label Edit \
         -url [ossweb::lookup::url cmd edit.edit company_id $company_id page $page]
    ossweb::widget form_company.address -type link -label "New Address" \
         -url [ossweb::lookup::url cmd edit.address company_id $company_id page $page]
    ossweb::widget form_company.entry -type link -label "New Entry" \
         -url [ossweb::lookup::url cmd edit.entry company_id $company_id page $page]
}

ossweb::conn::callback create_form_search {} {

    ossweb::lookup::form form_search -close t
    ossweb::widget form_search.company_id -label "Company ID" -html { size 5 } -optional
    ossweb::widget form_search.company_url -label "Company URL" -optional
    ossweb::widget form_search.company_name -label "Company Name" -optional
    ossweb::widget form_search.description -label "Description" -optional
    ossweb::widget form_search.entry_name -label "Notes" -optional

    ossweb::widget form_search.number -label "Street #" -html { size 5 } -optional
    ossweb::widget form_search.street -label "Street" -html { size 20 } -optional
    ossweb::widget form_search.unit_type -type select -label "Unit Type" \
         -optional -label "Unit Type" -empty "--" \
         -options [ossweb::db::multilist sql:ossweb.address.unit.list.select]
    ossweb::widget form_search.unit -label "Unit #" -html { size 4 } -optional
    ossweb::widget form_search.city -label "City" -html { size 27 } -optional
    ossweb::widget form_search.state -type select -label "State" \
         -optional -empty "--" \
         -options [ossweb::db::multilist sql:ossweb.address.state.list.select]
    ossweb::widget form_search.zip_code -label "Zip" -html { size 10 maxlength 10 } \
         -optional

    ossweb::widget form_search.search -type submit -name cmd -label Search
    ossweb::widget form_search.reset -type reset -label Reset -clear
    ossweb::widget form_search.add -type button -label New \
         -url [ossweb::lookup::url cmd edit.edit]
}

ossweb::conn::callback create_form_address {} {

    ossweb::lookup::form form_address
    ossweb::form form_address -title "Contact Address"
    ossweb::widget form_address.company_id -type hidden
    ossweb::widget form_address.page -type hidden -value $page -optional
    ossweb::widget form_address.ctx -type hidden -value address -freeze
    ossweb::widget form_address.address_id -type address -label "Postal Address" -country
    ossweb::widget form_address.description -type textarea -label Description \
         -html { rows 3 cols 50 } -optional
    ossweb::widget form_address.back -type button -label Back \
         -url [ossweb::lookup::url cmd edit company_id $company_id page $page]
    ossweb::widget form_address.update -type submit -name cmd -label Update
    ossweb::widget form_address.delete -type button -label Delete \
         -eval { if { $address_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete.address company_id $company_id address_id $address_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"
}

ossweb::conn::callback create_form_entry {} {

    ossweb::form form_entry -title "Contact Entry"
    ossweb::widget form_entry.company_id -type hidden
    ossweb::widget form_entry.entry_id -type hidden -optional
    ossweb::widget form_entry.page -type hidden -value $page -optional
    ossweb::widget form_entry.ctx -type hidden -value entry -freeze
    ossweb::widget form_entry.entry_name -type text -label "Title" \
         -html { size 40 }
    ossweb::widget form_entry.entry_value -type textarea -label "Decription" \
         -html { rows 2 cols 40 wrap off } \
         -onenter submit \
         -optional
    ossweb::widget form_entry.entry_date -type date -label "Associated Date" \
         -optional \
         -calendar \
         -year_start 1900 \
         -format "MON / DD / YYYY HH24 : MI"
    ossweb::widget form_entry.entry_notify -type select -label "Email Notification" \
         -optional \
         -empty -- \
         -options { { Yearly Yearly }
                    { Monthly Monthly }
                    { Weekly Weekly }
                    { Daily Daily }
                    { Once Once } }
    ossweb::widget form_entry.entry_file -type file -label "Associated File" \
         -optional
    ossweb::widget form_entry.back -type button -label Back \
         -url [ossweb::lookup::url cmd edit company_id $company_id page $page]
    ossweb::widget form_entry.update -type submit -name cmd -label Update
    ossweb::widget form_entry.delete -type button -label Delete \
         -eval { if { $entry_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete.entry company_id $company_id entry_id $entry_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"
}

ossweb::conn::callback create_form_filter {} {

    ossweb::lookup::form form_filter
    ossweb::widget form_filter.page -type hidden -value $page -optional
    ossweb::widget form_filter.company_id -type hidden -value $company_id
    ossweb::widget form_filter.cmd -type hidden -value edit -freeze
    ossweb::widget form_filter.entry_sort -type select -label "Sort By" \
         -optional \
         -options { { "Date Asc" "" }
                    { "Date Desc" 1 }
                    { Title 2 }
                    { Description 3 } }
    ossweb::widget form_filter.entry_filter -type text -label Filter \
         -optional \
         -html { size 15 }
    ossweb::widget form_filter.go -type submit -label Go
}

set columns { company_id int ""
              company_name text ""
              company_url_name "" ""
              company_icon "" ""
              address_id int ""
              entry_id int ""
              entry_filter "" ""
              entry_name "" ""
              entry_sort int ""
              user_id int ""
              page int 1
              pagesize int 25
              force const f }

# Process request parameters
ossweb::conn::process -columns $columns \
             -on_error { -cmd_name view } \
             -forms { form_search } \
             -eval {
                delete.address {
                  -forms { form_address }
                  -exec { address_delete }
                  -next { -cmd_name edit -ctx_name view }
                  -on_error { -cmd_name edit -ctx_name address }
                }
                update.address {
                  -forms { form_address }
                  -exec { address_update }
                  -next { -cmd_name edit -ctx_name view }
                  -on_error { -cmd_name edit -ctx_name address }
                }
                delete.entry {
                  -forms { form_entry }
                  -exec { entry_delete }
                  -next { -cmd_name edit -ctx_name view }
                  -on_error { -cmd_name edit -ctx_name entry }
                }
                update.entry {
                  -forms { form_entry }
                  -exec { entry_update }
                  -next { -cmd_name edit -ctx_name view }
                  -on_error { -cmd_name edit -ctx_name entry }
                }
                delete {
                  -exec { company_delete }
                  -next { -cmd_name view }
                  -on_error { -cmd_name edit }
                }
                update {
                  -forms { form_company }
                  -exec { company_update }
                  -next { -cmd_name edit -ctx_name view }
                  -on_error { -cmd_name edit -ctx_name edit }
                }
                lookup {
                  -exec { ossweb::lookup::exec -sql sql:company.read }
                }
                edit.entry {
                  -forms { form_company form_entry }
                  -exec { company_edit }
                }
                edit.address {
                  -forms { form_company form_address }
                  -exec { company_edit }
                }
                edit {
                  -forms { form_company form_filter }
                  -exec { company_edit }
                }
                file {
                  -exec { ossweb::file::return [ns_queryget file] -path contact }
                }
                default {
                  -exec { company_list }
                  -on_error { index.index }
                }
             }
