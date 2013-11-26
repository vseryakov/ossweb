# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2006
#
# $Id: sso_procs.tcl 1975 2006-10-19 18:58:31Z vlad $


#
# sso.tcl --
#
#   Set of procedures implementing Single Sign-On
#
#   To use it, just drop it into tcl/ or modules/tcl directory under
#   naviserver install home which is usually /usr/local/ns and
#   add the following entries into config file (it shows default values).
#
#  ns_section      ns/server/sso
#  ns_param        enabled                 1
#  ns_param        url                     /_sso
#
#  ns_section      ns/server/sso/1234
#  ns_param        ssourl                     http://host1/_sso/sso.php
#  ns_param        loginurl                   http://host1/login.php
#  ns_param	   secret		      key1
#
#  ns_section      ns/server/sso/45778
#  ns_param        ssourl                     http://host2/_sso/sso.tcl
#  ns_param        loginurl                   http://host2/login.tcl
#  ns_param	   secret		      key2
#
#     where
#        each site should be defined with it own section by site ID,
#        id can be anything, it is just to be unique and each site should use it in the
#        requests to SSO server.
#        - ssourl is where remote SSO login script is located,
#        - loginurl is where to redirect in case of error or invalid session
#        - key is secret key to be used for encrypting urls between SSO server and web site
#
#  How it works
#
#   1. After user has logged into website, website SSO client tells SSO server about just created new session,
#      it calls login function and receives security token back
#
#     http://host/_sso?cmd=login&site=site&id=id&name=name&email=email&ip=ip&ua=ua&expires=expires
#
#     where
#        site        - id of the site, each site has unique id
#        id          - new established session
#        name        - user name
#        email       - user email address
#        ip          - browser's IP address
#        ua          - browser's  User-Agent
#        expires     - absolute time in the future when session expires, 0 if never
#
#   2. Once token is received from SSO server, we redirect browser to SSO server and provide token in the query.
#      SSO server verifies the token and setup session cookies, then redirects the user back to site using supplied
#      actual url
#
#     http://host/_sso?cmd=setup&site=site&token=token&url=url
#
#     where
#        site        - id of the site, each site has unique id
#        token       - token returned by SSO server after setup call
#        url         - the actual url user was trying to access
#
#
#  3. When new user comes to the site and does not have valid session, we redirect him to SSO server with
#     command session
#
#     http://host/_sso?cmd=session&site=site&url=url
#
#     where
#        site        - id of the site, each site has unique id
#        url         - the actual url user was trying to access
#
#  4. SSO server finds the existing session by checking sso cookies and if found
#     makes a request back to site with user info and security token. If site can
#     map given user with its database, it returns the same token back. In this case
#     SSO server redirects the client back to site with same security token in the url.
#     The site should then verify that token and establics its own Web session.
#
#     http://site/sso/sso.tcl?cmd=login&token=token&name=name&email=email&ip=ip&ua=ua
#
#     where
#        token       - token to be used for session mapping
#        name        - user name
#        email       - user email address
#        ip          - browser's IP address
#        ua          - browser's  User-Agent
#
#  5. Redirect the client back to site with security token and let the site to finish session
#     mapping by given token
#
#     http://site/sso/sso.tcl?cmd=session&token=token&url=url
#
#     where
#        token       - token that as used in previos request
#        url         - the actual url user was trying to access
#
#
#   Author Vlad Seryakov vlad@crystalballinc.com
#

namespace eval sso {
  namespace eval url {}
  namespace eval handler {}
  namespace eval session {}
}

ossweb::register_init sso::init

