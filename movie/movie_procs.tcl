# Author: Vlad Seryakov vlad@crystalballinc.com
# June 2004


namespace eval movie {
  variable version "Movie DB version 1.0"
  variable genre { Cartoon Movie Documentary Action News Talk Drama Comedy Sports
                   Western Travel Soap Mistery History Sci-Fi Music Musical Adult Thriller
                   Entertainment Children Romance Fantasy Crime Horror Sitcom
                   Adventure War Concert Teens }

  namespace eval export {}
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
    namespace eval prefs {}
  }
}

ossweb::register_init movie::init

proc ossweb::schedule::hourly::movie { args } {

    movie::export
}
					  
proc movie::init {} {

    ossweb::file::register_download_proc movie ::movie::download
    ossweb::file::register_download_proc cover ::movie::download
    # Setup home directory
    env set HOME [ossweb::util::gethome]
    # X11 display for local playback
    env set DISPLAY ":0.0"
    ns_log Notice movie: initialized
}

# Returns 1 if current user has access to the movie
proc movie::access { movie_title movie_genre } {

    switch -regexp -- $movie_genre {
     Adult {
       if { ![ossweb::conn::check_acl -acl "Movie.Access.By.Genre.Adult"] } { return 1 }
       return 0
     }
    }
    return 1
}

# File download handler, used by ossweb::file::download for file download verification
proc movie::download { params } {

    # Show movie cover without restrictions
    set file_name [file tail [ns_set get $params file:name]]
    if { [regexp {\.(gif|jpg|png)$} $file_name] } {
      if { [ossweb::file::exists $file_name -path cover] } {
        ns_set update $params file:mode direct
        ns_set update $params file:name [ossweb::file::getname $file_name -path cover]
        return file_return
      }
      return file_notfound
    }
    # Restrict movie files
    set movie_id [ns_set get $params movie_id]
    if { [ossweb::datatype::integer $movie_id] != "" } {
      return file_notfound
    }
    # Allow from local network only, otherwise should be logged in
    if { ![ossweb::conn::localnetwork] && [ossweb::conn session_id] == "" } {
      ns_log Notice movie:download: invalid session [ossweb::conn session_id], not local network [ossweb::conn peeraddr]
      return file_accessdenied
    }
    # Update watch counter/time
    set watch_time NOW()
    set watch_count COALESCE(watch_count,0)+1
    ossweb::db::exec sql:movie.update.watch_count
    if { ![ossweb::db::rowcount] } {
      return file_notfound
    }
    if { [ossweb::db::multivalue sql:movie.file.read] } {
      return file_notfound
    }
    ns_set update $params file:mode direct
    ns_set update $params file:name $file_path
    return file_return
}

# Link to movie from the toolbar
proc ossweb::html::toolbar::movie {} {

    if { [ossweb::conn session_id] == "" } { return }
    if { [ossweb::conn::check_acl -acl *.movie.movie.view.*] } { return }
    return [ossweb::html::link -image film.gif -hspace 6 -status Movies -alt Movies -app_name movie movie]
}

# Preferences for mvoies
proc ossweb::control::prefs::movie { type args } {

    switch -- $type {
     columns {
       return { movie_mstream int "" }
     }

     form {
       if { [ossweb::conn::check_acl -acl *.movie.movie.view.*] } { return }
       ossweb::form form_prefs -section "Movies"
       ossweb::widget form_prefs.movie_mstream -type checkbox \
            -label "Use MStream Mozilla Extension: (<A HREF=/js/mstream.xpi>Install</A> | <A HREF=\"javascript:;\" onClick=\"window.open('[ossweb::html::url help app_name main page_name prefs cmd_name mstream]','Help','location=0,menubar=0,width=600,height=600')\">Help</A>)" \
            -optional \
            -horizontal \
            -value [ossweb::conn movie_mstream] \
            -options { { Yes t } { No f} }
     }

     save {
       ossweb::admin::prefs set -obj_id [ossweb::conn user_id] \
            movie_mstream [ns_querygetall movie_mstream]
     }
    }
}

