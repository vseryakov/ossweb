# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001
#
# $Id: conn.tcl 2938 2007-01-31 17:08:19Z vlad $

ossweb::register_init ossweb::conn::init

# Performs system initialization
proc ossweb::conn::init {} {

    # System filter for internal and non-web access
    ns_register_proc GET /ossweb:handler ::ossweb::conn::filter::system

    # Type of global security filter to use
    if { [set filter [ossweb::param security:filter secure]] != "none" } {
      # Secure directory, by default the whole site
      foreach directory [ossweb::param security:directory] {
        # Register security filter
        ns_register_filter preauth GET $directory ::ossweb::conn::filter::$filter
        ns_register_filter preauth POST $directory ::ossweb::conn::filter::$filter
        ns_register_filter preauth HEAD $directory ::ossweb::conn::filter::$filter
        ns_log Notice ossweb::init $filter filter installed for $directory
      }
    }

    # Per directory filter setup
    foreach { directory filter } [ossweb::param security:filter:list] {
      ns_register_filter preauth GET $directory ::ossweb::conn::filter::$filter
      ns_register_filter preauth POST $directory ::ossweb::conn::filter::$filter
      ns_register_filter preauth HEAD $directory ::ossweb::conn::filter::$filter
      ns_log Notice ossweb::init $filter filter installed for $directory
    }
    ns_log Notice ossweb::conn: initialized
}

# Global connection specific information. It is possible to create
# new parameter and store them into this global pool and
# use througout application.
# Usage: ossweb::conn [switch] name [value]
# Switches:
#    -get - retrieves parameter value, default value may be specified
#    -set - sets parameter value
#    -reset - clears all parameters
#    -dump - returns the whole array as a list
#    -check - check global array for existence and resets it necessary
#    -new_session_id - generates new session id
#    -acl - returns value of ACL parameter
#    -new_acl - creates new ACL parameter
#
# Standard parameters:
#    user_id - unique id of the user
#    session_id - current session id
#    user_name - user login name
#    full_name - full name of logged in user
#    url - current request url
proc ossweb::conn { args } {

    global session_conn session_acl

    switch -- [set cmd [lindex $args 0]] {
      -lexists {
        if { [set value [lindex $args 2]] == "" ||
             [set list [ossweb::conn [lindex $args 1]]] == "" } {
          return 1
        }
        return [ossweb::lexists $list $value]
      }

      -set {
        foreach { name value } [lrange $args 1 end] {
          set session_conn($name) $value
        }
        return $value
      }

      -append {
        foreach { name value } [lrange $args 1 end] {
          append session_conn($name) $value
        }
        return $value
      }

      -push {
        foreach { name value } [lrange $args 1 end] {
          lappend session_conn($name) $value
        }
      }

      -pop {
        set name [lindex $args 1]
        if { [info exists session_conn($name)] } {
          set val [lindex $session_conn($name) end]
          set session_conn($name) [lrange $session_conn($name) 0 end-1]
          return $val
        }
      }

      -incr {
        set name [lindex $args 1]
        if { ![info exists session_conn($name)] || ![string is integer -strict $session_conn($name)] } {
          set session_conn($name) 0
        }
        set session_conn($name) [eval incr session_conn($name) [lindex $args 2]]
        return $session_conn($name)
      }

      -unset {
        unset session_conn([lindex $args 1])
      }

      -clear {
        # Clears the value and returns the previous one
        set name [lindex $args 1]
        if { [info exists session_conn($name)] } {
          set val $session_conn($name)
          unset session_conn($name)
          return $val
        }
        return
      }

      -check {
        if { ![info exists session_conn] } {
          ossweb::conn -reset
        }
      }

      -parse_url {
        if { ![info exists session_conn] ||
             ![info exists session_conn(url)] } {
          ossweb::conn -reset
          ossweb::conn::parse_url
        }
      }

      -dump {
        return [array get session_conn]
      }

      -reset {
        if { [info exists session_conn] } {
          ossweb::db::release
          unset session_conn
        }
        set session_acl [list]
        set session_conn(project_name) unknown
        set session_conn(app_name) unknown
        set session_conn(page_name) unknown
        set session_conn(cmd_name) unknown
        set session_conn(ctx_name) unknown
        if { [ns_conn isconnected] } {
          set session_conn(url) [ns_conn url]
        }

        # For public sites everything is allowed
        if { [ossweb::true [ossweb::config server:public]] } {
          ossweb::conn -new_acl * * * * * Y
        }
      }

      -reset_acl {
        set session_acl [list]
      }

      -url {
        set args [lreplace $args 0 0]
        ns_parseargs { {-skip ""} {-include ""} {-host f} } $args

        if { $host == "t" } {
          set url [ossweb::conn::hostname]
        }
        append url [ossweb::conn url]?[ossweb::conn::export_form -skip $skip -include $include]
        return $url
      }

      -msg {
        if { [info exists session_conn(msg)] && $session_conn(msg) != "" } {
          return $session_conn(msg)
        }
        return [ossweb::message [ns_queryget msg]]
      }

      -new_session_id {
        set session_conn(session_id) [ossweb::db::nextval ossweb_session]
        # Autogenerate random token
        if { $session_conn(session_id) == "" } {
           set session_conn(session_id) [ns_sha1 [clock microseconds][ns_conn peeraddr][ossweb::random]]
        }
        return $session_conn(session_id)
      }

      -new_acl {
        foreach { n i } { project_name 1 app_name 2 page_name 3 cmd_name 4 ctx_name 5 value 6 query 7 handlers -1 } {
           set acl($n) [lindex $args $i]
        }
        foreach { name proc } [lindex $args 8] {
          namespace eval :: "if { \[info procs $proc\] == {} } { continue }"
          lappend acl(handlers) $name $proc
        }
        lappend session_acl [array get acl]
      }

      -acl {
        if { ![info exists session_acl] } { return }
        # Given ACL to be checked may contain empty fields for that values we don't want to check
        foreach row $session_acl {
           array set acl $row
           set i 1
           foreach { name } { project_name app_name page_name cmd_name ctx_name } {
             set val [lindex $args $i]
             if { $val != "" && $val != "*" && ![string match -nocase $acl($name) $val] } {
               break
             }
             incr i
           }
           # Now we check custom query parameters, use value
           # from query, never use local variable, sixth argument should be Y
           if { $i == 6 } {
             if { [lindex $args 6] == "Y" && $acl(query) != "" } {
               # Because acls are sorted in descendent order, empty query will be
               # the last one in the list of acls for the same page.
               set ok 0
               foreach { name value } $acl(query) {
                 if { [set ok [string match [ns_queryget $name] $value]] } { break }
               }
               # Continue evaluating other acls with different query if exist
               if { !$ok } { continue }
             }
             # Now we can check data-aware handlers, call specified proc for each
             # query parameter, algorithm is the same as for query above.
             if { [lindex $args 7] == "Y" && $acl(handlers) != "" } {
               set ok 0
               foreach { name proc } $acl(handlers) {
                 if { $name != "" && ![ns_queryexists $name] } { continue }
                 if { [catch { set ok [$proc $name [ns_queryget $name]] } errmsg] } {
                   ossweb::conn::log Error ossweb::conn -acl ${proc}($name): $errmsg
                   set ok -1
                 }
                 if { $ok } { break }
               }
               if { $ok } { continue }
             }
             return $acl(value)
           }
        }
      }

      default {
        set var [lindex $args 0];  # variable name
        set val [lindex $args 1];  # default value
        if { [info exists session_conn($var)] } {
          set val $session_conn($var)
        }
        # Postprocess for special variables
        switch -- $var {
         start -
         peeraddr -
         peerport -
         authpassword -
         authuser -
         content -
         contentlength -
         copy -
         driver -
         encoding -
         files -
         fileoffset -
         filelength -
         fileheaders -
         flags -
         form -
         headers -
         host -
         id -
         isconnected -
         location -
         method -
         outputheaders -
         port -
         protocol -
         query -
         request -
         server -
         sock -
         status -
         url -
         urlc -
         urlencoding -
         urlv -
         version -
         write_encoded {
           if { $val == "" && [ns_conn isconnected] } {
             set val [ns_conn $var]
           }
         }

         ipaddr {
           # Return ip address from most recent session
           set sid [lindex [ossweb::coalesce session_conn(session-list)] 0]
           if { $sid != "" } {
             return [ossweb::coalesce session_conn(session-ip-$sid)]
           }
         }

         session_id {
           # Return most recent session
           if { $val == "" } {
             set val [lindex [ossweb::coalesce session_conn(session-list)] 0]
           }
         }

         pageroot {
           return [ossweb::config server:path:root [ns_info pageroot]]
         }

         project_name {
           # Return default project if not set
           if { $val == "" || $val == "unknown" } {
             set val [ossweb::config server:project unknown]
           }
         }

         page_name {
           if { ($val == "" || $val == "unknown") && [ns_conn isconnected] } {
             set val [file rootname [file tail [ns_conn url]]]
             set session_conn(page_name) $val
           }
         }
        }
        return $val
      }
    }
    return
}

# Performs writing in the server log file, automatically outputs
# current application/user environment
proc ossweb::conn::log { type name args } {

    # Log all parameters that end with _id
    foreach { qname qval } [ossweb::convert::set_to_list [ns_getform] -filter {_id$}] {
      lappend args $qname $qval
    }
    ns_log $type $name: [ossweb::conn url]: [ossweb::conn user_name]: [ossweb::conn project_name].[ossweb::conn app_name].[ossweb::conn page_name].[ossweb::conn cmd_name].[ossweb::conn ctx_name]: [join $args " "]
}

