# Author: Vlad Seryakov vlad@crystalballinc.com
# September 2003

namespace eval news {
  variable version "News version 1.1"
  namespace eval yahoo {}
  namespace eval parser {}
}


# Link to news from the toolbar
proc ossweb::html::toolbar::news {} {

    return [ossweb::html::link -image /img/toolbar/news.gif -mouseover /img/toolbar/news_o.gif -hspace 6 -status News -alt News -app_name news news]
}

# Refresh current news snapshot
proc ossweb::schedule::hourly::news {} {

    if { [ossweb::true [ossweb::config news:enabled 1]] } {
      news::yahoo::schedule
      ossweb::db::exec sql:news.update.history
    }
}

# RSS news feed
proc news::yahoo::schedule {} {

    set id [ossweb::db::nextval news]
    news::yahoo::parser $id topstories GENERAL
    news::yahoo::parser $id us REGION
    news::yahoo::parser $id world WORLD
    news::yahoo::parser $id business BUSINESS
    news::yahoo::parser $id tech TECH
    news::yahoo::parser $id science SCIENCE
    news::yahoo::parser $id sports SPORTS
    news::yahoo::parser $id entertaiment ENTERTAINMENT
    news::yahoo::parser $id health HEALTH
}

# Reset current state of the parser
proc news::parser::reset { args } {

    lappend args name ""
    foreach { key val } $args {
      nsv_set news:ctl $key $val
    }
    nsv_array reset news:data {}
}

proc news::yahoo::parser { id rss category } {

    set body [ns_httpget http://rss.news.yahoo.com/rss/$rss]

    news::parser::reset id $id category $category top ""

    set parser [expat yahoo -final yes \
                      -elementstartcommand {news::yahoo::element start} \
                      -elementendcommand {news::yahoo::element end} \
                      -characterdatacommand {news::yahoo::element data}]

    if { [catch { $parser parse $body } errmsg] } {
      ns_log Error news::yahoo::parser: $rss: $errmsg: $::errorInfo
    }
    $parser free
}

proc news::yahoo::element { tag name { attrs "" } } {

    set top [nsv_get news:ctl top]
    switch -- $tag {
     start {
       switch -- $top.$name {
        .item {
          news::parser::reset top item name ""
        }

        item.url -
        item.link -
        item.title -
        item.pubDate -
        item.description {
          nsv_set news:ctl name $name
        }

        default {
          nsv_set news:ctl name ""
        }
       }
     }

     end {
       switch -- $top.$name {
        item.item {
          set news_id [nsv_get news:ctl id]
          set category [nsv_get news:ctl category]
          foreach { key value } [nsv_array get news:data] {
            set [string tolower $key] $value
          }
          ossweb::db::exec sql:news.create
          news::parser::reset top "" name ""
        }
       }
     }

     data {
       set key [nsv_get news:ctl name]
       switch -- $top.$key {
        item.url -
        item.link -
        item.pubDate -
        item.title -
        item.description {
          nsv_append news:data $key $name
        }
       }
     }
    }
}
