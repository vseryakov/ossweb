#  The contents of this file are subject to the Mozilla Public License
#  Version 1.1 (the "License"); you may not use this file except in
#  compliance with the License. You may obtain a copy of the License at
#  http://mozilla.org/.
#
#  Software distributed under the License is distributed on an "AS IS"
#  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
#  the License for the specific language governing rights and limitations
#  under the License.
#
#  Author Vlad Seryakov vlad@crystalballinc.com

namespace eval im {

   namespace eval icq {}
   namespace eval modem {}
   namespace eval callerid {
     namespace eval send {}
   }
}

ossweb::register_init im::init

proc im::init {} {

  icq::init
  ns_thread begindetached im::icq::thread
  ns_thread begindetached im::modem::thread
}

proc im::icq::info { uin } {

    array set rec [ossweb::cache get im:$uin]
    if { [set status [ossweb::coalesce rec(status)]] == "" } { return }
    switch -- $status {
     online - away - na {
       set image icq/$status.gif
     }
     default  {
       set image icq/offline.gif
     }
    }
    return $image
}

# Send ICQ message to specified  UIN
proc im::icq::send { uin msg { type text } } {

    ossweb::cache lappend icq:message [list SendMsg $type $uin $msg]
}

# ICQ message handler
proc im::icq::event { event args } {

    global icq

    if { $event != "Log" && [ossweb::config icq:logevents 0] > 0 } {
      ns_log Notice "im::event: <$event> <$args>"
    }
    switch -- $event {
     MyStatus {
       set status [lindex $args 0]
     }

     Incoming {
       ns_log Notice "im::event: $event $args"
       foreach { type uin time text } $args {}
       switch -- $type {
        text {
           array set rec [ossweb::cache icq:$uin]
           set contacts [ossweb::config icq:contacts]
           # Do no accept msgs outside of contact list
           if { [lsearch -exact $contacts $uin] == -1 && [ossweb::config icq:unknown] == "" } {
             return
           }
           set title "[clock format $time -format "%m/%d/%y %H:%M"]: ICQ Message From [ossweb::coalesce rec(alias)] $uin]"
           #im::icq::notify $title $text
        }
       }
     }

     Status {
       set uin [lindex $args 0]
       array set rec [ossweb::cache get icq:$uin]
       set rec(status) [lindex $args 1]
       ossweb::cache put icq:$uin [array get rec]
       ns_log Notice "im::event: $event $uin [ossweb::coalesce rec(alias)] $rec(status)"
     }

     Info {
       set ref [lindex $args 0]
       set uin [ossweb::cache get icq:mapping:$ref]
       if { $uin != "" } {
         array set rec [ossweb::cache icq:$uin]
         foreach { key val } [lindex $args 1] {
           if { $val == "" } { continue }
           switch -- $key {
            Nick { set key alias }
           }
           set rec($key) $val
         }
         ossweb::cache set icq:$uin [array get rec]
         ossweb::cache flush icq:mapping:$ref
         ns_log Notice "im::event: $event: [array get rec]"
       }
     }

     SendMsg {
       foreach { type uin msg } $args {}
       $icq send $type $uin $msg
     }

     GetInfo {
       set uin [lindex $args 0]
       set ref [ossweb::cache incr icq:refcount]
       ossweb::cache set icq:mapping:$ref $uin
       $icq info $uin $ref
       if { $ref >= 250 } {
         ossweb::cache set icq:refcount 0
       }
     }
    }
}

# Main ICQ thread
proc im::icq::thread {} {

    global icq

    set uin [ossweb::config icq:user]
    set passwd [ossweb::config icq:passwd]
    if { $uin == "" || $passwd == "" } { return }
    # Login to ICQ and populate internal contacts list
    set icq [icq::icq $uin $passwd -event im::icq::event -reconnect 1]
    foreach c [ossweb::config icq:contacts] {
      $icq contacts all $c
    }
    ns_thread name icq:$uin
    $icq status online
    ns_log Notice im::icq::thread started: $uin
    while { ![ns_info shutdownpending] && [ossweb::config icq:stop] == "" } {
      set msgs [ossweb::cache get icq:message]
      if { $msgs != "" } {
        ossweb::cache set icq:message ""
        foreach msg $msgs {
          if { [catch { eval im::icq::event $msg } errmsg] } {
            ns_log Notice im_thread: $errmsg
          }
        }
      }
      update
      after 500
    }
    $icq delete
    ns_log Notice im::icq::thread stopped
}

# Send to ICQ accounts
proc im::callerid::send::icq { phone name text } {

    foreach uin [ossweb::config callerid:icq] {
       im::icq::send $uin "INCOMING PHONE CALL\nPhone Number: $phone\nCaller ID: $name\n$text"
    }
}

