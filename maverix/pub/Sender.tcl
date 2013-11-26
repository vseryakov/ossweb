# Author: Vlad Seryakov vlad@crystalballinc.com 
# March 2003

set cmd [ns_queryget c]
set user_email [ns_queryget u]
set sender_email [ns_queryget s]
set sender_digest [ns_queryget d]
set messages:rowcount 0

# Locate sender record for given user
if { $user_email == "" || 
     $sender_email == "" ||
     [ossweb::db::multivalue sql:maverix.sender.read] ||
     $sender_digest != $digest_id } {
  ossweb::conn::set_msg -color red \
       "Sorry, that verification request in invalid, 
        Please check for a more recent verification URL"
  ns_log Debug Sender: $cmd, u=$user_email, s=$sender_email, d=$sender_digest, error
  set cmd error
  return
}
# Check for stale digest
if { [ns_time] - $digest_time > [ossweb::config maverix:stale 86400] } {
  ossweb::conn::set_msg -color red \
       "Sorry, this verification URL has expired,
        Please check for a more recent verification URL"
  ns_log Debug Sender: $cmd, u=$user_email, s=$sender_email, d=$digest_id, stale
  set cmd error
  return
}
# Verify status
if { $sender_type == "PASS" } {
  ossweb::conn::set_msg -color red "You have already been verified for $user_email"
  set cmd ""
}
ns_log Debug Sender: $cmd, u=$user_email, s=$sender_email, d=$digest_id, ok
switch -- $cmd {
 v {
   set sender_type PASS
   set sender_method Self
   set digest_update [ossweb::date now]
   ossweb::db::exec sql:maverix.sender.update.type
   maverix::cache::sender_flush $user_email $sender_email
   ossweb::conn::set_msg \
       "Thank you for completing this one-time verification process.<BR>
        Your message has been delivered to the intended recipient <B>$user_email.</B><P>
        All subsequent messages will now be delivered directly to<BR>
        <I>$user_email</I> without having to perform verification again."
 }
}

# Show current unverified recipient
set base_url [ossweb::conn::hostname]/maverix/Sender.oss
ossweb::db::multirow messages sql:maverix.sender.user.list -eval {
   set row(rcpt_verify) $base_url?s=$sender_email&d=$row(digest_id)&u=$row(user_email)&c=v
}

