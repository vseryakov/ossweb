# Author: Vlad Seryakov vlad@crystalballinc.com
# September 2003

ossweb::conn::callback queue_action {} {

    if { [set file [ossweb::dehexify $file]] == "" } { return }
    
    switch ${ossweb:cmd} {
     print {
       print::send [ossweb::file::getname $file -path pqueue/$printer -unique f]
       ossweb::conn::set_msg "File has been sent to the printer"
     }
     
     delete {
       ossweb::file::delete $file -path pqueue/$printer
       ossweb::conn::set_msg "File has been deleted"
     }
    }
}

ossweb::conn::callback queue_view {} {

    ossweb::multirow create queue printer file size date user edit
    foreach printer [ossweb::file::list -path pqueue -types d -dirname f] {
      foreach file [ossweb::file::list -path pqueue/$printer] {
        if { ![string match *.@@@ $file] } { continue }
        if { [catch { file stat $file stat }] } { continue }
        set file [file tail $file]
        if { [set user_id [ossweb::file::name $file user]] != "" } {
          set user_id [ossweb::db::value sql:ossweb.user.read_name]
        }
        set name [string range [ossweb::file::name $file] 0 end-4]
        ossweb::multirow append queue \
             $printer \
             [ossweb::file::link print $file -text $name -window File printer $printer] \
             $stat(size) \
             [ns_fmttime $stat(mtime) "%m/%d/%y %H:%M:%S"] \
             $user_id \
             "[ossweb::html::link -image print.gif cmd print printer $printer file [ossweb::hexify $file]]
              [ossweb::html::link -image trash.gif cmd delete printer $printer file [ossweb::hexify $file]]"
      }
    }
}

ossweb::conn::process \
     -columns { file "" "" printer "" "" } \
     -on_error index \
     -eval {
       delete -
       print {
         -exec { queue_action }
         -next { -cmd_name view }
         -on_error { -cmd_name view }
       }
       default {
         -exec { queue_view }
       }
     }