# Send HTTP broadcast
proc im::callerid::send::http { phone name text } {

    set url "/callerid:$phone:[string map {" " +} $name]"

    foreach ipaddr [ossweb::config callerid:ipaddr] {
      foreach { ipaddr port } [split $ipaddr :] {}
      if { [string match http:* $ipaddr] } {
        catch { ns_httpget http://[string range $ipaddr 4 end]:$port$url 3 }
      } else {
        if { [info command ns_udp] != "" } {
          ns_udp -noreply $ipaddr $port "GET $url HTTP/1.0\r\n\r\n"
        }
      }
    }
}


# Initialize modem device
proc im::modem::thread {} {

    if { [set device [ossweb::config modem:device]] == "" } {
      return
    }

    if { [catch {
      set fd [open $device {RDWR NOCTTY}]
      set modem_init [ossweb::config modem:init "AT+VCID=1"]
      # Modem port params: ex. 9600,8,n,1
      if { [set modem_mode [ossweb::config modem:mode]] != "" } {
        fconfigure $fd -mode $mode -buffering none -encoding binary -translation binary
      }
      puts $fd "ATZ\r\n$modem_init\r"
      flush $fd
    } errmsg] } {
      ns_log Error im::modem: $errmsg
      return
    }
    # Run as system admin
    ossweb::conn -set user_id 0
    ns_thread name modem:$fd
    ns_log Notice im::modem:thread started
    while { ![ns_info shutdownpending] && [ossweb::config modem:stop] == "" } {
      if { [set line [string trim [gets $fd]]] == "" } {
        continue
      }
      ns_log Notice im::modem: $line
      switch -glob -- $line {
       NMBR* {
         switch -- [set phone [lindex $line 2]] {
          P { set phone Private }
          O { set phone Unknown }
         }
       }

       NAME* {
         switch -- [set name [join [lrange $line 2 end]]] {
          P { set name Private }
          O { set name Unknown }
         }
         ns_log Notice im::modem:: Caller ID: $phone=$name
         # Look in address book
         set text ""
         set people_id ""
         set entry_name $phone
         foreach people_id [lindex [ossweb::db::list sql:people.search1] 0] {
           ossweb::db::multivalue sql:people.read -array person
           set name "$person(first_name) $person(last_name)"
           if { $person(description) != "" } {
             append text "$person(description)\n"
           }
           if { $person(birthday) != "" } {
             append text "Birthday: $person(birthday)\n"
           }
         }
         # Send through registered handlers
         foreach proc [namespace eval ::im::callerid::send { info procs }] {
           if { [catch { ::im::callerid::send::$proc $phone $name $text } errmsg] } {
             ns_log error im::modem::thread: $proc: $errmsg
           }
         }
         set name ""
         set phone ""
       }
      }
   }
   ns_log Notice im::modem::thread stopped
}

# Preferences for im
proc ossweb::control::prefs::im { type args } {

    switch -- $type {
     columns {
       return { im_skype "" "" im_icq "" "" im_aim "" "" im_yahoo "" "" im_gtalk "" "" im_msn "" "" }
     }

     form {
       ossweb::form form_prefs -section IM

       foreach { n t d } [ossweb::control::prefs::im columns] {
          ossweb::widget form_prefs.$n -type text -label [string toupper [string range $n 3 end]]: \
               -optional \
               -value [ossweb::conn $n]
       }
     }

     save {
       set data [list]
       foreach { n t d } [ossweb::control::prefs::im columns] {
         lappend data $n [ns_querygetall $n]
       }
       eval ossweb::admin::prefs set -obj_id [ossweb::conn user_id] $data
     }
    }
}

# Extend user admin screen
proc ossweb::control::user::im { type user_id args } {

    switch -- $type {
     tab {
       ossweb::widget form_tab.im -type link -label IM -value $args
     }

     form {
       ossweb::form form_prefs -title "User IM Settings"

       foreach { n t d } [ossweb::control::prefs::im columns] {
          ossweb::widget form_prefs.$n -type text -label [string toupper [string range $n 3 end]]: \
               -optional \
               -value [ossweb::conn $n]
       }
     }

     row {
       upvar row row
       foreach { n v } [ossweb::coalesce row(user_prefs)] {
         if { $v == "" } {
           continue
         }
         switch -glob -- $n {
          im_skype {
            append row(user_email) "<BR><A HREF=\"skype:$v\">Call $v on Skype</A>"
          }
          im_gtalk {
            append row(user_email) "<BR><A HREF=\"gtalk:call?jid=$v\">Call $v on GTalk</A>"
          }
          im_* {
            append row(user_email) "<BR>[string toupper [string range $n 3 end]]: $v"
          }
         }
       }
     }

     save {
       set data [list]
       foreach { n t d } [ossweb::control::prefs::im columns] {
         lappend data $n [ns_querygetall $n]
       }
       eval ossweb::admin::prefs set -obj_id $user_id $data
     }
    }
}
