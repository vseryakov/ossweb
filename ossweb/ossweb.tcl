# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001
#
# $Id: ossweb.tcl 2873 2007-01-27 23:18:38Z vlad $

# Initialize subsystems
proc ossweb::init {} {

    # Server log file rotating at midnight
    ns_schedule_daily 0 0 ns_logroll

    # Job queue for background tasks
    ns_job create __ossweb_jobs [ossweb::config server:thread:jobs 3]

    foreach init_proc [nsv_array names __ossweb_init] {
      if { [catch { eval $init_proc } errmsg] } {
        ns_log Error ossweb::init: $init_proc: $errmsg
      }
    }
}

# Source reloader for development mode
proc ossweb::reload { args } {

    if { [catch {
      foreach file [lsort [glob -nocomplain [ns_library shared]/ossweb/*.tcl]] {
        if { [string match */init.tcl $file] || ![ns_filestat $file stat] } {
          continue
        }
        # Tcl file signature, cached and current
        set cookie0 $stat(mtime):$stat(ino):$stat(dev):$stat(size)
        set cookie1 [info procs ${file}.dev]
        if { $cookie1 == "" || [$cookie1] != $cookie0 } {
          ::proc ${file}.dev {} "return $cookie0"
          namespace eval :: source $file
          ns_log dev ossweb::reload: $file changed
        }
      }
    } errmsg] } {
      ns_log Error ossweb::reload: $errmsg: $::errorInfo
    }
}

# Generates a random string
proc ossweb::random {} {

    variable random_seed
    set value [ns_sha1 "[ns_time][ns_rand 2147483645][::clock clicks]$random_seed"]
    set random_seed [string range $value 0 10]
    return [ns_sha1 [string range $value 11 39]]
}

# Returns random number between 0 and specified max
proc ossweb::random_range { { range 100 } } {

    nsv_set __ossweb_rand seed [expr ([nsv_get __ossweb_rand seed] * [nsv_get __ossweb_rand ia] + [nsv_get __ossweb_rand ic]) % [nsv_get __ossweb_rand im]]
    set random [expr [nsv_get __ossweb_rand seed]/double([nsv_get __ossweb_rand im])]
    return [expr int($random * $range)]
}

proc ossweb::version { args } {

    ns_parseargs { {-module ossweb} {-rev f} } $args

    set result [list]
    foreach name [namespace eval :: { namespace children }] {
      set modname [string range $name 2 end]
      if { [info exists "${name}::version"] && ($module == "" || [regexp $module $modname]) } {
        set modver [subst "\$${name}::version"]
        if { $rev == "t" } {
          if { [regexp {Revision: ([0-9]+)} $modver d modver] } {
            lappend result $modname $modver
          }
        } else {
          lappend result $modver
        }
      }
    }
    return $result
}

# Returns 1 if database is working
proc ossweb::database {} {

    return [nsv_exists __ossweb_config OSSWEB:DB]
}

# Returns the value of a configuration parameter from config file or
# config database table.
# If the parameter doesn't exist, returns the default specified as the third argument (or
# empty string if not default is specified).  Note that AOLserver reads these files when
# the server starts up and stores parameters in an in-memory hash table.
# If section is psecified, try to locate parameter under oss/section in config file
# or section:parameter from database config table. If value is not lcoated, try
# to find it in global section or config list.
proc ossweb::config { param { default "" } } {

    # Check that configuration table is loaded
    if { ![nsv_exists __ossweb_config OSSWEB:CONFIG] } {
      nsv_array reset __ossweb_config { OSSWEB:CONFIG 1 }

      # Verify if database working
      if { ![nsv_exists __ossweb_config OSSWEB:DB] } {
         if { [ossweb::sql::columns ossweb_config] != "" } {
            nsv_set __ossweb_config OSSWEB:DB 1
         }
      }

      # Do not use XQL here to avoid XQL loading loops
      if { [nsv_exists __ossweb_config OSSWEB:DB] } {
          ossweb::db::foreach "SELECT name,value FROM ossweb_config" {
             nsv_set __ossweb_config $name $value
          }
      }
    }  
    if { [set value [ns_config "ns/server/[ns_info server]/ossweb" $param NULL]] != "NULL" } {
      return $value
    }
    # Try global config
    if { [nsv_exists __ossweb_config $param] } {
      return [nsv_get __ossweb_config $param]
    }
    return $default
}

# Set a config parameter, if db is set to 1 also update database
proc ossweb::set_config { name { value "" } { db 0 } } {

    nsv_set __ossweb_config $name $value
    if { $db } {
      if { $value == "" } {
        ossweb::db::exec sql:ossweb.config.delete
      } else {
        ossweb::db::exec sql:ossweb.config.update
        if { ![ossweb::db::rowcount] } {
          ossweb::db::exec sql:ossweb.config.create
        }
      }
    }
}

# Returns list of config parameters matching the pattern
proc ossweb::list_config { pattern } {

    set result ""
    foreach { name value } [nsv_array get __ossweb_config $pattern] {
      lappend result $name $value
    }
    return $result
}

# Refreshes config cache
proc ossweb::reset_config { args } {

    ns_parseargs { {-cluster f} } $args

    nsv_array reset __ossweb_config {}

    if { $cluster == "t" & [info procs ossweb::cluster] != "" } {
      ossweb::cluster ::ossweb::reset_config ""
    }
}

# Determines whether a variable both exists and is not an empty string,
# returns 1 if exists otherwise 0
proc ossweb::exists { name } {

    upvar 1 $name var
    if { [array exists var] || ([info exists var] && $var != "") } {
      return 1
    }
    return 0
}

# Returns 1 if value is in the list
proc ossweb::lexists { list value } {

    return [expr [lsearch -exact $list $value] > -1]
}

# Builds correct image path and name, if just image name is specified it
# prepends correct image path.
proc ossweb::image_name { name } {

    if { $name != "" && [string index $name 0] != "/" } {
      set name "[ossweb::config server:path:images "/img"]/$name"
    }
    return $name
}

# Returns image name if exists
proc ossweb::image_exists { id { path "" } { root "" } } {

    if { $root == "" } {
      set root [ns_info pageroot]
    }
    foreach img "$id.jpg $id.gif $id.png" {
      if { [ns_filestat $root/$path/$img] } {
        return $path/$img
      }
    }
    return
}

# Takes the place of an if (or switch) statement -- convenient because it's
# compact and you don't have to break out of an ns_write if you're in one.
# args: same order as in sql: first the unknown value, then any number of
# pairs denoting "if the unknown value is equal to first element of pair,
# then return second element", then if the unknown value is not equal to any
# of the first elements, return the last arg if exists,
# or return the value itself
# Ex:  [ossweb::decode $value 1 "one" 2 "two" "infinite"]
#      [ossweb::decode $value one 1 two 2 three 3]
proc ossweb::decode { value args } {

    set default $value
    set length [llength $args]
    if { [expr $length % 2] } {
      set default [lindex $args end]
      incr length -1
    }
    for { set i 0 } { $i < $length } { incr i 2 } {
      if { $value == [lindex $args $i] } {
        return [lindex $args [incr i]]
      }
    }
    return $default
}

# Brief version of if then else syntax
proc ossweb::iftrue { if then { else "" } } {

    uplevel "
      if { $if } { return \[subst {$then}] }
      return \[subst {$else}]
    "
}

# Returns first non empty value or the last one as default
proc ossweb::nvl { args } {

    if { [llength $args] == 1 } {
      lappend args ""
    }
    foreach arg [lrange $args 0 end-1] {
      if { $arg != "" } {
        return $arg
      }
    }
    return [lindex $args end]
}

# Return 1 if value is boolean true
proc ossweb::true { value { null 0 } } {

    if { [set value [string tolower $value]] == "" && $null } { return }
    if { [lsearch { 1 t true y yes on } $value] >= 0 } { return 1 }
    return 0
}

# Returns first non empty value from the list of variables,
# returns default which is the last item in the argument list
# if all are nonexistent or empty. Accepts variable names to
# be checked, not values itself.
# Ex: ossweb::coalesce var1 var2 var3 None
proc ossweb::coalesce { args } {

    if { [llength $args] == 1 } {
      lappend args ""
    }
    foreach arg [lrange $args 0 end-1] {
      upvar 1 $arg var
      if { [array exists var] || ([info exists var] && $var != "") } {
        return $var
      }
    }
    return [lindex $args end]
}

