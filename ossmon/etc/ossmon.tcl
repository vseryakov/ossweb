#!/bin/sh
#the next line restarts using tclsh \
exec tclsh "$0" "$@" 2>> /usr/local/ns/logs/ossmon.log

# Author: Vlad Seryakov vlad@crystalballinc.com 
# May 2004

# SNMP extensible manager, it is used with NET-SNMP agent to perform
# custom actions and handling process fix procedure.
# Supports OSSMON-MIB extensions.

namespace eval ossmon {

    variable configfile /usr/local/ns/conf/ossmon.conf
    variable logfile /usr/local/ns/logs/ossmon.log
    variable cachefile /usr/local/ns/logs/ossmon.cache
    variable configlist
    array set configlist {
        ps-bin "/bin/ps -ax"
        ping-bin /bin/ping
        tail-bin /usr/bin/tail
        grep-bin /bin/grep
        kill-bin /usr/bin/kill
        killall-bin /usr/bin/killall
        snmpd-bin /usr/sbin/snmpd
        cache-time 60
        syslog-regexp {}
        syslog-dir {}
        syslog-file /var/log/messages
        syslog-max-lines 50
        syslog-silence-period { 18:00 57600 "Sat 0:0" 86400 "Sun 0:0" 86400 }
        syslog-noactivity-time 7200
        ping-count 5
        ping-timeout 15
    }
    namespace eval cache {
      variable cache
      variable cachetime
    }
    namespace eval config {}
    namespace eval service {}
    namespace eval process {}
}


# Perform logging
proc ossmon::log { args } {

    catch { ::puts stderr "[clock format [clock seconds]]: [join $args " "]" }
}

# Output a string
proc ossmon::write { msg } {

    ::puts $msg
    ossmon::log $msg
}

# Shows uptime in human form
proc ossmon::uptime { secs } {

    if { $secs == "" } { return }
    set days [expr $secs / 86400]
    set uptime [expr $secs % 86400]
    set hrs [expr $uptime / 3600]
    set uptime [expr $uptime % 3600]
    set mins [expr $uptime / 60]
    set secs [expr $secs - (($days * 86400) + ($hrs * 3600) + ($mins * 60))]
    set result ""
    if { $days > 0 } {
      append result " $days day"
      if { $days > 1 } { append result s }
    }
    if { $hrs > 0 } {
      append result " $hrs hour"
      if { $hrs > 1 } { append result s }
    }
    if { $mins > 0 } {
      append result " $mins minute"
      if { $mins > 1 } { append result s }
    }
    if { $secs > 0 } {
      append result " $secs second"
      if { $secs > 1 } { append result s }
    }
    return $result
}

# Converts list of lists into plain list
proc ossmon::plain_list { name } {

    upvar $name var
    regsub -all {[{}]} $var {} tmp
    regsub -all { +} $tmp { } tmp
    set var [string trim $tmp]
}

# Returns 1 if current time within any given time period
proc ossmon::period { period duration } {

    set now [clock seconds]
    if { [set period [string trim $period]] == "" } { return 0 }
    if { [set duration [string trim $duration]] == "" } { return 0 }
    # Parse duration
    if { [regexp -nocase {^([0-9]+)m$} $duration d minutes] } {
      set duration [expr $minutes*60]
    } elseif { [regexp -nocase {^([0-9]+)h$} $duration d hours] } {
      set duration [expr $hours*3600]
    } elseif { ![string is integer -strict $duration] } {
      return 0
    }
    # Parse period
    if { [regexp -nocase {^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)+[ ]+([0-9]+\:[0-9]+)$} $period d dow time] } {
      if { ![string equal -nocase $dow [clock format $now -format %a]] } { return 0 }
      if { [catch { set seconds [clock scan $time] }] } { return 0 }
    } else {
      if { [catch { set seconds [clock scan $period] }] } { return 0 }
    }
    set hn [string trimleft [clock format $now -format "%H"] 0]
    set hs [string trimleft [clock format $seconds -format "%H"] 0]
    if { $hn < $hs } { incr seconds -86400 }
    if { $now >= $seconds && $now <= $seconds+$duration } { return 1 }
    return 0
}

# Return configuration value
proc ossmon::config { name { default "" } } {

    variable configlist
    if { [info exists configlist($name)] } { return $configlist($name) }
    return $default
}


