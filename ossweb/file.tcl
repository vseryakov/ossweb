# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001
#
# $Id: file.tcl 2822 2007-01-23 22:37:54Z vlad $

# File initializing
ossweb::register_init ossweb::file::init

# File storage initialization
proc ossweb::file::init {} {

    ns_register_proc GET /SYSTEM/FILE ::ossweb::file::download
    ns_log Notice ossweb::file: initialized
}

# File download handler
# Format: /SYSTEM/FILE/module/query_args/file_name
proc ossweb::file::download { args } {

    set url [split [ns_conn url] "/"]
    set module [lindex $url 3]
    if { [llength $url] == 5 } {
      set file_name [ns_normalizepath [join [lrange $url 4 end] /]]
      set query ""
    } else {
      set file_name [ns_normalizepath [join [lrange $url 5 end] /]]
      set query [ossweb::dehexify [lindex $url 4]]
    }
    set params [ns_parsequery $query]
    ns_set update $params file:mode storage
    ns_set update $params file:path $module
    ns_set update $params file:module $module
    ns_set update $params file:name $file_name
    ns_set update $params file:query $query
    set status file_return

    # Parse session and user id
    if { [ossweb::conn::parse_request] == "" } {
      ossweb::conn::read_user [ossweb::conn -set user_id [ossweb::config session:user:public]]
    }

    # Call registered callback
    if { [nsv_exists __ossweb_core file:proc:$module] } {
      set status [[nsv_get __ossweb_core file:proc:$module] $params]
    } else {
      # Check if the user is logged in and/or has access to the module
      if { [ossweb::conn::check_acl -acl "*.$module.*.view.*"] } {
        set status file_accessdenied
      }
    }
    # User/permissions verified, now run module check
    if { $status == "file_return" && [nsv_exists __ossweb_core file:check:$module] } {
      set status [[nsv_get __ossweb_core file:check:$module] $params]
    }
    # Now perform reply
    switch -- $status {
     file_done {
     }

     file_return {
       set file_mode [ns_set get $params file:mode]
       set file_path [ns_set get $params file:path]
       set file_name [ns_set get $params file:name]
       ossweb::file::return $file_name -path $file_path -mode $file_mode
       if { [ns_set get $params file:debug] != "" } {
         ns_log Notice ossweb::file::download: $status: $url: /$module/$file_name?$query: Header: [ossweb::convert::set_to_list [ossweb::conn headers]]: Output: [ossweb::convert::set_to_list [ossweb::conn outputheaders]]
       }
     }

     file_notfound {
       ns_return 404 text/plain "File not found"
       ns_log Notice ossweb::file::download: $status: /$module/$file_name?$query
     }

     file_accessdenied {
       ns_return 403 text/plain "Access denied"
       ns_log Notice ossweb::file::download: $status: $url: /$module/$file_name?$query: Header: [ossweb::convert::set_to_list [ossweb::conn headers]]: Output: [ossweb::convert::set_to_list [ossweb::conn outputheaders]]
     }

     default {
       ns_return 501 text/plain "Internal Server Error"
       ns_log Notice ossweb::file::download: $status: /$module/$file_name?$query
     }
    }
}

# Register file download handler
# File handler should return file storage root path to the requested file,
# this proc should perform all security checks
proc ossweb::file::register_download_proc { module proc_name args } {

    nsv_set __ossweb_core file:proc:$module $proc_name
}

# Register file download checker
# After main check is done, i.e. user logged in and permissions are valid
# this check will be called
proc ossweb::file::register_download_check { module proc_name args } {

    nsv_set __ossweb_core file:check:$module $proc_name
}

# Returns root directory for file storage
proc ossweb::file::root {} {

    set path [ossweb::config server:path:storage:[ossweb::conn project_name]]
    if { $path == "" } {
      set path [ossweb::config server:path:storage [ns_info home]/modules/files]
    }
    ::return $path
}

# Returns url for file download, args are additional parameters
# as for ossweb::html::link
proc ossweb::file::url { module file_name args } {

    lappend args u [ossweb::conn user_id]
    ::return /SYSTEM/FILE/$module/[ossweb::hexify [ossweb::convert::list_to_query $args]]/[ossweb::html::escape $file_name]
}

