# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001
#
# $Id: admin.tcl 2918 2007-01-30 19:31:34Z vlad $

# Initialization
ossweb::register_init ossweb::cluster::init

# Encrypts the password to be stored in the database, returns list with
# encrypted password and salt and salt2
proc ossweb::admin::password { user password } {

    set salt [ossweb::random]
    set salt2 [ns_sha1 "$password$user"]
    set password [ns_sha1 "$password$salt"]
    return [list $password $salt $salt2]
}

# Update or create user preferences
proc ossweb::admin::prefs { cmd args } {

    ns_parseargs { {-obj_id ""} {-obj_type U} args } $args

    switch -- $cmd {
     list {
        return [ossweb::db::multilist sql:ossweb.prefs.list -plain t]
     }

     get {
        set name [lindex $args 0]
        return [ossweb::db::value sql:ossweb.prefs.read]
     }

     set {
        foreach { name value } $args {
          if { $value == "" } {
            ossweb::db::exec sql:ossweb.prefs.delete
          } else {
            ossweb::db::exec sql:ossweb.prefs.update
            if { ![ossweb::db::rowcount] } {
              ossweb::db::exec sql:ossweb.prefs.create
            }
          }
        }
        # Refresh user cache to update new prefs
        ossweb::admin::flush_user $obj_id
     }
    }
}

# Create new user, args should be a list with pairs { column_name value },
# for ex:
#       ossweb::admin::create_user first_name Vlad last_name Seryakov password test
# Returns user_id of the new user
proc ossweb::admin::create_user { args } {

    ns_parseargs { {-groups ""} {-group_names ""} -- args } $args

    # Scan arguments and get column values
    foreach { name value } $args {
       if { $name == "" } { continue }
       set $name $value
    }
    ossweb::db::begin
    # Encrypt the password
    if { [info exists password] && [info exists user_name] } {
      set pw [ossweb::admin::password $user_name $password]
      set password [lindex $pw 0]
      set salt [lindex $pw 1]
      set salt2 [lindex $pw 2]
    }
    # Add new user and grant basic access permissions
    if { [ossweb::db::insert ossweb_users] } {
      ossweb::db::rollback
      return
    }
    set user_id [ossweb::db::currval ossweb_user]
    # Update user groups
    foreach group_id $groups {
      if { [ossweb::db::insert ossweb_user_groups] } {
        ossweb::db::rollback
        return
      }
    }
    foreach group_name $group_names {
      if { [ossweb::db::exec sql:ossweb.user.group.create.by.name] } {
        ossweb::db::rollback
        return
      }
    }
    ossweb::db::commit
    ns_log Notice "ossweb::admin::create_user: $user_id, $user_name, $first_name $last_name, groups $groups"
    return $user_id
}

# Updates current user table, args should be a list with pairs { column_name value }
# Reserved parameters:
#  -user_id parameter is optional, if specified the function updates
#  -transaction if true all updates will be performed within
#               transaction, otherwise as separate SQL statements
#  -flush if t flushes user cache
#  -groups list of group ids to include the user to
#  -group_names list of group names to include the user to
# user with given id instead of current logged on user.
#
# for example:
#       ossweb::admin::update_user user_email aaa@mail.com

