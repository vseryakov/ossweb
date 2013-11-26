# Author: Vlad Seryakov vlad@crystalballinc.com
# May 2004

namespace eval album {
  variable version "Albums version 1.1"
  variable default_width 300
  variable default_height 200
  variable default_row_size 3
  variable default_page_size 6
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

ossweb::register_init album::init

# Link to albums from the toolbar
proc ossweb::html::toolbar::album {} {

    if { [ossweb::conn::check_acl -acl *.album.album.view.*] } { return }
    return [ossweb::html::link -image camera.gif -status Albums -alt Albums -app_name album albums]
}

proc album::init {} {

    ossweb::file::register_download_proc album ::album::download
    ns_log Notice album: initialized
}

# File download handler, used by ossweb::file::download for file download verification
proc album::download { params } {

    set album_id [ns_set get $params album_id]
    set photo_id [ns_set get $params photo_id]
    if { [ossweb::datatype::integer $album_id] != "" ||
         [ossweb::datatype::integer $photo_id] != "" ||
         [ossweb::db::multivalue sql:album.check.view] == "" } {
      ns_log Notice album::download: [ns_conn url]: User=[ossweb::conn user_id]: ID=$album_id, Photo=$photo_id
      return file_accessdenied
    }
    return file_return
}

# Resize album image
proc album::resize { album_id file { width "" } { height "" } } {

    variable default_width
    variable default_height

    if { $width == "" } { set width $default_width }
    if { $height == "" } { set height $default_height }
    set file1 [ossweb::file::getname $album_id/$file -path album]
    set file2 [ossweb::file::getname $album_id/_$file -path album]
    catch { exec convert -size ${width}x${height} -resize ${width}x${height} $file1 $file2 }
    if { [file exists $file2] } {
      if { [string match -nocase *.jpg $file2] } { return [ns_jpegsize $file2] }
      if { [string match -nocase *.gif $file2] } { return [ns_gifsize $file2] }
    }
    return "$width $height"
}

# Returns name of thumbnail image if exists
proc album::thumbnail { album_id { image "" } } {

    if { $image == "" } {
      foreach rec [ossweb::db::multilist sql:album.photo.list] {
        foreach { photo_id image width height } $rec {}
        foreach { width height } [album::resize $album_id $image $width $height] {}
        ossweb::db::exec sql:album.photo.update
      }
      return
    }
    if { [ossweb::file::exists $album_id/_$image -path album] } { return _$image }
    return $image
}

