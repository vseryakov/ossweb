# Author: Vlad Seryakov vlad@crystalballinc.com
# September 2007

namespace eval youtube {
    variable version "Youtube version 0.1"

    namespace eval export {}
}

proc ossweb::html::toolbar::youtube {} {

    return [ossweb::html::link -image youtube.gif -hspace 6 -status YouTube -alt YouTube -app_name youtube youtube]
}

proc ossweb::schedule::hourly::youtube {} {

    if { [ossweb::true [ossweb::config youtube:enabled 1]] } {
      youtube::schedule
    }
}

proc youtube::schedule {} {

    # Cleanup old records
    foreach episode [ossweb::db::select youtube -columns episode -where "load_time < NOW() - '[ossweb::config youtube:history 1] days'::INTERVAL"] {
      ossweb::file::delete $episode.jpg -path youtube
      ossweb::db::delete youtube episode $episode
    }

    set sort 0
    set load_time [ns_fmttime [ns_time] "%Y-%m-%d %H:%M:%S"]

    foreach category [ossweb::config youtube:feed:standard] {
      youtube::parser $load_time [incr sort] $category http://gdata.youtube.com/feeds/api/standardfeeds/$category?
    }

    foreach category [ossweb::config youtube:feed:custom] {
      youtube::parser $load_time [incr sort] $category http://gdata.youtube.com/feeds/api/videos?vq=[ns_urlencode $category]
    }

    foreach category [ossweb::config youtube:feed:api] {
      youtube::parser $load_time [incr sort] $category http://gdata.youtube.com/feeds/api/videos/-/[ns_urlencode $category]?
    }

    # Custom handlers
    foreach proc [namespace eval ::youtube::export { info procs }] {
      if { [catch { ::youtube::export::$proc } errmsg] } {
        ns_log error ossweb::schedule::hourly::youtube: $proc: $errmsg
      }
    }
}

proc youtube::videourl { ylink { yurl "" } } {

    # Link to flash video
    if { $ylink != "" } {
      if { [catch { set fds [ns_httpopen GET $ylink] } errmsg] } {
        ns_log Error youtube::videourl: $ylink: $errmsg
        return
      }
      close [lindex $fds 0]
      close [lindex $fds 1]

      set hdrs [lindex $fds 2]
      set location [ns_set iget $hdrs location]
      ns_set free $hdrs

      if { [regexp {video_id=([^&= ]+).+t=([^&= ]+)} $location d id t] } {
        return http://www.youtube.com/get_video?video_id=$id&t=$t
      }
    }

    # Url to page with embedded flash
    if { $yurl != "" } {
      catch { ns_httpget $yurl } data

      if { [regexp {"video_id": "([^"]+)".+"t": "([^"]+)"} $data d id t] } {
        return http://www.youtube.com/get_video?video_id=$id&t=$t
      }
    }
    return
}

proc youtube::imagefile { id imageurl } {

    # Make sure we do not have image from the previous batch because indexes are reused
    set file [ossweb::file::getname $id.jpg -path youtube -create t]

    if { $imageurl != "" && ![file exists $file] && ![catch { ns_httpget $imageurl } data] } {
      ossweb::write_file $file $data
    }
}

# Reset current state of the parser
proc youtube::reset { args } {

    nsv_array reset youtube:data {}

    foreach { k v } $args {
      nsv_set youtube:ctl $k $v
    }
}

proc youtube::parser { load_time sort category url } {

    set max [ossweb::config youtube:maxresults 50]
    append url &max-results=$max

    set time [ossweb::config youtube:time]
    switch -- $category {
     top_rated -
     most_viewed {
       if { $time != "" } {
         append url &time=$time
       }
     }
    }

    if { [catch { ns_httpget $url } data] } {
      ns_log Error youtube::parser: $category: $data: $::errorInfo
      return
    }

    ossweb::write_file /tmp/$category.xml $data

    ns_log notice youtube::parser: $category: $url

    youtube::reset load_time $load_time sort $sort category $category path ""

    set parser [expat youtube -final yes \
                      -elementstartcommand {youtube::element start} \
                      -elementendcommand {youtube::element end} \
                      -characterdatacommand {youtube::element data}]

    if { [catch { $parser parse $data } errmsg] } {
      ns_log Error youtube::parser: $category: $errmsg: $::errorInfo
    }
    $parser free
}

proc youtube::element { tag name { attrs "" } } {

    switch -- $tag {
     start {

       # Append tag name
       nsv_lappend youtube:ctl path $name

       # Tag attributes
       array set params $attrs

       set path [nsv_get youtube:ctl path]

       switch -- $path {
        "feed entry" {
          youtube::reset
        }

        "feed entry category" {
          nsv_lappend youtube:data keywords [ossweb::coalesce params(term)]
        }

        "feed entry media:group yt:duration" {
          nsv_set youtube:data duration [ossweb::coalesce params(seconds)]
        }

        "feed entry yt:statistics" {
          nsv_set youtube:data views [ossweb::coalesce params(viewCount)]
        }

        "feed entry gd:rating" {
          nsv_set youtube:data rating [ossweb::coalesce params(average)]
        }

        "feed entry media:group media:player" {
          if { ![nsv_exists youtube:data playurl] } {
            nsv_set youtube:data playurl [ossweb::coalesce params(url)]
          }
        }

        "feed entry media:group media:content" {
          if { [ossweb::coalesce params(yt:format)] == 5 } {
            nsv_set youtube:data playurl $params(url)
          }
        }

        "feed entry media:group media:thumbnail" {
          if { ![nsv_exists youtube:data imageurl] } {
            nsv_set youtube:data imageurl [ossweb::coalesce params(url)]
          }
        }
       }
     }

     end {
       set path [nsv_get youtube:ctl path]

       switch -- $path {
        "feed entry" {
          foreach { key value } [nsv_array get youtube:data] {
            set [string tolower $key] $value
          }
          foreach { key value } [nsv_array get youtube:ctl] {
            set $key $value
          }

          # Required fields
          if { [ossweb::coalesce id] == "" ||
               [ossweb::coalesce name] == "" ||
               [ossweb::coalesce title] == "" ||
               [ossweb::coalesce playurl] == "" } {
             return
          }
          set episode [lindex [split $id /] end]
          set description [ossweb::coalesce content]
          set update_time [ossweb::coalesce updated]
          set create_time [ossweb::coalesce published]
          set author $name
          set id ""

          # Output all info in case of error
          if { [ossweb::db::replace youtube episode $episode] } {
            ns_log notice youtube: ctl: [nsv_array get youtube:ctl]
            ns_log notice youtube: data: [nsv_array get youtube:data]
          }

          youtube::reset

          # Save screen snapshot
          youtube::imagefile $episode [ossweb::coalesce imageurl]
        }
       }

       # Remove last item
       nsv_set youtube:ctl path [lrange $path 0 end-1]
     }

     data {
       set path [nsv_get youtube:ctl path]

       nsv_append youtube:data [lindex $path end] $name
     }
    }
}