# Returns message text according to given message type,
# you can call this function for pre-defined standard message.
# Table 'msgs' contains all messages.
proc ossweb::message { type } {

    if { $type == "" } {
      return
    }
    if { ![ossweb::cache exists standard:msg::] } {
      ossweb::db::read ossweb_msgs -type foreach -eval {
        ossweb::cache set standard:msg:$msg_name $description
      }
      ossweb::cache set standard:msg:: 1
    }
    return [ossweb::cache get standard:msg:$type]
}

# Converts a string into hex string
proc ossweb::hexify { data } {

    set out ""
    for { set i 0 } { $i < [string length $data] } { incr i } {
      if { [scan [string index $data $i] "%c" val] } {
        append out [format "%02X" $val]
      }
    }
    return $out
}

# Converts hex string into regular string
proc ossweb::dehexify { data } {

    set out ""
    for { set i 0 } { $i < [string length $data] } { set i [expr { $i + 2 }] } {
      if { [scan [string range $data $i [expr { $i + 1 }]] "%x" val] } {
        append out [format "%c" $val]
      }
    }
    return $out
}

# Pad a string with leading zeroes
proc ossweb::pad0 { string size } {

    if { ![string is integer -strict $string] } {
      return $string
    }
    set val [string repeat "0" [expr $size - [string length $string]]]
    append val $string
    return $val
}

# Trim the leading zeroes from the value
proc ossweb::trim0 { value } {

    set val [string trimleft $value 0]
    if { $value != "" && $val == "" } {
      return 0
    }
    return $val
}

