# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback user_message {} {

  switch -exact ${ossweb:ctx} {
   send {
     if { [set text [ns_queryget text]] == "" } { return }
     switch -- [set type [ns_queryget type]] {
      popup {
        if { [set sound [ns_queryget sound]] != "" } {
          append text "@sound:[lindex [split $sound .] 0]@"
        }
        ossweb::admin::send_popup -user_id $user_id $text
        ossweb::widget form_message.text -value ""
      }

      email {
        set user_old $user_id
        set status active
        set from [ossweb::conn user_email]
        set subject "Message from [ossweb::conn full_name]"
        foreach user_id [ossweb::db::multilist sql:ossweb.user.search1] {
          set email [ossweb::db::value sql:ossweb.user.read_email]
          if { $email == "" } { continue }
          ossweb::sendmail $email $from $subject $text
        }
        set user_id $user_old
      }
     }
     ns_log Notice user [ossweb::conn user_id] sent $type message to $user_id
     ossweb::adp::Exit ""
   }
  }
}

# Perform action with user
ossweb::conn::callback user_action {} {

  if { $user_id == "" && ${ossweb:cmd} != "update" } {
    error "User with id $user_id not found"
    return
  }

  switch -exact ${ossweb:cmd} {
   save {
     # Extended preferences update
     ossweb::control::user save $user_id
     ossweb::conn::set_msg "Preferences updated"
   }

   update {
     # Zero user id means creating new user
     if { $user_id == "" } {
       set user_id [ossweb::admin::create_user \
                         -groups $groups \
                         user_name $user_name \
                         first_name $first_name \
                         last_name $last_name \
                         user_email $user_email \
                         status $status \
                         password $password \
                         user_type $user_type \
                         start_page $start_page \
                         update_time NOW()]
      if { $user_id == "" } {
        set user_id ""
        error "OSS:Unable to create user"
      }
      ossweb::conn::set_msg "User Details Updated"

     } else {
      if { [ossweb::admin::update_user \
                 -user_id $user_id \
                 -groups $groups \
                 -flush t \
                 user_name $user_name \
                 first_name $first_name \
                 last_name $last_name \
                 user_email $user_email \
                 password $password \
                 status $status \
                 user_type $user_type \
                 start_page [ossweb::nvl $start_page Null] \
                 update_time NOW()] } {
        error "OSS:Unable to update user"
      }
      ossweb::conn::set_msg "User Details Updated"
     }
   }

   delete {
     if { $user_id == [ossweb::conn user_id] } {
       error "OSS:Could not delete itself"
     }
     if { [ossweb::admin::delete_user $user_id] } {
       error "OSS:Unable to delete user"
     }
     set user_id ""
     ossweb::conn::set_msg "User $user_name deleted from the system"
   }

   refresh {
     ossweb::admin::flush_user $user_id
   }
  }
  ossweb::sql::multipage users -flush t
  ossweb::admin::flush_user $user_id
}

ossweb::conn::callback acl_action {} {

  # Process command
  switch -exact ${ossweb:cmd} {
   add {
     # Only admin is able to enable admin privileges for other users
     if { [ossweb::conn::check_acl -acl "*.*.*.*.*"] &&
          "$project_name$app_name$page_name$cmd_name$ctx_name" == "" } {
       error "OSS:ACL shouldn't be empty"
     }
     if { [ossweb::conn::create_acl $user_id \
                -obj_type U \
                -project_name $project_name \
                -app_name $app_name \
                -page_name $page_name \
                -cmd_name $cmd_name \
                -ctx_name $ctx_name \
                -query $query \
                -handlers $handlers \
                -precedence $precedence \
                -value $value] } {
       error "OSS:Unable to create ACL record"
     }
     ossweb::conn::set_msg "Access Permission Added"
   }

   remove {
     if { [ossweb::db::exec sql:ossweb.acls.delete] } {
       error "OSS:Unable to delete ACL record"
     }
     ossweb::conn::set_msg "Access Permission Removed"
   }
  }
}

