# Author: Vlad Seryakov vlad@crystalballinc.com
# May 2004

ossweb::conn::callback photos_action {} {

    if { [ossweb::db::value sql:album.check.edit] == "" } {
      error "OSSWEB: Album $album_id not found"
    }
    switch -exact ${ossweb:cmd} {
     update {
       foreach { width height } [album::resize $album_id $image $width $height] {}
       if { [ossweb::db::exec sql:album.photo.update] } {
        error "OSSWEB: Unable to update photo"
       }
       ossweb::conn::set_msg "Photo has been updated"
     }

     delete {
       ossweb::db::begin
       if { [ossweb::db::multivalue sql:album.photo.read] } {
         error "OSSWEB: Photo $photo_id not found"
       }
       if { [ossweb::db::exec sql:album.photo.delete] ||
            [ossweb::db::exec sql:album.update.photo_count] } {
        error "OSSWEB: Unable to delete photo"
       }
       ossweb::db::commit
       ossweb::file::delete $image -path album/$album_id
       ossweb::conn::set_msg "Photo has been deleted"
     }
    }
    ossweb::sql::multipage photos -flush t
}

ossweb::conn::callback photos_edit {} {

    if { [ossweb::db::value sql:album.check.edit] == "" ||
         [ossweb::db::multivalue sql:album.read] } {
      error "OSSWEB: Album $album_id not found"
    }
    if { [ossweb::db::multivalue sql:album.photo.read] } {
      error "OSSWEB: Photo $photo_id not found"
    }
    ossweb::form form_photo -title $album_name
    ossweb::form form_photo set_values
    if { [set width [ossweb::nvl $width $default_width]] > $default_width } { set width $default_width }
    if { [set height [ossweb::nvl $height $default_height]] > $default_height } { set height $default_height }
    set image_url [ossweb::file::url album $album_id/$image "album_id $album_id photo_id $photo_id"]
    set thumbnail_url [ossweb::file::url album $album_id/[album::thumbnail $album_id $image] "album_id $album_id photo_id $photo_id"]
}

ossweb::conn::callback albums_action {} {

    switch -exact ${ossweb:cmd} {
     update {
       if { $album_id == "" } {
        if { [ossweb::db::exec sql:album.create] } {
          error "OSSWEB: Unable to create album"
        }
        set album_id [ossweb::db::currval album]
       } else {
        if { [ossweb::db::exec sql:album.update] } {
          error "OSSWEB: Unable to update album"
        }
       }
       ossweb::conn::set_msg "Album has been updated"
     }

     upload {
       if { [ossweb::db::value sql:album.check.edit] == "" } {
         error "OSSWEB: Album $album_id not found"
       }
       for { set i 1 } { $i <= 10 } { incr i } {
         set image [ossweb::file::upload photo$i -path album/$album_id -unique t]
         if { $image == "" } { continue }
         foreach { width height } [album::resize $album_id $image] {}
         if { [ossweb::db::exec sql:album.photo.create.image] } {
           error "OSSWEB: Unable to save image $image"
         }
       }
       ossweb::db::exec sql:album.update.photo_count
       ossweb::conn::set_msg "Photos have been uploaded"
     }

     delete {
       ossweb::db::foreach sql:album.photo.list {
         catch { file delete -force $path/$image $path/_$image }
       }
       if { [ossweb::db::exec sql:album.delete] } {
         error "OSSWEB: Unable to delete album"
       }
       ossweb::conn::set_msg "Album has been deleted"
     }
    }
    ossweb::sql::multipage photos -flush t
}

ossweb::conn::callback albums_list {} {

    if { ![ossweb::conn::check_acl -acl "*.album.*.update.*"] } {
      set album:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    }
    ossweb::db::multirow albums sql:album.list -eval {
      set row(album_name) [ossweb::html::link -text $row(album_name) cmd album album_id $row(album_id)]
      if { $row(user_id) == [ossweb::conn user_id] } {
        set row(edit) [ossweb::html::link -text Edit cmd edit album_id $row(album_id)]
      } else {
        set row(edit) ""
      }
    }
}

ossweb::conn::callback albums_edit {} {

    if { $album_id == "" } { return }
    switch -- ${ossweb:cmd} {
     edit {
       if { [ossweb::db::value sql:album.check.edit] == "" } {
         error "OSSWEB: You have no access to this album"
       }
     }
     album {
       set tab photos
     }
    }
    if { [ossweb::db::multivalue sql:album.read] } {
      error "OSSWEB: Album $album_id not found"
    }
    ossweb::form form_album set_values
    ossweb::form form_album -title $album_name
    switch -- $tab {
     upload {
       ossweb::form form_upload -title $album_name
     }

     photos {
       ossweb::db::multipage photos \
            sql:album.photo.search1 \
            sql:album.photo.search2 \
            -page $page \
            -pagesize [ossweb::nvl $page_size $default_page_size] \
            -cmd_name ${ossweb:cmd} \
            -query "album_id=$album_id&tab=$tab" \
            -eval {
         set row(file_name) [ossweb::file::name $row(image)]
         set row(break) [expr [incr count] % [ossweb::nvl $row_size $default_row_size]]
         if { [set width [ossweb::nvl $row(width) $default_width]] > $default_width } { set width $default_width }
         if { [set height [ossweb::nvl $row(height) $default_height]] > $default_height } { set height $default_height }
         set url [ossweb::file::url album $album_id/[album::thumbnail $album_id $row(image)] album_id $album_id photo_id $row(photo_id) page $page]
         set image [ossweb::html::image $url -width $width -height $height]
         if { ${ossweb:cmd} == "edit" } {
           set row(image) [ossweb::html::link -text $image cmd edit.photo album_id $album_id photo_id $row(photo_id) page $page]
         } else {
           set url [ossweb::file::url album $album_id/$row(image) album_id $album_id photo_id $row(photo_id) page $page]
           set row(image) "<A HREF=$url TARGET=Photo>$image</A>"
         }
       }
     }
    }
}

