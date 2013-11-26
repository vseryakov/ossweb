# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2003

ossweb::conn::callback senders_action {} {

    switch -- ${ossweb:cmd} {
     add {
        switch -- $tab {
         white { set sender_type PASS }
         black { set sender_type DROP }
         gray { set sender_type VRFY }
         default { return }
        }
        if { [set sender_email [string trim $sender_email]] == "" } {
          error "OSSWEB:Invalid email address"
        }
        if { [ossweb::db::value sql:maverix.sender.check.email] != "" } {
          ossweb::conn::set_msg -color red "Sender $sender_email already exists"
          return
        }
        # Treat as domain if not valid email address
        set sender_email [string trim $sender_email *@]
        if { [string first @ $sender_email] == -1 } { set sender_email @$sender_email }
        if { [ossweb::db::exec sql:maverix.sender.create] } {
          error "OSSWEB:Unable to add sender $sender_email"
        }
        maverix::cache::sender_set $user_email $sender_email $sender_type
        ossweb::conn::set_msg "Sender $sender_email has been added"
     }
     
     delete {
        if { [ossweb::db::exec sql:maverix.sender.delete] } {
          error "OSSWEB:Unable to delete sender $sender_email "
        }
        maverix::cache::sender_flush $user_email $sender_email
        ossweb::conn::set_msg "Sender $sender_email has been deleted"
     }
     
     clear {
        switch -- $tab {
         white { set sender_type PASS }
         black { set sender_type DROP }
         gray { set sender_type VRFY }
         default { return }
        }
        if { [ossweb::db::exec sql:maverix.sender.delete.by.user] } {
          ossweb::conn::set_msg -color red "Unable to delete senders"
          return
        }
        maverix::cache::sender_flush $user_email $sender_type
        ossweb::conn::set_msg "Senders have been deleted"
     }
     
     pend -
     block -
     permit {
        switch -- ${ossweb:cmd} {
         permit { set sender_type PASS }
         block { set sender_type DROP }
         pend { set sender_type VRFY }
         default { return }
        }
        if { [ossweb::db::exec sql:maverix.sender.update.type] } {
          error "OSSWEB:Unable to update sender $sender_email "
        }
        maverix::cache::sender_set $user_email $sender_email $sender_type
        ossweb::conn::set_msg "Sender $sender_email has been updated"
     }
    }
    ns_log Notice admin:sender: ${ossweb:cmd}: u=$user_email, s=$sender_email, $tab
    # Flush cached search results
    ossweb::sql::multipage senders -flush t
}

ossweb::conn::callback aliases_action {} {

    switch -exact ${ossweb:cmd} {
     add {
       if { [ossweb::db::exec sql:maverix.user.alias.create] } {
         error "OSSWEB: Unable to update message record"
       }
       ossweb::conn::set_msg "Alias has been added"
     }
     
     delete {
       if { [ossweb::db::exec sql:maverix.user.alias.delete] } {
         error "OSSWEB: Unable to delete alias record"
       }
       ossweb::conn::set_msg "Alias record has been deleted"
     }
    }
    # Flush caches
    maverix::cache::user_flush $user_email
}

ossweb::conn::callback messages_action {} {

    switch -exact ${ossweb:cmd} {
     update {
       if { [ossweb::db::exec sql:maverix.user.message.update] } {
         error "OSSWEB: Unable to update the message"
       }
       ossweb::conn::set_msg "Message has been updated"
       set msg_id ""
     }
     
     forward {
       set msg_status PASS
       set deliver_count 0
       foreach msg_id $msg_id {
         if { [ossweb::db::exec sql:maverix.user.message.update.status] } {
           error "OSSWEB: Unable to forward the message"
         }
       }
       ossweb::conn::set_msg "Message has been forwarded"
       set msg_id ""
     }
     
     spam {
       ns_schedule_proc -once 0 "maverix::trainSpam $user_email {$msg_id} 1"
       set msg_status DROP
       foreach msg_id $msg_id {
         if { [ossweb::db::exec sql:maverix.user.message.update.status] } {
           error "OSSWEB: Unable to delete the message"
         }
       }
       ossweb::conn::set_msg "Message has been marked as SPAM"
       set msg_id ""
     }

     delete {
       foreach msg_id $msg_id {
         if { [ossweb::db::exec sql:maverix.user.message.delete] } {
           error "OSSWEB: Unable to delete the message"
         }
       }
       ossweb::conn::set_msg "Message has been deleted"
       set msg_id ""
     }
    }
    # Flush cached search results
    ossweb::sql::multipage messages -flush t
}

