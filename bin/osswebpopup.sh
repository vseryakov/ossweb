#!/usr/bin/pgtclsh

# First parameter should be user id
if { [set user [lindex $argv 0]] == "" } { exit }

# Read message from stdin
set data ""
while { ![eof stdin] } { append data [gets stdin] "\n" }
if { $data == "" } { exit }

if { [catch {
  # Double quote single quotes
  regsub -all {'} $data {''} data

  # Open database connection
  set db [pg_connect ossweb]
  set rc [pg_exec $db "UPDATE ossweb_user_properties SET value=value||'$data'
                       WHERE user_id=$user AND session_id='0' AND name='ossweb:popup0msg'"]
  # Create new record if no updates
  if { [pg_result $rc -cmdTuples] == 0 } {
    pg_exec $db "INSERT INTO ossweb_user_properties(timestamp,user_id,session_id,name,value)
                 VALUES([clock seconds],$user,'0','ossweb:popup0msg','$data')"
  }
  pg_disconnect $db
} errmsg] } {
  exec logger $errmsg
  exit
}

