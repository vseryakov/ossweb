# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2002

namespace eval weather {
  variable version "Weather version 1.0"
  variable weather_level 0
  namespace eval zone {}
  namespace eval zipcode {}
  namespace eval metar {}
  namespace eval radar {}
  namespace eval export {}
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

# Link to weather from the toolbar
proc ossweb::html::toolbar::weather {} {

    if { [ossweb::conn::check_acl -acl *.weather.weather.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/weather.gif -mouseover /img/toolbar/weather_o.gif -width "" -height "" -hspace 6 -status Weather -alt Weather -app_name weather weather]
}

# REFERENCES:
#   Finding a locations' Station ID:
#     http://www.nws.noaa.gov/oso/siteloc.shtml
#     http://www.nws.noaa.gov/pub/stninfo/nsd_cccc.txt
#
#   Zone Forecasts:
#     Finding a location's Zone ID:
#     http://iwin.nws.noaa.gov/iwin/??/zone.html
#     (replace ?? with your lowercase 2 character state code).
#     Then scroll down until you find the city/area you want
#     listed. Just above that you will find the zone code, in
#     the format of ??Z??? (first 2 chars are state code,
#     followed by "Z", followed by 3 digit zone code).
#
#   TAF forecasts:
#     ftp://weather.noaa.gov/data/forecasts/taf/stations/
#     (eg ftp://weather.noaa.gov/data/forecasts/taf/stations/KSAC.TXT)
#
#   METAR conditions:
#     http://weather.noaa.gov/pub/data/observations/metar/decoded/station.TXT
#     (eg ftp://weather.noaa.gov/data/observations/metar/stations/KSAC.TXT)
#
#   Specifications:
#    http://wsom.nws.noaa.gov/wsom/manual/CHAPTERC/C_11_PDF/c11_main.pdf

# Refresh current weather data
proc ossweb::schedule::hourly::weather {} {

    if { [ossweb::true [ossweb::config weather:enabled 1]] } {
      foreach nm [namespace children ::weather] {
        if { [info proc ${nm}::schedule] != "" } {
           ${nm}::schedule
        }
      }
      ossweb::db::exec sql:weather.update.history

      # Custom handlers
      foreach proc [namespace eval ::weather::export { info procs }] {
        if { [catch { ::weather::export::$proc } errmsg] } {
          ns_log error ossweb::schedule::hourly::weather: $proc: $errmsg
        }
      }
    }
}

# Zone Forecast (ZFP)
#
# FPUS54 KTSA 132158
# ZFPTUL
#
# EASTERN OKLAHOMA/NORTHWEST ARKANSAS ZONE FORECASTS
# NATIONAL WEATHER SERVICE TULSA OK
# 400 PM CST FRI DEC 13 2002
#
# ARZ001-141030-
# BENTON-INCLUDING THE CITIES OF...ROGERS
# 400 PM CST FRI DEC 13 2002
#
# .TONIGHT...PARTLY CLOUDY. LOWS AROUND 30. NORTHWEST WINDS 5 TO 10MPH.
# .SATURDAY...MOSTLY SUNNY. HIGHS IN THE MID 50S. WEST WINDS AROUND 5 MPH.
# .SATURDAY NIGHT...MOSTLY CLEAR. LOWS IN THE LOWER 30S. LIGHT SOUTHWEST WINDS.
# .SUNDAY...PARTLY CLOUDY. HIGHS IN THE MID 60S.
# .SUNDAY NIGHT...PARTLY CLOUDY. LOWS AROUND 40.
# .MONDAY...PARTLY CLOUDY. HIGHS IN THE MID 60S.
# .MONDAY NIGHT...PARTLY CLOUDY. LOWS IN THE MID 40S.
# .TUESDAY...PARTLY CLOUDY. HIGHS IN THE LOWER 60S.
# .WEDNESDAY...PARTLY CLOUDY WITH A CHANCE OF SHOWERS. LOWS IN THE MID 40S.
# HIGHS IN THE UPPER 50S.
# .THURSDAY...MOSTLY CLOUDY WITH A CHANCE OF RAIN. LOWS AROUND 40. HIGHS AROUND 50.
# .FRIDAY...PARTLY CLOUDY. LOWS IN THE UPPER 20S. HIGHS IN THE MID 40S.
#
proc weather::zone::request { zone } {

    set zone [string tolower $zone]
    set state [string range $zone 0 1]
    set data [ns_httpget http://weather.noaa.gov/pub/data/forecasts/zone/$state/$zone.txt]
    if { [string first "WEATHER SERVICE" $data] == -1 } {
      ns_log Error weather::zone::request: $data
      return
    }
    return $data
}

proc weather::zone::process { zone } {

    return [weather::zone::parse $zone [weather::zone::request $zone]]
}

proc weather::zone::schedule {} {

    # Weather aleerts that will be shown on the web pages
    set walerts ""
    set weather_type Zone
    set wregexp [ossweb::config weather:alerts]
    set wcount [ossweb::config weather:alerts:count 1]
    foreach weather_id [ossweb::config weather:zone] {
      if { [set weather_data [weather::zone::request $weather_id]] == "" } { continue }
      ossweb::db::exec sql:weather.create
      # Extract alerts
      if { $wregexp == "" } { continue }
      set name [weather::zone::parse $weather_id $weather_data]
      set line [weather::object $name forecast:warning]
      if { [regexp -nocase $wregexp $line] } { lappend walerts "WARNING: $line" }
      set count [weather::object $name forecast:rowcount]
      for { set i 1 } { $i <= $count } { incr i } {
        set line [weather::object $name forecast:$i:weather]
        if { [regexp -nocase $wregexp $line] } {
          if { [set high [weather::object $name forecast:$i:high]] != "" } { append line "/$high" }
          lappend walerts "[weather::object $name forecast:$i:day]: $line"
          if { [incr wcount -1] <= 0 } { break }
        }
      }
    }
    if { $walerts != "" } {
      set walerts "<A HREF=[ossweb::html::url -app_name weather weather] STYLE=\"color:red;\">[join $walerts ,]</A>"
    }
    ossweb::conn::set_property WEATHER:ALERTS $walerts -user_id 0 -global t -cache t
}

# Returns weather object name
proc weather::zone::parse { id data } {

    set name [ns_rand 100000]:zone
    weather::object $name -create obj:id $id obj:type zone
    set data [string tolower $data]
    # Position of the forecast data
    set forecast [string first $data "\n."]
    set flag 0
    set count 0
    set buffer ""
    set lines [split $data "\r\n"]
    for { set i 0 } { $i < [llength $lines] } { incr i } {
      set line [lindex $lines $i]
      switch $flag {
       0 {
         # Parse header
         switch -regexp -- $line {
          {.+zone forecasts} {
             weather::object $name -Set forecast:area $line
          }
          {weather service} {
             weather::object $name -Set forecast:center $line
          }
          {^[a-z][a-z]z[0-9][0-9][0-9][>-]} {
             weather::object $name -Set forecast:zone $line
             set flag 1
          }
         }
       }
       1 {
         # Collecting cities
         if { [string is integer -strict [lindex $line 0]] } {
           set flag 2
           weather::object $name -set forecast:date [string toupper $line]
         } else {
           weather::object $name -Append forecast:city [string map { ... " " } $line]
         }
       }
       2 {
         # Warning message
         if { [string index $line 0] == "." && [string index $line 1] != "." } {
           incr i -1
           set flag 3
           continue
         }
         weather::object $name -Append forecast:warning [string map { "..." {} } $line]
       }
       3 {
         # Parse forecast days
         set line2 [lindex $lines [expr $i+1]]
         if { $line2 != "" && ![string match ".*...*" $line2] } {
           append buffer $line " "
           continue
         }
         set line "$buffer$line"
         set buffer ""
         if { ![string match ".*...*" $line] } {
           # Forecast separator
           if { [string match "*\$\$*" $line] } { break }
           continue
         }
         set data [split $line "."]
         incr count
         weather::object $name -Set \
                  forecast:$count:day [lindex $data 1] \
                  forecast:$count:weather [lindex $data 4]
         foreach item [lrange $data 5 end] {
           switch -glob -- $item {
            "*lows*" {
               weather::object $name -Append forecast:$count:temp $item
            }
            "*highs*" {
               weather::object $name -Append forecast:$count:temp $item
            }
            "*winds*" {
               weather::object $name -Append forecast:$count:wind $item
            }
            default {
               weather::object $name -Append forecast:$count:weather $item
            }
           }
         }
         # Assign weather icon
         weather::object $name -set forecast:$count:icon \
               [weather::icon "[weather::object $name forecast:$count:day] [weather::object $name forecast:$count:weather]"]
         # Extract temperature numbers
         set temp [weather::object $name forecast:$count:temp]
         if { [regexp -nocase {Lows[^0-9]* ([0-9]+)} $temp d low] } {
           weather::object $name -set forecast:$count:low "$low F"
         }
         if { [regexp -nocase {Highs[^0-9]* ([0-9]+)} $temp d high] } {
           weather::object $name -set forecast:$count:high "$high F"
         }
       }
      }
    }
    weather::object $name -set forecast:rowcount $count
    return $name
}

# Weather Underground raw weather information
# by zip code.
#
# 6:51 PM EST December 15, 2002|46|41|N/A|47%|27|SSW at 9|
# 29.79|Overcast|10|07:20 AM (EST)|04:47 PM (EST)|
# 11|36|45|N/A|N/A|N/A|Herndon|Virginia|02:22 PM (EST)|03:13 AM (EST)|KIAD|
#
#  1) Updated Time & Date
#  2) Temperature
#  3) Wind Chill
#  4) Heat Index
#  5) Humidity
#  6) Dew Point
#  7) Wind Direction & Speed
#  8) Pressure
#  9) Conditions
# 10) Visibility
# 11) Sunrise Time
# 12) Sunset Time
# 13) Yesterday's Growing Degree Days
# 14) Yesterdays Maximum
# 15) Yesterdays Minimum
# 16) UNKNOWN
# 17) UNKNOWN
# 18) UNKNOWN
# 19) City
# 20) State
# 21) Moonrise Time
# 22) Moonset Time
# 23) Weather Station Code (???)
# 24) Time script checked the site
#

proc weather::zipcode::request { zipcode } {

    set data [ns_httpget http://www.wunderground.com/auto/raw/$zipcode]
    if { ![string match "*|*|*|*" $data] } {
      ns_log Error weather::zipcode::request: $data
      return
    }
    return $data
}

proc weather::zipcode::process { zipcode } {

    return [weather::zipcode::parse $zipcode [weather::zipcode::request $zipcode]]
}

proc weather::zipcode::schedule {} {

    set weather_type Zipcode
    foreach weather_id [ossweb::config weather:zipcode] {
      if { [set weather_data [weather::zipcode::request $weather_id]] != "" } {
        ossweb::db::exec sql:weather.create
      }
    }
}

# Returns weather object name
proc weather::zipcode::parse { id data } {

    set name [ns_rand 100000]:zipcode
    weather::object $name -create obj:id $id obj:type zipcode
    set data [split $data "|"]
    weather::object $name -set \
             Date [lindex $data 0] \
             Temperature [ossweb::util::fmt [lindex $data 1] "%s F"] \
             Wind_Chill [ossweb::util::fmt [lindex $data 2] "%s F"] \
             Heat_Index [lindex $data 3] \
             Humidity [lindex $data 4] \
             DewPoint [ossweb::util::fmt [lindex $data 5] "%s F"] \
             Wind [lindex $data 6] \
             Pressure [ossweb::util::fmt [lindex $data 7] "%s in. Hg"] \
             Visibility [ossweb::util::fmt [lindex $data 9] "%s mile(s)"] \
             Sunrise [lindex $data 10] \
             Sunset [lindex $data 11] \
             City [lindex $data 18] \
             State [lindex $data 19] \
             Moonrise [lindex $data 20] \
             Moonset [lindex $data 21] \
             Station [lindex $data 22] \

    weather::object $name -Set \
             Sky [lindex $data 8]
    weather::object $name -icon
    return $name
}

# The National Oceanic and Atmospheric Administration (NOAA,
# www.noaa.gov) provides easy access to the weather reports
# generated by a large number of weather stations (mostly at
# airports) worldwide. To get the station code go to
# http://www.nws.noaa.gov/tg/siteloc.shtml.
# Those reports are called METAR reports and
# are delivered as plain text files that look like this:
# Station list format: http://www.nws.noaa.gov/oso/site.shtml
#
#
# Washington DC, Washington-Dulles International Airport, VA, United States (KIAD) 38-56-05N 077-26-51W 93M
# Dec 13, 2002 - 02:51 PM EST / 2002.12.13 1951 UTC
# Wind: from the SE (140 degrees) at 3 MPH (3 KT):0
# Visibility: 1 1/2 mile(s):0
# Sky conditions: overcast
# Weather: light rain
# Precipitation last hour: 0.08 inches
# Temperature: 37.0 F (2.8 C)
# Dew Point: 32.0 F (0.0 C)
# Relative Humidity: 81%
# Pressure (altimeter): 29.92 in. Hg (1013 hPa)
# ob: KIAD 131951Z 14003KT 1 1/2SM -RA SCT007
# cycle: 20
#

proc weather::metar::request { station } {

    set station [string toupper $station]
    set data [ns_httpget http://weather.noaa.gov/pub/data/observations/metar/decoded/$station.TXT]
    if { [string first "Temperature:" $data] == -1 } {
      if { [string first "Weather:" $data] == -1 } {
        ns_log Error weather::metar::request: $data
      }
      return
    }
    return $data
}

proc weather::metar::process { station } {

    return [weather::metar::parse $station [weather::metar::request $station]]
}

proc weather::metar::schedule {} {

    set weather_type Metar
    foreach weather_id [ossweb::config weather:station] {
      if { [set weather_data [weather::metar::request $weather_id]] != "" } {
        ossweb::db::exec sql:weather.create
      }
    }
}

# Returns weather object name
proc weather::metar::parse { id data } {

    set name [ns_rand 100000]:metar
    weather::object $name -create obj:id $id obj:type metar
    set count 0
    foreach line [split $data "\r\n"] {
      switch -glob -- $line {
       "Wind:*" {
          weather::object $name -set Wind [string range $line 6 end]
       }
       "Visibility:*" {
          weather::object $name -set Visibility [string range $line 12 end]
       }
       "Sky conditions:*" {
          weather::object $name -Set Sky [string range $line 16 end]
       }
       "Weather:*" {
          weather::object $name -Set Weather [string range $line 9 end]
       }
       "Precipitation last hour:*" {
          weather::object $name -set Precipitation [string range $line 25 end]
       }
       "Temperature:*" {
          weather::object $name -set Temperature [string range $line 13 end]
       }
       "Dew Point:*" {
          weather::object $name -set Dew_Point [string range $line 12 end]
       }
       "Relative Humidity:*" {
          weather::object $name -set Humidity [string range $line 20 end]
       }
       "Pressure (altimeter):*" {
          weather::object $name -set Pressure [string range $line 22 end]
       }
       default {
         switch $count {
          0 {
            weather::object $name -set City $line
          }
          1 {
            weather::object $name -set Date $line
          }
          default { continue }
         }
       }
      }
      incr count
    }
    weather::object $name -icon
    return $name
}

# How to setup radar config:
# Go to www.weather.com, find your city/zipcode, click on radar screen. Large radar web page will be
# shown. If using  Mozilla, right click on radar image and choose 'View Image'. Image url will look like
# http://image.weather.com/web/radar/us_lax_closeradar_large_usen.jpg.
# Then go to Config and add Weather Radar LAX parameter.
proc weather::radar::schedule {} {
    
    foreach lax [ossweb::config weather:radar] {
      if { [catch {
        set data [ns_httpget http://image.weather.com/web/radar/us_${lax}_closeradar_plus_usen.jpg]
        if { $data != "" } {
          ossweb::file::save $lax.jpg $data -path weather
        }
      } errmsg] } {
        ns_log Error weather::radar::schedule: $lax: $errmsg
      }
    }
}

# Returns global level where all objects are allocated
proc weather::level {} {

    variable weather_level
    return $weather_level
}

proc weather::object { id args } {

    upvar #[weather::level] $id object

    set name [lindex $args 0]
    switch -exact -- $name {

     -create {
       if { [info exists object] } { unset object }
       array set object { obj:id ""
                          obj:type ""
                          Icon clear.gif
                          Date ""
                          Temperature ""
                          Wind_Cill ""
                          Heat_Index ""
                          Humidity ""
                          Dew_Point ""
                          Wind ""
                          Pressure ""
                          Sky ""
                          Weather ""
                          Visibility ""
                          Precipitation ""
                          Sunrise ""
                          Sunset ""
                          Moonrise ""
                          Moonset ""
                          City ""
                          State ""
                          Station ""
                          forecast:rowcount 0
                          forecast:date ""
                          forecast:area ""
                          forecast:zone ""
                          forecast:city ""
                          forecast:center ""
                          forecast:1:day ""
                          forecast:1:weather ""
                          forecast:1:icon ""
                          forecast:1:wind ""
                          forecast:1:temp ""
                          forecast:1:low ""
                          forecast:1:high "" }
       foreach { name value } [lrange $args 1 end] {
         set object($name) $value
       }
     }

     -dump {
       set result ""
       set sep [ossweb::nvl [lindex $args 1] "\n"]
       foreach name [lsort [array names object]] {
         append result $name = $object($name) $sep
       }
       return $result
     }

     -destroy {
       catch { unset object }
     }

     -set {
       foreach { name value } [lrange $args 1 end] {
         set object($name) $value
       }
     }

     -Set {
       foreach { name value } [lrange $args 1 end] {
         set object($name) ""
         set words ""
         ossweb::convert::plain_list value
         foreach word [split $value " /-"] {
           lappend words [string totitle $word]
         }
         append object($name) [join $words " "]
       }
     }

     -append {
       set name [lindex $args 1]
       if { $name == "" } { return }
       if { ![info exists object($name)] } { set object($name) "" }
       if { $object($name) != "" } {
         append object($name) " "
       }
       append object($name) [join [lrange $args 2 end] " "]
     }

     -Append {
       set name [lindex $args 1]
       if { $name == "" } { return }
       if { ![info exists object($name)] } { set object($name) "" }
       foreach value [lrange $args 2 end] {
         set words ""
         ossweb::convert::plain_list value
         foreach word [split $value " /-"] {
           lappend words [string totitle $word]
         }
         if { $object($name) != "" } {
           append object($name) " "
         }
         append object($name) [join $words " "]
       }
     }

     -icon {
       set date [string map { - {} } [lindex [split $object(Date) /] 0]]
       if { ![catch { set time [clock scan $date] }] } {
         if { [set time [ns_fmttime $time "%H%M"]] > 2100 || $time < 0700 } {
           set date Night
         }
       }
       set object(Icon) [weather::icon "$date $object(Weather) $object(Sky)"]
     }

     default {
       set default ""
       foreach { key val } [lrange $args 1 end] {
         switch -- $key {
          -config {
             set default [::ossweb::config $name $val]
          }
          -default {
             set default $val
          }
        }
       }
       return [ossweb::coalesce object($name) $default]
     }
    }
    return
}

# Reads latest weather records and returns a list of weather objects
proc weather::process { { weather_type "" } } {

    set objs ""
    ossweb::db::foreach sql:weather.read {
      if { ![info exists types($weather_type)] } {
        lappend objs [weather::[string tolower $weather_type]::parse $weather_id $weather_data]
        set types($weather_type) 1
      }
    }
    return $objs
}

# Returns corresponding icon for weather conditions
proc weather::icon { name } {

    if { [regexp {([0-9]+) Percent} $name d percent] && $percent >= 50 } {
      switch -regexp -- $name {
       "Snow" { return snow }
       "Thunder" { return tstorm }
       "Rain" { return rain }
       "Showers" { return showers }
      }
    }

    switch -regexp -- $name {
     "Mostly.*Cloudy" {
        if { [regexp -nocase Night $name] } { return ncloudy }
        return mcloudy
     }

     "Partly.*Cloudy" {
        if { [regexp -nocase Night $name] } { return ncloudy }
        return pcloudy
     }

     "Overcast" -
     "Cloudy" {
        if { [regexp -nocase Night $name] } { return ncloudy }
        return cloudy
     }

     "Fog" { return fog }
     "Mist" { return misty }
     "Snow.*Rain" { return snowshowers }
     "Snow.*Flurr" { return snowshowers }
     "Snow" { return snow }
     "Showers" { return showers }
     "Rain" { return rain }
     "Thunder" { return tstorm }
     "Haze" { return haze }
     "Sun" { return sunny }
     "Freeze.*Drizzle" { return freezingdrizzle }
     "Drizzle" { return drizzle }
     "Freeze.*Grain" { return freezinggrain }
     "Wind" { return wind }
     "Cold" { return cold }
     "Hot" { return hot }
     "Sleet" { return sleet }
     "Dust" { return dust }
     "Fair" { return fair }
     default {
        if { [regexp -nocase Night $name] } { return nclear }
        return clear
     }
    }
}

