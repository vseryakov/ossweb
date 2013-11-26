# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback users_action {} {

    switch -exact ${ossweb:cmd} {

     add {
       if { [ossweb::db::exec sql:problem.user.delete] ||
            [ossweb::db::exec sql:problem.user.create] } {
        error "OSS: Operation failed"
       }
     }

     remove {
       if { [ossweb::db::exec sql:problem.user.delete] } {
        error "OSS: Operation failed"
       }
     }
    }
    ossweb::db::cache flush PROBLEM:*
}

ossweb::conn::callback projects_action {} {

  switch -exact ${ossweb:cmd} {

   update {
     # Use prefix to distinguish form fields from
     # quoted database columns
     if { $project_id == "" } {
      if { [ossweb::db::exec sql:problem.project.create] } {
        error "OSS: Operation failed"
      }
      set project_id [ossweb::db::currval problem]
      if { $owner_id != "" } {
        set user_id $owner_id
        if { [ossweb::db::exec sql:problem.user.create] } {
          error "OSS: Operation failed"
        }
      }
     } else {
      if { [ossweb::db::exec sql:problem.project.update] } {
        error "OSS: Operation failed"
      }
     }
     ossweb::conn::set_msg "Record updated"
   }

   delete {
     if { [ossweb::db::exec sql:problem.project.delete.users] ||
          [ossweb::db::exec sql:problem.project.delete] } {
      error "OSS: Operation failed"
     }
     ossweb::conn::set_msg "Record deleted"
   }
  }
  ossweb::db::cache flush PROBLEM:*
}

# Application list
ossweb::conn::callback projects_list {} {

    switch -- ${ossweb:cmd} {
     search {
       ossweb::conn::set_property PROBLEM:PROJECT:FILTER "" -forms form_project -global t -cache t
     }
     default {
       ossweb::conn::get_property PROBLEM:PROJECT:FILTER -columns t -global t -cache t
     }
    }
    # Process query and execute script for each row
    ossweb::db::multirow projects sql:problem.project.read_all -eval {
      set row(project_name) [ossweb::html::link -text $row(project_name) cmd edit project_id $row(project_id)]
      set row(description) [ossweb::util::wrap_text $row(description) -size 40 -break "<BR>"]
    }
    set projects:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    ossweb::form form_project set_values
}

# Edit screen with user details
ossweb::conn::callback projects_edit {} {

    if { $project_id > 0 } {
     if { [ossweb::db::multivalue sql:problem.project.read] } {
       error "OSS:Record with id $project_id not found"
     }
     ossweb::db::multirow users sql:problem.user.read_all -eval {
      set row(edit) [ossweb::html::link -image trash.gif cmd remove project_id $project_id user_id $row(user_id)]
     }
     # Read only mode
     if { ${ossweb:ctx} == "info" } {
       ossweb::form form_project readonly
     }
     # Project statistics
     ossweb::form form_project -section "Statistics"
     ossweb::db::multirow stats sql:problem.project.stats -cache PROBLEM:STATS:$project_id -timeout 3600 -eval {
        ossweb::widget form_project.$row(status) -type label -label "$row(status) Tasks" -value $row(count)
     }
     # When this project was last time updated
     ossweb::widget form_project.last -type label -label "Last Updated" -value \
          [ossweb::db::select problems -type value -columns "{MAX(TO_CHAR(update_date,'YYYY-MM-DD HH24:MI'))}" -cache PROBLEM:LAST:$project_id -timeout 3600 project_id $project_id]

     # Longest task in the project
     ossweb::widget form_project.longest -type label -label "Longest Task" -value \
          [ossweb::db::select problems -type value -columns "{MAX(NOW() - create_date)}" -where "problem_status IN ('open','pending', 'inprogress')" -cache PROBLEM:LONGEST:$project_id -timeout 3600 project_id $project_id]
    }
    ossweb::form form_project set_values
    ossweb::form form_users set_values
}

ossweb::conn::callback create_form_project {} {

    ossweb::form form_project -title "Task/Problem Project [ossweb::html::link -text #$project_id cmd edit project_id $project_id]"

    ossweb::widget form_project.project_id -type hidden -datatype integer -optional

    ossweb::widget form_project.project_name -type text -label "Name"

    ossweb::widget form_project.status -type select -label "Status" \
         -options [ossweb::db::multilist sql:problem.project_status.select.read]

    ossweb::widget form_project.type -type select -label "Type" \
         -options { { Private Private } { Public Public } }

    ossweb::widget form_project.owner_id -type select -label "Project Owner" \
         -empty -- \
         -options [ossweb::db::multilist sql:problem.user.select.read] \
         -optional

    ossweb::widget form_project.problem_type -type select -label "Project Category" \
         -optional \
         -empty -- \
         -sql sql:problem.type.select.read \
         -sql_cache PROBLEM:TYPES

    ossweb::widget form_project.app_name -type text -label "Application(s)" \
         -size 80 \
         -optional

    ossweb::widget form_project.email_on_update -type boolean -label "Email On Update" \
         -optional

    ossweb::widget form_project.description -type textarea -label "Description" \
         -rows 5 \
         -cols 50 \
         -resize \
         -optional

    ossweb::widget form_project.back -type button -label Back \
         -url [ossweb::html::url cmd view]

    ossweb::widget form_project.update -type submit -name cmd -label Update

    ossweb::widget form_project.delete -type submit -label Delete \
         -condition "@project_id@ gt 0" \
         -name cmd \
         -html { onClick "return confirm('Record will be deleted, continue?')" }
}

ossweb::conn::callback create_form_users {} {

    ossweb::widget form_users.project_id -type hidden -value $project_id

    ossweb::widget form_users.user_id -type select \
         -options [ossweb::db::multilist sql:problem.user.select.read]

    ossweb::widget form_users.role -type select -label "Role" \
         -empty -- \
         -optional \
         -options { { Developer Developer } { Admin Admin } }

    ossweb::widget form_users.precedence -type text -label Precedence \
         -datatype int \
         -size 3 \
         -optional

    ossweb::widget form_users.cmd -type submit -label Add
}

ossweb::conn::callback create_form_search {} {

    ossweb::widget form_search.user_name -type text -label "User Name" \
         -optional

    ossweb::widget form_search.project_name -type text -label "Name" \
         -optional

    ossweb::widget form_search.status -type select -label "Status" \
         -empty -- \
         -optional \
         -options [ossweb::db::multilist sql:problem.project_status.select.read]

    ossweb::widget form_search.type -type select -label "Type" \
         -empty -- \
         -optional \
         -options { { Private Private } { Public Public } }

    ossweb::widget form_search.search -type submit -name cmd -label Search

    ossweb::widget form_search.add -type button -label Add \
         -url [ossweb::html::url cmd edit]

    ossweb::widget form_search.reset -type reset -label Reset \
         -clear
}

# Table/form columns
set columns { project_id int ""
              project_name "" ""
              status "" ""
              email_on_update "" t
              description "" ""
              owner_id int ""
              user_id int ""
              user_name "" "" }

# Process request parameters
ossweb::conn::process -columns $columns \
           -form_recreate t \
           -forms { form_project form_users form_search } \
           -eval {
            remove -
            add {
              -exec { users_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            delete {
              -exec { projects_action }
              -next { -cmd_name view }
              -on_error { -cmd_name view }
            }
            update {
              -exec { projects_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            edit {
              -exec { projects_edit }
            }
            default {
              -exec { projects_list }
            }
           }
