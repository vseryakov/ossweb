# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2006
#
# $Id: sso.tcl 1975 2006-10-19 18:58:31Z vlad $

#
# Single Sign-On client implementation
#

# SSO config
set sso_server [ossweb::config sso:server]
set sso_site [ossweb::config sso:site]
set sso_secret [ossweb::config sso:secret]
# For how long keep the session in the cache
set timeout [ossweb::config sso:timeout 3]

# Site should match with our configured site id
set site [ns_queryget site]
if { $site != $sso_site } {
  ns_returnbadrequest InvalidSite
  return
}

# Try to decrypt the query if it is encrypted and secret is configured
sso::secret $sso_secret

# Requsted action
set cmd [ns_queryget cmd]

# Security token given by SSO server
set token [ns_queryget token]

# How to map user sessions
set name [ns_queryget name]
set email [ns_queryget email]

# To verify IP address and User-Agent of the client
set ipaddr [ns_queryget ip]
set useragent [ns_queryget ua]

# Url where to redirect user after login
set url [ns_queryget url /]

# Browsers' IP address and User-agent header
set peeraddr [ns_conn peeraddr]
set peeragent [ossweb::conn::header User-Agent]

switch -- $cmd {
 login {
   # User requested login from another site, SSO server checked session
   # and sends us info about the user, if we can map it to one of our users by email
   # we reply back with the same token and save token in the cache, because user will
   # be redirected to us imeediately with this token

   set user_id [ossweb::db::value "SELECT user_id
                                   FROM ossweb_users
                                   WHERE user_email=[ossweb::sql::quote $email] AND
                                         first_name||' '||last_name=[ossweb::sql::quote $name]"]

   if { $user_id != "" } {
     nsv_set ns_sso_users $token "$user_id [ns_time] $ipaddr {$useragent}"
     ns_return 200 text/plain $token
   } else {
     ns_return 200 text/plain NotFound
   }
 }

 session {
   # Now we have request from the client with the securty token in the url, we must check
   # our cache for this token and verify that it is still valid. Also we check IP address and
   # browser's User-Agent for this token

   if { [nsv_exists ns_sso_users $token] } {
     set user [nsv_get ns_sso_users $token]
     nsv_unset ns_sso_users $token
     set now [ns_time]

     # Unfold cache into variables
     set cached_id [lindex $user 0]
     set cached_time [lindex $user 1]
     set cached_ipaddr [lindex $user 2]
     set cached_useragent [lindex $user 3]

     if { $now - $cached_time <= $timeout &&
          $peeraddr == $cached_ipaddr &&
          $peeragent == $cached_useragent &&
          [ossweb::admin::login "" "" -user_id $cached_id -redirect f -callbacks f] != -1 } {
       ns_log Notice SSO: User $cached_id logged in, redirecting to $url
       ns_returnredirect $url
       return
     }
   }
   ns_log Notice SSO: Invalid session: token=$token, ip=$peeraddr, ua=$peeragent, timeout=[expr $now - $cached_time] < $timeout
   # If we got here that means we could not verify token and session, just go to login page,
   # disable all hooks to avoid loops
   ossweb::conn::redirect_for_login -callbacks f -redirect f
 }

 default {
   ns_returnbadrequest UnknownCommand
 }
}
