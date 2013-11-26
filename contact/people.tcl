# Author: Vlad Seryakov vlad@crystalballinc.com
# January 2002

proc contact_title { title } {

    set title [string trim $title]
    return [string toupper [string index $title 0]][string range $title 1 end]
}

ossweb::conn::callback address_update {} {

    if { [ossweb::db::value sql:people.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    ossweb::db::begin
    if { $address_id == "" } {
      set address_id [ossweb::db::value sql:ossweb.location.update]
      if { $address_id == "" || [ossweb::db::exec sql:people.address.create] } {
        set address_id ""
        error "OSSWEB: Operation failed"
      }
    } else {
      if { [ossweb::db::exec sql:ossweb.location.update] } {
        error "OSSWEB: Operation failed"
      }
      if { [ossweb::db::exec sql:people.address.update] ||
           ([ossweb::db::rowcount] == 0 && [ossweb::db::exec sql:people.address.create]) } {
         error "OSSWEB: Operation failed"
      }
    }
    ossweb::db::commit
    ossweb::conn::set_msg "Record updated"
}

ossweb::conn::callback address_delete {} {

    if { [ossweb::db::value sql:people.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::exec sql:people.address.delete] } {
      error "OSSWEB: Operation failed"
    }
    ossweb::conn::set_msg "Address has been deleted"
}

ossweb::conn::callback entry_update {} {

    if { [ossweb::db::value sql:people.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { $entry_notify != "" && $entry_date == "" } {
      error "OSSWEB: Entry Date or Time should be specified if Notification is set"
    }
    if { [ossweb::date $entry_date hours] != "" && [ossweb::date $entry_date day] == "" } {
      set entry_date [eval ossweb::date -set $entry_date [ns_fmttime [ns_time] "year %Y month %m day %d"]]
    }
    set entry_name [contact_title $entry_name]
    set entry_file [ossweb::file::upload entry_file -path contact -unique t]
    if { [regexp -nocase phone $entry_name] } {
      set entry_value [string map { " " {} - {} . {} {(} {} {)} {} } $entry_value]
    }
    if { $entry_id == "" } {
      if { [ossweb::db::exec sql:people.entry.create] } {
        error "OSSWEB: Unable to create the record"
      }
    } else {
      if { [ossweb::db::exec sql:people.entry.update] } {
        error "OSSWEB: Unable to update the record"
      }
    }
    ossweb::conn::set_msg "Record has been updated"
}

ossweb::conn::callback entry_delete {} {

    if { [ossweb::db::value sql:people.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::exec sql:people.entry.delete] } {
      error "OSSWEB: Unable to delete the record"
    }
    ossweb::conn::set_msg "Record has been deleted"
}

ossweb::conn::callback people_update {} {

    foreach n { first_name middle_name last_name } {
      set $n [contact_title [set $n]]
    }
    if { $people_id == "" } {
      # Try to resolve company name
      if { $company_id == "" && $company_name != "" } {
        set company_id [ossweb::db::value sql:company.search_by_name]
      }
      if { [ossweb::db::exec sql:people.create] } {
        error "OSSWEB: Unable to create the record"
      }
      ossweb::form form_people destroy
      set people_id [ossweb::db::currval ossweb_contact]
    } else {
      if { [ossweb::db::value sql:people.access.update] != 1 } {
        error "OSSWEB: Access to the record denied"
      }
      if { $company_name == "NULL" } { set company_id "" }
      if { [ossweb::db::exec sql:people.update] } {
        error "OSSWEB: Unable to update the record"
      }
      if { ![ossweb::db::rowcount] } { set picture "" }
    }
    if { $picture != "" } {
      set imgname $people_id[file extension $picture]
      ossweb::file::upload picture -path contact -newname $imgname
    }
    ossweb::conn::set_msg "Record has been updated"
    ossweb::sql::multipage people -flush t
}

ossweb::conn::callback people_delete {} {

    if { [ossweb::db::value sql:people.access.update] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::exec sql:people.delete] } {
      error "OSSWEB: Unable to delete the record"
    }
    ossweb::conn::set_msg "Record has been deleted"
    ossweb::sql::multipage people -flush t
}

ossweb::conn::callback people_edit {} {

    if { $people_id == "" } { return }

    if { [ossweb::db::value sql:people.access] != 1 } {
      error "OSSWEB: Access to the record denied"
    }
    if { [ossweb::db::multivalue sql:people.read] } {
      error "OSSWEB: Record not found"
    }

    if { $company_name != "" } {
      set company_name [ossweb::html::link -text $company_name companies cmd edit company_id $company_id]
    }
    if { [set picture [ossweb::image_exists $people_id contact]] != "" } {
      set picture "<IMG SRC=[ossweb::file::url contact $picture] WIDTH=100 HEIGHT=100 BORDER=0>"
    }
    ossweb::form form_people set_values
    ossweb::conn -set title "$first_name $last_name"

    switch -- ${ossweb:ctx} {
     edit {
       return
     }

     address {
       set description ""
       if { $address_id != "" } {
         ossweb::db::multivalue sql:people.address.read
       }
       ossweb::form form_address set_values
     }

     entry {
       if { $entry_id != "" } {
         ossweb::db::multivalue sql:people.entry.read
         ossweb::widget form_entry.entry_notify -info "Last Sent: [ossweb::nvl $notify_date Never]"
       }
       ossweb::form form_entry set_values
       ossweb::widget form_entry.entry_name focus
     }

     default {
       ossweb::db::multirow addresses sql:people.address.list -eval {
         set name "$row(number) $row(street) $row(street_type) $row(unit) $row(city) $row(state) $row(zip_code) $row(country_name)"
         set row(name) [ossweb::lookup::link -text $name cmd edit.address people_id $people_id address_id $row(address_id) page $page]
       }
       if { $entry_sort == "" } {
         ossweb::conn::get_property PEOPLE:ENTRY:FILTER -skip "people_id page" -columns t -global t -cache t
       } else {
         ossweb::conn::set_property PEOPLE:ENTRY:FILTER "" -skip "people_id page" -forms form_filter -global t -cache t
       }
       ossweb::form form_filter set_values
       set entry_sort [ossweb::decode $entry_sort 1 "update_date desc" 2 entry_name 2 entry_value ""]
       ossweb::db::multirow entries sql:people.entry.list -eval {
         if { $row(entry_file) != "" } {
           set row(entry_file) [ossweb::file::link contact $row(entry_file) people_id $people_id]
         }
         set row(entry_name) [ossweb::lookup::link -text $row(entry_name) cmd edit.entry people_id $people_id entry_id $row(entry_id) page $page]
       }
     }
    }
    ossweb::form form_people readonly -null ""
    ossweb::form form_people set_properties class:label gray
}

ossweb::conn::callback people_list {} {

    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property PEOPLE:FILTER "" -skip page -forms form_search -global t -cache t
     }
     default {
       ossweb::conn::get_property PEOPLE:FILTER -skip page -columns t -global t -cache t
     }
    }
    ossweb::form form_search set_values
    ossweb::conn -set title "People Search"
    set birth_day [ossweb::date day $birthday]
    set birth_month [ossweb::date month $birthday]
    set birth_year [ossweb::date year $birthday]
    ossweb::db::multipage people \
         sql:people.search1 \
         sql:people.search2 \
         -page $page \
         -force $force \
         -pagesize 10 \
         -query [ossweb::lookup::property query] -eval {
      set row(name) "$row(salutation) $row(first_name) $row(middle_name) $row(last_name) $row(suffix)"
      if { [ossweb::lookup::row name -id people_id] } {
        set row(name) [ossweb::lookup::link -text $row(name) cmd edit people_id $row(people_id) page $page]
      }
      if { [set picture [ossweb::image_exists $row(people_id) contact]] != "" } {
        set row(picture) "<IMG SRC=[ossweb::file::url contact $picture] WIDTH=40 HEIGHT=40 BORDER=0>"
      } else {
        set row(picture) ""
      }
    }
}

ossweb::conn::callback create_form_people {} {

    ossweb::lookup::form form_people -select [ossweb::decode $people_id "" f t]
    ossweb::widget form_people.page -type hidden -optional
    ossweb::widget form_people.access_type -type select -label "Access" \
         -optional \
         -options { {Public Public} {Open Open} {Group Group} {Private Private} }
    ossweb::widget form_people.people_id -type hidden -optional
    ossweb::widget form_people.salutation -type select -label "Salut."  \
         -optional \
         -empty -- \
         -options { {Mr Mr} {Mrs Mrs} {Miss Miss} {Dr Dr} }
    ossweb::widget form_people.first_name -label "First Name"
    ossweb::widget form_people.middle_name -label "Middle" \
         -html { size 10 } \
         -optional
    ossweb::widget form_people.last_name -label "Last Name" -optional
    ossweb::widget form_people.suffix -type select -label "Suffix" \
         -optional \
         -empty -- \
         -options { {Jr Jr} {Sr Sr} {II II} {III III} }
    ossweb::widget form_people.picture -type file -label "Picture" \
         -optional
    ossweb::widget form_people.birthday -type date -label "Birthday" \
         -optional \
         -calendar \
         -year_start 1900 \
         -format { MON / DD / YYYY }
    ossweb::widget form_people.company_id -type lookup -label "Company" \
         -noclearbutton \
         -html { size 25 } \
         -title_name company_name -optional -mode 2 \
         -map {form_people.company_id company_id form_people.company_name company_name} \
         -url [ossweb::html::url companies cmd search]
    ossweb::widget form_people.description -type textarea -label "Notes" \
         -html { cols 35 rows 3 } \
         -optional

    ossweb::widget form_people.update -type submit -name cmd -label Update
    ossweb::widget form_people.back -type button -label Back \
         -url [ossweb::lookup::url cmd [ossweb::decode $people_id "" view edit] people_id $people_id page $page]
    ossweb::widget form_people.delete -type button -label Delete \
         -eval { if { $people_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete people_id $people_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"

    ossweb::widget form_people.search -type link -label Search \
         -url [ossweb::lookup::url cmd view page $page]
    ossweb::widget form_people.edit -type link -label Edit \
         -url [ossweb::lookup::url cmd edit.edit people_id $people_id page $page]
    ossweb::widget form_people.address -type link -label "New Address" \
         -url [ossweb::lookup::url cmd edit.address people_id $people_id page $page]
    ossweb::widget form_people.entry -type link -label "New Entry" \
         -url [ossweb::lookup::url cmd edit.entry people_id $people_id page $page]
}

ossweb::conn::callback create_form_search {} {

    ossweb::widget form_search.people_id -label "Company ID" -html { size 5 } -optional
    ossweb::widget form_search.first_name -label "First Name" -optional
    ossweb::widget form_search.last_name -label "Last Name" -optional
    ossweb::widget form_search.company_name -label "Company Name" -optional

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
    ossweb::widget form_search.birthday -type date -label "Birthday" \
         -optional \
         -calendar \
         -range \
         -year_start 1900 \
         -format { MON / DD / YYYY }
    ossweb::widget form_search.entry_name -label "Notes" -optional
    ossweb::widget form_search.search -type submit -name cmd -label Search
    ossweb::widget form_search.reset -type reset -label Reset -clear
    ossweb::widget form_search.add -type button -label New \
         -url [ossweb::lookup::url cmd edit.edit]
    ossweb::widget form_search.export -type button -label Export \
         -url [ossweb::lookup::url cmd export]
}

ossweb::conn::callback create_form_address {} {

    ossweb::form form_address -title "Contact Address"
    ossweb::widget form_address.people_id -type hidden
    ossweb::widget form_address.page -type hidden -value $page -optional
    ossweb::widget form_address.ctx -type hidden -value address -freeze
    ossweb::widget form_address.address_id -type address -label "Postal Address" -country
    ossweb::widget form_address.description -type textarea -label Description \
         -html { rows 3 cols 50 } -optional
    ossweb::widget form_address.back -type button -label Back \
         -url [ossweb::lookup::url cmd edit people_id $people_id page $page]
    ossweb::widget form_address.update -type submit -name cmd -label Update
    ossweb::widget form_address.delete -type button -label Delete \
         -eval { if { $address_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete.address people_id $people_id address_id $address_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"
}

ossweb::conn::callback create_form_entry {} {

    ossweb::form form_entry -title "Contact Entry [ossweb::html::link -text #$entry_id cmd edit.entry people_id $people_id entry_id $entry_id page $page]"
    ossweb::widget form_entry.people_id -type hidden
    ossweb::widget form_entry.entry_id -type hidden -optional
    ossweb::widget form_entry.page -type hidden -value $page -optional
    ossweb::widget form_entry.cmd -type hidden -value update -freeze
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
         -url [ossweb::lookup::url cmd edit people_id $people_id page $page]
    ossweb::widget form_entry.update -type submit -label Update
    ossweb::widget form_entry.delete -type button -label Delete \
         -eval { if { $entry_id == "" } { return } } \
         -url [ossweb::lookup::url cmd delete.entry people_id $people_id entry_id $entry_id page $page] \
         -confirm "confirm('Record will be deleted, continue?')"
}

ossweb::conn::callback create_form_filter {} {

    ossweb::widget form_filter.page -type hidden -value $page -optional
    ossweb::widget form_filter.people_id -type hidden -value $people_id
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

set columns { people_id int ""
              first_name text ""
              last_name "" ""
              birthday "" ""
              picture "" ""
              address_id int ""
              entry_id int ""
              entry_date "" ""
              entry_filter "" ""
              entry_notify "" ""
              entry_sort int ""
              company_id int ""
              company_name "" ""
              page int 1
              force const f
              master const {[ossweb::lookup::master]} }

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
                  -exec { people_delete }
                  -next { -cmd_name view }
                  -on_error { -cmd_name edit }
                }
                update {
                  -forms { form_people }
                  -exec { people_update }
                  -next { -cmd_name edit -ctx_name view }
                  -on_error { -cmd_name edit -ctx_name edit }
                }
                lookup {
                  -exec { ossweb::lookup::exec -sql sql:people.read }
                }
                edit.entry {
                  -forms { form_people form_entry }
                  -exec { people_edit }
                }
                edit.address {
                  -forms { form_people form_address }
                  -exec { people_edit }
                }
                edit {
                  -forms { form_people form_filter }
                  -exec { people_edit }
                }
                file {
                  -exec { ossweb::file::return [ns_queryget file] -path contact }
                }
                export {
                  -exec { contact::export }
                  -next { -cmd_name search }
                }
                default {
                  -exec { people_list }
                  -on_error { -cmd_name view index.index }
                }
             }
