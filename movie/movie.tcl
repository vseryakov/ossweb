# Author: Vlad Seryakov vlad@crystalballinc.com
# June 2004

ossweb::conn::callback disks_report {} {

     set total_size 0.0
     set disk_max [ossweb::db::value sql:movie.disk.max]
     ossweb::multirow create disks disk_id file_name size
     ossweb::db::foreach sql:movie.disk.list {
       if { $_disk_id == "" } { set _disk_id -1 }
       if { $_file_size == "" } { set _file_size 0 }
       if { $disk_id != "" } {
         if { $disk_id != $_disk_id } { continue }
         set total_size [expr $total_size+$_file_size]
         ossweb::multirow append disks $disk_id $_file_path $_file_size
       } else {
         set disk_size [ossweb::coalesce disk_list($_disk_id) 0.0]
         set total_size [expr $total_size+$_file_size]
         set disk_list($_disk_id) [expr $disk_size+$_file_size]
       }
     } -prefix _
     foreach id [lsort -integer [array names disk_list]] {
       set url [ossweb::lookup::link -text $id cmd disks disk_id $id]
       ossweb::multirow append disks $url "" "[format "%.0f" $disk_list($id)] ([ossweb::util::size $disk_list($id)])"
     }
     ossweb::multirow append disks "<B>TOTAL</B>" "" "[format "%.0f" $total_size] ([ossweb::util::size $total_size])"
}

# Sort and returns movie files in the order they will be played
proc movie_files { files { key "" } } {

    set part ""
    set parts ""
    set mfiles ""
    set sfiles ""
    foreach file $files {
      set mpaths([file tail $file]) $file
      lappend sfiles [file tail $file]
    }
    foreach file [lsort $sfiles] {
      if { ![regexp -nocase {([0-9]+)\..+$} $file d num] ||
           [string trimleft $num 0] == "" } { set num 0 }
      if { $key != "" && $key == $num } { set part $num }
      lappend parts [list $file [ossweb::trim0 $num]]
    }
    foreach file [lsort -integer -index 1 $parts] {
      if { $part != "" && $part != [lindex $file 1] } { continue }
      lappend mfiles $mpaths([lindex $file 0])
    }
    return $mfiles
}

proc disk_size { disk_id } {

    set disk_size 0.0
    ossweb::db::foreach sql:movie.disk.files {
      set disk_size [expr $disk_size+$file_size]
    }
    return $disk_size
}

