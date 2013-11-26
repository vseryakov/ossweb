# Author: Vlad Seryakov vlad@crystalballinc.com 
# March 2003

# Update user record with only specified columns
proc user_update { user_email args } {

    if { $user_email == "" } { return }
    foreach { name value } $args { set $name $value }
    if { [ossweb::db::exec sql:maverix.user.update] } {
      ossweb::conn::set_msg -color red "Unable to update user record"
    }
}

# Update last time user updated senders/msgs from the digest
proc digest_update { user_email { drop 0 } } {

    set digest_count 0
    set digest_update [ossweb::date now]
    return [ossweb::db::exec sql:maverix.user.update]
}

# Update sender type
proc sender_update { cmd user_email sender_email } {

    ns_log Debug Update: $cmd, u=$user_email, s=$sender_email
    
    switch -- [string index $cmd 1] {
     a {
        switch -- [string index $cmd 0] {
         w { set sender_type PASS }
         b { set sender_type DROP }
         g { set sender_type VRFY }
        }
        if { [set sender_email [string trim $sender_email]] == "" } {
          ossweb::conn::set_msg -color red "Invalid email address"
          return
        }
        if { [ossweb::db::value sql:maverix.sender.check.email] != "" } {
          ossweb::conn::set_msg -color red "Sender $sender_email already exists"
          return
        }
        # Treat as domain if not valid email address
        set sender_email [string trim $sender_email *@]
        if { [string first @ $sender_email] == -1 } { set sender_email @$sender_email }
        if { [ossweb::db::exec sql:maverix.sender.create] } {
          ossweb::conn::set_msg -color red "Unable to add sender $sender_email"
          return
        }
        digest_update $user_email
        maverix::cache::sender_set $user_email $sender_email $sender_type
        ossweb::conn::set_msg "Sender $sender_email has been added"
        return t
     }
     
     d {
        if { [ossweb::db::exec sql:maverix.sender.delete] } {
          ossweb::conn::set_msg -color red "Unable to delete sender $sender_email"
          return
        }
        digest_update $user_email
        maverix::cache::sender_flush $user_email $sender_email
        ossweb::conn::set_msg "Sender $sender_email has been deleted"
        return t
     }
     
     c {
        switch -- [string index $cmd 0] {
         w { set sender_type PASS }
         b { set sender_type DROP }
         g { set sender_type VRFY }
        }
        if { [ossweb::db::exec sql:maverix.sender.delete.by.user] } {
          ossweb::conn::set_msg -color red "Unable to delete senders"
          return
        }
        digest_update $user_email
        maverix::cache::sender_flush $user_email $sender_type
        ossweb::conn::set_msg "Senders have been deleted"
        return t
     }
     
     w -
     b -
     g {
        switch -- [string index $cmd 1] {
         w { set sender_type PASS }
         b { set sender_type DROP }
         g { set sender_type VRFY }
        }
        if { [ossweb::db::exec sql:maverix.sender.update.type] } {
          ossweb::conn::set_msg -color red "Unable to update sender $sender_email "
          return
        }
        digest_update $user_email
        maverix::cache::sender_set $user_email $sender_email $sender_type
        ossweb::conn::set_msg "Sender $sender_email has been updated"
        return t
     }
    }
}

set cmd [string tolower [ns_queryget c]]
set user_digest [ns_queryget d]
set sender_list [ns_querygetall s]
set message_list [ns_querygetall m]
set messages:rowcount 0
set senders:rowcount 0
set quiet_flag f
set session_flag f

