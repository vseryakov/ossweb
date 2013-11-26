# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2002

ossweb::conn::callback weather_search {} {

    if { $zipcode == "" } {
      ossweb::conn::next -cmd_name view
      return
    }
    set weather [weather::zipcode::process $zipcode]
}

ossweb::conn::callback weather_view {} {

    if { [set style [ossweb::config weather:style kn]] != "" &&
         [string index $style end] != "/" } {
      append style /
    }
    set imgdir weather/$style

    foreach name [weather::process] {
      switch -glob $name {
       *zone {
         set forecast $name
         ossweb::multirow create days day weather wind temp icon image
         set count [weather::object $name forecast:rowcount]
         for { set i 1 } { $i <= $count } { incr i } {
           set temp [weather::object $name forecast:$i:high]
           if { [set low [weather::object $name forecast:$i:low]] != "" } {
             if { $temp != "" } { append temp "/" }
             append temp $low
           }
           if { $temp == "" } { set temp [weather::object $name forecast:$i:temp] }
           ossweb::multirow append days \
                [weather::object $name forecast:$i:day] \
                [weather::object $name forecast:$i:weather] \
                [weather::object $name forecast:$i:wind] \
                $temp \
                [weather::object $name forecast:$i:icon] \
                [ossweb::html::image $imgdir/[weather::object $name forecast:$i:icon].gif -width "" -height ""]
         }
       }
       *metar -
       *zipcode {
         if { $weather == "" } { set weather $name }
       }
      }
    }
}

ossweb::conn::callback create_form_weather {} {

     ossweb::widget form_weather.zipcode -type text -label "Zip Code" \
          -datatype integer \
          -html { size 5 maxlength 5 } \
          -optional
     ossweb::widget form_weather.search -type submit -name cmd -label Search
}

ossweb::conn::process \
     -columns { format "" ""
                zipcode int ""
                imgdir const weather
                weather const ""
                forecast const ""
                days:rowcount const 0 } \
     -forms form_weather \
     -on_error index \
     -eval {
       search {
         -exec { weather_search }
       }
       default {
         -exec { weather_view }
       }
     }