# Builds html link for file download, args are additional parameters
# as for ossweb::html::link
proc ossweb::file::link { module file_name args } {

    ns_parseargs { {-html ""} {-name ""} {-text ""} {-status ""} {-class osswebLink}
                   {-image ""} {-confirm ""} {-window ""} {-winopts ""} {-align ""} {-alt ""}
                   {-path ""} {-proto ""} {-host f} {-width 16} {-height 16} args } $args

    set url [eval "ossweb::file::url $module {$file_name} $args"]
    if { $host == "t" } { set url "[ossweb::conn::hostname $proto]$url" }

    if { $alt != "" } { append html " TITLE=\"$alt\"" }
    if { $name != "" } { append html " NAME=\"$name\"" }
    if { $status != "" } { append html " onMouseOver=\"window.status='$status';return true\"" }
    if { $class != "" } { append html " CLASS=$class" }
    if { $window == "" } {
      if { $confirm != "" } { append html " onClick=\"return $confirm\"" }
      set link "<A HREF=\"$url\" $html>"
    } else {
      set link "<A HREF=\"javascript:;\" onClick=\"$confirm; var w=window.open('$url','$window','$winopts');w.focus();\" $html>"
    }
    if { $image != "" } {
      set text [ossweb::html::image $image -alt $alt -path $path -align $align -width $width -height $height]
    } else {
      if { $text == "" } {
        set text [ossweb::file::name $file_name]
      }
    }
    ::return "$link$text</A>"
}

# Given name of the uploaded file and temporary file name where the contents
# are. Creates entry in file storage, copies file contents and returns new unique
# file name. Can be safely used with all query parameters bacause it checks for uploaded
# file, returns old name if specified in case of empty/non-existent file.
proc ossweb::file::upload { name args } {

    ns_parseargs { {-path ""}
                   {-unique f}
                   {-newname ""}
                   {-oldname ""}
                   {-save ""}
                   {-mode storage}
                   {-nonempty f}
                   {-cmd copy}
                   {-form {[ns_getform]}}
                   {-debug f} } $args

    set tmpname [ns_set get $form $name]
    set tmpfile [ns_set get $form $name.tmpfile]
    set oldname [ossweb::nvl $oldname [ns_set get $form $name.oldname]]
    set newname [ossweb::nvl $newname $tmpname]

    # Save old value into another variable
    if { $save != "" } { uplevel "set $save {$newname}" }

    # Return the same value if it is not upload object
    # In nonempty mode, treat empty file as regular text submission
    if { $tmpfile == "" ||
         $tmpname == "" ||
         ![ns_filestat $tmpfile stat] ||
         ($nonempty == "t" && !$stat(size)) } {
      if { $debug == "t" } {
        ns_log Notice ossweb::file::upload: $name: $tmpfile, old=$oldname, new=$newname, size=[ossweb::coalesce stat(size) 0], ignoring
      }
      ::return [ossweb::nvl $newname $oldname]
    }
    # Strip off all directories
    set newname [lindex [split $newname "\\/"] end]
    set fname [ossweb::file::getname $newname -path $path -unique $unique -create t -mode $mode]
    # Copy/move into new location
    if { $name == "" || [catch { file $cmd -force -- $tmpfile $fname } errMsg] } {
      ns_log Error ossweb::file::upload: $fname: $errMsg
      ::return
    }
    ::return [file tail $fname]
}

# Saves contents in the specified file, creates new file or overwrites
# existing file with new contents.
proc ossweb::file::save { name value args } {

    ns_parseargs { {-path ""} {-unique f} {-user_id ""} } $args

    set fname [ossweb::file::getname $name -path $path -unique $unique -create t -user_id $user_id]
    if { $fname == "" } { ::return }

    if { [catch {
      set fd [::open $fname w]
      ::fconfigure $fd -encoding binary -translation binary
      ::puts -nonewline $fd $value
      ::close $fd
    } errMsg] } {
      catch { ::close $fd }
      ns_log Error ossweb::file::save: $name: $errMsg
      ::return
    }
    ::return $fname
}

