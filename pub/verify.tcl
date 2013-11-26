# Author Vlad Seryakov vlad@crystalballinc.com
# August 2001

# Verifies user name and password

set user [ns_queryget user_name]
set password [ns_queryget password]
set user_id [ossweb::admin::login_user $user $password -verify t]
if { $user_id == -1 } {
  ns_return 404 "Not Found" "-1"
} else {
  ns_return 200 OK $user_id
}

