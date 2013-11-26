# Author: Vlad Seryakov vlad@crystalballinc.com 
# March 2003

namespace eval maverix {

   variable version "Maverix version 2.5.1"
   
   namespace eval handler {}
   namespace eval html {}
   namespace eval http {}
   namespace eval cache {}
   namespace eval schedule {}
}

proc maverix::init {} {

    set args ""
    if { [regexp {^([0-9]+)([bBkKmM]*)$} [ossweb::config maverix:cache:size] d size type] } {
      switch -- [string toupper $type] {
       K { set args "-size [expr $size*1024]" }
       M { set args "-size [expr $size*1024*1024]" }
       default { set args "-size $size" }
      }
    }
    eval ossweb::cache::create maverix:user $args
    eval ossweb::cache::create maverix:sender $args
    eval ossweb::cache::create maverix:domain $args

    maverix::cache::init
    maverix::initconfig
    # If called too early i.e. no config loaded from the db, rescheule again
    if { [ns_smtpd relay get] == "" } {
      ns_schedule_proc -once 5 maverix::initconfig
    }
    if { ![ossweb::true [ossweb::config maverix:stop]] } {
      ns_thread begindetached maverix::schedule::digest
      ns_thread begindetached maverix::schedule::sender
      ns_thread begindetached maverix::schedule::deliver
    }
}

proc maverix::initconfig {} {

    eval ns_smtpd relay set [string map { \r {} \n { } } [ossweb::config maverix:domain:relay]]
    ns_log notice maverix::init: Relay Domains: [ns_smtpd relay get]
    eval ns_smtpd local set [string map { \r {} \n { } } [ossweb::config maverix:domain:local]]
    ns_log notice maverix::init: Local Domains: [ns_smtpd local get]
}

# Shutdowns the server
proc maverix::shutdown { { timeout 1 } } {

    maverix::cache::flush
    ns_shutdown $timeout
}

# Generate new unique digest id
proc maverix::digest { { data "" } } {

    return [ns_sha1 [ns_rand 10000000][ns_time]$data]
}

# Decode message header
proc maverix::decodeHdr { str } {

    set b [string first "=?" $str]
    if { $b >= 0 } {
      set b [string first "?" $str [expr $b+2]]
      if { $b > 0 } {
        set e [string first "?=" $str $b]
        if { $e == -1 } { set e end } else { incr e -1 }
        switch [string index $str [expr $b+1]] {
         Q {
           set str [ns_smtpd decode qprint [string range $str [expr $b+3] $e]]
         }
         B {
           set str [ns_smtpd decode base64 [string range $str [expr $b+3] $e]]
         }
        }
      }
    }
    return $str
}

