# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

# The same as reftable, but id is VARCHAR instead of NUMERIC IDENTITY

ossweb::conn::callback reftable_action {} {

    switch -exact ${ossweb:cmd} {
     refresh {
       # Flush cache contents, the system re-read this table into memory
       ossweb::db::cache flush $ref_refresh
     }

    update {
       if { ${ossweb:ctx} == "new" } {
         if { [ossweb::db::exec sql:ossweb.admin.reftable2.create] } {
           error "OSS: Operation failed"
         }
       } else {
         if { [ossweb::db::exec sql:ossweb.admin.reftable2.update] } {
           error "OSS: Operation failed"
         }
         ossweb::conn::set_msg "Record $name updated"
       }
    }
    delete {
       if { [ossweb::db::exec sql:ossweb.admin.reftable2.delete] } {
          error "OSS: Operation failed"
        }
        ossweb::conn::set_msg "Record $name deleted from the system"
    }
   }
}

ossweb::conn::callback reftable_list {} {

    ossweb::db::multirow reftable sql:ossweb.admin.reftable2.read_all -replace_null "&nbsp;" -eval {
      set row(url) [ossweb::html::url cmd edit id $row(id)]
      set row(description) [ns_quotehtml $row(description)]
      if { $ref_extra_name2 != "" } {
        set row(extra_name2) $row($ref_extra_name2)
      }
    }
}

ossweb::conn::callback reftable_edit {} {

    if { $id != "" } {
      if { [ossweb::db::multivalue sql:ossweb.admin.reftable2.read] } {
        error "OSS: Record with id $id not found"
      }
    }
    ossweb::form form_reftable -info [ossweb::html::link -text "\[$id\]" cmd edit id $id]
    ossweb::form form_reftable set_values
}

ossweb::conn::callback create_form_reftable {} {

    ossweb::form form_reftable -title "$ref_title Details" -ctx

    if { $id == "" } {
      ossweb::widget form_reftable.id -type text -label ID
    } else {
      ossweb::widget form_reftable.id -type label -label ID
    }

    ossweb::widget form_reftable.name -type text -label "Name" \
         -size 60

    ossweb::widget form_reftable.description -type textarea -label "Description" \
         -rows 5 \
         -cols 60 \
         -resize \
         -optional

    if { $ref_extra_name != "" } {
      ossweb::widget form_reftable.$ref_extra_name -type textarea -label $ref_extra_label \
           -rows 3 \
           -cols 60 \
           -resize \
           -optional
    }

    if { $ref_extra_name2 != "" } {
      ossweb::widget form_reftable.$ref_extra_name2 -type text -label $ref_extra_label2 \
           -size 60 \
           -resize \
           -optional
    }

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

# Setup table names
ossweb::conn::init_reftable

# Table/form columns
set columns { id "" ""
              name "" ""
              description "" ""
              precedence int 0 }

# Process request parameters
ossweb::conn::process -columns $columns \
                      -forms form_reftable \
                      -on_error { -cmd_name view } \
                      -eval {
                      refresh {
                        -exec { reftable_action }
                        -next { -cmd_name view }
                      }
                      update -
                      delete {
                        -validate { { id "" } }
                        -exec { reftable_action }
                        -next { -cmd_name view }
                      }
                      edit {
                        -exec { reftable_edit }
                      }
                      default {
                        -exec { reftable_list }
                        -on_error { index.index }
                      }
                     }