ossweb::conn::callback users_action {} {

    ns_log Notice admin:user: ${ossweb:cmd}: u=$user_email, $user_type
    
    switch -exact ${ossweb:cmd} {
     digest {
       if { [maverix::schedule::digest $user_email] > 0 } {
         ossweb::conn::set_msg "Digest has been sent"
       } else {
         ossweb::conn::set_msg "There is nothing to be sent"
       }
     }
     
     update {
       if { $digest_date != "" } { 
         set digest_date [ossweb::date -set "" clock $digest_date] 
         set digest_count 0
       }
       if { [ossweb::db::exec sql:maverix.user.update.prefs] } {
         error "OSSWEB: Unable to update user record"
       }
       if { [ossweb::db::rowcount] == 0 } {
         if { [ossweb::db::exec sql:maverix.user.create] } {
           error "OSSWEB: Unable to create user record"
         }
       }
       ossweb::conn::set_msg "User record has been updated"
     }

     delete {
       ossweb::db::begin
       if { [ossweb::db::exec sql:maverix.user.delete] } {
         error "OSSWEB: Unable to delete user record"
       }
       ossweb::db::commit
       ossweb::conn::set_msg "User record has been deleted"
     }
    }
    # Flush caches
    maverix::cache::user_flush $user_email
    ossweb::sql::multipage users -flush t
}

