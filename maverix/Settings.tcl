# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2003

ossweb::conn::callback settings_save {} {
    
    set query [ossweb::conn::query -match "maverix:*" -return t]
    foreach item $query {
      set name [lindex $item 0]
      set value [string trim [lindex $item 1]]
      if { [ossweb::db::exec sql:ossweb.config.update] } {
        error "OSS: Unable to save settings"
      }
    }
    ossweb::conn::set_msg "Settings have been updated"
    ossweb::reset_config
    # Refresh internal tables
    eval ns_smtpd relay set [string map { \r {} \n { } } [ossweb::config maverix:domain:relay]]
    ns_log debug maverix::init: Relay Domains: [ns_smtpd relay get]
    eval ns_smtpd local set [string map { \r {} \n { } } [ossweb::config maverix:domain:local]]
    ns_log debug maverix::init: Local Domains: [ns_smtpd local get]
}

ossweb::conn::callback settings_view {} {

    set spamversion [ns_smtpd spamversion]
    set virusversion [ns_smtpd virusversion]
    set address [ns_smtpd info address]
    set relay [ns_smtpd info relay]
    foreach { name value } [nsv_array get __ossweb_config maverix:*] {
      set $name $value
      if { [string match "*(secs)" [ossweb::widget form_settings.$name label]] } {
        ossweb::widget form_settings.$name -data " [ossweb::date uptime $value]"
      }
    }
    ossweb::form form_settings set_values
}

ossweb::conn::callback create_form_settings {} {

     ossweb::form form_settings -title "System Settings" \
          -action Settings.oss \
          -border_style default
     ossweb::widget form_settings.spamversion -type label -label "Maverix Anti-Spam Software" \
          -nohidden
     ossweb::widget form_settings.virusversion -type label -label "Maverix Anti-Virus Software" \
          -nohidden
     ossweb::widget form_settings.address -type label -label "Maverix SMTP Server" \
          -nohidden
     ossweb::widget form_settings.relay -type label -label "SMTP Relay for Delivery" \
          -nohidden
     ossweb::widget form_settings.maverix:user:relay -type text -label "SMTP Relay for User Digests" \
          -info "SMTP server for delivering user digests" \
          -optional
     ossweb::widget form_settings.maverix:sender:relay -type text -label "SMTP Relay for Sender Digests" \
          -info "SMTP server for delivering sender digests" \
          -optional
     ossweb::widget form_settings.maverix:hostname -type text -label "Maverix Hostname" \
          -info "Hostname to be used in Maverix urls" \
          -optional
     ossweb::widget form_settings.maverix:user:admin -type text -label "User Digest Email" \
          -info "Email address to be sent from for user digests" \
          -datatype email
     ossweb::widget form_settings.maverix:sender:admin -type text -label "Sender Digest Email" \
          -info "Email address to be sent from for sender digests" \
          -datatype email
     ossweb::widget form_settings.maverix:user:type -type select -label "Default User Mode" \
          -info "Default mode for new users" \
          -options { { VRFY VRFY } { PASS PASS } { DROP DROP } }
     ossweb::widget form_settings.maverix:sender:type -type select -label "Default Sender Mode" \
          -info "Default mode for new senders" \
          -options { { VRFY VRFY } { PASS PASS } { DROP DROP } }
     ossweb::widget form_settings.maverix:domain:relay -type textarea -label "Relay domains" \
          -optional \
          -html { cols 45 rows 5 wrap off } \
          -info "Domains to be allowed for relaying, smtp relay host 
                 optionally may be specified in format: domain:relayhost"
     ossweb::widget form_settings.maverix:domain:local -type textarea -label "Local domains/networks" \
          -optional \
          -html { cols 45 rows 5 wrap off } \
          -info "Domains/networks that are local"
     ossweb::widget form_settings.maverix:cache:size -type text -label "Cache Size" \
          -info "Size of the cache for users/senders, format: size{M|B|K}<BR>
                 where M,B,K are Mbytes, Kbytes and Bytes respectively." \
          -optional \
          -html { size 5 }
     ossweb::form form_settings -section "Digest Preferences"
     ossweb::widget form_settings.maverix:digest:interval -type text -label "Digest Interval (secs)" \
          -info "Maximum period between digests in case of inactivity" \
          -optional \
          -datatype integer \
          -html { size 8 }
     ossweb::widget form_settings.maverix:body:size -type text -label "Message Body Size (bytes)" \
          -info "Size of the body to show in the digest" \
          -optional \
          -datatype integer \
          -html { size 5 }
     ossweb::widget form_settings.maverix:history -type text -label "Message Lifetime (secs)" \
          -info "Maximum message lifetime, after this period message will be deleted" \
          -optional \
          -datatype integer \
          -html { size 8 }
     ossweb::widget form_settings.maverix:stale -type text -label "Stale Period (secs)" \
          -info "Period after which digest is considered stale" \
          -optional \
          -datatype integer \
          -html { size 8 }
     ossweb::widget form_settings.maverix:digest:history -type text -label "Message Digest Period (secs)" \
          -info "Messages should be no older than this period to be included into digest" \
          -optional \
          -datatype integer \
          -html { size 8 }
     ossweb::widget form_settings.maverix:user:interval -type text -label "Rcpt Digest Interval (secs)" \
          -info "Interval between digests for recipients" \
          -optional \
          -datatype integer \
          -html { size 8 }
     ossweb::widget form_settings.maverix:sender:interval -type text -label "Sender Digest Interval (secs)" \
          -info "Interval between digests for senders" \
          -optional \
          -datatype integer \
          -html { size 7 }
     ossweb::widget form_settings.maverix:digest:start -type text -label "Digest Start Time" \
          -info "Starting time for digest" \
          -optional \
          -html { size 5 }
     ossweb::widget form_settings.maverix:digest:end -type text -label "Digest End Time" \
          -info "Ending time for digest" \
          -optional \
          -html { size 5 }
     ossweb::widget form_settings.maverix:digest:sender -type boolean -label "Sender Self Verification" \
          -info "Yes to allow sender to do self verification" \
          -optional
     ossweb::widget form_settings.update -type submit -name cmd -label Update
}

ossweb::conn::process \
         -forms { form_settings } \
         -on_error_set_template { -cmd_name error } \
         -on_error_set_cmd "" \
         -eval {
            update {
              -exec { settings_save }
              -on_error_set_template { -cmd_name edit }
              -next_template { -cmd_name edit }
            }
            error {
            }
            default {
              -exec { settings_view }
              -on_error_set_cmd ""
            }
         }

