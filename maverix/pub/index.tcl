# Author: Vlad Seryakov vlad@crystalballinc.com 
# March 2003

set cmd [ns_queryget cmd]

switch -- $cmd {
  Digest {
    if { [set user_email [ns_queryget email]] == "" } {
      ossweb::conn::set_msg -color red "Please, provide your Email address"
      return
    }
    if { [ossweb::db::multivalue sql:maverix.user.search] } {
      ossweb::conn::set_msg -color red "Sorry, this email is unknown"
      return
    }
    if { [set messages [ossweb::db::list sql:maverix.user.message.list]] == "" } {
      ossweb::conn::set_msg "No new messages pending verification at this time"
      return
    }
    set digest_date [ossweb::date parse 1969-12-31]
    set digest_count 0
    ossweb::db::exec sql:maverix.user.update
    ossweb::conn::set_msg "Maverix Digest has been scheduled"
  }
}