# Initialize variables with default values
# -level defines at which level variables should be created
# -force makes specified variables to be initialized with default values
# { name type default }
# default value may contain references to variables, they will be
# substituted. All variables will be set to default values only if
# they don't exist, otherwise they will be left alone as is.
# Columns also may be a list consisting from column definition lists.
# Variable types:
#   int,text,integer,float,.. - regular data types as for widgets
#   var - just variable, doesn't necessary belong to form
#   hidden - form hidden variable
#   set - will be set to default value every time
# Ex: ossweb::conn::init_vars id int 0 name "" "" url "" "/"
proc ossweb::conn::init_vars { args } {

    ns_parseargs { {-level {[expr [info level]-1]}} {-force f} {-skip ""} {-array ""} -- columns } $args

    foreach { name type default } $columns {
      if { [lsearch -exact $skip $name] >= 0 } {
        continue
      }
      # Store in array instead of variable
      if { $array != "" } {
        set name ${array}($name)
      }
      switch -exact -- $type {
       Const -
       const {
         uplevel #$level "set $name {[subst $default]}"
       }

       userid {
         uplevel #$level "set $name {[ossweb::conn user_id $default]}"
       }

       default {
         upvar #$level $name var
         if { $force == "t" || ![info exists var] } {
           set var [subst $default]
         }
       }
      }
    }
}

# Setups environment for reftable application context for
# administration of reference tables which have common
# columns. In order to use table with this system, the table
# should consist of these columns:
# obj_id,obj_name,description
#     where obj is name of object
# See definition of objects,data_types,units tables for more
# information.
# Returns 0 if everything is okay, otherwise returns -1.
proc ossweb::conn::init_reftable { args } {

    ns_parseargs { {-app_name {[ossweb::conn app_name]}}
                   {-page_name {[ossweb::conn page_name]}} } $args

    set rec [ossweb::db::multilist sql:ossweb.reftable.read -plain t]
    if { $rec == "" } {
      error "OSS: Invalid reftable settings for $page_name"
    }
    uplevel "
       set ref_table {[lindex $rec 0]}
       set ref_object {[lindex $rec 1]}
       set ref_title {[lindex $rec 2]}
       set ref_refresh {[lindex $rec 3]}
       set ref_precedence {[lindex $rec 4]}
       set ref_extra_name {[lindex $rec 5]}
       set ref_extra_label {[lindex $rec 6]}
       set ref_extra_name2 {[lindex $rec 7]}
       set ref_extra_label2 {[lindex $rec 8]}
    "
}

# Returns a URL parameter string of name-value pairs of all the
# form parameters passed to this page.
#  -include specifies a list of parameter names that
# will be exported only.
#  -skip specifies a list of parameter names that
# shouldn't be the exported.
#  -format if specifies as "list" returns list of name value
# pairs as in array get
proc ossweb::conn::export_form { args } {

    ns_parseargs { {-form {[ns_getform]}} {-include ""} {-skip "" } {-format ""} } $args

    if { $form == "" } {
      return ""
    }
    set params [list]
    set size [ns_set size $form]
    for { set i 0 } { $i < $size } { incr i } {
      set name [ns_set key $form $i]
      set value [ns_set value $form $i]
      if { $name == "" && $value == "" } {
        continue
      }
      if { $include == "" && $skip == "" } {
        lappend params $name $value
        continue
      }
      if { $include != "" && [regexp -nocase $include $name] } {
        lappend params $name $value
        continue
      }
      if { $skip != "" && ![regexp -nocase $skip $name] } {
        lappend params $name $value
        continue
      }
    }
    set result ""
    foreach { name value } $params {
      switch -- $format {
       list {
         lappend result $name $value
       }
       hidden {
         lappend result "<INPUT TYPE=hidden NAME=$name VALUE=\"$value\">"
       }
       default {
         lappend result "$name=[ns_urlencode $value]"
       }
      }
    }
    switch $format {
     list {
       return $result
     }
     hidden {
       return [join $result "\n"]
     }
     default {
       return [join $result "&"]
     }
    }
}

# Looks up a property for the current session.
#  -cache If true, will use the cached value if available.
#               All subsequent calls will read value from cache instead of database.
#  -global if t get global user property, otherwise
#                    get session specific property value.
#  -default specifies default value if actual value is empty
#  -columns if set, create local variables from value
proc ossweb::conn::get_property { name args } {

    ns_parseargs { {-global f}
                   {-cache t}
                   {-default ""}
                   {-columns ""}
                   {-array ""}
                   {-skip ""}
                   {-db t}
                   {-debug f}
                   {-timeout ""}
                   {-encrypt f}
                   {-decrypt f}
                   {-user_id {[ossweb::conn user_id]}} } $args

    if { $user_id == "" } {
      return
    }
    if { $global == "t" } {
      set session_id 0
    } else {
      set session_id [ossweb::conn session_id]
    }
    set key PROPERTY:$user_id:$session_id:$name
    # Try cache first
    if { $db == "f" || ($cache == "t" && [ossweb::cache exists $key]) } {
      set value [ossweb::cache get $key]
    } else {
      if { [set value [ossweb::db::multilist sql:ossweb.user.property.read -plain t -debug $debug]] != "" } {
        set timeout [lindex $value 1]
        set value [lindex $value 0]
        # Store global values in the cache
        if { $cache == "t" } {
          ossweb::cache set $key $value $timeout
        }
      }
    }
    if { $columns != "" } {
      if { $columns != "t" } {
        ossweb::conn::init_vars -force t -level [expr [info level]-1] -skip $skip $columns
      }
      ossweb::convert::list_to_vars $value -level 2 -skip $skip
    }
    if { $array != "" } {
     if { [catch { array set $array $value } errmsg] } {
       ns_log Error ossweb::conn::get_property: $user_id: $name: $errmsg
     }
    }
    if { $value == "" } {
      set value $default
    }
    if { $decrypt == "t" } {
      set value [ossweb::decrypt $value]
    }
    if { $encrypt == "t" } {
      set value [ossweb::encrypt $value]
    }
    return $value
}

# Sets a client (session-level) property.
# -global if true, sets global persistent user property,
#         otherwise session specific property
# -cache if true, cache value
# -columns if set, user local variables from columns to store them all as value
# -array specifies array with values to be saved
# -forms specifies list of forms which values which be saved
# -save if true saves value in the properties table
# Example: ossweb::conn::set_property ORDER_ID 12344
#          set order_id [ossweb::conn::get_property ORDER_ID]
proc ossweb::conn::set_property { name value args } {

    ns_parseargs { {-global f}
                   {-cache t}
                   {-columns ""}
                   {-array ""}
                   {-vars ""}
                   {-forms ""}
                   {-skip ""}
                   {-db t}
                   {-debug f}
                   {-append f}
                   {-lappend f}
                   {-timeout ""}
                   {-encrypt f}
                   {-decrypt f}
                   {-user_id {[ossweb::conn user_id]}} } $args

    if { $user_id == "" } {
      return
    }
    if { $global == "t" } {
      set session_id 0
    } else {
      set session_id [ossweb::conn session_id]
    }
    if { $columns != "" } {
      set colnames ""
      foreach { cname ctype cdef } $columns {
        lappend colnames $cname
      }
      append value " " [ossweb::convert::vars_to_list $colnames -skip $skip -level 2]
    }
    if { $vars != "" } {
      append value " " [ossweb::convert::vars_to_list $vars -skip $skip -level 2]
    }
    if { $array != "" } {
      append value " " [array get $array]
    }
    foreach form $forms {
      append value " " [ossweb::convert::vars_to_list [ossweb::form $form widgets] -skip $skip -level 2]
    }
    if { $decrypt == "t" } {
      set value [ossweb::decrypt $value]
    }
    if { $encrypt == "t" } {
      set value [ossweb::encrypt $value]
    }
    # Store global values in the cache
    if { $cache == "t" } {
      set key PROPERTY:$user_id:$session_id:$name
      # Check for the same value
      if { [ossweb::cache exists $key] && [ossweb::cache get $key] == $value } {
        return $value
      }
      if { $lappend == "t" } {
        ossweb::cache lappend $key $value $timeout
      } elseif { $append == "t" } {
        ossweb::cache append $key $value $timeout
      } else {
        ossweb::cache set $key $value $timeout
      }
    }
    if { $db == "f" } {
      return $value
    }
    # Update or create the property
    if { $lappend == "t" } {
      set value " {$value}"
      ossweb::db::exec sql:ossweb.user.property.append -debug $debug
    } elseif { $append == "t" } {
      ossweb::db::exec sql:ossweb.user.property.append -debug $debug
    } else {
      ossweb::db::exec sql:ossweb.user.property.update -debug $debug
    }
    if { ![ossweb::db::rowcount] } {
      ossweb::db::exec sql:ossweb.user.property.create -debug $debug
    }
    return $value
}

# Removes a client (session-level) property from property table.
proc ossweb::conn::clear_property { name args } {

    ns_parseargs { {-global f} {-cache f} {-db t} {-user_id {[ossweb::conn user_id]}} } $args

    if { $global == "t" } {
      set session_id 0
    } else {
      set session_id [ossweb::conn session_id]
    }
    set key PROPERTY:$user_id:$session_id:$name
    # Clear the cache
    if { $cache == "t" } {
      ossweb::cache flush $key
    }
    if { $db == "t" } {
      ossweb::db::exec sql:ossweb.user.property.delete
    }
}

# Update/retrieve session variables from the query or from specified local variables
proc ossweb::conn::sessionvars { args } {

    ns_parseargs { {-level {[expr [info level]-1}]} {-global f} {-clear f} {-query t} {-debug f} -- args } $args

    # Ignore current vars
    if { $clear != "t" } {
      array set sessionarr [ossweb::conn::get_property SESSIONVARS -cache t -db t -global $global]
    }
    foreach svar $args {
      set svar [split $svar :]
      set svarname [lindex $svar 0]
      set svartype [lindex $svar 1]
      # Take value from the query and update local variables
      if { $query == "t" } {
        if { [ns_queryexists $svarname] } {
          set svarval [ossweb::convert::query_to_value [ns_queryget $svarname]]
          if { $svartype == "" || [ossweb::datatype::$svartype $svarval] == "" } {
            set sessionarr($svarname) $svarval
          }
        }
        if { [info exists sessionarr($svarname)] } {
          upvar #$level $svarname svarlink
          set svarlink $sessionarr($svarname)
          if { $debug != "f" } {
            ns_log notice ossweb::conn::sessionvars: $svarname = $sessionarr($svarname)
          }
        }
      } else {
        # Just take local variables and save them
        upvar #$level $svarname svarlink
        if { [info exists svarlink] } {
          if { $svartype == "" || [ossweb::datatype::$svartype $svarlink] == "" } {
            set sessionarr($svarname) $svarlink
          }
        }
      }
    }
    # Sort vars to preserve order and avoid extra DB updates
    set vars ""
    foreach name [lsort [array names sessionarr]] {
      lappend vars $name $sessionarr($name)
    }
    if { $debug != "f" } {
      ns_log notice ossweb::conn::sessionvars: $vars
    }
    ossweb::conn::set_property SESSIONVARS $vars -cache t -db t -global $global
}