proc ossweb::admin::update_user { args } {

    ns_parseargs { {-user_id {[ossweb::conn user_id]}}
                   {-flush t}
                   {-transaction t}
                   {-groups ""}
                   {-group_names ""}
                   {-columns2 ""}
                   {-prefs f} -- args } $args

    if { $user_id == "" || $args == "" } {
      return -1
    }

    # Create local variables
    set count 0
    foreach { name value } $args {
      if { $name == "" } { continue }
      set $name $value
      incr count
    }
    # Nothing to update
    if { !$count } {
      return -1
    }
    # Construct password hash
    if { [info exists password] && $password != "" } {
      if { ![info exists user_name] || $user_name == "" } {
        set user_name [ossweb::db::value sql:ossweb.user.read_username]
      }
      set pw [ossweb::admin::password $user_name $password]
      set password [lindex $pw 0]
      set salt [lindex $pw 1]
      set salt2 [lindex $pw 2]
      ns_log Notice ossweb::admin::update_user: $user_id: password change
    }
    if { $transaction == "t" } {
      ossweb::db::begin
    }
    # Update the record
    if { [ossweb::db::update ossweb_users user_id $user_id] } {
      ossweb::db::rollback
      return -1
    }
    # Update user groups
    if { $groups != "" || $group_names != "" } {
       if { [ossweb::db::delete ossweb_user_groups user_id $user_id] } {
         ossweb::db::rollback
         return -1
       }
       foreach group_id $groups {
         if { [ossweb::db::insert ossweb_user_groups] } {
           ossweb::db::rollback
           return -1
         }
       }
       foreach group_name $group_names {
         if { [ossweb::db::exec sql:ossweb.user.group.create.by.name] } {
           ossweb::db::rollback
           return ""
         }
       }
    }
    if { $transaction == "t" } {
      ossweb::db::commit
    }
    # We need to flush cached user info
    if { $flush == "t" } {
      ossweb::admin::flush_user $user_id
    }
    return 0
}

# Flushes local user cachce and permissions
proc ossweb::admin::flush_user { { user_id "" } } {

    if { $user_id == "" } {
      set user_id [ossweb::conn user_id]
    }
    ossweb::db::cache flush user:$user_id:*
    ossweb::cluster dbflush user:$user_id:*
}

# Removes user from database, clears all reference
# tables as well
proc ossweb::admin::delete_user { user_id } {

    ossweb::db::begin
    ossweb::db::delete ossweb_user_properties user_id $user_id
    ossweb::db::delete ossweb_user_sessions  user_id $user_id
    ossweb::db::delete ossweb_user_groups user_id $user_id
    ossweb::db::delete ossweb_acls obj_id $user_id obj_type U
    ossweb::db::delete ossweb_users user_id $user_id
    ossweb::db::commit
}

# Updates current user session
# Reserved parameters:
#  -user_id parameter is optional, if specified the function updates
#  -interval specifies interval between real updates from now to the last access time
proc ossweb::admin::update_session { args } {

    ns_parseargs { {-user_id {[ossweb::conn user_id]}}
                   {-session_id {[ossweb::conn session_id]}}
                   {-flush f}
                   {-interval ""} -- args } $args

    if { $user_id == "" || $args == "" } {
      return -1
    }
    # Do not perform update if within specified interval
    if { $interval > 0 } {
      if { [ns_time] - [ossweb::db::cache get user:$user_id:access 0] < $interval } {
        return 0
      }
      ossweb::db::cache set user:$user_id:access [ns_time]
    }
    # Create local variables
    foreach { name value } $args {
      if { $name == "" } { continue }
      set $name $value
      switch -exact $name {
        access_time {
          set access_time [ns_fmttime $value "%Y-%m-%d %H:%M:%S"]
        }
      }
    }
    # Update the record
    if { [ossweb::db::update ossweb_user_sessions user_id $user_id session_id $session_id] } {
      return -1
    }
    # We need to flush cached user info
    if { $flush == "t" } {
      ossweb::admin::flush_user $user_id
    }
    return 0
}

# Returns empty if the user does not belongs to any of
# specified groups or found group id
proc ossweb::admin::belong_group { args } {

    ns_parseargs { {-user_id {[ossweb::conn user_id]}} {-group_id ""} {-group_name ""} } $args

    return [ossweb::db::list sql:ossweb.user.group.belong]
}

