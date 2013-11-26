# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

# Run SVN command
proc svn_run { args } {

    catch { set rc [eval exec svn $args] } rc
    return $rc
}

# Build current search filter
proc problem_filter {} {

    set filter [ossweb::convert::list_to_query [ossweb::conn::get_property PROBLEM:FILTER -global t]]
    append filter " " [ossweb::convert::list_to_query [ossweb::conn::get_property PROBLEM:SORTFILTER -global t]]
    return [string trim $filter]
}

# Return icon for the status
proc problem_icon { status { name_only 0 } } {

    switch -glob -- [string tolower $status] {
     open -
     *progress {
       set icon Red
     }
     closed -
     cancelled {
       set icon Grey
     }

     approval -
     completed {
       set icon Green
     }

     pending {
       set icon Yellow
     }

     default {
       set icon Blue
     }
    }
    if { $name_only } {
      return /img/balls/$icon.gif
    }
    return [ossweb::html::image balls/$icon.gif -align absbottom]
}

# Send notifications
ossweb::conn::callback email_action {} {

    set quiet_flag [ossweb::nvl $quiet_flag [ossweb::config problem:email:notify]]

    if { $quiet_flag == 1 } {
      set quiet_flag t
    }
    if { $email_flag == 1 || $quiet_flag == 0 } {
      set quiet_flag f
    }
    ossweb::db::value sql:problem.email
}

# Initialize SVN files and revisions
ossweb::conn::callback svn_action {} {

    # Information datasource
    ossweb::multirow create info line

    # Specific parameteres
    set rev [ns_queryget rev]
    set std [ns_queryget std]

    # SVN configuration
    set path [ossweb::config problem:svn:path]
    set config [ossweb::config problem:svn:config]
    if { $path == "" || $config == "" } {
      ns_log Notice problem: SVN is not configured
      return
    }

    # List of files in the repository
    set files [ossweb::cache::run problem:svn files {
       foreach file [split [svn_run ls -R --config-dir $config $path] "\n"] {
         lappend files $file
       }
       return $files
    } -expires 3600]

    # These are for files only
    if { ![string match */ $title] } {
      ossweb::widget form_svn.info -type button -label Info \
           -onClick "sGet('$title','info',this.form.revisions.value)" \
           -help "Show info about the current file/revision"

      ossweb::widget form_svn.diff -type button -label Diff \
           -onClick "sGet('$title','diff',this.form.revisions.value)" \
           -help "Show diff for current file/revision"

      ossweb::widget form_svn.log -type button -label Log \
           -onClick "sGet('$title','log',this.form.revisions.value)" \
           -help "Show log for current file/revision"

      ossweb::widget form_svn.view -type button -label View \
           -onClick "sGet('$title','view',this.form.revisions.value)" \
           -help "Show source code for the current file/revision"
    }

    # Common widgets for all types
    set revisions [ossweb::cache::run problem:svn revisions {
       set revisions ""
       foreach rev [svn_run log -q --config-dir $config $path] {
         if { [string index $rev 0] == "r" } {
           set rev [string range [lindex $rev 0] 1 end]
           lappend revisions [list "Rev $rev" $rev]
         }
       }
       return $revisions
    } -expires 3600]

    ossweb::widget form_svn.revisions -type select \
         -options $revisions \
         -value $rev \
         -css "font-weight bold"

    ossweb::widget form_svn.select -type button -label Select \
         -onClick "sPut('$title',this.form.revisions.value)" \
         -help "Select this file/revision for the note" \
         -eval { if { $std != "" } { return } }

    ossweb::widget form_svn.update -type button -label Refresh \
         -onClick "sGet('$title','update')" \
         -help "Refresh from repository"

    # Subcommand processing
    switch -- ${ossweb:ctx} {
     update {
        foreach line [split [svn_run up --config-dir $config $path] "\n"] {
          if { [regexp {^r([0-9]+)} $line d rev] } {
            ossweb::multirow append info $line
          }
        }
        ossweb::cache::flush problem:svn files
        ossweb::cache::flush problem:svn revisions
     }

     view {
        foreach line [split [svn_run cat --config-dir $config $path/$title@$rev] "\n"] {
          if { $line != "" } {
            ossweb::multirow append info [string map { " " "&nbsp;" } $line]
          }
        }

     }

     diff {
        foreach line [split [svn_run diff -r $rev --config-dir $config $path/$title] "\n"] {
          if { $line != "" } {
            ossweb::multirow append info [string map { " " "&nbsp;" } $line]
          }
        }
     }

     log {
        set prev ""
        foreach line [split [svn_run log --config-dir $config $path/$title] "\n"] {
          if { [regexp {^r([0-9]+)} $line d rev] } {
            set line "[ossweb::html::link -text Diff -url "javascript:sGet('$title','diff','$rev$prev')"] $line"
            ossweb::multirow append info $line
            set prev :$rev
          }
        }
     }

     info {
        # For directory show list of files
        if { [string match */ $title] } {
          foreach file $files {
            if { [regexp "$title\[^/]+\$" $file] } {
              set text "[ossweb::html::image [ossweb::file::icon $file]]&nbsp;[file tail $file]"
              ossweb::multirow append info [ossweb::html::link -text $text -url "javascript:sGet('$file')"]
            }
          }
        } else {
          # For file, show information about the file
          foreach line [split [svn_run info --config-dir $config $path/$title] "\n"] {
            if { $line != "" } {
              ossweb::multirow append info $line
            }
          }
        }
     }

     file -
     tree {
        foreach file $files {
          # Show only directories
          if { ![string match */ $file] } {
            continue
          }
          set name [file tail $file]
          set owner [file dirname $file]/
          set url "javascript:sGet(\\'$file\\');"
          set parent [ossweb::coalesce folders($owner) 0]
          append tree_items "Tree\[[incr tree_idx]\] = new Array([incr tree_id],$parent,'$name','$url','','/img/tree/folder.gif');\n"
          set folders($file) $tree_id
        }
        ossweb::html::include /js/tree.js
     }
    }
}

