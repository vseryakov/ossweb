# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2002


namespace eval bookmarks {
  variable version "Bookmarks version 1.1"
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

# Returns html link to be publsihed on the web site for
# quick access to bookmarks
proc ossweb::html::toolbar::bookmarks {} {

    if { [ossweb::conn::check_acl -acl *.bookmarks.bookmarks.view.*] } { return }
    return [ossweb::html::link \
                 -image /img/toolbar/book.gif \
                 -mouseover /img/toolbar/book_o.gif \
                 -width "" \
                 -height "" \
                 -hspace 6 \
                 -alt Bookmarks \
                 -status Bookmarks \
                 -window Bookmarks \
                 -winopts "width=450,height=750,menubar=0,location=0,scrollbars=1" \
                 -query "url='+escape(window.location)+'" \
                 -app_name bookmarks \
                  bookmarks \
                  lookup:mode 2]
}

# Perform importing of foreign bookmarks
proc bookmarks::import { type file } {

    switch $type {
     netscape {
       if { [catch { set fd [open $file] } errmsg] } {
         ns_log Error bookmarks::import: $type: $file: $errmsg
         return -1
       }
       set section ""
       while { ![eof $fd] } {
         set line [gets $fd]
         if { [regexp {</DL>} $line] } {
           set section ""
           continue
         }
         if { [regexp {<H3[^>]*>([^<]*)</H3>} $line d title] } {
           set url ""
           ossweb::db::exec sql:bookmarks.create
           set section [ossweb::db::value "SELECT CURRVAL('bookmarks_seq')"]
           continue
         }
         if { [regexp {<DT><A HREF="([^"]*)"[^>]*>([^<]*)</A>} $line d url title] } {
           ossweb::db::exec sql:bookmarks.create
           continue
         }
       }
       close $fd
     }
    }
    return 0
}
