# Author: Vlad Seryakov vlad@crystalballinc.com
# May 2002

# Contact management namespace
namespace eval contact {
  variable version {Contacts version 3.2 $Revision: 3419 $}

  namespace eval location {}
  namespace eval address {}
  namespace eval schedule {}
  namespace eval company {}
  namespace eval people {
    namespace eval send {}
  }
}

# Link to contacts from the toolbar
proc ossweb::html::toolbar::people {} {

    if { [ossweb::conn::check_acl -acl *.contact.people.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/people.gif -mouseover /img/toolbar/people_o.gif -status People -alt People -app_name contact people]
}

# Extend user admin screen
proc ossweb::control::user::contact { type user_id args } {

    switch -- $type {
     tab {
       set isAllowed [ossweb::lexists [ossweb::db::columns ossweb_users] contact_companies]
       if { $isAllowed != "" } {
         ossweb::widget form_tab.contact -type link -label Contact -value $args
       }
     }

     form {
       ossweb::form form_prefs -title "User Contact Settings"
       ossweb::widget form_prefs.contact_companies -type multiselect -label "Companies the user has access to:" \
            -optional \
            -sql sql:company.select.list
       ossweb::widget form_prefs.contact_people -type multiselect -label "People the user has access to:" \
            -optional \
            -sql sql:people.select.list
     }

     save {
       if { [ossweb::admin::update_user -user_id $user_id \
                  contact_companies [ns_querygetall contact_companies NULL] \
                  contact_people [ns_querygetall contact_people NULL]] } {
         error "OSSWEB: Error occured during updating preferences"
       }
     }
    }
}

# Company lookup widget
proc ossweb::widget::company_lookup { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     readonly {
       set widget(type) label
       return 1
     }
     create {
       set widget(title_name) [regsub {_id$} $widget(name) {}]_name
       set widget(search_name) company_name
       set widget(mode) 2
       set widget(map) "$widget(form:id).$widget(name) company_id $widget(form:id).$widget(title_name) company_name"
       set widget(url) [eval ossweb::html::url -app_name contact companies cmd search [ossweb::coalesce widget(url_params)]]
       if { [ossweb::coalesce widget(autocomplete)] == 1 } {
         set widget(autocomplete) [ossweb::html::url -app_name contact companies cmd ac company_name ""]
         set widget(autocomplete_value) $widget(name)
       }
     }
    }
    return [uplevel ossweb::widget::lookup widget $command $args]
}

# People lookup widget
proc ossweb::widget::people_lookup { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {
     create {
       set widget(title_name) [regsub {_id$} $widget(name) {}]_name
       set widget(mode) 2
       set widget(map) "$widget(form:id).$widget(name)_id people_id $widget(form:id).$widget(title_name) name"
       set widget(url) [eval ossweb::html::url -app_name contact people cmd search [ossweb::coalesce widget(url_params)]]
     }
     readonly {
       set widget(type) label
       return 1
     }
    }
    return [uplevel ossweb::widget::lookup widget $command $args]
}