# Return configuration value
proc ossmon::config::init {} {

    variable ::ossmon::configlist
    variable ::ossmon::configfile
    
    if { [file exists $configfile] } {
      set fd [::open $configfile]
      while { ![eof $fd] } {
        if { [set line [string trim [gets $fd]]] == "" ||
             [string index $line 0] == "#" } {
          continue
        }
        set name [lindex $line 0]
        set value [join [lrange $line 1 end]]
        ossmon::plain_list value
        if { ![info exists mark($name)] } {
          if { [llength $value] == 1 } {
            set configlist($name) $value
          } else {
            set configlist($name) [::list $value]
          }
          set mark($name) 1
          continue
        }
        ::lappend configlist($name) $value
      }
      ::close $fd
    }
}

# Return the config
proc ossmon::config::list {} {

    variable ::ossmon::configlist
    return [array get configlist]
}

# Return configuration value unsig regexp
proc ossmon::config::match { name { prefix "" } } {

    variable ::ossmon::configlist
    foreach key [array names configlist] {
      if { $prefix != "" && [string match $prefix* $key] } {
        set key [string range $key [string length $prefix] end]
      }
      if { [regexp -nocase $key $name] } { return $configlist($prefix$key) }
    }
    return
}

# Reads the whole cache file into memory
proc ossmon::cache::init {} {

    variable ::ossmon::cachefile
    variable cache 
    variable cachetime
    
    if { [catch { set fd [::open $cachefile r] } errmsg] } {
      ossmon::log ossmon::cache::read: $errmsg
      return ""
    }
    while { ![eof $fd] } {
      set line [split [gets $fd] "\001"]
      if { [llength $line] < 3 } { continue }
      set cache([lindex $line 0]) [lindex $line 1]
      set cachetime([lindex $line 0]) [lindex $line 2]
    }
    close $fd
}

# Return cache value
proc ossmon::cache::get { name { default "" } } {

    variable cache
    if { [info exists cache($name)] } { return $cache($name) }
    return $default
}

# Return the cache 
proc ossmon::cache::list {} {

    variable cache
    return [array get cache]
}

# Set local cache value
proc ossmon::cache::put { name value } {

    variable cache
    variable cachetime

    regsub -all {[``$\[\]]} $value {} value
    set cache($name) $value
    set cachetime($name) [clock seconds]
    return
}

# Check local cache for duplication
proc ossmon::cache::check { name value } {

    variable cache 
    variable cachetime
    set now [clock seconds]
    
    if { [info exists cache($name)] &&
         $cache($name) == $value &&
         [incr now -$cachetime($name)] < [ossmon::config cache-time] } {
      ossmon::log ossmon::cache::check: duplicate request: $name: $value: $now
      return 1
    }
    ossmon::cache::put $name $value
    return 0
}

# Save local memory cache into cache file
proc ossmon::cache::shutdown {} {

    variable ::ossmon::cachefile
    variable cache
    variable cachetime

    if { [catch { set fd [::open $cachefile w] } errmsg] } {
      ossmon::log ossmon::cache::save: $errmsg
      return
    }
    foreach { name value } [array get cache] {
      ::puts $fd "$name\001$value\001$cachetime($name)"
    }
    close $fd
}
 
# SNMP agent checking
proc ossmon::service::snmpd { name } {

    switch $name {
     check {
       if { [exec [ossmon::config ps-bin] | [ossmon::config tail-bin] -c 'snmpd'] < 2 } {
         exec [ossmon::config snmpd-bin]
       }
     }
     
     restart {
       exec [ossmon::config killall-bin] -9 snmpd
       exec [ossmon::config snmpd-bin]
     }
    }
}

