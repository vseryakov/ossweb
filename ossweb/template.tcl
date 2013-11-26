# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001
#
# $Id: template.tcl 2918 2007-01-30 19:31:34Z vlad $

ossweb::register_init ossweb::adp::Init

# Performs template initialization
proc ossweb::adp::Init {} {

    variable adp_ext

    # Temlating extension
    if { [set adp_ext [ossweb::param server:extension oss]] != "none" } {
      # Register templating filter
      ns_register_filter postauth GET *.$adp_ext ::ossweb::adp::Filter
      ns_register_filter postauth POST *.$adp_ext ::ossweb::adp::Filter
      ns_register_filter postauth GET */ ::ossweb::adp::Filter
      ns_log Notice ossweb::Init templating filter installed for *.$adp_ext
    }
}

# Template filter
proc ossweb::adp::Filter { args } {

    variable adp_ctype

    set _url [ossweb::conn url]
    set _root "[ossweb::config server:path:root [ns_info pageroot]]/[file rootname $_url]"

    # Resolve index page if under the project and we are in the application directory
    if { [string match */ $_url] } {
      set _path [split [string trim $_url /] /]
      if { [llength $_path] != 2 } {
        return filter_ok
      }
      set _root [ns_normalizepath [ns_info pageroot]/[lindex $_path 0]/index/index]
      if { ![ns_filestat $_root.adp] } {
        return filter_ok
      }
    }
    ossweb::adp::Reset
    # Execute template
    if { [catch { set output [ossweb::adp::Execute $_root] } errmsg] } {
      if { $errmsg == "OSSWEB_EXIT" } {
        return filter_return
      }
      ossweb::conn::log Error ossweb::adp::Filter: [ns_quotehtml $_root]: $::errorInfo
      set errorPage [ossweb::config server:path:error ""]
      if { $errorPage == "" } {
        set output "<html><body><p>Internal Server Error in [ns_quotehtml $_root]:
                    <pre>[ns_quotehtml $::errorInfo]</pre></body></html>"
      } else {
        ns_returnredirect $errorPage
        return filter_return
      }
    }
    if { [string length $output] } {
      # Expire dynamic pages
      ns_set update [ns_conn outputheaders] Expires -1
      ns_set update [ns_conn outputheaders] Cache-Control no-cache
      ns_set update [ns_conn outputheaders] Pragma no-cache
      ns_return 200 $adp_ctype $output
    }
    return filter_return
}

# Set the path of the template to be executed.
#   file absolute path to the next template to parse.
# Returns currently executed template file
proc ossweb::adp::File { { file "" } } {

    variable adp_stack

    if { $file != "" } {
      lappend adp_stack $file
    }
    return [lindex $adp_stack end]
}

# Returns the execution stack length
proc ossweb::adp::Length {} {

    variable adp_stack

    return [llength $adp_stack]
}

# Returns directory of currently executed template file
proc ossweb::adp::DirName {} {

    variable adp_stack

    set file [lindex $adp_stack end]
    if { $file != "" } {
      return [::file dirname $file]
    }
    return
}

# Returns full path to the included template or master
proc ossweb::adp::Include { file } {

    if { $file == "" } {
      return
    }
    # Absolute path
    if { [string index $file 0] == "/" } {
      return [ns_normalizepath [ns_info pageroot]/$file]
    }
    # Relative path
    set rpath [ns_normalizepath [ossweb::adp::DirName]/$file]
    if { [ns_filestat $rpath.adp] } {
      return $rpath
    }
    set root [ossweb::config server:path:include [ns_info pageroot]/[ossweb::conn project_name]/index]
    return [ns_normalizepath $root/$file]
}

# Global execution level at which template is being evaluated.
# Returns current Tcl execution level
proc ossweb::adp::Level { { level "" } } {

    variable adp_level

    if { $level != "" } {
      set adp_level $level
    }
    return $adp_level
}

# Change global trim value
proc ossweb::adp::Trim { { trim "" } } {

    variable adp_trim

    if { $trim != "" } {
      set adp_trim $trim
    }
    return $adp_trim
}

# Change global returncontent type
proc ossweb::adp::ContentType { { type "" } } {

    variable adp_ctype

    if { $type != "" } {
      set adp_ctype $type
    }
    return $adp_ctype
}

# Reset templating stack
proc ossweb::adp::Reset {} {

    variable adp_stack
    variable adp_level
    variable adp_trim
    variable adp_ctype

    set adp_stack ""
    set adp_level 1
    set adp_trim 0
    set adp_ctype text/html
}

# Writes to the ADP output buffer
#  text A string containing text or markup.
proc ossweb::adp::Write { text } {

    variable adp_level
    variable adp_buffer

    upvar #$adp_level __adp_buffer_$adp_buffer buffer
    append buffer(output) $text
}