# Retrieves all form/query url parameteres and puts them
# into local variables of the calling frame
#  -quote specifies to perform SQL quoting
#  -level specifies level at which to create variables
#  -match specifies pattern which parameters should be
#               retrieved only
#  -columns specifies column definition, some column types cannot be
#                 overwritten by query parameters: const
#  -return t returns query parameters as a list of lists
#                  { { name value } { .. } .. }
#  -form specifies ns_set with form/query parameters, if empty default
#        submitted form is used
#  -validate t tell to validate values for valid datatype
#  -array specifies array where all query parametetrs will be stored instead of variables
#
# For example, for query like index.oss?name=John&user_id=1
#   ossweb::conn::query
#   ns_db dml $db "update user set name='$name' where user_id=$user_id"
proc ossweb::conn::query { args } {

    ns_parseargs { {-quote f}
                   {-level {[expr [info level]-1]}}
                   {-return f}
                   {-regexp ""}
                   {-match ""}
                   {-columns ""}
                   {-form {[ns_getform]}}
                   {-validate t}
                   {-plain f}
                   {-array ""}
                   {-debug f} } $args

    if { $form == "" } {
      return
    }
    if { $debug != "f" } {
      set debug "\n"
    }
    foreach { name type default } $columns {
      set types($name) [string tolower $type]
    }
    set qlist [list]
    set size [ns_set size $form]
    for { set i 0 } { $i < $size } { incr i } {
      set name [ns_set key $form $i]
      set value [string trim [ns_set value $form $i]]
      if { $name == "" ||
           ($match != "" && ![string match $match $name]) ||
           ($regexp != "" && ![regexp $regexp $name]) } {
        continue
      }
      set value [ossweb::convert::query_to_value $value]
      if { $debug != "f" } {
        set formvalue [ns_set value $form $i]
        append debug "\t$name = $formvalue"
        if { $formvalue != $value } {
          append debug "($value)"
        }
        append debug "\n"
      }
      # Verify special variables
      if { [info exists types($name)] } {
        switch -exact -- [set type $types($name)] {
          const -
          userid {
             continue
          }

          crypt {
             set value [ossweb::decrypt $value]
          }

          sql {
             set value [ossweb::sql::quote $value]
          }

          default {
             if { $value != "" && [info proc ::ossweb::datatype::$type] != "" } {
               if { [set msg [::ossweb::datatype::$type $value]] != "" } {
                 ns_log Error ossweb::conn::query: $name: $value: $msg
                 continue
               }
             }
          }
        }
      } else {
        # In strict mode we do not put all query variables into Tcl variables
        if { $columns != "" } {
          continue
        }
        set type ""
      }
      if { $quote == "t" } {
        set value [ossweb::sql::quote $value]
      }
      if { $return == "t" } {
        if { $plain == "t" } {
          lappend qlist $name $value
        } else {
          lappend qlist [list $name $value]
        }
      } else {
        # Store in array
        if { $array != "" } {
          upvar #$level ${array}($name) var
        } else {
          upvar #$level $name var
        }
        # Postrpocess
        switch -exact -- $type {
         list -
         ilist {
           # Initialize for the first time because of lappend
           if { ![info exists vinit($name)] } {
             set vinit($name) 1
             set var ""
           }
           # Convert into plain list
           foreach v [split $value " "] {
             lappend var $v
           }
         }

         default {
           set var $value
         }
        }
      }
    }
    if { $debug != "f" } {
      ossweb::conn::log Notice ossweb::conn::query: $debug
    }
    return $qlist
}

# Tcl proc which is executed at adp level
proc ossweb::conn::callback { name args } {

    # Use page's cookies
    set cookie0 [::ossweb::adp::Cookie]
    set cookie1 [info procs ::ossweb::adp::cache::$name]

    # The callback is valid, do not recompile it
    if { $cookie1 == "" || [$cookie1] != $cookie0 } {
      # Actual callback proc
      ::proc ::ossweb::adp::$name {} "
          ossweb::conn -set callback:name $name
          uplevel #[ossweb::adp::Level] { [join [lrange $args 1 end] "\n"] }
          ossweb::conn -set callback:name {}
      "
      ::proc ::ossweb::adp::cache::$name {} "return $cookie0"
    }
}


# Return data to the client, close the connection and stop template processing
proc ossweb::conn::response { { data "" } { type text/html } } {

    ns_return 200 $type $data
    ns_conn close
    error OSSWEB_EXIT
}

# This function defines template to be used, usefull to change templates
# inside Tcl scripts. Optional name argument can specify template name,
# if it is not present current application context is taken for template name.
# The rest parameters treated like query name=value pairs and will be set
# as local variables.
#  -return If set to 't' returns the page to the caller.
#  -project_name allows to specify different project from the current one
#  -app_name or -app allows to specify different application from the current one
#  -page_name or -page allows to specify application page name
#  -cmd_name or -cmd command to be used inside specified template, if empty 'view' is used
#  -ctx_name or -ctx command context to be used inside specified template
#  -url specifies url to be redirected, uses ossweb::conn::redirect
#  -exit will return data and stop processing, useful for AJAX stuff
#  -progress to return uploaded size for given key
#  -none tell to do nothing, just fake call
#
#  page_name can be specified as app_name.page_name
#  app_name can be specified as app_name.page_name
#  cmd_name can be specified as cmd_name.ctx_name
#
# Example : ossweb::conn::next -app_name order -cmd_name edit orders order_id 1
#           ossweb::conn::next -app order.orders -cmd edit order_id 1
#           ossweb::conn::next order.orders cmd edit order_id 1
proc ossweb::conn::next { args } {

    ns_parseargs { {-project_name {[ossweb::conn project_name]}}
                   {-app_name {[ossweb::conn app_name]}}
                   {-page_name {[ossweb::conn page_name]}}
                   {-cmd_name view}
                   {-ctx_name {[ossweb::conn ctx_name]}}
                   {-progress ""}
                   {-popup f}
                   {-app ""}
                   {-page ""}
                   {-path ""}
                   {-cmd ""}
                   {-ctx ""}
                   {-exit ?}
                   {-redirect f}
                   {-javascript ""}
                   {-errormsg ""}
                   {-target ""}
                   {-return f}
                   {-url ""}
                   {-hash ""}
                   {-debug f}
                   {-none f} -- args } $args

    if { $none == "t" } {
      return
    }

    # Browser redirect
    if { $url != "" } {
      ossweb::conn::redirect $url
      return
    }

    # Returns data and stop templating engine
    if { $exit != "?" } {
      ossweb::adp::Exit [string trim $exit]
    }

    # Returns error message as javascript, to be used in pagePopupGet or frames if -parent t
    if { $errormsg != "" } {
      ossweb::adp::Exit "[ossweb::html::include /js/ossweb.js -return t]
                         <SCRIPT>varSet('$errormsg','[ossweb::conn -msg]'[ossweb::decode $target "" "" ",$target.document"])</SCRIPT>"
    }

    # Execute javascript in the output window
    if { $javascript != "" } {
      ossweb::adp::Exit "[ossweb::html::include /js/ossweb.js -return t]
                         <SCRIPT>$javascript</SCRIPT>"
    }
    # In memory routing
    set level [ossweb::adp::Level]
    if { [set len [llength $args]] >= 1 } {
      if { [expr $len % 2] } {
        set page_name [lindex $args 0]
        # The rest are local variables
        set args [lrange $args 1 end]
      }
      # Setup environment
      foreach { param value } $args {
        # Check for reserved names
        switch -- $param {
         cmd {
            set cmd $value
         }
         ctx {
            set ctx $value
         }
         default {
            upvar #$level $param var
            set var $value
         }
        }
      }
    }
    # Useful shortcuts
    set app_name [ossweb::nvl $app $app_name]
    set page_name [ossweb::nvl $page $page_name]
    set cmd_name [ossweb::nvl $cmd $cmd_name]
    set ctx_name [ossweb::nvl $ctx $ctx_name]
    # Split app/command if context is given
    regexp {^([^\.]+)\.(.+)$} $app_name d app_name page_name
    # Page can include app name optionally
    regexp {^([^\.]+)\.(.+)$} $page_name d app_name page_name
    # Command with optional ctx
    regexp {^([^\.]+)\.(.+)$} $cmd_name d cmd_name ctx_name
    # Use index if not specified
    set page_name [ossweb::nvl $page_name index]

    # Skip unknown pieces
    if { $project_name != "unknown" } {
      append path /$project_name
    }
    if { $app_name != "unknown" } {
      append path /$app_name
    }
    set path [ns_normalizepath [ossweb::config server:path:root [ns_info pageroot]]$path/$page_name]

    # Switch to project's index if local does not exists
    if { $page_name == "index" && ![ns_filestat $path.adp] } {
      regsub "/$app_name/index\$" $path /index/index path
    }

    if { $debug != "f" } {
      ossweb::conn::log Notice ossweb::conn::next switching to $app_name.$page_name.$cmd_name.$ctx_name: $path [lrange $args 1 end]
    }

    # Perform permissions check for new template
    if { [ossweb::conn user_id] != "" &&
         [ossweb::conn::check_acl \
               -project_name $project_name \
               -app_name $app_name \
               -page_name $page_name \
               -cmd_name $cmd_name \
               -ctx_name $ctx_name \
               -handlers Y \
               -query Y] } {
      ossweb::conn::redirect_access_denied
      ossweb::adp::Exit
    }

    ossweb::conn -set app_name $app_name
    ossweb::conn -set page_name $page_name
    ossweb::conn -set cmd_name $cmd_name
    ossweb::conn -set ctx_name $ctx_name

    set url [ossweb::html::url -hash $hash -list $args -app_name $app_name -page_name $page_name cmd $cmd_name ctx $ctx_name]

    if { $redirect == "t" } {
       if { $popup == "t" } {
          ossweb::adp::Exit "<SCRIPT>window.location='$url'</SCRIPT>"
       }
       ns_returnredirect $url
       ossweb::adp::Exit
    }

    # Progress report
    if { $progress == "t" } {
       set key [ns_queryget key]
       set stats [ns_upload_stats $key]
       # Calculate percentage
       if { $stats != "" } {
          foreach { len size } $stats {}
          set stats [expr round($len.0*100/$size.0)]
       } else {
          set stats ""
       }
       ossweb::adp::Exit $stats
    }

    if { $return == "f" } {
      ossweb::adp::File $path
    } else {
      return [ossweb::adp::Execute $path]
    }
}


