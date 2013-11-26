# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2006

# Convert sort notation into SQL sort order clause
proc mail_sort { sort } {

    switch -- $sort {
     date - "date desc" -
     subject - "subject desc" -
     from - "from desc" { return msg_$sort }
     default { return msg_date }
    }
}

# Compare routine for folder sorting, special folder at the top
proc mail_lsort { s1 s2 } {

    if { [string equal -nocase $s1 Inbox] } { return -1 }
    if { [string equal -nocase $s2 Inbox] } { return 1 }
    if { [string equal -nocase $s1 Drafts] } { return -1 }
    if { [string equal -nocase $s2 Drafts] } { return 1 }
    if { [string equal -nocase $s1 Sent] } { return -1 }
    if { [string equal -nocase $s2 Sent] } { return 1 }
    if { [string equal -nocase $s1 Trash] } { return -1 }
    if { [string equal -nocase $s2 Trash] } { return 1 }
    return [string compare $s1 $s2]
}

# Returns a list with all IMAP folders, performs
# caching of the list for some time
proc mail_folderlist { conn_id { top INBOX } { refresh 0 } } {

    set folders [ossweb::cache get WMAIL:[ossweb::conn user_id]:$conn_id:folders]
    if { $refresh || $folders == "" } {
      set folders [list]
      set maildir [ossweb::config mail:dir]
      set index [string length $maildir]
      foreach { name flags } [ns_imap list $conn_id "[ns_imap getparam $conn_id mailbox.host]" $maildir*] {
        if { [string match "*noselect*" $flags] } { continue }
        set name [string range $name $index end]
        lappend folders $name
      }
      ossweb::cache set WMAIL:[ossweb::conn user_id]:$conn_id:folders $folders 3600
    }
    set folders [lsort -command mail_lsort $folders]
    # Insert inbox only if it is not the first folder already
    if { ![string equal -nocase [lindex $folders 0] $top] } {
      set folders [linsert $folders 0 $top]
    }
    return $folders
}

# Formats body text according to given type for mail composeing
proc mail_compose_body { body type } {

    set body [string map { <BR> "\n" <br> "\n" <P> "\n\n" <p> "\n\n" } $body]
    set body [ossweb::util::wrap_text [ns_striphtml $body]]
    return [string map { "\n" "\n> " } $body]
}

# Preferences
ossweb::conn::callback mail_prefs_action {} {

    switch -- ${ossweb:ctx} {
     update {
       ossweb::conn::set_property WMAIL:PREFS "" -forms form_prefs -global t -cache t
       ossweb::conn::set_msg "Preferences updated"
     }
    }
    ossweb::form form_prefs set_values
}

