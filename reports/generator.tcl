# Author Darren Ferguson : darren@crystalballinc.com
# March 2002
# Author: Vlad Seryakov vlad@crystalballinc.com
# May 2002

ossweb::conn::callback report_email { } {

     foreach name [ossweb::form form_report widgets] {
       lappend remind_args $name [set $name]
     }
     switch $repeat {
      Daily {
        set date [ns_fmttime [ns_time] "%Y-%m-%d"]
      }
      Weekly {
        set week [eval ossweb::date weekArray [ns_fmttime [ns_time] "%d %m %y"]]
        set date [lindex $week 1]
      }
      Weekly2 {
        set week [eval ossweb::date weekArray [ns_fmttime [ns_time] "%d %m %y"]]
        set date [lindex $week 4]
        set repeat Weekly
      }
      Monthly {
        set date [ns_fmttime [ns_time] "%Y-%m-01"]
      }
      default {
        ossweb::db::exec sql:reports.calendar.delete
        ossweb::conn::set_msg "All Email notifications for this report has been deleted"
        return
      }
     }
     # Check for duplicate calendar entries
     if { [lsearch -exact [ossweb::db::list sql:reports.calendar.read] $repeat] > -1 } {
       ossweb::conn::set_msg "$repeat Email notification has been already set"
       return
     }
     calendar::create $date "1:0" $report_name \
            -repeat $repeat \
            -description $report_name \
            -remind 300 \
            -remind_args $remind_args \
            -remind_proc report::schedule::calendar
     ossweb::conn::set_msg "Email notification has been registered"
}

ossweb::conn::callback report_create { } {

     if { [ossweb::db::multivalue sql:reports.read] } {
        error "OSS: Unable to retrieve report information"
     }
     ossweb::form form_report -title $report_name
     ossweb::widget form_report.back -url [ossweb::html::url cmd view report_type $report_type]
     ossweb::widget form_report.email -type popupbutton -label "Email..." \
          -leftside \
          -options { { "Daily" "javascript:var i" "reportEmail('Daily');return false" } \
                     { "Weekly, every Monday" "javascript:var i" "reportEmail('Weekly');return false" } \
                     { "Weekly2, every Thursday" "javascript:var i" "reportEmail('Weekly2');return false" } \
                     { "Monthly, every 1st" "javascript:var i" "reportEmail('Monthly');return false" }
                     { "Clear All" "javascript:var i" "reportEmail('');return false" } }

     set data:rowcount 0
     set data:columns ""
     set data_opts(tr.params) "VALIGN=TOP"
     # Report formatting
     switch -- $report_fmt {
      csv {
         ossweb::conn -set html:link:disabled 1
      }
     }
     if { [catch {
         set db [ossweb::db::handle $dbpool_name]
         if { $before_script != "" } {
           eval $before_script
         }
         # XQL with Tcl proc name
         switch -glob -- $xql_id {
          "" {
          }

          tcl:* {
              eval $eval_script
          }

          select* -
          SELECT* {
             ossweb::db::multirow data $xql_id -db $db -debug t -maxrows $maxrows -eval $eval_script
          }

          default {
             ossweb::db::multirow data sql:$xql_id -db $db -debug t -maxrows $maxrows -eval $eval_script
          }
         }
         if { $after_script != "" } {
           eval $after_script
         }
     } errmsg] } {
       if { $errmsg != "STOP" } {
         global errorInfo
         ns_log Error report::generator: $report_id: $errmsg: $errorInfo
         error "OSS: Unable to create report $report_name"
       }
     }
     # Report formatting
     switch -- $report_fmt {
      csv {
         set file "[ns_info pageroot]/[ossweb::conn project_name]/reports/$report_id.csv"
         set data [ns_striphtml [string map { <BR> "\n" <br> "\n" } [ossweb::multirow csv data]]]
         ossweb::write_file $file $data
         set header 0
         set data:rowcount 0
         set data_body "<SCRIPT>window.open('$report_id.csv','XLS')</SCRIPT>"
         append data_body "<A HREF=$report_id.csv>CSV File: $report_id.csv</A>"
      }
     }
     # Spredsheet mode, show black grid
     if { $spreadsheet == 1 } {
       set cellspacing 1
       set cellpadding 2
       set underline 0
       set norow 1
       set style table
     }
     if { $data_rowcount == 0 } {
       set data_rowcount ${data:rowcount}
     }
     # Update report statistics
     ossweb::db::release
     ossweb::db::exec sql:reports.update.stats
     ossweb::form form_report set_values
}