# Logs the user in, variables $user_name and $user_password should exist
# in the given form. On error returns -1 otherwise returns 0.
# After successful login user will be redirecting to appropriate page
# otherwise error message will be displayed
# -verify t tells not to login but just verify user name and password and return
#           user_id on success
# -user_id id if given try to establish session by user id, this is for internal admins
proc ossweb::admin::login { user_name password args } {

    ns_parseargs { {-verify f} {-user_id ""} {-redirect t} {-callbacks t} args } $args

    # Read user and check password
    set user_id [ossweb::conn::read_user $user_id -user_name $user_name -check_password $password]
    if { $user_id == "" } {
      return -1
    }
    if { $verify == "t" } {
      return $user_id
    }
    ossweb::conn::set_user_id
    ossweb::conn::set_session_id -new t
    ossweb::conn::log Notice admin::login "[ossweb::conn first_name] [ossweb::conn last_name] from [ns_conn peeraddr]"
    # Check for multiple sessions, if not, keep only last one
    if { ![ossweb::true [ossweb::config session:multiple 1]] } {
      ossweb::db::delete ossweb_user_sessions user_id $user_id
    }

    # Create new session
    set session_id [ossweb::conn session_id]
    set ipaddr [ossweb::conn peeraddr]
    ossweb::db::insert ossweb_user_sessions

    # Update hash password for secure logins
    if { [ossweb::conn salt2] == "" } {
      ossweb::admin::update_user password $password
    }
    ossweb::admin::flush_user $user_id
    # Figure out redirect url
    ossweb::conn -set redirect_url \
         [ossweb::nvl [ossweb::conn start_page] \
               [ossweb::nvl [ns_queryget url] \
                     [ossweb::conn::hostname]/[ossweb::conn project_name]/main/]]

    # Run registered callbacks on user login
    if { $callbacks == "t" } {
      foreach name [lsort [eval "namespace eval ::ossweb::control::login { info procs }"]] {
        if { [catch { set rc [::ossweb::control::login::$name] } errmsg] } {
          ns_log Error ossweb::admin::login: $name: $errmsg
          set rc ""
        }
        switch -- $rc {
         filter_return - filter_ok {
           break
         }
        }
      }
    }

    # Redirect to start page
    set url [ossweb::conn redirect_url]
    # Make sure we do not point back to login page after login
    if { [string match "*/pub/login.*" $url] } {
      regsub {/pub/login\.[^?&=]+} $url {/main/} url
      ossweb::conn -set redirect_url $url
    }

    if { $redirect == "t" && $url != "" } {
      ossweb::conn::redirect $url -log t
    }
    return 0
}

# Closes current user session and redirecting to public home page
proc ossweb::admin::logout { args } {

    ns_parseargs { {-callbacks t}
                   {-redirect t}
                   {-session_id {[ossweb::conn session_id]}}
                   {-user_id {[ossweb::conn user_id -1]}} } $args

    # Url where to redirect after logout
    ossweb::conn -set redirect_url [ossweb::html::url -app_name pub login]

    # Run registered callbacks on user logout
    if { $callbacks == "t" } {
      foreach name [lsort [eval "namespace eval ::ossweb::control::logout { info procs }"]] {
        if { [catch { set rc [::ossweb::control::logout::$name] } errmsg] } {
          ns_log Error ossweb::admin::logout: $name: $errmsg
          set rc ""
        }
        switch -- $rc {
         filter_return - filter_ok {
           break
         }
        }
      }
    }
    # Disable the session first
    set logout_time [ns_fmttime [ns_time] "%Y-%m-%d %H:%M:%S"]
    ossweb::db::update ossweb_user_sessions user_id $user_id session_id $session_id

    # Clear local cache
    ossweb::admin::flush_user $user_id
    # Clear cookies
    ossweb::conn::set_user_id -clear t
    ossweb::conn::set_session_id -clear t
    # Redirect to special page if specified
    if { $redirect == "t" } {
      ossweb::conn::redirect [ossweb::conn redirect_url]
    }
    return 0
}

# Reboot AOLServer in specified amount of time in seconds
proc ossweb::admin::reboot { { interval 30 } } {

    ns_schedule_proc -once $interval "ns_shutdown $interval"
}