# Edit screen with user details
ossweb::conn::callback user_edit {} {

    set ossweb:cmd edit

    if { $user_id == "" } { return }
    # Retrieve user details
    if { [ossweb::db::multivalue sql:ossweb.user.read] } {
      error "OSS:User with id $user_id not found"
    }
    set password ""
    # Take first and most recent session from the session list
    if { $user_sessions != "" } {
      set login_time [ns_fmttime [lindex $user_sessions 1] "%D %H:%M:%S"]
      set access_time [ns_fmttime [lindex $user_sessions 2] "%D %H:%M:%S"]
    }
    set ipaddr [lindex $user_sessions 3]
    set user_link [ossweb::lookup::link -text "<B>\[$user_id\]</B>" cmd edit user_id $user_id]
    ossweb::form form_user set_values

    ossweb::widget form_user.groups \
         -value [ossweb::db::list sql:ossweb.user.group.list] \
         -info "<DIV STYLE=\"width:230;font-size:9pt;text-align:left;\">
                Created: $create_time<BR>
                Login time: $login_time<BR>
                Access time: $access_time<BR>
                IP Address: $ipaddr</DIV>"

    # Customize user form
    if { $tab != "edit" } {
      ossweb::widget form_user.status -type none
      ossweb::widget form_user.groups -type none
      ossweb::widget form_user.first_name -type none
      ossweb::widget form_user.last_name -type none
      ossweb::widget form_user.user_name -value "$user_name ($first_name $last_name)"
      ossweb::form form_user readonly -skip_null t -skip {back|refresh}
    }

    switch -- $tab {
     acl {
       ossweb::form form_user_acls.user_id -value $user_id
       # Retreive all user access permissions
       ossweb::db::multirow acls sql:ossweb.acls.list -vars "obj_id $user_id" -eval {
         set row(action) "&nbsp;"
         set row(group) "&nbsp;"
         if { $row(obj_type) == "U" } {
           set row(action) [ossweb::lookup::link -image trash.gif -alt Remove cmd remove.acl user_id $user_id acl_id $row(acl_id)]
         } else {
           if { ![ossweb::lookup::mode] } {
             set row(group_name) [ossweb::html::link -text $row(group_name) groups cmd edit group_id $row(group_id)]
           }
         }
       }
     }

     default {
       # Store prefs as Tcl variables
       foreach { key val } [ossweb::admin::prefs list -obj_id $user_id] {
         set $key $val
       }
       ossweb::form form_prefs set_values
     }
    }
}

# Users list
ossweb::conn::callback user_list {} {

    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property USERS:FILTER "" -forms form_user -global t
     }

     error {
       ossweb::form form_user set_values
       return
     }

     ac {
       # Autocomplete search
       set data [list]
       set user_limit 10
       set ac:id [ns_queryget ac:id 1]
       set ac:email [ns_queryget ac:email 0]
       ossweb::db::foreach sql:ossweb.user.search {
         if { ${ac:email} == 1 } {
           set rec "name:'$first_name $last_name $user_email',value:'$user_email'"
         } else {
           set rec "name:'$first_name $last_name'"
           # ID is not disabled
           if { ${ac:id} != 0 } {
             lappend rec "value:$user_id"
           }
         }
         lappend data "{[join $rec ,]}"
       } -map { ' {} }
       ns_return 200 text/plain [join $data "\n"]
       # Stop template processing
       ossweb::adp::Exit
     }

     sort {
       # Change sorting order
       ossweb::conn::set_property USERS:SORTFILTER "" -columns { sort "" "" desc "" "" } -global t
     }
    }

    # Read current filter settings
    ossweb::conn::get_property USERS:FILTER -skip page -columns t -global t

    # Update sorting widgets and variables
    ossweb::conn::get_property USERS:SORTFILTER -columns t -global t
    ossweb::form form_sorting refresh_values

    # Update form with current values
    ossweb::form form_user set_values
    ossweb::db::multipage users \
         sql:ossweb.user.search1 \
         sql:ossweb.user.search2 \
         -query [ossweb::lookup::property query] \
         -force $force \
         -debug f \
         -page $page \
         -pagesize $pagesize \
         -eval {
      set row(full_name) "$row(first_name) $row(last_name)"
      set row(_full_name) $row(full_name)
      if { [ossweb::lookup::row full_name -id user_id] } {
        set row(full_name) [ossweb::lookup::link -text $row(full_name) cmd edit user_id $row(user_id) page $page]
      }
      set groups ""
      foreach { g1 g2 } $row(groups) { append groups $g1 " " $g2 "<BR>" }
      set row(groups) $groups
      # Custom row modifications
      ossweb::control::user row $row(user_id)
    }
}