# Plays video on local X11 display
proc movie::play { movie_id { file "" } } {

    if { $movie_id == "" } { return }
    # Play all files if not specified
    if { $file == "" } {
      ossweb::db::foreach sql:movie.file.list {
        lappend file $file_name
      }
    }
    if { $file == "" } { return }
    # Update watch counter/time
    set watch_time NOW()
    set watch_count COALESCE(watch_count,0)+1
    ossweb::db::exec sql:movie.update.watch_count
    if { ![ossweb::db::rowcount] } { return }
    # Setup environment
    foreach file $file {
      append files [lindex [movie::path $file 0 1] 0] " "
    }
    set cmd [string map [list @file@ $files] [ossweb::config movie:player]]
    # Run media player
    ns_log Notice movie::play: $movie_id: $cmd
    if { $cmd != "" && [catch { exec sh -c "$cmd >> [ns_info log] 2>&1 &" } errmsg] } {
      ns_log Notice movie::play: $file: $errmsg
    }
}

# Retrieves codec info from movie file, mplayer specific
proc movie::info { file } {

    set info ""
    set file [lindex [movie::path $file 0 1] 0]
    set cmd [string map [list @file@ $file] [ossweb::config movie:informer]]
    catch { set result [exec sh -c "$cmd"] } result
    if { [regexp {VIDEO:([^\n]+)} $result d a] } { append info VIDEO: $a " " }
    if { [regexp {AC3:([^\n]+)} $result d a] } { append info AC3: $a " " }
    if { [regexp {AUDIO:([^\n]+)} $result d a] } { append info AUDIO: $a }
    return [string trim $info]
}

proc movie::image { movie_id } {

    foreach img "$movie_id.jpg $movie_id.gif $movie_id.png [ossweb::config movie:image]" {
      if { [ossweb::file::exists $img -path cover] } { return images/$img }
    }
    return
}

# Resolve movie full path
proc movie::path { file_name { force 0 } { split 0} } {

    set hash ""
    if { [set idx [string first "#" $file_name]] > 0 } {
      set hash [string range $file_name $idx  end]
      set file_name [string range $file_name 0 [incr idx -1]]
    }
    if { [string index $file_name 0] == "/" } {
      if { !$force } {
        if { $split } {
              return [list $file_name $hash]
            }
        return $file_name$hash
      }
      set file_name [file tail $file_name]
    }
    foreach dir [ossweb::config movie:dirs] {
      set files [ossweb::cache run movie:files:$dir "ossweb::file_list $dir .*" 3600]
      foreach path $files {
        if { [file tail $path] == $file_name } {
          if { $split } {
            return [list $path $hash]
          }
          return $path$hash
        }
      }
    }
    if { $split } {
      return [list $file_name $hash]
    }
    return $file_name$hash
}

