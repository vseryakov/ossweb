# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2002

namespace eval webcam {
    variable version "Webcam version 1.1"
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

# Link to webcam from the toolbar
proc ossweb::html::toolbar::webcam {} {

    if { [ossweb::conn::check_acl -acl *.webcam.webcam.view.*] } { return }
    return [ossweb::html::link -image webcam.gif -status Webcam -alt Webcam -app_name webcam webcam]
}

# Device properties
proc webcam::device { device { name "" } } {

    set dev [split $device :]
    set device [lindex $dev 0]
    set width [ossweb::nvl [lindex $dev 1] 320]
    set height [ossweb::nvl [lindex $dev 2] 200]
    set brightness [ossweb::nvl [lindex $dev 3] 32768]
    set contrast [ossweb::nvl [lindex $dev 4] 32768]
    set input [ossweb::nvl [lindex $dev 5] 1]
    set norm [ossweb::nvl [lindex $dev 6] 1]
    switch -- $name {
     width { return $width }
     height { return $height }
     brightness { return $brightness }
     contrast { return $contrast }
     name { return [file tail $device] }
     acl { return [ossweb::conn::check_acl -acl *.webcam.*.grab.[file tail $device]] }
     info { return "-device $device -width $width -height $height -brightness $brightness -contrast $contrast -input $input -norm $norm" }
     default { return $device }
    }
}

# List of all webcam devices
proc webcam::devices { args } {

    ns_parseargs { {-acl f} } $args

    set devices ""
    foreach device [ossweb::config webcam:devices] {
      if { $acl == "t" && [webcam::device $device acl] } { continue }
      lappend devices [webcam::device $device]
    }
    return $devices
}

# Generates images from the camera
proc webcam::schedule { { filter "" } } {

    set history [ossweb::config webcam:history 60]
    foreach dev [ossweb::config webcam:devices] {
      set device [webcam::device $dev]
      if { $filter != "" && ![regexp $filter $device] } { continue }
      if { [ossweb::resource::trylock video $device] <= 0 } { continue }
      set path [ossweb::config webcam:path [ns_info home]/modules/files/webcam]/[file tail $device]
      set now [ns_time]
      set info [webcam::device $dev info]
      if { ![file isdirectory $path] } { catch { file mkdir $path } }
      if { [catch { eval "ns_sysv4l grab $info -file $path/$now.png" } errmsg] } {
        ns_log Error webcam::schedule: $device: $info: $errmsg
      }
      ossweb::resource::unlock video $device
      # Perform garbage collection
      if { $now - [ossweb::cache get webcam:cleanup:$device 0] > 300 } {
        ossweb::cache set webcam:cleanup:$device $now
        foreach file [lsort [glob -nocomplain $path/*]] {
          if { $now - [file mtime $file] >= $history } { file delete -force -- $file }
        }
      }
    }
}

# Returns last image to be displayed
proc webcam::image { { device "" } } {

    # Take first device from the list
    if { $device == "" } {
      set device [webcam::device [lindex [ossweb::config webcam:devices] 0]]
    }
    set path [ossweb::config webcam:path [ns_info home]/modules/files/webcam/[file tail $device]]
    return [lindex [lsort [glob -nocomplain $path/*]] end]
}

