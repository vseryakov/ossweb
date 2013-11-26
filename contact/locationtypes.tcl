#
# Author Vlad Seryakov vseryakov@mcdean.com
# February 2007
#

ossweb::conn::callback delete {} {

    if { [ossweb::db::delete ossweb_location_types type_id $type_id] } {
      error "OSSWEB: Unable to delete record"
    }

    ossweb::conn::set_msg "Record has been deleted"
    ossweb::conn::next cmd view
}

ossweb::conn::callback update {} {

    if { $type_id == "" } {
       if { [ossweb::db::insert ossweb_location_types] } {
         error "OSSWEB: Unable to create record"
       }
       ossweb::conn::set_msg "Record has been created"
    } else {
       if { [ossweb::db::update ossweb_location_types type_id $type_id] } {
         error "OSSWEB: Unable to update record"
       }

       ossweb::conn::set_msg "Record has been updated"
    }
    ossweb::conn::next cmd view
}

ossweb::conn::callback edit {} {

    # Raise error if we cannot read record by primary key
    if { $type_id != "" && [ossweb::db::read ossweb_location_types type_id $type_id] } {
      error "OSSWEB: Unable to read record"
    }
    ossweb::form form_type set_values
}

ossweb::conn::callback view {} {

    ossweb::db::select ossweb_location_types -type "multirow types" -orderby precedence -eval {
      set row(type_id) [ossweb::html::link -text $row(type_id) cmd edit type_id $row(type_id)]
      foreach k [array names row] {
        if { [string match *_check $k] } {
          set row($k) [ossweb::decode $row($k) t Yes f No ""]
        }
      }
    }
    # Remove unneeded columns
    regsub {(description)} ${types:columns} {} types:columns
}

ossweb::conn::callback create_form_type {} {

    ossweb::form form_type -title "Location type"

    ossweb::widget form_type.type_id -type text -label {Type id}

    ossweb::widget form_type.type_name -type text -label {Type name}

    ossweb::widget form_type.description -type textarea -label {Description} \
         -optional \
         -cols 50 \
         -rows 2 \
         -resize

    ossweb::widget form_type.precedence -type text -label {Precedence} \
         -optional \
         -size 5

    ossweb::widget form_type.name_check -type yesno -label {Name Check} \
         -optional

    ossweb::widget form_type.address_check -type yesno -label {Address Check} \
         -optional

    ossweb::widget form_type.type_check -type yesno -label {Type Check} \
         -optional

    ossweb::widget form_type.number_check -type yesno -label {Number Check} \
         -optional

    ossweb::widget form_type.street_check -type yesno -label {Street Check} \
         -optional

    ossweb::widget form_type.unit_check -type yesno -label {Unit Check} \
         -optional

    ossweb::widget form_type.city_check -type yesno -label {City Check} \
         -optional

    ossweb::widget form_type.state_check -type yesno -label {State Check} \
         -optional

    ossweb::widget form_type.zip_check -type yesno -label {Zip Check} \
         -optional

    ossweb::widget form_type.country_check -type yesno -label {Country Check} \
         -optional

    ossweb::widget form_type.back -type button -label Back \
         -url [ossweb::html::url cmd view]

    ossweb::widget form_type.update -type submit -name cmd -label Update

    ossweb::widget form_type.delete -type button -label Delete \
         -eval { if { $type_id == {} } { return } } \
         -url [ossweb::html::url cmd delete type_id $type_id]
}

ossweb::conn::process \
        -columns { type_id "" "" } \
        -forms form_type \
        -default view
