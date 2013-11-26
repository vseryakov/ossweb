# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

namespace eval timesheet {
  variable version "Timesheet version 1.0"
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

# Link to timesheets from the toolbar
proc ossweb::html::toolbar::timesheet {} {

    if { [ossweb::conn::check_acl -acl *.timesheet.timesheet.view.*] } { return }
    return [ossweb::html::link -image timesheet.gif -status Timesheet -alt Timesheet -app_name timesheet timesheet]
}

