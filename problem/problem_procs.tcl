# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

namespace eval problem {
  variable version {Problem/Task version 2.0 $Revision: 3414 $}
  namespace eval schedule {}
  namespace eval output {}

}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

ossweb::register_init problem::init

# Link to problems from the toolbar
proc ossweb::html::toolbar::problem {} {

    if { [ossweb::conn::check_acl -acl *.problem.problem.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/problem.gif -mouseover /img/toolbar/problem_o.gif -window Problem -width "" -height "" -hspace 6 -alt "Problems/Bug Report" -app_name problem problem cmd edit close_on_complete t app_name (hex):[ossweb::conn url]?[ossweb::conn::export_form]]
}

# Preferences for problem/task
proc ossweb::control::prefs::problem { type args } {

    switch -- $type {
     columns {
        return { problem_wday "" "" }
     }

     form {
        if { [set isProblem [ossweb::admin::belong_group -group_name problem]] == "" } {
          return
        }
        ossweb::form form_prefs -section Task/Problem

        ossweb::widget form_prefs.problem_richtext -type radio -label "Use RichText Editor:" \
             -optional \
             -values [ossweb::conn problem_richtext 1] \
             -horizontal \
             -freeze \
             -options { {Yes 1} {No 0} }

        ossweb::widget form_prefs.problem_pagesize -type text -label "Tasks per Page:" \
             -datatype int \
             -size 7 \
             -optional \
             -value [ossweb::conn problem_pagesize]

        ossweb::widget form_prefs.problem_wday -type checkbox -label "Send Task/Problem Reports on:" \
            -optional \
            -horizontal \
            -values [ossweb::conn problem_wday] \
            -freeze \
            -options { {Sunday 0} {Monday 1} {Tuesday 2} {Wednesday 3} {Thursday 4} {Friday 5} {Saturday 6} }
     }

     save {
        ossweb::admin::prefs set -obj_id [ossweb::conn user_id] \
             problem_wday [ns_querygetall problem_wday] \
             problem_richtext [ns_querygetall problem_richtext] \
             problem_pagesize [ns_querygetall problem_pagesize]
     }
    }
}

# Extend user admin screen
proc ossweb::control::user::problem { type user_id args } {

    switch -- $type {
     tab {
       set isAllowed [ossweb::lexists [ossweb::db::columns ossweb_users] problem_wday]
       if { $isAllowed != "" } {
         ossweb::widget form_tab.problem -type link -label Task/Problem -value $args
       }
     }

     form {
       ossweb::form form_prefs -title "User Task/Problem Settings"

       ossweb::widget form_prefs.problem_wday -type checkbox -label "Send Task/Problem Reports on:" \
            -optional \
            -horizontal \
            -options { {Sunday 0} {Monday 1} {Tuesday 2} {Wednesday 3} {Thursday 4} {Friday 5} {Saturday 6} }

        ossweb::widget form_prefs.project_id -type checkbox \
             -label "Projects in which user is involved:" \
             -optional \
             -empty -- \
             -horizontal \
             -horizontal_cols 2 \
             -separator /img/misc/graypixel.gif \
             -css { border 0px overflow auto } \
             -values [ossweb::db::list sql:problem.project.read.by.user -colname project_id] \
             -options [ossweb::db::multilist sql:problem.project.select.all]

        ossweb::widget form_prefs.problem_projects -type checkbox \
             -label "Projects this user restricted to:" \
             -optional \
             -empty -- \
             -horizontal \
             -horizontal_cols 2 \
             -separator /img/misc/graypixel.gif \
             -css { border 0px overflow auto } \
             -options [ossweb::db::multilist sql:problem.project.select.all]

     }

     save {
       ossweb::admin::prefs set -obj_id $user_id \
            problem_wday [ns_querygetall problem_wday] \
            problem_projects [ns_querygetall problem_projects]

       if { [ossweb::db::exec sql:problem.user.delete.projects] } {
         error "OSS: Unable to clear user projects"
       }
       foreach project_id [ns_querygetall project_id] {
         if { [ossweb::db::exec sql:problem.user.create] } {
           error "OSS: Unable to add project"
         }
       }
     }
    }
}

# Runs every night and sends reports about open/completed problems via email
proc ossweb::schedule::daily::problem {} {

    problem::schedule::report \
          due_flag 1 \
          notice "You are involved into the following tasks/problems which are not completed" \
          subject "Due Report"

    problem::schedule::report \
          completed_flag 1 \
          notice "The following tasks/problems have been completed, you need to verify and close them" \
          subject "Completed Report"

    problem::schedule::report \
          unassigned_flag 1 \
          notice "The following tasks/problems are not assigned to anyone" \
          subject "Unassigned Report"
}

# Problem initialization
proc problem::init {} {

    ossweb::cache::create problem:svn

    ossweb::file::register_download_proc problem ::problem::download

    ns_register_proc GET /PROBLEM ::problem::webservice

    ns_log Notice problem: initialized
}

# Calendar reminder proc to re-open tasks
proc problem::tracker { args } {

    foreach { key val } $args { set $key $val }
    ossweb::db::exec sql:problem.reopen
}

# File download handler, used by ossweb::file::download for file download verification
proc problem::download { params } {

    set problem_id [ns_set get $params problem_id]
    if { [ossweb::datatype::integer $problem_id] != "" ||
         ([ossweb::conn session_id] == "" && [ossweb::config session:user:public] == "") ||
         [ossweb::db::value sql:problem.check] != "t" } {
      ns_log Error problem::download: [ns_conn url]: User=[ossweb::conn user_id]/[ossweb::conn session_id]: ID=$problem_id
      return file_accessdenied
    }
    ns_set update $params file:path [problem::path $problem_id]
    return file_return
}

# Webservices API to problem
proc problem::webservice { args } {

    if { ![ossweb::conn::localnetwork [ns_conn peeraddr]] } {
      ns_returnaccessdenied
      return
    }

    set cmd [file tail [ns_conn url]]
    set problem_id [ns_queryget id]
    set problem_status [ns_queryget status]
    set description [ns_queryget description]
    set svn_file [ns_queryget file]
    set svn_revision [ns_queryget rev]
    set user [ns_queryget user]

    if { $user != "" } {
      # Try to resolve user id from given name
      set user_id [ossweb::db::value sql:ossweb.user.search.by.name -vars "user_name {$user}" ]
      # If not found, try by exact first name
      if { $user_id == "" } {
        set user_id [ossweb::db::list sql:ossweb.user.search1 -vars "first_name {$user}" ]
        if { [llength $user_id] > 1 } {
          set user_id ""
        }
      }
      ossweb::conn -set $user_id $user_id
    }
    set quiet_flag [ns_queryget quiet [ossweb::config problem:email:notify]]

    switch -- $cmd {
     note {
       ossweb::db::exec sql:problem.notes.create
       ossweb::db::value sql:problem.email
     }
    }
    ns_return 200 text/html OK
}

# Path to problem files
proc problem::path { problem_id } {

    return "/problem/$problem_id"
}

# General problem report utility
proc problem::schedule::report { args } {

    set email ""
    set report ""
    set notice ""
    set subject ""
    set queue [list]
    set problem_link [ossweb::config problem:url]
    set wday [ns_fmttime [ns_time] "%w"]
    set admin_email [ossweb::config problem:email:unassigned]

    set style "<STYLE>
               .t {font-family:Verdana,Arial,Helvetica;}
               .l {color:green;}
               .d {font-family:Verdana,Arial,Helvetica;background-color:#EEEEEE;}
               </STYLE>"

    foreach { key val } $args { set $key $val }

    ossweb::db::foreach sql:problem.schedule.report {
      # Skip unwanted days
      if { $problem_wday != "" && [lsearch -exact $problem_wday $wday] == -1 } {
        continue
      }
      # Use admin email if owner is not set
      set user_email [ossweb::nvl $user_email $admin_email]
      # Put email in the queue
      if { $user_email != $email } {
        if { $report != "" && $email != "" } {
          lappend queue $email $report
        }
        set email $user_email
        set report [list "<B>$notice:</B>"]
      }
      lappend report "<HR>"
      if { $problem_link != "" } {
        lappend report "<A HREF=${problem_link}&problem_id=$problem_id><SPAN CLASS=l>ID</SPAN>: $problem_id</A>"
      } else {
        lappend report "<SPAN CLASS=l>ID</SPAN>: $problem_id"
      }
      lappend report "<SPAN CLASS=l>Project</SPAN>: [ns_striphtml $project_name]"
      lappend report "<SPAN CLASS=l>Type</SPAN>: $problem_type"
      lappend report "<SPAN CLASS=l>Status</SPAN>: $status_name ($priority_name/$severity_name)"
      lappend report "<SPAN CLASS=l>Created</SPAN>: $create_date"
      lappend report "<SPAN CLASS=l>Submitted By</SPAN>: $user_name"
      lappend report "<SPAN CLASS=l>Last Updated</SPAN>: $update_date"
      if { $due_date != "" } {
        lappend report "<SPAN CLASS=l>Due Date</SPAN>: $due_date [ossweb::decode $overdue t "(Overdue)" ""]"
      }
      if { $owner_name != "" } {
        lappend report "<SPAN CLASS=l>Assigned</SPAN>: $owner_name"
      }
      lappend report "<SPAN CLASS=l>Responsible</SPAN>: [problem::output::users $problem_users -format text -break ", "]"
      if { $count > 0 } {
        lappend report "<SPAN CLASS=l>Followups</SPAN>: $count"
      }
      lappend report "<SPAN CLASS=l>Title</SPAN>: <SPAN CLASS=t>[ns_striphtml $title]</SPAN>"
      lappend report "<SPAN CLASS=l>Description</SPAN>: <SPAN CLASS=d>$description</SPAN>"
    }
    if { $report != "" && $email != "" } {
      lappend queue $email $report
    }
    # Send all messages from local queue
    foreach { email body } $queue {
      set body "$style\n[join $body "<BR>"]"
      set subj "\[TASK/Problem\]: $subject"
      ossweb::sendmail $email problem $subj $body -content_type text/html
    }
}

# Output problem users
proc problem::output::users { users args } {

    ns_parseargs { {-format html} {-break "\n"} {-prefix ""} {-role ""} {-email f} } $args

    set result ""
    foreach { user_id user_name user_email user_role } $users {
      # Role filter
      if { $role != "" && ![regexp -nocase $role $user_role] } {
        continue
      }
      # Return just emails
      if { $email == "t" } {
        lappend result $user_email
        continue
      }
      switch $format {
       html {
          append result $prefix $user_name
          if { $user_role != "" } {
            append result /$user_role
          }
          append result "<BR>"
       }

       text {
          append result $prefix $user_name
          if { $user_role != "" } {
            append result /$user_role
          }
          append result $break
       }
      }
    }
    return $result
}

# Output problem files
proc problem::output::files { problem_id files args } {

    ns_parseargs { {-format html}
                   {-break ""}
                   {-prefix ""}
                   {-suffix ""}
                   {-delete f}
                   {-direct f}
                   {-size f}
                   {-mtime f}
                   {-separator "&nbsp;"} } $args

    set path [problem::path $problem_id]
    set result ""
    switch $format {
     html {
        foreach file $files {
          set item ""
          set name [ossweb::file::name $file]
          if { ![ossweb::file::exists $file -path $path] } {
            set item "$name <FONT SIZE=1 COLOR=red>(not available)</FONT>"
          } else {
            switch $direct {
             f {
               set item [ossweb::file::link problem $name -html "TARGET=file" problem_id $problem_id]
             }
             t {
               set item [ossweb::html::link -text $name -html "TARGET=file" cmd file problem_id $problem_id name $file]
             }
            }
            if { $mtime == "t" } {
              append item "$separator[ns_fmttime [ossweb::file::mtime $file -path $path] "%Y-%m-%d %H:%M"]"
            }
            if { $size == "t" } {
              append item "$separator[ossweb::util::size [ossweb::file::size $file -path $path]]"
            }
            if { $delete == "t" } {
              append item "$separator[ossweb::html::link -image trash.gif -confirm "confirm('File will be deleted, continue?')" cmd delete.file problem_id $problem_id name $file]"
            }
          }
          lappend result $prefix$item$suffix
        }
     }

     list {
        foreach file $files {
          set name [ossweb::file::name $file]
          switch $direct {
           f {
             set url [ossweb::file::link problem $name -html "TARGET=file" problem_id $problem_id]
           }
           t {
             set url [ossweb::html::link -text $name -html "TARGET=file" cmd file problem_id $problem_id name $file]
           }
          }
          lappend result $name $url [ossweb::file::mtime $file -path $path] [ossweb::file::size $file -path $path]
        }
     }

     text {
        foreach file $files {
          lappend result "$prefix[ossweb::file::name $file]$suffix"
        }
     }
    }
    return [join $result $break]
}

# Full text search provider for problem records
proc ossweb::tsearch::problem { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type problem
       set tsearch_id problem_id::TEXT
       set tsearch_value project_id
       set tsearch_table problems
       set tsearch_date update_date
       set tsearch_text "title||' '||COALESCE(description,'')||' '||COALESCE(problem_tags,'')"
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     filter {
       return {str_lexists('[ossweb::conn problem_projects]',tsearch_value)}
     }

     name {
       return Task
     }

     url {
       # Returns full url to the record
       return [ossweb::html::url problem.problem cmd edit problem_id [lindex $args 0]]
     }
    }
}

# Full text search provider for problem notes
proc ossweb::tsearch::problem_note { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type problem_note
       set tsearch_id problem_note_id::TEXT
       set tsearch_data problem_id
       set tsearch_value "(SELECT project_id FROM problems p WHERE p.problem_id=tt.problem_id)"
       set tsearch_table problem_notes
       set tsearch_date create_date
       set tsearch_text "description||' '||problem_files(problem_id,problem_note_id)"
       set tsearch_noupdate 1
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     filter {
       return {str_lexists('[ossweb::conn problem_projects]',tsearch_value)}
     }

     app_name {
       return problem
     }

     name {
       return TaskNote
     }

     url {
       # Returns full url to the record
       return [ossweb::html::url problem.problem cmd edit problem_note_id [lindex $args 0] problem_id [lindex $args 1]]
     }
    }
}

# Tracker support
proc ossweb::tracker::problem { cmd args } {

    ns_parseargs { {-limit ""} {-id ""} {-title ""} {-data ""} } $args

    switch -- $cmd {
     new {
        set problem_limit $limit
        set problem_sort "update_date DESC"
        set problem_columns { INITCAP(p.problem_status)||'/'||INITCAP(p.problem_type)||': '||title
                              p.last_note_text
                              TO_CHAR(p.update_date,'YYYY-MM-DD HH24:MI')
                              "ROUND(EXTRACT(EPOCH FROM (NOW() - p.update_date)))"
                              last_note_id }
        return [ossweb::db::multilist sql:problem.search1]
     }

     title {
        return Tasks/Problems
     }

     url {
        return [ossweb::html::url -hash $data problem.problem cmd edit problem_id $id]
     }
    }
}
