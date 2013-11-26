# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

# The same as category, but id is VARCHAR instead of NUMERIC IDENTITY

ossweb::conn::callback category_action {} {

    switch -exact [ossweb::conn cmd_name] {

      update {
         if { $ctx == "new" } {
           if { [ossweb::db::exec sql:reports.category.create] } {
             error "OSS: Operation failed"
           }
         } else {
           if { [ossweb::db::exec sql:reports.category.update] } {
             error "OSS: Operation failed"
           }
           ossweb::conn::set_msg "Record updated"
         }
      }
      delete {
         if { [ossweb::db::exec sql:reports.category.delete] } {
           error "OSS: Operation failed"
         }
         ossweb::conn::set_msg "Record deleted"
      }
    }
}

ossweb::conn::callback category_list {} {

    set category:add [ossweb::html::link -image add.gif -alt Add cmd edit ctx new]
    ossweb::db::multirow category sql:reports.category.list -replace_null "&nbsp;" -eval {
       set row(category_name) [ossweb::html::link -text $row(category_name) cmd edit category_id $row(category_id)]
       set row(description) "[string range $row(description) 0 25] ..."
    }
}

ossweb::conn::callback category_edit {} {

    if { $ctx != "new" } {
      if { [ossweb::db::multivalue sql:reports.category.edit] } {
        error "OSS: Record not found"
      }
    }
    ossweb::form form_category set_values
}

ossweb::conn::callback create_form_category {} {

    ossweb::form form_category
    ossweb::widget form_category.ctx -type hidden -optional
    ossweb::widget form_category.category_id -type text -label ID \
              -html { size 30 } -old
    ossweb::widget form_category.category_name -type text -label Name \
              -html { size 30 }
    ossweb::widget form_category.category_parent -type select -label Parent \
              -optional \
              -empty -- \
              -options [ossweb::db::multilist sql:reports.category.select.read]
    ossweb::widget form_category.description -type textarea \
              -html { rows 5 cols 50} -label "Description" -optional
    ossweb::widget form_category.back -type button -label Back \
              -url [ossweb::html::url cmd view]
    ossweb::widget form_category.update -type submit \
              -name cmd -label Update
    ossweb::widget form_category.delete -type submit \
              -condition "@ctx@ ne new" \
              -name cmd -label Delete -html { onClick "return confirm('Are you sure?')" }
}

# Table/form columns
set columns { category_id "" ""
              category_id:old "" ""
              category_name "" ""
              category_parent "" ""
              description "" ""
              ctx hidden "" }

# Process request parameters
ossweb::conn::process -columns $columns \
                     -forms form_category \
                     -on_error { index.index } \
                     -eval {
                        update -
                        delete {
                           -exec { category_action }
                           -next { -cmd_name view }
                        }
                        edit {
                           -exec { category_edit }
                           -on_error { -cmd_name view }
                        }
                        default {
                           -exec { category_list }
                           -on_error { index.index }
                        }
                     }
