# Author: Vlad Seryakov vlad@crystalballinc.com
# October 2004

ossweb::conn::callback music_play {} {

    set mode ""
    if { [ns_queryget random] != "" } { set mode random }
    music::stop
    if { [string first " " $file] > -1 } { set file "{$file}" }
    ns_schedule_proc -thread -once 0 "music::play {$file} {$mode}"
}

ossweb::conn::callback music_list {} {

    ossweb::multirow create music file size play

    switch -- ${ossweb:cmd} {
     search {
       foreach f [ossweb::file_list $root .+] {
         if { [regexp -nocase $filter $f] } {
           lappend files [string range $f [string length $root] end]
         }
       }
       set file ""
     }

     panel {
       # Remember currently playing list
       set file [nsv_get music path]
       ossweb::conn -set title "Music Panel"
       ossweb::html::refresh 60 -url [ossweb::lookup::url cmd panel]
       ossweb::widget form_music.ctx -type hidden -value panel -freeze
     }

     m3u {
       foreach f [glob -nocomplain -types { f l d r } $root/$file/*] {
         lappend files [ossweb::conn::hostname][ossweb::file::url music $file/[file tail $f]]
       }
       ns_return 200 audio/x-mpegurl [join $files "\n"]
       return
     }

     default {
       if { $file == "" } {
         set files [ossweb::file::list -path music -dirname f]
       } else {
         set file [string trimleft $file "./"]
         if { ![file isdirectory $root/$file] } {
           set file [file dirname $file]
         }
         foreach f [glob -nocomplain -types { f l d r } $root/$file/*] {
           lappend files $file/[file tail $f]
         }
       }
       if { $file != "" } {
         ossweb::multirow append music [ossweb::lookup::link -text Back file [file dirname $file]]
       }
     }
    }
    ossweb::form form_music set_values
    foreach file [lsort $files] {
      set play ""
      set size ""
      set name [string trimleft $file /]
      if { $ipaddr == "127.0.0.1" || $ipaddr == $host } {
        set play [ossweb::lookup::link -text Play cmd play file $file]
      } else {
        set play [ossweb::lookup::link -text Play cmd m3u file $file]
      }
      if { [file isdirectory $root/$file] } {
        set file [ossweb::lookup::link -text $name file $file]
      } else {
        set size [file size $root/$file]
        set file [ossweb::file::link music $file -text $name]
      }
      ossweb::multirow append music $file $size $play
    }
    # Current playing info
    if { [set f [nsv_get music file]] != "" } {
      set music:size [ossweb::util::size [file size $f]]
      set music:file [string range $f [string length $root] end]
    }
}

ossweb::conn::callback create_form_music {} {

    ossweb::lookup::form form_music
    ossweb::widget form_music.cmd -type hidden -value search -freeze
    ossweb::widget form_music.file -type hidden -optional
    ossweb::widget form_music.filter -type text -label Search \
         -optional
    ossweb::widget form_music.random -type checkbox -label Random \
         -optional \
         -value 1
    ossweb::widget form_music.search -type submit -label Search
    ossweb::widget form_music.play -type button -cmd_name play -label Play
    ossweb::widget form_music.stop -type button -cmd_name stop -label Stop
    ossweb::widget form_music.next -type button -cmd_name next -label "Next>>"
    ossweb::widget form_music.panel -type button -label Panel \
         -window panel \
         -winopts "width=400,height=100,location=0,menubar=0" \
         -url [ossweb::html::url cmd panel lookup:mode 2]
}

set columns { file "" ""
              files const ""
              filter "" ""
              music:size const 0
              music:file const None
              music:rowcount const 0
              ipaddr const {[ns_conn peeraddr]}
              host const {[ns_addrbyhost [ns_info hostname]]}
              root const {[ossweb::file::getname "" -path music]} }

ossweb::conn::process -columns $columns \
           -forms { form_music } \
           -form_recreate t \
           -on_error { index.index } \
           -eval {
            play.panel {
              -exec { music_play }
              -next { -cmd_name panel }
            }
            stop.panel {
              -exec { music::stop }
              -next { -cmd_name panel }
            }
            next.panel {
              -exec { music::stop 0 }
              -next { -cmd_name panel }
            }
            play {
              -exec { music_play }
              -next { -cmd_name view }
            }
            stop {
              -exec { music::stop }
              -next { -cmd_name view }
            }
            next {
              -exec { music::stop 0 }
              -next { -cmd_name view }
            }
            default {
              -exec { music_list }
            }
           }
