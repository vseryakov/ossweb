# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback mibs_list {} {

    switch -- $obj_type {
     var - walk - group { set ids [lsort -unique [ns_mib labels .+ VALUE-ASSIGNEMENT]] }
     table { set ids [lsort -unique [ns_mib labels .+ "SEQUENCE OF"]] }
     default { set ids "" }
    }
    ossweb::multirow create oids oid module
    foreach oid $ids {
      ossweb::multirow append oids $oid [ns_mib module $oid]
    }
}

ossweb::conn::callback alert_update {} {

    set alert_count ""
    set alert_time ""
    if { [ossweb::db::exec sql:ossmon.alert.update] } {
      error "OSS: Could not update the status of the alert"
    }
    ossweb::conn::set_msg "The alert status has been changed"
}

ossweb::conn::callback alert_delete {} {

    if { [ossweb::db::exec sql:ossmon.alert.delete]} {
      error "OSS: Could not delete the status of the alert"
    }
    ossweb::conn::set_msg "The alert has been deleted"
    set alert_id ""
}

ossweb::conn::callback property_update {} {

    if { [ossweb::db::exec sql:ossmon.object.property.update] } {
      error "OSS: Could not update the object property"
    }
    if { [ossweb::db::rowcount] == 0 } {
      if { [ossweb::db::exec sql:ossmon.object.property.create] } {
        error "OSS: Could not insert the record"
      }
    }
    ossweb::conn::set_msg "The record has been updated"
}

ossweb::conn::callback property_delete { } {

    if { [ossweb::db::exec sql:ossmon.object.property.delete] } {
      error "OSS: Could not delete the record"
    }
    ossweb::conn::set_msg "The record has been removed"
}