# Postal address widget
proc ossweb::widget::address { widget_id command args } {

    upvar $widget_id widget

    switch -exact $command {

     create {
       ossweb::html::include /js/ac.js
     }

     readonly {
       return 1
     }

     get_value {
       ns_parseargs { {-level {[expr [info level]-2}]} {-array ""} } $args

       set name_prefix [ossweb::coalesce widget(name_prefix)]
       foreach name "$widget(name) number street street_type unit_type unit city
                      state zip_code country location_name location_type
                      address_notes longitude latitude" {
         upvar #$level $name_prefix$name value
         set value [ns_queryget $name_prefix$name]
       }
       return 1
     }

     validate {
       set errmsg ""
       set required ""
       set name_prefix [ossweb::coalesce widget(name_prefix)]
       set $widget(name) [ns_queryget ${name_prefix}$widget(name)]
       set optional [ossweb::coalesce widget(optional) 0]
       set street_type [ns_queryget ${name_prefix}street_type]
       # To make happy global validation routine
       set widget(optional) 1
       # Nothing to verify
       if { $optional } { return }
       # List of required fields
       if { [ns_queryexists ${name_prefix}street] } {
         # Postal address validation
         lappend required number city
         # Street types that do not require street names
         switch -- $street_type {
          "PO BOX" {}
          default {
            lappend required street
          }
         }
         # Verify street type as well
         if { [ossweb::coalesce widget(street_type) 1] > 0 } {
           lappend required street_type
         }
       } elseif { [ns_queryexists ${name_prefix}location_name] } {
         # Location validation
         lappend required location_name location_type
       }
       foreach name $required {
         set value [ns_queryget ${name_prefix}$name]
         if { $value == "" } {
           append errmsg "[string totitle $name]: cannot be empty<BR>"
         }
       }
       return $errmsg
     }

     html {
       set output ""
       set name_prefix [ossweb::coalesce widget(name_prefix)]
       upvar #[ossweb::adp::Level] \
                    ${name_prefix}$widget(name) address_id \
                    ${name_prefix}number number \
                    ${name_prefix}street street \
                    ${name_prefix}street_type street_type \
                    ${name_prefix}unit_type unit_type \
                    ${name_prefix}unit unit \
                    ${name_prefix}city city \
                    ${name_prefix}state state \
                    ${name_prefix}zip_code zip_code \
                    ${name_prefix}country country \
                    ${name_prefix}latitude latitude \
                    ${name_prefix}longitude longitude \
                    ${name_prefix}location_type location_type \
                    ${name_prefix}location_name location_name  \
                    ${name_prefix}address_notes address_notes

       # Read only widget
       if { [info exists widget(readonly)] } {
         if { [ossweb::coalesce location_name] != "" } {
           append output "[ossweb::coalesce location_name]([ossweb::coalesce location_type])<BR>"
         }
         if { [ossweb::coalesce number] != "" } {
           append output "[ossweb::coalesce number] [ossweb::coalesce street] [ossweb::coalesce street_type]"
         }
         if { [ossweb::coalesce unit] != "" } {
           append output "<BR>[ossweb::coalesce unit_type] [ossweb::coalesce unit]"
         }
         if { [ossweb::coalesce city] != "" } {
           append output "<BR>[ossweb::coalesce city] [ossweb::coalesce state] [ossweb::coalesce zip_code]"
         }
         if { [ossweb::coalesce country] != "" } {
           append output " [ossweb::coalesce country]"
         }
         if { [ossweb::coalesce address_notes] != "" } {
           append output "<BR>[ossweb::coalesce address_notes]"
         }
         return $output
       }
       set class [ossweb::coalesce class osswebAddressLabel]
       set iclass [ossweb::coalesce input_class osswebAddressInput]
       set sclass [ossweb::coalesce select_class osswebAddressSelect]
       set bclass [ossweb::coalesce button_class osswebTextButton]
       # Lookup mapping
       set map [list $widget(form:id).${name_prefix}$widget(name) address_id \
                     $widget(form:id).${name_prefix}number number \
                     $widget(form:id).${name_prefix}street street \
                     $widget(form:id).${name_prefix}street_type street_type \
                     $widget(form:id).${name_prefix}unit unit \
                     $widget(form:id).${name_prefix}unit_type unit_type \
                     $widget(form:id).${name_prefix}city city \
                     $widget(form:id).${name_prefix}state state \
                     $widget(form:id).${name_prefix}zip_code zip_code \
                     $widget(form:id).${name_prefix}country country \
                     $widget(form:id).${name_prefix}address_notes address_notes \
                     $widget(form:id).${name_prefix}latitude latitude \
                     $widget(form:id).${name_prefix}longitude longitude \
                     $widget(form:id).${name_prefix}location_name location_name \
                     $widget(form:id).${name_prefix}location_type location_type]

       # Use address fieleds
       set use_address [ossweb::decode [info exists widget(noaddress)] 1 0 1]
       set use_gps [info exists widget(gps)]
       # Use description
       if { [set use_descr [ossweb::coalesce widget(descr) 0]] > 0 } {
         set location_types [ossweb::db::multilist sql:ossweb.location.type.list.select -cache ADDR:LT]
         set location_types [linsert $location_types 0 { "--" ""}]
         set name_html [ossweb::coalesce widget(name_html)]
         ossweb::widget l.n -type text -name ${name_prefix}location_name -class $iclass \
              -size [ossweb::coalesce size_name 25] \
              -value [ossweb::coalesce location_name]
         if { [info exists widget(autocomplete_name)] } {
           ossweb::widget l.n \
                -autocomplete [ossweb::html::url -app_name contact address cmd ac location_name ""] \
                -autocomplete_proc "function(o,v){o.value=v.location_name;formAddressGet(o.form,'[ossweb::html::url -app_name contact address cmd ac.a address_id ""]'+v.value,'$widget(name)','$name_prefix')}"
         }
       }

       if { $use_address } {
         # Use buttons for search, map, ...
         set use_icons [info exists widget(icons)]
         set use_buttons [ossweb::decode [info exists widget(nobuttons)] 1 0 1]

         ossweb::widget l.s -type text -name ${name_prefix}street \
              -class $iclass \
              -size 20 \
              -value [ossweb::coalesce street]

         if { [info exists widget(autocomplete_street)] } {
           ossweb::widget l.s -autocomplete [ossweb::html::url -app_name contact address cmd ac.s street ""]
         }

         # City
         ossweb::widget l.c -type text -name ${name_prefix}city \
              -class $iclass \
              -size 20 \
              -value [ossweb::coalesce city]

         if { [info exists widget(autocomplete_city)] } {
           ossweb::widget l.c -autocomplete [ossweb::html::url -app_name contact address cmd ac.c city ""]
         }

         # Use street types in the widget
         if { [set use_street_type [ossweb::coalesce widget(street_type) 1]] > 0 } {
           set street_types [ossweb::db::multilist sql:ossweb.address.street.type.list.select -cache ADDR:ST]
           set street_types [linsert $street_types 0 { "--" ""}]
         }

         # Use unit types in the widget
         if { [set use_unit [ossweb::coalesce widget(unit) 1]] > 0 } {
           set unit_types [ossweb::db::multilist sql:ossweb.address.unit.list.select -cache ADDR:UT]
           set unit_types [linsert $unit_types 0 { "--" ""}]
         }

         # States
         ossweb::widget l.t -type select -name ${name_prefix}state \
              -class $sclass \
              -empty -- \
              -value [ossweb::coalesce state] \
              -sql sql:ossweb.address.state.list.select \
              -sql_cache ADDR:S

         # Use country in the widget
         if { [set use_country [ossweb::coalesce widget(country) 0]] > 0 } {
           set countries [ossweb::db::multilist sql:ossweb.address.country.list.select -cache ADDR:C]
           set countries [linsert $countries 0 { "--" ""}]
         }
       }

       # Use notes
       if { [info exists widget(notes)] } {
         ossweb::widget l.o -type textarea -name ${name_prefix}address_notes \
              -class $iclass \
              -resize \
              -cols 45 \
              -rows 2 \
              -value [ossweb::coalesce address_notes]
       }
       # Build lookup url, by default separate window
       set mode [ossweb::coalesce widget(mode) 2]
       set url [ossweb::html::url -app_name contact address \
                  cmd lookup \
                  lookup:mode $mode \
                  lookup:return [ossweb::coalesce widget(return)] \
                  lookup:map $map]
       switch $mode {
        2 {
            set url "var w=window.open('$url'+formAddressQuery(document.$widget(form:id),'$name_prefix'),'Lookup$widget(name)','[ossweb::lookup::property winopts]');w.focus()"
        }
        default {
            set url "window.location='$url'+formAddressQuery(document.$widget(form:id),'$name_prefix')"
        }
       }
       # Assign global javascript handlers to all fields
       set g_js [list]
       if { [info exists widget(jsglobal)] } {
         foreach { k v } $widget(html) {
           if { [string match on* $k] } {
             lappend g_js $k $v
             ossweb::widget l.n -$k $v
             ossweb::widget l.s -$k $v
             ossweb::widget l.c -$k $v
             ossweb::widget l.o -$k $v
             ossweb::widget l.t -$k $v
           }
         }
       }
       set gh_js [ossweb::convert::list_to_attributes $g_js]
       set output \
           "<INPUT TYPE=HIDDEN NAME=\"${name_prefix}$widget(name)\" VALUE=\"[ossweb::coalesce address_id]\">
            <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>"
       if { $use_descr } {
         append output "
            <TR><TD COLSPAN=2>
                <TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>
                <TR><TD CLASS=$class>Name</TD>
                    <TD CLASS=$class>Type</TD>
                </TR>
                <TR><TD>[ossweb::widget l.n html]</TD>
                    <TD>[ossweb::html::select ${name_prefix}location_type $location_types [ossweb::coalesce location_type] "class $sclass $g_js"]</TD>
                </TR>
                </TABLE>
                </TD>
            </TR>"
       } else {
         append output "<INPUT TYPE=HIDDEN NAME=${name_prefix}location_name VALUE='[ossweb::coalesce location_name]'>"
         append output "<INPUT TYPE=HIDDEN NAME=${name_prefix}location_type VALUE='[ossweb::coalesce location_type]'>"
       }
       if { $use_address } {
         append output "
            <TR><TD COLSPAN=2 NOWRAP>
                <TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>
                <TR><TD CLASS=$class>Number &nbsp;&nbsp;&nbsp;Street Name</TD>"

         if { $use_street_type } {
           append output "<TD CLASS=$class>Street Type</TD>"
         } else {
           append output "<TD></TD>"
         }
         append output "
                </TR>
                <TR><TD NOWRAP>
                       <INPUT TYPE=TEXT CLASS=$iclass NAME=${name_prefix}number SIZE=7 VALUE=\"[ossweb::coalesce number]\" $gh_js>&nbsp;
                       [ossweb::widget l.s html]
                    </TD>"
         if { $use_street_type } {
           append output "<TD>[ossweb::html::select ${name_prefix}street_type $street_types [list [ossweb::coalesce street_type]] "class $sclass $g_js"]</TD>"
         } else {
           append output "<TD><INPUT TYPE=HIDDEN NAME=${name_prefix}street_type VALUE='[ossweb::coalesce street_type]'></TD>"
         }

         append output "
                </TR>
                </TABLE>
                </TD>
            </TR>"
         if { $use_unit || $use_buttons } {
           append output "
            <TR>"
           if { $use_unit } {
             append output "
                <TD NOWRAP>
                  [ossweb::html::select ${name_prefix}unit_type $unit_types [list [ossweb::coalesce unit_type]] "class $sclass $g_js"]&nbsp;
                  <INPUT TYPE=TEXT CLASS=$iclass NAME=${name_prefix}unit SIZE=5 VALUE=\"[ossweb::coalesce unit]\" $gh_js>
                </TD>"
           } else {
             append output "
                <TD><INPUT TYPE=HIDDEN NAME=${name_prefix}unit_type VALUE='[ossweb::coalesce unit_type]'>
                    <INPUT TYPE=HIDDEN NAME=${name_prefix}unit VALUE='[ossweb::coalesce unit]'>
                </TD>"
           }
           if { $use_icons } {
             set findimage [ossweb::image_name [ossweb::coalesce widget(find_image) search.gif]]
             set mapimage [ossweb::image_name [ossweb::coalesce widget(map_image) map.gif]]
             set clearimage [ossweb::image_name [ossweb::coalesce widget(clear_image) clear.gif]]
             set classimage [ossweb::coalesce widget(icon_class) osswebImage]
             append output "
                <TD NOWRAP>
                <TABLE BORDER=0>
                <TR><TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>"

             if { ![info exists widget(nofind)] } {
               append output "
                    <TD><A HREF=javascript:;
                         TITLE=\"Search for address\"
                         onClick=\"$url\"><IMG SRC=\"$findimage\" CLASS=$classimage></A>
                    </TD>"
             }

             append outpout "
                    <TD><A HREF=javascript:;
                         TITLE=\"Show map for the address\"
                         onClick=\"formAddressMap(document.$widget(form:id),0,'${name_prefix}')\"><IMG SRC=\"$mapimage\" CLASS=$classimage></A>
                    </TD>
                    <TD><A HREF=javascript:;
                         TITLE=\"Clear address form\"
                         onClick=\"formAddressReset(document.$widget(form:id),'$widget(name)','$name_prefix')\"><IMG SRC=\"$clearimage\" CLASS=$classimage></A>
                    </TD>
                </TR>
                </TABLE>
                </TD>"
           } elseif { $use_buttons } {
             append output "
                <TD NOWRAP>
                <TABLE BORDER=0>
                <TR><TD>&nbsp;&nbsp;&nbsp;&nbsp;</TD>"

             if { ![info exists widget(nofind)] } {
               append output "
                    <TD><DIV CLASS=${bclass}
                         onMouseOver=\"this.className='${bclass}Over'\"
                         onMouseOut=\"this.className='${bclass}'\"
                         onClick=\"$url\">Find</DIV>
                    </TD>"
             }

             append output "
                    <TD><DIV CLASS=${bclass}
                         onMouseOver=\"this.className='${bclass}Over'\"
                         onMouseOut=\"this.className='${bclass}'\"
                         onClick=\"formAddressMap(document.$widget(form:id),0,'${name_prefix}')\">Map</DIV>
                    </TD>
                    <TD><DIV CLASS=${bclass}
                         onMouseOver=\"this.className='${bclass}Over'\"
                         onMouseOut=\"this.className='${bclass}'\"
                         onClick=\"formAddressReset(document.$widget(form:id),'$widget(name)','$name_prefix')\">Clear</DIV>
                    </TD>
                </TR>
                </TABLE>
                </TD>"
           } else {
             append output "<TD>&nbsp;</TD>"
           }
           append output "
            </TR>"
         }
         append output "
            <TR><TD CLASS=$class>City</TR></TR>
            <TR><TD COLSPAN=2>[ossweb::widget l.c html]</TD>
            </TR>
            <TR><TD COLSPAN=2>
                <TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>
                <TR><TD CLASS=$class>State/Province</TD>
                    <TD CLASS=$class>Zip Code</TD>"

         if { $use_country == 1} {
           append output "
                    <TD CLASS=$class>Country</TD>"
         }
         append output "
                </TR>
                <TR><TD>[ossweb::widget l.t html]</TD>
                    <TD><INPUT TYPE=TEXT CLASS=$iclass NAME=${name_prefix}zip_code SIZE=8 VALUE=\"[ossweb::coalesce zip_code]\" $gh_js></TD>"

         if { $use_country == 1 } {
           append output "
                    <TD>[ossweb::html::select ${name_prefix}country $countries [ossweb::coalesce country] "class $sclass $g_js"]</TD>"
         }
         append output "
                </TR>"

         if { $use_country == 2 } {
           append output "
                <TR><TD COLSPAN=2 CLASS=$class>Country</TD></TD>
                <TR><TD COLSPAN=2>[ossweb::html::select ${name_prefix}country $countries [ossweb::coalesce country] "class $sclass"]</TD></TR>"
         }

         if { !$use_country } {
           append output "<INPUT TYPE=HIDDEN NAME=${name_prefix}country VALUE='[ossweb::coalesce country]'>"
         }
         append output "
                </TABLE>
               </TD>
            </TR>"
       }
       if { $use_gps } {
         append output "
            <TR><TD COLSPAN=2>
                <TABLE BORDER=0 CELLSPACING=2 CELLPADDING=0>
                <TR><TD CLASS=$class>Latitude</TD>
                    <TD CLASS=$class>Longitude</TD>
                    <TD></TD>
                </TR>
                <TR><TD><INPUT TYPE=TEXT CLASS=$iclass NAME=${name_prefix}latitude SIZE=7 VALUE=\"[ossweb::coalesce latitude]\" $gh_js></TD>
                    <TD><INPUT TYPE=TEXT CLASS=$iclass NAME=${name_prefix}longitude SIZE=7 VALUE=\"[ossweb::coalesce longitude]\" $gh_js></TD>
                    <TD><DIV CLASS=${bclass}
                         TITLE=\"Show map for provided long/lat\"
                         onMouseOver=\"this.className='${bclass}Over'\"
                         onMouseOut=\"this.className='${bclass}'\"
                         onClick=\"formAddressMap(document.$widget(form:id),1,'${name_prefix}')\">Map</DIV>
                    </TD>
                </TR>
                </TABLE>
                </TD>
            </TR>"
       }
       if { [info exists widget(notes)] } {
         append output "
           <TR><TD CLASS=$class>Location Notes</TR></TR>
           <TR><TD COLSPAN=2>[ossweb::widget l.o html]</TD></TR>"
       }
       append output "
            </TABLE>"
       return $output
     }
    }
}