# Initializes variables, reads query parameters and stores
# them into local variables. Existing variables will not be
# overwritten if this rouitine is called more than once.
# The main purpose of this routine to be like a gateway
# to the application, it ensures that all required variables
# are declared and initialized with default values. It also
# checks forms for existence and creates them if necessary and
# if any of the forms in submission state it validates data
# agains form widgets.
#  -columns specifies list of column definiton.
# Each column item consists of 3 items,
#     name type default_value ...
#  where name is column name
#        type is column data type ( int, text ,datetime ... )
#        default is value to be assign if variable is empty
#  local variables will be created and populated with default values
#  with every call of this procedure. If variable alreadu exists, it will not
#  be re-created.
#  -default is the last resort command to execute if nothing was matched
#  -query specifies if t that query parametetrs should be re-read on every processing step
#  -queryarray tells that query values should be stored in array instead of Tcl variables
#  -forms specified list of forms to be initalized,
#         can be global or local for each command, upon execution
#         form existence will be checked, if necesary form will be created
#         using form_create procedure or prepending create_ to the form name
#         and form will be validated. If form validation fails, command context is switched
#         to value from -on_error parameter if it is not empty
# -on_error sets template where to go in case of error, this
#                        parameter can be set in global parameter list
#                        and will be inherited by all command blocks.
#                        If specified in command handlers it takes precedence
#                        over global one.
#                        If error happend, database rollback will be called automatically.
#  -sessionvars specifies list of variables that have to be saved in the cache
#               if defined in the query or retrieved from the cache otherwise
#  -form_tracking if true generates unique form id and tracks against double-submits, can also
#                 be a list of forms to be tracked
#  -form_destroy in case of form error drop invalid form
#  -form_recreate forces to drop and create forms
#  -form_error will propagate form error into global message, should be used
#               in case of form_recreate to display form validation messages
#  -form_create form creation procedure name, will be called
#                     before verification of forms, optional
#  -form_validate specifies list of form names which should be validated
#                       regardless of their submission state.
#  -sql_stmt executes given SQL statement before creating the form
#  -validate specifies conditions which should be true for query parameters
#        syntax is -validate { { name type condition } { name type condition } ...}
#        if condition is empty than variable should be defined and non-empty
#        otherwise condition is evaluated. It may include any valid Tcl expression and
#        commands. It should return 1 if everything is okay or 0 in case of error.
#        msg is error message to show.
#  -eval specifies Tcl handlers for commands. It consists from list of pairs
#              where first item is command name and the second is actions.
#              Inside command context all global parameters are available except
#              -sql... related switches. Local parameter takes precedence over global ones.
#
#              Example:
#              ossweb::conn::process -forms { form_orders } \
#                  -validate { { order_id int { $order_id > 0 } } \
#                              { name text { $order_id == -1 } } } \
#                  -on_error { services } \
#                  -eval {
#                       update -
#                       delete {
#                            -validate { id int }
#                            -exec { order_edit_proc }
#                            -on_error { orders }
#                            -next { orders }
#                       }
#                  }
# Returns 0 if form is submitted and valid,
#         1 if nothing is submitted
#        -1 if form is invalid and command otherwise.
proc ossweb::conn::process { args } {

    ns_parseargs { {-columns ""}
                   {-columns2 ""}
                   {-sessionvars ""}
                   {-sessionvars_clear f}
                   {-sessionvars_global f}
                   {-next ""}
                   {-on_error_set_msg "Application was unable to process the request"}
                   {-on_error {-cmd error}}
                   {-on_error_eval ""}
                   {-transaction f}
                   {-validate ""}
                   {-sql_stmt ""}
                   {-forms ""}
                   {-form_error f}
                   {-form_validate ""}
                   {-form_create ""}
                   {-form_recreate f}
                   {-form_tracking f}
                   {-form_tracking_clear f}
                   {-query f}
                   {-queryarray ""}
                   {-exec ""}
                   {-debug f}
                   {-final ""}
                   {-default ""}
                   {-eval ""} } $args


    global errorInfo
    set level [ossweb::adp::Level]
    # Output submitted parameters to the log
    if { $debug == "f" } {
      set debug [ossweb::config server:debug f]
    }

    # Check if we are not under filter, in this case
    # it will parse url and reset conn structure
    ossweb::conn -parse_url

    # Global variables that contains current command name
    upvar #$level ossweb:cmd cmd_name ossweb:ctx ctx_name ossweb:page page_name ossweb:app app_name
    upvar #$level ossweb:caller caller ossweb:user user ossweb:uagent uagent

    set app_name [ossweb::conn app_name]
    set page_name [ossweb::conn page_name]
    set cmd_name [ossweb::conn cmd_name]
    set ctx_name [ossweb::conn ctx_name]
    set caller [ossweb::conn caller]
    set user [ossweb::conn user_id]
    set uagent [ns_set iget [ns_conn headers] user-agent]

    # Initialize columns with default values
    ossweb::conn::init_vars -level $level -force $query $columns
    if { $columns2 != "" } {
      ossweb::conn::init_vars -level $level -force $query $columns2
    }

    # Get query parameters if we didn't get it yet
    if { $query == "t" || [ossweb::conn __query:got] == "" } {
      ossweb::conn -set __query:got 1
      ossweb::conn::query -level $level -columns $columns -debug $debug -array $queryarray
      if { $columns2 != "" } {
        ossweb::conn::query -level $level -columns $columns2 -debug $debug
      }
      if { $debug == "a" } {
        ns_set print [ns_conn headers]
      }
    }

    # Process session variables, only once
    if { $sessionvars != "" && [ossweb::conn __sessionvars:got] == "" } {
      ossweb::conn -set __sessionvars:got 1
      eval ossweb::conn::sessionvars \
                -global $sessionvars_global \
                -clear $sessionvars_clear \
                -level $level \
                -query t \
                 $sessionvars
    }

    # Form tracking,disable double submits
    if { $form_tracking == "t" &&
         [ossweb::conn __tracking:checked] == "" &&
         [set tracking_id [ns_queryget form:track:id]] != "" } {
      ossweb::conn -set __tracking:checked 1
      set tracking_list [ossweb::conn::get_property OSSWEB:FORM:TRACKING -global t -cache t -db t]
      # Clear current list
      if { $form_tracking_clear == "t" } {
        set tracking_list ""
      }
      if { [ossweb::lexists $tracking_list $tracking_id] } {
        ossweb::conn::log Notice ossweb::conn::process page expired: $tracking_id
        ossweb::conn::set_msg -color red "This page has been already expired, please to not use Back button"
        uplevel #$level eval ossweb::conn::next -debug $debug $on_error
        set app_name [ossweb::conn app_name]
        set page_name [ossweb::conn page_name]
        set cmd_name [ossweb::conn cmd_name]
        set ctx_name [ossweb::conn ctx_name]
        return -1
      }
      if { [llength $tracking_list] > 100 } {
        set tracking_list [lrange $tracking_list end-25 end]
      }
      lappend tracking_list $tracking_id
      ossweb::conn::set_property OSSWEB:FORM:TRACKING $tracking_list -global t -cache t -db t
    }

    # Generate new unique request id
    ossweb::conn -set form:track:id [ossweb::conn session_id][ns_time]
    # Validate variables
    foreach item $validate {
      set name [lindex $item 0]
      set type [lindex $item 1]
      set code [lindex $item 2]
      set errMsg [lindex $item 3]
      if { [ossweb::datatype::validate $name $type -code $code -errmsg errMsg -level 1] } {
        ossweb::conn::log Notice ossweb::conn::process '$name' validation failed ($code), set template to '$on_error'
        ossweb::conn::set_msg -color red [ossweb::nvl $errMsg "$name is invalid"]
        uplevel #$level eval ossweb::conn::next -debug $debug $on_error
        set app_name [ossweb::conn app_name]
        set page_name [ossweb::conn page_name]
        set cmd_name [ossweb::conn cmd_name]
        set ctx_name [ossweb::conn ctx_name]
        return -1
      }
    }
    # Remember execution stack
    set stack [ossweb::adp::Length]
    # Execute global Tcl code
    if { $exec != "" } {
      if { $debug != "f" } {
        ossweb::conn::log Notice ossweb::conn::process:: calling $exec
      }
      switch -- [catch { uplevel #$level $exec } errMsg] {
       0 - 4 {}
       2 - 3 {
         ossweb::conn::log Notice Returning from global exec
         return 0
       }
       default {
         if { $errMsg == "OSSWEB_EXIT" } {
           error OSSWEB_EXIT
         }
         # Show application specific errors
         if { [regexp {^(OSSWEB|OSS):*} $errMsg] } {
           set start [expr [string first : $errMsg] + 1]
           ossweb::conn::set_msg -color red [string range $errMsg $start end]
         } else {
           ossweb::conn::set_msg -color red $on_error_set_msg
           ossweb::conn::log Error ossweb::conn::process: "QUERY: [ossweb::convert::set_to_list [ns_getform]]: $errMsg: $errorInfo"
         }
         ossweb::conn::log Notice ossweb::conn::process exec failed, set template to '$on_error'
         uplevel #$level eval ossweb::conn::next -debug $debug $on_error
         set app_name [ossweb::conn app_name]
         set page_name [ossweb::conn page_name]
         set cmd_name [ossweb::conn cmd_name]
         set ctx_name [ossweb::conn ctx_name]
         return -1
       }
      }
    }
    # Execute pre-creation SQL
    if { $sql_stmt != "" } {
      set sql $sql_stmt
      uplevel #$level { set __rc [ossweb::db::multivalue [subst $__sql]] }
      if { $rc } {
        ossweb::conn::log Notice ossweb::conn::process SQL failed: set template to '$on_error'
        ossweb::conn::set_msg -color red $on_error_set_msg
        uplevel #$level eval ossweb::conn::next -debug $debug $on_error
        set app_name [ossweb::conn app_name]
        set page_name [ossweb::conn page_name]
        set cmd_name [ossweb::conn cmd_name]
        set ctx_name [ossweb::conn ctx_name]
        return -1
      }
    }
    # If template has been changed in global exec just exit
    if { $stack != [ossweb::adp::Length] } {
      ossweb::conn::log Notice ossweb::conn::process: template has been changed from $page_name.$cmd_name.$ctx_name
      set rc 0
    } else {
      # Executes normal Tcl code for the current command
      set rc [ossweb::conn::dispatch]
    }
    set app_name [ossweb::conn app_name]
    set page_name [ossweb::conn page_name]
    set cmd_name [ossweb::conn cmd_name]
    set ctx_name [ossweb::conn ctx_name]
    # Last final handler
    if { $final != "" } {
      if { $debug != "f" } {
        ossweb::conn::log Notice ossweb::conn::process:: calling $final
      }
      if { [catch { uplevel #$level $final } errMsg] } {
        ossweb::conn::log Error ossweb::conn::process: FINAL: [ossweb::convert::set_to_list [ns_getform]]: $errMsg: $errorInfo
      }
    }
    return $rc
}

# Executes command handler which is in format of -eval
# flag for ossweb::conn::process_request.
#  code_ref contains reference on Tcl handler description in caller frame
#  level specifies how many levels up the code should be executed
proc ossweb::conn::dispatch { args } {

    upvar 1 eval eval \
            default default \
            debug debug \
            forms forms \
            form_error form_error \
            form_recreate form_recreate \
            form_create form_create \
            required required \
            validate validate \
            transaction transaction \
            form_validate form_validate \
            next next \
            on_error on_error \
            on_error_set_msg on_error_set_msg \
            on_error_set_cmd on_error_set_cmd \

    set exec ""
    set args ""
    set index -1
    set level [ossweb::adp::Level]
    set cookie [ossweb::adp::Cookie]
    # Command could be changed, so we need fresh value.
    set cmd_name [ossweb::conn cmd_name]
    # Search eval for command or use default if not found.
    if { [set ctx_name [ossweb::conn ctx_name]] != "" } {
      set index [lsearch -exact $eval "$cmd_name.$ctx_name"]
      if { $index == -1 &&
           [info proc ::ossweb::adp::cache::$cmd_name.$ctx_name] != "" &&
           [::ossweb::adp::cache::$cmd_name.$ctx_name] == $cookie } {
        set exec $cmd_name.$ctx_name
      }
    }
    # Try exact command handler
    if { $index == -1 && $exec == "" } {
      set index [lsearch -exact $eval $cmd_name]
      if { $index == -1 &&
           [info proc ::ossweb::adp::cache::$cmd_name] != "" &&
           [::ossweb::adp::cache::$cmd_name] == $cookie } {
        set exec $cmd_name
      }
    }
    # If no exec method found we can still try default handler
    if { $index == -1 && $exec == "" } {
      set index [lsearch -exact $eval default]
      # Last resort, -default callback
      if { $index == -1 } {
        set exec $default
      }
    }
    # Command block found, parse it
    if { $exec == "" && $index != -1 } {
      incr index
      set args [lindex $eval $index]
      # Take handler from the next command
      while { [string equal $args -] } {
        incr index 2
        set args [lindex $eval $index]
      }
      # Process handler arguments
      ns_parseargs { -exec
                     -forms
                     -debug
                     -form_create
                     -form_error
                     -on_error
                     -on_error_set_msg
                     -next
                     -validate
                     -transaction
                     -form_recreate
                     -form_validate } $args
    }

    # Re-create all forms
    if { $form_recreate != "f" } {
      foreach form [ossweb::decode $form_recreate t $forms] {
        if { [ossweb::form $form exists] } {
          # We have to save form error messages
          if { [set error [ossweb::form $form error]] != "" } {
            ossweb::conn::set_msg -color red $error
          }
          ossweb::form $form destroy
        }
      }
    }
    # Create forms before validation
    foreach form $forms {
      if { ![ossweb::form $form exists] } {
        set create_proc [ossweb::nvl $form_create create_$form]
        if { $debug != "f" } {
          ossweb::conn::log Notice ossweb::conn::process:: calling $create_proc
        }
        if { [catch { uplevel 2 $create_proc } errMsg] } {
          if { $errMsg == "OSSWEB_EXIT" } {
            error OSSWEB_EXIT
          }
          global errorInfo
          ossweb::conn::log Notice ossweb::conn::request $form creation failed: $errMsg, $errorInfo, set template to '$on_error'
          ossweb::conn::set_msg -color red $errMsg
          uplevel #$level eval ossweb::conn::next -debug $debug $on_error
          return -1
        }

        # Run script phase to egenrate common javascript in the HEAD
        ossweb::form $form script
      }
    }
    # All forms should be validated
    switch -- [lindex $form_validate 0] {
     all {
        set form_validate $forms
     }
     none {
        set forms {}
     }
    }
    # Validate submitted form
    foreach form $forms {
      set submitted [ossweb::form $form submitted]
      # Form should be in submission state or mentioned in validation list
      if { $submitted == "f" && [lsearch -exact $form_validate $form] == -1 } {
        continue
      }
      # Already validated
      if { [ossweb::conn __form_validated:$form] == "1" } {
        continue
      }
      # Mark it as validated, we keep it here as well in case of form_recreate flag
      # so form will not be validated twice
      ossweb::conn -set __form_validated:$form 1
      # Clear submission flag so application will not validate it anymore
      ossweb::form $form -submitted f
      # Perform form validation
      if { ![ossweb::form $form validate] } {
        # Form is ok, now we can put form values into Tcl variables
        ossweb::form $form get_values -level $level -array [ossweb::form $form array]
        continue
      }
      # Validation failed, put form error into the system message
      if { $submitted == "t" && [ossweb::form $form error] != "" } {
        ossweb::conn::set_msg -color red [ossweb::form $form error]
      }

      set on_formerror [ossweb::nvl [ossweb::form $form on_error] $on_error]
      ossweb::conn::log Notice ossweb::conn::request form $form validation failed ([ossweb::form $form error]), set template to '$on_formerror'
      uplevel #$level eval ossweb::conn::next -debug $debug $on_formerror
      return -1
    }
    # Validate variables
    foreach item $validate {
      set name [lindex $item 0]
      set type [lindex $item 1]
      set code [lindex $item 2]
      set errMsg [lindex $item 3]
      if { [ossweb::datatype::validate $name $type -code $code -errmsg errMsg -level $level] } {
        ossweb::conn::log Notice ossweb::conn::request '$name' validation failed ($errMsg), set template to '$on_error'
        ossweb::conn::set_msg -color red [ossweb::nvl $errMsg "$name is invalid"]
        uplevel #$level eval ossweb::conn::next -debug $debug $on_error
        return -1
      }
    }
    # Execute Tcl code if specified, catch all errors and show them in log file and web page
    if { $exec != "" } {
      if { $debug != "f" } {
        ossweb::conn::log Notice ossweb::conn::process:: calling $exec
      }
      if { $transaction == "t" } {
        ossweb::db::begin
      }
      set stack [ossweb::adp::Length]
      switch -- [catch { uplevel #$level $exec } errMsg] {
       0 - 2 - 3 - 4 {}
       default {
         if { $errMsg == "OSSWEB_EXIT" } {
           error OSSWEB_EXIT
         }
         # Show application specific errors
         if { [regexp {^(OSSWEB|OSS):*} $errMsg] } {
           set start [expr [string first : $errMsg] + 1]
           ossweb::conn::set_msg -color red [string range $errMsg $start end]
         } else {
           ossweb::conn::set_msg -color red $on_error_set_msg
           global errorInfo
           ossweb::conn::log Error ossweb::conn::process QUERY: [ossweb::convert::set_to_list [ns_getform]]: $errMsg: $errorInfo
         }
         ossweb::db::rollback
         ossweb::conn::log Notice ossweb::conn::request exec failed ($errMsg), set template to '$on_error'
         uplevel #$level eval ossweb::conn::next -debug $debug $on_error
         return -1
       }
      }
      if { $transaction == "t" } {
        ossweb::db::commit
      }
      # Switch to next template only if the stack is the same as before Tcl code execution
      if { $stack != [ossweb::adp::Length] } {
        return 0
      }
    }
    # Go to specified template after code evaluation
    if { $next != "" } {
      ossweb::conn::log Notice ossweb::conn::request next template '$next'
      uplevel #$level eval ossweb::conn::next -debug $debug $next
    }
    return 0
}

# Issues signed user cookies.
# user_id variable should be set using
# ossweb::conn -set user_id $user_id before calling this proc.
# -max_age specifies lifetime for the user cookie
proc ossweb::conn::set_user_id { args } {

    ns_parseargs { {-domain {[ossweb::config session:domain]}}
                   {-cookie {[ossweb::config session:cookie:user user_id]}}
                   {-max_age {[ossweb::config session:timeout 3600]}}
                   {-path /}
                   {-secure f}
                   {-clear f}
                   {-user_id {[ossweb::conn user_id]}} } $args

    if { $clear == "t" } {
      ns_deletecookie -domain $domain -path $path $cookie
      return
    }
    # Not given or already set
    if { $user_id == "" } {
      return
    }
    ossweb::conn::sign_cookie -max_age $max_age -domain $domain -path $path -secure $secure $cookie $user_id
    # Save user in the runtime cache
    ossweb::conn -set user_id $user_id
}

# Issues signed session cookies for current user.
# User should be assigned with user id already.
# -max_age specifies lifetime for session cookie
# -new if t generates new session
proc ossweb::conn::set_session_id { args } {

    ns_parseargs { {-max_age {[ossweb::config session:timeout 3600]}}
                   {-domain {[ossweb::config session:domain]}}
                   {-cookie {[ossweb::config session:cookie:id session_id]}}
                   {-secure f}
                   {-path /}
                   {-new f}
                   {-clear f}
                   {-data ""}
                   {-session ""}
                   {-user_id {[ossweb::conn user_id]}} } $args

    if { $clear == "t" } {
      ns_deletecookie -domain $domain -path $path $cookie
      return
    }
    if { $user_id == "" } {
      return
    }
    # We have special case whereby we assign new session id every time for better security.
    set id [ossweb::conn session_id]
    if { $id == "" || $new == "t" || [ossweb::true [ossweb::config session:new 0]] } {
      set id [ossweb::conn -new_session_id]
    }
    # Additional session data, no space between id and data
    if { $data != "" } {
      append id $data
    }
    # Previously specified session, used in session renewal
    if { $session == "" } {
      set session "$id $user_id"
    }
    # Combined session cookie: session_id,user_id
    ossweb::conn::sign_cookie -max_age $max_age -domain $domain -path $path -secure $secure $cookie $session
}

# Redirect and abort processing
# If abort is set to 1, fires exception to stop template processing
proc ossweb::conn::redirect { url args } {

    ns_parseargs { {-exit t} {-log f} } $args

    if { ![regexp {^https?://} $url] } {
      if { [string index $url 0] != "/" } {
        set url [ossweb::dirname [ns_conn url]]$url
      }
      set url [ossweb::conn::hostname]$url
    }
    if { [ns_conn isconnected] } {
      ns_returnredirect $url
    }
    if { $log == "t" } {
      ossweb::conn::log Notice Redirecting to $url
    }
    if { $exit == "t" } {
      ossweb::adp::Exit
    }
}

# Redirects user to login page.
# When login process will complete, the user will be returned
# to the current location if -redirect t. All variables in ns_getform
# (both posts and gets) will be maintained.
proc ossweb::conn::redirect_for_login { args } {

    ns_parseargs { {-url ""} {-redirect t} {-callbacks t} } $args

    # Run registered callbacks if user need to be logged in
    if { $callbacks == "t" } {
      foreach name [lsort [eval "namespace eval ::ossweb::control::nosession { info procs }"]] {
        if { [catch { set rc [::ossweb::control::nosession::$name] } errmsg] } {
          if { $errmsg != "OSSWEB_EXIT" } {
            ns_log Error ossweb::conn::redirect_for_login: $name: $errmsg
          }
          set rc ""
        }
        switch -- $rc {
         filter_return - filter_ok {
           break
         }
        }
      }
    }
    # Redirection is already done, just exit
    if { ![ns_conn isconnected] } {
      return 1
    }
    # Regular login redirection processing
    set project [ossweb::conn project_name]
    set public [ossweb::config server:project:public]
    # Redirect to the same url after login
    if { $redirect == "t" } {
      set url [ossweb::conn -url -host t]
    }
    # Try same url in the public project
    if { $url != "" && $public != "" && $project != $public } {
      if { [regsub "/($project)/" $url "/$public/" url] } {
        ns_log Notice ossweb::conn::redirect_for_login: $url
        ns_returnredirect $url
        return 1
      }
    }
    # Project specific first
    set login_url [ossweb::project login_url]
    if { $login_url == "" } {
      set login_url [ossweb::config security:url:login [ossweb::html::url -project_name $project -app_name pub login]]
    }
    # Build full redirect url to the login page
    set login_url [ossweb::html::url -url $login_url url (hex):$url]

    # See if this is our login url already, prevent loops, strip out everything except url
    set url $login_url
    if { [string index $url 0] != "/" && [set idx [string first / $url]] > 0 } {
      set url [string range $url $idx end]
    }
    if { [set idx [string first ? $url]] > 0 } {
      set url [string range $url 0 [incr idx -1]]
    }
    if { [string match [ns_conn url] $url] } {
      return 0
    }
    ossweb::conn::redirect $login_url
    return 1
}

# Redirects user because of access denied situation, user tried to acces the page
# which is not allowed for him.
proc ossweb::conn::redirect_access_denied { args } {

    ns_parseargs { {-msg accessdenied} } $args

    # Run registered callbacks on user not having access rights
    foreach name [lsort [eval "namespace eval ::ossweb::control::noaccess { info procs }"]] {
      if { [catch { set rc [::ossweb::control::noaccess::$name] } errmsg] } {
        if { $errmsg != "OSSWEB_EXIT" } {
          ns_log Error ossweb::conn::redirect_access_denied: $name: $errmsg
        }
        set rc ""
      }
      switch -- $rc {
       filter_return - filter_ok {
         break
       }
      }
    }
    # Redirection is already done, just exit
    if { ![ns_conn isconnected] } {
      return
    }
    # Regular access denied processing
    set referer [ossweb::nvl [ns_set get [ns_conn headers] Referer]]
    set error_url [ossweb::project error_url]
    # Project specific first
    if { $error_url == "" } {
      set error_url [ossweb::config security:url:accessdenied [ossweb::html::url -app_name pub index]]
    }
    ossweb::conn::log Notice "Access Denied, Referer=$referer"
    ossweb::conn::redirect [ossweb::html::url -url $error_url msg $msg url $referer]
}

# Returns a digital signature of the value.
#  -max_age specifies the length of time the signature is
#           valid in seconds. The default is forever.
#  value the value to be signed.
proc ossweb::conn::sign { args } {

    ns_parseargs { {-max_age ""} -- value } $args

    set seed [ossweb::random]
    set secret [ossweb::conn::secret $seed]
    if { $max_age == "-1" || $max_age == "" } {
      set expires 2051240400
    } else {
      set expires [expr $max_age + [ns_time]]
    }
    set hash [ns_sha1 "$value$seed$expires$secret"]
    return [list $seed $expires $hash]
}

# Retrieves a signed cookie value. Validates a cookie against its
# cryptographic signature and insures that the cookie has not expired.
# If validation fails returns empty string
#  -set_cookies t gets cookie from Set-Cookie header
#  -set_expires t returns a list with value and expiration date
proc ossweb::conn::signed_cookie { args } {

    ns_parseargs { {-set_expires f} -- name } $args

    set cookie [ns_getcookie $name ""]
    if { $cookie == "" } {
      return
    }
    set value [lindex $cookie 0]
    set signature [lindex $cookie 1]
    set seed [lindex $signature 0]
    set expires [lindex $signature 1]
    set hash [ns_sha1 "$value$seed$expires[ossweb::conn::secret $seed]"]
    if { $hash != [lindex $signature 2] || $expires <= [ns_time] } {
      ns_log Notice ossweb::conn::signed_cookie: $name: verification failed, $cookie
      return
    }
    if { $set_expires == "t" } {
      return "$value $expires"
    }
    return $value
}

# Cookie signature
# Acceptes the same arguments as ossweb::conn::set_cookie
proc ossweb::conn::sign_cookie { args } {

    ns_parseargs { {-secure 0}
                   {-max_age ""}
                   {-domain ""}
                   {-path ""} -- name value } $args

    set cookie_value [ossweb::conn::sign -max_age $max_age $value]
    set data [list $value $cookie_value]
    set params ""
    if { $secure } {
      append params "-secure $secure "
    }
    if { [string is integer $max_age] && $max_age > 0 } {
      append params "-expires $max_age "
    }
    if { $domain != "" } {
      append params "-domain $domain "
    }
    if { $path != "" } {
      append params "-path $path "
    }
    eval "ns_setcookie $params $name {$data}"
    if { [ossweb::config security:debug 0] > 1 } {
      ns_log Notice ossweb::conn::sign_cookie: $name: domain=$domain, path=$path, max_age=$max_age, value=$value, $data: [ossweb::convert::set_to_list [ns_conn headers]]
    }
}

# Parses request url and sets security tokens in global connection
# variable which can be accessed via ossweb::conn.
# Items extracted are:
#   project_name  - user project it belongs to
#   app_name  - name of current application
#   page_name - page within current application, implements basic logic
#               of the application
#   cmd_name  - operation that is executed within current context. There are
#               standard set of permitted commands.
#   ctx_name  - context within current command, implements different
#               commands for differents parts of one application context
#   url       - name of current file name, to be used in constructing
#               request urls, use [ossweb::conn url] instead of [ns_conn url].
proc ossweb::conn::parse_url {} {

    set ext [ossweb::config server:extension "oss"]
    set cmd [ns_queryget cmd]
    # Setting command context environment
    ossweb::conn -set ctx_name [ns_queryget ctx unknown]
    if { $cmd != "" } {
      # Context inside command has higher priority than query parameter
      set cmd [split [string tolower $cmd] "."]
      ossweb::conn -set cmd_name [lindex $cmd 0]
      if { [llength $cmd] == 2 } {
        ossweb::conn -set ctx_name [lindex $cmd 1]
      }
    } else {
      ossweb::conn -set cmd_name view
    }

    # Check/resolve request url, if user specified only
    # directory, try to resolve it into default index page
    set url [ns_conn url]

    # We rely on server's configured index pages if don't have one here
    set pageroot [ossweb::config server:path:root [ns_info pageroot]]
    if { [ns_filestat "$pageroot$url" stat] && $stat(type) == "directory" } {
      if { [ns_filestat "$pageroot$url/index.adp"] } {
        append url "/" "index.$ext"
      }
    }

    # Save full url
    ossweb::conn -set url $url

    # Setting application context environment
    set dir [split $url /]
    set len [llength $dir]
    set last ""

    # Project name is the first directory in the url path
    set project_name [lindex $dir 1]
    if { $project_name != "" && [file isdirectory "$pageroot/$project_name"] } {
      ossweb::conn -set project_name $project_name
      set last $project_name
    }

    # Application name is the second directory
    set app_name [lindex $dir 2]
    if { $app_name != "" && [file isdirectory "$pageroot/$project_name/$app_name"] } {
      ossweb::conn -set app_name $app_name
      set last $app_name
    }

    # Page name is the last one
    set page_name [lindex $dir end]
    if { $page_name != "" && $page_name != $last } {
      # Only strip our application extension
      if { [file extension $page_name] == ".$ext" } {
        set page_name [file rootname $page_name]
      }
      ossweb::conn -set page_name $page_name
    }

    # Other reserved parameters
    ossweb::conn -set caller [ns_queryget caller]
}

# Parses user cookies, sets ossweb::conn with user info.
# Returns user_id on success, otherwise empty
proc ossweb::conn::parse_user { { cookie "" } } {

    # Request initialization
    ossweb::conn -reset
    # Parse request for aplication information, extract names and command
    ossweb::conn::parse_url
    # Read user record
    return [ossweb::conn::read_user \
                 [ossweb::conn::signed_cookie \
                       [ossweb::nvl $cookie [ossweb::config session:cookie:user user_id]]]]
}

# Validates session cookies, if valid sets user_id and session_id in the ossweb::conn.
# Returns session_id if verified, otherwise empty
proc ossweb::conn::parse_session { user_id args } {

    ns_parseargs { {-cookie {[ossweb::config session:cookie:id session_id]}}
                   {-check_ip ""} } $args

    set now [ns_time]
    set timeout [ossweb::config session:timeout]
    # Session cookie: session_id user_id expiration
    set session [ossweb::conn::signed_cookie -set_expires t $cookie]
    set session_id [lindex $session 0]
    set session_user [lindex $session 1]
    set session_expires [lindex $session 2]
    # Cookie may not exist, tampered or expired
    if { [ossweb::conn session-access-$session_id] == "" || $session_user != $user_id } {
      if { [ossweb::config security:debug 0] > 0 } {
        ns_log Notice ossweb::conn::parse_session: [ns_conn url]: $user_id/$session_id: session mismatch: [ossweb::convert::set_to_list [ns_conn headers]]
      }
      return
    }
    # Check for expired session
    if { $timeout != "" && $now - [ossweb::conn session-access-$session_id] > $timeout } {
      if { [ossweb::config security:debug 0] > 0 } {
        ns_log Notice ossweb::conn::parse_session: [ns_conn url]: $user_id/$session_id: session expired: [ossweb::convert::set_to_list [ns_conn headers]]
      }
      return
    }
    # Check IP address of the session
    if { [ossweb::true [ossweb::config session:check:ip]] &&
         [ossweb::conn session-ip-$session_id] != [ns_conn peeraddr] } {
      ns_log Notice ossweb::conn::read_user: [ns_conn url]: $user_id/$session_id: incorrect session IP address [ns_conn peeraddr]
      return
    }
    # Update session cache
    ossweb::conn -set user_id $user_id session_id $session_id
    # Re-issue session cookie so session doesn't expire if the renewal period has passed
    if { $session_expires - [ossweb::config session:renew 300] < $now } {
      ossweb::conn::set_session_id
      if { [ossweb::config security:debug 0] > 0 } {
        ns_log Notice ossweb::conn::parse_session: [ns_conn url]: $user_id: $cookie: session renew
      }
    }
    # Update access time
    ossweb::admin::update_session -interval 60 access_time $now
    return $session
}

# Verifies current request for for valid user/session information.
# Sets ossweb::conn with user info
proc ossweb::conn::parse_request {} {

    if { [set user_id [ossweb::conn::parse_user]] == "" ||
         [ossweb::conn::parse_session $user_id] == "" } {
      return
    }
    return $user_id
}

# Returns user_id if the user_id is correct id. Populate user information
# into global connection array, ossweb::conn. Required variables that are set here are:
# user_id, session_id, user_name, user_email and all fields from users table.
# Called in security filter, in case of succesfull user verification, user info is
# available in the applicatiuon through ossweb::conn method.
# -check_password if specified, also compares user password, used for login procees.
# Otherwise returns empty string.
proc ossweb::conn::read_user { user_id args } {

    ns_parseargs { {-user_name ""}
                   {-user_email ""}
                   {-check_password ""}
                   {-cache ""}
                   {-refresh f}
                   {-timeout 900} } $args

    if { $user_id == "" && $user_name == "" && $user_email == "" } {
      return
    }
    # Do not use cache if we are checking password, otherwise perform cacheable query
    if { $check_password != "" } {
      set refresh t
    }
    # Special case when used with user_id, we use default cache
    if { $user_id != "" } {
      set cache user:$user_id:
    }
    # Read record
    if { [ossweb::db::multivalue sql:ossweb.user.read \
               -refresh $refresh \
               -cache $cache \
               -array userArray \
               -arrayvars user_prefs \
               -local t \
               -vars { status "" first_name "" last_name "" } \
               -timeout $timeout] } {
      return
    }
    set rc 0
    set user_id $userArray(user_id)
    set userArray(full_name) "$userArray(first_name) $userArray(last_name)"

    # Check password if specified, run through local digests first
    if { $check_password != "" } {
      # Run authentication plugins, they require plain text password to be used in most cases,
      # plugin should return 1 if authenticated, stop at first success
      foreach name [ossweb::config security:auth:list [lsort [eval "namespace eval ::ossweb::control::auth { info procs }"]]] {
        if { [catch { set rc [::ossweb::control::auth::$name $userArray(user_name) $check_password -array userArray] } errmsg] } {
          ns_log Error ossweb::control::auth::$name: $userArray(user_name)/$user_id: $errmsg
        }
        if { $rc != 1 } {
          ns_log Notice ossweb::control::auth::$name: $userArray(user_name)/$user_id: authentication FAILED
        } else {
          ns_log Notice ossweb::control::auth::$name: $userArray(user_name)/$user_id: authentication OK
          break
        }
      }

      # No success, just exit with error
      if { $rc == 0 } {
        ns_log Notice ossweb::conn::read_user: incorrect password, $userArray(user_id), $userArray(full_name)
        return
      }
    }
    # Check account state
    switch -- $userArray(status) {
     active {
       # Active user account
     }

     onetime {
       # Can login onetime only, password will be cleared after successfull login
       ossweb::admin::update_user \
            -user_id $user_id \
            -flush t \
            status active \
            salt [ossweb::random] \
            salt2 [ossweb::random]
       # Display warning message in case inmemory routing
       ossweb::conn::set_msg -color red [ossweb::message onetime]
       # Create temporary login handler to add warning message in case of redirect
       proc ::ossweb::control::login::zz_onetime {} {
          ossweb::conn -append redirect_url ?&msg=onetime
       }
     }

     default {
       ossweb::admin::flush_user $user_id
       ns_log Error ossweb::conn::read_user: account is not active($userArray(status)), $userArray(user_id), $userArray(full_name)
       return
     }
    }
    set now [ns_time]
    set userArray(ipaddr) ""
    set userArray(session_id) ""
    set sessionList [list]
    # Prepare quick access to user sessions
    foreach { session_id login_time access_time ipaddr } $userArray(user_sessions) {
      lappend sessionList $session_id
      set userArray(session-access-$session_id) $access_time
      set userArray(session-ip-$session_id) $ipaddr
    }
    unset userArray(user_sessions)
    eval ossweb::conn -set user_id $user_id session-list {$sessionList} [array get userArray]

    # Update Naviserver auth set, it may be used by PHP or other external tools
    set auth [ns_conn auth]
    if { $auth != "" } {
      ns_set update $auth Username $userArray(user_name)
      ns_set update $auth Userid $user_id
    }

    # Load all permissions
    ossweb::conn::read_acl $user_id
    return $user_id
}

# Read permissions list and store it into ns_set
proc ossweb::conn::read_acl { obj_id args } {

    ns_parseargs { {-obj_type U} {-reset t} } $args

    if { $reset == "t" } {
      ossweb::conn -reset_acl
    }

    ossweb::db::multirow user:$obj_id:acl sql:ossweb.acls.list \
         -local t \
         -cache t \
         -timeout 86400 \
         -eval {
      # Put all ACLs into local connection structure
      ossweb::conn -new_acl $project_name $app_name $page_name $cmd_name $ctx_name $value $query $handlers

      if { [ossweb::config security:debug 0] > 3 } {
        ossweb::conn::log Notice ossweb::conn::read_acl $project_name.$app_name.$page_name.$cmd_name.$ctx_name=$value ($query) ($handlers)
      }
    }
}

# Returns 0 if the user has permission to perform operation
# within current application's context.
# If no arguments are given, current access tokens are used otherwise
# -project_name, -app_name, -page_name, -cmd_name, -ctx_name may be specified separately, or
# -acl with combined five elements in one string may be given.
# -query Y tells that additional query parameters should be checked against submitted query data.
# -handlers Y tells to check all data-aware handlers
# -params is a list { name value } of parameters which should be put into
#         query set to be appeared as they are submitted by the browser
#
# Ex. ossweb::conn::check_acl -acl "*.*.*.add.*"
#
proc ossweb::conn::check_acl { args } {

    ns_parseargs { {-acl ""}
                   {-project_name ""}
                   {-app_name ""}
                   {-page_name ""}
                   {-cmd_name ""}
                   {-ctx_name ""}
                   {-query N}
                   {-handlers N}
                   {-params ""}
                   {-unknown unknown}
                   {-debug f} } $args

    # Full ACL is given
    if { $acl != "" } {
      set acl [split $acl "."]
      set project_name [lindex $acl 0]
      set app_name [lindex $acl 1]
      set page_name [lindex $acl 2]
      set cmd_name [lindex $acl 3]
      set ctx_name [lindex $acl 4]
    }
    set project_name [ossweb::coalesce project_name $unknown]
    set app_name [ossweb::coalesce app_name $unknown]
    set page_name [ossweb::coalesce page_name $unknown]
    set cmd_name [ossweb::coalesce cmd_name view]
    set ctx_name [ossweb::coalesce ctx_name $unknown]
    # Public applications don't have access restrictions for current project
    if { $app_name == "pub" && ($project_name == "*" || $project_name == [ossweb::conn project_name]) } {
      return 0
    }
    # Put params into query form
    if { $params != "" && [set form [ns_getform]] != "" } {
      foreach { name value } $params {
        if { [ns_queryexists $name] } {
          set psave($name) [ns_queryget $name]
        }
        ns_set update $form $name $value
      }
    }
    # Get permission value for this access context
    set acl [ossweb::conn -acl $project_name $app_name $page_name $cmd_name $ctx_name $query $handlers]
    # Restore original parameters
    if { $params != "" && $form != "" } {
      foreach { name value } $params {
        ns_set delkey $form $name
      }
      foreach { name value } [array get psave] {
        ns_set update $form $name $value
      }
    }
    if { $acl == "Y" } {
      return 0
    }
    return -1
}

# Adds new ACL record for specified user.
# -query which should be in format name=val&name=val.. will
# be converted into plain list of name/value pairs.
# Each value should be one word only.
proc ossweb::conn::create_acl { obj_id args } {

    ns_parseargs { {-project_name {[ossweb::conn project_name]}}
                   {-app_name *}
                   {-page_name *}
                   {-cmd_name *}
                   {-ctx_name *}
                   {-value Y}
                   {-query ""}
                   {-handlers ""}
                   {-precedence ""}
                   {-obj_type U} } $args

    regsub -all {\n\r\t} $query {} query
    # Verify security handlers, proc should exist
    regsub -all {\n\r\t} $handlers {} handlers
    # Add new ACL record
    if { [ossweb::db::exec sql:ossweb.acls.create] } {
      return -1
    }
    # Flush acl list for this id from the cache
    ossweb::db::cache flush user:$obj_id:acl
    return 0
}

# Returns the shared secret that can be used for encryption.
proc ossweb::conn::shared_secret {} {

    return [ossweb::config server:secret "213454mgrkjjktrn8439brvrvdmvdsh4380487r094fj2fn2;fcm;lcmfnvjn438henfknefwlk"]
}

# Returns the secret corresponding to the seed
proc ossweb::conn::secret { seed } {

    return [ns_sha1 "$seed[ossweb::conn::shared_secret]"]
}

# Sets global error or info message that will be displayed on the main index
# page under the top toolbar. Most recent messages are placed at the beginning
# of the message list by default.
#  -color specifies color for this message
#  -standard points that message is standard messages stored in msgs table
#                  and here we pass only id of this messages.
#  -new if set to t removes all previous messages
proc ossweb::conn::set_msg { args } {

    ns_parseargs { {-color ""} {-standard f} {-new f} -- msg } $args

    if { $standard == "t" } {
      set msg [ossweb::message $msg]
    }
    set list [ossweb::conn msg]
    # Do not save duplicate messages
    if { [string first $msg $list] > -1 } { return }
    if { $color != "" } {
      set msg "<FONT COLOR=$color>$msg</FONT>"
    }
    # Add to the current message
    if { $new == "f" && $list != "" } {
      set msg "$msg<BR>$list"
    }
    ossweb::conn -set msg $msg
}

# Returns HTTP header value
proc ossweb::conn::header { name } {

    if { [ns_conn isconnected] } {
      return [ns_set iget [ns_conn headers] $name]
    }
    return
}

# Returns full hostname and port for current HTTP server
proc ossweb::conn::hostname { { proto "http://" } } {

    set location ""
    if { [ns_conn isconnected] } {
      set location [ns_conn location]
    }
    if { $location == "" } {
      set location "$proto[ns_info hostname]"
      if { [set port [ns_config "ns/server/[ns_info server]/module/nssock" port]] != 80 } {
        append location : $port
      }
    }
    # Replace protocol part if different
    if { $proto != "" && $proto != "http://" } { regsub {http://} $location $proto location }
    return $location
}

# Returns 1 if connection from local network
proc ossweb::conn::localnetwork { { ipaddr "" } } {

    if { $ipaddr == "" } {
      set ipaddr [ossweb::conn peeraddr]
    }
    if { $ipaddr == "127.0.0.1" } {
      return 1
    }
    set client [join [lrange [split $ipaddr .] 0 end-1] .]
    set network [ossweb::config server:network:local]
    lappend network [join [lrange [split [ns_addrbyhost [ns_info hostname]] .] 0 end-1] .]
    if { [lsearch -exact $network $client] > -1 } {
      return 1
    }
    return 0
}

# Filter for access verification, should be installed as preauth filter.
# It takes care about cookies and session management.
proc ossweb::conn::filter::secure { args } {

    catch {
      set user_id [ossweb::conn::parse_user]
      # Public applications don't require any authentication
      if { [ossweb::conn app_name] == "pub" } {
        return filter_ok
      }
      # user_id is not available and this is restricted page, redirect to login page
      if { $user_id == "" } {
        # It may decide that theer is no need for redirection
        if { ![ossweb::conn::redirect_for_login] } {
          return filter_ok
        }
        return filter_return
      }
      # Validate session cookies
      if { [ossweb::conn::parse_session $user_id] == "" } {
        if { ![ossweb::conn::redirect_for_login] } {
          return filter_ok
        }
        return filter_return
      }
      # Here we perform user authorization
      if { [ossweb::conn::check_acl \
                 -project_name [ossweb::conn project_name] \
                 -app_name [ossweb::conn app_name] \
                 -page_name [ossweb::conn page_name] \
                 -cmd_name [ossweb::conn cmd_name] \
                 -ctx_name [ossweb::conn ctx_name] \
                 -handlers Y \
                 -query Y] } {
        ossweb::conn -set session_id ""
        ossweb::conn::redirect_access_denied
        return filter_return
      }
      # Release database handle
      ossweb::db::release
      return filter_ok
    } rc

    switch -- $rc {
     filter_ok -
     filter_return {
       return $rc
     }
     OSSWEB_EXIT {
       return filter_return
     }
     default {
       ns_log Error ossweb::conn::filter::secure: $rc: $::errorInfo
       if { ![ossweb::conn::redirect_for_login] } {
         return filter_ok
       }
       return filter_return
     }
    }
}

# Public filter, doesn't do any authentication but supports sessions
proc ossweb::conn::filter::public { args } {

    catch {
      set user_id [ossweb::conn::parse_user]
      # Use public user id for all sessions
      if { $user_id == "" } {
        set user_id [ossweb::config session:user:public]
      }
      if { $user_id != "" } {
        ossweb::conn -set user_id $user_id
        if { [ossweb::conn::read_user $user_id] == "" } {
          ossweb::conn::redirect_access_denied
          return filter_return
        }
      } else {
        # If no public user, use special public group for access
        set obj_id [ossweb::db::select ossweb_groups group_name public -columns group_id -cache t -timeout 86400]
        if { $obj_id != "" } {
          ossweb::conn::read_acl $obj_id -obj_type G -reset f
        }
      }

      # Public cookies configured
      if { [set cookie [ossweb::config session:cookie:public]] != "" } {
        # Validate session cookies and re-issue them if something wrong
        if { [set session_id [ossweb::conn::signed_cookie $cookie]] == "" } {
          set domain [ossweb::config session:domain]
          set session_id [ossweb::conn -new_session_id]
          ossweb::conn::sign_cookie -domain $domain $cookie $session_id
        }
        ossweb::conn -set session_id $session_id
      }
      # Even in public mode we check access permissions
      if { [ossweb::conn::check_acl \
                 -project_name [ossweb::conn project_name] \
                 -app_name [ossweb::conn app_name] \
                 -page_name [ossweb::conn page_name] \
                 -cmd_name [ossweb::conn cmd_name] \
                 -ctx_name [ossweb::conn ctx_name] \
                 -handlers Y \
                 -query Y] } {
        ossweb::conn -set session_id ""
        ossweb::conn::redirect_access_denied
        return filter_return
      }
      # Release database handle
      ossweb::db::release
      return filter_ok
    } rc

    switch -- $rc {
     filter_ok -
     filter_return {
       return $rc
     }
     OSSWEB_EXIT {
       return filter_return
     }
     default {
       ns_log Error ossweb::conn::filter::public: $rc: $::errorInfo
       return filter_return
     }
    }
}

# Security system handler for special tasks
proc ossweb::conn::filter::system { args } {

    if { [ossweb::conn::parse_request] == "" } {
      ns_returnforbidden
      return
    }
    set result OK
    set cmd [ns_queryget cmd]
    set url [ns_queryget url]
    ns_log Notice ossweb::handler: [ossweb::conn user_id]: $cmd

    switch -- $cmd {
     reboot {
       set timeout [ns_queryget timeout 5]
       ossweb::admin::reboot $timeout
       set result "Scheduling OSSWEB reboot in $timeout seconds"
       if { [ns_queryget c] == 1 } {
         append result "<SCRIPT>setTimeout('window.close()',5000);</SCRIPT>"
       }
     }

     proxy {
       set type [ns_queryget type text/html]
       set rewrite [ns_queryget rewrite f]
       if { $url != "" && [string match http://* $url] } {
         catch { ns_httpget $url } result
       }
       # Rewrite all relative urls, very simple parser
       if { $rewrite == "t" } {
         set host [lindex [split $url /] 2]
         set root [file dirname [string range $url 7 end]]
         regsub -all -nocase {src="?([a-z\.][^:" ]+)"?} $result "src=\"http://$root/\\1\"" result
         regsub -all -nocase {href="?([a-z\.][^:" ]+)"?} $result "href=\"http://$root/\\1\"" result
         regsub -all -nocase {src="?/} $result "src=\"http://$host/" result
         regsub -all -nocase {href="?/} $result "href=\"http://$host/" result
       }
       ns_return 200 $type $result
       return
     }
    }

    # Redirect after the action
    if { $url != "" } {
      ns_returnredirect $url
      return
    }
    ns_return 200 text/html $result
}

# Maintenance filter, reponses with predefined page about work being held on the web server
proc ossweb::conn::filter::maintenance { args } {

    # Serves template if defined
    if { [set url [ossweb::config server:maintenance]] != "" } {
      ossweb::conn -reset
      ossweb::conn -set url "$url.[ossweb::config server:extension "oss"]"
      return [ossweb::adp::Filter $args]
    }
    # Static message
    ns_return 200 text/html "Sorry, the server is under maintenance"
    return filter_return
}