# Moves the specified file, creates new file or overwrites existing file with new contents,
# mode - in or out which means copy into or from repositiry
proc ossweb::file::rename { src dest args } {

    ns_parseargs { {-path ""} {-unique f} {-user_id ""} {-mode in} {-cmd rename} } $args

    switch -- $mode {
     out {
       # Out of repository
       set fname [ossweb::file::getname $src -path $path -unique $unique -create t -user_id $user_id]
       set tname $dest
     }

     default {
       # Into repository
       set fname $src
       set tname [ossweb::file::getname $dest -path $path -unique $unique -create t -user_id $user_id]
     }
    }

    if { $fname != "" &&  $tname != "" && [catch { file $cmd -force -- $fname $tname } errMsg] } {
      ns_log Error ossweb::file::$cmd: $fname/$tname: $errMsg
      ::return -1
    }
    ::return 0
}

# Returns normal file name without any special embedded information,
# if file was saved with unique t flag set, file name may include some
# special substrings or symbols to make it unique per given directory.
proc ossweb::file::name { name { property "" } } {

    set index [string first "::" $name]
    if { $index <= 0 } { ::return $name }
    switch -- $property {
     id {
       ::return [lindex [split [string range $name 0 $index] :] 0]
     }

     user {
       ::return [lindex [split [string range $name 0 $index] :] 1]
     }

     default {
       ::return [string range $name [expr $index+2] end]
     }
    }
}

# Returns full path to the given file name
proc ossweb::file::getname { name args } {

    ns_parseargs { {-path ""} {-unique f} {-create f} {-user_id ""} {-mode storage} } $args

    if { [ossweb::file::check_acl $name $path $user_id] } { ::return "" }

    # Build new unique file name
    if { $unique == "t" } {
      set name "[ossweb::db::nextval ossweb_file]:[ossweb::conn user_id 0]::[ossweb::file::name $name]"
    }
    switch -- $mode {
     direct {
       ::return [ns_normalizepath $name]
     }

     default {
       switch -- $mode {
        path {
        }

        pageroot {
          set path [ns_info pageroot]/$path
        }

        default {
          set path [ossweb::file::root]/$path
        }
       }

       if { [string index $path 0] != "/" } {
         set path [ns_info home]/$path
       }
       if { $create == "t" && ![file isdirectory $path] } {
         if { [catch { file mkdir $path } errMsg] } {
           ns_log Error ossweb::file::getname: $name: $errMsg
           ::return ""
         }
       }
       ::return [ns_normalizepath $path/$name]
     }
    }
}

# Deletes file from file storage
proc ossweb::file::delete { name args } {

    ns_parseargs { {-path ""} {-user_id ""} } $args

    set fname [ossweb::file::getname $name -path $path -user_id $user_id]
    if { $fname == "" } { return 0 }

    if { [ns_filestat $fname] && [catch { file delete -force -- $fname } errMsg] } {
      ns_log Error ossweb::file::delete: $fname: $errMsg
      ::return -1
    }
    ::return 0
}

# Returns info about the file, the same as file stat command plus additional
# element called mime_type
proc ossweb::file::stat { name varname args } {

    ns_parseargs { {-path ""} {-user_id ""} {-mode storage} } $args

    set fname [ossweb::file::getname $name -path $path -user_id $user_id -mode $mode]
    if { $fname == "" } {
      ::return
    }

    upvar $varname var
    if { ![ns_filestat $fname var] } {
      ns_log Error ossweb::file::stat: $fname: no file
      ::return -1
    }
    set var(mime_type) [ns_guesstype [file extension $fname]]
    ::return 0
}

# Returns icon for the file's mime type
proc ossweb::file::icon { file } {

    switch -glob -- [ns_guesstype [file extension $file]] {
     *audio* {
       ::return mime/audio.png
     }
     *video* {
       ::return mime/video.png
     }
     *image* {
       ::return mime/image.png
     }
     *html* {
       ::return mime/html.png
     }
     *msword* {
       ::return mime/doc.png
     }
     *powerpoint* {
       ::return mime/ppt.png
     }
     *text/plain* {
       ::return mime/text.png
     }
    }
    ::return mime/binary.png
}

# Returns size of the file
proc ossweb::file::size { name args } {

    ns_parseargs { {-path ""} {-user_id ""} {-mode storage} } $args

    set fname [ossweb::file::getname $name -path $path -user_id $user_id -mode $mode]
    if { $fname == "" } { ::return -1 }

    if { ![ns_filestat $fname stat] } { ::return -1 }
    ::return $stat(size)
}