# Operations with ADP dynamic buffer
proc ossweb::adp::Buffer { what { name "" } { value "" } } {

    variable adp_level
    variable adp_trim
    variable adp_buffer

    switch $what {
     init {
        incr adp_buffer
        upvar #$adp_level __adp_buffer_$adp_buffer buffer
        set buffer(output) ""
        set buffer(master) ""
        # It may exist if there was <slave> tag in the document
        if { ![ossweb::exists buffer(slave)] } {
          set buffer(slave) ""
        }
     }
     set {
        switch $name {
         slave {
           upvar #$adp_level "__adp_buffer_[expr $adp_buffer + 1]" buffer
           set buffer(slave) $value
         }
         default {
           upvar #$adp_level __adp_buffer_$adp_buffer buffer
           set buffer($name) $value
         }
        }
     }
     get {
        upvar #$adp_level __adp_buffer_$adp_buffer buffer
        # Trim extra spaces if requested
        if { $adp_trim } {
          return [string trim $buffer($name)]
        }
        return $buffer($name)
     }
     clear {
        upvar #$adp_level __adp_buffer_$adp_buffer buffer
        unset buffer
        incr adp_buffer -1
     }
     reset {
        upvar #$adp_level __adp_buffer_$adp_buffer buffer
        set buffer(output) ""
        set buffer(slave) ""
        set buffer(master) ""
     }
     cacheset {
     }
     cacheget {
     }
    }
}

# Returns current file signature cookies
proc ossweb::adp::Cookie {} {

    set path [ossweb::adp::File]
    return [::ossweb::adp::${path}.tcl]
}

# Template ADP cache support
#  type - tcl or adp
proc ossweb::adp::Cache { type path } {

    variable adp_level
    variable adp_cache

    # Build file signature
    if { ![ns_filestat $path.$type stat] } {
      error "OSSWEB: $path.$type not found"
    }
    set cookie0 $stat(mtime):$stat(size):$stat(ino):$stat(dev)

    # Check if cookie proc exists
    set cookie1 [info procs ${path}.$type]

    # Verify file modification time
    if { $cookie1 == "" || [$cookie1] != $cookie0 } {
      set code [ossweb::read_file $path.$type]
      if { $type == "adp" } {
        set code [Compile $code [ossweb::conn adp:mode 1]]
      }
      ::proc ${path}:$type {} "uplevel #$adp_level { $code }"
      # Do not cache templates in development mode
      if { !$adp_cache } {
        set $cookie0 ""
      }
      ::proc ${path}.$type {} "return $cookie0"
    }
    # Run the proc
    ${path}:$type
}

# Executes template script if exists and evaluates template embedded tags
#  path   absolute path to the template without extension
#  params  list of pairs of variables and values to be created
proc ossweb::adp::Execute { path { params "" } } {

    variable adp_level
    variable adp_stack

    # Initialize the ADP buffer
    ossweb::adp::Buffer init
    # Declare any variables passed in to an include or master
    foreach { key value } $params {
      uplevel #$adp_level "set $key \"$value\""
    }
    # Append currently processed template file to the execution stack
    lappend adp_stack $path
    # Execute Tcl code first
    if { [catch {
      while 1 {
        if { ![ns_filestat $path.tcl] } { break }
        # Remember current position in the execution stack
        set len [llength $adp_stack]
        if { $len > 5 } {
          ns_log Notice ossweb::adp::Execute: $adp_stack
          error "Infinite template loop"
        }
        # Run the code
        ossweb::adp::Cache tcl $path
        # If template has been switched inside the script, run the new one
        if { [llength $adp_stack] == $len } { break }
        set path [lindex $adp_stack end]
      }
    } errMsg] } {
      # Return without error in case of special abort
      if { $errMsg == "OSSWEB_EXIT" } {
        return
      }
      error $errMsg $::errorInfo
    }
    # If we have ADP file, generate output
    if { [ns_filestat "$path.adp"] } {
      # Run the code
      ossweb::adp::Cache adp $path
      set output [Buffer get output]
      # Call the master template if one has been defined
      set master [Buffer get master]
      if { $master != "" } {
        # Save current output for <slave> tag
        Buffer set slave $output
        # Call master template with passed properties
        set output [ossweb::adp::Execute $master]
      }
      Buffer clear
      return $output
    } else {
      # index in the application dir not found, try global project index
      if { [string match */index $path] } {
        regsub {/[^/]+/index$} $path /index/index ipath
        if { $ipath != $path } {
          return [ossweb::adp::Execute $ipath]
        }
      }
      ns_log Notice ossweb::adp::Execute: $path.adp not found, url=[ns_conn url]
    }
    Buffer clear
    # If file is not set it means we couldn't resolve any template or script
    if { [ossweb::adp::File] == "" } {
      ns_log Notice ossweb::adp::Execute: $path not found, url=[ns_conn url]
      return "The requested URL was not found on this server: '[ns_quotehtml [ns_conn url]]'"
    }
}