ossweb::conn::callback user_init {} {

    set mode [ossweb::lookup::mode]
    set adpname [ossweb::conn page_name]
    set email_search [lindex [split $email_search ,] end]
}

# User ACL form
ossweb::conn::callback create_form_user_acls {} {

    ossweb::form form_user_acls

    ossweb::lookup::form form_user_acls

    ossweb::widget form_user_acls.user_id -type hidden -datatype integer

    ossweb::widget form_user_acls.cmd -type submit -label Add

    ossweb::widget form_user_acls.project_name -type text -optional \
         -datatype name -html { size 10 } -label "Project Name"

    ossweb::widget form_user_acls.app_name -type text -optional \
         -datatype name -html { size 10 } -label "App Name"

    ossweb::widget form_user_acls.page_name -type text -optional \
         -datatype text -html { size 10 } -label "App Context"

    ossweb::widget form_user_acls.cmd_name -type text -optional \
         -datatype name -html { size 10 } -label "Cmd Name"

    ossweb::widget form_user_acls.ctx_name -type text -optional \
         -datatype name -html { size 10 } -label "Cmd Context"

    ossweb::widget form_user_acls.query -type textarea -optional \
         -datatype text -html { wrap soft rows 2 cols 10 } -label "Query"

    ossweb::widget form_user_acls.handlers -type textarea -optional \
         -datatype text -html { wrap soft rows 2 cols 10 } -label "Handlers"

    ossweb::widget form_user_acls.value -type select \
         -datatype name -options { { Y Y } { N N } } -label "ACL Value"

    ossweb::widget form_user_acls.precedence -type numberselect \
         -optional \
         -empty -- \
         -end 1000
}

