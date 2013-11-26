# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2002


ossweb::conn::callback bookmarks_action {} {

    switch -- ${ossweb:cmd} {
     import {
        if { ![bookmarks::import [ns_queryget type] [ns_queryget file.tmpfile]] } {
          ossweb::conn::set_msg "Bookmarks has been imported"
        } else {
          ossweb::conn::set_msg "Bookmarks has NOT been imported"
        }
        ossweb::db::cache flush "bookmarks:$user_id"
     }

     update {
       # Retrieve title from the page
       if { $title == "" && $url != "" } {
         if { ![catch { set page [ns_httpget $url] }] } {
           regexp -nocase {<title>([^<]*)</title>} $page d title
         }
       }
       if { $title == "" } {
         ossweb::conn::set_msg "Empty bookmark has been ignored"
         return
       }
       if { $bm_id != "" } {
         if { [ossweb::db::exec sql:bookmarks.update] } {
           error "OSS: Unable to update bookmark record"
         }
       } else {
         if { [ossweb::db::exec sql:bookmarks.create] } {
           error "OSS: Unable to create bookmark record"
         }
       }
       ossweb::conn::set_msg "Bookmark record has been updated"
       ossweb::db::cache flush "bookmarks:$user_id"
     }

     delete {
       if { [ossweb::db::exec sql:bookmarks.delete] } {
         error "OSS: Unable to delete bookmark record"
       }
       ossweb::conn::set_msg "Bookmark record has been deleted"
       ossweb::db::cache flush "bookmarks:$user_id"
     }

     open {
       set menuState [ossweb::conn::get_property bookmarksState -global t -cache t]
       append menuState ":$bm_id;"
       ossweb::conn::set_property bookmarksState $menuState -global t -cache t
     }

     close {
       set menuState [split [ossweb::conn::get_property bookmarksState -global t -cache t] ":"]
       set newState ""
       foreach item $menuState {
        if { $item == "" || $item == "$bm_id;" } { continue }
        append newState ":$item"
       }
       ossweb::conn::set_property bookmarksState $newState -global t -cache t
     }
    }
}

ossweb::conn::callback bookmarks_edit {} {

    if { $bm_id != "" } {
      if { [ossweb::db::multivalue sql:bookmarks.read] } {
        error "OSS: Invalid bookmark id"
      }
      ossweb::form form_bookmarks -info [ossweb::lookup::link -text "\[$bm_id\]" cmd edit bm_id $bm_id]
      if { $url == "" } {
        ossweb::widget form_bookmarks.url destroy
      }
    }
    ossweb::form form_bookmarks set_values
}

ossweb::conn::callback bookmarks_view {} {

    # Current items state
    set menuState [ossweb::conn::get_property bookmarksState -global t -cache t]
    ossweb::db::multirow bookmarks sql:bookmarks.list \
         -cache t \
         -cache:global f \
         -timeout 86400 \
         -eval {
      set offset [string repeat "&nbsp; " [expr ([llength [split $row(path) /]]-3)*5]]
      set row(title) "$offset$row(title)"
      # Skip this item if it is inside closed folder
      if { [info exists closed($row(section))] } {
        set closed($row(bm_id)) 1
        continue
      }
      set row(edit) [ossweb::lookup::link -image edit.gif cmd edit bm_id $row(bm_id)]
      set row(delete) [ossweb::lookup::link -image trash.gif -hash $row(section) -confirm "confirm('Record will be deleted, continue?')" cmd delete bm_id $row(bm_id)]
      if { $row(url) != "" } {
        set row(title) "<A HREF=\"javascript:var a\" [ossweb::html::popup_handlers U$row(bm_id)] onClick=\"bmUrl('$row(url)')\">$row(title)</A>"
        ossweb::conn -append html:foot [ossweb::html::popup_object U$row(bm_id) [ossweb::util::wrap_text $row(url) -size 20]]
      } else {
        # Check config property where we have all opened folder ids
        if { [string first ":$row(bm_id);" $menuState] == -1 } {
          set closed($row(bm_id)) 1
          set cmd open
          set icon closed.gif
        } else {
          set cmd close
          set icon open.gif
        }
        set row(title) [ossweb::lookup::link -name $row(bm_id) -hash $row(bm_id) -text "[ossweb::html::image $icon] <B>$row(title)</B>" cmd $cmd bm_id $row(bm_id)]
      }
    }
    ossweb::widget form_bookmarks.add -type button -label New \
         -html { onClick bmNew() }
    ossweb::widget form_bookmarks.import -type button -label Import \
         -url [ossweb::lookup::url cmd edit.import]
    ossweb::widget form_bookmarks.close -type button -label Close \
         -html { onClick window.close() }
}

ossweb::conn::callback create_form_import {} {

    ossweb::form form_import -title "Import Bookmark" -html { ENCTYPE multipart/form-data }
    ossweb::lookup::form form_import
    ossweb::widget form_import.type -type select -label Type \
         -options { { Netscape netscape } }
    ossweb::widget form_import.file -type file -label File
    ossweb::widget form_import.import -type submit -name cmd -label Import

}

ossweb::conn::callback create_form_bookmarks {} {

    ossweb::form form_bookmarks -title "Bookmark Details"
    ossweb::lookup::form form_bookmarks
    ossweb::widget form_bookmarks.bm_id -type hidden -optional
    ossweb::widget form_bookmarks.url -type text -label Url \
         -optional \
         -html { size 40 }
    ossweb::widget form_bookmarks.title -type text -label Title \
         -html { size 40 } \
         -optional
    ossweb::widget form_bookmarks.section -type select -label "Existing Section" \
         -empty "--" \
         -options [ossweb::db::multilist sql:bookmarks.section.list] \
         -optional
    ossweb::widget form_bookmarks.sort -type text -label Sort \
         -optional \
         -datatype integer \
         -html { size 5 }
    ossweb::widget form_bookmarks.update -type submit -name cmd -label Update
    ossweb::widget form_bookmarks.reset -type reset -label Reset -clear
    ossweb::widget form_bookmarks.back -type button -label List \
         -url [ossweb::lookup::url cmd view] \
         -leftside
}

ossweb::conn::process \
     -columns { bm_id int ""
                url "" ""
                title "" ""
                section "" ""
                sort int ""
                user_id const {[ossweb::conn user_id]} } \
     -on_error index \
     -eval {
       open -
       close -
       import -
       update -
       delete {
         -forms form_bookmarks
         -exec { bookmarks_action }
         -on_error { -cmd_name edit }
         -next { -cmd_name view }
       }
       edit {
         -forms form_bookmarks
         -exec { bookmarks_edit }
         -on_error { -cmd_name view }
       }
       edit.import {
         -forms form_import
         -on_error { -cmd_name view }
       }
       default {
         -exec { bookmarks_view }
       }
     }