ossweb::conn::callback object_action {} {

    set html ""
    set title ""
    set properties ""
    set name obj:$obj_id

    # Create standard NMS object
    ossmon::object $name -create obj:id $obj_id

    set obj_name [ossmon::object $name obj:name]
    set obj_host [ossmon::object $name obj:host]
    set obj_type [ns_queryget obj_type [ossmon::object $name obj:type]]
    set obj_name [ossweb::html::link -text $obj_name -alt Monitor cmd edit obj_id $obj_id lookup:mode 2]
    set chart_type [ossmon::object $name -info:charts]

    set device_id [ossmon::object $name device:id]
    set device_type [ossmon::object $name device:type]
    set device_name [ossweb::html::link -text $device_name -alt Device devices cmd edit device_id $device_id lookup:mode 2]

    # Common navigator menu
    append html [ossweb::html::link -text Details cmd test obj_id $obj_id chart_date $chart_date lookup:mode 2] " | "

    # Build supported charts links
    foreach type_id $chart_type {
      set type_name [ossmon::chart::get_title $type_id]
      if { $type_id == "collect" && [ossmon::object $name chart:title] != "" } {
        set type_name [ossmon::object $name chart:title]
      }
      append html [ossweb::html::link -text $type_name cmd chart chart_type $type_id obj_id $obj_id chart_date $chart_date start_date $start_date end_date $end_date lookup:mode 2] " | "
    }
    append html "<P>"

    # Command preparation
    switch -- ${ossweb:cmd} {
     chart {
        if { $chart_date != "" } {
          if { [string is integer -strict $chart_date] } {
            set end_date [ossweb::date parse2 $chart_date]
            set start_date [ossweb::date parse2 [expr $chart_date-86400]]
          } else {
            set start_date [ossweb::date parse2 $chart_date]
            set end_date [ossweb::date -set $start_date hours 23 minutes 59 seconds 59]
          }
        } else {
          set chart_date [ossweb::date clock $end_date]
        }
        set chart_type [ns_queryget chart_type [lindex $chart_type 0]]
        if { $chart_type == "collect" } {
          set layer_count 1
        }
        set image [ossmon::chart::exec $obj_id $chart_type \
                     -debug f \
                     -start_date [ossweb::date clock $start_date] \
                     -end_date [ossweb::date clock $end_date] \
                     -hide [ns_queryget hide f] \
                     -layer_count $layer_count \
                     -filter $filter]
        if { $image == "" } {
          append html "<B>No data available<B><P>"
          return
        }
        foreach name $image {
          append html "<CENTER><IMG SRC=$name BORDER=0></CENTER><P>"
        }
        return
     }

     showrun {
        set title "Router/Switch Runtime Config"
        catch { exec /usr/local/ossmon/bin/router.tcl -cmd "{sh run}" -host $obj_host } errmsg
        set html "<PRE>$errmsg</PRE>"
        return
     }

     alert {
        set title [ossmon::object $name info:alert:name]
        append html "<B>[ossmon::object $name info:alert:name] [ossmon::object $name info:alert:time]</B><BR>
                     <PRE>[ossmon::object $name info:alert:data]</PRE>"
        return
     }

     ps {
        append properties " ossmon:snmp:version 1"
        set title "Process List"
        # Process kill request
        set kill [ns_queryget kill]
        set signal [ossweb::nvl [ns_queryget signal] 15]
        if { $kill != "" } {
        }
     }

     tail {
        append properties " ossmon:snmp:version 1"
        set title "File contents info"
        # Set file to be displayed
        append html "
           <FORM ACTION=[ossweb::html::url]>
           <INPUT TYPE=HIDDEN NAME=obj_id VALUE=$obj_id>
           <TABLE WIDTH=100% BORDER=0>
           <TR>
             <TD>[ossweb::html::font -type column_title "File name to display:"]<BR>
                 <SELECT onChange=\"if(this.selectedIndex>0)this.form.file.value=this.options\[this.selectedIndex\].text\">
                 <OPTION>--
                 <OPTION>/var/log/messages
                 <OPTION>/var/log/maillog
                 <OPTION>/var/log/switch/LD-VA-DHCP.log
                 <OPTION>/var/log/switch/BL-VA-DHCP.log
                 <OPTION>/var/log/dco/dco-[ns_fmttime [ns_time] "%Y-%m"].log
                 <OPTION>/var/log/cdr/cdr-[ns_fmttime [ns_time] "%Y-%m"].log
                 <OPTION>/usr/local/snmp/logs/snmpmgr.log
                 </SELECT><BR>
                 <INPUT TYPE=TEXT NAME=file SIZE=30>
             </TD>
             <TD>[ossweb::html::font -type column_title "Substring(optional):"]<BR><INPUT TYPE=TEXT NAME=str></TD>
             <TD>[ossweb::html::font -type column_title "Lines to display:"]<BR><INPUT TYPE=TEXT NAME=lines></TD>
             <TD><INPUT TYPE=SUBMIT NAME=cmd VALUE=Tail CLASS=ossButton></TD>
           </TR>
           </TABLE>
           </FORM>
           <HR>"
        if { [ns_queryget file] == "" } {
          return
        }
     }

     netstat {
        append properties " ossmon:snmp:version 1"
        set title "Netstat info"
     }

     fix {
        set obj_type prTable
        set title "Process Request"
        set obj_url "prErrFixCmd [ossweb::html::url cmd fix obj_id $obj_id]"
        set obj_html "prErrFixCmd {onClick=\"return confirm('Fix process?')\"}"
     }

     default {
        set obj_url ""
        set obj_html ""
        switch $obj_type {
         prTable {
           set title "Process Request"
           set obj_url "prErrFixCmd [ossweb::html::url cmd fix obj_id $obj_id]"
           set obj_html "prErrFixCmd {onClick=\"return confirm('Fix process?')\"}"
         }
         dskTable {
           set title "Disk Status Request"
         }
         laTable {
           set title "Load Status Request"
         }
         default {
           set title "[ossweb::nvl [ossmon::object::get_title $obj_type] "SNMP"] Request"
         }
        }
     }
    }

    # Update with custom properties and type
    foreach { key val } $properties {
      ossmon::object $name -set $key $val
    }
    ossmon::object $name -set obj:type $obj_type
    # Run create again to re-initialize objec to new type
    ossmon::object $name -setup

    if { [catch { set rc [ossmon::object $name -init] } errmsg] } {
      ossmon::object $name -set ossmon:status $errmsg
      set rc -1
    }
    if { $rc == -1 } {
      append html [ossweb::html::font -color red [ossmon::object $name ossmon:status]]
      ossmon::object $name -close
      return
    }

    # Command action execution
    switch -- ${ossweb:cmd} {
     fix {
        if { [ossmon::object::snmp::update $name prErrFix.[ns_queryget index] i 1] } {
          ns_log Error ossmon_objects: $name: [ossmon::object $name obj:status]: [ns_queryget prErrFixCmd]
        }
        ns_sleep 3
        set ossweb:cmd test
        ossweb::conn::set_msg "Process has been fixed"
     }
    }
    set fd [ossmon::object $name snmp:fd]

    # Command output generation
    switch -- ${ossweb:cmd} {
     ps {
        append html "<PRE>"
        if { [catch {
          ns_snmp walk $fd [ns_mib oid psTable].101 var {
            append html [lindex $var 2] "<BR>"
          }
        } errmsg] } {
          append html [ossweb::html::font -color red $errmsg]
          append html "<P><H3>Object Dump</H3><P>" [ossmon::object $name -dump -sep "<BR>"]
          ossmon::object $name -close
          return
        }
        append html "</PRE>"
     }

     netstat {
        append html "<PRE>"
        if { [catch {
          ns_snmp walk $fd [ns_mib oid netstatTable].101 var {
            append html [lindex $var 2] "<BR>"
          }
        } errmsg] } {
          set html [ossweb::html::font -color red $errmsg]
          append html "<P><H3>Object Dump</H3><P>" [ossmon::object $name -dump -sep "<BR>"]
          ossmon::object $name -close
          return
        }
        append html "</PRE>"
     }

     tail {
        append html "<PRE>"
        if { [catch {
            ns_snmp set $fd [ns_mib oid tailFile] s "[ns_queryget file]|[ns_queryget lines]|[ns_queryget str]"
            ns_snmp walk $fd [ns_mib oid tailTable].101 var {
              append html [lindex $var 2] "<BR>"
            }
        } errmsg] } {
          append html [ossweb::html::font -color red $errmsg]
          append html "<P><H3>Object Dump</H3><P>" [ossmon::object $name -dump -sep "<BR>"]
          ossmon::object $name -close
          return
        }
        append html "</PRE>"
     }

     default {
        if { [catch { set rc [ossmon::object $name -poll] } errmsg] } {
          ossmon::object $name -set ossmon:status $errmsg
          set rc -1
        }
        if { $rc == -1 } {
          append html [ossweb::html::font -color red [ossmon::object $name ossmon:status]]
          append html "<P><H3>Object Dump</H3><P>" [ossmon::object $name -dump -sep "<BR>"]
          ossmon::object $name -close
          return
        }
        append html [ossmon::object::get_html $name -url $obj_url -html $obj_html]
     }
    }
    ossmon::object $name -close
}

