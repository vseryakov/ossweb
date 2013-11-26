# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001
#
# $Id: util.tcl 2561 2006-12-20 15:29:27Z vlad $

# Parses an argument list for switches.
# Switch values are placed in corresponding variable names in the calling
# environment.
#    switch_list is a list of allowable switch names with default values.
#                if default value is equal 'null' initialization of this
#                variable will be skipped otherwise each variable will be
#                set with specified default value.
#    name_list is a list with argument names in case where switches are before arguments,
#              if empty this indicates that extra values should be tolerated
#              after switches and placed in the args list. If it contains 'args',
#              it means to leave the rest of arguments without processing and return.
#    argv a list of command-line options.
#    returns error if the list of command-line options is not valid.
#  Example:
#    function with switches before required arguments
#    proc get_cookie { args } {
#      ossweb::util::parse_args { -expire f -cache t } { name value } $args
#
#    function with switches after required arguments
#    proc get_cookie { name value args } {
#      ossweb::util::parse_args { -expire f -cache t } {} $args
#
proc ossweb::util::parse_args { switch_list name_list argv } {

    set set_optional_value ""
    # Set default values first
    ::foreach { switch value } $switch_list {
      if { [string index $switch 0] != "-" } {
        error "ossweb::util::parse_args: expected switch but encountered \"$switch\""
      }
      if { [string equal $value "null"] } { continue }
      set switch [string range $switch 1 end]
      upvar 1 $switch var_name
      set var_name [uplevel "subst {$value}"]
    }
    set index 0
    set varargs 0
    # Re-create argument list
    upvar args args
    set args [list]
    # If name_list is empty it means we process switches at the end of argument list
    if { [llength $name_list] > 0 } {
      set varargs 1
      set switch_list [lrange $switch_list 0 [expr { [llength $switch_list] - 2}]]
    }
    set counter 0
    ::foreach { switch value } $argv {
      if { [string index $switch 0] != "-" } {
        if { $varargs } {
          # Remove switches from the beginning of the parameters
          set args [lrange $argv $counter end]
          # Assign arguments by name
          set counter 0
          ::foreach { name } $name_list {
            # Variable number of arguments, just exit
            if { $name == "args" } {
              # Remove all resolved parameters
              set args [lrange $args $counter end]
              return
            }
            upvar $name var_name
            if { [llength $args] > $counter } {
              set var_name [lindex $args $counter]
            } else {
              set var_name ""
            }
            incr counter 1
          }
          set args [lrange $args $counter end]
          return
        }
        error "ossweb::util::parse_args: expected argument switch but encountered \"$switch\" in $argv"
      }
      if { [lsearch $switch_list $switch] < 0 } {
        error "ossweb::util::parse_args: invalid switch '$switch' (expected one of [join $switch_list ","]): '$argv'"
      }
      # Mark position of the first switch
      if { !$index } {
        set index $counter
      }
      upvar 1 [string range $switch 1 end] var_name
      set var_name $value
      incr counter 2
    }
    if { [llength $argv] % 2 != 0 } {
      # The number of arguments has to be even!
      error "ossweb::util::parse_args: invalid switch syntax - no argument to final switch \"[lindex $argv end]\""
    }
    # Remove switches from the end of parameters
    if { [llength $name_list] == 0 && $index > 0 } {
      set args [lrange $argv 0 $index]
    }
}

proc ossweb::util::fmt { value format { default "" } } {

    if { $value == "" } { return $default }
    return [format $format $value]
}

# Returns max element in the list
proc ossweb::util::lmax { list args } {

    return [lindex [eval lsort $args \$list] end]
}

# Returns min element in the list
proc ossweb::util::lmin { list args } {

    return [lindex [eval lsort $args \$list] 0]
}

# Shuffles a list, taken from http://wiki.tcl.tk/941
proc ossweb::util::lshuffle { list } {

     set len [llength $list]
     set len2 $len
     for { set i 0 } { $i < $len-1 } { incr i } {
       set n [expr {int($i + $len2 * rand())}]
       incr len2 -1
       set temp [lindex $list $i]
       lset list $i [lindex $list $n]
       lset list $n $temp
     }
     return $list
}

# Returns string representation of date/time in default format,
# value is seconds as retuned by ns_time
proc ossweb::util::clock { seconds } {

    return [::clock format $seconds -format "%Y-%m-%d %H:%M:%S"]
}

# Capitalize each word
proc ossweb::util::totitle { str } {

    set title [list]
    foreach word [split [string map { _ " " } $str] " "] {
      lappend title [string totitle $word]
    }
    return [join $title]
}

