# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2001

# Build full mailbox name
proc mail_mailbox { mailbox } {

    upvar mailhost mailhost maildir maildir mailopts mailopts
    if { $mailbox != "INBOX" } { set mailbox "$maildir$mailbox" }
    return "{$mailhost$mailopts}$mailbox"
}

# Returns name portion of mailbox name
proc mail_name { conn_id } {

    upvar maildir maildir
    set mailbox [ns_imap getparam $conn_id mailbox.name]
    if { $mailbox != "INBOX" } {
      set mailbox [string range $mailbox [string length $maildir] end]
    }
    return $mailbox
}

# Returns a list with all IMAP folders, performs
# caching of the list for some time
proc mail_folders { conn_id { top {INBOX INBOX} } { refresh 0 } } {

    upvar maildir maildir

    # Cache folders list
    set folders [ossweb::cache get MAIL:folders:$conn_id:[ossweb::conn user_id]]
    if { $refresh || $folders == "" } {
      set folders [list]
      set index [string length $maildir]
      foreach { name flags } [ns_imap list $conn_id "[ns_imap getparam $conn_id mailbox.host]" $maildir*] {
        if { [string match "*noselect*" $flags] } { continue }
        set name [string range $name $index end]
        lappend folders [list $name $name]
      }
      ossweb::cache set MAIL:folders:$conn_id:[ossweb::conn user_id] $folders 600
    }
    set folders [linsert [lsort $folders] 0 $top]
    return $folders
}

# Send return receipt notification
proc mail_return_receipt { to subject date msg_id } {

   upvar Version Version

   if { $to == "" } { return }
   set from [ossweb::conn user_email]
   set boundary "[pid][clock seconds][clock clicks][ns_rand]"
   set hdrs [list "MIME-Version" "1.0" "Content-Type" "multipart/report; report-type=disposition-notification; boundary=\"$boundary\""]

   set body "--$boundary\n"
   append body "Content-Type: text/plain\n\n"
   append body "Your message\n\tTo: $from\n\tSubject: $subject\nDate: $date\n has been displayed.\n"
   append body "--$boundary\n"
   append body "Content-type: message/disposition-notification\n\n"
   append body "Reporting-UA: $Version\n"
   append body "Final-Recipient: rfc822;$from\n"
   append body "Original-Message-Id: $msg_id\n"
   append body "Disposition: manual-action/MDN-sent-manually; displayed\n"
   append body "--$boundary--"
   ossweb::sendmail $to $from "Disposition notification" $body -headers $hdrs
}

# Decodes header string
proc mail_decode_hdr { str } {

    set b [string first "=?" $str]
    if { $b >= 0 } {
      set b [string first "?" $str [expr $b+2]]
      if { $b > 0 } {
        set e [string first "?=" $str $b]
        if { $e == -1 } { set e end } else { incr e -1 }
        switch [string index $str [expr $b+1]] {
         Q {
           set str [ns_imap decode qprint [string range $str [expr $b+3] $e]]
         }
         B {
           set str [ns_imap decode base64 [string range $str [expr $b+3] $e]]
         }
        }
      }
    }
    return $str
}

proc mail_decode_body { conn_id msg_id bodydata { bodyid "" } } {

    array set struct $bodydata

    if { $struct(type) == "multipart" } {
      set body ""
      set files ""
      for { set i 1 } { $i <= $struct(part.count) } { incr i } {
        array unset part
        array set part $struct(part.$i)
        if { $bodyid != "" } { set part_id "$bodyid.$i" } else { set part_id $i }
        if { $part(type) == "multipart" } {
          append body [mail_decode_body $conn_id $msg_id $struct(part.$i) $part_id]
          continue
        }
        if { [info exists part(body.name)] } {
          append files "<TR><TD>[ossweb::file::link webmail $part(body.name) -html "TARGET=file" conn_id $conn_id msg_id $msg_id part_id $part_id]</TD>
                            <TD>[string tolower "$part(type)/$part(subtype)"]</TD>
                            <TD>[ossweb::util::size [ossweb::coalesce part(bytes)]]</TD>
                        </TR>"
        } else {
          append body [mail_format_body [ns_imap body $conn_id $msg_id $part_id -decode] $part(subtype)]
        }
        append body "<P>"
      }
      if { $files != "" } {
        append body "<TABLE WIDTH=100% BORDER=0><TR CLASS=osswebFirstRow><TD COLSPAN=3><B>Attachments</B></TD></TR>" $files "</TABLE>"
      }
    } else {
      if { $bodyid != "" } { set part_id "$bodyid.1" } else { set part_id 1 }
      set body [mail_format_body [ns_imap body $conn_id $msg_id $part_id -decode] $struct(subtype)]
    }
    return $body
}

# Formats body text according to given type, used for putting
# email body into display form, takes care about all dangerous tags/symbols
proc mail_format_body { body type } {

    upvar linesize linesize

    set body [webmail::smilies $body]
    switch $type {
     HTML {
       set body [ns_imap striphtml $body]
     }
     default {
       set body "<PRE>[ossweb::util::wrap_text [ns_quotehtml $body]]</PRE>"
     }
    }
    return $body
}