ossweb::conn::callback object_clear {} {

    switch -- ${ossweb:ctx} {
     alert {
      if { [ossweb::db::exec sql:ossmon.object.clear]} {
        error "OSS: Could not clear the status of the alert"
      }
      ossweb::conn::set_msg "Alerts have been cleared"
     }

     chart {
       file delete -force [ns_info home]/modules/charts/$obj_id:1.png
       ossweb::conn::set_msg "Charts have been cleared"
     }
    }
}

ossweb::conn::callback object_copy {} {

    ossweb::db::begin
    set new_obj_id [ossweb::db::nextval ossmon_object]
    if { [ossweb::db::exec sql:ossmon.object.copy] ||
         [ossweb::db::exec sql:ossmon.object.copy.properties] } {
      error "OSS: Could not copy the object"
    }
    set obj_id $new_obj_id
    ossweb::db::commit
}

ossweb::conn::callback object_update {} {

    ossweb::db::begin
    # Try to discover object's IP address
    if { $obj_host == "" } {
      set obj_host [ossweb::db::value sql:ossmon.device.ipaddr]
      if { $obj_host == "" } {
        error "OSS: Unable to determine device's IP Address"
      }
    }
    if { $obj_id == "" } {
      if { [ossweb::db::exec sql:ossmon.object.create] } {
        set obj_id ""
        error "OSS: Could not insert the object"
      }
      set obj_id [ossweb::db::currval ossmon_object]
    } else {
      if { [ossweb::db::exec sql:ossmon.object.update] } {
        error "OSS: Could not update the object"
      }
    }
    # Update required properties
    set delete_list ""
    foreach item [ossweb::conn::query -return t -match PROP:*] {
      foreach { property_id value } $item {}
      set property_id [string range $property_id 5 end]
      # Remove empty properties
      if { $value == "" } {
        lappend delete_list $property_id
        continue
      }
      # Update or create new properties
      if { [ossweb::db::exec sql:ossmon.object.property.update] } {
        error "OSS: Could not update the object property"
      }
      if { [ossweb::db::rowcount] == 0 } {
        if { [ossweb::db::exec sql:ossmon.object.property.create] } {
          error "OSS: Could not insert the record"
        }
      }
    }
    if { $delete_list != "" } {
      set property_id $delete_list
      if { [ossweb::db::exec sql:ossmon.object.property.delete] } {
        error "OSS: Could not delete empty properties"
      }
    }
    ossweb::db::commit
    # Flush caches
    ossmon::object obj -create obj:id $obj_id
    ossmon::object::flush_cache obj
    ossweb::sql::multipage objects -flush t -cache ossmon:list
    ossweb::conn::set_msg "The object has been updated"
}