# Read pending popup
proc ossweb::admin::read_popup { { user_id "" } } {

    if { $user_id == "" } {
      set user_id [ossweb::conn user_id]
    }
    if { [set msg [ossweb::conn::get_property ossweb:popup0msg -user_id $user_id -global t]] != "" } {
      ns_log Notice ossweb::admin::read_popup: message to $user_id
    }
    ossweb::conn::set_property ossweb:popup0msg "" -user_id $user_id -global t
    return [string trim $msg]
}

# Sets alert message to be poped up for active user(s)
proc ossweb::admin::send_popup { args } {

    ns_parseargs { {-user_id ""} {msg ""} } $args

    # All currently logged in users
    if { $user_id == "" } {
      foreach user [ossweb::db::cache names user:*:] {
        lappend user_id [string trim [string range $user 4 end] " :"]
      }
    }
    append msg "\n"
    foreach id $user_id {
      ossweb::conn::set_property ossweb:popup0msg $msg -user_id $user_id -global t -append t
    }
    # Send empty cluster command to refresh cache on all server, it will add just
    # \n to the popup message and read_popup will trim it and will not show anything
    # if message has been displayed already
    ossweb::cluster ossweb::admin::send_popup $user_id
}

# User preferences
proc ossweb::control::prefs { type args } {

    set result ""
    foreach name [lsort [eval "namespace eval ::ossweb::control::prefs { info procs }"]] {
      if { [string index $name 0] == "_" } { continue }
      switch -- $type {
       columns {
          eval lappend result [ossweb::control::prefs::$name columns]
       }

       names {
          foreach { name t d } [ossweb::control::prefs::$name columns] {
            lappend result $name
          }
       }

       modules {
          lappend result $name
       }

       form {
          ossweb::control::prefs::$name $type
       }

       save {
          ossweb::control::prefs::$name $type
          # Re-read conn preferences
          ossweb::conn::read_user [ossweb::conn user_id]
       }
      }
    }
    return $result
}

# API for extending administration of users
proc ossweb::control::user { type user_id args } {

    set tab [ns_queryget tab]
    foreach name [lsort [eval "namespace eval ::ossweb::control::user { info procs }"]] {
      switch -- $type {
       save -
       form {
         if { $tab != $name } { continue }
       }
      }
      uplevel "ossweb::control::user::$name $type $user_id $args"
    }
}

# Extend user admin screen
proc ossweb::control::user::group { type user_id args } {

    switch -- $type {
     tab {
       ossweb::widget form_tab.group -type link -label Groups -value $args
     }

     form {
       set options ""
       ossweb::db::foreach sql:ossweb.group.read_all {
         lappend options [list "$group_name - $description" $group_id]
       }
       ossweb::form form_prefs -title "User Groups"
       ossweb::widget form_prefs.group_id -type checkbox -label Groups \
            -optional \
            -freeze \
            -values [ossweb::db::list sql:ossweb.user.group.list -colname group_id] \
            -options $options
     }

     save {
       if { [ossweb::db::delete ossweb_user_groups user_id $user_id] } {
         error "OSS: Unable to clear user groups"
       }
       foreach group_id [ns_querygetall group_id] {
         if { [ossweb::db::insert ossweb_user_groups] } {
           error "OSS: Unable to user group"
         }
       }
     }
    }
}

# PAM authentication
proc ossweb::control::auth::pam { user passwd args } {

    ns_parseargs { {-array ""} } $args

    if { [info command ns_authpam] == "" } {
      return 0
    }
    set service [ossweb::config security:pam:service ossweb]
    return [ns_authpam auth $service $user $passwd]
}

# Local password authentication
proc ossweb::control::auth::local { user passwd args } {

    ns_parseargs { {-array ""} } $args

    if { $array == "" } {
      return 0
    }

    upvar 1 $array userArray

    if { [ns_sha1 $passwd[ossweb::coalesce userArray(salt)]] == [ossweb::coalesce userArray(password)] ||
         [ns_sha1 [ossweb::coalesce userArray(salt2)][ossweb::conn peeraddr]] == $passwd } {
      return 1
    }
    return 0
}

