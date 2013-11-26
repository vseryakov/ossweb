# Author: Vlad Seryakov vlad@crystalballinc.com
# January 2003

namespace eval webmail {
  variable version "Webmail version 2.0"
  namespace eval schedule {}
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

# Initialization
ossweb::register_init webmail::init

# Link to webmail from the toolbar
proc ossweb::html::toolbar::webmail {} {

    if { [ossweb::conn::check_acl -acl *.webmail.webmail.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/mail.gif -mouseover /img/toolbar/mail_o.gif -width "" -height "" -hspace 6 -status Webmail -alt Webmail -app_name webmail wm]
}

# Problem initialization
proc webmail::init {} {

    ossweb::file::register_download_proc webmail ::webmail::download
    ns_log Notice webmail: initialized
}

# File download handler, used by ossweb::file::download for file download verification
proc webmail::download { params } {

    set conn_id [ns_set get $params conn_id]
    if { [ossweb::conn::parse_request] == "" ||
         [set conn_id [webmail::parse_session $conn_id]] == "" } {
      ns_log Error webmail::download: [ns_conn url]: User=[ossweb::conn user_id]: ID=$conn_id
      return file_accessdenied
    }
    set msg_id [ns_set get $params msg_id]
    set part_id [ns_set get $params part_id]
    # Can be message body part
    if { $msg_id != "" && $part_id != "" } {
      ns_imap body $conn_id $msg_id $part_id -return
      return file_done
    }
    # Regular attachement
    ns_set update $params file:path [webmail::path $conn_id]
    return file_return
}

# Path to web mail attachements
proc webmail::path { conn_id } {

    return mail/[ossweb::conn user_id],$conn_id
}

# Verify user session against mail session, try get mail id from cookies if set
# Returns valid mail session id if successful, otherwise empty result
proc webmail::parse_session { { conn_id "" } } {

    if { $conn_id == "" } {
      set conn_id [ns_getcookie imap_id ""]
    }
    if { [catch { set uid [ns_imap getparam $conn_id user_id] }] } {
      set uid ""
    }
    if { [catch { set sid [ns_imap getparam $conn_id session_id] }] } {
      set sid ""
    }
    if { $conn_id == "" || [ossweb::conn user_id] != $uid || [ossweb::conn session_id] != $sid } {
      ns_log Notice webmail::parse_session: $conn_id: $uid/$sid, invalid session
      return
    }
    return $conn_id
}

# Parses email addresess, removes duplicates
proc webmail::parse_email { email } {

    set result ""
    regsub -all {"([^"]+),([^"]+)"} $email {"\1 \2"} email
    foreach addr [ossweb::convert::string_to_list $email -separator ","] {
      regexp {.*<(.*)>} $addr d addr
      lappend result $addr
    }
    return [join [lsort -uniq $result] ,]
}

# Build full mailbox name
proc webmail::mailbox { mailbox args } {

    ns_parseargs { {-host t} } $args

    if { ![string equal -nocase $mailbox "INBOX"] } {
      set mailbox [ossweb::config mail:dir]$mailbox
    }
    if { $host == "f" } {
      return $mailbox
    }
    return "{[ossweb::config mail:host][ossweb::config mail:options]}$mailbox"
}

# Returns name portion of mailbox name
proc webmail::name { conn_id } {

    set maildir [ossweb::config mail:dir]
    set mailbox [ns_imap getparam $conn_id mailbox.name]
    if { ![string equal -nocase $mailbox "INBOX"] } {
      set mailbox [string range $mailbox [string length $maildir] end]
    }
    return $mailbox
}

# Decodes header string
proc webmail::decode_hdr { str } {

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

# Decodes multipart body and returns formatted text with artachments list
proc webmail::decode_body { conn_id msg_id msgstruct args } {

    ns_parseargs { {-files ""} {-msgpart ""} {-smilies f} } $args

    if { $files != "" } {
      upvar $files msgfiles
    }

    array set struct $msgstruct

    if { $struct(type) == "multipart" } {
      set body ""
      set files ""
      for { set i 1 } { $i <= $struct(part.count) } { incr i } {
        array unset part
        array set part $struct(part.$i)
        if { $msgpart != "" } {
          set part_id "$msgpart.$i"
        } else {
          set part_id $i
        }
        if { $part(type) == "multipart" } {
          append body [webmail::decode_body $conn_id $msg_id $struct(part.$i) -files msgfiles -msgpart $part_id -smilies $smilies]
          continue
        }
        if { [info exists part(body.name)] || [info exists part(disposition.filename)] } {
          if { [set filename [ossweb::coalesce part(body.name)]] == "" } {
            set filename $part(disposition.filename)
          }
          lappend msgfiles [list [ossweb::file::url webmail $filename conn_id $conn_id msg_id $msg_id part_id $part_id] \
                                  $filename \
                                  [string tolower "$part(type)/$part(subtype)"] \
                                  [ossweb::util::size [ossweb::coalesce part(bytes)]]]
        } else {
          append body [webmail::format_body [ns_imap body $conn_id $msg_id $part_id -decode] $part(subtype) -smilies $smilies]
        }
        append body "<P>"
      }
    } else {
      if { $msgpart != "" } {
        set part_id "$msgpart.1"
      } else {
        set part_id 1
      }
      set body [webmail::format_body [ns_imap body $conn_id $msg_id $part_id -decode] $struct(subtype) -smilies $smilies]
    }
    return $body
}

# Formats body text according to given type, used for putting
# email body into display form, takes care about all dangerous tags/symbols
proc webmail::format_body { body type args } {

    ns_parseargs { {-smilies f} } $args

    if { $smilies == "t" } {
      set body [webmail::smilies $body]
    }
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

# Replaces smilies symbols with mages
proc webmail::smilies { text } {

    return [string map { ":-)" "<IMG SRC=/img/smilies/happy.png BORDER=0>"
                         ":)" "<IMG SRC=/img/smilies/happy.png BORDER=0>"
                         ":->" "<IMG SRC=/img/smilies/happy.png BORDER=0>"
                         ";-)" "<IMG SRC=/img/smilies/wink.png BORDER=0>"
                         ";)" "<IMG SRC=/img/smilies/wink.png BORDER=0>"
                         ";->" "<IMG SRC=/img/smilies/wink.png BORDER=0>"
                         ";-(" "<IMG SRC=/img/smilies/sad.png BORDER=0>"
                         ";(" "<IMG SRC=/img/smilies/sad.png BORDER=0>"
                         ";-<" "<IMG SRC=/img/smilies/sad.png BORDER=0>"
                         ":-(" "<IMG SRC=/img/smilies/sad.png BORDER=0>"
                         ":(" "<IMG SRC=/img/smilies/sad.png BORDER=0>"
                         ":-<" "<IMG SRC=/img/smilies/sad.png BORDER=0>"
                         ">:-)" "<IMG SRC=/img/smilies/devil.png BORDER=0>"
                         ">:)" "<IMG SRC=/img/smilies/devil.png BORDER=0>"
                         ">;-)" "<IMG SRC=/img/smilies/devil.png BORDER=0>"
                         "8-)" "<IMG SRC=/img/smilies/grin.png BORDER=0>"
                         "8->" "<IMG SRC=/img/smilies/grin.png BORDER=0>"
                         ":-D" "<IMG SRC=/img/smilies/grin.png BORDER=0>"
                         ";-D" "<IMG SRC=/img/smilies/grin.png BORDER=0>"
                         "8-D" "<IMG SRC=/img/smilies/grin.png BORDER=0>"
                         ":-d" "<IMG SRC=/img/smilies/tasty.png BORDER=0>"
                         ";-d" "<IMG SRC=/img/smilies/tasty.png BORDER=0>"
                         "8-d" "<IMG SRC=/img/smilies/tasty.png BORDER=0>"
                         ":-P" "<IMG SRC=/img/smilies/nyah.png BORDER=0>"
                         ";-P" "<IMG SRC=/img/smilies/nyah.png BORDER=0>"
                         "8-P" "<IMG SRC=/img/smilies/nyah.png BORDER=0>"
                         ":-p" "<IMG SRC=/img/smilies/nyah.png BORDER=0>"
                         ";-p" "<IMG SRC=/img/smilies/nyah.png BORDER=0>"
                         "8-p" "<IMG SRC=/img/smilies/nyah.png BORDER=0>"
                         ":-O" "<IMG SRC=/img/smilies/scare.png BORDER=0>"
                         ";-O" "<IMG SRC=/img/smilies/scare.png BORDER=0>"
                         "8-O" "<IMG SRC=/img/smilies/scare.png BORDER=0>"
                         ":-o" "<IMG SRC=/img/smilies/scare.png BORDER=0>"
                         ";-o" "<IMG SRC=/img/smilies/scare.png BORDER=0>"
                         "8-o" "<IMG SRC=/img/smilies/scare.png BORDER=0>"
                         ":-/" "<IMG SRC=/img/smilies/ironic.png BORDER=0>"
                         ";-/" "<IMG SRC=/img/smilies/ironic.png BORDER=0>"
                         "8-/" "<IMG SRC=/img/smilies/ironic.png BORDER=0>"
                         ":-\\" "<IMG SRC=/img/smilies/ironic.png BORDER=0>"
                         ";-\\" "<IMG SRC=/img/smilies/ironic.png BORDER=0>"
                         "8-\\" "<IMG SRC=/img/smilies/ironic.png BORDER=0>"
                         ":-|" "<IMG SRC=/img/smilies/plain.png BORDER=0>"
                         ";-|" "<IMG SRC=/img/smilies/wry.png BORDER=0>"
                         "8-|" "<IMG SRC=/img/smilies/koed.png BORDER=0>"
                         ":-X" "<IMG SRC=/img/smilies/yukky.png BORDER=0>"
                         ";-X" "<IMG SRC=/img/smilies/yukky.png BORDER=0>" } $text]
}