# Sort and returns movie files in the order they will be played
proc movie::sort_files { files { key "" } } {

    set part ""
    set parts ""
    set pcount 0
    set mfiles ""

    # Save full paths
    foreach file $files {
      set fname [file tail $file]
      set mpaths($fname) $file
    }
    # Sort according to sequence or number
    foreach file [lsort [array names mpaths]] {
      if { (![regexp -nocase {\#pos\:([0-9]+)} $file d num] &&
            ![regexp -nocase {([0-9]+)\.[^0-9]+$} $file d num]) ||
           [string trimleft $num 0] == "" } {
        set num 0
      }
      lappend parts [list $file [ossweb::trim0 $num] [incr pcount]]
    }
    # Build final list with full paths
    foreach file [lsort -integer -index 1 $parts] {
      if { $key != "" && $key != [lindex $file 2] } { continue }
      lappend mfiles $mpaths([lindex $file 0])
    }
    return $mfiles
}

# Refresh file paths to reflect actual locations
proc movie::update_files { { movie_id "" } } {

    if { $movie_id == "" } {
       set list [ossweb::db::multilist sql:movie.files -array t]
    } else {
       set list [ossweb::db::multilist sql:movie.file.list -array t]
    }

    foreach rec $list {
      foreach { key val } $rec { set $key $val }
      foreach { file_path file_params } [movie::path $file_name 1 1] {}
      set file_name [file tail $file_path]
      if { [catch { set file_size [file size [lindex [split $file_path "#"] 0]] } errmsg] } {
        ns_log Error movie::update_files: $file_name: $errmsg
        continue
      }
      ossweb::db::exec sql:movie.file.update
    }
}

# Look for non-existent files
proc movie::check_files {} {

    set result ""
    ossweb::db::foreach sql:movie.files {
      set file_path [lindex [movie::path $file_name 1 1] 0]
      if { ![file exists $file_path] } {
        lappend result $file_name $disk_id
      }
    }
    return $result
}

# Export movie list into text file
proc movie::export { args } {

    ns_parseargs { {-dbpool ""} {-file movies.txt} {-path ""} } $args

    set count 0
    set xml ""
    set xml2 ""
    set fav ""
    set fav2 ""

    if { $dbpool != "" } {
      ossweb::db::handle $dbpool
    }

    if { $path == "" } {
      set path [ossweb::file::getname "" -path movie]
    }

    if { [string index $file 0] != "/" } {
      set file $path/$file
    }

    ossweb::db::foreach sql:movie.export {
      set descr ""
      set plot ""
      set crew ""
      incr count

      if { $file_time > $update_time } {
           set update_time $file_time
      }

      foreach line [split $movie_descr "\n"] {
        if { [set line [string trim $line { \r\t}]] == "" } {
          continue
        }
        # Parse actors
        if { [regexp {([^.]+)\.\.\.\.(.+)} $line d a b] } {
          set line [string trim "[string trim $a] [string trim $b]"]
          lappend crew [string trim $a]
        }
        # Parse plot
        if { $plot == "" } {
          if { [regexp {Plot Outline:(.+)$} $line d plot] ||
               [regexp {Plot Summary:(.+)$} $line d plot] ||
               [regexp {Tagline:(.+)$} $descr d plot] ||
               [regexp {User Comments:(.+)$} $descr d plot] } {
          }
        }
        append descr $line "\n"
      }

      set files ""
      set files2 ""
      set disks ""
      foreach { file_name file_info disk_id } $movie_files {
        lappend disks $disk_id
        lappend files [movie::path $file_name]
        lappend files2 [ossweb::conn::hostname http://][ossweb::file::url movie [file tail $file_name] movie_id $movie_id]
      }
      if { $files == "" } { continue }
      set files [movie::sort_files $files]
      append descr "DISKS: [join [lsort -unique $disks] ,]\n"
      set descr [string map { \n { } \r {} \t {} | ! } $descr]

      set title [string map { < &lt; > &gt; & &amp; " &quot; " &quote; \n {} \r {} \t {} } $movie_title]
      set descr [string map { < &lt; > &gt; & &amp; " &quot; " &quote; \n {} \r {} \t {} } $descr]
      set crew [string map { < &lt; > &gt; & &amp; " &quot; " &quote; \n {} \r {} \t {} } [join $crew ,]]

      set tmp ""
      foreach u [split $title ""] { scan $u %c t; append tmp [expr {$t>127? "&#$t;" : $u}] }
      set title $tmp
      set tmp ""
      foreach u [split $descr ""] { scan $u %c t; append tmp [expr {$t>127? "&#$t;" : $u}] }
      set descr $tmp
      set tmp ""
      foreach u [split $crew ""] { scan $u %c t; append tmp [expr {$t>127? "&#$t;" : $u}] }
      set crew $tmp

      set category ""
      set movie_genre [string map {"{" {} "}" {} Movie {}} $movie_genre]
      switch -nocase -regexp -- $movie_genre {
       war -
       action -
       thriller -
       adventure {
          set category Action  
       }
       comedy {
          set category Comedy
       }
       drama {
          set category Drama
       }
      } 

      set rec ""
      set icon ""
      set icon2 ""
      append rec " <id>$movie_id</id>\n"
      append rec " <type>movie</type>\n"
      append rec " <title>$title</title>\n"
      append rec " <date>[ns_fmttime $update_time "%Y-%m-%d %H:%M:%S"]</date>\n"
      append rec " <category>$category</category>\n"
      append rec " <genre1>[lindex $movie_genre 0]</genre1>\n"
      append rec " <genre2>[lindex $movie_genre 1]</genre2>\n"
      append rec " <genre3>[lindex $movie_genre 2]</genre3>\n"
      append rec " <released>$movie_year</released>\n"
      append rec " <lang>$movie_lang</lang>\n"
      append rec " <crew>$crew</crew>\n"
      append rec " <descr>$descr</descr>\n"
      append rec " <community>1</community>\n"
      append rec " <recommend>1</recommend>\n"
      append rec " <program>$movie_id</program>\n"
    
      foreach img "$movie_id.jpg $movie_id.gif $movie_id.png" {
       if { [ossweb::file::exists $img -path cover] } { 
          set icon " <icon>/public/icons/$img</icon>\n"
          set icon2 " <icon>[ossweb::conn::hostname http://][ossweb::file::url movie [file tail $img] movie_id $movie_id]</icon>\n"
       }
      }

      if { $movie_age <= 9 } {
         set rating 4
      } elseif { $movie_age < 18 } {
         set rating 3
      } else {
         set rating 0
      }

      append rec " <rating>$rating</rating>\n"

      set files " <file>[join $files |]</file>\n"
      append xml "<movie>\n$rec$files$icon</movie>\n"

      set files2 " <file>[join $files2 |]</file>\n"
      append xml2 "<movie>\n$rec$files2$icon2</movie>\n"

      if { [ns_time] - $update_time <= 30*86400 } {
        append fav "<favorite>\n$rec$files$icon</favorite>\n"
        append fav2 "<favorite>\n$rec$files2$icon2</favorite>\n"
      }
    }

    # Clips favorites
    foreach clip [glob -nocomplain /public/clips/*.avi] {
      if { [ns_time] - [file mtime $clip] <= 30*86400 } {
         append fav "<favorite>\n"
         append fav " <id>$clip</id>\n"
         append fav " <type>file</type>\n"
         append fav " <title>[file rootname [file tail $clip]]</title>\n"
         append fav " <file>$clip</file>\n"
         append fav " <icon>[file rootname $clip].png</icon>\n"
         append fav " <rating>4</rating>\n"
         append fav " <date>[ns_fmttime [file mtime $clip] "%Y-%m-%d %H:%M:%S"]</date>\n"
         append fav " <community>1</community>\n"
         append fav " <recommend>1</recommend>\n"
         append fav "</favorite>\n"
      }
    }
    
    # Photos favorites
    foreach dir [glob -nocomplain -type d /public/images/*] {
      if { [ns_time] - [file mtime $dir] <= 30*86400 } {
         append fav "<favorite>\n"
         append fav " <id>$dir</id>\n"
         append fav " <type>album</type>\n"
         append fav " <title>[file rootname [file tail $dir]]</title>\n"
         append fav " <file>$dir</file>\n"
         append fav " <rating>4</rating>\n"
         append fav " <date>[ns_fmttime [file mtime $dir] "%Y-%m-%d %H:%M:%S"]</date>\n"
         append fav " <community>1</community>\n"
         append fav " <recommend>1</recommend>\n"
         append fav "</favorite>\n"
      }
    }

    # Movie favorites
    set file [file dirname $file]/1.linux.xml
    set fav "<favorites>\n$fav</favorites>\n"
    if { ![file exists $file] || [file size $file] != [string length $fav] } {
       ossweb::write_file $file $fav
    }

    set file [file dirname $file]/movie.linux.xml
    set xml "<movies>\n$xml</movies>\n"
    if { ![file exists $file] || [file size $file] != [string length $xml] } {
       ossweb::write_file $file $xml
    }

    # Mac streamong version
    set file [file dirname $file]/1.macosx.xml
    set fav2 "<favorites>\n$fav2</favorites>\n"
    if { ![file exists $file] || [file size $file] != [string length $fav2] } {
       ossweb::write_file $file $fav2
    }
    set file [file dirname $file]/movie.macosx.xml
    set xml2 "<movies>\n$xml2</movies>\n"
    if { ![file exists $file] || [file size $file] != [string length $xml2] } {
       ossweb::write_file $file $xml2
    }

    set urls ""
    set count 0

    # Genre keywords
    foreach url { 70s 80s 90s Alternative Blues Easy+Listening Electronic 
                  Jazz Pop Rap Reggae Rock Folk World+Folk Contemporary+Folk 
                  Latin Latin+Dance Slasa Latin+Pop Tango Funk } {
      append urls "http://www.shoutcast.com/radio/$url "
    }
    # Search keywords
    foreach url { Zumba } {
      append urls "http://www.shoutcast.com/Internet-Radio/$url "
    }
    catch { eval exec wget -O /tmp/shoutcast.html $urls } errmsg

    set wd [open $path/_radio.xml w]
    puts $wd "<radios>"
    set fd [open /tmp/shoutcast.html]
    foreach line [split [read $fd] "\n"] {
      set line [string trim $line]
      if { [string match {<a href=*tunein*} $line] } {
        set url [string range $line 9 [string first {"} $line 10]-1]
        set i [string first title= $line]
        set title [string range $line $i+7 [string first {"} $line $i+8]-1]
        set i [string first id= $url]
        set id [string range $url $i+3 end]
        puts $wd "<radio>"
        puts $wd "<id>$id</id>"
        puts $wd "<type>shoutcast</type>"
        puts $wd "<rating>4</rating>"
        puts $wd "<file>$url</file>"
        puts $wd "<channelname>shoutcast</channelname>"
        puts $wd "<title>[string map { {#} {} {)))} {} {(((} {} < &lt; > &gt; & &amp; " &quot; " &quote; \n {} \r {} \t {} } $title]</title>"
      } elseif { [string match {<div>Tags:*} $line] } {
        set g 1
        set title ""
        while {$g <= 3} {
           set i [string first href= $line]
           if { $i < 0 } {
              break
           }
           set genre [string totitle [string range $line $i+13 [string first {'} $line $i+7]-1]]
           set line [string range $line $i+8 end]
           set genre [string map { < &lt; > &gt; & &amp; " &quot; " &quote; \n {} \r {} \t {} } $genre]
           if { ![regexp -nocase {top} $genre] } {
              puts $wd "<genre$g>$genre</genre$g>"
              if { $g == 1 } {
                 puts $wd "<category>$genre</category>"
              }
              incr g
           }
        }
        puts $wd "</radio>"
        incr count
      }
    }
    puts $wd "</radios>"

    file rename -force $path/_radio.xml $path/radio.xml
}

# Generate movie icons as snapshot frame
proc movie::icons {} {

    set movies ""
    ossweb::db::foreach sql:movie.search1 {
      if { ![ossweb::file::exists $movie_id.gif -path cover] &&
           ![ossweb::file::exists $movie_id.jpg -path cover] } {
        lappend movies $movie_id
      }
    }
    foreach id $movies {
      if { [set file [ossweb::db::value sql:movie.file.names]] == "" } { continue }
      set icon [ossweb::file::getname $id.jpg -path cober]
      ossweb::util::snapshot $file $icon -pos 120
    }
}

# Retrieves movie info from www.imdb.com
proc movie::imdb { id args } {

    ns_parseargs { {-movie_id ""} {-search ""} {-year "" } } $args

    # IMDB id is here, retrieve the movie info
    if { [catch { set data [ns_httpget http://us.imdb.com/title/tt$id] } errmsg] } {
      ns_log Error movie::imdb:: $errmsg
      return
    }
    # Movie icon
    if { [set sindex [string first {<a name="poster"} $data]] > 0 &&
         [set eindex [string first "</a>" $data $sindex]] > 0 &&
         [regexp {src="([^"]+)} [string range $data $sindex $eindex] d icon_url] } {
      ns_log Notice imdb: $id: found image $icon_url
      if { $movie_id != "" } {
        set icon_file [ossweb::file::getname $movie_id[file ext $icon_url] -path cover]
      } else {
        set icon_file /tmp/$id[file ext $icon_url]
      }
      if { [catch { ossweb::write_file $icon_file [ns_httpget $icon_url] } errmsg] } {
        ns_log Error movie:imdb: $errmsg
      }
    }
    set data [string map { {<a href="/name/} "\n <a href=" } $data] ;# convert names "
    set data [string trim [ns_striphtml $data]]
    set data [string map { .... : ":\n" : ": \n" : {(more)} {} } $data]
    # Movie info, cut out the beginning and the end with non-related text
    if { [set sindex [string first "Directed by" $data]] == -1 &&
         [set sindex [string first "IMDbPro Professional Details:" $data]] == -1 &&
         [set sindex [string first "Genre:" $data]] == -1 &&
         [set sindex [string first "Tagline:" $data]] == -1 &&
         [set sindex [string first "Plot Outline:" $data]] == -1 &&
         [set sindex [string first "Plot Summary:" $data]] == -1 } {
      return
    }
    if { [set eindex [string first "Memorabilia" $data $sindex]] == -1 &&
         [set eindex [string first "Awards:" $data $sindex]] == -1 &&
         [set eindex [string first "Language:" $data $sindex]] == -1 &&
         [set eindex [string first "Certification:" $data $sindex]] == -1 &&
         [set eindex [string first "Color:" $data $sindex]] == -1 &&
         [set eindex [string first "Sound Mix:" $data $sindex]] == -1 &&
         [set eindex [string first "Country:" $data $sindex]] == -1 } {
      return
    }
    set data2 [string range $data $sindex [incr eindex -1]]
    # Movie year
    if { [regexp {\((20[0-9][0-9])\)} $data d year] || [regexp {\((19[0-9][0-9])\)} $data d year] } {
      append data2 "\nYear: $year"
    }
    set result ""
    set prev_line ""
    foreach line [split $data2 "\n"] {
      if { [set line [string trim $line]] == "" } { continue }
      # Director
      if { $prev_line == "Directed by" } {
        set line "Directed by: $line"
      }
      if { [regexp {^[^\:]+\:.+} $line] } {
        switch -glob -- $line {
         "Cast overview*" {
         }
        }
        append result $line "\n"
      }
      set prev_line $line
    }
    if { $result == "" } { return }

    if { $movie_id != "" } {
      if { [ossweb::db::multivalue sql:movie.read] } { return $result }
      if { [regexp {Genre:([^\n]+)\n} $result d glist] } {
        foreach gname [split $glist "/()"] {
          set gname [string trim $gname]
          if { [set gname [string trim $gname]] == "" } { continue }
          if { [lsearch -exact $movie_genre $gname] == -1 } { lappend movie_genre $gname }
        }
        if { [lsearch -exact $movie_genre Animation] != -1 } {
          lappend movie_genre Cartoon
        }
        if { [lsearch -exact $movie_genre Family] != -1 } {
          lappend movie_genre Children Teens
        }
      }
      if { [lsearch -exact $movie_genre Movie] == -1 &&
           [lsearch -exact $movie_genre Cartoon] == -1 } {
        lappend movie_genre Movie
      }
      if { $movie_year == "" } {
        regexp {Year: ([0-9]+)} $result d movie_year
      }
      ossweb::db::exec sql:movie.update
    }
    return $result
}

# Hourly scheduler
proc ossweb::schedule::hourly::movie {} {

    movie::export
}

# Full text search provider for movie records
proc ossweb::tsearch::movie { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type movie
       set tsearch_id movie_id::TEXT
       set tsearch_table movies
       set tsearch_date update_time
       set tsearch_text "movie_title||' '||COALESCE(movie_descr,'')||' '||COALESCE(movie_genre,'')||' '||movie_files(movie_id)"
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     url {
       # Returns full url to the record
       set data [lindex $args 1]
       return [ossweb::html::url movie.movie cmd edit movie_id [lindex $args 0]]
     }
    }
}