ossweb::conn::callback users_edit {} {
 
    if { $user_email == "" } { return }
    if { [ossweb::db::multivalue sql:maverix.user.read] } {
      error "OSSWEB: Record not found"
    }
    append digest_id " ($digest_update, $digest_count) "
    ossweb::form form_user set_values
    switch -- $tab {
     aliases {
       ossweb::form form_user readonly -skip_null t
       ossweb::widget form_user.update -type none
       ossweb::widget form_alias.user_email -type hidden -value $user_email
       ossweb::widget form_alias.cmd -type hidden -value add.alias -freeze
       ossweb::widget form_alias.alias_email -type text -value "" -freeze
       ossweb::widget form_alias.add -type submit -label Add
       ossweb::db::multirow aliases sql:maverix.user.alias.list -eval {
         set row(delete) [ossweb::html::link -image trash.gif cmd delete.alias user_email $user_email alias_email $row(alias_email)]
       }
     }
     
     white -
     black -
     gray {
       switch -- $tab {
        white { set sender_type PASS }
        black { set sender_type DROP }
        gray { set sender_type VRFY }
       }
       ossweb::widget form_sender.cmd -type hidden -value edit.search -freeze
       ossweb::widget form_sender.tab -type hidden -value $tab -freeze
       ossweb::widget form_sender.user_email -type hidden -value $user_email -freeze
       ossweb::widget form_sender.sort -type hidden -value $sort -freeze
       ossweb::widget form_sender.page -type hidden -value $page -freeze
       ossweb::widget form_sender.sender_email -type text -label Email -optional
       ossweb::widget form_sender.add -type button -cmd_name add.sender -label Add
       ossweb::widget form_sender.search -type button -cmd_name edit.search -label Search
       ossweb::form form_user readonly -skip_null t
       ossweb::widget form_user.update -type none
       if { ${ossweb:ctx} != "search" } { set sender_email "" }
       ossweb::db::multipage senders \
            sql:maverix.user.sender.search1 \
            sql:maverix.user.sender.search2 \
            -page $page \
            -force $force \
            -datatype str \
            -query "tab=$tab&user_email=$user_email&sort=$sort" \
            -cmd_name edit \
            -eval {
         set row(url) [ossweb::html::url Senders cmd edit sender_email $row(sender_email) user_email $user_email]
         set row(edit) ""
         switch -- $tab {
          white {
            append row(edit) "<A HREF=[ossweb::html::url cmd block.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:blue\">Block</A>" "&nbsp;"
            append row(edit) "<A HREF=[ossweb::html::url cmd pend.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:black\">Pend</A>" "&nbsp;"
            append row(edit) "<A HREF=[ossweb::html::url cmd delete.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:red\">Delete</A>"
          }
          black {
            append row(edit) "<A HREF=[ossweb::html::url cmd permit.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:green\">Permit</A>" "&nbsp;"
            append row(edit) "<A HREF=[ossweb::html::url cmd pend.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:black\">Pend</A>" "&nbsp;"
            append row(edit) "<A HREF=[ossweb::html::url cmd delete.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:red\">Delete</A>"
          }
          gray {
            append row(edit) "<A HREF=[ossweb::html::url cmd permit.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:green\">Permit</A>" "&nbsp;"
            append row(edit) "<A HREF=[ossweb::html::url cmd block.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:blue\">Block</A>" "&nbsp;"
            append row(edit) "<A HREF=[ossweb::html::url cmd delete.sender user_email $user_email sender_email $row(sender_email) tab $tab sort $sort page $page] STYLE=\"color:red\">Delete</A>"
          }
         }
       }
     }
     
     log {
       ossweb::form form_user readonly -skip_null t
       ossweb::db::multirow log sql:maverix.sender.log.list -eval {
         set row(subject) [maverix::decodeHdr $row(subject)]
       }
     }
     
     messages {
       set msg_list ""
       ossweb::form form_user readonly -skip_null t
       ossweb::widget form_user.update -type none
       ossweb::widget form_user.refresh -type button -label Refresh \
            -url [ossweb::html::url cmd edit.refresh tab $tab user_email $user_email] 
       if { $msg_id != "" } {
         if { ![ossweb::db::multivalue sql:maverix.user.message.read] } {
           append spam_status /$spam_score
           set subject [maverix::decodeHdr $subject]
           set body [string range $body $body_offset end]
           set body "<PRE>[ossweb::util::wrap_text [ns_quotehtml $body]]</PRE>"
         }
         ossweb::form form_msg set_values
       }
       if { ${ossweb:ctx} == "refresh" } { set force t }
       ossweb::db::multipage messages \
            sql:maverix.user.message.search1 \
            sql:maverix.user.message.search2 \
            -page $page \
            -force $force \
            -query "tab=$tab&user_email=$user_email" \
            -cmd_name edit \
            -eval {
         lappend msg_list $row(msg_id)
         set row(subject) [maverix::decodeHdr $row(subject)]
         set row(body) [string range $row(body) $row(body_offset) end]
         set row(url) [ossweb::html::url cmd edit msg_id $row(msg_id) user_email $user_email tab messages page $page]
         set row(forward) [ossweb::html::url cmd forward.msg msg_id $row(msg_id) user_email $user_email tab messages page $page]
         set row(drop) [ossweb::html::url cmd delete.msg msg_id $row(msg_id) user_email $user_email tab messages page $page]
         set row(spam) [ossweb::html::url cmd spam.msg msg_id $row(msg_id) user_email $user_email tab messages page $page]
       }
     }
    }
}

ossweb::conn::callback users_list {} {
    
    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property USER:FILTER "" -forms form_user -global t -cache t
     }
     page {
       ossweb::conn::get_property USER:FILTER -skip page -columns t -global t -cache t
     }
     default {
       set users:rowcount 0
       return
     }
    }
    ossweb::form form_user set_values
    ossweb::db::multipage users \
         sql:maverix.user.search1 \
         sql:maverix.user.search2 \
         -cmd_name page \
         -datatype str \
         -page $page \
         -force $force \
         -eval {
      set row(url) [ossweb::html::url cmd edit user_email $row(user_email)]
      append row(digest_date) " ($row(digest_update))"
    }
}