ossweb::conn::callback imdb_parse {} {

   if { [regexp {Genre:([^\n]+)\n} $movie_descr d glist] } {
     foreach gname [split $glist "/()"] {
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
     regexp {Year: ([0-9]+)} $movie_descr d movie_year
   }
}

ossweb::conn::callback movie_imdb {} {

    if { [ossweb::db::multivalue sql:movie.read] } {
      error "OSSWEB: Invalid movie record"
    }
    if { $imdb_id == "" || [set movie_descr [movie::imdb $imdb_id -movie_id $movie_id]] == "" } { return }
    imdb_parse
    if { [ossweb::db::exec sql:movie.update] } {
      error "OSSWEB: Unable to update movie"
    }
    ossweb::conn::set_msg "Movie has been updated"
}

ossweb::conn::callback movie_add {} {

    ossweb::db::begin
    # Verify size of DVD disk
    set dvd_size [ossweb::config movie:disk:size 4700000000]

    # Split file name and params
    set file_name [string trim $file_name]
    ossweb::cache flush movie:files:*
    foreach { file_path file_params } [movie::path $file_name 1 1] {}
    set file_name [file tail $file_path]

    # Delete old file if exists
    if { [ossweb::db::exec sql:movie.file.delete] } {
      error "OSSWEB: Unable to delete movie file"
    }
    if { ![file exists $file_path] } {
      ossweb::conn::set_msg "Warning: File $file_name not found"
    } else {
      set file_size [file size $file_path]
      if { $disk_id > 0 && $file_size > 0 } {
        set disk_size [expr [disk_size $disk_id]+$file_size]
        if { $disk_size > $dvd_size } {
          error "OSSWEB: Disk size exceeds DVD size limit of $dvd_size bytes"
        }
      }
      set file_info [movie::info $file_name]
    }
    if { [ossweb::db::exec sql:movie.file.update] } {
      error "OSSWEB: Unable to update movie file"
    }
    if { [ossweb::db::rowcount] == 0 } {
      if { [ossweb::db::exec sql:movie.file.create] } {
        error "OSSWEB: Unable to add movie file"
      }
    }
    ossweb::db::commit
    ossweb::conn::set_msg "Movie file $file_path has been added"
}

ossweb::conn::callback movie_remove {} {

    if { [ossweb::db::exec sql:movie.file.delete] } {
      error "OSSWEB: Unable to delete movie file"
    }
    ossweb::conn::set_msg "Movie file has been deleted"
    # Flush cached search results
    ossweb::sql::multipage movies -flush t
    set force t
}

ossweb::conn::callback movie_update {} {

    if { [lsearch -exact $movie_genre Movie] == -1 &&
         [lsearch -exact $movie_genre Cartoon] == -1 } {
      lappend movie_genre Movie
    }
    if { $movie_id != "" } {
      if { [ossweb::db::exec sql:movie.update] } {
        error "OSSWEB: Unable to update movie"
      }
      ossweb::conn::set_msg "Movie has been updated"
    } else {
      if { [ossweb::db::exec sql:movie.create] } {
        error "OSSWEB: Unable to create movie"
      }
      set movie_id [ossweb::db::currval movie]
      ossweb::conn::set_msg -color black "Movie has been created"
    }
    # Update with IMDB info
    if { $movie_descr == "" &&
         $imdb_id != "" &&
         [set movie_descr [movie::imdb $imdb_id -movie_id $movie_id]] != "" } {
      imdb_parse
      if { [lsearch -exact $movie_genre Movie] != -1 &&
           [lsearch -exact $movie_genre Cartoon] != -1 } {
        set movie_genre [string map {Movie {}} $movie_genre]
      }
      if { [ossweb::db::exec sql:movie.update] } {
        error "OSSWEB: Unable to update movie"
      }
    }
    if { $image_name != "" } {
      set ext [string map {.jpeg .jpg} [string tolower [file extension $image_name]]]
      set imgname $movie_id$ext
      ns_log notice $imgname: [ossweb::file::upload image_name -path cover -newname $imgname]
    }
    if { ${ossweb:cmd} == "update&exit" } {
      ossweb::conn::next -cmd_name view
    }
}

ossweb::conn::callback movie_delete {} {

    if { [ossweb::db::exec sql:movie.delete] } {
      error "OSSWEB: Unable to delete movie"
    }
    set movie_id ""
    ossweb::conn::set_msg -color black "Movie has been delete"
}

ossweb::conn::callback movie_edit {} {

    if { $movie_id != "" } {
      if { [ossweb::db::multivalue sql:movie.read] } {
        error "OSSWEB: Invalid movie record"
      }
      # Genre restrictions
      switch -- [ossweb::conn user_type] {
       children {
         if { $movie_age > 8 } {
           error "OSSWEB: Access to the movie denied: $genre"
         }
       }

       teen {
         if { $movie_age > 15 } {
           error "OSSWEB: Access to the movie denied: $genre"
         }
       }
      }
      
      # Run player in the background
      if { ${ossweb:ctx} == "play" && $allow == 0 } {
        movie::play $movie_id $file_name
      }
      
      # Info parsing
      if { ${ossweb:cmd} == "info" } {
        set movie_info ""
        foreach line [split $movie_descr "\n"] {
          switch -regexp -- $line {
           ^Also -
           ^Directed -
           ^Plot -
           Country: -
           Outline: -
           Runtime: {
             append movie_info $line "<BR>"
           }
          }
        }
      }
      # Retrieve list of files
      set ipaddr [ns_conn peeraddr]
      set host [ns_addrbyhost [ns_info hostname]]
      set use_mstream [ossweb::conn movie_mstream]
      set n 0
      ossweb::db::multirow files sql:movie.file.list -eval {
        set row(edit) ""
        set row(size) 0
        if { $row(disk_id) == "" } { set row(disk_id) -1 }
        if { $allow == 0 } {
          set row(disk_id) [ossweb::html::link -text $row(disk_id) -window Disk -winopts $winopts cmd disks disk_id $row(disk_id) lookup:mode 2]
        }
        if { [movie::access $movie_title $movie_genre] } {
          set row(size) [expr abs([ossweb::nvl $row(file_size) 0]/1024/1024)]
          append row(edit) [ossweb::file::link movie $row(file_name) -text Download movie_id $movie_id] " "

          if { $ipaddr == "127.0.0.1" || $ipaddr == $host } {
            append row(edit) [ossweb::html::link -text Play cmd edit.play movie_id $movie_id page $page file_name $row(file_name)] " "
          } elseif { $use_mstream == "t" } {
            append row(edit) [ossweb::file::link movie [file tail $row(file_name)] -text Stream -alt Stream -proto mstream:// -host t movie_id $movie_id] " "
          }
          append row(edit) [ossweb::html::link -image trash.gif -confirm "confirm('Delete File?')" cmd remove movie_id $movie_id file_name $row(file_name) page $page]
        }
      }

      # Disable remote access
      if { $noremote_access && ![ossweb::conn::localnetwork] } {
        set files:rwocount 0
      }

      if { [set image [movie::image $movie_id]] != "" } {
        ossweb::widget form_movie.movie_descr -info "<A HREF=$image TARGET=IMG><IMG SRC=$image WIDTH=96 HEIGHT=140></A>"
      }
      if { $imdb_id != "" } {
        append imdb_info [ossweb::html::link -text { [IMDb Page]} -window IMDB -winopts $winopts -url http://us.imdb.com/title/tt$imdb_id/]
        append imdb_info [ossweb::html::link -text { [IMDb Refresh]} cmd imdb movie_id $movie_id page $page]
        ossweb::widget form_movie.imdb_id -info $imdb_info
      }
    }
    ossweb::widget form_file.movie_id -value $movie_id
    ossweb::form form_movie set_values
}

ossweb::conn::callback movie_list {} {

    switch ${ossweb:cmd} {
     search {
       set force t
       ossweb::conn::set_property MOVIE:FILTER "" -forms form_movie -global t -cache t
     }

     error {
       ossweb::form form_movie set_values
       return
     }

     export {
       set force t
       movie::export
       ossweb::conn::get_property MOVIE:FILTER -skip page -columns t -global t -cache t
     }

     default {
       ossweb::conn::get_property MOVIE:FILTER -skip page -columns t -global t -cache t
     }
    }
    set ipaddr [ns_conn peeraddr]
    set host [ns_addrbyhost [ns_info hostname]]
    set use_mstream [ossweb::conn movie_mstream]

    # Genre restrictions
    switch -- [ossweb::conn user_type] {
     children {
        set movie_age 9
     }

     teen {
        set movie_age 15
     }
    }
    
    # Build regexp
    if { $movie_genre != "" } {
      set genres ""
      foreach g $movie_genre {
        lappend genres "movie_genre ~* [ossweb::sql::quote $g]"
      }
      set movie_genre [join $genres " AND "]
    }
    
    ossweb::db::multipage movies \
         sql:movie.search1 \
         sql:movie.search2 \
         -force $force \
         -page $page \
         -debug t \
         -eval {
      foreach n { edit image } { set row($n) "" }
      if { ![movie::access $row(movie_title) $row(movie_genre)] } {
        continue
      }
      set row(movie_title) [ossweb::html::link -text $row(movie_title) cmd edit movie_id $row(movie_id) page $page]
      set n 1
      foreach file [movie_files $row(movie_files)] {
        if { $use_mstream == "t" } {
          append row(edit) [ossweb::file::link movie [file tail $file] -text $n -alt Play -proto mstream:// -host t movie_id $row(movie_id)] " "
        } else {
          append row(edit) [ossweb::file::link movie [file tail $file] -text $n -alt Download movie_id $row(movie_id)] " "
        }
        incr n
      }
      # Disable remote access
      if { $noremote_access && ![ossweb::conn::localnetwork] } {
        set row(edit) ""
      }
      if { $ipaddr == "127.0.0.1" || $ipaddr == $host && $row(edit) != "" } {
        append row(edit) [ossweb::html::link -text Play cmd edit.play movie_id $row(movie_id) page $page]
      }
      set row(image) [movie::image $row(movie_id)]
      if { [set index [string first "Plot Outline:" $row(movie_descr)]] != -1 ||
           [set index [string first "Plot Summary:" $row(movie_descr)]] != -1 ||
           [set index [string first "Tagline:" $row(movie_descr)]] != -1 ||
           [set index [string first "Also Known As:" $row(movie_descr)]] != -1 } {
        set row(movie_descr) [string range $row(movie_descr) [incr index 14] end]]
      }
      set row(movie_descr) [string range $row(movie_descr) 0 80]
      if { [set index [string last "." $row(movie_descr)]] != -1 } {
        set row(movie_descr) [string range $row(movie_descr) 0 $index]
      }
      if { $row(movie_age) != "" } {
        append row(movie_genre) " Age/$row(movie_age)"
      }
    }
    set movie_genre [split $movie_genre |]
    ossweb::form form_movie set_values
}

ossweb::conn::callback create_form_movie {} {

    variable ::movie::genre
    foreach g [lsort $genre] { lappend genres [list $g $g] }

    switch -- ${ossweb:cmd} {
     edit -
     update {
       ossweb::form form_movie -title "Movie Details"

       ossweb::widget form_movie.page -type hidden -optional

       ossweb::widget form_movie.movie_id -type hidden -optional

       ossweb::widget form_movie.movie_title -type text -label Title \
            -info "[ossweb::html::link -text { [IMDb Search]} -window IMDB -winopts "$winopts,location=1" -url {http://www.imdb.com/find?tt=on;nm=on;mx=20;q='+document.form_movie.movie_title.value+'}]
                   [ossweb::html::link -text { [Image Search]} -window IMDB -winopts "$winopts,location=1" -url {http://images.google.com/images?q=movie+'+document.form_movie.movie_title.value+'}]"

       ossweb::widget form_movie.movie_descr -type textarea -label Description \
            -html { rows 6 cols 60 wrap off } \
            -resize \
            -optional

       ossweb::widget form_movie.movie_age -type numberselect -label "Viewer's Age" \
            -optional \
            -empty -- \
            -start 0 \
            -end 21

       ossweb::widget form_movie.movie_genre -type multiselect -label Genre \
            -html { size 6 } \
            -optional \
            -options $genres \
            -resize

       ossweb::widget form_movie.movie_lang -type select -label Language \
            -optional \
            -options { { English English }
                       { Russian Russian }
                       { French French }
                       { Thai Thai }
                       { Chinese Chinese }
                       { Japanese Japanese }
                     }

       ossweb::widget form_movie.movie_year -type text -label Year \
            -optional \
            -datatype integer \
            -validate { {$value == "" || ($value >= 1900 && $value <= 2010)} "Year must be between 1900 and 2010" } \
            -html { size 4 maxlength 4 }

       ossweb::widget form_movie.imdb_id -type text -label "IMDB Id" \
            -html { size 10 } \
            -datatype integer \
            -optional

       ossweb::widget form_movie.image_name -type file -label Image \
            -optional

       ossweb::widget form_movie.create_time -type inform -label "Date Added"

       ossweb::widget form_movie.update_time -type inform -label "Date Updated"

       ossweb::widget form_movie.update -type submit -name cmd -label Update \
            -eval { if { $allow } { return } }

       ossweb::widget form_movie.update2 -type submit -name cmd -label Update&Exit \
            -eval { if { $allow } { return } }

       ossweb::widget form_movie.delete -type button -label Delete \
            -eval { if { $movie_id == "" || $allow } { return } } \
            -confirm "confirm('Delete movie?')" \
            -url [ossweb::html::url cmd delete movie_id $movie_id page $page]

       ossweb::widget form_movie.new -type button -label New \
            -eval { if { $allow } { return } } \
            -url [ossweb::html::url cmd edit]

       ossweb::widget form_movie.back -type button -label Back \
            -url [ossweb::html::url cmd view page $page]
     }

     default {
       ossweb::widget form_movie.cmd -type hidden -optional -value search -freeze

       ossweb::widget form_movie.movie_title -type text -label Title \
            -optional

       ossweb::widget form_movie.movie_descr -type text -label Description \
            -optional

       ossweb::widget form_movie.movie_genre -type multiselect -label Genre \
            -size 5 \
            -resize \
            -optional \
            -options $genres

       ossweb::widget form_movie.movie_lang -type select -label Language \
            -optional \
            -empty -- \
            -options { { English English }
                       { Russian Russian }
                       { French French }
                       { Thai Thai }
                       { Chinese Chinese }
                       { Japanese Japanese }
                     }

       ossweb::widget form_movie.movie_year -type text -label Year \
            -optional \
            -html { size 4 maxlength 4 } \
            -datatype integer

       ossweb::widget form_movie.movie_age -type numberselect -label "Viewer's Age" \
            -optional \
            -empty -- \
            -start 0 \
            -end 21

       ossweb::widget form_movie.imdb_id -type text -label "IMDB Id" \
            -html { size 10 } \
            -optional

       ossweb::widget form_movie.create_time -type date -label "Added after this Date" \
            -optional \
            -format "MON / DD / YYYY" \
            -calendar

       ossweb::widget form_movie.nofile_flag -type checkbox -label "No Files" \
            -value 1

       ossweb::widget form_movie.nodisk_flag -type checkbox -label "No Disk" \
            -value 1

       ossweb::widget form_movie.neverwatched_flag -type checkbox -label "Never Watched" \
            -value 1

       ossweb::widget form_movie.nodescr_flag -type checkbox -label "No Description" \
            -value 1

       ossweb::widget form_movie.search -type submit -label Search

       ossweb::widget form_movie.reset -type reset -label Reset -clear

       ossweb::widget form_movie.new -type button -label New \
            -eval { if { $allow } { return } } \
            -url [ossweb::html::url cmd edit]

       ossweb::widget form_movie.disks -type button -label Disks \
            -eval { if { $allow } { return } } \
            -window Disk \
            -winopts $winopts \
            -url [ossweb::html::url cmd disks lookup:mode 2]

       ossweb::widget form_movie.export -type button -label Export \
            -eval { if { $allow } { return } } \
            -url [ossweb::html::url cmd export]
     }
    }
}

ossweb::conn::callback create_form_disk {} {

    ossweb::lookup::form form_disk

    ossweb::widget form_disk.cmd -type hidden -value disks -freeze

    ossweb::widget form_disk.disk_id -type text -label Disk \
         -eval { if { $allow } { return } } \
         -optional \
         -html { size 4 }
}

ossweb::conn::callback create_form_file {} {

    ossweb::widget form_file.movie_id -type hidden

    ossweb::widget form_file.cmd -type hidden -value add -freeze

    ossweb::widget form_file.page -type hidden -value $page -freeze

    ossweb::widget form_file.file_name -type text -label File \
         -eval { if { $allow } { return } } \
         -html { size 55 }

    ossweb::widget form_file.disk_id -type text -label Disk \
         -eval { if { $allow } { return } } \
         -optional \
         -html { size 4 }

    ossweb::widget form_file.add -type submit -label Add \
         -eval { if { $allow } { return } } \
}

set columns { movie_id int ""
              movie_title "" ""
              movie_year int ""
              movie_age int ""
              movie_descr "" ""
              movie_genre "" ""
              file_name "" ""
              image_name "" ""
              imdb_id int ""
              disk_id int ""
              page int 1
              movies:rowcount const 0
              force const f
              genres const ""
              nogenre_flag int ""
              noremote_access const {[ossweb::config movie:access:remote 0]}
              allow const {[ossweb::conn::check_acl -acl *.movie.movie.play.*]}
              winopts const "width=800,height=600,menubar=0,location=0,scrollbars=1" }

ossweb::conn::process -columns $columns \
           -form_recreate t \
           -forms { form_movie form_file } \
           -on_error { index.index } \
           -eval {
            disks {
              -forms form_disk
              -exec { disks_report }
              -on_error { cmd_name error }
            }
            imdb {
              -exec { movie_imdb }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            add {
              -exec { movie_add }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            remove {
              -exec { movie_remove }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            delete {
              -exec { movie_delete }
              -on_error { -cmd_name edit }
              -next { -cmd_name search }
            }
            update -
            update&exit {
              -exec { movie_update }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
            }
            info -
            edit {
              -exec { movie_edit }
              -on_error { -cmd_name view }
            }
            error {}
            default {
              -exec { movie_list }
            }
           }