# Command preprocessing
switch -- $cmd {
 login {
   if { [set user_name [ns_queryget u]] == "" || [set user_password [ns_queryget p]] == "" } {
     return
   }
   set columns ""
   if { ![ossweb::db::multivalue sql:maverix.user.read] && $user_password == $password } {
     set session_flag t
   } else {
     # Try POP3 authentication and save username/password in the local table
     if { [set host [ossweb::config maverix:hostname:pop3]] != "" &&
          [set user_email $user_name] != "" &&
          ![ossweb::db::multivalue sql:maverix.user.read] &&
          [ossweb::auth::pop3 $user_email $user_password -host $host] == 0 } {
       set session_flag t
       append columns "user_name {$user_email} password {$user_password}"
     }
   }
   switch $session_flag {
    t {
      ossweb::conn::set_session_id -user_id $user_email -cookie MVRX_SID
      eval user_update $user_email session_id "{[ossweb::conn session_id] [ns_conn peeraddr]}" $columns
      set cmd v
    }
    default {
      ossweb::conn::set_msg -color red "Username or password incorrect, please try again"
      ns_log Debug Login: [ns_conn peeraddr]: u=$user_name
      set cmd login
      return
    }
   }
 }
 logout {
   ossweb::conn::set_session_id -clear t -cookie MVRX_SID
   user_update [ns_queryget u] session_id NULL
   set cmd login
   return
 }
 "permit checked" {
   set cmd sv
   set quiet_flag t
   foreach id [ns_querygetall i] {
     regsub -all {[\{\}]} $id {} id
     lappend sender_list [lindex $id 0]
     lappend messsage_list [lindex $id 1]
   }
 }
 "block checked" {
   set cmd sb
   set quiet_flag t
   foreach id [ns_querygetall i] {
     regsub -all {[\{\}]} $id {} id
     lappend sender_list [lindex $id 0]
     lappend messsage_list [lindex $id 1]
   }
 }
 "forward checked" {
   set cmd mf
   set quiet_flag t
   foreach id [ns_querygetall i] { 
     regsub -all {[\{\}]} $id {} id
     lappend message_list [lindex $id 1] 
   }
 }
 "drop checked" {
   set cmd md
   set quiet_flag t
   foreach id [ns_querygetall i] { 
     regsub -all {[\{\}]} $id {} id
     lappend message_list [lindex $id 1] 
   }
 }
}

# Session authentication
if { $session_flag == "f" &&
     [set user_email [lindex [ossweb::conn::signed_cookie MVRX_SID] 1]] != "" &&
     [ossweb::db::multivalue sql:maverix.user.read] == 0 &&
     [ossweb::conn -set oss_session_id [lindex $session_id 0]] != "" &&
     [ossweb::conn::parse_session $user_email -cookie MVRX_SID] != "" &&
     [lindex $session_id 1] == [ns_conn peeraddr] } {
  set session_flag t
  # parse_session set user_id with user email
  ossweb::conn -unset user_id
}

# Digest authentication
if { $session_flag == "f" } {
  if { [set user_email [ns_queryget u]] == "" ||
       [ossweb::db::multivalue sql:maverix.user.read] || 
       $user_digest != $digest_id } {
    ossweb::conn::set_msg -color red \
         "Sorry, that verification request in invalid, 
          Please check for a more recent verification URL or
          if you have username and password you may login
          into the Maverix at any time."
    ns_log Debug User: $cmd, u=$user_email, d=$user_digest, error
    set cmd login
    return
  }
  # Check for stale digest
  if { [ns_time] - $digest_time > [ossweb::config maverix:stale 86400] } {
    ossweb::conn::set_msg -color red \
         "Sorry, this verification URL has expired,
          Please check for a more recent verification URL"
    ns_log Debug User: $cmd, u=$user_email, d=$digest_id, stale
    set cmd login
    return
  }
}

# Build tabs
ossweb::widget form_tab.v -type link -label Messages -notab -value "/maverix/User.oss?c=v&u=$user_email&d=$digest_id"
ossweb::widget form_tab.p -type link -label Properties -notab -value "/maverix/User.oss?c=p&u=$user_email&d=$digest_id"
ossweb::widget form_tab.w -type link -label "White List" -notab -value "/maverix/User.oss?c=w&u=$user_email&d=$digest_id"
ossweb::widget form_tab.b -type link -label "Black List" -notab -value "/maverix/User.oss?c=b&u=$user_email&d=$digest_id"
ossweb::widget form_tab.g -type link -label "Gray List" -notab -value "/maverix/User.oss?c=g&u=$user_email&d=$digest_id"
ossweb::widget form_tab.l -type link -label "Log" -notab -value "/maverix/User.oss?c=l&u=$user_email&d=$digest_id"