ossweb::conn::callback create_form_user {} {
    
    ossweb::form form_user -title "User Details \[$user_email\]"

    switch ${ossweb:cmd} {
     edit -
     update -
     delete {
       ossweb::widget form_user.ctx -type hidden -value user -freeze
       ossweb::widget form_user.user_email -type text -label "Email" \
            -datatype email
       ossweb::widget form_user.user_type -type radio -label "Type" \
            -options { { VRFY VRFY } { PASS PASS } { DROP DROP } } \
            -labelselect \
            -horizontal
       ossweb::widget form_user.digest_id -type label -label "Digest" -nohidden \
            -info [ossweb::html::link -text "Resend Digest" cmd digest.user user_email $user_email]
       ossweb::widget form_user.digest_email -type text -label "Digest Email" \
            -datatype email \
            -optional
       ossweb::widget form_user.digest_start -type date -label "Digest Start Time" \
            -optional \
            -format "HH24 : MI" \
            -html { size 8 }
       ossweb::widget form_user.digest_end -type date -label "Digest End Time" \
            -optional \
            -format "HH24 : MI" \
            -html { size 8 }
       ossweb::widget form_user.body_size -type text -label "Digest Message Size" \
            -optional \
            -datatype integer \
            -html { size 5 }
       ossweb::widget form_user.page_size -type text -label "Digest Page Size" \
            -optional \
            -datatype integer \
            -html { size 5 }
       ossweb::widget form_user.digest_interval -type text -label "Digest Interval(secs)" \
            -optional \
            -datatype integer \
            -html { size 5 }
       ossweb::widget form_user.sender_digest_flag -type radio -label "Sender Self Verification" \
            -optional \
            -horizontal \
            -options { { Enabled t } { Disabled f } }
       ossweb::widget form_user.anti_virus_flag -type select -label "Anti-Virus Verification" \
            -optional \
            -horizontal \
            -options { { PASS PASS } { VRFY VRFY } { DROP DROP } }
       ossweb::widget form_user.spam_autolearn_flag -type radio -label "Spam auto-learn" \
            -optional \
            -horizontal \
            -options { { Enabled t } { Disabled f } }
       ossweb::widget form_user.spam_score_white -type select -label "Forward message if score is below" \
            -optional \
            -empty -- \
            -options [maverix::spamScores]
       ossweb::widget form_user.spam_status -type checkbox -label "Drop message if identified as" \
            -optional \
            -horizontal \
            -options { { Spam Spam } }
       ossweb::widget form_user.spam_score_black -type select -label "Drop message if score is above" \
            -optional \
            -empty -- \
            -options [maverix::spamScores]
       ossweb::widget form_user.back -type button -label Back \
            -url [ossweb::html::url cmd view] \
            -value Back
       ossweb::widget form_user.update -type submit -name cmd -label Update
       ossweb::widget form_user.delete -type button -label Delete \
            -url [ossweb::html::url cmd delete.user user_email $user_email] \
            -confirm "confirm('User will be deleted, continue?')"
       ossweb::widget form_sender.clear -type link -label Clear \
            -value [ossweb::html::url cmd clear.sender user_email $user_email tab $tab] \
            -notab \
            -html { onClick "return confirm('All senders from this list will be deleted, continue?')" }
     }
     
     default {
       ossweb::widget form_user.user_type -type multiselect -label "Type" \
            -optional \
            -empty " --" \
            -options { { VRFY VRFY } { PASS PASS } { DROP DROP } }
       ossweb::widget form_user.user_email -type text -label "User Email" \
            -optional
       ossweb::widget form_user.sender_digest_flag -type select -label "Sender Self Verification" \
            -optional \
            -empty -- \
            -options { { Enabled t } { Disabled f } }
       ossweb::widget form_user.anti_virus_flag -type select -label "Anti-Virus Verification" \
            -optional \
            -empty -- \
            -options { { Enabled t } { Disabled f } }
       ossweb::widget form_user.reset -type reset -label Reset -clear
       ossweb::widget form_user.search -type submit -name cmd -label Search
       ossweb::widget form_user.new -type button -label New \
            -url [ossweb::html::url cmd edit]
     }
    }
}