# Address Book actions
ossweb::conn::callback mail_contacts_action {} {

    switch -- ${ossweb:ctx} {
     update {
        if { $email == "" } {
          error "OSSWEB:Email Address is required"
        }
        if { $contact_type == "P" } {
          set user_id -1
        }
        if { $contact_id == "" } {
          if { [ossweb::db::exec sql:webmail.contacts.create] } {
            error "OSSWEB:Unable to create address book record"
          }
        } else {
          if { [ossweb::db::exec sql:webmail.contacts.update] } {
            error "OSSWEB:Unable to update address book record"
          }
        }
        ossweb::conn::set_msg "Contact has been updated"
        ossweb::form form_contacts reset
     }

     delete {
        if { $contact_id != "" } {
          if { [ossweb::db::exec sql:webmail.contacts.delete] } {
            error "OSSWEB:Unable to update address book record"
          }
        }
        ossweb::conn::set_msg "Contact has been deleted"
        ossweb::form form_contacts reset
     }

     edit {
        if { $contact_id > 0 } {
          ossweb::db::multivalue sql:webmail.contacts.read
          ossweb::form form_contacts set_values
        }
        return
     }

     ac {
       set data ""
       set filter [lindex [split $filter ,] end]
       if { $filter != "" } {
         ossweb::db::foreach sql:webmail.contacts.search {
           if { $name != "" } {
             set email "< $name > $email"
           }
           lappend data "{name:'$email'}"
         } -map { ' "" }
       }
       ossweb::adp::Exit [join $data "\n"]
     }

     search {
        set contact_id ""
     }
    }
    if { ${ossweb:ctx} == "error" } {
      return
    }
    # This is the field name where to put email address in case of compose mode
    set return [ns_queryget return]
    ossweb::db::multirow contacts sql:webmail.contacts.search -eval {
      if { $return != "" } {
        set row(email) [ossweb::html::link -text $row(email) -url "javascript:;" -onClick "wmContact('$return','$row(email)')"]
      } else {
        set row(email) [ossweb::html::link -text $row(email) cmd contacts.edit contact_id $row(contact_id)]
      }
    }
}

# Folders management
ossweb::conn::callback mail_folders_action {} {

    set folder [ns_queryget folder]
    set name [ns_queryget name]

    switch -- ${ossweb:ctx} {
     create {
       if { $name == "" } { return }
       ns_imap m_create $conn_id [webmail::mailbox $name]
     }

     rename {
       if { $name == "" || $folder == "" } { return }
       ns_imap m_rename $conn_id [webmail::mailbox $folder] [webmail::mailbox $name]
     }

     delete {
       if { $folder == "" } { return }
       ns_imap m_delete $conn_id [webmail::mailbox $folder]
     }
    }
    # Refresh folder list in already created forms
    ossweb::widget form_folders.folder -options [mail_folderlist $conn_id {"--" ""} 1]
    ossweb::widget form_view.folder -options [mail_folderlist $conn_id]
}

# Send return receipt notification
ossweb::conn::callback mail_return_receipt {} {

    variable ::webmail::version

    set to [ns_imap header $conn_id $msg_id Disposition-Notification-To -flags UID]
    if { $to == "" } {
      return
    }
    subject [ns_imap header $conn_id $msg_id subject -flags UID]
    set date [ns_imap header $conn_id $msg_id date -flags UID]
    set from [ossweb::conn user_email]
    set boundary "[pid][clock seconds][clock clicks][ns_rand]"
    set hdrs [list "MIME-Version" "1.0" "Content-Type" "multipart/report; report-type=disposition-notification; boundary=\"$boundary\""]

    set body "--$boundary\n"
    append body "Content-Type: text/plain\n\n"
    append body "Your message\n\tTo: $from\n\tSubject: $subject\nDate: $date\n has been displayed.\n"
    append body "--$boundary\n"
    append body "Content-type: message/disposition-notification\n\n"
    append body "Reporting-UA: $version\n"
    append body "Final-Recipient: rfc822;$from\n"
    append body "Original-Message-Id: [ns_imap header $conn_id $msg_id message-id]\n"
    append body "Disposition: manual-action/MDN-sent-manually; displayed\n"
    append body "--$boundary--"
    ossweb::sendmail $to $from "Disposition notification" $body -headers $hdrs
}

ossweb::conn::callback mail_login {} {

    set conn_id ""
    set mailbox INBOX
    set mailuser [ns_queryget user]
    set mailpassword [ns_queryget passwd]
    if { [catch { mail_open } errmsg] } {
      ossweb::conn::log Notice $errmsg
      error "OSSWEB: Unable to login into Webmail server"
    }
    ossweb::conn::next -cmd_name view
}

# Mailbox and mail actions
ossweb::conn::callback mail_logout {} {

    if { $auto_expunge == "t" } {
      mail_compact
    }
    catch { ns_imap close $conn_id }
    set conn_id ""
    ossweb::conn::sessionvars -form f conn_id
}

ossweb::conn::callback mail_compact {} {

    if { [catch {
      if { [ns_imap n_msgs $conn_id] > 0 } {
        ns_imap expunge $conn_id
      }
    } errmsg] } {
      ossweb::conn::log Error expunge: $errmsg
      ossweb::conn::set_msg "Error compacting mailbox"
    }
}

# Mailbox and mail actions
ossweb::conn::callback mail_move {} {

    if { $msg_id == "" || $folder == "" || $folder == $mailbox } {
      ossweb::conn::set_msg "No messages to move"
      return
    }
    if { [catch {
      ns_imap move $conn_id [join $msg_id ,] [webmail::mailbox $folder -host f] -flags UID
      ns_imap delete $conn_id [join $msg_id ,] -flags UID
      ossweb::db::exec sql:webmail.message.delete
    } errmsg] } {
      ossweb::conn::log Error move: $folder: $errmsg
      ossweb::conn::set_msg "Error moving messages"
    }
}

ossweb::conn::callback mail_delete {} {

    if { $msg_id == "" } {
      ossweb::conn::set_msg "No messages to delete"
      return
    }
    if { [catch {
      if { $trash_mailbox != "" } {
        ns_imap move $conn_id [join $msg_id ,] [webmail::mailbox $trash_mailbox -host f] -flags UID
      }
      ns_imap delete $conn_id [join $msg_id ,] -flags UID
      ossweb::db::exec sql:webmail.message.update -vars "msg_flags D"
    } errmsg] } {
      ossweb::conn::log Error delete: $trash_mailbox: $errmsg
      ossweb::conn::set_msg "Error deleting messages"
    }
}

# Realtime progress statistics about how many messages downloaded
ossweb::conn::callback mail_progress {} {

    set data ""
    catch { set data [nsv_get wm_count $conn_id] }
    ossweb::adp::Exit $data
}

ossweb::conn::callback mail_send {} {

    variable ::webmail::version

    set text ""
    set to [webmail::parse_email [ns_queryget to]]
    if { $to == "" } {
      error "OSSWEB: Specify To: email address"
    }
    set from [ossweb::nvl $from [ossweb::conn user_email]]
    set body [ns_queryget body]
    set hdrs [ns_set new]
    ns_set put $hdrs X-Mailer $version
    if { $reply_to != "" } {
      ns_set update $hdrs Reply-To $reply_to
    }
    # Message return receipt
    if { [ns_queryget rr] != "" } {
      ns_set put $hdrs Disposition-Notification-To $from
    }
    set flist [ns_querygetall file]
    if { $flist != "" } {
      set boundary "[pid][clock seconds][clock clicks][ns_rand]"
      ns_set put $hdrs "MIME-Version" "1.0"
      ns_set put $hdrs "Content-Type" "multipart/mixed; boundary=\"$boundary\""
      append text "--$boundary\n"
      append text "Content-Type: text/plain; charset=us-ascii\n\n"
      append text $body [ossweb::decode $signature "" "" "--\n$signature"] "\n\n"
      foreach name $flist {
        set fd [ossweb::file::open $name -path [webmail::path $conn_id]]
        if { $fd == "" } { continue }
        append text "--$boundary\n"
        set type [ns_guesstype $name]
        # We assume that undefined types are plain text
        if { $type == "text/plain" } {
          set type "application/octet-stream"
        }
        append text "Content-Type: $type; name=\"$name\"\n"
        append text "Content-Disposition: attachment; filename=\"$name\"\n"
        append text "Content-Transfer-Encoding: base64\n\n"
        set data [read $fd]
        close $fd
        append text [ns_imap encode base64 $data] "\n\n"
      }
      append text "--$boundary--\n"
    } else {
      append text $body [ossweb::decode $signature "" "" "--\n$signature"]
    }
    set subject [ns_queryget subject]
    set cc [webmail::parse_email [ns_queryget cc]]
    set bcc [webmail::parse_email [ns_queryget bcc]]
    if { [catch { ns_sendmail $to $from $subject $text $hdrs $bcc $cc } errmsg] } {
      error "OSSWEB: Unable to send message: $errmsg"
    }
    # Save copy of the message in Sent folder
    if { $sent_mailbox != "" } {
      set extra ""
      foreach { name value } [ossweb::convert::set_to_list $hdrs] {
        append extra "$name: $value\n"
      }
      set date [clock format [clock seconds] -format "%a, %d %b  %Y %H:%M:%S %Z" -gmt 1]
      set text "To: $to\nDate: $date\nFrom: $from\nSubject: $subject\n$extra\n\n$text"
      if { [catch { ns_imap append $conn_id [webmail::mailbox $sent_mailbox] $text } errmsg] } {
        ossweb::conn::set_msg -color red $errmsg
        ossweb::conn::log Error sent: $errmsg
      }
    }
    # Add outgoing emails to address book
    if { $auto_contacts == "Y" } {
      set emails [ossweb::convert::string_to_list "$to,$cc,$bcc" -separator ,]
      foreach email $emails {
        if { [ossweb::db::exec sql:webmail.contacts.add] } { break }
      }
    }
    ossweb::conn::set_msg "Message has been sent"
}

ossweb::conn::callback mail_attach_clear {} {

    foreach name [ns_querygetall file] {
      ossweb::file::delete $name -path [webmail::path $conn_id]
    }
}

ossweb::conn::callback mail_attach {} {

    set name [ossweb::file::upload upload -path [webmail::path $conn_id] -unique f]
    set attachments($name) 1
}

ossweb::conn::callback mail_reply {} {

    ns_imap struct $conn_id $msg_id -array struct -flags UID
    # Use message number in subsequent calls
    set msg $struct(msgno)
    ns_imap setflags $conn_id $msg "\\ANSWERED"
    set to [ns_imap header $conn_id $msg to]
    set from [ns_imap header $conn_id $msg from]
    set subject [ns_imap header $conn_id $msg subject]
    # Put into body text part of the message
    set body "\n\n\n$from wrote:\n> "
    if { $struct(type) == "multipart" } {
      for { set i 1 } { $i <= $struct(part.count) } { incr i } {
        array set part $struct(part.$i)
        if { ![info exists part(body.name)] } {
          append body [mail_compose_body [ns_imap body $conn_id $msg $i -decode] $part(subtype)]
        } else {
          # Save attachments into session file area
          set fname [ossweb::file::getname $part(body.name) -create t -unique f -path [webmail::path $conn_id]]
          ns_imap body $conn_id $msg $i -file $fname
        }
      }
    } else {
      append body [mail_compose_body [ns_imap body $conn_id $msg 1 -decode] $struct(subtype)]
    }
    # Customization
    switch ${ossweb:cmd} {
     reply {
        set prefix "Re"
     }
     replyall {
        set prefix "Re"
        set cc [webmail::parse_email "[ns_imap header $conn_id $msg cc],$to"]
     }
     forward {
        set prefix "Fwd"
        set from ""
     }
    }
    set to [webmail::parse_email $from]
    set subject "\[$prefix: $subject\]"
    ossweb::html::include "javascript:formCursorPos(document.form_compose.body,0)"
}

# Compose new email message
ossweb::conn::callback mail_compose {} {

    ossweb::form form_compose set_values
    ossweb::multirow create files name
    # Currently selected attachment files
    foreach name [ns_querygetall file] { set attachments($name) 1 }
    # Output uploaded files from session attachment area
    foreach name [ossweb::file::list -path [webmail::path $conn_id]] {
      set name [file tail $name]
      set checked [ossweb::decode [info exists attachments($name)] 1 "CHECKED" ""]
      set file "<INPUT TYPE=CHECKBOX NAME=file VALUE=\"$name\" $checked>&nbsp;"
      append file [ossweb::file::link webmail $name -html "TARGET=file" conn_id $conn_id file $name]
      ossweb::multirow append files $file
    }
    if { $compose_html == "t" } {
      ossweb::html::include body -type tiny_mce
    }
}

# Display email message
ossweb::conn::callback mail_read {} {

    if { [catch { ns_imap struct $conn_id $msg_id -array struct -flags UID } errmsg] } {
      error "OSSWEB: $msg_id: $errmsg"
    }
    # Flags and status
    set msg_flags ""
    set flags [ossweb::coalesce struct(flags)]

    # Read from the database
    ossweb::db::multivalue sql:webmail.message.read

    # Mark message as read and update database record
    if { [regexp {[NU]} $flags] ||
         $msg_flags != $flags ||
         [ossweb::coalesce msg_size] != [ossweb::coalesce struct(size)] } {
      ns_imap setflags $conn_id $msg_id "\\SEEN" -flags UID
      regsub {[NU]} $flags {} msg_flags
      set msg_size [ossweb::coalesce struct(size)]
      ossweb::db::exec sql:webmail.message.update
    }

    # Multirow with all headers
    ossweb::multirow create headers id name value class
    foreach { name value } [ns_imap headers $conn_id $msg_id -flags UID] {
      set name [string totitle $name]
      switch -- $name {
       To - Cc - Date - From - Subject {
         set id [ossweb::multirow size headers]
         set class visible
         ossweb::multirow insert headers 1 $id $name [ns_quotehtml [webmail::decode_hdr $value]] $class
       }
       default {
         set id [ossweb::multirow size headers]a
         set class hidden
         ossweb::multirow append headers $id $name [ns_quotehtml [webmail::decode_hdr $value]] $class
       }
      }
    }

    # For multipart messages show plain text in the body
    set body [webmail::decode_body $conn_id $struct(msgno) [array get struct] -files mailfiles -smilies $auto_smilies]
    set body_size [string length $body]
    if { $struct(type) == "multipart" } {
      append flags [ossweb::html::image attach2.gif -width "" -height "" -align bottom]
    }

    # Build attachements drop down
    if { $mailfiles != "" } {
      set files_list ""
      foreach file $mailfiles {
        foreach { furl fname ftype fsize } $file {}
        lappend files_list [list "<B>$fname</B>: $ftype/$fsize" "javascript:window.open('$furl')"]
      }
      set mailfiles [ossweb::html::dropdown_menu wmFiles Attachments $files_list -class:title webmailLink]
    }
}

# Show messages of the current mailbox
ossweb::conn::callback mail_list {} {

    # Mailbox status
    set msg_list ""
    set msg_list_flags ""
    set msg_total [ns_imap n_msgs $conn_id]
    set msg_recent [ns_imap n_recent $conn_id]
    set msg_uidvalidity [ns_imap uidvalidity $conn_id]

    # Message list datasource
    ossweb::multirow create messages msg_id subject flags attach from date size checkbox class

    # Manage local subcommand
    switch -- ${ossweb:ctx} {
     markread {
       if { $msg_total > 0 } {
         set msgs [join [ossweb::number_list $msg_total 1] ,]
         if { [catch { ns_imap setflags $conn_id $msgs \\SEEN } errmsg] } {
           ossweb::conn::log Error markread: 1-$msg_total $errmsg
         }
       }
       ossweb::conn::set_msg "Folder marked as read"
     }

     compact {
       mail_compact
       ossweb::conn::set_msg "Folder compacted"
     }

     refresh {
       ossweb::db::exec sql:webmail.message.delete.all
       ossweb::conn::set_msg "Folder messages refreshed"
     }

     sort {
       # Save new sorting order
       if { ![regexp desc $sort] } { lappend msg_sort desc }
       set sort $msg_sort
       # Save in preferences
       ossweb::conn::set_property WMAIL:PREFS "" -columns $prefs -global t -cache t
     }
    }

    # Verify mailbox and cache consistency
    set msg_last [ossweb::db::multilist sql:webmail.message.uid.last -plain t]
    if { $msg_last == "" || $msg_uidvalidity != [lindex $msg_last 1] } {
      # UID VALIDITY changed, re-read the whole mailbox
      ossweb::db::exec sql:webmail.message.delete.all
      set msg_list [ossweb::number_list $msg_total 1]
    } else {
      if { $msg_total > 0 } {
        set uid_last [ns_imap uid $conn_id $msg_total]
        if { [lindex $msg_last 0] < $uid_last } {
          set msg_list [ossweb::number_list $uid_last [expr [lindex $msg_last 0]+1]]
          set msg_list_flags UID
        }
      }
    }
    # Retrieve messages from the server
    if { $msg_list != "" } {
      set msg_count 0
      set msg_length [llength $msg_list]
      # This is to support realtime AJAX requests for progress info
      # during downloading messages
      nsv_set wm_count $conn_id "0 of $msg_length"
      foreach msg_id $msg_list {
        array unset struct
        set msg_type ""
        set msg_size ""
        set msg_flags ""
        if { [catch { set msg_headers [ns_imap headers $conn_id $msg_id -flags $msg_list_flags] } errmsg] } {
          ns_log notice webmail: $msg_id: $errmsg
          continue
        }
        incr msg_count
        if { $msg_count % 10 == 0 } {
          nsv_set wm_count $conn_id "$msg_count of $msg_length"
        }
        # Parse headers
        foreach { name value } $msg_headers {
          switch -glob -- [string tolower $name] {
           x-message-size { set msg_size $value }
           x-message-flags { set msg_flags $value }
           content-type { set msg_type [lindex [split $value "/;"] 0] }
           from { set msg_from $value }
           subject { set msg_subject $value }
           date { set msg_date [ns_fmttime [ns_imap parsedate $value]] }
          }
        }
        # Save with UID only
        if { $msg_list_flags == "" } {
          set msg_id [ns_imap uid $conn_id $msg_id]
        }
        ossweb::db::exec sql:webmail.message.create
      }
      nsv_unset wm_count $conn_id
    }

    set msg_sort [mail_sort $sort]
    # Retrieve messages from the cache
    ossweb::db::foreach sql:webmail.message.list {
      set class ""
      set attach [ossweb::html::image misc/1.gif]
      set from [webmail::decode_hdr $msg_from]
      set subject [ns_quotehtml [webmail::decode_hdr [ossweb::nvl $msg_subject "No subject"]]]
      set from [ossweb::html::link -text [ns_quotehtml $from] -window Compose -winopts $winopts cmd compose to $from msg_id $msg_id]
      set subject [ossweb::html::link -text $subject -id wmMsg$msg_id -url "javascript:;" -onClick "wmRead($msg_id);"]
      # Mark unread messages
      if { [regexp {[NU]} $msg_flags] } {
        incr msg_new
        set class unread
      }
      # Show icon if there are files attached
      if { $msg_type == "multipart" } {
        set attach [ossweb::html::image attach2.gif -width "" -height "" -align middle]
      }
      set checkbox "<INPUT TYPE=checkbox NAME=msg_id VALUE=$msg_id>"
      set size [ossweb::util::size $msg_size]
      ossweb::multirow append messages $msg_id $subject $msg_flags $attach $from $msg_time $size $checkbox $class
    }
}

# Returns javascript tree with folders
ossweb::conn::callback mail_folders {} {

    switch -- ${ossweb:cmd} {
     refresh {
       ossweb::cache flush WMAIL:[ossweb::conn user_id]:*
     }
    }

    # Setup javascript parameters
    ossweb::html::include "javascript:wmBaseUrl='[ossweb::html::url]';javascript:wmShowDeleted=[ossweb::decode $show_deleted t 1 0];"
    if { $auto_refresh > 0 } {
      ossweb::html::include "javascript:wmRefresh=$auto_refresh;setTimeout('wmScheduler()',wmRefresh*1000);"
    }

    # Retrieve folders and build javascript menu
    set id 0
    set seq -1
    foreach folder [mail_folderlist $conn_id] {
      incr id
      set parent 0
      set title $folder
      set icon /img/folder2.gif
      set url <hex>:[ossweb::hexify $folder]
      set link "javascript:wmList($conn_id,\\'$url\\');"
      set folder [split $folder {\\}]
      if { [llength $folder] > 1 } {
        set title [lindex $folder 1]
        set parent $folders([lindex $folder 0])
      } else {
        set folders([lindex $folder 0]) $id
      }
      set iname /img/webmail/folder-[string tolower $title].png
      if { [file exists [ns_info pageroot]$iname] } {
        set icon $iname
      }
      append mailfolders "Tree\[[incr seq]\] = new Array($id,$parent,'$title','$link','onMouseOver=\"this.wmOver=$seq\" onMouseOut=\"this.wmOver=null\" ','$icon',null,'$url');\n"
    }
    append mailfolders "createTree(Tree,null,'','[ossweb::config mail:host]','webmailTree');\n"
}

# Try to reloading using cached session info
ossweb::conn::callback mail_reopen {} {

    # For special mailboxes do not use cached username
    if { $mailaccess == "" } {
      set cache [ossweb::conn::get_property webmail:user:${ossweb:page} -global t -decrypt t]
      set mailuser [lindex $cache 0]
      set mailpassword [lindex $cache 1]
    }
    # Login user with provided username/password
    if { $mailuser != "" && $mailpassword != "" } {
      if { $conn_id != "" } {
        catch { ns_imap close $conn_id }
      }
      set conn_id ""
      return [mail_open]
    }
    return
}

# Login into IMAP server
ossweb::conn::callback mail_open {} {

    set conn_id ""
    # Find existing connection
    foreach { mid t1 t2 mbox } [ns_imap sessions] {
      if { [ns_imap getparam $mid user_id] == [ossweb::conn user_id] } {
        set conn_id $mid
        ns_log Notice webmail::open:: reusing session $conn_id for [ossweb::conn user_name]/[ossweb::conn user_id]
        break
      }
    }
    # At this point we may login with username/password only
    if { $mailuser == "" || $mailpassword == "" } {
      return
    }
    # Append domain to the username if confogured
    if { $mailsuffix != "" && ![string match "*$mailsuffix" $mailuser] } {
      append mailuser $mailsuffix
    }
    # Open new connection
    if { $conn_id == "" } {
      set conn_id [ns_imap open -mailbox [webmail::mailbox $mailbox] -user $mailuser -password $mailpassword]
    }
    # Save authentication data into mail session
    ns_imap setparam $conn_id user_id [ossweb::conn user_id]
    ns_imap setparam $conn_id session_id [ossweb::conn session_id]
    # Install at close handler to delete all attachments
    ns_imap setparam $conn_id session.atclose "ossweb::file::delete {} -path [webmail::path $conn_id]"
    # Put cookie as well to access mail app without explicit url
    ns_setcookie imap_id $conn_id
    # Replace request mail id with the new one
    if { [set form [ns_getform]] != "" } {
      ns_set update $form conn_id $conn_id
      ossweb::conn::sessionvars -query f conn_id
    }
    # Save name/password/mailbox in the server cache for broken sessions
    set key "{$mailuser} {$mailpassword}"
    if { $key != [ossweb::conn::get_property webmail:user:${ossweb:page} -global t -decrypt t] } {
      ossweb::conn::set_property webmail:user:${ossweb:page} $key -global t -encrypt t
    }
    return $conn_id
}

# Verify mail session
ossweb::conn::callback mail_check {} {

    # Special mailboxes access
    set mailuser [ossweb::config mail:user:${ossweb:page}]
    set mailpassword [ossweb::config mail:password:${ossweb:page}]
    set mailaccess [ossweb::config mail:access:${ossweb:page}]

    if { $mailaccess != "" && [lsearch -exact $mailaccess [ossweb::conn user_id]] == -1 } {
      ns_log Error webmail: ${ossweb:page}: access denied for [ossweb::conn user_id]
      error "Access to mailbox denied"
    }

    # Verify user session against mail session, try get mail id from cookies if set
    if { [set conn_id [webmail::parse_session $conn_id]] == "" && [set conn_id [mail_reopen]] == "" } {
      error "You should login in order to use Web Mail"
    }

    # If this session is used in another thread we should termninate this call
    if { [ns_imap getparam $conn_id session.status] == "Busy" } {
      ns_return 200 text/html Busy
      ns_conn close
      return
    }

    # Verify session
    if { ![ns_imap ping $conn_id] && [catch { ns_imap reopen $conn_id -reopen }] } {
      ns_log Notice mail::init $conn_id: server error
      if { [set conn_id [mail_reopen]] == "" } {
        error "Mail session expired or closed by the server, please login again"
      }
    }
    # Switch if different mailbox only
    if { [webmail::mailbox $mailbox -host f] != [webmail::name $conn_id] } {
      ns_imap reopen $conn_id -mailbox [webmail::mailbox $mailbox]
    }
    return $conn_id
}

# Verify mail session
ossweb::conn::callback mail_init {} {

    # Initialize config variables/preferences
    ossweb::conn::get_property WMAIL:PREFS -columns t -global t -cache t

    # Webmail stylesheet and javascript files
    ossweb::html::include /js/tree.js
    ossweb::html::include /js/webmail.js
    ossweb::html::include /css/webmail.css

    # Pages for which we do not have to verify session
    switch -- ${ossweb:cmd} {
     attach -
     clear -
     compose -
     contacts -
     prefs -
     logout -
     login -
     progress -
     error { return }
    }

    # See if we logged in and session is valid
    if { [catch { mail_check } errmsg] } {
      ns_log Notice mail::init ${ossweb:page}: $mailuser: $errmsg
      if { [ns_conn isconnected] } {
        ossweb::conn::set_msg -color red $errmsg
        ossweb::conn::next -cmd_name login -ctx_name error
      }
      return
    }
    # Retrieve currnet mailbox name
    if { $mailbox == "" } {
      set mailbox [ns_imap getparam $conn_id mailbox.name]
    }
    # Mark this session as busy
    ns_imap setparam $conn_id session.status Busy
    ns_atclose "ns_imap setparam $conn_id session.status {}"
}

ossweb::conn::callback create_form_view {} {

    ossweb::widget form_view.search -type text -label "Search" \
         -html { size 20 class search onKeyUp wmSearch() } \
         -name webmailSearch \
         -optional

    ossweb::widget form_view.refresh -type button -label "Refresh" \
         -url [ossweb::html::url cmd refresh] \
         -help "Refresh Webmail screen" \
         -class osswebSmallButton

    ossweb::widget form_view.stop -type button -label "Stop" \
         -url "javascript:wmStop()" \
         -help "Stop current request" \
         -class osswebSmallButton

    ossweb::widget form_view.contacts -type button -label "Contacts" \
         -help "Show contacts page" \
         -window Compose \
         -winopts $winopts \
         -url [ossweb::html::url cmd contacts] \
         -class osswebSmallButton

    ossweb::widget form_view.folders -type button -label "Folders" \
         -help "Manage folders" \
         -window Compose \
         -winopts $winopts \
         -url "javascript:wmFolderManage()" \
         -class osswebSmallButton

    ossweb::widget form_view.prefs -type button -label "Preferences" \
         -help "Show settings page" \
         -window Compose \
         -winopts $winopts \
         -url [ossweb::html::url cmd prefs] \
         -class osswebSmallButton

    ossweb::widget form_view.compose -type button -label "Compose" \
         -help "Compose new message" \
         -window Compose \
         -winopts $winopts \
         -url [ossweb::html::url cmd compose] \
         -class osswebSmallButton

    ossweb::widget form_view.reply -type button -label "Reply" \
         -help "Compose reply message" \
         -window Compose \
         -winopts $winopts \
         -url "javascript:wmReply()" \
         -class osswebSmallButton

    ossweb::widget form_view.replyall -type button -label "Reply All" \
         -help "Compose reply message to everybody" \
         -window Compose \
         -winopts $winopts \
         -url "javascript:wmReplyAll()" \
         -class osswebSmallButton

    ossweb::widget form_view.forward -type button -label "Forward" \
         -help "Compose forward message" \
         -window Compose \
         -winopts $winopts \
         -url "javascript:wmForward()" \
         -class osswebSmallButton

    ossweb::widget form_view.delete -type button -label "Delete" \
         -help "Delete current message" \
         -url "javascript:wmDelete()" \
         -class osswebSmallButton

    ossweb::widget form_view.actions -type popupbutton -label "Actions..." \
         -help "Folder local actions" \
         -class osswebSmallButton \
         -options { { "Compact" "javascript:;" "wmFolderCompact()" "TITLE='Remove deleted messages'" }
                    { "Mark Read" "javascript:;" "wmFolderMarkRead()" "TITLE='Mark all messages as Read'" }
                    { "Refresh All" "javascript:;" "wmFolderRefresh()" "TITLE='Refresh message list from the server'" } }

    ossweb::widget form_view.close -type button -name cmd -label "Close" \
         -class osswebSmallButton \
         -url "javascript:window.close()"

    ossweb::widget form_view.logout -type button -label "Logout" \
         -url [ossweb::html::url cmd logout] \
         -confirmtext "Session will be closed. Continue?" \
         -class osswebSmallButton
}

ossweb::conn::callback create_form_compose {} {

    ossweb::form form_compose -title "Compose Email"
    ossweb::widget form_compose.conn_id -type hidden
    ossweb::widget form_compose.mailbox -type hidden
    ossweb::widget form_compose.sort -type hidden
    ossweb::widget form_compose.to -type text -label "To:" \
         -size 80 \
         -autocomplete [ossweb::html::url cmd contacts.ac filter ""] \
         -autocomplete_proc wmSearchContact \
         -optional
    ossweb::widget form_compose.contacts_to -type link -value "javascript:;" -label [ossweb::html::image abook.gif] \
         -onClick "window.open('[ossweb::html::url cmd contacts.search return to]&email='+document.form_compose.to.value,'Contacts','$winopts')"
    ossweb::widget form_compose.cc -type text -label "CC:" \
         -size 80 \
         -autocomplete [ossweb::html::url cmd contacts.ac filter ""] \
         -autocomplete_proc wmSearchContact \
         -optional
    ossweb::widget form_compose.contacts_cc -type link -value "javascript:;" -label [ossweb::html::image abook.gif] \
         -onClick "window.open('[ossweb::html::url cmd contacts.search return cc]&email='+document.form_compose.cc.value,'Contacts','$winopts')"
    ossweb::widget form_compose.bcc -type text -label "BCC:"  \
         -size 80 \
         -autocomplete [ossweb::html::url cmd contacts.ac filter ""] \
         -autocomplete_proc wmSearchContact \
         -optional
    ossweb::widget form_compose.contacts_bcc -type link -value "javascript:;" -label [ossweb::html::image abook.gif] \
         -onClick "window.open('[ossweb::html::url cmd contacts.search return bcc]&email='+document.form_compose.bcc.value,'Contacts','$winopts')"
    ossweb::widget form_compose.rr -type checkbox -label "Return Receipt" \
         -value 1 \
         -optional
    ossweb::widget form_compose.subject -type text -label "Subject:" \
         -size 80
    ossweb::widget form_compose.body -type textarea -label "Text" \
         -html [list wrap hard style "font-size: ${fontsize}pt;"] \
         -rows 20 \
         -cols $editsize \
         -optional \
         -focus
    ossweb::widget form_compose.upload -type file -label "File" -optional
    ossweb::widget form_compose.send -type submit -name cmd -label "Send" \
         -class osswebSmallButton
    ossweb::widget form_compose.compose -type button -label "New" \
         -url [ossweb::html::url cmd compose] \
         -class osswebSmallButton
    ossweb::widget form_compose.attach -type submit -name cmd -label "Attach" \
         -class osswebSmallButton
    ossweb::widget form_compose.clear -type submit -name cmd -label "Clear" \
         -class osswebSmallButton
    ossweb::widget form_compose.close -type button -name cmd -label "Close" \
         -class osswebSmallButton \
         -url "javascript:window.close()"
}

ossweb::conn::callback create_form_contacts {} {

    ossweb::form form_contacts -title "Contacts Management"
    ossweb::widget form_contacts.contact_id -type hidden -optional
    ossweb::widget form_contacts.return -type hidden -optional
    ossweb::widget form_contacts.contact_type -type checkbox -label "Contact Type" \
         -optional \
         -value N \
         -options { { Public P } }
    ossweb::widget form_contacts.email -label "E-mail" \
         -optional
    ossweb::widget form_contacts.first_name -label "First Name" \
         -optional
    ossweb::widget form_contacts.last_name -label "Last Name" \
         -optional
    ossweb::widget form_contacts.description -type textarea -label "Description" \
         -rows 2 \
         -cols 40 \
         -optional
    ossweb::widget form_contacts.search -type button -label Search -cmd_name contacts.search
    ossweb::widget form_contacts.update -type button -label Add -cmd_name contacts.update
    ossweb::widget form_contacts.reset -type reset -label Reset -clear
    # Allow only search in non-full mode
    if { ${ossweb:ctx} == "search" || $contact_id <= 0 } { return }
    ossweb::widget form_contacts.update -type button -label Update -cmd_name contacts.update
    ossweb::widget form_contacts.delete -type button -label Delete -cmd_name contacts.delete
}

ossweb::conn::callback create_form_folders {} {

    ossweb::form form_folders -title "Folder Management" -cmd folders
    ossweb::widget form_folders.folder -type select -label "Existing Folders" -optional
    ossweb::widget form_folders.name -label "New Folder" -optional
    ossweb::widget form_folders.create -type button -label Create \
         -cmd_name folders.create
    ossweb::widget form_folders.rename -type button -label Rename \
         -cmd_name folders.rename
    ossweb::widget form_folders.delete -type button -label Delete \
         -cmd_name folders.delete
}

ossweb::conn::callback create_form_prefs {} {

    ossweb::form form_prefs -title "Mail Preferences" -cmd prefs -ctx update
    ossweb::widget form_prefs.from -type text -label "My Email" \
         -datatype email \
         -optional
    ossweb::widget form_prefs.reply_to -type text -label "Reply To Email" \
         -datatype email \
         -optional
    ossweb::widget form_prefs.sound_on_email -type soundselect -label "New Mail Sound" -optional
    ossweb::widget form_prefs.auto_refresh -type intervalselect -label "Auto refresh interval (secs)" \
         -optional
    ossweb::widget form_prefs.linesize -type numberselect -label "Message line size" \
         -start 40 \
         -end 120 \
         -optional
    ossweb::widget form_prefs.editsize -type numberselect -label "Size of editor textarea" \
         -start 40 \
         -end 120 \
         -optional
    ossweb::widget form_prefs.fontsize -type numberselect -label "Font size for editor textarea" \
         -start 10 \
         -end 24 \
         -optional
    ossweb::widget form_prefs.sort -type select \
         -label "Message Sort Order" -optional \
         -options { { Date date } { "Date Reverse" "date desc" }
                    { Subject subject } { "Subject Reverse" "subject desc" }
                    { From from } { "From Reverse" "from desc" } }
    ossweb::widget form_prefs.sent_mailbox -type select -label "Sent Folder" \
         -optional \
         -options [mail_folderlist $conn_id {"None" ""}]
    ossweb::widget form_prefs.trash_mailbox -type select -label "Trash Folder" \
         -optional \
         -options [mail_folderlist $conn_id {"None" ""}]
    ossweb::widget form_prefs.show_deleted -type boolean -label "Show deleted messages" \
         -optional
    ossweb::widget form_prefs.auto_expunge -type boolean -label "Expunge on Exit" \
         -optional
    ossweb::widget form_prefs.compose_html -type boolean -label "Compose in HTML(use richtext editor)" \
         -optional
    ossweb::widget form_prefs.auto_contacts -type boolean -label "Auto add emails to Address Book" \
         -optional
    ossweb::widget form_prefs.auto_smilies -type boolean -label "Convert text smilies into icons" \
         -optional
    ossweb::widget form_prefs.signature -type textarea -label "Signature" \
         -cols 40 \
         -rows 3 \
         -optional
    ossweb::widget form_prefs.update -type submit -label Update
}

ossweb::conn::callback create_form_login {} {

    ossweb::form form_login -title "Web Mail Login ($mailhost)"
    ossweb::widget form_login.user -label "User Name" \
         -html { size 15 }
    ossweb::widget form_login.passwd -type password -label "Password" \
         -html { size 15 }
    ossweb::widget form_login.cmd -type submit -label Login
}

# Preferences variables
set prefs { from "" ""
            sort "" 0date
            pagesize const 30
            linesize const 80
            fontsize const 12
            editsize const 80
            auto_refresh const 300
            compose_html const f
            sound_on_email const ""
            sent_mailbox const ""
            show_deleted const f
            trash_mailbox const ""
            auto_expunge const f
            auto_contacts const Y
            auto_smilies const f
            reply_to const ""
            signature const "" }

# Global variables
set columns { conn_id int ""
              mailbox "" ""
              msg_id ilist ""
              msg_sort "" ""
              first_name "" ""
              last_name "" ""
              email "" ""
              folder "" ""
              filter "" ""
              contact_id int ""
              contact_type "" ""
              mailuser const ""
              mailaccess const ""
              mailfiles const ""
              mailfolders const ""
              msg_new const 0
              msg_total const 0
              msg_recent const 0
              contacts:rowcount const 0
              mailhost const {[ossweb::config mail:host localhost]}
              mailopts const {[ossweb::config mail:options]}
              maildir const {[ossweb::config mail:dir]}
              mailsuffix const {[ossweb::config mail:suffix]}
              winopts const "width=950,height=800,location=0,menubar=0,scrollbars=1" }

ossweb::conn::process \
           -debug t \
           -columns $columns \
           -columns2 $prefs \
           -on_error_set_cmd "" \
           -on_error { -cmd_name login -ctx_name error } \
           -form_recreate t \
           -sessionvars { conn_id mailbox } \
           -exec { mail_init } \
           -eval {
             error {
             }

             login {
               -forms form_login
               -exec { mail_login }
             }

             login.error {
               -forms form_login
               -exec {}
             }

             logout {
               -exec { mail_logout }
               -next { -app_name index index }
             }

             clear {
               -forms form_compose
               -exec { mail_attach_clear }
               -next { -cmd_name compose }
               -on_error_set_cmd compose
             }

             attach {
               -forms form_compose
               -exec { mail_attach }
               -next { -cmd_name compose }
               -on_error_set_cmd compose
             }

             reply -
             replyall -
             forward {
               -forms form_compose
               -exec { mail_reply }
               -next { -cmd_name compose }
               -on_error_set_cmd compose
             }

             returnreceipt {
               -exec { mail_return_receipt }
               -next { -exit "" }
               -on_error { -exit "" }
             }

             delete {
               -exec { mail_delete }
               -next { -exit {[ossweb::conn msg]} }
               -on_error { -exit {[ossweb::conn msg]} }
             }

             move {
               -exec { mail_move }
               -next { -exit {[ossweb::conn msg]} }
               -on_error { -exit {[ossweb::conn msg]} }
             }

             progress {
               -exec { mail_progress }
               -on_error { -exit }
             }

             send {
               -forms form_compose
               -exec { mail_send }
               -on_error_set_cmd compose
               -on_error { -cmd_name compose }
             }

             compose {
               -forms { form_compose }
               -exec { mail_compose }
               -on_error { -cmd_name error }
             }

             prefs {
               -forms { form_view form_prefs }
               -exec { mail_prefs_action }
               -on_error { -cmd_name prefs -ctx_name error }
             }

             folders {
               -forms { form_view form_folders }
               -exec { mail_folders_action }
               -on_error { -cmd_name error }
             }

             contacts {
               -forms { form_view form_contacts }
               -exec { mail_contacts_action }
               -on_error { -cmd_name contacts -ctx_name error }
             }

             read {
               -exec { mail_read }
               -on_error { -cmd_name error }
             }

             list {
               -exec { mail_list }
               -on_error { -exit {[ossweb::conn msg]} }
             }

             default {
               -forms form_view
               -exec { mail_folders }
             }
           }