ossweb::conn::callback create_form_album {} {

    ossweb::form form_album -title "Album Details"
    ossweb::widget form_album.album_id -type hidden -datatype integer -optional
    ossweb::widget form_album.album_name -type text -label "Name"
    ossweb::widget form_album.album_status -type select -label "Status" \
         -options { { Active Active } { Inactive Inactive } }
    ossweb::widget form_album.album_type -type select -label "Type" \
         -options { { Public Public } { Private Private } { Group Group } }
    ossweb::widget form_album.row_size -type text \
         -html { size 2 maxlength 2 } -label "Photos per row" \
         -optional
    ossweb::widget form_album.page_size -type text \
         -html { size 2 maxlength 2 } -label "Photos on the page" \
         -optional
    ossweb::widget form_album.description -type textarea \
         -html { rows 5 cols 50 } -label "Description" \
         -optional
    ossweb::widget form_album.back -type button -label Back \
         -url [ossweb::html::url cmd view page $page]
    ossweb::widget form_album.update -type submit -name cmd -label Update
    ossweb::widget form_album.delete -type submit -label Delete \
         -condition "@album_id@ gt 0" \
         -name cmd \
         -html { onClick "return confirm('Record will be deleted, continue?')" }
}

ossweb::conn::callback create_form_upload {} {

    ossweb::form form_upload -title "Upload Photos"
    ossweb::widget form_upload.tab -type hidden -optional -value $tab
    ossweb::widget form_upload.album_id -type hidden -datatype integer -optional
    ossweb::widget form_upload.photo1 -type file -label Photo1 -optional
    ossweb::widget form_upload.photo2 -type file -label Photo2 -optional
    ossweb::widget form_upload.photo3 -type file -label Photo3 -optional
    ossweb::widget form_upload.photo4 -type file -label Photo4 -optional
    ossweb::widget form_upload.photo5 -type file -label Photo5 -optional
    ossweb::widget form_upload.photo6 -type file -label Photo6 -optional
    ossweb::widget form_upload.photo7 -type file -label Photo7 -optional
    ossweb::widget form_upload.photo8 -type file -label Photo8 -optional
    ossweb::widget form_upload.photo9 -type file -label Photo9 -optional
    ossweb::widget form_upload.photo10 -type file -label Photo10 -optional
    ossweb::widget form_upload.back -type button -label Back \
         -url [ossweb::html::url cmd view page $page]
    ossweb::widget form_upload.upload -type submit -name cmd -label Upload
}

ossweb::conn::callback create_form_photo {} {

    ossweb::form form_photo -title "Photo Details"
    ossweb::widget form_photo.ctx -type hidden -value photo -freeze
    ossweb::widget form_photo.page -type hidden -value $page -freeze
    ossweb::widget form_photo.album_id -type hidden -datatype integer
    ossweb::widget form_photo.photo_id -type hidden -datatype integer
    ossweb::widget form_photo.image -type label -label Image
    ossweb::widget form_photo.description -type textarea \
         -html { rows 3 cols 50 } -label "Description" \
         -optional
    ossweb::widget form_photo.width -type text -label Width \
         -datatype integer \
         -html { size 5 } \
         -info "Max 300x200" \
         -optional
    ossweb::widget form_photo.height -type text -label Height \
         -datatype integer \
         -html { size 5 } \
         -optional
    ossweb::widget form_photo.back -type button -label Back \
         -url [ossweb::html::url cmd edit album_id $album_id tab photos page $page]
    ossweb::widget form_photo.update -type submit -name cmd -label Update
    ossweb::widget form_photo.delete -type submit -label Delete \
         -condition "@album_id@ gt 0" \
         -name cmd \
         -html { onClick "return confirm('Record will be deleted, continue?')" }
}

ossweb::conn::callback create_form_tab {} {

    ossweb::form form_tab
    if { $album_id != "" } {
      set url [ossweb::lookup::url cmd edit album_id $album_id]
      ossweb::widget form_tab.edit -type link -label Edit -value $url
      ossweb::widget form_tab.upload -type link -label Upload -value $url
      ossweb::widget form_tab.photos -type link -label Photos -value $url
    }
}

variable ::album::default_width
variable ::album::default_height
variable ::album::default_row_size
variable ::album::default_page_size

set columns { album_id int ""
              album_name "" ""
              album_status "" ""
              album:add const ""
              photo_id int 0
              photos:rowcount const 0
              description "" ""
              tab "" edit
              count const 0
              page int 1 }

# Process request parameters
ossweb::conn::process \
           -columns $columns \
           -form_recreate t \
           -forms { form_album form_upload form_tab } \
           -on_error { index.index } \
           -eval {
            delete {
              -exec { albums_action }
              -next { -cmd_name view }
              -on_error { -cmd_name view }
            }
            upload -
            update {
              -exec { albums_action }
              -next { -cmd_name edit }
              -on_error { -cmd_name edit }
            }
            edit -
            album {
              -exec { albums_edit }
              -on_error { -cmd_name view }
            }
            delete.photo {
              -exec { photos_action }
              -next { -cmd_name edit -ctx_name album tab photos }
              -on_error { -cmd_name edit }
            }
            update.photo {
              -forms { form_tab form_photo }
              -exec { photos_action }
              -next { -cmd_name edit -ctx_name photo }
              -on_error { -cmd_name edit }
            }
            edit.photo {
              -forms { form_tab form_photo }
              -exec { photos_edit }
              -on_error { -cmd_name edit -ctx_name album }
            }
            error {
            }
            default {
              -exec { albums_list }
            }
           }
