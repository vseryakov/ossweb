# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

# Call after succssesfull login to establish global session
ossweb::conn::callback sso_login {} {

    set site [ossweb::config sso:site]
    set server [ossweb::config sso:server]
    set timeout [ossweb::config sso:timeout 3]
    set secret [ossweb::config sso:secret]

    if { $server != "" && $site != "" && ![string match http://[ns_info hostname]/* $server] } {
      set id [ossweb::conn session_id]
      set name [ossweb::conn full_name]
      set email [ossweb::conn user_email]
      set url [ossweb::conn redirect_url]
      set token ""

      # Login into SSO server and receive a session token
      set loginurl [sso::url::login -server $server -site $site -id $id -name $name -email $email -secret $secret]

      if { [catch { set token [ns_httpget $loginurl $timeout] } errmsg] } {
        ns_log Error sso_login: $errmsg
      }
      # Now redirect the browser to SSO server with established session and actual site url where
      # SSO will redirect us back
      if { $token != "" } {
        # Do ping before redirect to make sure server is up
        catch { ns_httpget [sso::url::ping -server $server -site $site] $timeout } rc

        if { $rc == "OK" } {
          ossweb::conn -set redirect_url [sso::url::setup -server $server -site $site -token $token -url $url -secret $secret]
        }
      }
    }
}

# Call on this page entry to see if we can find global session, use sso=1 to avoid redirect loops
# when SSO server will redirect us to login page back
ossweb::conn::callback sso_session {} {

    set site [ossweb::config sso:site]
    set server [ossweb::config sso:server]
    set timeout [ossweb::config sso:timeout 3]
    set secret [ossweb::config sso:secret]

    # Save original url and pass it to SSO server, we will be redirected to it after successfull login
    # Ask SSO server about the session and redirect back
    if { $server != "" && $site != "" && $sso == "" && ![string match http://[ns_info hostname]/* $server] } {
      # Do ping before redirect to make sure server is up
      catch { ns_httpget [sso::url::ping -server $server -site $site] $timeout } rc

      if { $rc == "OK" } {
        ossweb::conn::redirect [sso::url::session -server $server -site $site -url $url -secret $secret]
      }
    }
}

ossweb::conn::callback login_action {} {

    if { $token == "" || [ossweb::cache get LOGIN:$token] == "" } {
      error "OSS:Login session expired, try again"
    }
    if { [ossweb::admin::login $user_name $password -redirect f] == -1 } {
      error "OSS:Invalid User name or password"
    }
    # Check SSO support
    sso_login
    # Redirect to the required page
    ossweb::conn::redirect [ossweb::conn redirect_url] -log t
}

ossweb::conn::callback login_init {} {

    # Check for SSO session first
    sso_session
    # No support, runthrough local authentication then
    set token [ns_sha1 [ns_conn peeraddr][ns_time][ns_rand 99898989]]
    ossweb::cache set LOGIN:$token 1 180
    ossweb::form form_login set_values
}

ossweb::conn::callback create_form_login {} {

    ossweb::form form_login -title "[ossweb::project name] login" \
         -action [ossweb::html::url login] \
         -html { onSubmit doLogin(this) }

    ossweb::widget form_login.url -type hidden -optional

    ossweb::widget form_login.sso -type hidden -optional

    ossweb::widget form_login.token -type hidden -optional

    ossweb::widget form_login.cmd -type hidden -value login -freeze

    ossweb::widget form_login.user_name -type text -label "User&nbsp;Name" \
         -size 20 \
         -class inputText

    ossweb::widget form_login.password -type password -label Password \
         -size 20 \
         -html { onFocus "this.value=''"
                 onKeyUp="if(event.keyCode==13)doLogin();" } \
         -class inputText

    # Enryption checkbox can be completely disabled
    if { [ossweb::config security:encrypt:password] != "f" } {
      ossweb::widget form_login.encrypted -type checkbox -label "&nbsp;" \
         -separator /img/misc/bluepixel.gif \
         -class:label osswebSmallText \
         -class:cell osswebSmallText \
         -optional \
         -values [ossweb::config security:encrypt:password t] \
         -options { { "Encrypt Password" t } }
    } else {
         ossweb::widget form_login.encrypted -type hidden -value f
    }

    ossweb::widget form_login.login -type button -label Login \
         -url "javascript:doLogin(this)"

    ossweb::html::include /js/sha1.js
}

# Dump headers to the log
if { [ns_queryget headers] != "" } { ns_set print [ns_conn headers] }

ossweb::conn::process -columns { user_name "" ""
                                 password "" ""
                                 url "" ""
                                 sso "" ""
                                 token const "" } \
           -forms form_login \
           -on_error index \
           -eval {
             login {
               -exec { login_action }
               -on_error { -cmd_name view }
             }

             default {
               -exec { login_init }
             }
           }