ossweb::conn::callback info_action {} {

    if { [ossweb::db::multivalue sql:problem.read] } {
      error "OSSWEB: Record not found or access denied"
    }

    switch -exact ${ossweb:ctx} {
     notedescr {
        ossweb::db::multivalue sql:problem.notes.read
        ossweb::adp::Exit $description
     }

     default {
        ossweb::db::foreach sql:problem.notes.read_all {
          append description "<P><B>$_create_date by $_user_name</B>"
          if { $_status_name != "" } {
            append description ", <B>$_status_name</B>"
          }
          if { ![ossweb::true $tinyMCE] } {
            set _description [string map { \n <BR> } $_description]
          }
          append description "<BR>" $_description
        } -prefix _
     }
    }
}

ossweb::conn::callback note_action {} {

    if { [ossweb::db::value sql:problem.check] != "t" } {
      error "OSSWEB: Access denied to this project"
    }
    ossweb::db::begin
    switch -exact ${ossweb:cmd} {

     update {
       if { $due_date != "" } {
          set due_date [ossweb::date parse2 $due_date]
       }
       # Cannot schedule if no description given
       if { $cal_date != "" && $description == "" } {
         set cal_date ""
         set cal_repeat ""
         ossweb::conn::set_msg "Reopen/Reminder is not set due to lack of description"
       }
       # Let note to update problem status once
       if { [ossweb::db::exec sql:problem.update -vars {problem_status {}}] } {
         error "OSSWEB: Unable to update the record"
       }
       if { $problem_status != "" || $description != "" } {
         # Convert HTML tags so they will be shown on the page properly
         if { $html_flag == 1 } {
           set description [string map { < &lt; > &gt; } $description]
         }
         if { $owner_flag == 1 } {
           set owner_id [ossweb::conn user_id]
         }
         if { [set problem_note_id [ns_queryget problem_note_id]] == "" } {
           set problem_cc $notes_cc
           if { [ossweb::db::exec sql:problem.notes.create] } {
             error "OSSWEB: Unable to create note"
           }
           set problem_note_id [ossweb::db::currval problem]
           # Send notifications
           email_action
         } else {
           if { [ossweb::db::exec sql:problem.notes.update] } {
             error "OSSWEB: Unable to update note"
           }
         }
         ossweb::conn::set_msg "Record updated"
       }
       # Merge other tasks
       if { [set merge_id [ns_queryget merge_id]] != "" &&
            [ossweb::db::value sql:problem.project.owner] == [ossweb::conn user_id] } {
         if { [ossweb::db::exec sql:problem.merge.notes] ||
              [ossweb::db::exec sql:problem.merge.files] ||
              [ossweb::db::exec sql:problem.merge.problems] } {
           error "OSSWEB: Unable to merge notes"
         }
       }

       # Save uploaded file
       set ossweb:cmd upload
       file_action

       # Exit to the top search page requested
       if { [ns_queryget exit] != "" } {
         ossweb::conn::next -cmd_name view
       }
     }

     delete {
       if { [ossweb::db::exec sql:problem.notes.delete] } {
         error "OSSWEB: Unable to delete note"
       }
       ossweb::conn::set_msg "Record deleted"
     }
    }
    ossweb::db::commit
    # Flush cached search results
    ossweb::sql::multipage problem -flush t
}

ossweb::conn::callback file_action {} {

    if { [ossweb::db::value sql:problem.check] != "t" } {
      error "OSSWEB: Access denied to this project"
    }

    switch -exact ${ossweb:cmd} {

     file {
        ossweb::file::return [ns_queryget name] -path [problem::path $problem_id]
     }

     upload {
       foreach file { upload upload1 upload2 upload3 upload4 } {
         set name [ossweb::file::upload $file -path [problem::path $problem_id]]
         if { [ossweb::file::exists $name -path [problem::path $problem_id]] } {
           if { [ossweb::db::exec sql:problem.file.update] ||
                ([ossweb::db::rowcount] == 0 &&
                 [ossweb::db::exec sql:problem.file.create]) } {
             error "Unable to save problem note file"
           }
           ossweb::conn::set_msg "File $name uploaded"
         }
       }
     }

     delete {
       if { [ossweb::db::exec sql:problem.file.delete] } {
        error "OSSWEB: Unable to delete the file"
       }
       ossweb::file::delete [ns_queryget name] -path [problem::path $problem_id]
       ossweb::conn::set_msg "File deleted"
     }
    }
}

ossweb::conn::callback problem_action {} {

    ossweb::db::begin
    switch -exact ${ossweb:cmd} {

     add {
       if { [ossweb::db::value sql:problem.project.check] != "t" } {
         error "OSSWEB: Access denied to this project"
       }
       if { [ossweb::db::exec sql:problem.create] } {
         error "OSSWEB: Unable to create problem record"
       }
       set problem_id [ossweb::db::currval problem]
       # Save uploaded file
       set ossweb:cmd upload
       file_action
       email_action
       ossweb::conn::set_msg "Record added"
       # Flush project statistics with new tasks
       ossweb::db::cache flush PROBLEM:STATS:*
     }

     update {
       if { [ossweb::db::multivalue sql:problem.read -prefix _] } {
         error "OSSWEB: Unable to read problem record"
       }
       if { [ns_queryexists due_date] } {
         if { $due_date == "" } {
           set due_date NULL
         } else {
           set due_date [ossweb::date parse2 $due_date]
         }
       }
       if { [ns_queryexists problem_tags] } {
         if { $problem_tags == "" } {
           set problem_tags NULL
         }
       }
       if { [ossweb::db::exec sql:problem.update] } {
         error "OSSWEB: Unable to update the problem"
       }
       # Save uploaded file
       set ossweb:cmd upload
       file_action
       ossweb::conn::set_msg "Record updated"

       # Special quick update
       if { ${ossweb:ctx} == "fast" } {
         ossweb::db::commit
         ossweb::adp::Exit
       }
     }

     close {
       if { [ossweb::db::exec sql:problem.close_all_completed] } {
        error "OSSWEB: Unable to close problems"
       }
     }

     delete {
       if { [ossweb::db::exec sql:problem.delete] } {
        error "OSSWEB: Unable to delete from the problem"
       }
       ossweb::conn::set_msg "Record deleted"
     }
    }
    ossweb::db::commit
    # Flush cached search results
    ossweb::sql::multipage tasks -flush t
}

