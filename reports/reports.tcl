# Author Darren Ferguson : darren@crystalballinc.com
# March 2002
# Author: Vlad Seryakov vlad@crystalballinc.com
# May 2002

ossweb::conn::callback report_action { } {

     ossweb::db::begin
     switch -exact ${ossweb:cmd} {
      update {
         if { $report_id == "" } {
           set report_id [ossweb::db::nextval reports]
           if { [ossweb::db::exec sql:reports.create] } {
             set report_id ""
             error "OSS: Could not create the new report type in the system"
           }
         } else {
           if { [ossweb::db::exec sql:reports.update] } {
             error "OSS: Could not update the report type in the system"
           }
           ossweb::conn::set_msg  "Report type has been successfully updated"
         }
      }

      copy {
         set old_report_id $report_id
         set report_id [ossweb::db::nextval reports]
         if { [ossweb::db::exec sql:reports.copy] } {
           set report_id $old_report_id
           error "OSS: Unable to copy the report"
         }
      }

      delete {
         if { [ossweb::db::exec sql:reports.delete] } {
           error "OSS: Could not remove the report type from the system"
         }
         ossweb::conn::set_msg  "Report type has been successfully removed from the system"
      }
     }
     ossweb::db::commit
}

ossweb::conn::callback script_action {} {

    if { [ossweb::db::exec sql:reports.update.script] } {
      error "OSS: Could not update the report type in the system"
    }
}

ossweb::conn::callback report_edit { } {

    if { $report_id != "" && [ossweb::db::multivalue sql:reports.read] } {
       error "OSS: Unable to read report record"
    }
    set report_link [ossweb::html::link -text "\[$report_id\]" cmd edit report_id $report_id]
    ossweb::form form_report set_values

    if { $report_id == "" } { return }

    ossweb::widget form_report.report_version -info "$run_count: $run_date"
    if { [set len [string length $xql_id]] > 80 } {
      ossweb::widget form_report.xql_id -rows [expr round($len/80)]
    }
    switch $tab {
     form -
     eval -
     after {
     }

     before {
       ossweb::widget form_tcl.before_script -type textarea -info {
        <DIV STYLE="font-size:7pt;font-weight:normal;text-align:left;padding:10px;">
        The following Tcl variables can change default view of the report:<P>
          <UL>
          <LI>style - border style, passed to border tag
          <LI>underline - if 1, each row will be underlined
          <LI>spreadsheet - if 1, table will look like spreadsheet
          <LI>width - default 100%
          <LI>header - if 0, no header will be shown with data rows, default 1
          <LI>maxrows - max number of rows, default 999999
          <LI>cellspacing - default 0
          <LI>cellpadding - default 2
          <LI>data_border - show multirow data, default 1
          <LI>data_title - HTML to show before data rows
          <LI>data_body - HTML to show after data rows
          <LI>data_header - TR with columns to show just before data rows, useful with "set header 0"
          <LI>data_footer - TR with columnd to show just after data rows, like totals
          <LI>data_total - to show total row counter, default 1
          <LI>data_form - if 0, do not show for with report fields
          <LI>data:columns - array with columns for data rows
          <LI>data:rowcount - number of records in the datasource "data"
          </DIV>
        }
     }

     summary {
       set form_script [ns_quotehtml $form_script]
       set before_script [ns_quotehtml $before_script]
       set eval_script [ns_quotehtml $eval_script]
       set after_script [ns_quotehtml $after_script]
     }

     sql {
       set before_script "INSERT INTO report_types [ossweb::sql::insert_values -nl "\n" -skip_null t -full t \
                          { report_id int ""
                            report_name "" ""
                            report_type "" ""
                            report_acl "" ""
                            report_version int ""
                            xql_id "" ""
                            dbpool_name "" ""
                            disable_flag "" ""
                            form_script "" ""
                            before_script "" ""
                            eval_script "" ""
                            after_script "" "" }]"
     }
    }
    ossweb::form form_tcl set_values
}