# Formats given size in bytes into more user-friendly size text
proc ossweb::util::size { size } {

    if { $size > 1073741824 } {
      set size "[format "%.1f" [expr $size / 1073741824.0]]G"
    } elseif { $size > 1048576 } {
      set size "[format "%.1f" [expr $size / 1048576.0]]M"
    } elseif { $size > 1024 } {
      set size "[format "%.1f" [expr $size/1024.0]]K"
    }
    return $size
}

# Perform text wrapping using configured line size,
# try to wrap on special symbols, if no luck just cut the line
# on max size.
proc ossweb::util::wrap_text { text args } {

    ns_parseargs { {-size 80} {-break \n} } $args

    set lines [split $text "\n"]
    set result ""
    foreach line $lines {
      while { [string length $line] > $size } {
       for { set i $size } \
           { $i > 0 && [string first [string index $line $i] " ,;-:.|!?>"] == -1 } \
           { incr i -1 } {}
       if { $i == 0 } { set i $size }
       append result [string range $line 0 $i] $break
       set line [string range $line [incr i] end]
      }
      append result $line $break
    }
    return $result
}

# Converts money string into number
proc ossweb::util::money { value } {

    set value [string trim $value {$}]
    if { [string is double -strict $value] } { return $value }
    return 0
}

# Returns home directory, if name is specified, config paramerer
# checked first and returned if not empty
proc ossweb::util::gethome { { name "" } } {

    set home ""
    if { $name == "" || [set home [ossweb::config $name]] == "" } {
      catch { set home [exec sh -c "grep `id -un` /etc/passwd|awk -F: '{print \$6}'"] }
    }
    return [ossweb::nvl $home [ns_env get HOME]]
}

# Opens TCP connectin
proc ossweb::util::open { host port { timeout 30 } } {

    set fd [ns_sockopen -nonblock $host $port]
    ::close [lindex $fd 1]
    return [lindex $fd 0]
}

# Reads one line from the socket
proc ossweb::util::gets { fd { timeout 30 } } {

    set done 0
    set bytes 0
    set line ""
    set now [ns_time]
    while { !$done && [ns_sockcheck $fd] } {
      if { [set bytes [ns_socknread $fd]] == 0 } {
        if { [lindex [ns_sockselect -timeout $timeout $fd {} {}] 0] == "" ||
             [set bytes [ns_socknread $fd]] == 0 && [ns_time]-$now > $timeout*2 } {
          error "ossweb::util::gets: read timeout"
        }
      }
      while { $bytes > 0 } {
        if { [set char [::read $fd 1]] == "\n" } {
          set done 1
          break
        }
        incr bytes -1
        switch -- $char {
         "\r" {}
         default {
           append line $char
         }
        }
      }
    }
    return $line
}

# Writes text to the socket
proc ossweb::util::puts { fd line { timeout 30 } } {

    if { [lindex [ns_sockselect -timeout $timeout {} $fd {}] 1] == "" } {
      error "ossweb::util::puts: write timeout"
    }
    ::puts $fd $line
    ::flush $fd
}


# Saves movie snapshot in the image file
proc ossweb::util::snapshot { file1 file2 args } {

    ns_parseargs { {-pos 10} {-width 200} {-height 280} {-error f} } $args

    if { [catch { exec mplayer -really-quiet -zoom -x $width -y $height -ss $pos -frames 1 -ao null -vo jpeg -jpeg outdir=/tmp "$file1" } errmsg] } {
      if { $error == "t" } { ns_log Error ossweb::util::snapshot: $file1 $file2: $errmsg }
    }

    if { [file exists /tmp/00000002.jpg] } {
      catch { file rename -force -- /tmp/00000002.jpg $file2 }
    } elseif { [file exists /tmp/00000001.jpg] } {
      catch { file rename -force -- /tmp/00000001.jpg $file2 }
    }
}

# Returns non-zero value if specified parameter is valid number
proc ossweb::util::number { num { default 0 } } {

    if { [string is double -strict $num] } { return $num }
    return $default
}

