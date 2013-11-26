# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback config_viewlog {} {

    set size [ns_queryget size 4096]
    switch -- [ns_queryget file] {
     access {
        set file [ns_accesslog file]
     }
     default {
        set file [ns_info log]
     }
    }
    set fd [open $file]
    set offs [expr [file size $file] - $size]
    if { $offs < 0 } { set offs $size }
    seek $fd $offs
    gets $fd
    set data [ns_quotehtml [read $fd]]
    close $fd
}

ossweb::conn::callback config_action {} {

  switch -exact ${ossweb:cmd} {

   reboot {
     if { ![ossweb::conn::check_acl -acl *.*.*.*.*] } {
       ossweb::admin::reboot 30
       ossweb::conn::set_msg "Server will be rebooted in 30 seconds"
     } else {
       ossweb::conn::set_msg "Not enough permissions to reboot the server"
     }
   }

   add {
     regsub -all {::} $name {:} name
     if { [ossweb::db::exec sql:ossweb.config.create] } {
       error "OSSWEB: Operation failed"
     }
     ossweb::conn::set_msg "Record added"
     ossweb::form form_config reset -skip info
   }

   update {
     set module ""
     set description ""
     set query [ossweb::conn::query -match "CFG:*" -return t]
     foreach cfg $query {
      set name [string range [lindex $cfg 0] 4 end]
      if { [string match "*:old" $name] } { continue }
      set name [ossweb::dehexify $name]
      regsub -all {::} $name {:} name
      set value [string trim [lindex $cfg 1]]
      if { $value == [ns_queryget "[lindex $cfg 0]:old"] } {
        continue
      }
      if { $value == "" } {
        if { [ossweb::db::exec sql:ossweb.config.delete] } {
          error "OSSWEB: Operation failed"
        }
      } else {
        if { [ossweb::db::exec sql:ossweb.config.update] } {
          error "OSSWEB: Operation failed"
        }
      }
     }
     ossweb::conn::set_msg "Record updated"
     ossweb::form form_config reset -skip info
   }

   delete {
     if { [set name [ossweb::dehexify [ns_queryget name]]] != "" &&
          [ossweb::db::exec sql:ossweb.config.delete] } {
       error "OSSWEB: Operation failed"
     }
   }
  }
  ossweb::form form_params destroy
  # Flush config cache
  ossweb::reset_config -cluster t
}

ossweb::conn::callback config_list {} {

}

ossweb::conn::callback create_form_config {} {

    global tcl_patchLevel

    ossweb::widget form_config.type -type select -label "System Parameters" \
         -empty "--" \
         -optional \
         -options [ossweb::db::multilist sql:ossweb.config_types.list] \
         -html { onChange "setConfigType(this)" }

    ossweb::widget form_config.module -type text -label Module -optional

    ossweb::widget form_config.name -type text -datatype text -label Name

    ossweb::widget form_config.value -type text -label Value \
         -resize

    ossweb::widget form_config.description -type textarea -label Description \
         -rows 2 \
         -cols 35  \
         -resize \
         -optional

    ossweb::widget form_config.info -type inform -value \
         "<TABLE BORDER=0>
          <TR VALIGN=TOP><TD CLASS=osswebFormLabel>Server:</TD><TD>[ns_info name] [ns_info version] [ns_info platform]</TD></TR>
          <TR VALIGN=TOP><TD CLASS=osswebFormLabel>Host:</TD><TD>[ns_info hostname]/[ns_info address]</TD></TR>
          <TR VALIGN=TOP><TD CLASS=osswebFormLabel>Listen:</TD><TD>[ns_config "ns/server/[ns_info server]/module/nssock" address [ns_config "ns/server/[ns_info server]/module/nssock" hostname]]:[ns_config "ns/server/[ns_info server]/module/nssock" port]</TD></TR>
          <TR VALIGN=TOP><TD CLASS=osswebFormLabel>Uptime:</TD><TD>[ossweb::date uptime [ns_info uptime]]</TD></TR>
          <TR VALIGN=TOP><TD CLASS=osswebFormLabel>OSSWEB:</TD><TD>[ossweb::version]</TD></TR>
          <TR VALIGN=TOP><TD CLASS=osswebFormLabel>Tcl:</TD><TD>$tcl_patchLevel</TD></TR>
          </TABLE>"

    ossweb::widget form_config.add -type submit -name cmd -label Add

    if { [set type_id $type] != "" } {
      if { [ossweb::db::multivalue sql:ossweb.config_types.read] } {
        error "OSS: Invalid config parameter"
      }
      # Update widget parameters
      if { $widget != "" } {
        eval "ossweb::widget form_config.value $widget"
      }

      ossweb::widget form_config.type -value $type_id

      ossweb::widget form_config.name -value $type_id

      ossweb::widget form_config.module -value $module

      ossweb::widget form_config.description -value $description
    }

    if { ![ossweb::conn::check_acl -acl *.*.*.*.*] } {

      ossweb::widget form_config.reboot -type button -label Reboot \
           -confirm "confirm('Reboot the Web server?')" \
           -url [ossweb::html::url cmd reboot]

      ossweb::widget form_config.serverlog -type button -label ServerLog \
           -window Log \
           -winopts "width=800,height=600,menubar=0,location=1,scrollbars=1" \
           -url [ossweb::html::url cmd viewlog size 4096]

      ossweb::widget form_config.accesslog -type button -label AccessLog \
           -window Log \
           -winopts "width=800,height=600,menubar=0,location=1,scrollbars=1" \
           -url [ossweb::html::url cmd viewlog file access size 4096]
    }

}

ossweb::conn::callback create_form_params {} {

    ossweb::db::foreach sql:ossweb.config.list {
      # Do not show sensitive parameters to non-admin
      if { [regexp -nocase {password|passwd|community|secret} $name] } {
        if { [ossweb::conn::check_acl -acl "*.*.*.*.*" ] } { continue }
      }
      set label [ossweb::nvl $type_name $name]
      set name [ossweb::hexify $name]
      append description "&nbsp;&nbsp;" [ossweb::html::link -image trash.gif -alt Delete config cmd delete name $name]
      regsub -all {::} $name {:} name
      eval "ossweb::widget form_params.CFG:$name -label {<B>$label</B>} \
                -value {$value} \
                -section {$module} \
                -info {$description} \
                -optional \
                -resize \
                -freeze \
                -old \
                $widget"
      if { [ossweb::widget form_params.CFG:$name type] == "text" } {
        ossweb::widget form_params.CFG:$name set_attr size 60
      }
    }
    ossweb::widget form_params.update -type submit -name cmd -label Update
}

# Process request parameters
ossweb::conn::process \
           -columns { type "" ""
                      name "" "" } \
           -forms { form_config form_params } \
           -on_error { index.index } \
           -eval {
            add -
            delete -
            reboot -
            update {
              -exec { config_action }
              -next { -cmd_name view }
              -on_error { -cmd_name view }
            }
            viewlog {
              -exec { config_viewlog }
              -on_error { -cmd_name error }
            }
            error {
            }
            default {
              -exec { config_list }
            }
           }