ossweb::conn::callback object_delete {} {

    ossweb::db::begin
    if { [ossweb::db::multivalue sql:ossmon.object.read] } {
      error "OSS: Unable to read object with id $obj_id"
    }
    if { [ossweb::db::exec sql:ossmon.object.property.delete] ||
         [ossweb::db::exec sql:ossmon.object.delete] } {
      error "OSS: Could not delete the object"
    }
    ossweb::db::commit
    ossweb::sql::multipage objects -flush t -cache ossmon:list
    ossweb::conn::set_msg "The object has been removed"
}

ossweb::conn::callback object_edit {} {

    if { $obj_id == "" } {
      if { $device_id != "" && $device_name == "" } {
        set device_name [ossweb::db::value sql:ossmon.device.name]
      }
      # Add required properties to the form according to object type
      ossmon::object obj -create obj:type [ossweb::nvl $obj_type snmp]
      foreach property [ossmon::object::get_property obj property:list -all t] {
        foreach { _property_id _property_name _description _widget } $property {}

        eval "ossweb::widget form_object.PROP:$_property_id -info {} $_widget \
                   -label {$_property_name} \
                   -optional \
                   -empty -- \
                   -labelhelp {$_description}"

         # Update info with help link
         ossweb::widget form_object.PROP:$_property_id \
              -info "[ossweb::widget form_object.PROP:$_property_id info]
                     [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#$_property_id')"]"

      }
      ossweb::form form_object set_values
      return
    }
    # Read exiting record
    if { [ossweb::db::multivalue sql:ossmon.object.read] } {
      error "OSS: Unable to read object with id $obj_id"
    }
    set obj_type [ns_queryget obj_type $obj_type]
    set device_name [ossweb::lookup::link -text "$device_name/ $location_name" devices cmd edit device_id $device_id]
    set device_icon [ossmon::object::get_icon $obj_type $device_vendor $device_type]

    # Create dummy object without reading record from database
    ossmon::object obj -create obj:type $obj_type
    foreach { key val } $obj_properties {
      ossmon::object obj -set $key $val
    }

    # Build object's supported charts list
    set chart_options ""
    foreach chart [ossmon::object obj -info:charts] {
      set title [ossmon::chart::get_title $chart]
      if { $chart == "collect" } {
        set title [ossmon::object obj chart:title -default $title]
      }
      lappend chart_options [list $title $chart]
    }

    # Parent link
    if { $obj_parent != "" } {
      set obj_parent_name [ossweb::lookup::link -text $obj_parent_name cmd edit obj_id $obj_parent]
    }
    # Last status info with link to last alert text
    if { $poll_time != "" } {
      append poll_time " " $obj_stats "&nbsp; [ossweb::lookup::link -image alert.gif -alt Alert -window Obj -winopts $winopts cmd alert obj_id $obj_id]"
    }
    if { $alert_count > 0 } {
      set alert_time "<FONT COLOR=red>$alert_time,<BR>$alert_name ($alert_type/$alert_level)</FONT></B>"
    }

    # Add required properties to the form according to object type
    foreach rec [ossmon::object::get_property obj property:list -all t] {
      foreach { _property_id _property_name _description _widget } $rec {}

      eval "ossweb::widget form_object.PROP:$_property_id \
                 -label {$_property_name} \
                 -value {[ossmon::object obj $_property_id]} \
                 -optional \
                 -empty -- \
                 -labelhelp {$_description} \
                 $_widget"

       # Update info with help link
       ossweb::widget form_object.PROP:$_property_id \
            -info "[ossweb::widget form_object.PROP:$_property_id info]
                   [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#$_property_id')"]"
    }

    switch -- $tab {
     edit {
       ossweb::widget form_object.test -type button -label "Test" -leftside \
            -html { onClick doTest(this.form) }

       # Build tools popup button
       set tools [list \
          [list Ping "" "var w=window.open('[ossweb::conn::hostname]/cgi-bin/ping?$obj_host','Obj','$winopts');w.focus();return false"] \
          [list Traceroute "" "var w=window.open('[ossweb::conn::hostname]/cgi-bin/traceroute?$obj_host','Obj','$winopts');w.focus();return false"]]

       if { $device_type == "Unix" } {
         lappend tools \
            [list ProcTable "" "var w=window.open('[ossweb::html::url cmd test obj_id $obj_id obj_type prTable]','Obj','$winopts');w.focus();return false"] \
            [list DiskTable "" "var w=window.open('[ossweb::html::url cmd test obj_id $obj_id obj_type dskTable]','Obj','$winopts');w.focus();return false"] \
            [list LoadTable "" "var w=window.open('[ossweb::html::url cmd test obj_id $obj_id obj_type laTable]','Obj','$winopts');w.focus();return false"] \
            [list Processes "" "var w=window.open('[ossweb::html::url cmd ps obj_id $obj_id]','Obj','$winopts');w.focus();return false"] \
            [list Netstat "" "var w=window.open('[ossweb::html::url cmd netstat obj_id $obj_id]','Obj','$winopts');w.focus();return false"] \
            [list LogFile "" "var w=window.open('[ossweb::html::url cmd tail obj_id $obj_id]','Obj','$winopts');w.focus();return false"]
       }
       if { $device_type == "Router" || $device_type == "Switch" } {
         lappend tools [list ShowRun "" "var w=window.open('[ossweb::html::url cmd showrun obj_id $obj_id]','Obj','$winopts');w.focus();return false"]
       }
       ossweb::widget form_object.tools -type popupbutton -label "Tools..." -leftside \
            -options $tools

       # Add quick chart button
       if { $charts_flag != "" } {
         ossweb::widget form_object.chart -type button -label Chart \
              -window Chart \
              -winopts $winopts \
              -leftside \
              -url [ossweb::html::url cmd chart obj_id $obj_id chart_type $charts_flag chart_date [ns_time] lookup:mode 2]
       }
     }

     property {
       ossweb::widget form_property.property \
            -options [ossmon::object::get_property obj property:options -all t -base t] \
            -value $property_id

       if { $property_id != "" } {
         set value [ossweb::db::value sql:ossmon.object.property.read]
         set rec [ossmon::object::get_property obj $property_id -base t]

         ossweb::widget form_property.value destroy
         eval ossweb::widget form_property.value -type text \
                   -label "{[lindex $rec 1]}" \
                   -value "{[ossmon::object obj $property_id]}" \
                   -optional \
                   -empty -- \
                   -freeze \
                   [lindex $rec end]

         ossweb::widget form_property.value \
               -info "[ossweb::widget form_property.value info]
                      [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#$property_id')"]"
       }
       ossweb::form form_property set_values
       ossweb::db::multirow properties sql:ossmon.object.property.list -eval {
          set row(edit) [ossweb::lookup::link -image trash.gif -alt Remove cmd delete.property obj_id $obj_id property_id $row(property_id)]
          set title [ossmon::object::get_property obj $row(property_id) -column title -base t -global t]
          set help [ossmon::object::get_property obj $row(property_id) -column descr -base t -global t]
          if { $title != "" } {
            set row(property_id) "$title <FONT COLOR=gray TITLE=\"$help\">($row(property_id))</FONT>"
          }
       }
     }

     chart {
       set chart_url [ossweb::lookup::url cmd edit obj_id $obj_id tab chart]
       ossweb::widget form_chart.chart_type -options $chart_options
       ossweb::form form_chart set_values
     }

     alert {
       set alert_id [ns_queryget alert_id]
       if { $alert_id == "" } {
         ossweb::db::multirow alerts sql:ossmon.object.alert.list -replace_null "&nbsp;" -eval {
           set row(alert_name) [ossweb::lookup::link -text $row(alert_name) cmd edit obj_id $obj_id alert_id $row(alert_id) alert_status $row(alert_status) tab alert]
         }
         ossweb::widget form_alert.alert_status -type select -label "Alert Status" \
              -empty " --" \
              -options $status_list \
              -html [list onChange "window.location='[ossweb::lookup::url cmd edit obj_id $obj_id tab alert alert_status ""]'+this.options\[this.selectedIndex\].value"]
       } else {
         set alert_status ""
         if { [ossweb::db::multivalue sql:ossmon.object.alert.list] } {
           error "OSS: Invalid information received by the system"
         }
         set alert_object $obj_id
         set alert_name "$obj_type - $alert_name"
         ossweb::db::multirow properties sql:ossmon.alert.property.read_all
         ossweb::db::multipage log \
              sql:ossmon.alert.log.search1 \
              sql:ossmon.alert.log.search2 \
              -page $page \
              -pagesize 5 \
              -cmd_name edit \
              -query "obj_id=$obj_id&alert_id=$alert_id&tab=alert"
       }
       ossweb::form form_alert set_values
     }
    }
    ossweb::widget form_object.charts_flag -options $chart_options
    ossweb::form form_object set_values
    if { $tab != "edit" } {
      ossweb::form form_object readonly -null ""
    }
    ossweb::widget form_object.list -type button -label Back \
         -url [ossweb::lookup::url devices cmd edit device_id $device_id]
}

ossweb::conn::callback object_init {} {

    set lookup_mode [ossweb::lookup::mode]
}

ossweb::conn::callback create_form_tab {} {

    set url [ossweb::lookup::url cmd edit obj_id $obj_id]
    ossweb::widget form_tab.edit -type link -label Details -value $url
    ossweb::widget form_tab.property -type link -label Properties -value $url
    ossweb::widget form_tab.chart -type link -label Charts -value $url
    ossweb::widget form_tab.alert -type link -label Alerts -value $url
}

ossweb::conn::callback create_form_view {} {

    ossweb::lookup::form form_view
    ossweb::widget form_view.cmd -type hidden -value search -freeze
    ossweb::widget form_view.obj_name -label Name \
         -optional
    ossweb::widget form_view.obj_host -label Host \
         -optional
    ossweb::widget form_view.obj_type -type multiselect -label Type \
         -optional \
         -empty -- \
         -html { size 3 } \
         -options [ossmon::object::get_types]
    ossweb::widget form_view.show_disable -type checkbox -label "Show Disabled" \
         -optional \
         -value t
    ossweb::widget form_view.search -type submit -label Search
    ossweb::widget form_view.add -type button -label New \
         -url [ossweb::lookup::url cmd edit]
    ossweb::widget form_view.reset -type reset -label Reset -clear
}

ossweb::conn::callback create_form_object {} {

    ossweb::lookup::form form_object
    ossweb::form form_object -title "OSSMON Object Details #$obj_id"
    ossweb::widget form_object.cmd -type hidden -optional
    ossweb::widget form_object.tab -type hidden -optional
    ossweb::widget form_object.page -type hidden -optional
    ossweb::widget form_object.obj_id -type hidden -optional
    ossweb::widget form_object.device_id -type hidden -optional
    ossweb::widget form_object.poll_time -type label -label "Last Poll" \
         -nohidden

    ossweb::widget form_object.alert_time -type label -label "Alert Info" \
         -nohidden

    ossweb::widget form_object.obj_host -type text -label "IP Address" \
         -html { size 15 } \
         -info [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#obj:host')"] \
         -optional

    ossweb::widget form_object.obj_name -type text -label Name \
         -optional \
         -info [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#obj:name')"]

    ossweb::widget form_object.obj_type -type select -label Type \
         -empty -- \
         -info [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#obj:type')"] \
         -options [ossmon::object::get_types] \
         -html { onChange "changeForm(this.form)" }

    ossweb::widget form_object.charts_flag -type select -label "Realtime Charts" \
         -empty -- \
         -info [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#obj:charts')"] \
         -optional

    ossweb::widget form_object.disable_flag -type boolean -label Disabled \
         -info [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#obj:disabled')"]

    ossweb::widget form_object.priority -type text -label Priority \
         -datatype integer \
         -info [ossweb::html::link -image help.gif -url "javascript:helpWin('doc/manual.html#obj:priority')"] \
         -optional \
         -html { size 3 }

    ossweb::widget form_object.description -type textarea -label Description \
         -html { rows 2 cols 40 } -optional

    ossweb::widget form_object.update -type button -label "Update" -cmd_name update

    ossweb::widget form_object.delete -type button -label "Delete" \
         -eval { if { $obj_id == "" } break } \
         -confirm "confirm('Are you sure?')" \
         -url [ossweb::lookup::url cmd delete obj_id $obj_id]

    ossweb::widget form_object.copy -type button -label "Copy" \
         -eval { if { $obj_id == "" } break } \
         -url [ossweb::lookup::url cmd copy obj_id $obj_id] \
         -confirm "confirm('Object will be copied, continue?')"

    ossweb::widget form_object.clear -type popupbutton -label "Clear..." \
         -eval { if { $obj_id == "" } break } \
         -options [list [list Alerts [ossweb::lookup::url cmd clear.alert obj_id $obj_id] "return confirm('Last Alert status will be cleared, continue?')"] \
                        [list Charts [ossweb::lookup::url cmd clear.chart obj_id $obj_id] "return confirm('Clear Realtime charts from the console?')"] ]

    ossweb::widget form_object.help -type helpbutton -url doc/manual.html#t14
}

ossweb::conn::callback create_form_chart { } {

    ossweb::lookup::form form_chart
    ossweb::widget form_chart.obj_id -type hidden
    ossweb::widget form_chart.obj_host -type hidden
    ossweb::widget form_chart.tab -type hidden -optional
    ossweb::widget form_chart.chart_date -type hidden -optional
    ossweb::widget form_chart.chart_type -type select -label "Type"
    ossweb::widget form_chart.start_date -type date -datatype date \
         -format "DD MONTH YYYY HH24 MI" -label "Start Date" \
         -calendar
    ossweb::widget form_chart.end_date -type date -datatype date \
         -format "DD MONTH YYYY HH24 MI" -label "End Date" \
         -calendar \
         -optional
    ossweb::widget form_chart.filter -type text -label "Filter" -optional
    ossweb::widget form_chart.trend -type checkbox -label "Trends" \
         -optional \
         -value t
    ossweb::widget form_chart.hide -type checkbox -label "Hide Specifics" \
         -optional \
         -value t
    ossweb::widget form_chart.chart -type button -label Chart \
         -html { onClick chartSubmit(this.form,'') }
}

ossweb::conn::callback create_form_property {} {

    ossweb::lookup::form form_property
    ossweb::widget form_property.obj_id -type hidden
    ossweb::widget form_property.tab -type hidden -optional
    ossweb::widget form_property.ctx -type hidden -value property -freeze
    ossweb::widget form_property.property_id -type text -label "Property"
    ossweb::widget form_property.property -type select -optional \
         -empty "--" \
         -html { onChange setProp(this) }
    ossweb::widget form_property.value -type text -label "Value"
    ossweb::widget form_property.add -type submit -name cmd -label "Add"
}

ossweb::conn::callback create_form_alert {} {

    ossweb::lookup::form form_alert
    ossweb::form form_alert -title "Alert Info"
    if { $alert_id != "" } {
      ossweb::widget form_alert.alert_id -type hidden
      ossweb::widget form_alert.tab -type hidden -optional
      ossweb::widget form_alert.alert_status -type label -label "Status" -nohidden
      ossweb::widget form_alert.alert_name -type label -label "Name" -nohidden
      ossweb::widget form_alert.alert_type -type label -label "Type" -nohidden
      ossweb::widget form_alert.alert_level -type label -label "Level" -nohidden
      ossweb::widget form_alert.create_time -type label -label "Created" -nohidden
      ossweb::widget form_alert.update_time -type label -label "Last Updated" -nohidden
      ossweb::widget form_alert.alert_time -type label -label "Last Alert" -nohidden
      ossweb::widget form_alert.alert_count -type label -label "Count" -nohidden
      ossweb::widget form_alert.back -type button -label "Back" \
           -url [ossweb::lookup::url cmd edit obj_id $obj_id tab alert alert_status $alert_status]
      ossweb::widget form_alert.update -name cmd -type popupbutton -label "Change To..." \
           -options [list [list Active [ossweb::lookup::url cmd update.alert obj_id $obj_id alert_id $alert_id alert_status active tab alert]] \
                          [list Closed [ossweb::lookup::url cmd update.alert obj_id $obj_id alert_id $alert_id alert_status closed tab alert]] \
                          [list Pending [ossweb::lookup::url cmd update.alert obj_id $obj_id alert_id $alert_id alert_status pending tab alert]]]
      ossweb::widget form_alert.delete -name cmd -type button -label "Delete" \
           -confirm "confirm('Are you sure?')" \
           -url [ossweb::lookup::url cmd delete.alert obj_id $obj_id alert_id $alert_id tab alert]
    }
}

# Table/form columns
set columns { obj_id int ""
              obj_host "" ""
              obj_name "" ""
              obj_type "" ""
              device_id "" ""
              device_name "" ""
              device_icon "" ""
              location_name "" ""
              property_id "" ""
              chart_type "" ""
              chart_image "" ""
              chart_date "" ""
              alert_id int ""
              alert_status "" Active
              alert_count const 0
              filter "" ""
              tab "" edit
              page "" 1
              layer_count int 2
              pagesize const 999
              force const f
              lookup_mode const 0
              status_list const { { Active Active } { Closed Closed } { Pending Pending } }
              winopts const "menubar=0,width=800,height=600,location=0,scrollbars=1,resizable=1"
              start_date "" {[ossweb::date parse [ns_fmttime [ns_time] "%Y-%m-%d 0:0"]]}
              end_date "" {[ossweb::date now]}
              alert_sound const {[ossweb::config ossmon:alert:sound]} }

ossweb::conn::process -columns $columns \
           -forms { form_object form_tab form_property form_chart form_alert } \
           -form_recreate t \
           -on_error { index.index } \
           -exec { object_init } \
           -eval {
             add.property {
              -exec { property_update }
              -on_error { -cmd_name edit tab property }
              -next { -cmd_name edit tab property }
             }
             delete.property {
              -exec { property_delete }
              -on_error { -cmd_name edit tab property }
              -next { -cmd_name edit tab property }
             }
             update.property {
              -exec { property_update }
              -on_error { -cmd_name edit tab property }
              -next { -cmd_name edit tab property }
             }
             delete.alert {
              -exec { alert_delete }
              -on_error { -cmd_name edit tab alert }
              -next { -cmd_name edit tab alert }
             }
             update.alert {
              -exec { alert_update }
              -on_error { -cmd_name edit tab alert }
              -next { -cmd_name edit tab alert }
             }
             update {
              -exec { object_update }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             copy {
              -exec { object_copy }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             clear {
              -exec { object_clear }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             delete {
              -exec { object_delete }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit devices tab objects }
             }
             master -
             edit {
              -exec { object_edit }
              -on_error { -cmd_name view }
             }
             test -
             config -
             showrun -
             alert -
             test -
             netstat -
             chart -
             tail -
             fix -
             ps {
              -validate { { obj_id int } }
              -exec { object_action }
              -on_error { -cmd_name error }
             }
             mibs {
              -exec { mibs_list }
              -on_error { -cmd_name error }
             }
             error {
             }
             edit -
             default {
              -exec { object_edit }
             }
           }