# Parse template(s), return triple as: subject, body, content type
# In the template file first line is the subject, the rest is email body
# Content type is determined from file extension
proc ossweb::util::email_template { args } {

    ns_parseargs { {-level ""} args } $args

    foreach name $args {
      set content_type text/html
      set file "[ns_info home]/modules/$name.html"
      if { ![ns_filestat $file] } {
        set content_type text/plain
        set file "[ns_info home]/modules/$name.txt"
        if { ![ns_filestat $file] } { continue }
      }
      if { [catch {
        set fd [::open $file]
        set subject [::gets $fd]
        set body [read $fd]
        ::close $fd
      } errmsg] } {
        ns_log Error ossweb::util::email_template: $name: $errmsg
        continue
      }
      set level [ossweb::nvl $level [expr [info level]-1]]
      if { [catch {
        set subject [ossweb::adp::Evaluate $subject $level 2]
        set body [ossweb::adp::Evaluate $body $level 2]
      } errmsg] } {
        ns_log Error ossweb::util::email_template: $name: $errmsg
        continue
      }
      return [list $subject $body $content_type]
    }
    return
}

# Generic charting
proc ossweb::util::chart { args } {

    ns_parseargs { {-title ""}
                   {-type line}
                   {-module gdchart}
                   {-image ""}
                   {-return f}
                   {-data ""}
                   {-labels ""}
                   {-colors ""}
                   {-xaxis Time}
                   {-xaxisangle 0}
                   {-yaxis Data}
                   {-ylabelfmt ""}
                   {-3d f}
                   {-layers f}
                   {-grid 0}
                   {-gridcolor 0x3c4e5e}
                   {-gridontop 1}
                   {-border 1}
                   {-shelf 1}
                   {-bgcolor 0xf2f5fa}
                   {-linecolor 0x000000}
                   {-width 500}
                   {-height 400}
                   {-legend bottom}
                   {-legendx 10}
                   {-legendy 350}
                   {-plotx 60}
                   {-ploty 30}
                   {-plotwidth 420}
                   {-plotheight 300}
                   {-plotcolor 0x000000}
                   {-barwidth 75} } $args

    if { $labels == "" || $data == "" || $image == "" } { return }

    switch -- $module {
     chartdir {
         set chart [ns_chartdir create xy $width $height]
         ns_chartdir setbackground $chart [ns_chartdir gradientcolor $chart silverGradient] -1 2
         ns_chartdir setplotarea $chart $plotx $ploty $plotwidth $plotheight 0xffffff -1 -1 0xc0c0c0 -1
         ns_chartdir addlegend $chart $legendx $legendy 1 Transparent Transparent "" 8 TextColor
         ns_chartdir addtitle $chart $title Top "" 8 TextColor [ns_chartdir gradientcolor $chart silverGradient] -1 1
         ns_chartdir yaxis $chart settitle $yaxis
         ns_chartdir yaxis $chart setautoscale 0.1 0 1
         ns_chartdir xaxis $chart settitle $xaxis
         ns_chartdir xaxis $chart setlabels $labels
         ns_chartdir xaxis $chart setlabelstyle "" 8 0xffff0002 $xaxisangle

         set count 0
         foreach { name data } $data {
           set color [ossweb::nvl [lindex $colors $count] -1]
           if { $count == 0 || $layers == "t" } {
             set id [ns_chartdir layer $chart create $type $data $name $color]
             if { $width > 0 } { ns_chartdir layer $chart setlinewidth $id $width }
             if { $3d == "t" } { ns_chartdir layer $chart set3d $id }
           } else {
             ns_chartdir layer $chart dataset 0 $data $name $color
           }
           incr count
         }
         if { $return == "t" } {
           ns_chartdir return $chart
         } else {
           ns_chartdir save $chart [ns_info pageroot]/$image
         }
         ns_chartdir destroy $chart
     }

     default {
         if { $3d == "t" } { set type 3d$type }
         set chart [ns_gdchart create \
                       type $type \
                       title $title \
                       ytitle $yaxis \
                       ylabelfmt $ylabelfmt \
                       xtitle $xaxis \
                       xaxisangle $xaxisangle \
                       barwidth $barwidth \
                       width $width \
                       height $height \
                       bgcolor $bgcolor \
                       border $border \
                       shelf $shelf \
                       grid $grid \
                       gridcolor $gridcolor \
                       gridontop $gridontop \
                       linecolor $linecolor \
                       plotcolor $plotcolor \
                       legend $legend \
                       legendx $legendx \
                       legendy $legendy \
                       hardheight $plotheight]

         ns_gdchart setlabels $chart $labels
         ns_gdchart setcolors $chart $colors
         foreach { name data } $data {
           ns_gdchart setdata $chart $name $data
         }
         if { $return == "t" } {
           ns_gdchart return $chart
         } else {
           ns_gdchart save $chart [ns_info pageroot]/$image
         }
         ns_gdchart destroy $chart
     }
    }
    return
}