ossweb::conn::callback create_form_user {} {

    ossweb::form form_user
    ossweb::lookup::form form_user -select t

    switch ${ossweb:cmd} {
     add -
     edit -
     remove -
     refresh -
     delete -
     update {
        ossweb::widget form_user.page -type hidden -optional

        ossweb::widget form_user.user_id -type hidden -datatype integer -optional

        ossweb::widget form_user.user_type -type select -label "User Type" \
             -options [ossweb::db::multilist sql:ossweb.user_types.list]

        ossweb::widget form_user.user_name -type text -label "User Name"

        ossweb::widget form_user.status -type select -label "Status" \
             -optional \
             -options { { Active active } { Disabled disabled } {Onetime onetime} }

        ossweb::widget form_user.groups -type multiselect -label "Groups" \
             -size 6 \
             -optional \
             -options [ossweb::db::multilist sql:ossweb.group.select.read]

        ossweb::widget form_user.password -type password -label Password \
             -optional \
             -size 15

        ossweb::widget form_user.first_name -type text -label "First Name"

        ossweb::widget form_user.last_name -type text -label "Last Name"

        ossweb::widget form_user.user_email -type text -datatype email -label "Email"

        ossweb::widget form_user.start_page -type text -label "Start Page" -optional

        ossweb::widget form_user.back -type button -label Back \
             -url [ossweb::lookup::url cmd view page $page]

        ossweb::widget form_user.refresh -type button -label Refresh \
             -url [ossweb::lookup::url cmd refresh user_id $user_id page $page]

        ossweb::widget form_user.update -type submit -name cmd -label Update

        ossweb::widget form_user.delete -type button -label Delete \
             -condition "@user_id@ gt 0" \
             -confirm "confirm('Record will be deleted, continue?')" \
             -url [ossweb::html::url cmd delete user_id $user_id page $page]

        ossweb::widget form_user.copy -type button -label Copy \
             -condition "@user_id@ gt 0" \
             -confirm "confirm('Record will be copied, continue?')" \
             -url [ossweb::html::url cmd copy user_id $user_id page $page]

        ossweb::widget form_user.message -type button -label Message \
             -popup t \
             -popupdnd \
             -popuptop 100 \
             -popupleft 100 \
             -popupwidth 50% \
             -popupbgcolor #EEEEEE \
             -url [ossweb::lookup::url -lookup t cmd message user_id $user_id page $page]
     }

     default {
        ossweb::lookup::form form_user

        ossweb::widget form_user.cmd -type hidden -value search -freeze

        ossweb::widget form_user.sort -type hidden -optional

        ossweb::widget form_user.user_id -type text -label "User ID" \
             -size 5 \
             -datatype int \
             -optional

        ossweb::widget form_user.user_name -type text -label "User Name" \
             -html { size 15 } \
             -optional

        ossweb::widget form_user.user_type -type multiselect -label "User Type" \
             -html { size 4 } \
             -optional \
             -options [ossweb::db::multilist sql:ossweb.user_types.list]

        ossweb::widget form_user.groups -type multiselect -label "Groups" \
             -html { size 4 } \
             -optional \
             -options [ossweb::db::multilist sql:ossweb.group.select.read]

        ossweb::widget form_user.status -type multiselect -label "Status" \
             -html { size 3 } \
             -optional \
             -options { { Active active } { Disabled disabled } }

        ossweb::widget form_user.first_name -type text -label "First Name" \
             -html { size 15 } \
             -optional

        ossweb::widget form_user.last_name -type text -label "Last Name" \
             -html { size 15 } \
             -optional

        ossweb::widget form_user.user_email -type text -label "Email" \
             -html { size 12 } \
             -optional

        ossweb::widget form_user.search -type submit -label Search

        ossweb::widget form_user.reset -type reset -label Reset -clear

        ossweb::widget form_user.add -type button -label New \
             -url [ossweb::lookup::url cmd edit page $page]

        ossweb::widget form_user.message -type button -label Message \
             -url [ossweb::lookup::url cmd message page $page]
     }
    }
}

ossweb::conn::callback create_form_message {} {

    set to "All Active Users"
    if { $user_id != "" } {
      set to [ossweb::db::value sql:ossweb.user.read_name]
    }

    ossweb::form form_message -title "Send a Message" -tracking 0

    ossweb::widget form_message.to -type inform -label To -value $to

    ossweb::widget form_message.type -type select -label Type \
         -options { {Popup popup} {Email email} }

    ossweb::widget form_message.toolbar -type inform -label "&nbsp;" -value "
         <TABLE ID=toolbar BORDER=1 CELLSPACING=0 CELLPADDING=2><TR>
         <TD TITLE=Bold onClick=\"document.form_message.text.value+='<B> </B>'\"><B>B</B></A></TD>
         <TD TITLE=Italic onClick=\"document.form_message.text.value+='<I> </I>'\"><B>I</B></A></TD>
         <TD TITLE=Underscore onClick=\"document.form_message.text.value+='<U> </U>'\"><B>U</B></A></TD>
         <TD TITLE=Colors onClick=\"window.open('[ossweb::html::url -app_name main colors element form_message.text format "<FONT COLOR=%s> </FONT>"]','IconSelect','alwaysRaised=yes,resizable=no,height=210,width=310,top=400,left=400,screenX=400,screenY=400,dependent=true')\"><IMG SRC=/img/color.gif></A></TD>
         <TD TITLE=Smilies onClick=\"window.open('[ossweb::html::url -app_name main smiles element form_message.text]','IconSelect','alwaysRaised=yes,resizable=no,height=210,width=400,top=400,left=400,screenX=400,screenY=400,dependent=true')\"><IMG SRC=/img/smilies/happy.png></A></TD>
         <TD TITLE=Image onClick=\"document.form_message.text.value+='<IMG SRC= >'\"><IMG SRC=/img/chart.gif></A></TD>
         </TR></TABLE>"

    ossweb::widget form_message.text -type textarea -label Text \
         -html { cols 60 rows 10 }

    ossweb::widget form_message.sound -type soundselect -label "Add Sound" \
         -optional

    ossweb::widget form_message.back -type button -label Close \
         -popupcloseobj

    ossweb::widget form_message.send -type button -label Send \
         -url [ossweb::html::url cmd message.send user_id $user_id] \
         -popup \
         -popupform \
         -onClick:after "formClear(this.form);"
}