# Formats body text according to given type for mail composeing
proc mail_compose_body { body type } {

    upvar linesize linesize

    set body [string map { <BR> \n <br> \n <P> \n\n <p> \n\n } $body]
    set body [ossweb::util::wrap_text [ns_striphtml $body]]
    return $body
}

# Build url for accesssing web mail app with required parameters
proc mail_url { args } {

    upvar conn_id conn_id sort sort page page mailbox mailbox
    # If different mailbox is specified, use that one instead of current mailbox
    if { [lsearch -exact $args mailbox] == -1 } {
      lappend args mailbox "{$mailbox}"
    }
    return [eval ossweb::html::url -page_name webmail $args conn_id $conn_id sort $sort page $page]
}

# Build link
proc mail_link { args } {

    upvar conn_id conn_id mailbox mailbox sort sort page page
    return [eval ossweb::html::link -page_name webmail $args conn_id $conn_id mailbox "{$mailbox}" sort $sort page $page $args]
}

# Preferences
ossweb::conn::callback mail_prefs_action {} {

    switch -- ${ossweb:ctx} {
     update {
       ossweb::conn::set_property MAIL:PREFS "" -forms form_prefs -global t -cache t
     }
    }
    ossweb::form form_prefs set_values
    ossweb::conn::set_msg "Preferences updated"
}

# Address Book actions
ossweb::conn::callback mail_abook_action {} {

    if { [set public [ns_queryget public]] == "Y" } { set user_id -1 }

    switch -- ${ossweb:ctx} {
     update {
        if { $email == "" } { error "OSSWEB:Email Address is required" }
        if { $contact_id == "" } {
          if { [ossweb::db::exec sql:webmail.contacts.create] } {
            error "OSSWEB:Unable to create address book record"
          }
        } else {
          if { [ossweb::db::exec sql:webmail.contacts.update] } {
            error "OSSWEB:Unable to update address book record"
          }
        }
        # For mass population, next update will add new record
        ossweb::conn::set_msg "Address has been updated"
     }

     delete {
        if { $contact_id != "" } {
          if { [ossweb::db::exec sql:webmail.contact.delete] } {
            error "OSSWEB:Unable to update address book record"
          }
        }
        ossweb::conn::set_msg "Address has been deleted"
     }

     edit {
        if { $contact_id > 0 } {
          ossweb::db::multivalue sql:webmail.contacts.read
        }
     }

     search {
        set contact_id ""
     }
    }
    set abook:rowcount 0
    ossweb::form form_abook set_values
    if { ${ossweb:ctx} == "error" || $contact_id > 0 } { return }
    # This is the field name where to put email address in case of abook2 mode
    set return [ns_queryget return]
    ossweb::db::multirow abook sql:webmail.contacts.search -eval {
      if { ${ossweb:cmd} == "abook2" } {
        set row(email) "<A HREF=\"javascript:var i\" onClick=\"addrAdd('$return','$row(email)')\">$row(email)</A>"
      } else {
        set row(email) [mail_link -text $row(email) cmd abook.edit contact_id $row(contact_id)]
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
       ns_imap m_create $conn_id [mail_mailbox $name]
     }

     rename {
       if { $name == "" || $folder == "" } { return }
       ns_imap m_rename $conn_id [mail_mailbox $folder] [mail_mailbox $name]
     }

     delete {
       if { $folder == "" } { return }
       ns_imap m_delete $conn_id [mail_mailbox $folder]
     }
    }
    # Refresh folder list in already created forms
    ossweb::widget form_folders.folder -options [mail_folders $conn_id {"--" ""} 1]
    ossweb::widget form_view.folder -options [mail_folders $conn_id]
}