# Misc utilities
proc ossmon::service::util { args } {

    switch -- [lindex $args 0] {
     config-get {
        ::puts "[lindex $args 1] = [ossmon::config [lindex $args 1]]"
     }
     
     config-list {
        foreach { key val } [ossmon::config::list] { ::puts "$key = $val" }
     }

     cache-list {
        foreach { key val } [ossmon::cache::list] { ::puts "$key = $val" }
     }
     
     cache-check {
        ::puts [ossmon::cache::check [lindex $args 1] [lindex $args 2]
     }
     
     cache-set {
        ossmon::cache::put [lindex $args 1] [lindex $args 2]
     }
     
     empty {
     }
    }
}

# Ping event
proc ossmon::service::ping {} {

    if { [set host [split [ossmon::cache::get ping:host] "|"]] == "" } { return }
    set data ""
    set count [ossmon::config ping-count 5]
    set timeout [ossmon::config ping-timeout 1]
    catch { exec /bin/sh -c "[ossmon::config ping-bin] -c $count -w $timeout $host 2>&1" } data
    if { $data != "" } { ::puts $data }
}

# Tail file event
proc ossmon::service::tail {} {

    if { [set tail [split [ossmon::cache::get tail:file] "|"]] == "" ||
         [set file [lindex $tail 0]] == "" } {
      return
    }
    set data ""
    if { [set lines [lindex $tail 1]] <= 0 } { set lines 100 }
    if { [set str [lindex $tail 2]] != "" } { set str "|[ossmon::config grep-bin] '$str'" }
    catch { exec /bin/sh -c "[ossmon::config tail-bin] -$lines $file $str" } data
    if { $data != "" } { ::puts $data }
}

# Kill service
proc ossmon::service::kill { type oid args } {

    switch -- $type {
     -n -
     -g {
        ::puts "$oid\ninteger\n0"
     }
     
     -s {
        # Format: -s OID.pid integer signal
        if { [lindex $args 0] != "integer" } { return }
        if { ![string is integer -strict [set pid [lindex [split $oid "."] end]]] } { return }
        if { ![string is integer -strict [set signal [lindex $args 1]]] } { return }
        
        if { $pid > 10 && $signal > 0 } {
          ossmon::log ossmon::service::kill: Killing -$signal $pid
          exec [ossmon::config kill-bin] -$signal $pid
        }
     }
    }
}

# Fixing configured process
proc ossmon::service::fix { name } {

    if { [set name [string trim $name]] == "" } { return }
    # Check for duplicate request
    if { [ossmon::cache::check "fix:cache" $name] } { return }
    # Find the proc to be fixed
    if { [set script [ossmon::config::match $name "fix-"]] == "" } {
      ossmon::log ossmon::service::fix: no entries for $name
      return 
    }
    # Call host specific fixing routines
    # entries are stored in sections [prog]
    # each section may contain any number of following commands:
    #   kill [-signal] process
    #   exec any shell command
    #   sleep SECONDS
::puts stderr $script

    foreach line $script {
      switch -- [lindex $line 0] {
       kill -
       killall {
          ossmon::log Executing: $line
          if { [catch { eval exec [ossmon::config killall-bin] [lrange $line 1 end] } errmsg] } {
            ::puts stderr $errmsg
          }
       } 
       exec {
           ossmon::log Executing: [lrange $line 1 end]
           if { [catch { exec /bin/sh -c "[join [lrange $line 1 end]]" } errmsg] } {
             ::puts stderr $errmsg
           }
       }
       sleep {
           after [lindex $line 1]000
       }
      }
    }
}

# Process syslog files for specified patterns
proc ossmon::service::syslog {} {
    
    foreach file [ossmon::config syslog-file] { ossmon::process::syslog $file }
    foreach dir [ossmon::config syslog-dir] {
      foreach file [glob -types f -nocomplain "$dir/*.log"] { ossmon::process::syslog $file }
    }
}

# Perform application specific events
# Event handler, handles GET/SET SNMP operations
# oid - event MIB OID
# data - empty for GET and non-empty for SET
proc ossmon::service::event { type oid args } {

    switch -- $oid {
     .1.3.6.1.4.1.19804.3.1 -
     .1.3.6.1.4.1.19804.3.1.0 {
        # Tail event
        # Write down file name to be shown in cache
        switch -- $type {
         -n -
         -g {
           ::puts "$oid\nstring\n[ossmon::cache::get tail:file]"
         }
         
         -s {
           if { [set data [lindex $args 1]] == "" } { return }
           ossmon::cache::put tail:file $data
         }
        }
     }

     .1.3.6.1.4.1.19804.3.2 -
     .1.3.6.1.4.1.19804.3.2.0 {
        # Kill process
        # Format: -signal PID [PID....]
        switch -- $type {
         -n -
         -g {
           ::puts "$oid\nstring\n"
         }
         
         -s {
           if { [set data [lindex $args 1]] == "" } { return }
           if { [set signal [lindex $data 0]] == "" } { return }
           foreach pid [lrange $data 1 end] { 
             ossmon::service::kill -s 0.$pid integer $signal
           }
         }
        }
     }
     
     .1.3.6.1.4.1.19804.3.3 -
     .1.3.6.1.4.1.19804.3.3.0 {
        # Fix process
        switch -- $type {
         -n -
         -g {
           ::puts "$oid\nstring\n"
         }
         
         -s {
           ossmon::service::fix [lindex $args 1]
         }
        }
     }

     .1.3.6.1.4.1.19804.3.4 -
     .1.3.6.1.4.1.19804.3.4.0 {
        # Ping event
        # Write down host name to be used for ping
        switch -- $type {
         -n -
         -g {
           ::puts "$oid\nstring\n[ossmon::cache::get ping:host]"
         }
         
         -s {
           if { [set data [lindex $args 1]] == "" } { return }
           ossmon::cache::put ping:host $data
         }
        }
     }

    }
    return
}

# Returns contents of the file beginning from the saved position
proc ossmon::process::syslog { log } {

    ossmon::log syslog:$log start

    # Check for last modification of the file
    if { [catch { file stat $log stat }] } { return }
    set now [clock seconds]
    set pattern [ossmon::config syslog-regexp]
    set maxlines [ossmon::config syslog-max-lines 50]
    set interval [ossmon::config syslog-noactivity-time 3600]
    # Check for silence, if within any period do not check for inactivity
    foreach { hour duration } [ossmon::config syslog-silence-period] {
      if { [ossmon::period $hour $duration] } {
        set interval $now
        break
      }
    }
    if { $now - $stat(mtime) > $interval } {
      ossmon::write "noActivity: $log: No activity in the last [ossmon::uptime $interval]($interval secs), last update on {[clock format $stat(mtime) -format "%m/%d/%y %H:%M:%S"]}"
    }
    if { [catch { set fd [open $log r] } errmsg] } {
      ossmon::log ossmon::syslog::process: $errmsg
      return
    }
    set count 0
    set size [file size $log]
    set position [ossmon::cache::get syslog:position:$log 0]
    if { $size < $position } { set position 0 }
    if { $size - $position > 1000000 } { set position [expr $size - 1000000] }
    # Read log file contents
    if { [catch {
      seek $fd $position
      while { ![eof $fd] } {
        if { [set line [string trim [gets $fd]]] == "" } { continue }
        if { [regexp -nocase $pattern $line] } {
          ::puts $line
          incr count
        }
        if { $count == $maxlines } { break }
      }
    } errmsg] } {
      ossmon::log ossmon::syslog::process: $errmsg
    }
    # Save current position
    ossmon::cache::put syslog:position:$log [tell $fd]
    close $fd
    ossmon::log syslog:$log stop
}

# Common functions
proc ossmon::process { command args } {

    fconfigure stdout -buffering none
    fconfigure stderr -buffering none

    ossmon::cache::init
    ossmon::config::init

    switch -- $command {
     psTable { 
        ::puts [exec ps -ef]
     }
     netstatTable { 
        ::puts [exec netstat -n]
     }
     killProcess { 
        eval ossmon::service::kill $args
     }
     tailTable {
        ossmon::service::tail
     }
     event { 
        eval ossmon::service::event $args
     }
     util { 
        eval ossmon::service::util $args
     }
     empty { 
        ossmon::service::util empty
     }
     snmpd { 
        ossmon::service::snmpd [lindex $args 0] 
     }
     fix { 
        ossmon::service::fix [lindex $args 0]
     }
     fixscript {
        foreach line [ossmon::config::match [lindex $args 0] "fix-"] { ::puts $line }
     }
     syslogTable {
        ossmon::service::syslog
     }
     pingTable {
        ossmon::service::ping
     }
    }
    ossmon::cache::shutdown
}

# Run the OSSMON manager
if { $argv == "" } {
  puts "ossmon.tcl command args"
  puts "where command is one of the:"
  puts " psTable - process list from ps -ef"
  puts " netstatTable - network connections from netstat -n"
  puts " syslogTable - returns lines from watched syslog files"
  puts " pingTable - performs pinging remote host from ping:host cache entry"
  puts " tailTable - list contents of the file from tail:file cache entry"
  puts " killProcess - kill process by given comma separated process IDs"
  puts "     format: -s OID.pid integer signal"
  puts "     example: ossmon.tcl killProcess -s .1.3.6.1.4.1.19804.2.1234 integer 9"
  puts "        sends signal 9 to process 1234"
  puts " event - SNMP SET events:"
  puts "   -s .1.3.6.1.4.1.19804.3.1 string FILENAME - saves file name for tailTable request in tail:file cache entry"
  puts "   -s .1.3.6.1.4.1.19804.3.2 string -SIGNAL PID PID... - kills processes by pid"
  puts "   -s .1.3.6.1.4.1.19804.3.3 string PROCNAME - fixes process by name"
  puts "   -s .1.3.6.1.4.1.19804.3.4 string HOSTNAME - saves host name for pingTable request in ping:host cache netry"
  puts " util - utilities:"
  puts "     config-get - returns config value by name"
  puts "     config-list - returns all config parameters"
  puts "     cache-list - returns all cache entries"
  puts "     cache-check - returns 1 if given entry is duplicate"
  puts "     cache-set - sets new caceh entry"
  puts " snmpd - snmpd agent restart/check status"
  puts "     check - checks if snmpd process is running, if not then starts it"
  puts "     restart - restarts snmpd agent"
  puts " fix - fixes failed process by name"
  puts " fixscript - returns script ot be used for fixing given process by name"
  exit
}
eval ossmon::process [join $argv]