# Favorite queries handling
ossweb::conn::callback problem_favorites {} {

    set name [ns_queryget name]
    set owner [ns_queryget owner]

    switch -exact ${ossweb:ctx} {
     save {
       # Save current filter and sorting order
       set filter [problem_filter]

       if { $name != "" && $filter != "" } {
         # Global or private filter
         set owner [ossweb::decode [ns_queryget global] true 0 [ossweb::conn user_id]]
         ossweb::db::exec sql:problem.favorites.add
       }
     }

     delete {
       if { $name != "" && $owner != "" } {
         ossweb::db::exec sql:problem.favorites.delete
       }
     }
    }

    ossweb::widget form_favorites.name -type text -label Name

    ossweb::widget form_favorites.global -type checkbox -label Global \
         -value t \
         -html { TITLE "Make this filter available to everyone" } \
         -optional

    ossweb::widget form_favorites.save -type button -label Save \
         -url "javascript:window.location='[ossweb::html::url cmd favorites.save name javascript:\$('name').value global javascript:\$('global').checked]'"

    ossweb::widget form_favorites.close -type button -label Close \
         -url "javascript:window.close()"

    ossweb::multirow create favorites url delete global

    ossweb::db::foreach sql:problem.favorites.list {
      if { $user_id == [ossweb::conn user_id] } {
        set delete [ossweb::html::link -image trash.gif -title Delete cmd favorites.delete name $name owner $owner]
      } else {
        set delete [ossweb::html::image world.gif -alt Global]
        append name "<SPAN STYLe=\"font-size:6pt;color:gray;\"> (by $user_name)</FONT>"
      }
      set filter "cmd=search&$filter"
      set url [ossweb::html::link -text $name -onClick "window.opener.location='[ossweb::html::url -query $filter]'" -url "js:;"]
      ossweb::multirow append favorites $url $delete
    }
}

ossweb::conn::callback problem_edit {} {

    if { $problem_id > 0 } {
      if { [ossweb::db::multivalue sql:problem.read] } {
        error "OSSWEB: Record not found or access denied"
      }
      # Mark last time the user seen this problem
      array set seen [ossweb::conn::get_property PROBLEM:SEEN -global t]
      if { ![info exists seen($problem_id)] || [ns_time] - $seen($problem_id) > 300 } {
        set seen($problem_id) [ns_time]
        ossweb::conn::set_property PROBLEM:SEEN [array get seen] -global t
      }

      set problem_link [ossweb::html::link -text "\[$problem_id\]" cmd edit problem_id $problem_id]
      ossweb::widget form_notes.problem_id -value $problem_id
      ossweb::widget form_notes.problem_status -value ""
      ossweb::widget form_notes.description -value ""
      ossweb::widget form_notes.cal_repeat -value ""

      if { ![ossweb::true $tinyMCE] } {
        set description [ossweb::util::wrap_text $description -size 80]
        set description [string map { \n <BR> < &lt; > &gt; } $description]
      } else {
        # No need, it is always HTML in tinyMCE
        ossweb::widget form_notes.html_flag -type none
      }
      if { [string length $description] > 512 } {
        incr descr_height 100
      }
      # Format list of attached files
      set files [problem::output::files $problem_id $files \
                       -delete t \
                       -prefix "<TR><TD>" \
                       -suffix "</TD></TR>" \
                       -separator "</TD><TD>" \
                       -mtime t -size t]
      # Adjust description size if too many files
      if { [string length $files] > 256 } {
        incr files_height 40
      }

      # Show only allowed statuses
      set type_filter [ossweb::db::value sql:problem.status.allowed.read]
      ossweb::convert::plain_list type_filter
      set type_filter "AND status_id IN ([ossweb::sql::list [ossweb::nvl $type_filter '']])"

      # Restrict non-owners from admin actions
      if { $user_id != [ossweb::conn user_id] && $project_owner_id != [ossweb::conn user_id] } {
        # Allow reopen as well
        append type_filter "AND type NOT IN ('close')"

        set title [ossweb::util::wrap_text $title -size 60 -break "<BR>"]
        set problem_cc [string map { , {, } } $problem_cc]

        ossweb::widget form_problem.update destroy
        ossweb::widget form_problem.delete destroy
        ossweb::widget form_problem.title -type inform
        ossweb::widget form_problem.hours_required -type inform
        ossweb::widget form_problem.problem_type -type labelselect -force
        ossweb::widget form_problem.project_id -type labelselect -force
        ossweb::widget form_problem.owner_id -type combobox -textwidget label \
             -title $owner_name \
             -onChange ";"
        ossweb::widget form_problem.due_date -format "TEXTl"
        ossweb::widget form_problem.priority -type labelselect -force
        ossweb::widget form_problem.severity -type labelselect -force
        ossweb::widget form_problem.problem_cc -type label -bold

        if { $alert_on_complete == "t" } {
          set alert_on_complete [ossweb::html::image checked.gif -width "" -height ""]
          ossweb::widget form_problem.alert_on_complete -type inform
        } else {
          ossweb::widget form_problem.alert_on_complete destroy
        }
        if { $close_on_complete == "t" } {
          set close_on_complete [ossweb::html::image checked.gif -width "" -height ""]
          ossweb::widget form_problem.close_on_complete -type inform
        } else {
          ossweb::widget form_problem.close_on_complete destroy
        }
      }

      # Editable tags
      ossweb::widget form_problem.problem_tags -type popuptext -label "Tags" \
           -size 50 \
           -image tag.gif \
           -url [ossweb::html::url cmd update.fast problem_id $problem_id] \
           -optional

      if { $project_owner_id == [ossweb::conn user_id] } {
        ossweb::widget form_notes.merge_id -type text -label "Merge with" \
             -size 25 \
             -labelhelp "List of Task/Problem IDs which notes/follow-ups should be
                         merged into current list"

        if { $problem_status == "deleted" } {
          ossweb::widget form_problem.delete -type button -label Delete \
               -url [ossweb::html::url cmd delete problem_id $problem_id] \
               -confirm "confirm('Record will be deleted, continue?')"
        }
      }

      ossweb::widget form_notes.problem_status \
           -options [ossweb::db::multilist sql:problem.status.select.read -cache PROBLEM:STATUS:$type_filter] \
           -values {}

      # Save sorting order
      if { ${ossweb:ctx} == "sort" } {
        ossweb::conn::set_property PROBLEM:SORTNOTES "" -columns { sort "" "" desc "" "" } -global t
      }
      # Update sorting widgets from cache
      ossweb::conn::get_property PROBLEM:SORTNOTES -columns t -global t
      ossweb::form form_nsort refresh_values

      ossweb::db::multirow notes sql:problem.notes.read_all -eval {
        if { ![ossweb::true $tinyMCE] } {
          set row(description) [string map { \n <BR> < &lt; > &gt; } $row(description)]
        }
        set row(files) [problem::output::files $problem_id $row(files) -break "<BR>"]
        if { $row(hours) != "" } {
          set hours_worked [expr $hours_worked + $row(hours)]
        }
        if { $row(svn_file) != "" } {
          set svn_file ""
          foreach file $row(svn_file) {
            append svn_file [ossweb::html::link -lookup t \
                                  -text [string map { / " /" } $file] \
                                  -window SVN \
                                  -winopts $winopts cmd svn.file title $file rev $row(svn_revision)]
          }
          set row(svn_file) $svn_file
        }
      }

      # Populate select boxes
      set owners [ossweb::db::multilist sql:problem.user.select.by.problem]
      lappend owners [list Unassign Null]
      ossweb::widget form_problem.owner_id -options $owners
      ossweb::widget form_notes.owner_id -options $owners

      # Top title
      ossweb::conn -set title "Task/Problem Details ($problem_status_name)"

    } else {
      # Assign project by application name
      if { $app_name != "" } {
        set project_id [ossweb::db::value sql:problem.project.read.by.app_name]
        set problem_type problem
        set description "URL: $app_name\n"
      }

      # List of possible responsible for given project
      if { $project_id != "" } {
        ossweb::widget form_problem.owner_id \
             -options [ossweb::db::multilist sql:problem.user.select.by.project]
        # Read project details
        ossweb::db::multivalue sql:problem.project.read -array project
        set problem_type $project(problem_type)
      }
      # Make description field bigger
      ossweb::widget form_problem.description -cols 80 -rows 20
    }
    set problem_icon [problem_icon $problem_status]
    ossweb::form form_problem set_values
}

