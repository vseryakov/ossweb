# Author: Vlad Seryakov vlad@crystalballinc.com
# October 2004

namespace eval music {
  variable version "Music version 1.0"
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
    namespace eval prefs {}
  }
}

ossweb::register_init music::init

proc music::init {} {

    ossweb::file::register_download_proc music ::music::download
    # Setup home directory
    env set HOME [ossweb::util::gethome]
    # X11 display for local playback
    env set DISPLAY ":0.0"
    # Cache for local playback
    nsv_array set music { path "" file "" stop 0 playing 0 id 0 }
    ns_log Notice music: initialized
}

# File download handler, used by ossweb::file::download for file download verification
proc music::download { params } {

    # Allow from local network only, otherwise should be logged in
    if { ![ossweb::conn::is_local_network] && [ossweb::conn session_id] == "" } {
      ns_log Notice music:download: invalid session [ossweb::conn session_id], not local network [ossweb::conn peeraddr]
      return file_accessdenied
    }
    return file_return
}

# Link to music from the toolbar
proc ossweb::html::toolbar::music {} {

    if { [ossweb::conn::check_acl -acl *.music.music.view.*] } { return }
    return [ossweb::html::link -image music.gif -hspace 6 -status Music -alt Music -app_name music music]
}

# Plays music on local X11 display
proc music::play { { files "" } { mode "" } } {

    if { [nsv_get music playing] } {
      ns_log Error music::play: music player [nsv_get music id] is running
      return
    }
    nsv_set music playing 1
    nsv_set music stop 0
    nsv_set music id [pid]
    nsv_set music path $files
    set path [ossweb::file::getname "" -path music]
    # Play all files if not specified
    if { $files == "" } {
      foreach f [ossweb::file_list $path {\.mp3|\.wav}] { lappend files $f }
    } else {
      set flist ""
      foreach d $files {
        if { [file isdirectory $path/$d] } {
          foreach f [ossweb::file_list $path/$d {\.mp3|\.wav}] { lappend flist $f }
        } else {
          lappend flist $path/$d
        }
      }
      set files $flist
    }
    switch -- $mode {
     random { set files [ossweb::util::lshuffle $files] }
    }
    # Run media player
    foreach file $files {
      set cmd [string map [list @file@ $file] [ossweb::config music:player]]
      ns_log Notice music::play: $cmd
      nsv_set music file $file
      if { $cmd != "" && [catch { exec sh -c "$cmd >> [ns_info log] 2>&1" } errmsg] } {
        ns_log Notice music::play: $file: $errmsg
      }
      if { [nsv_get music stop] } { break }
    }
    nsv_set music playing 0
}

# Stop music player
proc music::stop { { stop 1 } } {

    nsv_set music stop $stop
    if { [set file [file tail [nsv_get music file]]] == "" } { return }
    catch { set plist [exec sh -c "ps agx|grep \"$file\"|grep -v grep|awk '{print \$2}'"] }
    catch { foreach pid $plist { ns_kill $pid 15 } }
    ns_sleep 1
    catch { foreach pid $plist { ns_kill $pid 9 } }
}