ossweb::conn::callback create_form_msg {} {

    ossweb::form form_msg -title "Message Details \[[ossweb::html::link -text $msg_id Messages cmd edit msg_id $msg_id]\]"
    ossweb::widget form_msg.ctx -type hidden -value msg -freeze
    ossweb::widget form_msg.page -type hidden -optional
    ossweb::widget form_msg.msg_id -type hidden
    ossweb::widget form_msg.user_email -type hidden
    ossweb::widget form_msg.msg_status -type radio -label Status \
         -options { { NEW NEW } { NTFY NTFY } { PASS PASS } { DROP DROP } } \
         -horizontal
    ossweb::widget form_msg.deliver_count -type label -label "Delivery Count" -nohidden
    ossweb::widget form_msg.deliver_error -type label -label "Delivery Error" -nohidden
    ossweb::widget form_msg.fake -type inform -label "&nbsp;" -value "&nbsp;"
    ossweb::widget form_msg.sender_email -type label -label From -nohidden
    ossweb::widget form_msg.subject -type label -label Subject -nohidden
    ossweb::widget form_msg.create_date -type label -label "Create Date" -nohidden
    ossweb::widget form_msg.attachments -type label -label Attachments -nohidden
    ossweb::widget form_msg.spam_status -type label -label "Spam Status/Score" -nohidden
    ossweb::widget form_msg.body -type label -label Text -nohidden
    ossweb::widget form_msg.back -type button -label Back \
         -url [ossweb::html::url cmd edit user_email $user_email tab messages]
    ossweb::widget form_msg.update -type submit -name cmd -label Update
    ossweb::widget form_msg.forward -type button -label Forward \
         -url [ossweb::html::url cmd forward.msg user_email $user_email msg_id $msg_id page $page]
    ossweb::widget form_msg.delete -type button -label Delete \
         -url [ossweb::html::url cmd delete.msg user_email $user_email msg_id $msg_id page $page] \
         -confirm "confirm('Message will be deleted, continue?')"
    ossweb::widget form_msg.spam -type button -label SPAM \
         -url [ossweb::html::url cmd spam.msg user_email $user_email msg_id $msg_id page $page] \
         -confirm "confirm('Message will be marked as SPAM, continue?')"
}

ossweb::conn::callback create_form_tab {} {
  
    set url [ossweb::html::url cmd edit user_email $user_email]
    ossweb::widget form_tab.edit -type link -label Edit -value $url
    ossweb::widget form_tab.aliases -type link -label Aliases -value $url
    ossweb::widget form_tab.white -type link -label "White List" -value $url
    ossweb::widget form_tab.black -type link -label "Black List" -value $url
    ossweb::widget form_tab.gray -type link -label "Gray List" -value $url
    ossweb::widget form_tab.messages -type link -label Messages -value $url
    ossweb::widget form_tab.log -type link -label Log -value $url
}

ossweb::conn::process \
         -columns { user_email "" ""
                    user_type "" "VRFY PASS"
                    sender_email "" ""
                    alias_email "" ""
                    digest_date "" ""
                    msg_id ilist ""
                    sort var ""
                    tab var edit
                    page var 1
                    force var f } \
         -forms { form_user form_tab form_msg } \
         -form_recreate t \
         -on_error_set_template { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            delete.user {
              -exec { users_action }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name page }
            }
            digest.user -
            update.user {
              -exec { users_action }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name edit }
            }
            spam.msg -
            forward.msg -
            delete.msg -
            update.msg {
              -exec { messages_action }
              -on_error_set_template { -cmd_name edit tab messages }
              -next_template { -cmd_name edit tab messages }
            }
            add.sender -
            pend.sender -
            permit.sender -
            block.sender -
            delete.sender -
            clear.sender {
              -exec { senders_action }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name edit }
            }
            delete.alias -
            add.alias {
              -exec { aliases_action }
              -on_error_set_template { -cmd_name edit tab aliases }
              -next_template { -cmd_name edit tab aliases }
            }
            edit {
              -exec { users_edit }
            }
            error {
            }
            default {
              -exec { users_list }
              -on_error_set_cmd ""
            }
         }