proc ossweb::schedule::hourly::2::birthday { args } {

    ossweb::db::foreach sql:people.search.birthday {
      set name "$first_name $last_name"

      # Send through registered handlers
      foreach proc [namespace eval ::contact::people::send { info procs }] {
        if { [catch { ::contact::people::send::$proc $phone $name $birthday } errmsg] } {
          ns_log error ossweb::schedule::hourly::2::birthday: $proc: $errmsg
        }
      }
    }
}

proc ossweb::schedule::daily::reminder { args } {

    set notify_flag t
    ossweb::db::foreach sql:people.search.birthday {
      append list1($user_email) "  $first_name $last_name  - $birthday\n"
      lappend list2($user_email) $people_id
    }
    foreach { email text } [array get list1] {
      set text "The following people from your contact list have their birthday on:\n\n$text"
      ossweb::sendmail $email ossweb "Your Birthday Reminder" $text
      foreach people_id $list2($email) { 
        ossweb::db::exec sql:people.update.notify 
      }
    }

    ossweb::db::foreach sql:people.search.notify {
      append list3($user_email) "$first_name $last_name: $entry_date $entry_notify\n  $entry_name $entry_value\n\n"
      lappend list4($user_email) $entry_id
    }
    foreach { email text } [array get list3] {
      set text "Notifications about your contacts:\n\n$text"
      ossweb::sendmail $email ossweb "Your Contact Notifications" $text
      foreach entry_id $list4($email) { 
        ossweb::db::exec sql:people.entry.update.notify 
      }
    }
}