# Parses bounces
proc maverix::decodeBounce { id body } {

    set sender_email ""
    set filters { 
        {The following addresses had permanent fatal errors -----[\r\n]+<?([^>\r\n]+)} {}
        {The following addresses had permanent delivery errors -----[\r\n]+<?([^>\r\n]+)} {}
        {The following addresses had delivery errors---[\r\n]+<?([^> \r\n]+)} {}
        {<([^>]+)>:[\r\n]+Sorry, no mailbox here by that name.} {}
        {Your message.+To:[ \t]+([^ \r\n]+)[\r\n]+.+did not reach the following recipient} {}
        {Your message cannot be delivered to the following recipients:.+Recipient address: ([^ \r\n]+)} {}
        {Failed addresses follow:.+<([^>]+)>} {}
        {[\r\n]+([^ \t]+) - no such user here.} {}
        {qmail-send.+permanent error.+<([^>]+)>:} {}
        {Receiver not found: ([^ \r\n\t]+)} {%s@compuserve.com}
        {Failed to deliver to '<([^>]+)>'} {}
        {The following address\(es\) failed:[\r\n\t ]+([^ \t\r\n]+)} {}
        {User<([^>]+)>.+550 Invalid recipient} {}
        {Delivery to the following recipients failed.[\r\n\t ]+([^ \t\r\n]+)} {}
        {<([^>]+)>:[\r\n]+Sorry.+control/locals file, so I don't treat it as local} {}
        {RCPT To:<([^>]+)>.+550} {}
        {550.*<([^>]+)>... User unknown} {}
        {550.*unknown user <([^<]+)>} {}
        {could not be delivered.+The .+ program[^<]+<([^<]+)>} {}
        {The following text was generated during the delivery attempt:------ ([^ ]+) ------} {}
        {The following addresses were not valid[\r\n\t ]+<([^>]+)>} {}
        {These addresses were rejected:[\r\n\t ]+([^ \t\r\n]+)} {}
        {Unexpected recipient failure - 553 5.3.0 <([^>]+)>} {}
        {not able to deliver to the following addresses.[\r\n\t ]+<([^>]+)>} {}
        {cannot be sent to the following addresses.[\r\n\t ]+<([^>]+)>} {}
        {was not delivered to:[\r\n\t ]+([^ \r\n]+)} {}
        {<([^>]+)>  delivery failed; will not continue trying} {}
        {User mailbox exceeds allowed[^:]+: ([^ \n\r\t]+)} {}
        {could not be delivered[^<]+<([^>]+)>:} {}
        {undeliverable[^<]+<([^@]+@[^>]+)>} {}
        {could not be delivered.+Bad name:[ \t]+([^ \r\n\t]+)} {%s@oracle.com}
    }

    foreach { filter data } $filters {
      if { [regexp -nocase $filter $body d sender_email] } { 
        if { $data != "" } { set sender_email [format $data $sender_email] }
        break
      }
    }
    if { $sender_email != "" } {
      foreach rcpt [ns_smtpd getrcpt $id] {
        foreach { user_email user_flags spam_score } $rcpt {}
        ns_log Error maverix::decodeBounce: $id: $user_email: $sender_email
        maverix::cache::sender_drop $user_email $sender_email
      }
    }
    catch {
      if { $sender_email == "" } {
        set fd [open /tmp/maverix.bounces a]
        puts $fd "$body\n\n"
        close $fd
      }
    }
    return $sender_email
}

# Mailing list/Sender detection
proc maverix::decodeSender { id } {

    set From [ns_smtpd getfrom $id]
    if { [set List [ns_smtpd checkemail [ns_smtpd gethdr $id List-Id]]] != "" &&
         [regexp {<([^>]+)>} $List d List] } {
      return [list @$List f]
    }
    if { [set Sender [ns_smtpd checkemail [ns_smtpd gethdr $id Sender]]] != "" } {
      return [list $Sender f]
    }
    if { [set ReplyTo [ns_smtpd checkemail [ns_smtpd gethdr $id Reply-To]]] != "" && $ReplyTo != $From } {
      return [list $ReplyTo f]
    }
    if { [set XSender [ns_smtpd checkemail [ns_smtpd gethdr $id X-Sender]]] != "" } {
      return [list $XSender f]
    }
    # Try for old/obsolete mailing lists
    if { [ns_smtpd gethdr $id Mailing-List] != "" ||
         [ns_smtpd gethdr $id List-Help] != "" ||
         [ns_smtpd gethdr $id List-Unsubscribe] != "" ||
         [ns_smtpd gethdr $id Precedence] == "bulk" ||
         [ns_smtpd gethdr $id Precedence] == "list" } {
      return [list [ossweb::nvl $ReplyTo $From] f]
    }
    return [list $From ""]
}

# Returns 1 if email is internal maverix email
proc maverix::bouncedEmail { email } {

    if { $email == [ossweb::config maverix:user:admin] ||
         $email == [ossweb::config maverix:sender:admin] } {
      return 1
    }
    return 0
}

# Train anti-spam tool, type is: 1 - spam, 0 - not spam
proc maverix::trainSpam { user_email msg_list type { body "" } { signature "" } } {

    if { [set antispam [ns_smtpd spamversion]] == "" } { return }

    foreach msg_id $msg_list {
      if { $body == "" } { ossweb::db::multivalue sql:maverix.message.read.body }
      switch -- $antispam {
       DSPAM {
         ns_log Notice maverix::trainSpam: $user_email $msg_id: [ns_smtpd trainspam $type $user_email $body $signature]
       }
       
       SpamAssassin {
         set file /tmp/$msg_id.txt
         ossweb::write_file $file $body
         catch { exec cat $file | sa-learn --[ossweb::decode $type 1 spam ham] --no-rebuild }
         file delete -force -- $file
       }
      }
    }
}

proc maverix::spamScores {} {

    switch -- [ns_smtpd spamversion] {
     DSPAM {
       return { { 0 0 }
                { 0.1 0.1 } { 0.13 0.13 } { 0.15 0.15 } { 0.17 0.17 } { 0.19 0.19 }
                { 0.2 0.2 } { 0.23 0.23 } { 0.25 0.25 } { 0.27 0.27 } { 0.29 0.29 }
                { 0.3 0.3 } { 0.33 0.33 } { 0.35 0.35 } { 0.37 0.37 } { 0.39 0.39 }
                { 0.4 0.4 } { 0.43 0.43 } { 0.45 0.45 } { 0.47 0.47 } { 0.49 0.49 }
                { 0.5 0.5 } { 0.53 0.53 } { 0.55 0.55 } { 0.57 0.57 } { 0.59 0.59 }
                { 0.6 0.6 } { 0.63 0.63 } { 0.65 0.65 } { 0.67 0.67 } { 0.69 0.69 }
                { 0.7 0.7 } { 0.73 0.73 } { 0.75 0.75 } { 0.77 0.77 } { 0.79 0.79 }
                { 0.8 0.8 } { 0.83 0.83 } { 0.85 0.85 } { 0.87 0.87 } { 0.89 0.89 }
                { 0.9 0.9 } { 0.93 0.93 } { 0.95 0.95 } { 0.97 0.97 } { 0.99 0.99 }
                { 1 1 } }
     }
     
     SpamAssassin {
       return { { -1 -1 }
                { 0 0 } { 1 1 } { 2 2 } { 3 3 } { 4 4 } { 5 5 } { 6 6 } { 7 7 } { 8 8 } { 9 9 } { 10 10 }
                { 11 11 } { 12 12 } { 13 13 } { 14 14 } { 15 15 } }
     }
    }
}

proc maverix::handler::HELO { id } {}

proc maverix::handler::MAIL { id } {}

proc maverix::handler::RCPT { id } {

    # Current recipient
    foreach { user_email user_flags spam_score } [ns_smtpd getrcpt $id 0] {}
    # Special case: bounces from our digests
    if { [maverix::bouncedEmail $user_email] } { return }
    # Non-relayable user, just pass it through
    if { !($user_flags & [ns_smtpd flag RELAY]) } {
      ns_smtpd setflag $id 0 VERIFIED
      return
    }
    # Search for recipient record
    set user [maverix::cache::user $user_email]
    set user_email [ossweb::nvl [lindex $user 0] $user_email]
    set user_type [lindex $user 1]
    set spam_check_status [lindex $user 2]
    set spam_score_white [lindex $user 3]
    set spam_score_black [lindex $user 4]
    set anti_virus_flag [lindex $user 5]
    switch -- $user_type {
     DROP {
       # User is not allowed to receive any mail
       ns_smtpd setreply $id "550 ${user_email}... User unknown\r\n"
       ns_smtpd delrcpt $id 0
       return
     }
     PASS {
       switch -- $anti_virus_flag {
        VRFY - DROP {
           # Anti-virus verification enabled 
           ns_smtpd setflag $id -1 VIRUSCHECK
           return
        }
       }
       # Spam verification enabled
       if { $spam_check_status != "" || $spam_score_black != "" } {
         ns_smtpd setflag $id 0 SPAMCHECK
         return
       }
       # User is allowed all mail
       ns_smtpd setflag $id 0 VERIFIED
       return
     }
    }
    # Spam verification enabled
    if { $spam_check_status != "" || $spam_score_white != "" || $spam_score_black != "" } {
      ns_smtpd setflag $id 0 SPAMCHECK
    }
    # Search for sender record
    set sender_email [ns_smtpd getfrom $id]
    set sender [maverix::cache::sender $user_email $sender_email]
    set sender_type [lindex $sender 0]
    set reason [lindex $sender 1]
    switch -- $sender_type {
     DROP {
       # Sender is not allowed to send mail here
       ns_smtpd setreply $id "550 ${sender_email}... Sender blocked/$reason\r\n"
       ns_smtpd delrcpt $id 0
       nsv_set maverix:sender:drop $sender_email [ns_time]
       ns_log notice maverix::handler::RCPT: $id: $user_email, dropped $sender_email/$reason
       ossweb::db::exec sql:maverix.sender.log.create
     }
     PASS {
       # User is allowed all mail or this sender is a friend
       ns_smtpd setflag $id 0 VERIFIED
     }
     default {
       switch -- $user_type {
        SKIP {
          # Drop unknown emails
          ns_smtpd setreply $id "550 ${sender_email}... Sender blocked/$reason\r\n"
          ns_smtpd delrcpt $id 0
          nsv_set maverix:sender:drop $sender_email [ns_time]
          ns_log notice maverix::handler::RCPT: $id: $user_email, dropped $sender_email/$reason
          ossweb::db::exec sql:maverix.sender.log.create
        }
       }
     }
    }
    # Anti-virus verification enabled
    switch -- $anti_virus_flag {
     VRFY - DROP {
       ns_smtpd setflag $id -1 VIRUSCHECK
       ns_smtpd unsetflag $id 0 VERIFIED
     }
    }
}

proc maverix::handler::DATA { id } {

    set bounce 0
    set conn_flags [ns_smtpd getflag $id -1]
    set subject [ns_smtpd gethdr $id Subject]
    set signature [ns_smtpd gethdr $id X-Maverix-Signature]
    set virus_status [ns_smtpd gethdr $id X-Maverix-Virus-Status]
    foreach { body body_offset body_size } [ns_smtpd getbody $id] {}
    foreach { sender_email sender_digest_flag } [maverix::decodeSender $id] {}
    # Find users who needs verification
    foreach rcpt [ns_smtpd getrcpt $id] {
      foreach { deliver_email user_flags spam_score } $rcpt {}
      # Non-relayable user
      if { !($user_flags & [ns_smtpd flag RELAY]) } { continue }
      # Check for bounced email
      if { [maverix::bouncedEmail $deliver_email] } {
        set bounce 1
        continue
      }
      # Search/create recipient
      if { [set user [maverix::cache::user $deliver_email 1]] == "" } {
        ns_smtpd setreply $id "421 Transaction failed (Usr)\r\n"
        ns_smtpd setflag $id -1 ABORT
        return
      }
      set spam_status ""
      if { $user_flags & [ns_smtpd flag GOTSPAM] } { set spam_status Spam }
      set user_email [ossweb::nvl [lindex $user 0] $deliver_email]
      set user_type [lindex $user 1]
      set spam_check_status [lindex $user 2]
      set spam_score_white [lindex $user 3]
      set spam_score_black [lindex $user 4]
      set anti_virus_flag [lindex $user 5]
      set spam_autolearn_flag [lindex $user 6]
      set spam_subject [lindex $user 7]
      # Already delivered user
      if { $user_flags & [ns_smtpd flag DELIVERED] } { continue }
      # Search/create sender
      if { [set sender [maverix::cache::sender $user_email $sender_email 1]] == "" } {
        ns_smtpd setreply $id "421 Transaction failed (Snd)\r\n"
        ns_smtpd setflag $id -1 ABORT
        return
      }
      set sender_type [lindex $sender 0]
      set reason [lindex $sender 1]
      if { $sender_type == "DROP" } {
        ossweb::db::exec sql:maverix.sender.log.create
        nsv_set maverix:sender:drop $sender_email [ns_time]
        if { $spam_autolearn_flag == "t" } { maverix::trainSpam $user_email 0 1 $body $signature }
        continue
      }
      # Spam subject check 
      if { $spam_subject != "" } {
        if { [regexp -nocase $spam_subject $subject] } {
          set reason spam/subject
          ossweb::db::exec sql:maverix.sender.log.create
          nsv_set maverix:sender:drop $sender_email [ns_time]
          ns_log notice maverix::handler::RCPT: $id: $user_email, dropped $sender_email/$reason: $subject
          continue
        }
      }
      # Examine anti-virus flag for messages with detected viruses
      if { $conn_flags & [ns_smtpd flag GOTVIRUS] && $anti_virus_flag == "DROP" } {
        ns_log notice maverix::handler::DATA: $id: $user_email, dropped $sender_email, virus: $virus_status
        set reason virus
        ossweb::db::exec sql:maverix.sender.log.create
        nsv_set maverix:sender:drop $sender_email [ns_time]
        continue
      }
      if { $sender_type == "VRFY" } {
        # Examine spam score for black listing
        if { ($spam_score_black != "" && $spam_score >= $spam_score_black) ||
             ($spam_check_status != "" && $spam_status != "" && [lsearch -exact $spam_check_status $spam_status] > -1) } {
          ns_log notice maverix::handler::DATA: $id: $user_email, dropped $sender_email, score: $spam_score/$spam_score_black, status: $spam_status/$spam_check_status
          set reason spam
          ossweb::db::exec sql:maverix.sender.log.create
          nsv_set maverix:sender:drop $sender_email [ns_time]
          continue
        }
        # Examine spam score for white listing
        if { $spam_score_white != "" && $spam_score <= $spam_score_white } {
          set user_msgs($user_email) PASS
          ns_log notice maverix::handler::DATA: $id: $user_email, forwarded $sender_email, score: $spam_score/$spam_score_white
        }
      }
      if { $spam_autolearn_flag == "t" } { maverix::trainSpam $user_email 0 0 $body $signature }
      set users($deliver_email) "$user_email {$spam_status} $spam_score"
    }
    if { $bounce } { maverix::decodeBounce $id $body }
    if { [array size users] == 0 } { return }
    # Save message
    # Build attachements list
    foreach file [ns_smtpd gethdrs $id X-Maverix-File] {
      append attachments $file " "
    }
    # Save the message in the database
    if { [ossweb::db::exec sql:maverix.message.create] } {
      ns_smtpd setreply $id "421 Transaction failed (Msg)\r\n"
      ns_smtpd setflag $id -1 ABORT
      ns_smtpd dump $id /tmp/maverix.dump
      return
    }
    unset body
    set msg_id [ossweb::db::currval maverix_msg]
    # Bind the message to all recipients
    foreach deliver_email [array names users] {
      foreach { user_email spam_status spam_score } $users($deliver_email) {}
      if { [info exists user_msgs($user_email)] } {
        set msg_status $user_msgs($user_email)
      } else { 
        set msg_status ""
      }
      if { [ossweb::db::exec sql:maverix.user.message.create] } {
        ns_smtpd setreply $id "421 Transaction failed (Usr)\r\n"
        ns_smtpd setflag $id -1 ABORT
        return
      }
    }
    ossweb::db::release
}

proc maverix::handler::ERROR { id } {

    set line [ns_smtpd getline $id]
    # sendmail 550 user unknown reply
    if { [regexp -nocase {RCPT TO: <([^@ ]+@[^ ]+)>: 550} $line d user_email] } {
      ns_log notice maverix::handler::ERROR: $id: Dropping $user_email
      maverix::cache::user_flush $user_email
    }
}

# Hourly manitenance
proc ossweb::schedule::hourly::maverix {} {

    maverix::cache::flush
}

# Daily manitenance
proc ossweb::schedule::daily::maverix {} {

    ossweb::db::exec sql:maverix.schedule.cleanup.sender.log
    ossweb::db::exec sql:maverix.schedule.cleanup.user.messages
    ossweb::db::exec sql:maverix.schedule.cleanup.messages
    ossweb::db::exec sql:maverix.schedule.cleanup.users
    
    switch -- [ns_smtpd spamversion] {
     DSPAM {
       catch { exec [ns_info home]/modules/dspam/dspam.sh }
     }
    }
}

# Performs deliver of verified mail
proc maverix::schedule::deliver {} {

    ns_log Notice maverix::schedule::deliver: started

    while {1} {
      if { [catch {
        foreach rec [ossweb::db::multilist sql:maverix.schedule.deliver.list -array t] {
          foreach { name value } $rec { set $name $value }
          if { [catch { ns_smtpd send $sender_email $deliver_email body } deliver_error] } {
            ns_log Error maverix::schedule::deliver: $msg_id: $sender_email:$deliver_email: $deliver_error
            # Delete user on 550 user unknown error
            if { [regexp -nocase {unexpected status from [^:]+: 550} d deliver_error] } {
              ns_log notice maverix::schedule::deliver: Dropping $user_email
              maverix::cache::user_drop $user_email
            } else {
              set msg_status ""
              incr deliver_count
              ossweb::db::exec sql:maverix.user.message.update
            }
          } else {
            ossweb::db::exec sql:maverix.user.message.delete
            ossweb::db::exec sql:maverix.message.delete
          }
        }
      } errmsg] } {
        ns_log Error maverix::schedule::deliver: $errmsg
      }
      ns_sleep [ossweb::config maverix:schedule:deliver 60]
    }

    ns_log Notice maverix::schedule::deliver: exit
}

# Performs notification about unverified mail
proc maverix::schedule::digest { { user_list "" } } {

    ns_log Notice maverix::schedule::digest: started
    
    # Possible separate relay for delivering digests
    set relay [split [ossweb::config maverix:user:relay] :]
    set relayhost [lindex $relay 0]
    set relayport [lindex $relay 1]
    # Url to the digest
    set Url [ossweb::nvl [ossweb::config maverix:hostname] [ossweb::conn::hostname]]/maverix
    if { ![string match http://* $Url] } { set Url http://$Url }
    set Path [ossweb::config server:path:root [ns_info pageroot]]/maverix
    
    while { [set maverix_email [ossweb::config maverix:user:admin]] != "" } {
      if { [set digest_tmpl [ossweb::read_file $Path/RcptDigest.adp]] == "" } {
        ns_log Error maverix::schedule::digest: $Path/RcptDigest.adp is not found
        return -1
      }
      set user_count 0
      set boundary "MRVX[ns_time][pid]"
      foreach user [ossweb::db::multilist sql:maverix.schedule.digest.list] {
        if { [catch {
          set user_email [lindex $user 0]
          set digest_email [lindex $user 1]
          set body_size [lindex $user 2]
          set digest_count 0
          set digest_id [maverix::digest $user_email]
          set digest_date [ossweb::date now]
          set msgs ""
          ossweb::db::multirow messages sql:maverix.user.message.list -eval {
            set subject [maverix::decodeHdr $row(subject)]
            set row(subject:text) [ossweb::util::wrap_text $subject -size 30]
            set row(subject) [ossweb::util::wrap_text [ns_quotehtml $subject] -size 30 -break <BR>]
            set body [string range $row(body) $row(body_offset) end]
            # Strip off MIME headers
            regexp -nocase {Content-Type:[^\n]+(.+)} $body d body
            set row(body:text) [ossweb::util::wrap_text $body -size 30]
            set row(body) [ossweb::util::wrap_text [ns_striphtml $body] -size 30 -break <BR>]
            set row(sender_block) "$Url/User.oss?c=sb&u=[ns_urlencode $user_email]&s=[ns_urlencode $row(sender_email)]&d=$digest_id"
            set row(domain_block) "$Url/User.oss?c=sbd&u=[ns_urlencode $user_email]&s=[ns_urlencode $row(sender_email)]&d=$digest_id"
            set row(sender_verify) "$Url/User.oss?c=sv&u=[ns_urlencode $user_email]&s=[ns_urlencode $row(sender_email)]&d=$digest_id"
            set row(domain_verify) "$Url/User.oss?c=svd&u=[ns_urlencode $user_email]&s=[ns_urlencode $row(sender_email)]&d=$digest_id"
            set row(message_drop) "$Url/User.oss?c=md&u=[ns_urlencode $user_email]&m=$row(msg_id)&d=$digest_id"
            set row(message_forward) "$Url/User.oss?c=mf&u=[ns_urlencode $user_email]&m=$row(msg_id)&d=$digest_id"
            set row(sender) [ossweb::util::wrap_text $row(sender_email) -size 40 -break <BR>]
          }
          if { ${messages:rowcount} > 0 } {
            set body [ossweb::adp::Evaluate $digest_tmpl]
            # Deliver the digest to one user and mark all messages
            if { [catch { eval ns_smtpd send $maverix_email $digest_email body $relayhost $relayport } errmsg] } {
              ns_log Error maverix::schedule::digest: $digest_email: $errmsg
              # Delete user on 550 user unknown error
              if { [regexp -nocase {unexpected status from [^:]+: 550} d deliver_error] } {
                ns_log notice maverix::schedule::digest: Dropping $user_email
                maverix::cache::user_drop $user_email
              } else {
                ossweb::db::exec sql:maverix.user.update.digest_count
              }
            } else {
              # Update global user digest id for account access
              ossweb::db::exec sql:maverix.user.update
              ns_log notice maverix::schedule::digest: $digest_email
              incr user_count
            }
          }
        } errmsg] } {
          ns_log Error maverix::schedule::digest: $errmsg
          ossweb::db::rollback
        }
      }
      if { $user_list != "" } { return $user_count }
      ns_sleep [ossweb::config maverix:schedule:digest 120]
    }

    ns_log Notice maverix::schedule::digest: exit
}

# Performs notification about unverified mail
proc maverix::schedule::sender {} {

    ns_log Notice maverix::schedule::sender: started
    
    # Possible separate relay for delivering digests
    set relay [split [ossweb::config maverix:sender:relay] :]
    set relayhost [lindex $relay 0]
    set relayport [lindex $relay 1]
    # Url to the digest
    set Url [ossweb::nvl [ossweb::config maverix:hostname] [ossweb::conn::hostname]]/maverix
    if { ![string match http://* $Url] } { set Url http://$Url }
    set Path [ossweb::config server:path:root [ns_info pageroot]]/maverix

    while { [set maverix_email [ossweb::config maverix:sender:admin]] != "" } {
      if { [set digest_tmpl [ossweb::read_file $Path/SenderDigest.adp]] == "" } {
        ns_log Error maverix::schedule::digest: $Path/SenderDigest.adp is not found
        return
      }
      set boundary "MRVX[ns_time][pid]"
      foreach sender_email [ossweb::db::multilist sql:maverix.schedule.sender.list] {
        if { [catch {
          set users ""
          set digest_date [ossweb::date now]
          set digest_id [maverix::digest $sender_email]
          ossweb::db::multirow messages sql:maverix.sender.user.list -eval {
            set row(sender_verify) "$Url/Sender.oss?s=[ns_urlencode $sender_email]&u=[ns_urlencode $row(user_email)]&c=v&d=$digest_id"
            lappend users $row(user_email)
          }
          if { ${messages:rowcount} > 0 } {
            # Build digest message using html template
            set body [ossweb::adp::Evaluate $digest_tmpl]
            # Deliver the digest to one user and mark all messages
            if { [catch { eval ns_smtpd send $maverix_email $sender_email body $relayhost $relayport } errmsg] } {
              ns_log Error maverix::schedule::sender: $sender_email: $errmsg
              if { [regexp -nocase {unexpected status from [^:]+: 5[0-9][0-9]} $errmsg] } {
                foreach user_email $users {
                  ns_log notice maverix::schedule::sender: $user_email: Dropping $sender_email
                  maverix::cache::sender_drop $user_email $sender_email
                }
              } else {
                ossweb::db::exec sql:maverix.sender.update.digest_count
              }
            } else {
              # Update record with new digest ids
              foreach user_email $users {
                ossweb::db::exec sql:maverix.sender.update
              }
              ns_log notice maverix::schedule::sender: $sender_email
            }
          }
        } errmsg] } {
          ns_log Error maverix::schedule::sender: $errmsg
        }
      }
      ns_sleep [ossweb::config maverix:schedule:sender 60]
    }

    ns_log Notice maverix::schedule::sender: exit
}

# Cache initialization
proc maverix::cache::init {} {

    foreach name [ossweb::cache::keys maverix:user] { ossweb::cache::flush maverix:user $name }
    foreach name [ossweb::cache::keys maverix:sender] { ossweb::cache::flush maverix:sender $name }
    # Load users and senders into the cache
    ns_log Notice maverix::cache::init: loading users...
    set user_count 0
    ossweb::db::foreach sql:maverix.cache.users {
      maverix::cache::user_set \
               $user_email \
               $user_type \
               -spam_status $spam_status \
               -spam_score_white $spam_score_white \
               -spam_score_black $spam_score_black \
               -spam_autolearn_flag $spam_autolearn_flag \
               -anti_virus_flag $anti_virus_flag \
               -spam_subject $spam_subject \
               -cluster f
      incr user_count
    }
    ns_log Notice maverix::cache::init: $user_count users loaded
    ns_log Notice maverix::cache::init: loading senders...
    set sender_count 0
    ossweb::db::foreach sql:maverix.cache.senders {
      maverix::cache::sender_set \
               $user_email \
               $sender_email \
               $sender_type \
               -cluster f
      incr sender_count
    }
    ns_log Notice maverix::cache::init: $sender_count senders loaded
}

# Flush cache memory into the database
proc maverix::cache::flush {} {

    set cache [nsv_array get maverix:sender:drop]
    nsv_array reset maverix:sender:drop {}
    foreach { sender_email time } $cache {
      set update_date [ns_fmttime $time "%Y-%m-%d %T"]
      ossweb::db::exec sql:maverix.sender.update.timestamp
    }
}

# Retrieves sender record from the cache/database
proc maverix::cache::sender { user_email sender_email { create_flag 0 } } {

    catch {
      ossweb::cache::run maverix:sender $user_email:$sender_email {
        set sender_type [ossweb::config maverix:sender:type]
        if { [ossweb::db::multivalue sql:maverix.sender.search] } {
          # Try domain record
          set domain [lindex [split $sender_email @] 1]
          if { [set sender [ossweb::cache::get maverix:domain $user_email:@$domain]] != "" } { 
            error "$sender domain" 
          }
          # Try second level domain
          set domain [join [lrange [split $domain .] end-1 end] .]
          if { [set sender [ossweb::cache::get maverix:domain $user_email:@$domain]] != "" } { 
            error "$sender domain"
          }
          # Proceed with sender specific record
          if { $create_flag == 0 } { error $sender_type }
          set digest_id [maverix::digest $sender_email]
          if { [ossweb::db::exec sql:maverix.sender.create] } {
            ns_log Error maverix::cache::sender: $user_email:$sender_email: create error
            error ""
          }
        }
        return "$sender_type email"
      }
    } sender
    if { $sender == "" } { ossweb::cache::flush maverix:sender $user_email:$sender_email }
    return $sender
}

proc maverix::cache::sender_set { user_email sender_email sender_type args } {

    ns_parseargs { {-sender_method ""} {-cmd ""} {-cluster t} } $args

    regsub -all {[{}]} $sender_email {\\&} sender_email

    if { [string index $sender_email 0] == "@" } {
      ossweb::cache::put maverix:domain $user_email:$sender_email $sender_type
    } else {
      ossweb::cache::put maverix:sender $user_email:$sender_email $sender_type
    }
}

proc maverix::cache::sender_flush { user_email sender_email args } {

    ns_parseargs { {-sender_method ""} {-cmd ""} {-cluster t} } $args
    
    switch -- $sender_email {
     VRFY - PASS - DROP {
       foreach name [ossweb::cache::keys maverix:sender $user_email:*] {
         if { [set sender [ossweb::cache::get maverix:sender $name]] != "" && 
              [lindex $sender 0] == $sender_email } {
           ossweb::cache::flush maverix:sender $name
         }
       }
       foreach name [ossweb::cache::keys maverix:domain $user_email:*] {
         if { [set sender [ossweb::cache::get maverix:domain $name]] != "" && 
              [lindex $sender 0] == $sender_email } {
           ossweb::cache::flush maverix:domain $name
         }
       }
       return
     }
    }
    if { [string index $sender_email 0] == "@" } {
      ossweb::cache::flush maverix:domain $user_email:$sender_email
    } else {
      ossweb::cache::flush maverix:sender $user_email:$sender_email
    }
}

proc maverix::cache::sender_drop { user_email sender_email args } {

    ns_parseargs { {-sender_method Bounced} {-cmd ""} {-cluster t} } $args

    ossweb::db::exec sql:maverix.sender.drop
    maverix::cache::sender_flush $user_email $sender_email
}

# Retrieves user record from the cache/database
proc maverix::cache::user { user_email { mode 0 } } {

    catch {
      ossweb::cache::run maverix:user $user_email {
        set spam_status ""
        set spam_score_white ""
        set spam_score_black ""
        set anti_virus_flag ""
        set spam_autolearn_flag ""
        set email $user_email
        set user_type [ossweb::config maverix:user:type]
        set subject ""
        if { [ossweb::db::multivalue sql:maverix.user.search] } {
          if { $mode == 0 } {
            error "$user_email $user_type"
          }
          set digest_id [maverix::digest $user_email]
          if { [ossweb::db::exec sql:maverix.user.create] } { 
            ns_log Error maverix::cache::user: $user_email: create error
            error ""
          }
        }
        if { $user_email == $email } { set user_email "" }
        return [list $user_email \
                     $user_type \
                     $spam_status \
                     $spam_score_white \
                     $spam_score_black \
                     $anti_virus_flag \
                     $spam_autolearn_flag \
                     $spam_subject]
      }
    } user
    if { $user == "" } { ossweb::cache::flush maverix:user $user_email }
    return $user
}

proc maverix::cache::user_set { user_email user_type args } {

    ns_parseargs { {-cmd ""}
                   {-cluster t}
                   {-spam_status ""}
                   {-spam_score_white ""}
                   {-spam_score_black ""}
                   {-spam_autolearn_flag ""}
                   {-anti_virus_flag ""}
                   {-spam_subject ""} } $args

    ossweb::cache::put maverix:user $user_email \
             [list {} \
                   $user_type \
                   $spam_status \
                   $spam_score_white \
                   $spam_score_black \
                   $anti_virus_flag \
                   $spam_autolearn_flag \
                   $spam_subject]
}

proc maverix::cache::user_flush { user_email args } {

    ns_parseargs { {-cmd ""} } $args
    
    ossweb::cache::flush maverix:user $user_email
}

proc maverix::cache::user_drop { user_email args } {

    ns_parseargs { {-cmd ""} {-cluster t} } $args
    
    maverix::cache::user_set $user_email DROP
    ossweb::db::exec sql:maverix.user.delete
}
