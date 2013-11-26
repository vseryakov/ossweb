# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001

# IR Blaster Setup
#   http://www.lircsetup.com/lirc/blaster/index.php

nsv_array set ns:video { status stop channel 0 duration 300 bitrate 204800 size cif remote SA8000 }

ns_register_proc GET /video.ctl video_handler
ns_register_proc GET /video.m1v video_handler
ns_register_proc GET /video.flv video_handler
ns_register_proc GET /video.ffm video_handler

proc video_handler { args } {

    set url [ns_conn url]
    # Channel number to switch
    set channel [ns_queryget c]
    # Remote control button
    set cmd [ns_queryget e]
    
    # Duration of the stream, size and bitrate
    set duration [ns_queryget t]
    if { $duration == "" } {
      set duration [nsv_get ns:video duration]
    }
    set size [ns_queryget s]
    if { $size == "" } {
      set size [nsv_get ns:video size]
    }  
    set bitrate [ns_queryget r]
    if { $bitrate == "" } {
      set bitrate [nsv_get ns:video bitrate]
    }  
    set remote [ns_queryget p]
    if { $remote == "" } {
      set remote [nsv_get ns:video remote]
    }  

    switch -glob -- $url {
     *.ctl {
         # Control request
         # Perform channel switch first if different
         if { $channel != "" && [nsv_get ns:video channel] != $channel } {
           foreach digit [split $channel ""] {
             if { [catch { eval exec /usr/bin/irsend --device=/dev/lircd SEND_ONCE $remote $digit } errmsg] } {
               ns_log Error Video: $channel: $errmsg
             }
             after 1000
           }
           nsv_set ns:video channel $channel
         }
         # Send remote control button
         switch -- $cmd {
	  "" {}
	  
	  init {
	    # Initialize settings for the session
	    nsv_array set ns:video [list duration $duration size $size bitrate $bitrate remote $remote]
	  }
	  
	  kill {
	    exec killall -9 ffmpeg
	    nsv_set ns:video status stop
	  }
	  
	  default {
            if { [catch { eval exec /usr/bin/irsend --device=/dev/lircd SEND_ONCE $remote $cmd } errmsg] } {
              ns_log Error Video: $cmd: $errmsg
            } 
	  }    
         }
         ns_return 200 text/plain "$channel $cmd OK"
         ns_log notice [ns_conn peeraddr]: $cmd $channel
     }

     default {
         # Still busy
         if { [nsv_get ns:video status] == "play" } {
           ns_log Notice [ns_conn peeraddr] device busy
           ns_returnnotfound
           return
         }
         ns_log Notice [ns_conn peeraddr]: started

         ns_write "HTTP/1.0 200 OK\r\nContent-Type: video/mpeg\r\n\r\n"

         nsv_set ns:video status play

         if { [catch {
             switch -regexp -- $url {
              {.ffm|.flv} {
         	    set fd [open "|ffmpeg -v 0 -t $duration -i /dev/video0 -ar 11025 -s $size -b $bitrate -f flv -"]
              }
              default {
                 set fd [open /dev/video0]
              }
             }
             fconfigure $fd -translation binary -encoding binary
             set now [clock seconds]
             while { [clock seconds] - $now <= $duration && [nsv_get ns:video status] == "play" } {
                set buf [read $fd 2048]
                if { ![ns_write $buf] } { break }
             }
             close $fd
         } errmsg] } {
           ns_log Error Video: $errmsg
         }
         nsv_set ns:video status stop
         ns_log Notice [ns_conn peeraddr]: stopped
     }
    }
}

