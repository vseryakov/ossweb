# Author: Vlad Seryakov vlad@crystalballinc.com
# November 2004

namespace eval radio {
  variable version "Radio version 1.0"
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
    namespace eval prefs {}
  }
}

proc radio::init {} {

    # Setup home directory
    env set HOME [ossweb::util::gethome]
    # X11 display for local playback
    env set DISPLAY ":0.0"
    # Cache for local playback
    nsv_array set radio { station "" url "" playing 0 id 0 }
    ns_log Notice radio: initialized
}

ossweb::register_init radio::init

# Link to music from the toolbar
proc ossweb::html::toolbar::radio {} {

    if { [ossweb::conn::check_acl -acl *.radio.radio.view.*] } { return }
    return [ossweb::html::link -image radio.gif -status Radio -alt Radio -app_name radio radio]
}

# Plays radio on local X11 display
proc radio::play { url station } {

    if { $url == "" || $station == "" } { return }

    if { [nsv_get radio playing] } {
      ns_log Error radio::play: radio player [nsv_get radio id] is running
      return
    }
    nsv_set radio playing 1
    nsv_set radio id [pid]
    nsv_set radio url $url
    nsv_set radio station $station
    # Run media player
    set cmd [string map [list @file@ $url] [ossweb::config radio:player]]
    ns_log Notice radio::play: $cmd
    if { $cmd != "" && [catch { exec sh -c "$cmd >> [ns_info log] 2>&1" } errmsg] } {
      ns_log Notice radio::play: $url: $errmsg
    }
    nsv_array set radio { playing 0 url "" station "" }
}

# Stop radio player
proc radio::stop { { stop 1 } } {

    if { [set url [nsv_get radio url]] == "" } { return }
    catch { set plist [exec sh -c "ps agx|grep \"$url\"|grep -v grep|awk '{print \$2}'"] }
    catch { foreach pid $plist { ns_kill $pid 15 } }
    ns_sleep 1
    catch { foreach pid $plist { ns_kill $pid 9 } }
    nsv_array set radio { playing 0 url "" station "" }
}

# Schedule radio playlist downloader
proc radio::schedule {} {

    set url http://yp.shoutcast.com/directory/index.phtml?sgenre=TopTen
    ossweb::db::exec sql:radio.delete
    set data [exec /usr/bin/lynx -dump $url]
    set id 0
    foreach line [split $data "\n"] {
      if { [regexp {\[([0-9]+)\]\[tunein.gif\]} $line d id] } {
        set playurl($id) ""
        set playgenre($id) ""
        set playtitle($id) ""
      } elseif { [regexp {([0-9]+). (http://.+/sbin/shoutcast-playlist.pls.+)$} $line d id url] } {
        set playurl($id) $url
        set id 0
      } elseif { [regexp {\[([^\]]+)\] +CLUSTER +\[[0-9]+\](.+)} $line d genre title] } {
        set playtitle($id) "[string trim $title " \r\n\t"] "
        set playgenre($id) $genre
      } else {
        if { $id } { append playtitle($id) [string trim $line " \n\r\t"] }
        set id 0
      }
    }
    foreach id [lsort -integer [array names playurl]] {
      if { [set radio_url $playurl($id)] == "" } { continue }
      if { [set radio_genre $playgenre($id)] == "" } { continue }
      if { [set radio_title $playtitle($id)] == "" } { continue }
      if { [set idx [string first "Now Playing:" $radio_title]] > 0 } {
        set radio_title [string range $radio_title 0 [incr idx -1]]
      }
      ossweb::db::exec sql:radio.create
    }
}
