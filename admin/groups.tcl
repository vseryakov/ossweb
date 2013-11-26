# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback group_action {} {

    switch -exact ${ossweb:cmd} {
     update {
       if { $group_id != "" } {
         if { [ossweb::db::exec sql:ossweb.group.update] } {
           error "Operation failed"
         }
         ossweb::conn::set_msg "Group Details Updated"
       } else {
         if { [ossweb::db::exec sql:ossweb.group.create] } {
           error "Operation failed"
         }
         set group_id [ossweb::db::currval ossweb_user]
         ossweb::conn::set_msg -color black "Group Details Updated"
       }
     }

     refresh {
       # Flush group acl list
       ossweb::db::cache flush user:*:acl
     }

     delete {
       if { [ossweb::db::block {
                  sql:ossweb.group.delete.users
                  sql:ossweb.group.delete.acls
                  sql:ossweb.group.delete }] } {
         error "Operation failed"
       }
       ossweb::conn::set_msg "Group $group_name deleted from the system"
     }

     add {
       # Only admin is able to enable admin privileges for other users
       if { [ossweb::conn::check_acl -acl "*.*.*.*.*"] &&
            "$project_name$app_name$page_name$cmd_name$ctx_name" == "" } {
         error "OSSWEB: ACL shouldn't be empty"
       }
       if { [ossweb::conn::create_acl $group_id \
                  -obj_type G \
                  -project_name $project_name \
                  -app_name $app_name \
                  -page_name $page_name \
                  -cmd_name $cmd_name \
                  -ctx_name $ctx_name \
                  -query $query \
                  -handlers $handlers \
                  -precedence $precedence \
                  -value $value] } {
         error "Operation failed"
       }
       ossweb::conn::set_msg "Access Permission Added"
     }

     remove {
       if { [ossweb::db::exec sql:ossweb.acls.delete] } {
         error "Operation failed"
       }
       ossweb::conn::set_msg "Access Permission Removed"
     }
    }
}

ossweb::conn::callback group_list {} {

    # Link for creation new group
    set groups:add [ossweb::lookup::link -image add.gif -alt Add cmd edit]

    ossweb::db::multirow groups sql:ossweb.group.read_all -eval {
      ossweb::lookup::row group_name -id group_id
      set row(url) [ossweb::lookup::url groups cmd edit group_id $row(group_id)]
    }
}

ossweb::conn::callback group_edit {} {

    if { $group_id == "" } { return }

    if { [ossweb::db::multivalue sql:ossweb.group.read] } {
      error "Group with id $group_id not found"
    }
    set group_link [ossweb::lookup::link -text "<B>\[$group_id\]</B>" cmd edit group_id $group_id]

    ossweb::widget form_group_acls.cmd -value add
    ossweb::widget form_group_acls.group_id -value $group_id
    # Reterive all access permissions
    ossweb::db::multirow acls sql:ossweb.acls.list -vars "obj_id $group_id obj_type G" -eval {
      set row(remove) [ossweb::lookup::link -image trash.gif -alt Remove cmd remove.acl group_id $group_id acl_id $row(acl_id)]
    }
    ossweb::form form_group set_values
}

ossweb::conn::callback create_form_group {} {

    ossweb::lookup::form form_group -select t

    ossweb::widget form_group.group_id -type hidden -datatype integer -optional

    ossweb::widget form_group.group_name -type text -label "Group Name"

    ossweb::widget form_group.short_name -type text -label "Short Name" -optional

    ossweb::widget form_group.description -type textarea -label "Description" \
         -html { rows 3 cols 50 }

    ossweb::widget form_group.precedence -type numberselect -label "Precedence" \
         -empty -- \
         -optional \
         -end 1000

    ossweb::widget form_group.back -type button -label Back -url [ossweb::html::url cmd view]

    ossweb::widget form_group.refresh -type button -label Refresh -url [ossweb::html::url cmd refresh]

    ossweb::widget form_group.update -type submit -name cmd -label Update

    ossweb::widget form_group.delete -type button -label Delete \
         -condition "@group_id@ gt 0" \
         -url [ossweb::html::url cmd delete group_id $group_id] \
         -confirm "confirm('Record will be deleted, continue?')"

    ossweb::widget form_group.refresh -type button -name cmd -label Refresh \
         -url [ossweb::html::url cmd refresh group_id $group_id] \
         -condition "@group_id@ ne \"\""
}

ossweb::conn::callback create_form_group_acls {} {

    ossweb::form form_group_acls

    ossweb::lookup::form form_group_acls

    ossweb::widget form_group_acls.group_id -type hidden -datatype integer

    ossweb::widget form_group_acls.cmd -type submit -label Add

    ossweb::widget form_group_acls.project_name -type text -optional \
         -datatype name -html { size 10 } -label "Project Name"

    ossweb::widget form_group_acls.app_name -type text -optional \
         -datatype name -html { size 10 } -label "App Name"

    ossweb::widget form_group_acls.page_name -type text -optional \
         -html { size 10 } -label "App Context"

    ossweb::widget form_group_acls.cmd_name -type text -optional \
         -datatype name -html { size 10 } -label "Cmd Name"

    ossweb::widget form_group_acls.ctx_name -type text -optional \
         -datatype name -html { size 10 } -label "Cmd Context"

    ossweb::widget form_group_acls.query -type textarea -optional \
         -html { wrap soft rows 2 cols 10 } -label "Query"

    ossweb::widget form_group_acls.handlers -type textarea -optional \
         -html { wrap soft rows 2 cols 10 } -label "Handlers"

    ossweb::widget form_group_acls.value -type select \
         -datatype name -options { { Y Y } { N N } } -label "ACL Value"

    ossweb::widget form_group_acls.value -type select \
         -datatype name -options { { Y Y } { N N } } -label "ACL Value"

    ossweb::widget form_group_acls.precedence -type numberselect -label "Precedence" \
         -empty -- \
         -optional \
         -end 1000
}

# Table/form columns
set columns { group_id int ""
              group_name "" ""
              description "" ""
              group_link var ""
              project_name var ""
              app_name var ""
              page_name var ""
              cmd_name var ""
              ctx_name var ""
              query var ""
              handlers var ""
              acl_id var ""
              precedence int ""
              tab "" edit }

# Process request parameters
ossweb::conn::process -columns $columns \
           -forms { form_group form_group_acls } \
           -on_error { index.index } \
           -eval {
            delete {
              -exec { group_action }
              -next { -cmd_name view }
              -on_error { -cmd_name edit }
            }
            refresh {
              -exec { group_action }
              -next { -cmd_name edit }
            }
            update {
              -exec { group_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            add -
            remove {
              -exec { group_action }
              -next { -cmd_name edit tab acl }
              -on_error { -cmd_name edit tab acl }
            }
            edit {
              -exec { group_edit }
            }
            lookup {
              -exec { ossweb::lookup::exec -sql sql:ossweb.group.read }
            }
            default {
              -exec { group_list }
            }
           }