# Cluster initialization
proc ossweb::cluster::init {} {

    ns_register_proc GET /SYSTEM/CLUSTER ::ossweb::cluster::filter
    ns_log Notice ossweb::cluster: initialized

    # Job queue for cluster updates
    ns_job create __ossweb_cluster [ossweb::config server:thread:cluster 1]
}

# Request processor
proc ossweb::cluster::filter { args } {

    set debug [ossweb::config server:cluster:debug]
    set peeraddr [ns_conn peeraddr]
    set status 401
    set body ""
    foreach ipaddr "127.0.0.1 [ossweb::config server:cluster]" {
      foreach ipaddr [split $ipaddr /] {
        if { [lindex [split $ipaddr :] 0] == $peeraddr } {
          set ipaddr 0.0.0.0
          break
        }
      }
      if { $ipaddr == "0.0.0.0" } {
        if { [set hash [ns_queryget hash]] != "" && [set cmd [ns_queryget cmd]] != "" } {
          set name [ns_queryget name]
          set value [ns_queryget value]
          # Verify digital signature
          if { [ossweb::conn::secret "$cmd$name$value"] != $hash } {
            ns_log Error ossweb::cluster::filter: $peeraddr: $cmd: $name: invalid hash $hash
            break
          }
          if { $debug != "" } {
            ns_log $debug ossweb::cluster::filter $peeraddr: $cmd: $name: $value
          }
          switch -- $cmd {
           flush {
             if { $name != "" } {
               ossweb::cache flush $name
             }
             set status 200
           }

           dbflush {
             if { $name != "" } {
               ossweb::db::cache flush $name
             }
             set status 200
           }

           set {
             if { $name != "" } {
               ossweb::cache set $name $value
             }
             set status 200
           }

           get {
             if { $name != "" } {
               set body [ossweb::cache get $name]
             }
             set status 200
           }

           default {
             if { [namespace eval :: "info procs $cmd"] != "" || [info command $cmd] != "" } {
               if { [string first " " $name] > -1 } {
                 set name [list $name]
               }
               if { [catch { set body [eval namespace eval :: "$cmd $name $value"] } errmsg] } {
                 ns_log Error ossweb::cluster::filter: $peeraddr: $cmd $name $value: $errmsg: $::errorInfo
               }
               set status 200
             } else {
               set status 501
             }
           }
          }
        }
        break
      }
    }
    ns_return $status text/plain $body
    if { ($status != 200 && [set debug Error] != "") || $debug != "" } {
      ns_log $debug ossweb::cluster::filter $peeraddr: $status: [ns_queryget cmd]: [ns_queryget name]: [ns_queryget value]
    }
}