ossweb::conn::callback create_form_prefs {} {

    ossweb::form form_prefs -cmd save

    ossweb::widget form_prefs.tab -type hidden -value $tab -freeze

    ossweb::widget form_prefs.user_id -type hidden -value $user_id -freeze

    ossweb::control::user form $user_id

    ossweb::widget form_prefs.save -type submit -label Save
}

ossweb::conn::callback create_form_sorting {} {

    ossweb::widget form_sorting.user_type -type sorting -label Type \
         -html { TITLE "Sort by type" } \
         -map user_sort

    ossweb::widget form_sorting.user_name -type sorting -label Login \
         -html { TITLE "Sort by name" } \
         -map user_sort

    ossweb::widget form_sorting.full_name -type sorting -label Name \
         -html { TITLE "Sort by full name" } \
         -map { user_sort first_name||last_name }

    ossweb::widget form_sorting.user_email -type sorting -label Email \
         -html { TITLE "Sort by email" } \
         -map user_sort

    ossweb::widget form_sorting.access_time -type sorting -label "Last Access" \
         -html { TITLE "Sort by access time" } \
         -map { user_sort COALESCE(ossweb_user_access_time(user_id),'2000-1-1') }
}

ossweb::conn::callback create_form_tab {} {

    set url [ossweb::lookup::url cmd edit user_id $user_id page $page]

    ossweb::widget form_tab.edit -type link -label Edit -value $url

    ossweb::widget form_tab.acl -type link -label Access -value $url

    ossweb::control::user tab $user_id $url
}

# table/form columns
set columns { user_id int ""
              status list active
              user_type list employee
              user_name "" ""
              email_search "" ""
              first_name "" ""
              last_name "" ""
              full_name "" ""
              user_email "" ""
              create_time DateTime ""
              login_time DateTime ""
              access_time DateTime ""
              start_page "" ""
              department "" ""
              group_id int ""
              groups ilist ""
              groupnames list ""
              project_name var ""
              app_name var ""
              page_name var ""
              cmd_name var ""
              ctx_name var ""
              query var ""
              handlers var ""
              acl_id var ""
              user_link var ""
              precedence int ""
              tab "" edit
              sort "" ""
              desc "" ""
              page "" 1
              pagesize int 30
              force "" f }

# Process request parameters
ossweb::conn::process -columns $columns \
           -on_error { -cmd_name view } \
           -forms { form_user form_tab form_sorting } \
           -form_recreate t \
           -form_tracking t \
           -exec { user_init } \
           -eval {
            copy {
              -forms { form_user form_user_acls }
              -exec { user_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            delete {
              -forms { form_user form_user_acls }
              -exec { user_action }
              -next { -cmd_name view }
              -on_error { -cmd_name edit }
            }
            save -
            refresh -
            update {
              -forms { form_user form_user_acls }
              -exec { user_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            add -
            remove {
              -forms { form_user form_user_acls }
              -exec { acl_action }
              -next { -cmd_name edit tab acl }
              -on_error { -cmd_name edit tab acl }
            }
            add.group -
            delete.group {
              -forms { form_user }
              -exec { group_action }
              -next { -cmd_name edit tab group }
              -on_error { -cmd_name edit tab group }
            }
            lookup {
              -exec { ossweb::lookup::exec -sql sql:ossweb.user.read }
            }
            edit {
              -forms { form_user form_tab form_user_acls form_prefs } \
              -exec { user_edit }
            }
            calendar {
              -exec { user_calendar }
            }
            message {
              -forms { form_message form_tab }
              -exec { user_message }
            }
            default {
              -exec { user_list }
              -on_error { -cmd_name error }
            }
           }