ossweb::conn::callback problem_tree {} {

    ossweb::db::foreach sql:problem.tree {
      set icon ""
      set params ""
      set name [string map { "\n" {} "\r" {} "\t" {} ' {} } $name]
      if { [string length $name] > 50 } {
        set params "TITLE=\"$name\""
        set name [string range $name 0 50]...
      }
      if { $status != "" } {
        set icon [problem_icon $status 1]
      }
      if { $update_date != "" } {
        append status " ($update_date"
        if { $due_date != "" } {
          append status " / $due_date"
        }
        append status ")"
      }
      if { $percent_completed != "" } {
        append status "/$percent_completed%"
      }
      set url "javascript:pInfo($id,$type);"
      set parent [ossweb::coalesce folders($owner) 0]
      append tree_items "Tree\[[incr tree_idx]\] = new Array([incr tree_id],$parent,'$name','$url','$params','$icon','<SPAN>$status</SPAN>');\n"
      set folders($id) $tree_id
    } -map { "'" "" {"} {} {"} {} }
    ossweb::html::include /js/tree.js
}

ossweb::conn::callback problem_list {} {

    ossweb::conn -set title "Tasks"
    switch ${ossweb:cmd} {
     rss -
     search {
       ossweb::conn::set_property PROBLEM:FILTER "" -skip { cmd page pagesize } -forms form_search -global t
       set force t
       if { [ns_queryget list] != "" } {
         set pagesize 999999
       }
       if { ${ossweb:cmd} == "rss" } {
         ossweb::adp::Trim 1
         ossweb::adp::ContentType application/xhtml+xml
       }
     }

     sort {
       # Change sorting order
       ossweb::conn::set_property PROBLEM:SORTFILTER "" -columns { sort "" "" desc "" "" } -global t
     }

     reset {
       return
     }
    }

    ossweb::conn::get_property PROBLEM:SORTFILTER -columns t -global t
    ossweb::conn::get_property PROBLEM:FILTER -skip { cmd page pagesize } -columns t -global t

    ossweb::form form_search set_values
    # Group and color project if specified
    if { $projectgroup_flag != "" } {
      set problem_sort p.project_id
      set projectcolors { #000000 #3C688A #57574b #3a0e93 #366405 #993300 }
    }
    # Update sorting widgets and variables
    ossweb::form form_psort refresh_values
    # Retrieve already seen tasks
    array set seen [ossweb::conn::get_property PROBLEM:SEEN -global t]
    # Run the query
    ossweb::db::multipage tasks \
         sql:problem.search1 \
         sql:problem.search2 \
         -page $page \
         -force $force \
         -pagesize $pagesize \
         -eval {
      # Mark with red overdue problems
      set html [ossweb::decode $row(overdue) "t" "STYLE=\"color:red\"" ""]
      set row(icon) [problem_icon $row(problem_status)]
      set row(url) [ossweb::html::url cmd edit problem_id $row(problem_id)]
      set row(link) [ossweb::html::link -text $row(title) -html $html -url $row(url)]
      set row(icons) ""
      if { [lindex $row(count) 1] == "t" } {
        set last_seen [ossweb::coalesce seen($row(problem_id)) 0]
        if { $last_seen < [lindex $row(count) 2] } {
          append row(icons) [ossweb::html::image new.gif -alt "Unread Msgs"] "<BR>"
        }
      }
      if { $row(file_count) > 0 } {
        append row(icons) [ossweb::html::image attach.gif -alt "File Attached"] "<BR>"
      }
      set row(count) [lindex $row(count) 0]
      if { $row(update_time) != "" } {
        set row(update_time) [ossweb::date uptime $row(update_time) short]
      }
      # Separate different projects by color
      if { $projectgroup_flag != "" } {
        set color [ossweb::coalesce projectgroup($row(project_id))]
        if { $color == "" } {
          set color [lindex $projectcolors 0]
          set projectcolors "[lrange $projectcolors 1 end] $color"
          set projectgroup($row(project_id)) $color
        }
        set row(project_name) "<FONT COLOR=$color>$row(project_name)</FONT>"
      }
      # Use description for poup over if no notes yet
      if { $row(last_note_text) == "" } {
        set row(last_note_text) $row(description)
      }
      if { $row(last_note_text) != "" } {
        set row(last_note_text) [ossweb::html::link \
                                      -text [string range [string trim [ns_striphtml $row(last_note_text)]] 0 40]... \
                                      -popupover $row(last_note_text) \
                                      -popupoveropts { delay:1000,custom:popupPosition } \
                                      -class gray \
                                      -href f]
      }
    }
    # Refresh page every minute
    ossweb::html::include "javascript:setTimeout(function (){window.location='[ns_conn url]'},60000);"
}

ossweb::conn::callback problem_init { } {

    ossweb::html::include /js/notes.js
}

ossweb::conn::callback create_form_problem { } {

    ossweb::form form_problem -title "Task/Problem Details"

    if { $problem_id > 0 } {

      ossweb::widget form_problem.cmd -type hidden -value update -freeze

      ossweb::widget form_problem.ctx -type hidden -value problem -freeze

      ossweb::widget form_problem.problem_id -type hidden

      ossweb::widget form_problem.create_date -type inform -label "Created" \
           -bold

      ossweb::widget form_problem.user_name -type inform -label "Submitted By" \
           -bold

      ossweb::widget form_problem.owner_id -type select -label "Assigned To" \
           -optional \
           -empty "Not assigned"

      ossweb::widget form_problem.owner_users -type inform -label "Assigned Users" -bold

      ossweb::widget form_problem.project_id -type select -label "Project" \
           -sql sql:problem.project.select.read \
           -css { width 200 }

      ossweb::widget form_problem.problem_type -type select -label "Type" \
           -sql sql:problem.type.select.read \
           -sql_cache PROBLEM:TYPES

      ossweb::widget form_problem.priority -type select -label "Priority" \
           -sql_table problem_priorities \
           -sql_columns priority_name,priority_id \
           -sql_sort 2

      ossweb::widget form_problem.severity -type select -label "Severity" \
           -sql_table problem_severities \
           -sql_columns severity_name,severity_id \
           -sql_sort 2

      ossweb::widget form_problem.create_date -type inform -label "Created" \
           -bold

      ossweb::widget form_problem.due_date -type date -label "Due Date" \
           -calendar \
           -optional \
           -format TEXT \
           -labelhelp "Date which signifies when this<br>
                       task/problem should be completed"

      ossweb::widget form_problem.title -type textarea -label "Title" \
           -bold \
           -cols 50 \
           -rows 1 \
           -resize

      ossweb::widget form_problem.description -type inform -label "Description" \
           -bold

      ossweb::widget form_problem.hours_required -type text -label "Hours Required" \
           -bold \
           -size 5 \
           -labelhelp "Estimate how much time<br>
                       this task/problem may take"

      ossweb::widget form_problem.files -type inform -label "Files" -bold

      ossweb::widget form_problem.close_on_complete -type checkbox -label "Close On Complete" \
           -value t \
           -labelhelp "If checked, on completion this task<br>
                       will be automatically closed"

      ossweb::widget form_problem.alert_on_complete -type checkbox -label "Alert On Complete" \
           -value t \
           -labelhelp "If checked, on task completion an email<br>
                       will be sent to the owner immediately"

      ossweb::widget form_problem.problem_cc -type text -label "Email Notification" \
           -cols 25 \
           -rows 1 \
           -optional \
           -resize \
           -labelhelp "Additional emails who should receive<br>
                       notifications about progress of this task/project"

      ossweb::widget form_problem.update -type submit -label Update

      ossweb::widget form_problem.new -type button -label New \
           -url "cmd edit" \
           -help "Create new Task/Problem"

      ossweb::widget form_problem.back -type button -label List \
           -url "cmd view" \
           -help "Go back to the main list"

      ossweb::widget form_problem.tree -type button -label Tree \
           -url "cmd tree" \
           -help "Return to the hierachy view"

      if { [ossweb::config problem:svn:path] != "" } {
        ossweb::widget form_problem.svnTree -type button -label SVN \
             -help "Add file revision reference from SVN" \
             -url [ossweb::html::url -lookup t cmd svn.tree] \
             -window SVN \
             -winopts $winopts
      } 

    } else {
      ossweb::widget form_problem.problem_id -type hidden -optional

      ossweb::widget form_problem.app_name -type hidden -optional

      ossweb::widget form_problem.project_id -type select -label "Project" \
           -empty -- \
           -html [list onChange "window.location='[ossweb::html::url cmd edit project_id ""]'+this.form.project_id.value" ] \
           -sql sql:problem.project.select.read

      ossweb::widget form_problem.problem_type -type select -label "Type" \
           -sql sql:problem.type.select.read \
           -sql_cache PROBLEM:TYPES

      ossweb::widget form_problem.problem_status -type select -label "Status " \
           -sql sql:problem.status.select.read_new \
           -sql_cache PROBLEM:STATUS:NEW

      ossweb::widget form_problem.priority -type select -label "Priority" \
           -sql_table problem_priorities \
           -sql_columns priority_name,priority_id \
           -sql_sort 2

      ossweb::widget form_problem.severity -type select -label "Severity" \
           -sql_table problem_severities \
           -sql_columns severity_name,severity_id \
           -sql_sort 2

      ossweb::widget form_problem.owner_id -type select -label "Assign To" \
           -optional \
           -empty "Not assigned"

      ossweb::widget form_problem.due_date -type date -label "Due Date" \
           -format "DD MONTH YYYY" \
           -optional \
           -calendar

      ossweb::widget form_problem.title -type textarea -label "Title" \
           -cols 60 \
           -rows 2 \
           -resize \
           -focus

      ossweb::widget form_problem.description -type textarea -label "Description" \
           -rows 12 \
           -cols 80 \
           -resize \
           -rich [ossweb::true $tinyMCE] \
           -html { wrap off }

      ossweb::widget form_problem.upload -type file -label "Attach File" \
           -optional

      ossweb::widget form_problem.quiet_flag -type select -label "Notification" \
           -separator /img/misc/graypixel.gif \
           -optional \
           -empty -- \
           -options { { "Notify All" 0 } { "Quiet Mode" 1 } }

      ossweb::widget form_problem.problem_cc -type text -label "Email Also To" \
           -optional \
           -size 60

      ossweb::widget form_problem.close_on_complete -type boolean -label "Close On Complete"

      ossweb::widget form_problem.alert_on_complete -type boolean -label "Alert On Complete"

      ossweb::widget form_problem.hours_required -type text -label "Hours Required" \
           -size 5 \
           -optional

      ossweb::widget form_problem.upload -type file -label "File" -optional

      ossweb::widget form_problem.update -type submit -name cmd -label Add

      ossweb::widget form_problem.back -type button -label Back \
           -url "cmd view" \
           -help "Go back to the main list"
    }
}

ossweb::conn::callback create_form_notes {} {

    ossweb::form form_notes -html { onSubmit notesSubmit() }

    ossweb::widget form_notes.cmd -type hidden -value update -freeze

    ossweb::widget form_notes.ctx -type hidden -value note -freeze

    ossweb::widget form_notes.problem_id -type hidden -datatype integer

    ossweb::widget form_notes.problem_note_id -type hidden -optional -freeze

    if { [ossweb::config problem:svn:path] != "" } {
      ossweb::widget form_notes.svn_file -type label -label "SVN File" -optional

      ossweb::widget form_notes.svn_revision -type label -label "SVN Revision" -optional
    }

    ossweb::widget form_notes.problem_status -type radio -datatype name -label "Status" \
         -optional

    ossweb::widget form_notes.owner_id -type select -label "Reassign To" \
         -optional \
         -empty -- \
         -labelhelp "Re-assign this task to another person in the project"

    ossweb::widget form_notes.description -type textarea -datatype text -label "Notes" \
         -optional \
         -rows 10 \
         -cols 60 \
         -resize \
         -rich [ossweb::true $tinyMCE] \
         -html { wrap off }

    ossweb::widget form_notes.notes_cc -type email_lookup -label "Email To" \
         -email \
         -append \
         -optional \
         -autocomplete \
         -text \
         -size 30 \
         -labelhelp "Email address(es) which should<br>
                     receive notification on update"

    ossweb::widget form_notes.hours -type text -label "Hours Worked" \
         -optional \
         -size 5 \
         -datatype float \
         -labelhelp "Optional field to specify how many<br>
                     hours this particular task required<bR>
                     to complete, floating point is allowed"

    ossweb::widget form_notes.percent -type text -label "Percent Completed" \
         -optional \
         -size 5 \
         -datatype float \
         -labelhelp "What percentage of this task/problem<br>
                     is already completed"

    ossweb::widget form_notes.owner_flag -type checkbox -label "Assign to myself" \
         -value 1 \
         -labelhelp "Assign myself to this task/problem<br>
                     as responsible person/owner"

    ossweb::widget form_notes.html_flag -type checkbox -label "HTML mode" \
         -value 1 \
         -labelhelp "Check this if the text in Notes<br>
                     contains HTML tags that should not<br>
                     be rendered by the browser"

    ossweb::widget form_notes.quiet_flag -type checkbox -label "Quiet mode" \
         -value 1 \
         -labelhelp "Check this if Email notifications<br>
                     are not required after new followup<br>
                     will be added, otherwise assigned<br>
                     person will receive email with this Notes"

    ossweb::widget form_notes.email_flag -type checkbox -label "Notify all" \
         -value 1 \
         -labelhelp "Check this if Email notifications<br>
                     should be sent to everybody included<br>
                     in the project"

    ossweb::widget form_notes.cal_date -type date -label "Reopen/Remind Date" \
         -calendar \
         -optional \
         -format TEXT \
         -labelhelp "Schedule date when this Task/Problem<br>
                     should be reopened/reminded about automatically,<br>
                     if Repeat is set, it will do it every period until<br>
                     canceled, to clear the date, choose Unset. If it's <br>
                     already open at that time, just email will be sent"

    ossweb::widget form_notes.cal_repeat -type select -label "Repeat" \
         -optional \
         -html { style "font-size:7pt;border:1px dotted black;" } \
         -options { { "Dont Repeat" None }
                    { "Unset Date" Unset }
                    { Daily Daily }
                    { Weekly Weekly }
                    { Monthly Monthly }
                    { Yearly Yearly } }

    ossweb::widget form_notes.upload -type file -label "Attach File" \
         -optional \
         -data [ossweb::html::link -image add3.gif -width "" -height "" -title "Add file" -url "javascript:addFile()"] \
         -labelhelp "Upload file which will be<br>
                     associated with this task/problem"

    ossweb::widget form_notes.upload1 -type file -label "Attach File" \
         -optional \
         -class:data hidden \
         -data [ossweb::html::link -image cancel.gif -title "Remove file" -url "javascript:varStyle('upload1_div','display','none')"] \
         -labelhelp "Upload file which will be<br>
                     associated with this task/problem"

    ossweb::widget form_notes.upload2 -type file -label "Attach File" \
         -optional \
         -class:data hidden \
         -data [ossweb::html::link -image cancel.gif -title "Remove file" -url "javascript:varStyle('upload2_div','display','none')"] \
         -labelhelp "Upload file which will be<br>
                     associated with this task/problem"

    ossweb::widget form_notes.upload3 -type file -label "Attach File" \
         -optional \
         -class:data hidden \
         -data [ossweb::html::link -image cancel.gif -title "Remove file" -url "javascript:varStyle('upload3_div','display','none')"] \
         -labelhelp "Upload file which will be<br>
                     associated with this task/problem"

    ossweb::widget form_notes.upload4 -type file -label "Attach File" \
         -optional \
         -class:data hidden \
         -data [ossweb::html::link -image cancel.gif -title "Remove file" -url "javascript:varStyle('upload4_div','display','none')"] \
         -labelhelp "Upload file which will be<br>
                     associated with this task/problem"

    ossweb::widget form_notes.update -type submit -label Add \
         -help "Add notes, update status"

    ossweb::widget form_notes.exit -type submit -label "Add & Exit" \
         -help "Add notes, update status and exit to main list"

    ossweb::widget form_notes.noteCancel -type button -label "Cancel" \
         -url "javascript:notesForm(1)" \
         -css { display none }

}

ossweb::conn::callback create_form_search {} {

    set users [ossweb::db::multilist sql:problem.user.select.allowed]

    ossweb::widget form_search.problem_id -type text -label "ID" \
         -optional \
         -datatype integer \
         -size 10

    ossweb::widget form_search.title -type text -label "Title" \
         -optional \
         -size 30

    ossweb::widget form_search.description -type text -label "Description" \
         -optional \
         -size 30

    ossweb::widget form_search.problem_tags -type text -label "Tags" \
         -optional \
         -size 30

    ossweb::widget form_search.user_id -type select -label "Submitted By" \
         -empty "--" \
         -optional \
         -options [ossweb::db::multilist sql:problem.user.select.read]

    ossweb::widget form_search.owner_id -type multiselect -label "Assigned To" \
         -optional \
         -size 3 \
         -empty "--" \
         -options [linsert $users 0 { Nobody -1 }]

    ossweb::widget form_search.belong_id -type multiselect -label "Belong To" \
         -optional \
         -size 3 \
         -empty "--" \
         -options $users

    ossweb::widget form_search.project_id -type multiselect -label "Project" \
         -optional \
         -size 8 \
         -empty " --" \
         -options [ossweb::db::multilist sql:problem.project.select.read]

    ossweb::widget form_search.problem_status -type multiselect -label "Status" \
         -optional \
         -size 3 \
         -empty "--" \
         -options [ossweb::db::multilist sql:problem.status.select.read]

    ossweb::widget form_search.problem_type -type multiselect -label "Type" \
         -optional \
         -size 3 \
         -empty "--" \
         -options [ossweb::db::multilist sql:problem.type.select.read -cache PROBLEM:TYPES]

    ossweb::widget form_search.priority -type select -datatype name -label "Priority" \
         -optional \
         -empty -- \
         -sql_table problem_priorities \
         -sql_columns priority_name,priority_id \
         -sql_sort 2

    ossweb::widget form_search.severity -type select -datatype name -label "Severity" \
         -optional \
         -empty -- \
         -sql_table problem_severities \
         -sql_columns severity_name,severity_id \
         -sql_sort 2

    ossweb::widget form_search.create_date -type date -label "Create Date" \
         -format "DR MON YYYY" \
         -optional \
         -range \
         -calendar

    ossweb::widget form_search.due_date -type date -label "Due Date" \
         -format "DR MON YYYY" \
         -optional \
         -range \
         -calendar

    ossweb::widget form_search.unassigned_flag -type checkbox -label "Show my or unassigned tasks only" \
         -optional \
         -value t

    ossweb::widget form_search.projectgroup_flag -type checkbox -label "Group by project" \
         -optional \
         -value t

    ossweb::widget form_search.cmd -type hidden -value search -freeze

    ossweb::widget form_search.reset -type reset -label Reset -clear

    ossweb::widget form_search.search -type submit -label Search

    ossweb::widget form_search.tree -type button -label Tree \
         -html { title "Show tasks in hierachical view" } \
         -url [ossweb::html::url cmd tree]

    ossweb::widget form_search.list -type submit -label List \
         -html { title "Show as one plain list" } \

    ossweb::widget form_search.add -type button -label New \
         -html { title "Create new task/problem" } \
         -url [ossweb::html::url cmd edit]

    ossweb::widget form_search.favorites -type button -label Favorites \
         -window Favorites \
         -winopts $winopts \
         -html { title "Favorite filter selections" } \
         -url [ossweb::html::url cmd favorites]

    ossweb::widget form_search.tracker -type button -label Tracker \
         -window Tracker \
         -winopts $winopts \
         -html { title "Show last changes/updates" } \
         -url [ossweb::html::url -lookup t main.tracker tab problem]

    ossweb::widget form_search.close -type button -label Close \
         -cmd_name close \
         -html { title "Close all selected tasks" } \
         -confirm "confirm('All problems satisfied current filter criteria will be closed, continue?')"

    if { [ossweb::config problem:svn:path] != "" } {
      ossweb::widget form_search.svnTree -type button -label SVN \
           -help "Add file revision reference from SVN" \
           -url [ossweb::html::url -lookup t cmd svn.tree std 1] \
           -window SVN \
           -winopts $winopts
    }
}

ossweb::conn::callback create_form_psort {} {

    ossweb::widget form_psort.project_name -type sorting -label Project \
         -html { TITLE "Sort by Project" } \
         -map problem_sort

    ossweb::widget form_psort.title -type sorting -label Title \
         -html { TITLE "Sort by Title" } \
         -map problem_sort

    ossweb::widget form_psort.type_name -type sorting -label Type \
         -html { TITLE "Sort by Type" } \
         -map problem_sort

    ossweb::widget form_psort.status_name -type sorting -label Status \
         -html { TITLE "Sort by Status" } \
         -map problem_sort

    ossweb::widget form_psort.priority -type sorting -label Priority \
         -html { TITLE "Sort by Priority" } \
         -map problem_sort

    ossweb::widget form_psort.severity -type sorting -label Severity \
         -html { TITLE "Sort by Severity" } \
         -map problem_sort

    ossweb::widget form_psort.due_date -type sorting -label Due \
         -html { TITLE "Sort by Due Date" } \
         -map problem_sort

    ossweb::widget form_psort.last_name -type sorting -label Submitted \
         -html { TITLE "Sort by Person Submitted" } \
         -map { problem_sort u.last_name }

    ossweb::widget form_psort.update_date -type sorting -label Updated \
         -html { TITLE "Sort by Update Date" } \
         -map { problem_sort p.update_date }

    ossweb::widget form_psort.create_date -type sorting -label Created \
         -html { TITLE "Sort by Create Date" } \
         -map { problem_sort p.create_date }

}

ossweb::conn::callback create_form_nsort {} {

    set url [ossweb::html::url cmd edit.sort problem_id $problem_id]
    ossweb::widget form_nsort.created -type sorting -label Created \
         -html { TITLE "Sort by Create Date" } \
         -map { problem_note_sort b.create_date } \
         -url $url \
         -default

    ossweb::widget form_nsort.submitted -type sorting -label Submitted \
         -html { TITLE "Sort by Person Submitted" } \
         -map { problem_note_sort "u.first_name||' '||u.last_name" } \
         -url $url

    ossweb::widget form_nsort.status_name -type sorting -label Status \
         -html { TITLE "Sort by Status" } \
         -map problem_note_sort \
         -url $url

    ossweb::widget form_nsort.hours -type sorting -label Hrs \
         -html { TITLE "Sort by Hours" } \
         -map { problem_note_sort b.hours } \
         -url $url
}

# Columns for problem table
set columns { problem_id ilist ""
              user_id ilist ""
              owner_id ilist ""
              belong_id ilist ""
              project_id ilist ""
              problem_type list ""
              problem_status list ""
              problem_cc "" ""
              problem_tags "" ""
              problem_link const ""
              problem_status_name const ""
              problem_note_id ilist ""
              priority "" ""
              severity "" ""
              notes_cc "" ""
              hours_worked const 0
              create_date date ""
              due_date date ""
              cal_date "" ""
              title text ""
              description "" ""
              close_on_complete "" ""
              alert_on_complete "" ""
              html_flag "" ""
              email_flag "" ""
              quiet_flag "" ""
              owner_flag "" ""
              projectgroup_flag "" ""
              unassigned_flag "" ""
              sort "" ""
              desc "" ""
              page "" 1
              pagesize "" {[ossweb::conn problem_pagesize 30]}
              force "" f
              app_name "" ""
              tree_items const ""
              tree_id const 0
              tree_idx const -1
              tree_open "" ""
              descr_height const 100
              files_height const 20
              winopts const "width=900,height=600,menubar=0,location=0,scrollbars=1"
              tinyMCE const {[ossweb::conn problem_richtext 1]} }

# Columns for problem notes table
set columns_notes { problem_id int ""
                    user_id int ""
                    problem_status "" ""
                    description "" ""
                    owner_id int "" }

ossweb::conn::process \
             -columns $columns \
             -forms { form_problem form_notes } \
             -form_recreate t \
             -on_error { index.index } \
             -exec { problem_init } \
             -eval {
               delete.file -
               upload {
                 -validate { { problem_id int "" } }
                 -exec { file_action }
                 -next { -cmd_name edit }
                 -on_error { -cmd_name edit }
               }
               info {
                 -validate { { problem_id int "" } }
                 -exec { info_action }
                 -on_error { -cmd_name error }
               }
               file {
                 -validate { { problem_id int "" } }
                 -exec { file_action }
                 -on_error { -cmd_name error }
               }
               add -
               update {
                 -exec { problem_action }
                 -next { -cmd_name edit }
                 -on_error { -cmd_name edit }
               }
               delete {
                 -exec { problem_action }
                 -next { -cmd_name view }
                 -on_error { -cmd_name edit }
               }
               delete.note -
               update.note {
                 -validate { { problem_id int "" } }
                 -exec { note_action }
                 -next { -cmd_name edit }
                 -on_error { -cmd_name edit }
               }
               close {
                 -exec { problem_action }
                 -next { -cmd_name search }
                 -on_error { -cmd_name view }
               }
               edit {
                 -forms { form_problem form_notes form_nsort }
                 -exec { problem_edit }
                 -on_error { -cmd_name view }
               }
               favorites {
                 -exec { problem_favorites }
                 -on_error { -cmd_name error }
               }
               svn {
                 -exec { svn_action }
                 -on_error { -cmd_name error }
               }
               tree {
                 -exec { problem_tree }
                 -on_error { -cmd_name error }
               }
               error {
               }
               default {
                 -forms { form_psort form_search }
                 -exec { problem_list }
                 -on_error_set_cmd ""
                 -on_error { -cmd_name view }
               }
             }

