# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001


ossweb::conn::callback status_action {} {

  # Process command
  switch -exact ${ossweb:cmd} {

   update {
     if { $ctx == "new" } {
       if { [ossweb::db::exec sql:ossweb.state_machine.create] } {
         error "OSSWEB: Operation failed"
       }
     } else {
      if { [ossweb::db::exec sql:ossweb.state_machine.update] } {
        error "OSSWEB: Operation failed"
      }
     }
     ossweb::conn::set_msg "Record updated"
   }
   delete {
     if { [ossweb::db::exec sql:ossweb.state_machine.delete] } {
       error "OSSWEB: Operation failed"
     }
     ossweb::conn::set_msg "Record deleted from the system"
   }
  }
}

ossweb::conn::callback status_list {} {

   # Link for creation new record
   set status:add [ossweb::html::link -image add.gif -alt Add cmd edit ctx new]
   # Process query and execute script for each row
   ossweb::db::multirow status sql:ossweb.state_machine.list -eval {
     set row(url) [ossweb::html::url cmd edit status_id $row(status_id) module $row(module)]
     set row(description) "[string range $row(description) 0 25] ..."
     if { $row(states) != "&nbsp;" } {
       set row(states) [ossweb::util::wrap_text [ns_quotehtml $row(states)] -size 50 -break "<BR>"]
     }
   }
}

# Edit screen
ossweb::conn::callback status_edit {} {

  if { $ctx != "new" } {
    if { [ossweb::db::multivalue sql:ossweb.state_machine.read] } {
      error "OSSWEB: Record not found"
    }
  }
  ossweb::form form_status set_values
}

ossweb::conn::callback create_form_status {} {

  ossweb::form form_status -title "State Machine"
  ossweb::widget form_status.ctx -type hidden -optional
  if { $status_id == "" || $ctx == "new" } {
    ossweb::widget form_status.status_id -type text -label ID
    ossweb::widget form_status.module -type text -label "Module"
  } else {
    ossweb::widget form_status.status_id -type label -label ID
    ossweb::widget form_status.module -type label -label "Module"
  }
  ossweb::widget form_status.status_name -type text -label "Name"
  ossweb::widget form_status.type -type text -label "Type/Category"
  ossweb::widget form_status.states -type textarea -label "Next States" \
       -optional \
       -html { wrap off cols 60 rows 3 } \
       -resize \
       -info "Valid states should be in form &lt;state&gt;...<BR>
              For initial state it should include intself."
  ossweb::widget form_status.description -type textarea -label "Description" \
       -html { rows 3 cols 60 } \
       -optional
  ossweb::widget form_status.sort -type numberselect -label "Sort Order" \
       -end 100
  ossweb::widget form_status.back -type button -label Back -url [ossweb::html::url cmd view]
  ossweb::widget form_status.update -type submit -name cmd -label Update
  ossweb::widget form_status.delete -type submit \
       -condition "@ctx@ ne new" \
       -name cmd -label Delete -html { onClick "return confirm('Record will be deleted, continue?')" }
}

# Table/form columns
set columns { status_id "" "" \
              type "" "" \
              module "" "" \
              status_name "" "" \
              states "" "" \
              sort int 0 \
              description "" "" \
              ctx hidden "" }

# Process request parameters
ossweb::conn::process -columns $columns \
           -forms form_status \
           -on_error { index.index } \
           -eval {
            update -
            delete {
              -validate { { status_id name } }
              -exec { status_action }
              -next { -cmd_name view }
              -on_error { -cmd_name edit }
            }
            edit {
              -exec { status_edit }
              -on_error { -cmd_name view }
            }
            default {
              -exec { status_list }
            }
           }