# Performs actual http request to one server from the cluster,
# returns HTTP response status
proc ossweb::cluster::send { host cmd name args } {

    ns_parseargs { {-debug f} {-cache ""} {-noreply f} {-timeout ""} {-value ""} {-callback ""} } $args

    if { $timeout == "" } {
      set timeout [ossweb::config server:cluster:timeout 3]
    }
    # Sign request with shared secret
    set hash [ossweb::conn::secret "$cmd$name$value"]

    if { [catch {
      # Use HTTP over UDP if available
      if { [ossweb::config server:cluster:protocol tcp] == "udp" && [info command ns_udp] != "" } {
        if { ![regexp {([^:]+):?([0-9]+)?} $host d ipaddr port] || ![string is integer $port] } {
          error "invalid host $host"
        }
        set noreply [ossweb::decode $noreply t 1 0]
        set url [ossweb::html::url -url /SYSTEM/CLUSTER hash $hash cmd $cmd name $name value $value]
        set reply [ns_udp -noreply $noreply -timeout $timeout $ipaddr $port "GET /$url HTTP/1.0\n\n"]
      } else {
        set url [ossweb::html::url -url http://$host/SYSTEM/CLUSTER hash $hash cmd $cmd name $name value $value]
        set reply [ns_httpget $url $timeout]
      }
    } errmsg] } {
      ns_log Error ossweb::cluster::send: $url: $errmsg: $::errorInfo
      set reply ""
    }
    if { $debug } {
      ns_log Notice ossweb::cluster::send: $url: $reply
    }
    # If cache is given, set cache entry with returned value
    if { $cache != "" } {
      ossweb::cache set $cache $reply
    }
    # If callbackis given, return value will be passed to it and callback reply will be
    # returned instead. If callback fails with error, error message will be returned.
    if { $callback != "" } {
      catch { $callback $reply $host $cmd $name $value } reply
    }
    return $reply
}

# Perform operation in multi-server cluster.
# Cluster config should contain list of IP addresses involved in the cluster.
# IP addresses from the same server should be concatenated using /
# Ex: 192.168.1.1 192.168.1.2/192.168.1.3
proc ossweb::cluster { cmd name args } {

    ns_parseargs { {-host ""} {-debug f} {-value ""} {-cache ""} {-noreply f} {-self f} {-timeout ""} {-callback ""} } $args

    # Send to one server
    if { $host != "" } {
      if { $cache != "" } {
        set cache "$cache:$host"
      }
      return [ossweb::cluster::send $host $cmd $name -value $value -debug $debug -cache $cache -noreply $noreply -timeout $timeout -callback $callback]
    }

    # Send to all servers in the cluster
    set host [ns_addrbyhost [ns_info hostname]]
    set port [ns_config "ns/server/[ns_info server]/module/nssock" port 80]
    foreach ipaddr [ossweb::config server:cluster] {
      set ipaddr [split $ipaddr /]
      if { $self == "f" } {
        set skip_flag f
        foreach addr $ipaddr {
          foreach { host2 port2 } [split $addr :] {}
          if { $host2 == $host && ($port2 == "" || $port2 == $port) } {
            set skip_flag t
            break
          }
        }
        if { $skip_flag == "t" } { continue }
      }
      set _cache ""
      set ipaddr [lindex $ipaddr 0]
      if { $cache != "" } {
        set _cache "$cache:$ipaddr"
      }
      ns_job queue -detached __ossweb_cluster "::ossweb::cluster::send $ipaddr $cmd $name -value {$value} -debug {$debug} -cache {$_cache} -noreply {$noreply} -timeout {$timeout} -callback {$callback}"
    }
}

# Returns IP address of the master server in the cluster,
# returns empty for the master itself. This call can be usefull if some kind of config needs to be
# retrieved from the master site and master does not need to perform this because it hosts it
proc ossweb::cluster::master {} {

    set master [ossweb::config server:cluster:master]
    set ipaddr [ns_addrbyhost [ns_info hostname]]
    if { $master != "" && [lsearch -exact $master $ipaddr] == -1 } {
      return [lindex $master 0]
    }
    return
}

proc ossweb::resource::lock { rcs_type rcs_name args } {

    ns_parseargs { {-rcs_start ""} {-rcs_end ""} {-rcs_data ""} {-rcs_user ""} } $args

    if { [ossweb::db::exec sql:ossweb.resource.lock] } { return -1 }
    return [ossweb::db::currval ossweb_resource]
}

proc ossweb::resource::trylock { rcs_type rcs_name args } {

    ns_parseargs { {-rcs_start ""} {-rcs_end ""} {-rcs_data ""} {-rcs_user ""} } $args

    return [ossweb::db::value sql:ossweb.resource.trylock]
}

proc ossweb::resource::unlock { rcs_type rcs_name args } {

    ns_parseargs { {-rcs_start ""} {-rcs_end ""} {-rcs_id ""} {-rcs_user ""} } $args

    if { [ossweb::db::exec sql:ossweb.resource.unlock] } { return -1 }
    return 0
}

# Returns 1 if specified resource cannot be reserved
proc ossweb::resource::check { rcs_type rcs_name args } {

    ns_parseargs { {-rcs_start ""} {-rcs_end ""} {-rcs_id ""} {-rcs_user ""} } $args

    return [ossweb::db::value sql:ossweb.resource.check]
}