switch -- [string index $cmd 0] {

  s {
    # Sender verification
    foreach sender_email $sender_list {
      if { [ossweb::db::multivalue sql:maverix.sender.read] } {
        ns_log Debug User: $cmd, u=$user_email, s=$sender_email, d=$digest_id, sender error
        if { $quiet_flag == "t" } { continue }
        ossweb::conn::set_msg -color red \
             "Sorry, that verification request in invalid, 
              Please check for a more recent verification URL"
        return
      }
      ns_log Debug User: $cmd, u=$user_email, s=$sender_email, d=$digest_id, ok
    
      switch -- $cmd {
       sv {
         # Verify status
         if { $sender_type == "PASS" } {
           ossweb::conn::set_msg -color red "$sender_email has already been verified"
         } else {
           set digest_id ""
           set sender_type PASS
           set sender_method Verified
           ossweb::db::exec sql:maverix.sender.update.type
           maverix::cache::sender_set $user_email $sender_email $sender_type
           digest_update $user_email
           ossweb::conn::set_msg "Sender $sender_email has been verified"
         }
       }
  
       svd {
         set digest_id ""
         set sender_type PASS
         set sender_method Verified
         ossweb::db::exec sql:maverix.sender.update.type
         maverix::cache::sender_set $user_email $sender_email $sender_type
         # Verify the whole domain
         set domain [lindex [split $sender_email @] 1]
         set sender_email @[join [lrange [split $domain .] end-1 end] .]
         ossweb::db::exec sql:maverix.sender.update.type
         if { ![ossweb::db::rowcount] } {
           ossweb::db::exec sql:maverix.sender.create
         }
         maverix::cache::sender_set $user_email $sender_email $sender_type
         digest_update $user_email 1
         ossweb::conn::set_msg "Domain $sender_email has been verified"
       }
       
       sb {
         # Verify status
         if { $sender_type == "DROP" } {
           ossweb::conn::set_msg -color red "You have already dropped $sender_email"
         } else {
           set digest_id ""
           set sender_type DROP
           set sender_method Blocked
           ossweb::db::exec sql:maverix.sender.update.type
           maverix::cache::sender_set $user_email $sender_email $sender_type
           digest_update $user_email 1
           ossweb::conn::set_msg "Sender $sender_email has been blocked"
         }
       }

       sbd {
         set digest_id ""
         set sender_type DROP
         set sender_method Blocked
         ossweb::db::exec sql:maverix.sender.update.type
         maverix::cache::sender_set $user_email $sender_email $sender_type
         # Block the whole domain
         set domain [lindex [split $sender_email @] 1]
         set sender_email @[join [lrange [split $domain .] end-1 end] .]
         ossweb::db::exec sql:maverix.sender.create
         maverix::cache::sender_set $user_email $sender_email $sender_type
         digest_update $user_email 1
         ossweb::conn::set_msg "Domain $sender_email has been blocked"
       }
      }
    }
    # Flush user's list cache
    ossweb::cache flush "*senders*user_email=$user_email*"
    if { $spam_autolearn_flag == "t" } {
      switch -- $cmd {
       sv - svd { ns_schedule_proc -once 0 "maverix::trainSpam $user_email {$message_list} 0" }
       sb - sbd { ns_schedule_proc -once 0 "maverix::trainSpam $user_email {$message_list} 1" }
      }
    }
  }
  
  m {
    # Message verification
    foreach msg_id $message_list {
      if { ![string is integer -strict $msg_id] } { continue }
      if { [ossweb::db::multivalue sql:maverix.user.message.read] } {
        ns_log Debug User: $cmd, u=$user_email, m=$msg_id, d=$digest_id, msg error
        if { $quiet_flag == "t" } { continue }
        ossweb::conn::set_msg -color red \
             "Sorry, that verification request in invalid, or
              the message has been already dropped or forwarded.
              Please check for a more recent verification URL"
        return
      }
      ns_log Debug User: $cmd, u=$user_email, m=$msg_id, d=$digest_id, ok

      switch -- $cmd {
       md {
         # Verify status
         if { $msg_status == "DROP" } {
           ossweb::conn::set_msg -color red "You have already dropped this message"
         } else {
           set msg_status DROP
           ossweb::db::exec sql:maverix.user.message.update.status
           digest_update $user_email 1
           ossweb::conn::set_msg "Message from $sender_email has been dropped"
         }
       }

       mf {
         # Verify status
         if { $msg_status == "PASS" } {
           ossweb::conn::set_msg -color red "You have already forwarded this message"
         } else {
           set msg_status PASS
           ossweb::db::exec sql:maverix.user.message.update.status
           digest_update $user_email
           ossweb::conn::set_msg "Message from $sender_email has been forwarded"
         }
       }
      }
    }
    if { $spam_autolearn_flag == "t" } {
      switch -- $cmd {
       mf { ns_schedule_proc -once 0 "maverix::trainSpam $user_email {$message_list} 0" }
       md { ns_schedule_proc -once 0 "maverix::trainSpam $user_email {$message_list} 1" }
      }
    }
  }
  
  p {
    # Preferences
    ossweb::form form_prefs -action User.oss
    ossweb::widget form_prefs.c -type hidden -value pu -freeze
    ossweb::widget form_prefs.u -type hidden -value $user_email -freeze
    ossweb::widget form_prefs.d -type hidden -value $digest_id -freeze
    ossweb::widget form_prefs.user_email -type inform -value $user_email
    ossweb::widget form_prefs.user_type -type radio \
         -optional \
         -options { { "Put unknown email on hold for verification" VRFY } 
                    { "I want all email pass through directly to my mailbox" PASS }
                    { "Drop unknown emails, pass known emails through" SKIP } }
    ossweb::widget form_prefs.digest_interval -type select \
         -optional \
         -empty -- \
         -options { { "5 Minutes" 300 }
                    { "10 Minutes" 600 }
                    { "15 Minutes" 900 }
                    { "30 Minutes" 1800 }
                    { "1 Hour" 3600 }
                    { "2 Hours" 7200 }
                    { "3 Hours" 10800 }
                    { "6 Hours" 21600 }
                    { "12 Hours" 43200 }
                    { "1 Day" 86400 }
                    { "2 Days" 172800 }
                    { "3 Days" 259200 } 
                    { "5 Days" 432000 } 
                    { "7 Days" 604800 } 
                  }
    ossweb::widget form_prefs.digest_start -type date \
         -optional \
         -format "HH24 : MI" \
         -html { size 8 }
    ossweb::widget form_prefs.digest_end -type date \
         -optional \
         -format "HH24 : MI" \
         -html { size 8 }
    ossweb::widget form_prefs.sender_digest_flag -type radio \
         -optional \
         -options { { "Yes, Allow unknown senders to perform self-verification" t }
                    { "No, I will verify unknown senders by myself" f } }
    ossweb::widget form_prefs.anti_virus_flag -type radio \
         -optional \
         -options { { "Perform anti-virus verification for all messages" VRFY }
                    { "Drop the message if virus detected" DROP }
                    { "Pass all messages without anti-virus verification" PASS } }
    ossweb::widget form_prefs.page_size -type text \
         -optional \
         -datatype integer \
         -html { size 6 }
    ossweb::widget form_prefs.body_size -type text \
         -optional \
         -datatype integer \
         -html { size 6 }
    ossweb::widget form_prefs.user_name -type text \
         -optional \
         -html { size 12 }
    ossweb::widget form_prefs.password -type password \
         -optional \
         -html { size 12 }
    ossweb::widget form_prefs.spam_status -type checkbox \
         -optional \
         -options { { "Automatically drop message if identified as SPAM" Spam } }
    ossweb::widget form_prefs.spam_autolearn_flag -type checkbox \
         -optional \
         -options { { "Allow anti-spam tool to train its database" t } }
    ossweb::widget form_prefs.spam_score_white -type select \
         -optional \
         -empty -- \
         -options [maverix::spamScores]
    ossweb::widget form_prefs.spam_score_black -type select \
         -optional \
         -empty -- \
         -options [maverix::spamScores]
    ossweb::widget form_prefs.spam_subject -type textarea \
         -optional \
         -resize \
         -html { wrap off cols 70 rows 3 }
    ossweb::widget form_prefs.update -type submit -label Update
    if { [ossweb::conn session_id] != "" } {
      ossweb::widget form_prefs.logout -type button -label Logout \
           -url "window.location='User.oss?c=logout&u=$user_email&d=$digest_id'"
    }
    ossweb::widget form_prefs.help -type button -label Help \
         -window MavHelp \
         -winopts "width=800,height=600,menubar=0,scrollbars=1,location=0" \
         -url http://www.maverixsystems.com/maverixuserguide.htm
    
    switch -- $cmd {
     pu {
       ossweb::form form_prefs get_values
       set spam_subject [string map { "\n" {} "\r" {} "\t" {} } $spam_subject]
       if { [ossweb::db::exec sql:maverix.user.update.prefs] } {
         ossweb::conn::set_msg -color red "Unable to update preferances"
       } else {
         ns_log Debug User: $cmd, u=$user_email, d=$digest_id, ok
       }
       maverix::cache::user_flush $user_email
     }
    }
    ossweb::form form_prefs set_values
    set cmd p
    return
  }
  
  w - b - g {
    # White, black gray lists
    set force [sender_update $cmd $user_email [ns_queryget s]]
    set page [ns_queryget page 1]
    set sort [ns_queryget st]
    set _url "User.oss?u=[ns_urlencode $user_email]&d=$digest_id"
    set url "$_url&st=$sort"
    # Search 
    if { [string index $cmd 1] == "s" } { set sender_email [ns_queryget s] }
    switch -- [string index $cmd 0] {
     w {
       set cmd w
       set sender_type PASS
       set sender_list White
     }
     b {
       set cmd b
       set sender_type DROP
       set sender_list Black
     }
     g {
       set cmd g
       set sender_type VRFY
       set sender_list Gray
     }
    }
    ossweb::form form_sender -action User.oss
    ossweb::widget form_sender.c -type hidden -value ${cmd}s -freeze
    ossweb::widget form_sender.u -type hidden -value $user_email -freeze
    ossweb::widget form_sender.d -type hidden -value $digest_id -freeze
    ossweb::widget form_sender.st -type hidden -value $sort -freeze
    ossweb::widget form_sender.s -type text -label Email -optional
    ossweb::widget form_sender.page -type hidden -value $page -freeze
    ossweb::widget form_sender.add -type button -label Add \
         -html [list onClick "this.form.c.value='${cmd}a';this.form.submit()"]
    ossweb::widget form_sender.search -type button -label Search \
         -html [list onClick "this.form.c.value='${cmd}s';this.form.submit()"]
    ossweb::widget form_sender.help -type button -label Help \
         -window MavHelp \
         -winopts "width=800,height=600,menubar=0,scrollbars=1,location=0" \
         -url http://www.maverixsystems.com/maverixuserguide.htm
    ossweb::widget form_sender.clear -type link -label Clear \
         -value "$url&c=${cmd}c" \
         -notab \
         -html { onClick "return confirm('All senders from this list will be deleted, continue?')" }
    ossweb::db::multipage senders sql:maverix.user.sender.search1 \
                               sql:maverix.user.sender.search2 \
                               -page $page \
                               -pagesize $page_size \
                               -cmd c \
                               -datatype str \
                               -cmd_name $cmd \
                               -url $url \
                               -force $force \
                               -eval {
      set row(edit) ""
      switch -- $cmd {
       w {
         append row(edit) "<A HREF=$url&c=wb&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:blue\">Block</A>" "&nbsp;"
         append row(edit) "<A HREF=$url&c=wg&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:black\">Pend</A>" "&nbsp;"
         append row(edit) "<A HREF=$url&c=wd&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:red\">Delete</A>"
       }
       b {
         append row(edit) "<A HREF=$url&c=bw&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:green\">Permit</A>" "&nbsp;"
         append row(edit) "<A HREF=$url&c=bg&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:black\">Pend</A>" "&nbsp;"
         append row(edit) "<A HREF=$url&c=bd&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:red\">Delete</A>"
       }
       g {
         append row(edit) "<A HREF=$url&c=gw&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:green\">Permit</A>" "&nbsp;"
         append row(edit) "<A HREF=$url&c=gb&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:blue\">Block</A>" "&nbsp;"
         append row(edit) "<A HREF=$url&c=gd&s=[ns_urlencode $row(sender_email)]&page=$page STYLE=\"color:red\">Delete</A>"
       }
      }
    }
    return
  }
  
  l {
    ossweb::db::multirow log sql:maverix.sender.log.list -eval {
      set row(subject) [maverix::decodeHdr $row(subject)]
    }
    return
  }
}
# Show remaining unverified messages
set cmd v
ossweb::form form_user -action User.oss
ossweb::widget form_user.u -type hidden -value $user_email -freeze
ossweb::widget form_user.d -type hidden -value $user_digest -freeze
set url User.oss?u=[ns_urlencode $user_email]
ossweb::db::multirow messages sql:maverix.user.message.list -eval {
  set subject [maverix::decodeHdr $row(subject)]
  set row(body) [string range $row(body) $row(body_offset) end]
  # Strip off MIME headers
  regexp -nocase {Content-Type:[^\n]+(.+)} $row(body) d row(body)
  set row(subject) [ossweb::util::wrap_text [ns_quotehtml $subject] -size 40 -break <BR>]
  set row(body) [ossweb::util::wrap_text [ns_striphtml $row(body)] -size 60 -break <BR>]
  set row(sender_verify) $url&d=$row(digest_id)&s=[ns_urlencode $row(sender_email)]&m=$row(msg_id)&c=sv
  set row(domain_verify) $url&d=$row(digest_id)&s=[ns_urlencode $row(sender_email)]&m=$row(msg_id)&c=svd
  set row(sender_block) $url&d=$row(digest_id)&s=[ns_urlencode $row(sender_email)]&m=$row(msg_id)&c=sb
  set row(domain_block) $url&d=$row(digest_id)&s=[ns_urlencode $row(sender_email)]&m=$row(msg_id)&c=sbd
  set row(message_forward) $url&d=$row(digest_id)&s=[ns_urlencode $row(sender_email)]&m=$row(msg_id)&c=mf
  set row(message_drop) $url&d=$row(digest_id)&s=[ns_urlencode $row(sender_email)]&m=$row(msg_id)&c=md
  set row(sender) [ossweb::util::wrap_text $row(sender_email) -size 40 -break <BR>]
}

