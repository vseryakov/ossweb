# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

set help_id ""
set text ""
set project_name ""
set app_name ""
set page_name ""
set cmd_name ""
set ctx_name ""

ossweb::conn::query

set edit ""
set title "No help available"

# Check if this user is allowed to enter new help entries and provide with
# link to help entering system
if { ![ossweb::conn::check_acl -app_name admin -page_name help -cmd_name update] } {
  set edit [ossweb::html::url -lookup t -app_name admin helpadm cmd edit project_name $project_name app_name $app_name page_name $page_name cmd_name $cmd_name ctx_name $ctx_name]
}

ossweb::db::multivalue sql:ossweb.help.search

catch { set text [subst $text] }