# Returns company icon
proc contact::company::icon { company_id { company_name "" } } {

    if { [set icon [ossweb::file::image_exists $company_id companies]] != "" } {
      return [ossweb::file::url companies $icon company_id $company_id]
    }
}

# Export contact database into CSV file
proc contact::export { args } {

    ns_parseargs { {-type ""} {-file contacts.txt} } $args

    set data "First Name,Last Name,Display Name,Nickname,Primary Email,Secondary Email,Work Phone,"
    append data "Home Phone,Fax Number,Pager Number,Mobile Number,Home Address,Home Address 2,"
    append data "Home City,Home State,Home ZipCode,Home Country,Work Address,Work Address 2,"
    append data "Work City,Work State,Work ZipCode,Work Country,Job Title,Department,Organization,"
    append data "Web Page 1,Web Page 2,Birth Year,Birth Month,Birth Day,Custom 1,Custom 2,Custom 3,Custom 4,Notes,\n"

    if { [string index $file 0] != "/" } {
      set file [ossweb::file::getname $file -path contact]
    }
    ossweb::db::foreach sql:people.export {
      array unset a
      array set a $address
      set notes [string map { \n {} \r {} \t {} ' {} } $notes]
      foreach n { home_phone work_phone cell_phone pager fax email email2 icq } { set $n "" }
      foreach { en ev } $entries {
        set ev [string map { \n {} \r {} \t {} ' {} } $ev]
        switch -regexp -- [string tolower $en] {
         {home.*phone} { set home_phone [string map {- {} . {} { } {} } $ev] }
         {^phone$} { set home_phone [string map {- {} . {} { } {} } $ev] }
         {work.*phone} { set work_phone [string map {- {} . {} { } {} } $ev] }
         {cell.*phone} { set cell_phone [string map {- {} . {} { } {} } $ev] }
         {mobile.*phone} { set cell_phone [string map {- {} . {} { } {} } $ev] }
         pager { set pager [string map {- {} . {} { } {} } $ev] }
         fax { set fax [string map {- {} . {} { } {} } $ev] }
         email { if { $email == "" } { set email $ev } else { set email2 $ev } }
         {icq|msn|aim} { set icq $ev }
        }
      }
      append data "$first_name,$last_name,,,$email,$email2,$work_phone,$home_phone,$fax,$pager,$cell_phone,"
      append data "[string trim "[ossweb::coalesce a(number)] [ossweb::coalesce a(street)] [ossweb::coalesce a(street_type)]"],"
      append data "[string trim "[ossweb::coalesce a(unit_type)] [ossweb::coalesce a(unit)]"],"
      append data "[ossweb::coalesce a(city)],[ossweb::coalesce a(state)],[ossweb::coalesce a(zip_code)],[ossweb::coalesce a(country)],"
      append data ",,,,,,,,,$icq,,[lindex $birthday 2],[lindex $birthday 0],$birthday,,,,'$notes'\n"
    }
    ossweb::write_file $file $data
}

# Full text search provider for people records
proc ossweb::tsearch::people { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type people
       set tsearch_id people_id::TEXT
       set tsearch_table ossweb_people
       set tsearch_date update_date
       set tsearch_text "first_name||' '||COALESCE(last_name,'')||' '||COALESCE(TO_CHAR(birthday,'YYYY-MM-DD'),'')||' '||COALESCE(description,'')||' '||ossweb_people_entries(people_id)"
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     url {
       # Returns full url to the record
       return [ossweb::html::url contact.people cmd edit people_id [lindex $args 0]]
     }
    }
}

# Full text search provider for company records
proc ossweb::tsearch::company { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type company
       set tsearch_id company_id::TEXT
       set tsearch_table ossweb_companies
       set tsearch_date update_date
       set tsearch_text "company_name||' '||COALESCE(description,'')||' '||ossweb_company_entries(company_id)"
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     url {
       # Returns full url to the record
       return [ossweb::html::url contact.companies cmd edit company_id [lindex $args 0]]
     }
    }
}