# Mailbox and mail actions
ossweb::conn::callback mail_action {} {

    switch -- ${ossweb:cmd} {

     login {
        set conn_id ""
        set mailbox INBOX
        set mailuser [ns_queryget user]
        set mailpassword [ns_queryget passwd]
        if { [catch { mail_open } errMsg] } {
          ns_log Notice $errMsg
          error "OSSWEB: Unable to login into Web Mail server"
        }
        ossweb::conn::next -cmd_name view
     }

     logout {
        ns_imap close $conn_id
        set conn_id ""
     }

     mark {
        set spam [ns_queryget spam 0]
        set folder [ns_queryget folder]
        set msgs [ns_querygetall msg_id]
        set email [ossweb::nvl $from [ossweb::conn user_email]]
        if { [info command ns_maverix] == "" || ($msgs == "" && $folder == "") } { return }
        # Mark the whole folder
        if { $folder == $mailbox } {
          foreach msg [ns_imap sort $conn_id date 0] { lappend msgs $msg }
        }
        foreach msg $msgs {
          set body [ns_imap body $conn_id $msg 1]
          ns_log Debug webmail::mark: $email: $msg: [ns_maverix trainspam $spam $email $body "" teft corpus]
        }
        ossweb::conn::set_msg "Messages have been marked"
     }

     goto {
        set mailbox [ns_queryget mailbox]
        set mailuser ""
        set mailpassword ""
        mail_open
     }

     move {
        set folder [ns_queryget folder]
        if { $folder != "INBOX" } { set folder "$maildir$folder" }
        set msgs [ns_querygetall msg_id]
        if { $msgs == "" || $folder == "" || $folder == $mailbox } { return }
        if { [catch {
          ns_imap move $conn_id [join $msgs ","] $folder
          ns_imap delete $conn_id [join $msgs ","]
          ns_imap expunge $conn_id
        } errmsg] } {
          ossweb::conn::set_msg -color red $errmsg
        }
     }

     delete {
        set msgs [ns_querygetall msg_id]
        if { $msgs == "" } { return }
        if { [catch {
          if { $trash_mailbox != "" } {
            ns_imap move $conn_id [join $msgs ","] $trash_mailbox
          }
          ns_imap delete $conn_id [join $msgs ","]
          ns_imap expunge $conn_id
        } errmsg] } {
          ossweb::conn::set_msg -color red $errmsg
        }
        # Show next message after delete
        if { [ns_queryget form:id] == "form_edit" && [llength $msgs] == 1 } {
          if { [ns_imap n_msgs $conn_id] < $msg_id } { set msg_id [ns_imap n_msgs $conn_id] }
          if { $msg_id > 0 } { ossweb::conn::next -cmd_name edit }
        }
     }

     returnreceipt {
        mail_return_receipt [ns_queryget to] [ns_queryget subject] [ns_queryget date] [ns_queryget msg_id]
     }

     send {
        set text ""
        set to [webmail::parse_email [ns_queryget to]]
        if { $to == "" } { error "OSSWEB: Specify To: email address" }
        set from [ossweb::nvl $from [ossweb::conn user_email]]
        set body [ns_queryget body]
        set hdrs [ns_set new]
        ns_set put $hdrs X-Mailer $Version
        if { $reply_to != "" } { ns_set update $hdrs Reply-To $reply_to }
        # Message return receipt
        if { [ns_queryget rr] != "" } { ns_set put $hdrs Disposition-Notification-To $from }
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
            if { $type == "text/plain" } { set type "application/octet-stream" }
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
        ns_log Debug webmail: $from: $to: $cc: $bcc
        if { [catch { ns_sendmail $to \
                                  $from \
                                  $subject \
                                  $text \
                                  $hdrs \
                                  $bcc \
                                  $cc } errMsg] } {
          error "OSSWEB: Unable to send message: $errMsg"
        }
        ossweb::conn::set_msg "Message has been sent"
        # Save copy of the message in Sent folder
        if { $sent_mailbox != "" } {
          set extra ""
          foreach { name value } [ossweb::convert::set_to_list $hdrs] {
            append extra "$name: $value\n"
          }
          set date [clock format [clock seconds] -format "%a, %d %b  %Y %H:%M:%S %Z" -gmt 1]
          if { [catch { ns_imap append $conn_id \
                           [mail_mailbox $sent_mailbox] \
                           "To: $to\nDate: $date\nFrom: $from\nSubject: $subject\n$extra\n\n$text" } errmsg] } {
            ossweb::conn::set_msg -color red $errmsg
            ossweb::conn::log Error $errmsg
          }
        }
        # Add outgoing emails to address book
        if { $auto_abook == "Y" } {
          set emails [ossweb::convert::string_to_list "$to,$cc,$bcc" -separator ,]
          foreach email $emails {
            if { [ossweb::db::exec sql:webmail.contacts.add] } { break }
          }
        }
     }

     clear {
        foreach name [ns_querygetall file] {
          ossweb::file::delete $name -path [webmail::path $conn_id]
        }
     }

     attach {
        set name [ossweb::file::upload upload -path [webmail::path $conn_id] -unique f]
        set attachments($name) 1
     }

     reply -
     replyall -
     forward {
        ns_imap struct $conn_id $msg_id -array struct
        set to [ns_imap header $conn_id $msg_id to]
        set from [ns_imap header $conn_id $msg_id from]
        set subject [ns_imap header $conn_id $msg_id subject]
        # Put into body text part of the message
        set body "\n\n\n-------- Original Message --------\n"
        append body "To: $to\nFrom: $from\nSubject: $subject\n\n"
        if { $struct(type) == "multipart" } {
          for { set i 1 } { $i <= $struct(part.count) } { incr i } {
            array set part $struct(part.$i)
            if { ![info exists part(body.name)] } {
              append body [mail_compose_body [ns_imap body $conn_id $msg_id $i -decode] $part(subtype)]
            } else {
              # Save attachments into session file area
              set fname [ossweb::file::getname $part(body.name) -create t -unique f -path [webmail::path $conn_id]]
              ns_imap body $conn_id $msg_id $i -file $fname
            }
          }
        } else {
          append body [mail_compose_body [ns_imap body $conn_id $msg_id 1 -decode] $struct(subtype)]
        }
        # Customization
        switch ${ossweb:cmd} {
         reply {
            set prefix "Re"
         }
         replyall {
            set prefix "Re"
            set cc [webmail::parse_email "[ns_imap header $conn_id $msg_id cc],$to"]
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

     prev -
     next {
        # Shift to next/prev message or go to view mode if no more msgs
        if { ${ossweb:cmd} == "prev" } { set step -1 } else { set step 1 }
        set msgs [ns_imap sort $conn_id [string range $sort 1 end] [string index $sort 0]]
        set index [lsearch -exact $msgs $msg_id]
        if { $index > -1 } { set msg_id [lindex $msgs [expr $index+$step]] }
        if { $msg_id == "" } {
          ossweb::conn::next -cmd_name view
          return
        }
        # Recalculate page number
        set page [expr ($msg_id-1-(($msg_id-1)%$pagesize))/$pagesize+1]
     }

     file {
        # Can be body part or attachment file
        if { $msg_id != "" && $part_id != "" } {
          ns_imap body $conn_id $msg_id $part_id -return
        } elseif { [set file [ns_queryget file]] != "" } {
          ossweb::file::return $file -path [webmail::path $conn_id]
        }
     }
    }
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
    if { $use_tiny_mce } {
      ossweb::html::include body -type tiny_mce
    }
}

# Display email message
ossweb::conn::callback mail_edit {} {

    if { [catch { ns_imap struct $conn_id $msg_id -array struct } errmsg] } {
      error "OSSWEB: $errmsg"
    }
    ossweb::multirow create hdrs name value
    # Show all headers or basic headers only
    if { [ns_queryget full] == 1 } {
      set hdr_image [mail_link -image minus.gif -align top -alt "Brief" cmd edit msg_id $msg_id]
      foreach { name value } [ns_imap headers $conn_id $msg_id] {
        ossweb::multirow append hdrs [string totitle $name] [ns_quotehtml [mail_decode_hdr $value]]
      }
    } else {
      # Only basic headers
      set hdr_image [mail_link -image plus.gif -align top -alt "All headers" cmd edit msg_id $msg_id full 1]
      ossweb::multirow append hdrs To [ns_quotehtml [ns_imap header $conn_id $msg_id to]]
      ossweb::multirow append hdrs Cc [ns_quotehtml [ns_imap header $conn_id $msg_id cc]]
      ossweb::multirow append hdrs Date [ns_imap header $conn_id $msg_id date]
      ossweb::multirow append hdrs From [ns_quotehtml [mail_decode_hdr [ns_imap header $conn_id $msg_id from]]]
      ossweb::multirow append hdrs Subject [ns_quotehtml [mail_decode_hdr [ns_imap header $conn_id $msg_id subject]]]
    }
    set flags [ossweb::coalesce struct(flags)]
    # For multipart messages show plain text in the body and
    # list of attachments below
    set body [mail_decode_body $conn_id $msg_id [array get struct]]
    set body_size [string length $body]
    # Return receipt confirmation
    if { [string first N $flags] > -1 || [string first U $flags] > -1 } {
      set rr [ns_imap header $conn_id $msg_id Disposition-Notification-To]
      if { $rr != "" } {
        set url [mail_url cmd returnreceipt \
                          msg_id $msg_id \
                          to $rr \
                          subject [ns_imap header $conn_id $msg_id subject] \
                          date [ns_imap header $conn_id $msg_id date] \
                          msg_id [ns_imap header $conn_id $msg_id message-id]]
        append body "<SCRIPT LANGUAGE=JavaScript>
                       if(confirm('Message contains Desposition Notification request.Do you want to send Return Receipt?'))
                         window.location='$url'
                     </SCRIPT>"
      }
    }
}

# Show messages of the current mailbox
ossweb::conn::callback mail_view {} {

    set title $mailbox
    ossweb::widget form_view.view -label "Refresh"
    # Retrieve messages in given sorting order
    if { [catch { set msgs [ns_imap sort $conn_id [string range $sort 1 end] [string index $sort 0]] } errmsg] } {
      error "OSSWEB: $errmsg"
    }
    set msgs [ossweb::sql::multipage pages:mp \
                  -ids $msgs \
                  -cmd_name view \
                  -pagesize $pagesize \
                  -page $page \
                  -query "conn_id=$conn_id&mailbox=$mailbox&sort=$sort"]
    if { ${pages:mp(pagecount)} > 1 } {
      set range_msgs ", show ${pages:mp(start)} to ${pages:mp(end)}"
    } else {
      set range_msgs ""
    }
    set new 0
    # Go through messages and build datasource
    ossweb::multirow create mlist msg subject flags from date size
    foreach msg $msgs {
      ns_imap struct $conn_id $msg -array struct
      set date [ns_imap header $conn_id $msg date]
      set sdate [ns_imap parsedate $date]
      if { $sdate != "" } { set date [ns_fmttime $sdate "%a, %m/%d/%y %H:%M:%S"] }
      set from [ns_quotehtml [mail_decode_hdr [ns_imap header $conn_id $msg from]]]
      set subject [ns_quotehtml [mail_decode_hdr [ossweb::nvl [ns_imap header $conn_id $msg subject] "No subject"]]]
      set from [mail_link -text $from cmd compose to $from]
      set subject [mail_link -text $subject cmd edit msg_id $msg]
      # Mark unread messages
      set flags [ossweb::coalesce struct(flags)]
      if { [string first N $flags] > -1 || [string first U $flags] > -1 } {
        incr new
        set subject "<B>$subject</B>"
      }
      if { $struct(type) == "multipart" } {
        append flags [ossweb::html::image attach.gif -align absbottom]
      }
      set msg "<INPUT TYPE=checkbox NAME=msg_id VALUE=$msg>"
      set size [ossweb::util::size [ossweb::coalesce struct(size) 0]]
      ossweb::multirow append mlist $msg $subject $flags $from $date $size
    }
    # Refresh page every minute
    ossweb::html::include "javascript:setTimeout(function (){window.location='[mail_url cmd goto mailbox INBOX]'},${refresh}000)"
    # Produce new mail message and sound if configured
    if { $mailbox == "INBOX" && $new > 0 } {
      set title "$mailbox ($new)"
      ossweb::conn::set_msg "You have $new new message(s)"
      if { $sound != "" } {
        ossweb::conn::set_msg "<IFRAME SRC=\"[ossweb::config server:path:sound "/snd"]/$sound\" WIDTH=1 HEIGHT=1 FRAMEBORDER=0></IFRAME>"
      }
    }
    ossweb::conn -set title $title
}

# Try to reloagin using cached session info
ossweb::conn::callback mail_reopen {} {

    # For special mailboxes do not use cached username
    if { $mailaccess == "" } {
      set cache [ossweb::conn::get_property webmail:user:${ossweb:page} -global t -decrypt t]
      set mailuser [lindex $cache 0]
      set mailpassword [lindex $cache 1]
    }
    set mailbox [ossweb::cache get MAIL:[ossweb::conn session_id]:MBOX INBOX]
    if { $mailuser != "" && $mailpassword != "" && $mailbox != "" } {
      if { $conn_id != "" } { catch { ns_imap close $conn_id } }
      set conn_id ""
      return [mail_open]
    }
    return
}

# Login into IMAP server
ossweb::conn::callback mail_open {} {

    # Reopen another mailbox
    if { $conn_id != "" } {
      # Switch if different mailbox only
      if { $mailbox != [mail_name $conn_id] } {
        ns_imap reopen $conn_id -mailbox [mail_mailbox $mailbox]
        ossweb::cache set MAIL:[ossweb::conn session_id]:MBOX [mail_name $conn_id]
      }
      return $conn_id
    }
    if { $mailuser == "" || $mailpassword == "" } { return "" }
    if { $mailsuffix != "" && ![string match "*$mailsuffix" $mailuser] } {
      append mailuser $mailsuffix
    }
    set conn_id ""
    # Find existing connection
    foreach { mid t1 t2 mbox } [ns_imap sessions] {
      if { [ns_imap getparam $mid user_id] == [ossweb::conn user_id] } {
        set conn_id $mid
        ns_log debug webmail::open:: reusing session $conn_id for [ossweb::conn user_name]/[ossweb::conn user_id]
        break
      }
    }
    # Open new connection
    if { $conn_id == "" } {
      set conn_id [ns_imap open -mailbox [mail_mailbox $mailbox] -user $mailuser -password $mailpassword]
    }
    # Save authentication data into mail session
    ns_imap setparam $conn_id user_id [ossweb::conn user_id]
    ns_imap setparam $conn_id session_id [ossweb::conn session_id]
    # Install at close handler to delete all attachments
    ns_imap setparam $conn_id session.atclose "ossweb::file::delete {} -path [webmail::path $conn_id]"
    # Put cookie as well to access mail app without explicit url
    ns_setcookie imap_id $conn_id
    # Replace request mail id with the new one
    if { [set form [ns_getform]] != "" } { ns_set update $form conn_id $conn_id }
    # Save name/password/mailbox in the server cache for broken sessions
    ossweb::cache set MAIL:[ossweb::conn session_id]:MBOX [mail_name $conn_id]
    set key "{$mailuser} {$mailpassword}"
    if { $key != [ossweb::conn::get_property webmail:user:${ossweb:page} -global t -decrypt t] } {
      ossweb::conn::set_property webmail:user:${ossweb:page} $key -global t -encrypt t
    }
    return $conn_id
}

# Verify mail session
ossweb::conn::callback mail_init {} {

    # Setup configuration vars
    set mailhost [ossweb::config mail:host "localhost"]
    set mailopts [ossweb::config mail:options]
    set maildir [ossweb::config mail:dir]
    set mailsuffix [ossweb::config mail:suffix]

    # Pages for which we do not have to verify session
    if { ${ossweb:cmd} == "login" || ${ossweb:cmd} == "error" } { return }

    # Special mailboxes access
    mail_access

    # Verify user session against mail session, try get mail id from cookies if set
    if { [set conn_id [webmail::parse_session $conn_id]] == "" &&
         [set conn_id [mail_reopen]] == "" } {
      error "OSSWEB: You should login in order to use Web Mail"
    }
    # Verify session
    if { ![ns_imap ping $conn_id] && [catch { ns_imap reopen $conn_id -reopen }] } {
      ns_log Notice mail::init $conn_id: server error
      if { [set conn_id [mail_reopen]] == "" } {
        error "OSSWEB: Mail session expired or closed by the server, please login again"
      }
    }
    # Common mailbox information
    set mailbox [mail_name $conn_id]
    set total_msgs [ns_imap n_msgs $conn_id]
    set recent_msgs [ns_imap n_recent $conn_id]
    # Initialize config variables/preferences
    ossweb::conn::get_property MAIL:PREFS -columns t -global t -cache t
    # Webmail stylesheet
    ossweb::html::include /css/webmail.css
}

# Special mailboxes
ossweb::conn::callback mail_access {} {

    set mailuser [ossweb::config mail:user:${ossweb:page}]
    set mailpassword [ossweb::config mail:password:${ossweb:page}]
    set mailaccess [ossweb::config mail:access:${ossweb:page}]

    if { $mailaccess != "" && [lsearch -exact $mailaccess [ossweb::conn user_id]] == -1 } {
      ns_log Error webmail: ${ossweb:page}: access denied for [ossweb::conn user_id]
      error "OSSWEB: Access to mailbox denied"
    }
}

ossweb::conn::callback create_form_login {} {

    ossweb::form form_login -title "Web Mail Login ($mailhost)"
    ossweb::widget form_login.user -label "User Name" \
         -html { size 15 }
    ossweb::widget form_login.passwd -type password -label "Password" \
         -html { size 15 }
    ossweb::widget form_login.cmd -type submit -label Login
}

ossweb::conn::callback create_form_view {} {

    ossweb::sql::multipage pages:mp
    ossweb::widget form_view.conn_id -type hidden -value $conn_id -freeze
    ossweb::widget form_view.mailbox -type hidden -value $mailbox -freeze
    ossweb::widget form_view.sort -type hidden -value $sort -freeze
    ossweb::widget form_view.page -type hidden -value $page -freeze
    ossweb::widget form_view.folder -type select -label "Folders" \
         -options [mail_folders $conn_id] -value $mailbox
    ossweb::widget form_view.delete -type submit -name cmd -label "Delete" \
         -class osswebSmallButton
    ossweb::widget form_view.move -type submit -name cmd -label "Move" \
         -class osswebSmallButton
    ossweb::widget form_view.goto -type button -label "Go To" \
         -html [list onClick "window.location='[ossweb::html::url conn_id $conn_id cmd goto mailbox ""]'+this.form.folder.options\[this.form.folder.selectedIndex\].value"] \
         -class osswebSmallButton
    ossweb::widget form_view.compose -type button -label "Compose" \
         -url [mail_url cmd compose] \
         -class osswebSmallButton
    ossweb::widget form_view.view -type button -label "Messages" \
         -url [mail_url cmd view] \
         -class osswebSmallButton
    ossweb::widget form_view.abook -type button -label "Addresses" \
         -url [mail_url cmd abook] \
         -class osswebSmallButton
    ossweb::widget form_view.folders -type button -label "Folders" \
         -url [mail_url cmd folders] \
         -class osswebSmallButton
    ossweb::widget form_view.search -type button -label "Search" \
         -url [mail_url cmd search] \
         -class osswebSmallButton
    ossweb::widget form_view.prefs -type button -label "Preferences" \
         -url [mail_url cmd prefs] \
         -class osswebSmallButton
    ossweb::widget form_view.logout -type button -label "Logout" \
         -url [ossweb::html::url cmd logout conn_id $conn_id] \
         -class osswebSmallButton
    if { [info command ns_maverix] != "" } {
      ossweb::widget form_view.mark -type popupbutton -label "Mark..." \
           -options [list \
                      [list "As Innocent" [mail_url cmd mark spam 0 folder $mailbox]] \
                      [list "As SPAM" [mail_url cmd mark spam 1 folder $mailbox]]] \
           -class osswebSmallButton
    }
}

ossweb::conn::callback create_form_edit {} {

    ossweb::widget form_edit.msg_id -type hidden
    ossweb::widget form_edit.view -type button -label "Messages" \
         -url [mail_url cmd view] \
         -class osswebSmallButton
    ossweb::widget form_edit.folder -type select -label "Folders" \
         -options [mail_folders $conn_id] -value $mailbox \
         -class osswebSmallButton
    ossweb::widget form_edit.goto -type button -label "Go To" \
         -html [list onClick "window.location='[ossweb::html::url conn_id $conn_id cmd goto mailbox ""]'+this.form.folder.options\[this.form.folder.selectedIndex\].value"] \
         -class osswebSmallButton
    ossweb::widget form_edit.move -type submit -name cmd -label "Move" \
         -class osswebSmallButton
    ossweb::widget form_edit.reply -type button -label "Reply" \
         -url [mail_url cmd reply msg_id $msg_id] \
         -class osswebSmallButton
    ossweb::widget form_edit.replyall -type button -label "Reply All" \
         -url [mail_url cmd replyall msg_id $msg_id] \
         -class osswebSmallButton
    ossweb::widget form_edit.forward -type button -label "Forward" \
         -url [mail_url cmd forward msg_id $msg_id] \
         -class osswebSmallButton
    ossweb::widget form_edit.delete -type button -label "Delete" \
         -url [mail_url cmd delete msg_id $msg_id] \
         -class osswebSmallButton
    ossweb::widget form_edit.prev -type button -label "Prev" \
         -url [mail_url cmd prev msg_id $msg_id] \
         -class osswebSmallButton
    ossweb::widget form_edit.next -type button -label "Next" \
         -url [mail_url cmd next msg_id $msg_id] \
         -class osswebSmallButton
    ossweb::widget form_edit.search -type button -label "Search" \
         -url [mail_url cmd search] \
         -class osswebSmallButton
    ossweb::widget form_edit.mark -type popupbutton -label "Mark..." \
         -options [list \
                    [list "As Innocent" [mail_url cmd mark spam 0 msg_id $msg_id]] \
                    [list "As SPAM" [mail_url cmd mark spam 1 msg_id $msg_id]]] \
         -class osswebSmallButton
}

ossweb::conn::callback create_form_compose {} {

    # Address book popup window options
    set winopts "scrollbars=1,menubar=0,location=0,width=600,height=600"

    ossweb::form form_compose -html { enctype "multipart/form-data" }
    ossweb::widget form_compose.conn_id -type hidden
    ossweb::widget form_compose.mailbox -type hidden
    ossweb::widget form_compose.sort -type hidden
    ossweb::widget form_compose.page -type hidden
    ossweb::widget form_compose.to -type text -label "To:" -html { size 60 } -optional
    ossweb::widget form_compose.abook_to -type link -value "javascript:return" \
         -label [ossweb::html::image abook.gif] \
         -html [list onClick "window.open('[mail_url cmd abook2.search return to]&email='+document.form_compose.to.value,'Abook','$winopts')"]
    ossweb::widget form_compose.cc -type text -label "CC:" -html { size 60 } -optional
    ossweb::widget form_compose.abook_cc -type link -value "javascript:return" \
         -label [ossweb::html::image abook.gif] \
         -html [list onClick "window.open('[mail_url cmd abook2.search return cc]&email='+document.form_compose.cc.value,'Abook','$winopts')"]
    ossweb::widget form_compose.bcc -type text -label "BCC:"  -html { size 60 } -optional
    ossweb::widget form_compose.abook_bcc -type link -value "javascript:return" \
         -label [ossweb::html::image abook.gif] \
         -html [list onClick "window.open('[mail_url cmd abook2.search return bcc]&email='+document.form_compose.bcc.value,'Abook','$winopts')"]
    ossweb::widget form_compose.rr -type checkbox -label "Return Receipt" -value 1 -optional
    ossweb::widget form_compose.subject -type text -label "Subject:" -html { size 60 } -optional
    ossweb::widget form_compose.body -type textarea -label "Text" \
         -html [list rows 20 cols $editsize wrap hard style "font-size: ${fontsize}pt;"] \
         -optional \
         -focus
    ossweb::widget form_compose.upload -type file -label "File" -optional
    ossweb::widget form_compose.view -type button -label "Messages" \
         -url [mail_url cmd view] \
         -class osswebSmallButton
    ossweb::widget form_compose.compose -type button -label "Compose" \
         -url [mail_url cmd compose] \
         -class osswebSmallButton
    ossweb::widget form_compose.send -type submit -name cmd -label "Send" \
         -class osswebSmallButton
    ossweb::widget form_compose.attach -type submit -name cmd -label "Attach" \
         -class osswebSmallButton
    ossweb::widget form_compose.clear -type submit -name cmd -label "Clear" \
         -class osswebSmallButton
    ossweb::widget form_compose.toggle -type button -name cmd -label "Mark" \
         -html { onClick "toggle(this.form,'file')" } \
         -class osswebSmallButton
}

ossweb::conn::callback create_form_prefs {} {

    ossweb::form form_prefs -title "Mail Preferences"
    ossweb::widget form_prefs.ctx -type hidden -value update -freeze
    ossweb::widget form_prefs.cmd -type hidden -value prefs -freeze
    ossweb::widget form_prefs.sound -type soundselect -label "New Mail Sound" -optional
    ossweb::widget form_prefs.refresh -datatype integer \
         -html { size 5 } -label "Auto refresh interval (secs)" -optional
    ossweb::widget form_prefs.pagesize -datatype integer \
         -html { size 5 } -label "Messages per page" -optional
    ossweb::widget form_prefs.linesize -datatype integer \
         -html { size 5 } -label "Message line size" -optional
    ossweb::widget form_prefs.sort -type select \
         -label "Message Sort Order" -optional \
         -options { { Date 0date } { "Date Reverse" 1date }
                    { Subject 0subject } { "Subject Reverse" 1subject }
                    { From 0from } { "From Reverse" 1from }
                    { Size 0size } { "Size Reverse" 1size } }
    ossweb::widget form_prefs.editsize -datatype integer \
         -html { size 5 } -label "Size of editor textarea" -optional
    ossweb::widget form_prefs.fontsize -datatype integer \
         -html { size 5 } -label "Font size for editor textarea" -optional
    ossweb::widget form_prefs.sent_mailbox -type select \
         -label "Sent Folder" -optional \
         -options [mail_folders $conn_id {"None" ""}]
    ossweb::widget form_prefs.trash_mailbox -type select \
         -label "Trash Folder" -optional \
         -options [mail_folders $conn_id {"None" ""}]
    ossweb::widget form_prefs.from -type text \
         -label "Email" -optional
    ossweb::widget form_prefs.reply_to -type text \
         -label "Reply To" -optional
    ossweb::widget form_prefs.auto_abook -type boolean \
         -label "Auto add emails to Address Book" -optional
    ossweb::widget form_prefs.signature -type textarea \
         -html { cols 40 rows 4 } -label "Signature" -optional
    ossweb::widget form_prefs.update -type submit -label Update
}

ossweb::conn::callback create_form_abook {} {

    ossweb::form form_abook -title "Address Book Management"
    ossweb::widget form_abook.contact_id -type hidden -optional
    ossweb::widget form_abook.cmd -type hidden -value view -freeze
    ossweb::widget form_abook.return -type hidden -optional
    if { ${ossweb:cmd} == "abook2" } {
      ossweb::widget form_abook.public -type radio -label "Book Type" \
           -optional \
           -options { { Personal N } { Public Y } }
      ossweb::widget form_abook.close -type button -label Close \
           -html { onClick "window.close()" }
    }
    ossweb::widget form_abook.email -label "E-mail" -optional
    ossweb::widget form_abook.first_name -label "First Name" -optional
    ossweb::widget form_abook.last_name -label "Last Name" -optional
    ossweb::widget form_abook.description -type textarea -label "Description" \
         -html { rows 3 cols 50 } -optional
    ossweb::widget form_abook.search -type button -label Search \
         -cmd_name ${ossweb:cmd}.search
    ossweb::widget form_abook.update -type button -label Add -cmd_name abook.update
    ossweb::widget form_abook.reset -type reset -label Reset -clear
    # Allow only search in non-full mode
    if { ${ossweb:cmd} != "abook" || $contact_id <= 0 } { return }
    ossweb::widget form_abook.update -type button -label Update -cmd_name abook.update
    ossweb::widget form_abook.delete -type button -label Delete -cmd_name abook.delete
}

ossweb::conn::callback create_form_folders {} {

    ossweb::form form_folders -title "Folder Management"
    ossweb::widget form_folders.cmd -type hidden -value view -freeze
    ossweb::widget form_folders.folder -type select -label "Existing Folders" -optional
    ossweb::widget form_folders.name -label "New Folder" -optional
    ossweb::widget form_folders.create -type button -label Create \
         -cmd_name folders.create
    ossweb::widget form_folders.rename -type button -label Rename \
         -cmd_name folders.rename
    ossweb::widget form_folders.delete -type button -label Delete \
         -cmd_name folders.delete
}

set columns { conn_id int ""
              mailbox "" "INBOX"
              mailaccess const ""
              mailuser const ""
              msg_id "" ""
              part_id "" ""
              sort "" "1date"
              page int 1
              contact_id int ""
              Version const "OSSWEB WebMail 1.3"
              pagesize int 30
              linesize int 80
              fontsize int "12"
              editsize int 80
              refresh int 120
              sort "" "1date"
              sound "" ""
              signature "" ""
              sent_mailbox "" ""
              trash_mailbox "" ""
              auto_abook "" "Y"
              from "" ""
              reply_to "" ""
              first_name "" ""
              last_name "" ""
              email "" ""
              use_tiny_mce const 0 }

ossweb::conn::process \
           -columns $columns \
           -on_error_set_cmd "" \
           -on_error { -cmd_name login -ctx_name error } \
           -form_recreate t \
           -exec {
                if { [catch { mail_init } errMsg] } {
                  if { [string range $errMsg 0 6] == "OSSWEB:" } {
                    set errMsg [string range $errMsg 7 end]
                  } else {
                    ns_log Debug mail::init ${ossweb:page}: $mailuser: $errMsg
                  }
                  ossweb::conn::set_msg -color red $errMsg
                  ossweb::conn::next -cmd_name login -ctx_name error
                }
           } \
           -eval {
             login {
               -forms form_login
               -exec { mail_action }
             }
             login.error {
               -forms form_login
               -exec {}
             }
             logout {
               -exec { mail_action }
               -next { -app_name index index }
             }
             clear -
             attach -
             reply -
             replyall -
             forward {
               -forms form_compose
               -exec { mail_action }
               -next { -cmd_name compose }
               -on_error_set_cmd compose
               -on_error { -cmd_name view }
             }
             returnreceipt -
             prev -
             next {
               -exec { mail_action }
               -next { -cmd_name edit }
               -on_error { -cmd_name view }
             }
             delete -
             mark -
             move -
             goto {
               -exec { mail_action }
               -next { -cmd_name view }
               -on_error { -cmd_name view }
             }
             send {
               -forms form_compose
               -exec { mail_action }
               -next { -cmd_name view }
               -on_error_set_cmd compose
               -on_error { -cmd_name compose }
             }
             compose {
               -forms { form_compose }
               -exec { mail_compose }
               -on_error { -cmd_name view }
             }
             prefs {
               -forms { form_view form_prefs }
               -exec { mail_prefs_action }
               -on_error { -cmd_name prefs -ctx_name view }
             }
             folders {
               -forms { form_view form_folders }
               -exec { mail_folders_action }
               -on_error { -cmd_name view }
             }
             abook2 {
               -forms { form_abook }
               -exec { mail_abook_action }
               -on_error { -cmd_name error }
             }
             abook {
               -forms { form_view form_abook }
               -exec { mail_abook_action }
               -on_error { -cmd_name abook -ctx_name error }
             }
             file {
               -exec { mail_action }
               -on_error { -cmd_name error }
             }
             edit {
               -forms { form_edit }
               -exec { mail_edit }
               -on_error { -cmd_name view }
             }
             error {
             }
             default {
               -forms form_view
               -exec { mail_view }
             }
           }