ossweb::conn::callback report_edit { } {

    if { [ossweb::db::multivalue sql:reports.read] } {
      error "OSS: Unable to read report information"
    }
    ossweb::widget form_report.back -url [ossweb::html::url cmd view report_type $report_type]
    ossweb::form form_report -title $report_name
    ossweb::form form_report set_values
}

ossweb::conn::callback report_list { } {

    set type ""
    set tree_id 0
    set tree_seq -1
    set parent_id 0
    ossweb::db::foreach sql:reports.tree {
      if { $_report_acl != "" && [ossweb::conn::check_acl -acl $_report_acl] } { continue }
      set parent_id 0
      if { $_report_id == 0 } {
        set parent [lindex [split $_category_path |] end-2]
        if { [info exists folders($parent)] } { set parent_id $folders($parent) }
        append tree "Tree\[[incr tree_seq]\] = new Array([incr tree_id],$parent_id,'<B>$_category_name</B>','','');\n"
        if { $report_type == $_report_type } { set tree_open $tree_id }
        set folders($_report_type) $tree_id
      } else {
        set html ""
        switch -glob -- $_xql_id {
         /* -
         http://* {
            set url $_xql_id
            set html "TARGET=Report"
         }
         default {
            set url [ossweb::html::url cmd edit report_id $_report_id report_type $_report_type]
         }
        }
        if { [info exists folders($_report_type)] } { set parent_id $folders($_report_type) }
        append tree "Tree\[[incr tree_seq]\] = new Array([incr tree_id],$parent_id,'$_report_name','$url','$html');\n"
      }
    } -prefix "_"
}

ossweb::conn::callback create_form_report { } {

    ossweb::form form_report -title "Report" \
         -info "[ossweb::conn full_name] [ns_fmttime [ns_time] "%a, %d %b %Y %H:%M:%S"]" \
         -method GET
    ossweb::widget form_report.cmd -type hidden -value create -freeze
    ossweb::widget form_report.report_id -type hidden
    ossweb::widget form_report.user_id -type hidden -optional
    ossweb::widget form_report.report_name -type hidden -optional
    ossweb::widget form_report.repeat -type hidden -optional
    ossweb::widget form_report.category_name -type label -label "Report Type" \
         -info "<INPUT TYPE=RADIO NAME=report_fmt VALUE=html> HTML &nbsp;
                <INPUT TYPE=RADIO NAME=report_fmt VALUE=xls> Excel &nbsp;
                <INPUT TYPE=RADIO NAME=report_fmt VALUE=csv> CSV"
    if { [set emails [ossweb::db::list sql:reports.calendar.read]] != "" } {
      ossweb::widget form_report.emails -type label -label "Email Notifications" \
           -value $emails \
           -nohidden \
           -freeze
    }
    if { $report_id != "" && [set script [ossweb::db::value sql:reports.read.form_script]] != "" } {
      eval $script
    }
    ossweb::widget form_report.back -type button -label Back -leftside
    ossweb::widget form_report.create -type button -label Create -cmd_name create
    ossweb::widget form_report.reset -type reset -label Reset -clear
    ossweb::widget form_report.print -type button -label "Print" -html { onClick window.print() }
    if { $acl_edit == 0 } {
      ossweb::widget form_report.edit -type button -label Edit \
           -url [ossweb::html::url -app_name reports reports cmd edit report_id $report_id] \
           -leftside
    }
}

set columns { report_id int ""
              report_type "" ""
              report_mode "" ""
              report_fmt "" html
              report_name "" ""
              tree const ""
              style const ""
              tree_open var ""
              norow const 1
              underline const 1
              spreadsheet const 0
              width const 100%
              header const 1
              maxrows const 999999
              color2 const white
              cellspacing const 0
              cellpadding const 2
              data_border const 1
              data_title const ""
              data_body const ""
              data_header const ""
              data_footer const ""
              data_total const 1
              data_form const 1
              data_rowcount const 0
              acl_edit const {[ossweb::conn::check_acl -acl "*.*.*.*.*"]} }

ossweb::conn::process -columns $columns \
                      -forms form_report \
                      -form_recreate t \
                      -on_error index \
                      -eval {
                        email {
                          -validate { { report_id int } }
                          -forms { form_report }
                          -exec { report_email }
                          -next { -cmd_name edit }
                          -on_error { -cmd_name edit }
                        }
                        create {
                          -validate { { report_id int } }
                          -forms { form_report }
                          -exec { report_create }
                          -on_error { -cmd_name edit }
                        }
                        edit {
                          -validate { { report_id int } }
                          -forms { form_report }
                          -exec { report_edit }
                          -on_error { -cmd_name view }
                        }
                        default {
                          -exec { report_list }
                          -on_error { index.index }
                        }
                     }