# Returns mtime of the file
proc ossweb::file::mtime { name args } {

    ns_parseargs { {-path ""} {-user_id ""} {-mode storage} } $args

    set fname [ossweb::file::getname $name -path $path -user_id $user_id -mode $mode]
    if { $fname == "" } { ::return -1 }

    if { ![ns_filestat $fname stat] } { ::return -1 }
    ::return $stat(mtime)
}

# Returns 1 if file exists and accessable
proc ossweb::file::exists { name args } {

    ns_parseargs { {-path ""} {-user_id ""} } $args

    set fname [ossweb::file::getname $name -path $path -user_id $user_id]
    if { $fname == "" } { ::return 0 }

    ::return [expr { [ns_filestat $fname stat] && $stat(type) == "file" }]
}

# Returns image name if exists in the file storage
proc ossweb::file::image_exists { id path { prefix "" } } {

    foreach img "$id.jpg $id.gif $id.png" {
      if { [ossweb::file::exists $prefix$img -path $path] } { ::return $prefix$img }
    }
    ::return
}

# Returns 0 if file access is alowed for the given user
proc ossweb::file::check_acl { name path { user_id "" } } {

    #if { $user_id == "" } { set user_id [ossweb::conn user_id] }
    ::return 0
}

# Opens file and returns file descriptor, file is opened as binary without any
# translation.
proc ossweb::file::open { name args } {

    ns_parseargs { {-path ""} {-mode r} } $args

    set fname [ossweb::file::getname $name -path $path]
    if { $fname == "" } { ::return }

    if { [catch {
      set fd [::open $fname $mode]
      fconfigure $fd -encoding binary -translation binary
    } errMsg] } {
      ns_log Error ossweb::file::open: $path: $name: $errMsg
      ::return
    }
    ::return $fd
}

# Returns list with all files in the specified directory, doesn't read any subdirectories.
proc ossweb::file::list { args } {

    ns_parseargs { {-path ""} {-user_id ""} {-types ""} {-filter *} {-dirname t} {-sort ""} {-struct f} {-desc f} } $args

    set path [ossweb::file::root]/$path/
    if { [string index $path 0] != "/" } {
      set path [ns_info home]/$path
    }
    set files ""
    foreach file [glob -nocomplain -types $types $path/$filter] {
      if { ![ossweb::file::check_acl $file $path $user_id] } {
        if { $sort != "" || $struct == "t" } {
          ns_filestat $file stat
          if { $dirname == "f" } {
            set file [::file tail $file]
          }
          lappend files [::list $file $stat(size) $stat(ctime) $stat(mtime) $stat(atime)]
        } else {
          if { $dirname == "f" } {
            set file [::file tail $file]
          }
          lappend files $file
        }
      }
    }
    if { $sort != "" } {
      set desc [ossweb::decode $desc t -decreasing -increasing]
      switch -- $sort {
       size { set sorted [lsort -index 1 -integer $desc $files] }
       ctime { set sorted [lsort -index 2 -integer $desc $files] }
       mtime { set sorted [lsort -index 3 -integer $desc $files] }
       atime { set sorted [lsort -index 4 -integer $desc $files] }
       default { set sorted [lsort -index 0 $desc $files] }
      }
      if { $struct != "t" } {
        set files ""
        foreach file $sorted {
          lappend files [lindex $file 0]
        }
      } else {
        set files $sorted
      }
    }
    ::return $files
}

# Returns contents of the given file to the HTTP connection stream, similar to
# ns_returnfp.
proc ossweb::file::return { name args } {

    ns_parseargs { {-path ""} {-type ""} {-mode storage} } $args

    catch {
      if { [ossweb::file::stat $name stat -path $path -mode $mode] ||
           ($stat(type) != "file" && $stat(type) != "link") } {
        ns_return 404 text/plain "File not Found"
      } else {
        set type "[ossweb::nvl $type $stat(mime_type)]; name=\"$name\""
        set file [ossweb::file::getname $name -path $path -mode $mode]
        ns_respond -status 200 -type $type -file $file
      }
    }
}

