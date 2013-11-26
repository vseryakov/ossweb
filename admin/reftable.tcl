# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback ref_table_action {} {

    switch -exact ${ossweb:cmd} {
     refresh {
        # Flush cache contents, the system re-read this ref_table into memory
        ossweb::db::cache flush $ref_refresh
     }

    update {
        # Use prefix to distinguish form fields from
        # quoted database columns
        if { $id == -1 } {
          if { [ossweb::db::exec sql:ossweb.admin.reftable.create] } {
            error "OSS: Operation failed"
          }
        } else {
          if { [ossweb::db::exec sql:ossweb.admin.reftable.update] } {
            error "OSS: Operation failed"
          }
        }
        ossweb::conn::set_msg "Record updated"
    }

    delete {
       if { [ossweb::db::exec sql:ossweb.admin.reftable.delete] } {
         error "OSS: Operation failed"
       }
       ossweb::conn::set_msg "Record deleted"
    }
   }
}

ossweb::conn::callback ref_table_list {} {

    set id ""
    ossweb::db::multirow reftable sql:ossweb.admin.reftable.read_all -eval {
      set row(url) [ossweb::html::url cmd edit id $row(id)]
      set row(description) [ns_quotehtml $row(description)]
      if { $ref_extra_name2 != "" } {
        set row(extra_name2) $row($ref_extra_name2)
      }
    }
}

ossweb::conn::callback ref_table_edit {} {

    if { $id != -1 } {
      if { [ossweb::db::multivalue sql:ossweb.admin.reftable.read] } {
        error "OSS:Record with id $id not found"
      }
    }
    ossweb::form form_reftable -info [ossweb::html::link -text "\[$id\]" cmd edit id $id]
    ossweb::form form_reftable set_values
}

ossweb::conn::callback create_form_reftable {} {

    ossweb::form form_reftable -title "$ref_title Details"
    ossweb::widget form_reftable.id -type hidden -datatype integer
    ossweb::widget form_reftable.name -type text -label "Name"
    ossweb::widget form_reftable.description -type textarea -label "Description" \
         -html { rows 10 cols 60 wrap off } \
         -optional
    if { $ref_precedence == "Y" } {
      ossweb::widget form_reftable.precedence -label "Precedence" \
           -datatype integer -optional
    }
    ossweb::widget form_reftable.update -type submit -name cmd -label Update
    ossweb::widget form_reftable.delete -type button -label Delete \
         -eval { if { $id == "" } { return } } \
         -url [ossweb::html::url cmd delete id $id] \
         -confirmtext "Record will be deleted, continue?"
    ossweb::widget form_reftable.back -type button -label Back \
         -url [ossweb::html::url cmd view]
}

# Setup ta/ble names
ossweb::conn::init_reftable

# Table/form columns
set columns { id int ""
              name "" ""
              description "" ""
              precedence int 0 }

# Process request parameters
ossweb::conn::process -columns $columns \
                     -forms form_reftable \
                     -eval {
                     refresh {
                       -exec { ref_table_action }
                       -next { -cmd_name view }
                     }
                     delete -
                     update {
                       -validate { { id int } }
                       -exec { ref_table_action }
                       -next { -cmd_name view }
                     }
                     edit {
                       -validate { { id int } }
                       -exec { ref_table_edit }
                     }
                     default {
                       -exec { ref_table_list }
                     }
                    }