#  Evaluates template embedded tags
#  sdata   string with template tags
#  slevel  level at which to evaluate the code
#  smode   @..@ convert mode for Compile
proc ossweb::adp::Evaluate { sdata { slevel "" } { smode 1 } } {

    variable adp_level

    # Save current adp level
    set old_level $adp_level
    # Set adp level to our parent
    set adp_level [ossweb::nvl $slevel [expr [info level]-1]]
    # Initialize the ADP buffer
    ossweb::adp::Buffer init
    # Run the code
    set code [Compile $sdata $smode 1]
    switch [catch { uplevel #$adp_level $code } errmsg] {
     0 - 2 - 3 - 4 {}
     default {
       set adp_level $adp_level
       error $errmsg $::errorInfo
     }
    }
    set output [Buffer get output]
    # Call the master template if one has been defined
    set master [Buffer get master]
    if { $master != "" } {
      # Save current output for <slave> tag
      Buffer set slave $output
      # Call master template with passed properties
      set output [ossweb::adp::Execute $master]
    }
    Buffer clear
    set adp_level $old_level
    return $output
}

# Stops template processing, optionally output given data to the client
proc ossweb::adp::Exit { { result -1 } } {

    if { $result != "-1" } {
      ns_return 200 text/html $result
    }
    error OSSWEB_EXIT
}

# Converts an ADP template into a chunk of Tcl code.
#  chunk      A string containing the template
#  mode       1 convert @..@ using regular variables
#             2 convert @..@ using coalesce and extended datatypes
#  save       if 1, save generated code and restore it on return
# Returns The compiled code.
proc ossweb::adp::Compile { chunk { mode 1 } { save 0 } } {

    variable adp_code

    if { $save } {
      set adp_save $adp_code
    }

    set adp_code ""
    # Substitute standard <% ... %> tags with our own Tcl handler
    regsub -all {<%} $chunk {<tcl>} chunk
    regsub -all {%>} $chunk {</tcl>} chunk
    ossweb::adp::Parse $chunk
    switch -- $mode {
     1 {
       while {[regsub -all {@([a-zA-Z0-9_:]+)\.([a-zA-Z0-9_:]+)@} $adp_code {${\1(\2)}} adp_code]} {}
       while {[regsub -all {@([a-zA-Z0-9_:]+)@} $adp_code {${\1}} adp_code]} {}
     }
     2 {
       while {[regsub -all {@([a-zA-Z0-9_:]+)\.([a-zA-Z0-9_:]+)@} $adp_code "\[ossweb::coalesce \\1(\\2)\]" adp_code]} {}
       while {[regsub -all {@([a-zA-Z0-9_:-]+)\%([^@^]+)\^([^@]+)@} $adp_code "\[ossweb::datatype::value \\1 \\2 -default {\\3}]" adp_code]} {}
       while {[regsub -all {@([a-zA-Z0-9_:-]+)\%([^@^]+)@} $adp_code "\[ossweb::datatype::value \\1 \\2]" adp_code]} {}
       while {[regsub -all {@([a-zA-Z0-9_:-]+)\^([^@]+)@} $adp_code "\[ossweb::coalesce \\1 {\\2}]" adp_code]} {}
       while {[regsub -all {@([a-zA-Z0-9_:-]+)@} $adp_code "\[ossweb::coalesce \\1\]" adp_code]} {}
     }
    }
    regsub -all {@~} $adp_code {@} adp_code

    if { $save } {
      set result $adp_code
      set adp_code $adp_save
      return $result
    }
    return $adp_code
}

# Parses a template by calling ns_adp_parse and putting the result into
# template output buffer.
#  chunk   A template
proc ossweb::adp::Parse { chunk } {

    set chunk [ns_adp_parse $chunk]
    if { [string is space $chunk] } {
      return
    }
    regsub -all {[]["\\$]} $chunk {\\&} chunk ;# Escape quotes and other special symbols"
    ossweb::adp::AppendData $chunk
}

# Puts data string into template output buffer.
#  text  string to be output, double quotes should be escaped
proc ossweb::adp::AppendData { text } {

    AppendCode "ossweb::adp::Write \"$text\""
}

# Puts a line of code to the template output buffer. Newlines is added
# after code automatically.
#  code  Tcl code
proc ossweb::adp::AppendCode { code } {

    variable adp_code
    append adp_code " " $code "\n"
}