# Get the directory portion of a path.
proc ossweb::dirname { path } {

    regsub -all {//} $path {/} path
    if { ![string equal [string index $path end] /]} {
      set path [file dirname $path]/
    }
    return $path
}

# Check if a value is less than zero, but return false
# if the value is an empty string
proc ossweb::negative { value } {

    if { $value == "" } {
      return 0
    }
    return [expr $value < 0]
}

# Returns the list with all files starting from the given path and
# including files from each subdirectory as well.
# Returns only those files that matches specified regular expression.
proc ossweb::file_list { path match args } {

    ns_parseargs { {-dir f} } $args

    set files [list]
    # Get all possible images
    foreach file [lsort [glob -nocomplain -types {d f r} -path $path/ *]] {
      if { [file isdirectory $file] } {
        if { $dir == "t" } {
          lappend files $file
        } else {
          foreach file [::ossweb::file_list $file $match] {
            lappend files $file
          }
        }
      } else {
        if { $dir == "f" } {
          if { ![regexp -nocase $match $file] } { continue }
          lappend files $file
        }
      }
    }
    return $files
}

# Return a list of numbers, {1 2 3 ... n}, used for generating sequences
# of numbers with given range.
proc ossweb::number_list { last { first 0 } } {

    set result [list]
    for { set i $first } { $i <= $last } { incr i } {
      lappend result $i
    }
    return $result
}

# Creates list of numbers to be used as options in select boxes
#  size defines item size, smaller numbers will be padded with zeros
proc ossweb::option_list { first last { step 1 } { size 0 } } {

    set result [list [list "--" {}]]
    for { set i $first } { $i <= $last } { incr i $step } {
      set val [ossweb::pad0 $i $size]
      lappend result [list $val $val]
    }
    return $result
}

# Reads a text file.
#  path The absolute path to the file
#  Returns a string with the contents of the file.
proc ossweb::read_file { path args } {

    ns_parseargs { {-encoding binary} } $args

    if { ![ns_filestat $path] } {
      return
    }
    set text ""
    if { [catch {
      set fd [::open $path]
      fconfigure $fd -translation binary -encoding $encoding
      set text [::read $fd]
      ::close $fd
    } errMsg] } {
      ns_log Error ossweb::read_file: $errMsg
      catch { ::close $fd }
    }
    return $text
}

# Creates a text file.
#  path The absolute path to the file
#  data to be saved
#  Returns a string with the contents of the file.
proc ossweb::write_file { path data args } {

    ns_parseargs { {-empty t} {-mode w} {-encoding binary} } $args

    if { $empty == "f" && $data == "" } {
      return 0
    }
    if { [catch {
      set fd [::open $path $mode]
      fconfigure $fd -translation binary -encoding $encoding
      puts -nonewline $fd $data
      ::close $fd
    } errMsg] } {
      ns_log Error ossweb::write_file: $errMsg
      catch { ::close $fd }
      return -1
    }
    return 0
}

# Call object's method, search through object hierarchy
proc ossweb::oproc { nm proc params { default "" } } {

    if { [info proc ${nm}::$proc] != "" } {
      return [eval ${nm}::$proc $params]
    }
    # Direct parent
    if { [info exists ${nm}::superclass] } {
      set nm [namespace parent $nm]::[set ${nm}::superclass]
      return [ossweb::oproc $nm $proc $params $default]
    }
    # Namespace parent
    set nms [namespace parent $nm]
    if { $nm != "" } {
      return [ossweb::oproc $nm $proc $params $default]
    }
    return $default
}

# Return object's variable, search through object hierarchy
proc ossweb::ovar { nm var { default "" } } {

    if { [info exists ${nm}::$var] } {
      return [set ${nm}::$var]
    }
    # Direct parent
    if { [info exists ${nm}::superclass] } {
      set nm [namespace parent $nm]::[set ${nm}::superclass]
      return [ossweb::ovar $nm $var $default]
    }
    # Namespace parent
    set nm [namespace parent $nm]
    if { $nm != "" } {
      return [ossweb::ovar $nm $var $default]
    }
    return $nm
}

# Process template:
# Variable format:
#   @name@                  - simple text variable
#   @name^default@          - variable with default value
#   @name%datatype@         - variable with datatype
#   @name%datatype^default@ - variable with datatype and default
proc ossweb::template { name args } {

    ns_parseargs { {-level {[expr [info level]-1]}} } $args

    upvar #$level $name body
    if { ![info exists body] } {
      return -1
    }

    regsub -all {[]["\\$]} $body {\\&} body ;# Escape quotes and other special symbols"

    while {[regsub -all {@([a-zA-Z0-9_:-]+)\%([^@^]+)\^([^@]+)@} $body "\[ossweb::datatype::value \\1 \\2 -default {\\3}]" body]} {}
    while {[regsub -all {@([a-zA-Z0-9_:-]+)\%([^@^]+)@} $body "\[ossweb::datatype::value \\1 \\2]" body]} {}
    while {[regsub -all {@([a-zA-Z0-9_:-]+)\^([^@]+)@} $body "\[ossweb::coalesce \\1 {\\2}]" body]} {}
    while {[regsub -all {@([a-zA-Z0-9_:-]+)@} $body "\[ossweb::coalesce \\1\]" body]} {}
    if { [catch { uplevel #$level "set $name \[subst \$$name]" } errmsg] } {
      ns_log Error ossweb::template: $name: $errmsg
      return -1
    }
    return 0
}

# Encrypts the given string
proc ossweb::encrypt { str args } {

    ns_parseargs { {-secret ""} {-token ""} } $args

    if { $secret == "" } {
      set secret [ossweb::conn::shared_secret]
    }
    set token [ns_sha1 $secret$token]
    set slen [string length $str]
    set tlen [string length $token]
    if { $slen > $tlen } {
      set token [string repeat $token [expr $slen / $tlen + 1]]
    }
    set key ""
    for { set i 0 } { $i < $slen } { incr i } {
      set c1 [scan [string index $token $i] %c]
      set c2 [scan [string index $str $i] %c]
      append key [binary format c [expr $c1 ^ $c2]]
    }
    return [crc32 $str](*)$key
}

# Dencrypts the given string
proc ossweb::decrypt { str args } {

    ns_parseargs { {-secret ""} {-token ""} {-crc ""} } $args

    # Extract CRC code
    if { [set idx [string first (*) $str]] == -1 } {
      return
    }
    set crc [string range $str 0 [incr idx -1]]
    set str [string range $str [incr idx 4] end]

    if { $secret == "" } {
      set secret [ossweb::conn::shared_secret]
    }
    set token [ns_sha1 $secret$token]
    set slen [string length $str]
    set tlen [string length $token]
    if { $slen > $tlen } {
      set token [string repeat $token [expr $slen / $tlen + 1]]
    }
    set key ""
    for { set i 0 } { $i < $slen } { incr i } {
      set c1 [scan [string index $token $i] %c]
      set c2 [scan [string index $str $i] %c]
      append key [binary format c [expr $c1 ^ $c2]]
    }
    # Verify given CRC code
    if { $crc != "" } {
      if { [crc32 $key] != $crc } {
        return
      }
    }
    return $key
}

proc ossweb::>>> { x1 x2 } {

    # set __signbit to highest available bit.
    global __signbit

    if { ![info exists __signbit] } {
        for {set v 1} {$v != 0} {set __signbit $v; set v [expr {$v<<1}]} {}
    }
    expr {($x1>>$x2) & ~($__signbit>>($x2-1))}
}

proc ossweb::crc32 { instr } {

    variable CRCTABLE

    set crc_value 0xFFFFFFFF

    for { set idx 0 } { $idx < [string length $instr] } { incr idx } {
       set result [binary scan [string index $instr $idx] c num_value]
       set crc_value [expr [lindex $CRCTABLE [expr ($crc_value ^ $num_value) & 0xFF]] ^ [>>> $crc_value 8]]
    }
    return [format %u [expr $crc_value ^ 0xFFFFFFFF]]
}

# checks ACL by calling ossweb::conn::check_acl
proc ossweb::acl { acl } {

    return [ossweb::conn::check_acl -acl $acl]
}

# Date object support
# Usage:
#   ossweb::date -set key date value
#   ossweb::date key date
#   ossweb::date command
proc ossweb::date { command args } {

    # General purpose date commands, there is no date object passed
    switch -- $command {
     scan {
        if { [regexp {^([0-9-]+ [0-9:]+)} [lindex $args 0] d dt] } {
           if { ![catch { clock scan $dt } time] } {
              return $time
           } 
        }
     } 

     today {
        array set dateobj [::ossweb::date -set [lindex $args 0] clock [clock seconds]]
        set dateobj(minutes) ""
        set dateobj(hours) ""
        set dateobj(seconds) ""
        return [array get dateobj]
     }

     now {
        return [::ossweb::date -set [lindex $args 0] clock [clock seconds]]
     }

     weekDayName {
        set day [ossweb::trim0 [lindex $args 0]]
        if { ![string is integer -strict $day] } { return "" }
        set short [ossweb::nvl [lindex $args 1] 0]
        variable weekDayNames
        return [lindex $weekDayNames [expr ($day*2)+$short]]
     }

     monthName {
        set month [ossweb::trim0 [lindex $args 0]]
        if { ![string is integer -strict $month] } { return "" }
        set short [ossweb::nvl [lindex $args 1] 0]
        variable monthNames
        return [lindex $monthNames [expr ($month*2)+$short]]
     }

     uptime {
        set uptime [lindex $args 0]
        set type [lindex $args 1]
        if { $uptime == "" } {
          return
        }
        set days [expr $uptime / 86400]
        set uptime [expr $uptime % 86400]
        set hrs [expr $uptime / 3600]
        set uptime [expr $uptime % 3600]
        set mins [expr $uptime / 60]
        set secs [expr [lindex $args 0] - (($days * 86400) + ($hrs * 3600) + ($mins * 60))]
        switch -- $type {
         unix {
           set result "[ossweb::pad0 $days 2]d[ossweb::pad0 $hrs 2]h[ossweb::pad0 $mins 2]m[ossweb::pad0 $secs 2]s"
         }

         interval {
           set result "[ossweb::pad0 $days 2]:[ossweb::pad0 $hrs 2]:[ossweb::pad0 $mins 2]:[ossweb::pad0 $secs 2]"
         }

         default {
           set result ""
           if { $days > 0 } {
             append result " $days day"
             if { $days > 1 } { append result s }
           }
           if { $hrs > 0 } {
             append result " $hrs "
             if { $type != "short" } { append result hour } else { append result hr }
             if { $hrs > 1 } { append result s }
           }
           if { $mins > 0 } {
             append result " $mins "
             if { $type != "short" } { append result minute } else { append result min }
             if { $mins > 1 } { append result s }
           }
           if { $secs > 0 } {
             append result " $secs "
             if { $type != "short" } { append result second } else { append result sec }
             if { $secs > 1 } { append result s }
           }
         }
        }
        return $result
     }

     interval {
        set uptime [ossweb::trim0 [lindex $args 0]]
        if { $uptime == "" } { return }
        set hrs [expr $uptime / 3600]
        set uptime [expr $uptime % 3600]
        set mins [expr $uptime / 60]
        set secs [expr [lindex $args 0] - (($hrs * 3600) + ($mins * 60))]
        return "$hrs:$mins:$secs"
     }

     julianDate {
        set mm [ossweb::trim0 [lindex $args 0]]
        set dd [ossweb::trim0 [lindex $args 1]]
        set yy [ossweb::trim0 [lindex $args 2]]
        set ggg 1
        if { $yy <= 1585 } { set ggg 0 }
        set jd [expr -1 * int(7 * (int(($mm + 9) / 12) + $yy) / 4)]
        set s 1
        if { $mm - 9 < 0 } { set s -1 }
        set a [expr abs($mm - 9)]
        set j1 [expr int($yy + $s * int($a / 7))]
        set j1 [expr -1 * int((int($j1 / 100) + 1) * 3 / 4)]
        set jd [expr $jd + int(275 * $mm / 9) + $dd + ($ggg * $j1)]
        set jd [expr $jd + 1721027 + 2 * $ggg + 367 * $yy]
        if { $dd == 0 && $mm == 0 && $yy == 0 } { return }
        return $jd
     }

     daysInMonth {
        set month [ossweb::trim0 [lindex $args 0]]
        if { ![string is integer -strict $month] } { return 0 }
        variable monthDays
        set days [lindex $monthDays $month]
        if { $month == 2 && [ossweb::date leapYear [lindex $args 1]] } { incr days }
        return $days
     }

     dayOfYear {
        set secs [clock scan "[lindex $args 1]/[lindex $args 0]/[lindex $args 2]"]
        return [ns_fmttime $secs "%j"]
     }

     weekOfYear {
        set secs [clock scan "[lindex $args 1]/[lindex $args 0]/[lindex $args 2]"]
        return [ns_fmttime $secs "%U"]
     }

     dayOfWeek {
        set secs [clock scan "[lindex $args 1]/[lindex $args 0]/[lindex $args 2]"]
        return [ns_fmttime $secs "%w"]
     }

     leapYear {
        set year [ossweb::trim0 [lindex $args 0]]
        if { ![string is integer -strict $year] } { return 0 }
        if { (![expr $year % 4] && [expr $year % 100]) || ![expr $year % 400] } { return 1 }
        return 0
     }

     monthArray {
        set month [lindex $args 0]
        set year [lindex $args 1]
        set dm [ossweb::date daysInMonth $month $year]
        set dw [expr ([ossweb::date dayOfWeek 1 $month $year] + 7) % 7]
        set day 1
        for { set i 0 } { $i < 43 } { incr i } { lappend days "" }
        while { $dm > 0 } {
          set days [lreplace $days $dw $dw [ossweb::pad0 $day 2]]
          incr dm -1
          incr day
          incr dw
        }
        return $days
     }

     weekArray {
        set secs [clock scan "[lindex $args 1]/[lindex $args 0]/[lindex $args 2] 12:00"]
        set dow [expr $secs-(86400*[ns_fmttime $secs "%w"])]
        for { set i 0 } { $i < 7 } { incr i } {
          lappend days [ns_fmttime $dow "%m/%d/%Y"]
          incr dow 86400
        }
        return $days
     }

     nextDay {
        set date [clock scan "[lindex $args 1]/[lindex $args 0]/[lindex $args 2] 12:00"]
        return [expr $date+86400]
     }

     prevDay {
        set date [clock scan "[lindex $args 1]/[lindex $args 0]/[lindex $args 2] 12:00"]
        return [expr $date-86400]
     }

     nextMonth {
        set date [clock scan "[lindex $args 0]/[ossweb::date daysInMonth [lindex $args 0] [lindex $args 1]]/[lindex $args 1] 12:00"]
        return [expr $date+86400]
     }

     prevMonth {
        set date [clock scan "[lindex $args 0]/1/[lindex $args 1] 12:00"]
        return [expr $date-86400]
     }

     duration {
        if { [set duration [string trim [lindex $args 0]]] == "" } { return -1 }
        # Parse duration
        if { [regexp -nocase {^([0-9]+)m$} $duration d minutes] } {
          set duration [expr $minutes*60]
        } elseif { [regexp -nocase {^([0-9]+)h$} $duration d hours] } {
          set duration [expr $hours*3600]
        } elseif { [regexp -nocase {^([0-9]+)w$} $duration d weeks] } {
          set duration [expr $weeks*86400*7]
        } elseif { [regexp -nocase {^([0-9]+)d$} $duration d days] } {
          set duration [expr $days*86400]
        } elseif { [regexp -nocase {^([0-9][0-9]):([0-9][0-9]):([0-9][0-9])$} $duration d hours minutes seconds] } {
          set duration [expr [ossweb::trim0 $hours]*3600+[ossweb::trim0 $minutes]*60+[ossweb::trim0 $seconds]]
        } elseif { ![string is integer -strict $duration] } {
          return -1
        }
        return $duration
     }

     period {
        set now [clock seconds]
        if { [set period [string trim [lindex $args 0]]] == "" } { return 0 }
        if { [set duration [ossweb::date duration [lindex $args 1]]] == -1 } { return 0 }
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
    }
    # Setup array for date object
    array set dateobj { year "" month "" day "" hours "" minutes "" seconds "" day2 "" year2 "" month2 "" }

    # Set operation, date is third item
    switch -- $command {
     -check {
        foreach { name value } [lindex $args 0] { set temp($name) $value }
        foreach key [array names dateobj] {
          if { ![info exists temp($key)] } { return 0 }
        }
        return 1
     }

     -expr {
        set clock [eval expr [ossweb::date clock [lindex $args 0]] [lrange $args 1 end]]
        return [ossweb::date parse2 $clock]
     }

     -set {
        foreach { name value } [lindex $args 0] { set dateobj($name) $value }
        foreach { key value } [lrange $args 1 end] {
          switch -- $key {
           short_year {
             if { [string is integer -strict $value] } {
               if { $value < 69 } {
                 set dateobj(year) [expr $value + 2000]
               } else {
                 set dateobj(year) [expr $value + 1900]
               }
             }
           }
           clock {
             set now [clock format [lindex $args 2] -format "%Y %m %d %H %M %S"]
             set dateobj(clock) [lindex $args 2]
             set dateobj(year) [lindex $now 0]
             set dateobj(month) [lindex $now 1]
             set dateobj(day) [lindex $now 2]
             set dateobj(hours) [lindex $now 3]
             set dateobj(minutes) [lindex $now 4]
             set dateobj(seconds) [lindex $now 5]
           }
           ampm {
             if { [string is integer -strict $dateobj(hours)] } {
               if { $value == "pm" && $dateobj(hours) < 12 } {
                 set dateobj(hours) [ossweb::pad0 [expr [ossweb::trim0 $dateobj(hours)] + 12] 2]
               } elseif { $value == "am" } {
                 set dateobj(hours) [ossweb::pad0 [expr [ossweb::trim0 $dateobj(hours)] % 12] 2]
               }
             }
           }
           default {
             set dateobj($key) [ossweb::pad0 $value 2]
           }
          }
        }
        return [array get dateobj]
     }

     parse {
        set value [string trim [lindex $args 0]]
        # Date should be in format yyyy-mm-dd[ hh:mi[:ss]]
        if { ![regexp {^([0-9]+)\-([0-9]+)\-([0-9]+)\ ?([0-9]+)?\:?([0-9]+)?\:?([0-9]+)?} $value time year month day hours minutes seconds] } {
          if { ![regexp {^([0-9]+)\:([0-9]+)\:?([0-9]+)?} $value time hours minutes seconds] } {
            return $value
          }
        }
        foreach name { year month day hours minutes seconds } {
          set dateobj($name) [ossweb::pad0 [ossweb::coalesce $name ""] 2]
        }
        return [array get dateobj]
     }

     parse2 {
       # Date may be represented by seconds or string mm/dd/yy
       set date [lindex $args 0]
       if { ![string is integer -strict $date] } {
         # See if this is date object already
         if { [regexp {day2.+month2|month2.+day2} $date] } {
           return $date
         }
         # Strip off timezone from PostgreSQL dates, everything is in local time
         regsub {(\:[0-9][0-9])(\+[0-9][0-9])$} $date {\1} date
         regsub {(\.[0-9]+-[0-9][0-9])$} $date {} date
         regsub {(\:[0-9][0-9])(-[0-9][0-9])$} $date {\1} date
         # Parse date string
         if { [catch { set date [clock scan $date] } errmsg] } {
           ossweb::conn::log Error ossweb::date: parse2: $date: $errmsg
           set date [ns_time]
         }
       }
       foreach { month day year hours minutes seconds } [ns_fmttime $date "%m %d %Y %H %M %S"] {}
       set dateobj(month) $month
       set dateobj(day) $day
       set dateobj(year) $year
       set dateobj(hours) $hours
       set dateobj(minutes) $minutes
       set dateobj(seconds) $seconds
       set dateobj(clock) $date
       return [array get dateobj]
     }
    }

    # The rest are regular commands
    foreach { name value } [lindex $args 0] { set dateobj($name) $value }
    set result ""
    # Default value
    set default [lindex $args 1]
    switch -- $command {
     clock {
        if { $dateobj(year) != "" && $dateobj(month) != "" && $dateobj(day) != "" } {
          append result $dateobj(month) "/" $dateobj(day) "/" $dateobj(year)
        }
        if { $dateobj(hours) != "" && $dateobj(minutes) != "" } {
          if { $result != "" } { append result " " }
          append result $dateobj(hours) ":" $dateobj(minutes)
          if { $dateobj(seconds) != "" } {
            append result ":" $dateobj(seconds)
          }
        }
        if { [catch { set result [clock scan $result] } errmsg] } {
          ns_log Error ossweb::date: clock: $result: $errmsg
          set result 0
        }
     }

     range {
        # Returns SQL statement as BETWEEN for date range
        # -list t returns two dates in text format
        # -clock returns two dates as seconds
        if { $dateobj(day) == "" } {
          set month1 [ossweb::nvl $dateobj(month) 1]
          set month2 [ossweb::nvl $dateobj(month) 12]
        } else {
          set month1 [ossweb::nvl $dateobj(month) [clock format [clock seconds] -format "%m"]]
          set month2 [ossweb::nvl $dateobj(month2) $month1]
        }
        set year1 [ossweb::nvl $dateobj(year) [clock format [clock seconds] -format "%Y"]]
        set year2 [ossweb::nvl $dateobj(year2) $year1]
        set day1 [ossweb::nvl $dateobj(day) 1]
        set days2 [ossweb::date daysInMonth $month2 $year2]
        set day2 [ossweb::nvl $dateobj(day2) [ossweb::nvl $dateobj(day) $days2]]
        if { $day2 > $days2 } {
          set day2 $days2
        }
        switch -- $default {
         -clock {
           set result "[clock scan "$month1/$day1/$year1 00:00"] [clock scan "$month2/$day2/$year2 23:59:59"]"
         }

         -date {
           set result "{$year1-$month1-$day1 00:00} {$year2-$month2-$day2 23:59:59}"
         }

         default {
           set result "BETWEEN '$year1-$month1-$day1 00:00' AND '$year2-$month2-$day2 23:59:59'"
         }
        }
     }

     short_year {
        if { $dateobj(year) > 0 } {
          set result [ossweb::pad0 [expr [ossweb::trim0 [lindex $dateobj(year) 0]] % 100] 2]
        }
     }

     short_hours {
        if { [string is integer -strict $dateobj(hours)] } {
          set value [expr [ossweb::trim0 $dateobj(hours)] % 12]
          if { $value == 0 } { return 12 }
          set result [ossweb::pad0 $value 2]
        }
     }

     dow {
        set result [ossweb::date dayOfWeek $dateobj(day) $dateobj(month) $dateobj(year)]
     }

     ampm {
        if { $dateobj(hours) > 0 && $dateobj(hours) <= 11 } { return "am" }
        if { $dateobj(hours) > 11 } { return "pm" }
     }

     date {
        if { $dateobj(year) != "" && $dateobj(month) != "" && $dateobj(day) != "" } {
          append result $dateobj(year) "-" $dateobj(month) "-" $dateobj(day)
        }
     }

     time {
        if { $dateobj(hours) != "" && $dateobj(minutes) != "" } {
          append result $dateobj(hours) ":" $dateobj(minutes)
          if { $dateobj(seconds) != "" } {
            append result ":" $dateobj(seconds)
          }
        }
     }

     datetime -
     sql_date {
        set result [string trim "[ossweb::date date [lindex $args 0]] [ossweb::date time [lindex $args 0]]"]
     }

     pretty_date {
        if { $dateobj(year) != "" && $dateobj(month) != "" && $dateobj(day) != "" } {
          append result $dateobj(month) "/" $dateobj(day) "/" $dateobj(year)
        }
     }

     pretty_datetime {
        set result [string trim "[ossweb::date pretty_date [lindex $args 0]] [ossweb::date time [lindex $args 0]]"]
     }

     nice_date {
        if { $dateobj(year) != "" && $dateobj(month) != "" && $dateobj(day) != "" } {
          append result [ossweb::date monthName $dateobj(month)] " " $dateobj(day) ", " $dateobj(year)
        }
     }

     nice_datetime {
        set result [string trim "[ossweb::date nice_date [lindex $args 0]] [ossweb::date time [lindex $args 0]]"]
     }

     default {
        if { [info exists dateobj($command)] } {
          set result $dateobj($command)
        }
     }
    }
    if { $result != "" } {
      return $result
    }
    return $default
}


# Put message in the email message queue.
# Returns -1 on error or 0 on success
#  -headers is a list with additional SMTP headers in the form: name value ...
#  -direct t tells to use mail deliver directly without submitting into OSS message queue
#  -domain specifies which domain name to use in case of incomplete email from address
#  -files specifies list with absolute patch of files to be attached
#  -urgent t calls message queue scheduler right after submitting the message
#  -bcc specifies additonal address to be sent by BCC
proc ossweb::sendmail { rcpt_to mail_from subject body args } {

    ns_parseargs { {-headers ""}
                   {-domain ""}
                   {-files ""}
                   {-direct f}
                   {-bcc ""}
                   {-cc ""}
                   {-error ""}
                   {-message_type ""}
                   {-content_type ""}
                   {-filedir ""} } $args

    if { $error != "" } { upvar $error errmsg }
    if { $content_type == "" } { set content_type "text/plain" }
    # Check from email and append current host name if missing
    if { [string first @ $mail_from] == -1 } {
      append mail_from @ [ossweb::nvl $domain [ns_info hostname]]
    }
    if { [string first @ $rcpt_to] == -1 } {
      append rcpt_to @ [ossweb::nvl $domain [ns_info hostname]]
    }
    # Append attachements
    if { $files != "" } {
      set boundary "[pid][clock seconds][clock clicks][ns_rand]"
      lappend headers "MIME-Version" "1.0" \
                      "Content-Type" "multipart/mixed; boundary=\"$boundary\""
      # Insert text as a first part of the envelope
      set body "--$boundary\nContent-Type: $content_type; charset=us-ascii\n\n$body\n\n"
      foreach name $files {
        append body "--$boundary\n"
        switch [set type [ns_guesstype $name]] {
         "" - "text/plain" { set type "application/octet-stream" }
        }
        append body "Content-Type: $type; name=\"[file tail $name]\"\n"
        append body "Content-Disposition: attachment; filename=\"[file tail $name]\"\n"
        append body "Content-Transfer-Encoding: base64\n\n"
        append body [ns_uuencode [ossweb::read_file $filedir$name]] "\n\n"
      }
    } else {
      # simple MIME envelope
      if { $content_type != "text/plain" } {
        lappend headers MIME-Version 1.0 Content-Type $content_type
      }
    }
    # Send the message without submitting into message queue
    if { $direct == "t" } {
      set hdrs [ns_set new]
      foreach { name value } $headers {
        switch [set name [string tolower $name]] {
         cc - bcc { append $name $value, }
        }
        ns_set update $hdrs $name $value
      }
      if { [catch { ns_sendmail $rcpt_to $mail_from $subject $body $hdrs $bcc $cc } errmsg] } {
        ns_set free $hdrs
        ossweb::conn::log Error ossweb::sendmail $mail_from: $rcpt_to: $subject: $errmsg
        return -1
      }
      ns_set free $hdrs
      return 0
    }
    # Append CC/BCC header, scheduler will extract it and process accordingly
    if { $cc != "" } { lappend headers Cc $cc }
    if { $bcc != "" } { lappend headers Bcc $bcc }
    # Submit into the message queue
    set args $headers
    if { [ossweb::db::exec sql:ossweb.sendmail] } {
      ossweb::conn::log Error ossweb::sendmail $mail_from: $rcpt_to: $subject
      return -1
    }
    # Clear message queue search cache
    ossweb::sql::multipage mqueue -flush t
    return 0
}

# Perform get/set operations on a multirow datasource,
# -level by default datasource is created in caller frame,
#        this option specifies absolute frame level position
# Allowed operations:
#     create, drop, append, update, copy, local, size, get, set
proc ossweb::multirow { args } {

    ns_parseargs { {-level {[expr [info level]-1]}} -- op name args } $args

    upvar #$level $name:rowcount rowcount $name:columns columns

    switch -exact -- $op {

      exists {
        return [info exists columns]
      }

      create {
        set rowcount 0
        set columns $args
      }

      drop {
        if { [info exists columns] } { unset columns }
        if { [info exists rowcount] } {
          while { $rowcount } {
            upvar #$level $name:$rowcount row
            if { [info exists row] } { unset row }
            incr rowcount -1
          }
        }
      }

      delete {
        set index [lindex $args 0]
        for { set i $index } { $i < $rowcount } { incr i } {
          upvar #$level $name:$i row
          upvar #$level $name:[expr $i+1] row1
          array set row [array get row1]
        }
        upvar #$level $name:$rowcount row
        unset row
        incr rowcount -1
      }

      append {
        incr rowcount
        upvar #$level $name:$rowcount row
        for { set i 0 } { $i < [llength $columns] } { incr i } {
          set key [lindex $columns $i]
          set value [lindex $args $i]
          set row($key) $value
        }
        set row(rownum) $rowcount
      }

      insert {
        set index [lindex $args 0]
        for { set i $rowcount } { $i >= $index } { incr i -1 } {
          upvar #$level $name:$i row
          upvar #$level $name:[expr $i + 1] row2
          array set row2 [array get row]
        }
        upvar #$level $name:$index row
        for { set i 0 } { $i < [llength $columns] } { incr i } {
          set key [lindex $columns $i]
          set value [lindex $args [expr $i + 1]]
          set row($key) $value
        }
        set row(rownum) $index
        incr rowcount
      }

      list {
        set value ""
        for { set i 1 } { $i <= $rowcount } { incr i } {
          upvar #$level $name:$i row
          lappend value [array get row]
        }
        return $value
      }

      sort -
      sort:int -
      sort:real {
        set key [lindex $args 0]
        for { set i 1 } { $i <= $rowcount } { incr i } {
          upvar #$level $name:$i row
          set sort1($row($key)) $i
          set sort2($i) [array get row]
        }
        set i 1
        switch -- $op {
         sort { set data [lsort [array names sort1]] }
         sort:int { set data [lsort -integer [array names sort1]] }
         sort:real { set data [lsort -real [array names sort1]] }
        }
        foreach key $data {
          upvar #$level $name:$i row
          array set row $sort2($sort1($key))
          incr i
        }
      }

      clear {
        upvar #$level $name:$rowcount row
        for { set i 0 } { $i < [llength $columns] } { incr i } {
          set row([lindex $columns $i]) ""
        }
      }

      update {
        upvar #$level $name:[lindex $args 0] row
        for { set i 0 } { $i < [llength $columns] } { incr i } {
          set key [lindex $columns $i]
          set value [lindex $args [expr $i+1]]
          set row($key) $value
        }
        set row(rownum) $rowcount
      }

      copy {
        incr rowcount
        upvar #$level $name:$rowcount row
        upvar [lindex $args 0] row2
        array set row [array get row2]
      }

      local {
        set index [lindex $args 0]
        upvar #$level $name:$index row
        foreach name [array names row] {
          upvar 1 $name var
          set var $row($name)
        }
      }

      csv {
        set data ""
        set delim [ossweb::nvl [lindex $args 0] |]
        for { set i 1 } { $i <= $rowcount } { incr i } {
          upvar #$level $name:$i row
          set rlist ""
          foreach key $columns {
            lappend rlist $row($key)
          }
          append data [join $rlist $delim] "\n"
        }
        return $data
      }

      columns {
        return $columns
      }

      size {
        return $rowcount
      }

      get {
        set index [lindex $args 0]
        set column [lindex $args 1]
        # Set an array reference if no column is specified
        if { [string equal $column {}] } {
          uplevel "upvar #$level $name:$index $name"
        } else {
        # If a column is specified, just return the value for it
          upvar #$level $name:$index row
          return $row($column)
        }
      }

      eval {
        if { [set eval [lindex $args 0]] == "" } { return }
        for { set index 1 } { $index <= $rowcount } { incr index } {
          set rc [catch { uplevel #$level "upvar 0 ${name}:$index row; $eval" } errmsg]
          switch $rc {
           0 - 2 - 3 - 4 {}
           default {
              global errorInfo
              ::ossweb::conn::log Error ossweb::db::multirow "$name: $errmsg: $errorInfo"
           }
          }
        }
      }

      set {
        set value ""
        set index [lindex $args 0]
        foreach { column value } [lrange $args 1 end] {
          upvar #$level $name:$index row
          set row($column) $value
        }
        return $value
      }

      set:append {
        set value ""
        set index [lindex $args 0]
        foreach { column value } [lrange $args 1 end] {
          upvar #$level $name:$index row
          append row($column) $value
        }
        return $value
      }

      check {
        if { [set column [lindex $args 0]] == "" } { return -1 }
        if { [set value [lindex $args 1]] == "" } { return -1 }
        for { set index 1 } { $index <= $rowcount } { incr index } {
           # If a column is specified, just return the value for it
           upvar #$level $name:$index row
           if { $row($column) == $value } { return $index }
        }
        return -1
      }
   }
}

# Access to project settings and configuration,
# called for some project specific parameters like
# project_logo, project_name , etc.
proc ossweb::project { name { default "" } } {

    array set projects [ossweb::cache::run __ossweb_cache ossweb:projects {
       foreach prec [ossweb::db::select ossweb_projects -array t] {
         foreach { k v } $prec {
           regsub project_ $k {} k
           set pset($k) $v
         }
         set plist($pset(id)) [array get pset]
       }
       return [array get plist]
    }]

    switch -- $name {
     title {
       if { [info command ns_fortune] != "" } {
         if { [set value [ns_fortune fortune]] != "" } { return $value }
       }
       set name name
     }

     logo {
       if { [set path [ossweb::config server:path:logo]] != "" } {
         if { [set logos [ossweb::cache get CONFIG:LOGO:LIST]] == "" } {
           foreach file [glob -nocomplain [ns_info pageroot]$path/*] {
             lappend logos [file tail $file]
           }
           ossweb::cache set CONFIG:LOGO:LIST $logos
         }
         if { [set len [llength $logos]] > 0 && [set logo [lindex $logos [ns_rand $len]]] != "" } {
           return $path/$logo
         }
       }
     }
    }
    set project_name [ossweb::conn project_name]
    if { ![info exists projects($project_name)] } {
      set project_name *
    }
    if { [info exists projects($project_name)] } {
      array set project $projects($project_name)
    }
    return [ossweb::coalesce project($name) $default]
}

# Wrapper for full text search
proc ossweb::tsearch { cmd type args } {

    switch -- $cmd {
     types {
        # Scan all types if none given
        if { $type == "" } {
          set type [namespace eval ::ossweb::tsearch { info procs }]
        }
        set filter [list]
        foreach type $type {
          if { [ossweb::tsearch acl $type] == "" } {
            lappend filter $type
          }
        }
        return $filter
     }

     filters {
        # Return SQL condition restricting each type if configured
        if { $type == "" } {
          set type [namespace eval ::ossweb::tsearch { info procs }]
        }
        set filter [list]
        foreach type $type {
          set sql [ossweb::tsearch filter $type]
          if { $sql != "" } {
            set sql "AND $sql"
          }
          lappend filter "(tsearch_type='$type' $sql)"
        }
        if { $filter != "" } {
          return "([join $filter " OR "])"
        }
     }

     acl {
        # Check permissions by app name
        if { [info proc ::ossweb::tsearch::$type] == "" } {
          return unknown
        }
        set app_name [ossweb::nvl [ossweb::tsearch::$type app_name] $type]
        if { [ossweb::conn::check_acl -acl *.$app_name.*.view.*] } {
          return denied
        }
     }

     sections {
        set sections [list]
        foreach type [namespace eval ::ossweb::tsearch { info procs }] {
          if { [ossweb::tsearch acl $type] == "" } {
            lappend sections [list [ossweb::tsearch name $type] $type]
          }
        }
        return $sections
     }

     filter {
       if { [info proc ::ossweb::tsearch::$type] != "" } {
         return [eval ossweb::tsearch::$type filter $args]
       }
     }

     url {
       if { [info proc ::ossweb::tsearch::$type] != "" } {
         return [eval ossweb::tsearch::$type url $args]
       }
     }

     name {
        set name ""
        if { [info proc ::ossweb::tsearch::$type] != "" } {
          set name [eval ossweb::tsearch::$type name $args]
        }
        if { $name == "" } {
          set name [string totitle [string map { _ { } } $type]]
        }
        return $name
     }
    }
    return
}

# Generic caching mechanism, global throughout the whole server.
# Examples:
#   ossweb::cache set john "111"
#   set id [ossweb::cache get john]
#   ossweb::cache flush john
proc ossweb::cache { command key args } {

    set val [lindex $args 0]
    set ttl [lindex $args 1]

    switch -exact $command {

      exists {
        return [ossweb::cache::exists __ossweb_cache $key]
      }

      get {
        return [ossweb::cache::get __ossweb_cache $key -default $val]
      }

      run {
        return [ossweb::cache::run __ossweb_cache $key $val -expires $ttl -timeout [lindex $args 2]]
      }

      incr {
        return [ossweb::cache::incr __ossweb_cache $key -incr $val -expires $ttl]
      }

      set {
        ossweb::cache::put __ossweb_cache $key $val -expires $ttl
      }

      append {
        ossweb::cache::append __ossweb_cache $key $val -expires $ttl
      }

      lappend {
        ossweb::cache::lappend __ossweb_cache $key $val -expires $ttl
      }

      unset -
      flush  {
        ossweb::cache::flush __ossweb_cache $key
      }

      names {
        # List of names by pattern
        set result ""
        foreach name [ossweb::cache::keys __ossweb_cache $key] { lappend result $name }
        return $result
      }

      values {
        # List of key/values by pattern
        set result ""
        foreach name [ossweb::cache::keys __ossweb_cache $key] {
          ::lappend result $name [ossweb::cache::get __ossweb_cache $name]
        }
        return $result
      }

      cleanup {
      }

      default {
        error "ossweb::cache: Invalid command: $command"
      }
    }
}

# Create new cache
proc ossweb::cache::create { cache args } {

    ns_parseargs { {-params ""} {-expires ""} {-size 0} {-timeout ""} {-maxentry ""} } $args

    if { $expires > 0 } { ::lappend params -expires $expires }
    if { $timeout > 0 } { ::lappend params -timeout $timeout }
    if { $maxentry > 0 } { ::lappend params -maxentry $maxentry }

    eval ns_cache_create $params $cache $size
}

# Returns 1 if cache entry exists
proc ossweb::cache::exists { cache key args } {

    if { [catch { ns_cache_eval $cache $key { error "no entry" } }] } { return 0 }
    return 1
}

# Update cache entry
proc ossweb::cache::put { cache key val args } {

    ns_parseargs { {-params ""} {-expires ""} {-timeout ""} } $args

    if { $expires > 0 } { ::lappend params -expires $expires }
    if { $timeout > 0 } { ::lappend params -timeout $timeout }

    eval "ns_cache_eval $params -force -- $cache {$key} {return {$val}}"
}

# Evaluate the script and updzte cache entry with result
proc ossweb::cache::run { cache key script args } {

    ns_parseargs { {-params ""} {-expires ""} {-timeout ""} {-force ""} } $args

    if { [ossweb::true $force] } { ::lappend params -force }
    if { $expires > 0 } { ::lappend params -expires $expires }
    if { $timeout > 0 } { ::lappend params -timeout $timeout }

    uplevel "ns_cache_eval $params -- $cache {$key} {$script}"
}

# Returns cache entry value
proc ossweb::cache::get { cache key args } {

    ns_parseargs { {-params ""} {-default ""} {-timeout ""} args } $args

    if { $timeout > 0 } { ::lappend params -timeout $timeout }

    return [ossweb::nvl [eval "ns_cache_eval $params -- $cache {$key} {}"] $default]
}

# Increment cache entry value
proc ossweb::cache::incr { cache key args } {

    ns_parseargs { {-params ""} {-incr 1} {-expires ""} {-timeout ""} } $args

    if { $expires > 0 } { ::lappend params -expires $expires }
    if { $timeout > 0 } { ::lappend params -timeout $timeout }

    return [eval "ns_cache_incr $params -- $cache {$key} $incr"]
}

# Append data to cache entry
proc ossweb::cache::append { cache key val args } {

    ns_parseargs { {-params ""} {-expires ""} {-timeout ""} args } $args

    if { $expires > 0 } { ::lappend params -expires $expires }
    if { $timeout > 0 } { ::lappend params -timeout $timeout }

    return [eval "ns_cache_append $params -- $cache {$key} {$val} $args"]
}

# Append list elements to cache entry
proc ossweb::cache::lappend { cache key val args } {

    ns_parseargs { {-params ""} {-expires ""} {-timeout ""} args } $args

    if { $expires > 0 } { ::lappend params -expires $expires }
    if { $timeout > 0 } { ::lappend params -timeout $timeout }

    return [eval "ns_cache_lappend $params -- $cache {$key} {$val} $args"]
}

# Flush cache entry from the cache
proc ossweb::cache::flush { cache args } {

    eval ns_cache_flush -glob $cache $args
}

# Returns cache entry names by pattern
proc ossweb::cache::keys { cache { key "" } } {

    return [eval ns_cache_keys $cache $key]
}

# Returns all created caches
proc ossweb::cache::names {} {

    return [ns_cache_names]
}

# Validates variable for non-emptiness, valid data type format
# and custom validation condition
# Returns -1 in case of error and sets errmsg with error message
proc ossweb::datatype::validate { name type args } {

    ns_parseargs { {-code ""} {-errmsg ""} {-level {[expr [info level]-1]}} {-required 1} } $args

    if { $errmsg != "" } { upvar $errmsg msg }

    if { $name != "" } {
      upvar #$level $name value
      if { $required && ![info exists value] || [string equal $value {}]} {
        set msg "Required parameter '$name' is not specified"
        return -1
      }
      if { [info proc ::ossweb::datatype::$type] != "" } {
        set msg [ossweb::datatype::$type $value]
        if { $msg != "" } {
          set value ""
          return -1
        }
      }
    }
    # Run custom validation code
    if { ![string equal $code {}] } {
      upvar #$level __rc __rc
      uplevel #$level "if { $code } { set __rc 0 } else { set __rc -1 }"
      if { $__rc == -1 } {
        set value ""
        return -1
      }
    }
    return 0
}

# Returns value of the variable of the given datatype
proc ossweb::datatype::value { name type args } {

    ns_parseargs { {-default ""} {-level 1} } $args

    upvar $level $name var
    if { ![info exists var] } {
      return $default
    }
    switch [set type [string tolower $type]] {
     date -
     time -
     datetime -
     pretty_date -
     pretty_datetime -
     nice_date -
     nice_datetime {
       return [ossweb::date $type $var]
     }
     default {
       return $var
     }
    }
}

proc ossweb::datatype::integer { value } {

    if { ![string is integer -strict [ossweb::trim0 $value]] &&
         ![string equal -nocase $value NULL] } {
      return "Invalid number \"$value\""
    }
    return
}

proc ossweb::datatype::int { value } {

    return [ossweb::datatype::integer $value]
}

proc ossweb::datatype::ilist { value } {

    foreach int $value {
      set msg [ossweb::datatype::integer $int]
      if { $msg != "" } {
        return $msg
      }
    }
    return
}

proc ossweb::datatype::text { value } {

    return
}

proc ossweb::datatype::textarea { value } {

    return
}

proc ossweb::datatype::url { value } {

    set expr {^(https?://)?([a-zA-Z0-9_\-\.]+(:[0-9]+)?)?[a-zA-Z0-9_.%/?=&-]+$}
    if { ![regexp $expr $value] } {
      return "Invalid url \"$value\""
    }
    return
}

# Allow only alphanumeric symbols.
proc ossweb::datatype::name { value } {

    if { $value != "" && ![regexp {^[a-zA-Z0-9_.]+$} $value] }  {
      return "Invalid characters in \"$value\": should be letters, digits or _ only"
    }
    return
}

# File name UNIX and WIN
proc ossweb::datatype::file { value } {

    if { $value != "" && ![regexp {^[a-zA-Z0-9_\ \-\.:/\\]+$} $value] }  {
      return "Invalid file name \"$value\""
    }
    return
}

proc ossweb::datatype::email { value } {

    foreach name [split $value ","] {
      if { ![regexp "^\[^@<>\"\t ]+@\[^@<>\".\t ]+(\\.\[^@<>\".\n ]+)+$" [string trim $name]] &&
           ![regexp "^\[^@<>\"\t ]+@\[^@<>\"\t ]+$" $name] } {
        return "Invalid email address \"$name\""
      }
    }
    return
}

proc ossweb::datatype::float { value } {

    if { ![string is double -strict $value] } {
      return "Invalid decimal number \"$value\""
    }
    return
}

proc ossweb::datatype::money { value } {

    set val [string trim $value {$}]
    if { ![string is double -strict $val] } {
      return "Invalid money number \"$value\""
    }
    return
}

# Checks to make sure that the value in a valid MAC Address, xx:xx:xx:xx:xx:xx
proc ossweb::datatype::macaddr { value } {

    if { ![regexp -nocase {^([0-9abcd]{2}\:){5}[0-9abcd]{2}$} $value] } {
      return "Invalid MAC address \"$value\""
    }
    return
}

# Checks to make sure that the value in a valid IP Address, x.x.x.x/y
proc ossweb::datatype::ipaddr { value } {

    set mask { 255 255 255 255 32 }
    set ip [split $value "./"]
    set len [llength $ip]
    if { $len != 4 && $len != 5 } {
      return "Invalid IP address \"$value\""
    }
    # check each octet for valid range
    for { set i 0 } { $i < $len } { incr i } {
      set octet [lindex $ip $i]
      set max [lindex $mask $i]
      if { ![string is integer -strict $octet] || $octet < 0 || $octet > $max } {
        return "Invalid octet \"$octet\" in IP address \"$value\""
      }
    }
    return
}

proc ossweb::datatype::phone { value } {

    if ![regexp {^\(?([1-9][0-9]{2})\)?(-|\.|\ )?([0-9]{3})(-|\.|\ )?([0-9]{4})} $value] {
      return "Invalid phone number \"$value\""
    }
    return
}

proc ossweb::datatype::boolean { value } {

    if { [lsearch { 1 0 t f y n yes no true false } [string tolower $value]] == -1 } {
      return "Invalid boolean \"$value\""
    }
    return
}

# Converts string with items separated by specified symbol into Tcl list.
#  -skip list with items that should not be converted, if empty everything will be converted
# Returns A list in the form { key value key value key value ... }
proc ossweb::convert::string_to_list { str args } {

    ns_parseargs { {-skip ""} {-separator " "} } $args

    set result [list]
    foreach name [split $str $separator] {
      if { [string trim $name] == "" || ($skip != "" && [lsearch -exact $skip $name] != -1) } {
        continue
      }
      lappend result [string trim $name]
    }
    return $result
}

# Turns an ns_set into a key-value list, excluding any number of
# specified keys.
#  -skip list with items that should not be converted, if empty everything will be converted
#  -filter telss to include only matched values
#  -values t will return only values, not name-valuepairs
# Returns A list in the form { key value key value key value ... }
proc ossweb::convert::set_to_list { id args } {

    if { $id == "" } { return }

    ns_parseargs { {-skip ""} {-values f} {-names f} {-filter ""} {-lowercase f} } $args

    set result [list]
    for { set i 0 } { $i < [ns_set size $id] } { incr i } {
      set name [ns_set key $id $i]
      if { $name == "" || ($skip != "" && [lsearch -exact $skip $name] != -1) } {
        continue
      }
      if { $filter != "" && ![regexp -nocase $filter $name] } {
        continue
      }
      if { $lowercase == "t" } {
        set name [string tolower $name]
      }
      if { $values == "f" } {
        lappend result [string trim $name {""}]
      }
      if { $names == "f" } {
        lappend result [ns_set value $id $i]
      }
    }
    return $result
}

# Converts ns_set into HTML tag attributes in the form
# name="value" or just name. Good for using inside HTML tags.
proc ossweb::convert::set_to_attributes { id args } {

    if { $id == "" } { return }

    ns_parseargs { {-skip ""} {-quotes "\""} {-filter ""} } $args

    set skip [string toupper $skip]
    set result ""
    for { set i 0 } { $i < [ns_set size $id] } { incr i } {
      set name [string toupper [ns_set key $id $i]]
      if { $name == "" || ($skip != "" && [lsearch -exact $skip $name] != -1) } {
        continue
      }
      if { $filter != "" && ![regexp -nocase $filter $name] } {
        continue
      }
      append result " " $name
      set value [ns_set value $id $i]
      if { $value != "" } {
        append result "=$quotes$value$quotes"
      }
    }
    return $result
}

# Converts an ns_set into a local variables, excluding any number of
# specified keys.
#  -skip list with items that should be converted, if empty everything will be converted
# Returns A list in the form { key value key value key value ... }
proc ossweb::convert::set_to_vars { id args } {

    if { $id == "" } { return }

    ns_parseargs { {-skip ""} {-level 1} } $args

    for { set i 0 } { $i < [ns_set size $id] } { incr i } {
      set name [ns_set key $id $i]
      if { $name == "" || ($skip != "" && [lsearch -exact $skip $name] != -1) } {
        continue
      }
      upvar $level $name var_0
      set var_0 [ns_set value $id $i]
    }
}

# Updates given array with key/values from the given ns_set.
#  id is ns_set handle
#  name is array name in the caller's frame
#  -skip contains list with items that should be converted, if empty everything will be converted
proc ossweb::convert::set_to_array { id name args } {

    if { $id == "" } { return }

    ns_parseargs { {-skip ""} {-filter ""} } $args

    upvar $name arr_0
    for { set i 0 } { $i < [ns_set size $id] } { incr i } {
      set key [ns_set key $id $i]
      if { $key == "" || ($skip != "" && [lsearch -exact $skip $key] != -1) } {
        continue
      }
      if { $filter != "" && ![regexp $filter $key] } {
        continue
      }
      set arr_0($key) [ns_set value $id $i]
    }
}

# Converts Tcl list into URL query string in the form name=val&[...]
proc ossweb::convert::list_to_query { list } {

    set result ""
    foreach { name value } $list {
      append result "&" $name "=" [ossweb::convert::value_to_query $value]
    }
    return $result
}

# Converts list into HTML tag attributes in the form
# name="value" or just name. Good for using inside HTML tags.
proc ossweb::convert::list_to_attributes { list args } {

    ns_parseargs { {-skip ""} {-quote "\""} {-delim " "} } $args

    set result ""
    foreach { name value } $list {
      if { $skip != "" && [lsearch -exact $skip $name] != -1 } {
        continue
      }
      if { $result != "" } {
        append result $delim
      }
      append result $name
      if { $value != "" } {
        append result "=$quote$value$quote"
      }
    }
    return $result
}

# Converts a list into an array where each item corresponds to an element
# of the list and array values are item positions in the list.
#  list    A list of values
#  name    The name of the array to create in the calling frame.
proc ossweb::convert::list_to_array { list name } {

    upvar $name arr_0
    set i 1
    foreach item $list {
      if { [info exists arr_0($item)] } {
        continue
      }
      set arr_0($item) $i
      incr i
    }
}

# Converts list into local variables, list should be in format
# name value name value ...
# -null t allows to set empty values, otherwise only non-empty
proc ossweb::convert::list_to_vars { list args } {

    ns_parseargs { {-null t} {-level 1} {-skip ""} } $args

    foreach { name value } $list {
      if { $skip != "" && [lsearch -exact $skip $name] != -1 } {
        continue
      }
      if { $null == "f" && $value == "" } {
        continue
      }
      upvar $level $name var_0
      set var_0 $value
    }
}

# Converts local variables which are specified as parameters into a list in format
# name value name value ...
# -null t allows to use empty values, otherwise only non-empty
proc ossweb::convert::vars_to_list { vars args } {

    ns_parseargs { {-null t} {-level 1} {-skip ""} } $args

    set result [list]
    foreach name $vars {
      if { $skip != "" && [lsearch -exact $skip $name] != -1 } {
        continue
      }
      upvar $level $name var_0
      set val [ossweb::coalesce var_0]
      if { $null == "f" && $val == "" } {
        continue
      }
      lappend result $name $val
    }
    return $result
}

# Converts given array into ns_set
# -persist t create persistent ns_set
proc ossweb::convert::array_to_set { array args } {

    ns_parseargs { {-persist f} {-name ""} } $args

    upvar 1 $array arr_0
    set id [ossweb::decode $persist t [ns_set new -persist $name] [ns_set new $name]]
    foreach { name value } [array get arr_0] {
      ns_set update $id $name $value
    }
    return $id
}

# Converts given array into list of lists
proc ossweb::convert::array_to_list { array args } {

    ns_parseargs { {-skip ""} {-filter ""} } $args

    upvar 1 $array arr_0
    set result ""
    foreach { name value } [array get arr_0] {
      if { $skip != "" && [lsearch -exact $skip $name] != -1 } {
        continue
      }
      if { $filter != "" && ![regexp -nocase $filter $name] } {
        continue
      }
      lappend result [list $name $value]
    }
    return $result
}

# Converts given array into string in the form 'name=val,[name=val]...'
# separated by specified delimiter.
#  -delimiter specifies the delimiter, default is ','
#  -quote specifies that value should be quoted
#  -escape specifies that value shoult be URL escaped
proc ossweb::convert::array_to_string { array args } {

    ns_parseargs { {-delimiter ","} {-escape f} {-quote f} } $args

    upvar 1 $array arr_0
    set result ""
    foreach { key value } [array get arr_0] {
      if { $quote == "t" } {
        set value [dbquotevalue $value]
      }
      if { $escape == "t" } {
        set value [ns_urlencode $value]
      }
      append result $delimiter $key "=" $value
    }
    return $result
}

# converts Tcl array into javscript object
proc ossweb::convert::array_to_js { array args } {

    upvar 1 $array arr_0
    set result ""
    foreach { key value } [array get arr_0] {
      if { ![string is double -strict $value] } {
        set value "\"$value\""
      }
      lappend result $key:$value
    }
    return "{[join $result ,]}"
}

# Converts list of lists into one plain list
proc ossweb::convert::plain_list { name } {

    upvar $name var_0
    regsub -all {[{}]} $var_0 {} tmp
    regsub -all { +} $tmp { } tmp
    set var_0 [string trim $tmp]
}

# Converts query into local variables
proc ossweb::convert::query_to_vars { str args } {

    uplevel "ossweb::convert::set_to_vars [ns_parsequery $str] $args"
}

# Check for special decoding for given query variable
proc ossweb::convert::query_to_value { value { type "" } } {

    # Special type decoding
    switch -glob -- $value {
     <hex>:* {
       set value [ossweb::dehexify [string range $value 6 end]]
     }

     <base64>:* {
       set value [ns_uudecode [string range $value 9 end]]
     }

     <crypt>:* {
        set value [ossweb::decrypt [string range $value 8 end]]
     }
    }
    return $value
}

# Check for special encoding for given value
proc ossweb::convert::value_to_query { value { type "" } } {

    # Special type decoding
    switch -glob -- $value {
     (hex):* {
       set value [ossweb::html::escape <hex>:[ossweb::hexify [string range $value 6 end]]]
     }

     (base64):* {
       set value [ossweb::html::escape <base64>:[ns_uuencode [string range $value 9 end]]]
     }

     (crypt):* {
       set value [ossweb::html::escape <crypt>:[ossweb::encrypt [string range $value 8 end]]]
     }

     js:* {
       set value "'+ [string range $value 3 end] +'"
     }

     javascript:* {
       set value "'+ [string range $value 11 end] +'"
     }

     default {
       set value [ossweb::html::escape $value]
     }
    }
    return $value
}

