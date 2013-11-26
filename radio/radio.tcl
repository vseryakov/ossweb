# Author: Vlad Seryakov vlad@crystalballinc.com
# October 2004

ossweb::conn::callback radio_refresh {} {

    radio::schedule
}

ossweb::conn::callback radio_play {} {

    radio::stop
    ns_schedule_proc -thread -once 0 "radio::play {$url} {$station}"
}

ossweb::conn::callback radio_list {} {

    switch -- ${ossweb:cmd} {
     panel {
       # Remember currently playing list
       set file [nsv_get radio path]
       ossweb::conn -set title "Radio Panel"
       ossweb::html::refresh 60 -url [ossweb::lookup::url cmd panel]
       ossweb::widget form_radio.ctx -type hidden -value panel -freeze
     }
    }
    ossweb::form form_radio set_values
    ossweb::db::multirow radio sql:radio.list -eval {
      if { $ipaddr == "127.0.0.1" || $ipaddr == $host } {
        append row(play) [ossweb::lookup::link -text Play cmd play url $row(radio_url) station $row(radio_title)]
      }
      append row(play) " " [ossweb::html::link -image radio.gif -url $row(radio_url)]
    }
    # Current playing info
    set radio:url [nsv_get radio url]
    set radio:station [nsv_get radio station]
}

ossweb::conn::callback create_form_radio {} {

    ossweb::lookup::form form_radio
    ossweb::widget form_radio.cmd -type hidden -value search -freeze
    ossweb::widget form_radio.url -type hidden -optional
    ossweb::widget form_radio.station -type hidden -optional
    ossweb::widget form_radio.play -type button -cmd_name play -label Play
    ossweb::widget form_radio.stop -type button -cmd_name stop -label Stop
    ossweb::widget form_radio.next -type button -cmd_name next -label "Next>>"
    ossweb::widget form_radio.refresh -type button -label Refresh \
         -url [ossweb::lookup::url cmd refresh]
    ossweb::widget form_radio.panel -type button -label Panel \
         -window panel \
         -winopts "width=400,height=100,location=0,menubar=0" \
         -url [ossweb::html::url cmd panel lookup:mode 2]
}

set columns { url "" ""
              station "" ""
              format "" ""
              radio:url const None
              radio:station const None
              radio:rowcount const 0
              ipaddr const {[ns_conn peeraddr]}
              host const {[ns_addrbyhost [ns_info hostname]]}
              root const {[ossweb::file::getname "" -path radio]} }

ossweb::conn::process -columns $columns \
           -forms { form_radio } \
           -form_recreate t \
           -on_error { index.index } \
           -eval {
            play.panel {
              -exec { radio_play }
              -next { -cmd_name panel }
            }
            stop.panel {
              -exec { radio::stop }
              -next { -cmd_name panel }
            }
            next.panel {
              -exec { radio::stop 0 }
              -next { -cmd_name panel }
            }
            play {
              -exec { radio_play }
              -next { -cmd_name view }
            }
            refresh {
              -exec { radio_refresh }
              -next { -cmd_name view }
            }
            stop {
              -exec { radio::stop }
              -next { -cmd_name view }
            }
            next {
              -exec { radio::stop 0 }
              -next { -cmd_name view }
            }
            default {
              -exec { radio_list }
            }
           }