ossweb::conn::callback report_list {} {

    set report:add [ossweb::html::link -image add.gif -alt "Add New Report Type" cmd edit]
    ossweb::db::multirow reports sql:reports.read.all -eval {
       set row(report_name) [ossweb::html::link -text "$row(report_name)" cmd edit report_id $row(report_id)]
    }
}

ossweb::conn::callback create_form_report {} {

    ossweb::widget form_report.report_id -type hidden -label "Report Type ID" \
              -optional

    ossweb::widget form_report.report_version -type select -label "Report Version" \
               -options { { 2 2 } { 1 1 } }

    ossweb::widget form_report.report_name -type text -label "Report Type Name" \
               -html { size 40 }

    ossweb::widget form_report.report_type -type select -label "Report Category" \
              -options [ossweb::db::multilist sql:reports.category.select.read]

    ossweb::widget form_report.xql_id -type textarea -label "XQL ID or SQL" \
              -cols 80 \
              -rows 1 \
              -resize

    ossweb::widget form_report.dbpool_name -type text -label "DB Pool" \
              -optional

    ossweb::widget form_report.report_acl -type text -label "ACL" \
              -optional

    ossweb::widget form_report.disable_flag -type select -label "Disabled" \
              -options { { No f } { Yes t } } \
              -optional

    ossweb::widget form_report.back -type button -label Back \
              -url [ossweb::html::url cmd view]

    ossweb::widget form_report.update -type submit -name cmd -label Update

    ossweb::widget form_report.copy -type button -label Copy \
              -confirm "confirm('Report will be copied, continue?')" \
              -url [ossweb::html::url cmd copy report_id $report_id] \
              -condition "@report_id@ gt 0"

    ossweb::widget form_report.delete -type submit -name cmd -label Delete \
              -condition "@report_id@ gt 0" \
              -html { onClick "return confirm('Are you sure?');" }

    ossweb::widget form_report.run -type button -label Run \
              -condition "@report_id@ gt 0" \
              -url [ossweb::html::url generator cmd edit report_id $report_id]
}

ossweb::conn::callback create_form_tcl {} {

    ossweb::form form_tcl -width1 5% -ctx script

    ossweb::widget form_tcl.report_id -type hidden

    ossweb::widget form_tcl.tab -type hidden -value $tab -freeze

    ossweb::widget form_tcl.${tab}_script -type textarea -label "[string totitle $tab] Script" \
         -html { cols 120 rows 30 wrap off } \
         -optional \
         -resize

    ossweb::widget form_tcl.update -name cmd -type submit -label "Update"
}

ossweb::conn::callback create_form_tab {} {

    set url [ossweb::html::url cmd edit report_id $report_id]

    ossweb::widget form_tab.form -type link -label "Form Script" -value $url

    ossweb::widget form_tab.before -type link -label "Before Script" -value $url

    ossweb::widget form_tab.eval -type link -label "Eval Script" -value $url

    ossweb::widget form_tab.after -type link -label "After Script" -value $url

    ossweb::widget form_tab.summary -type link -label "Summary" -value $url

    ossweb::widget form_tab.sql -type link -label "SQL" -value $url
}

set columns { report_id int ""
              field_id int ""
              before_script "" ""
              eval_script "" ""
              after_script "" ""
              tab var form }

ossweb::conn::process -columns $columns \
                     -forms { form_report form_tcl form_tab } \
                     -form_recreate t \
                     -eval {
                        delete {
                           -exec { report_action }
                           -on_error { -cmd_name view }
                           -next { -cmd_name view }
                        }
                        copy -
                        update {
                           -exec { report_action }
                           -on_error { -cmd_name view }
                           -next { -cmd_name edit }
                        }
                        update.script {
                           -exec { script_action }
                           -on_error { -cmd_name view }
                           -next { -cmd_name edit }
                        }
                        edit {
                           -exec { report_edit }
                           -on_error { -cmd_name view }
                        }
                        default {
                           -exec { report_list }
                           -on_error { -cmd_name default report_types }
                        }
                     }
