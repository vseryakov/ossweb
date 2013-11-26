# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2006

ossweb::conn::callback view {} {

    if { [info proc ::ossweb::tracker::$tab] == "" } {
      return
    }

    set tracker_title [ossweb::tracker::$tab title]
    set tracker_link [ossweb::conn -url -host t]
    set tracker_rss [ossweb::html::link -image feed.png -alt "RSS Feed" cmd rss tab $tab]

    ossweb::multirow create result id url link subject text time age
    foreach row [::ossweb::tracker::$tab new -limit $limit] {
      foreach { id subject text time age data } $row {}
      set url [ossweb::tracker::$tab url -id $id -title $subject -data $data]
      # Dynamic links for HTML format
      if { [ossweb::lookup::mode] > 1 } {
        set link [ossweb::html::link -text $subject -url "javascript:window.opener.location='$url';window.opener.focus();"]
      } else {
        set link [ossweb::html::link -text $subject -url $url]
      }
      set age [ossweb::date uptime $age short]
      ossweb::multirow append result $id $url $link $subject $text $time $age
    }
}

ossweb::conn::callback rss {} {

    view
    ossweb::adp::Trim 1
    ossweb::adp::ContentType application/xhtml+xml
}

ossweb::conn::callback create_form_tab {} {

    foreach name [namespace eval ::ossweb::tracker { info procs }] {
      # Check permissions by app name
      set app_name [ossweb::nvl [ossweb::tracker::$name app_name] $name]
      if { [ossweb::conn::check_acl -acl *.$app_name.*.view.*] } {
        continue
      }
      # Show first tracker if not specified
      if { $tab == "" } {
        set tab $name
      }
      ossweb::widget form_tab.$name -type link -label [ossweb::tracker::$name title] \
           -lookup q
    }
}

ossweb::conn::process \
           -columns { tab "" ""
                      limit int 35
                      result:rowcount const 0
                      now const {[ns_time]} } \
           -forms form_tab  \
           -default view
