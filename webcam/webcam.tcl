# Author: Vlad Seryakov vlad@crystalballinc.com 
# August 2002

ossweb::conn::callback webcam_image {} {

   if { ![webcam::device $device acl] } {
     if { $grab == 1 } { webcam::schedule $device }
     if { [set img [webcam::image $device]] != "" } { set image $img }
   }
   ns_returnfile 200 image/png $image
   ossweb::adp::Exit
}

ossweb::conn::callback webcam_view {} {

   ossweb::multirow create devices device
   foreach device [webcam::devices -acl t] {
     ossweb::multirow append devices $device
   }
}

ossweb::conn::process \
     -columns { grab int 0
                device "" ""
                refresh const {[ossweb::config webcam:refresh 60]} 
                image const {[ossweb::config webcam:defimage [ns_info pageroot]/img/misc/1.gif]}
     } \
     -on_error index \
     -eval {
       image {
         -exec { webcam_image }
       }
       default {
         -exec { webcam_view }
       }
     }
     
     

