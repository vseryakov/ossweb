# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

# Clear user session cookies and redirect to home index page
ossweb::admin::logout -redirect f

# Where to redirect after logout
set url [ossweb::conn redirect_url]

# Perform SSO logout
set site [ossweb::config sso:site]
set server [ossweb::config sso:server]
set timeout [ossweb::config sso:timeout 3]
set secret [ossweb::config sso:secret]

if { $server != "" || $site != "" && ![string match http://[ns_info hostname]/* $server] } {
  # Do ping before redirect to make sure the SSO server is alive
  catch { ns_httpget [sso::url::ping -server $server -site $site] $timeout } rc
  if { $rc == "OK" } {
    ossweb::conn::redirect [sso::url::logout -server $server -site $site -secret $secret -url $url]
  }
}
# If we got here, SSO did not work, so just redirect to login page then
ossweb::conn::redirect $url