proc sso::init {} {

    if { [ns_config -bool ns/server/sso enabled 0] }  {
      set url [ns_config ns/server/sso url "/_sso"]
      ns_register_proc GET $url/* sso::handler
      ns_log notice SSO enabled for '$url'
    }
}

# Main dispatcher for SSO requests
proc sso::handler {} {

    ns_set update [ns_conn outputheaders] Expires now

    # Accept requests from registered sites only
    if { ![sso::handler::access] } {
      ns_returnbadrequest AccessDenied
      return
    }

    switch -- [ns_queryget cmd] {
     ping {
        ns_return 200 text/plain OK
     }

     session {
        sso::handler::session
     }

     setup {
        sso::handler::setup
     }

     login {
        sso::handler::login
     }

     logout {
        sso::handler::logout
     }

     default {
       ns_returnbadrequest UnknownCommand
     }
    }
}

# Call that is made by server, not browser, setups new session
proc sso::handler::login {} {

    set id [ns_queryget id]
    set name [ns_queryget name]
    set email [ns_queryget email]
    set ipaddr [ns_queryget ip]
    set useragent [ns_queryget ua]
    set expires [ns_queryget expires]
    if { ![string is integer -strict $expires] || $expires <= 0 } { set expires 0 }
    set timeout [ns_queryget timeout]
    if { ![string is integer -strict $timeout] || $timeout <= 0 } { set timeout 3 }

    # Generate securty token
    set session ""
    set time [ns_time]
    set seed [sso::rand]
    set token [ns_sha1 $time$seed$id$ipaddr$useragent]
    # Save session in the cache
    sso::session::update $token session id $id name $name email $email ip $ipaddr ua $useragent expires $expires hit $time time $time timeout $timeout seed $seed
    # Return new session token that should be used by browser
    ns_return 200 text/plain $token
    ns_log Notice sso::handler::login: token=$token, email=$email, ip=$ipaddr, ua=$useragent, expires=$expires
}

# Browser login request just after user logged in into the site
proc sso::handler::setup {} {

    set now [ns_time]
    set site [ns_queryget site]
    set token [ns_queryget token]
    set url [ns_queryget url]
    # Site config
    set section [sso::section $site]
    set loginurl [ns_set get $section loginurl]
    # Extract and verify provided token
    if { $token == "" || [set session [sso::session::check $token]] == "" } {
      sso::session::clear $token $loginurl
      return
    }
    # Login request should come within seconds after the session setup
    set session_time [sso::lget $session time]
    set session_timeout [sso::lget $session timeout]
    if { $now - $session_time > $session_timeout } {
      ns_log Notice sso::handler::session: Login Expired: token=$token, time=$session_time, timeout=$session_timeout
      sso::session::clear $token $loginurl
      return
    }
    # Update session
    sso::session::update $token session hit $now
    # Assign our cookies
    set expires [sso::lget $session expires]
    if { [set maxage [expr $expires-$now]] < 0 } { set maxage 0 }
    ns_setcookie -maxage $maxage sso $token
    # Redirect to the real site with optional original url, if no url given, go to
    # directory where login page is located
    if { $url == "" } {
      set url [file dirname [ns_set get $section loginurl]]
    }
    ns_returnredirect $url
    ns_log Notice sso::handler::setup: token=$token, email=[sso::lget $session email], ip=[ns_conn peeraddr], expires=$expires
}

# Browser setup request if session is not established with the site
proc sso::handler::session {} {

    set now [ns_time]
    set site [ns_queryget site]
    set token [ns_getcookie sso ""]
    # Site config
    set section [sso::section $site]
    set secret [ns_set get $section secret]
    set ssourl [ns_set get $section ssourl]
    set loginurl [ns_set get $section loginurl]
    # Extract and verify provided token
    if { $token == "" || [set session [sso::session::check $token]] == "" } {
      sso::session::clear $token $loginurl
      return
    }
    # Try to call the site and see if it can map the given user
    set errmsg ""
    set token2 [ns_sha1 $now[sso::rand][ns_conn peeraddr]$token]
    set url2 [sso::url -cmd login -server $ssourl -site $site -token $token2 -secret $secret -name [sso::lget $session name] -email [sso::lget $session email]]
    if { [catch { set data [ns_httpget $url2] } errmsg] || $data != $token2 } {
      ns_log Error sso::handler::session: $token2: $errmsg
      return
    }
    # Update session
    sso::session::update $token session hit $now
    # Assign our cookies
    set expires [sso::lget $session expires]
    if { [set maxage [expr $expires-$now]] < 0 } { set maxage 0 }
    ns_setcookie -maxage $maxage sso $token
    # Redirect to the real site with optional original url
    set url2 [sso::url -cmd session -server $ssourl -site $site -token $token2 -secret $secret -url [ns_queryget url]]
    ns_returnredirect $url2
    ns_log Notice sso::handler::session: token=$token, email=[sso::lget $session email], ip=[ns_conn peeraddr], expires=$expires
}

# Logout user from any sessions
proc sso::handler::logout {} {

    set site [ns_queryget site]
    set token [ns_getcookie sso ""]
    # Site config
    set section [sso::section $site]
    set loginurl [ns_set get $section loginurl]
    # Clear the session and redirect back to login page
    sso::session::clear $token $loginurl
}

# Returns 0 if access is denied
proc sso::handler::access {} {

    if { [set section [sso::section [ns_queryget site]]] == "" } {
      return 0
    }
    # IP address restrictions
    set ipaddr [ns_set get $section ipaddr]
    if { $ipaddr != "" && ![ossweb::lexists $ipaddr [ns_conn peeraddr]] } {
      return 0
    }
    # Decrypt data if encrypted
    sso::secret [ns_set get $section secret]
    return 1
}

# Builds login request url to SSO server
proc sso::url { args } {

    ns_parseargs { {-server http://localhost/_sso}
                   {-cmd ping}
                   {-token ""}
                   {-site ""}
                   {-url ""}
                   {-id ""}
                   {-name ""}
                   {-email ""}
                   {-ip {=$ossweb::conn peeraddr}}
                   {-ua {=$ossweb::conn::header User-Agent}}
                   {-expires ""}
                   {-secret ""}
                   {-timeout 3} } $args

    set data "cmd=$cmd"
    if { $token != "" } {
      append data &token=[ns_urlencode $token]
    }
    if { $id != "" } {
      append data &id=[ns_urlencode $id]
    }
    if { $name != "" } {
      append data &name=[ns_urlencode $name]
    }
    if { $email != "" } {
      append data &email=[ns_urlencode $email]
    }
    if { $ip != "" } {
      append data &ip=[ns_urlencode $ip]
    }
    if { $ua != "" } {
      append data &ua=[ns_urlencode $ua]
    }
    if { $expires != "" } {
      append data &expires=[ns_urlencode $expires]
    }
    if { $timeout != "" } {
      append data &timeout=[ns_urlencode $timeout]
    }
    if { $url != "" } {
      append data &url=[ns_urlencode $url]
    }
    # Encrypt the whole url, only site has to be visible
    if { $secret != "" } {
      set data data=[ossweb::hexify [ossweb::encrypt $data -secret $secret]]
    }
    if { $site != "" } {
      append data &site=[ns_urlencode $site]
    }
    return $server?$data
}

# Builds setup request url to SSO server
proc sso::url::login { args } {

    return [eval sso::url $args -cmd login]
}

# Builds setup request url to SSO server
proc sso::url::setup { args } {

    return [eval sso::url $args -cmd setup]
}

# Builds session request url to SSO server
proc sso::url::session { args } {

    return [eval sso::url $args -cmd session]
}

# Logs out from the SSO server
proc sso::url::logout { args } {

    return [eval sso::url $args -cmd logout]
}

# Pings the server
proc sso::url::ping { args } {

    ns_parseargs { {-server ""} {-site ""} } $args

    return [sso::url -server $server -site $site -cmd ping -ua "" -ip "" -timeout ""]
}

# Clear session fromthe cache and redirects to login page
proc sso::session::clear { token { loginurl "" } } {

    if { $token != "" } {
      catch { nsv_unset ns_sso_sessions $token }
    }
    if { $loginurl != "" } {
      ns_deletecookie sso
      ns_returnredirect $loginurl
    }
}

# Verify that given session is valid and
# the browser is what we expect and
# we got request within predefined period of time
proc sso::session::check { token } {

    if { $token == "" ||
         ![nsv_exists ns_sso_sessions $token] ||
         [catch { set session [nsv_get ns_sso_sessions $token] }] ||
         $session == "" } {
      ns_log Notice sso::session::check: Invalid Session: token=$token
      return
    }
    set ipaddr [ossweb::conn peeraddr]
    set useragent [ossweb::conn::header User-Agent]
    if { [sso::lget $session ip] != $ipaddr ||
         [sso::lget $session ua] != $useragent } {
      ns_log Notice sso::session::check: Invalid IP/UA: token=$token, ip=$ipaddr, ua=$useragent
      return
    }
    set now [ns_time]
    set expires [sso::lget $session expires]
    if { $expires > 0 && $expires < $now } {
      ns_log Notice sso::session::check: Session Expired: token=$token, ip=$ipaddr, ua=$useragent, expires=$expires
      return
    }
    return $session
}

# Update session fields and save new session in the cache
proc sso::session::update { token session args } {

    upvar $session _session
    foreach { name value } $args {
      sso::lset _session $name $value
    }
    nsv_set ns_sso_sessions $token $_session
}

# Generates random session
proc sso::rand {} {

    return [ns_rand 2000000000]
}

# Handles encrypted data in the url
proc sso::secret { secret } {

    if { $secret != "" && [set data [ns_queryget data]] != "" } {
      set form [ns_getform]
      set query [ns_parsequery [ossweb::decrypt [ossweb::dehexify $data] -secret $secret]]
      for { set i 0 } { $i < [ns_set size $query] } { incr i } {
        ns_set update $form [ns_set key $query $i] [ns_set value $query $i]
      }
      ns_set free $query
    }
}

# Returns ns_set with section paramaters
proc sso::section { site } {

    set var ::sso_site_$site
    if { ![info exists $var] } {
      set $var [ns_configsection ns/server/sso/$site]
    }
    return [set $var]
}

# Returns value by name from the list
proc sso::lget { list name { dflt "" } } {

    set idx [lsearch -exact $list $name]
    if { $idx > -1 } {
      return [lindex $list [incr idx]]
    }
    return $dflt
}

# Replaces value by name from the list
proc sso::lset { list name value } {

    upvar $list _list
    set idx [lsearch -exact $_list $name]
    if { $idx > -1 } {
      lset _list [incr idx] $value
    } else {
      lappend _list $name $value
    }
}

