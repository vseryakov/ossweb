# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2004

ossweb::conn::callback forums_action {} {

  switch -exact ${ossweb:cmd} {

   update {
     # Use prefix to distinguish form fields from
     # quoted database columns
     if { $forum_id == "" } {
      if { [ossweb::db::exec sql:forum.create] } {
       error "OSSWEB: Unable to create forum"
      }
      set forum_id [ossweb::db::currval forum]
     } else {
      if { [ossweb::db::exec sql:forum.update] } {
       error "OSSWEB: Unable to update forum"
      }
     }
     ossweb::conn::set_msg "Forum has been updated"
   }

   delete {
     if { [ossweb::db::exec sql:forum.delete] } {
      error "OSSWEB: Unable to delete forum"
     }
     ossweb::conn::set_msg "Forum has been deleted"
   }
  }
}

ossweb::conn::callback forums_list {} {

    set forums:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    # Process query and execute script for each row
    ossweb::db::multirow forums sql:forum.list -eval {
      set row(url) [ossweb::html::url cmd edit forum_id $row(forum_id)]
    }
}

ossweb::conn::callback forums_edit {} {

    if { $forum_id > 0 && [ossweb::db::multivalue sql:forum.read] } {
      error "OSSWEB: Record with id $forum_id not found"
    }
    ossweb::form form_forum set_values
}

ossweb::conn::callback create_form_forum {} {

    ossweb::widget form_forum.forum_id -type hidden -datatype integer -optional
    ossweb::widget form_forum.forum_name -type text -label "Name"
    ossweb::widget form_forum.forum_status -type select -label "Status" \
         -options { { Active Active } { Inactive Inactive } }
    ossweb::widget form_forum.forum_type -type select -label "Type" \
         -options { { Public Public } { Personal Personal } { Private Private } { Group Group } }
    ossweb::widget form_forum.description -type textarea \
         -html { rows 5 cols 50} -label "Description" \
         -optional
    ossweb::widget form_forum.msg_count -type inform -label "Messages Posted"
    ossweb::widget form_forum.msg_timestamp -type inform -label "Last Post"
    ossweb::widget form_forum.back -type button -label Back -url [ossweb::html::url cmd view]
    ossweb::widget form_forum.update -type submit -name cmd -label Update
    ossweb::widget form_forum.delete -type submit -label Delete \
         -condition "@forum_id@ gt 0" \
         -name cmd \
         -html { onClick "return confirm('Record will be deleted, continue?')" }
}

set columns { forum_id int ""
              forum_name "" ""
              status "" ""
              msg_count int 0
              description "" "" }

ossweb::conn::process -columns $columns \
           -forms { form_forum } \
           -on_error { index.index } \
           -eval {
            delete {
              -exec { forums_action }
              -next { -cmd_name view }
              -on_error { -cmd_name view }
            }
            update {
              -exec { forums_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            edit {
              -exec { forums_edit }
            }
            default {
              -exec { forums_list }
            }
           }
