# Author: Vlad Seryakov vlad@crystalballinc.com
# October 2002
# Modified Darren Ferguson : darren@crystalballinc.com
# May 2003

namespace eval report {
  namespace eval schedule {
    namespace eval monthly {}
    namespace eval weekly {}
    namespace eval daily {}
  }
}

# Which reports should be run on weekly basis
proc report::schedule::monthly { { end_date "" } } {

    set report_types ""
    foreach name [lsort [eval "namespace eval ::report::schedule::monthly { info procs }"]] {
      foreach type [$name] {
        lappend report_types $type
      }
    }
    report::schedule $end_date month Monthly $report_types 90
}

# Which reports should be run on weekly basis
proc report::schedule::weekly { { end_date "" } } {

    set report_types ""
    foreach name [lsort [eval "namespace eval ::report::schedule::weekly { info procs }"]] {
      foreach type [$name] {
        lappend report_types $type
      }
    }
    report::schedule $end_date 7 Weekly $report_types
}

# Which reports should be run on daily basis
proc report::schedule::daily { { end_date "" } } {

    set report_types ""
    foreach name [lsort [eval "namespace eval ::report::schedule::daily { info procs }"]] {
      foreach type [$name] {
        lappend report_types $type
      }
    }
    report::schedule $end_date 1 Daily $report_types
}

# Runs specified reports and saves them into files
proc report::schedule { end_date interval category_type report_types { category_days 31 } } {

    if { $report_types == "" || $category_type == "" } { return }

    # Path to the report directory, create if does not exist
    set report_path /[ossweb::conn project_name]/reports
    if { ![file exists [ns_info pageroot]$report_path] } {
      file mkdir [ns_info pageroot]$report_path
    }
    # Date range for the report
    set end_date [ossweb::nvl $end_date [ossweb::date today]]
    switch $interval {
     month {
       # Monthly report
       switch [set day [ossweb::date day $end_date]] {
        1 {
          set clock [ossweb::date clock $end_date]
          incr clock -86400
          set end_date [ossweb::date -set "" clock $clock]
        }
       }
       set month [ossweb::date month $end_date]
       set year [ossweb::date year $end_date]
       set days [ossweb::date daysInMonth $month $year]
       set start_date [ossweb::date -set "" year $year month $month day 1]
       set end_date [ossweb::date -set "" year $year month $month day $days]
     }
     default {
       set start_date [ossweb::date -set "" clock [expr [ossweb::date clock $end_date]-86400*$interval]]
     }
    }
    set dates [ossweb::date pretty_date $start_date]-[ossweb::date pretty_date $end_date]
    # Generate report output for the specified dates
    set html ""

    foreach report $report_types {
      foreach { report_title types vars } $report {}
      foreach xql_id $types {
        if { [ossweb::db::multivalue sql:reports.read.by.xql_id] } {
          ns_log Error report::schedule: $xql_id not found
          continue
        }
        append html [report::run $xql_id \
                          -width 600 \
                          -debug t \
                          -report_mode schedule \
                          -spreadsheet 1 \
                          -before_script $before_script \
                          -after_script $after_script \
                          -eval_script $eval_script \
                          -template $template \
                          -data_title $report_title \
                          -vars $vars]
      }
    }
    # Folder under which we put our report
    if { $html != "" } {
      set category_id $category_type$dates
      set category_name "$category_type Report $dates"
      set category_parent 0$category_type
      set report_type $category_id
      set report_name $category_name
      set report_file $report_path/[string map { / - } $report_name].html
      set xql_id $report_file
      set html "<CENTER>[ossweb::html::title $report_name]</CENTER><P>$html"
      ossweb::write_file [ns_info pageroot]/$report_file $html
      # Create new report category if doesn't exist
      if { [ossweb::db::multilist sql:reports.category.edit] == "" } {
        ossweb::db::exec sql:reports.category.create
      }
      # Create new report record if doesn't exist
      if { [ossweb::db::multilist sql:reports.search] == "" } {
        ossweb::db::exec sql:reports.create
      }
      # Delete old categories from the parent
      ossweb::db::exec sql:reports.category.delete.old
      ossweb::db::exec sql:reports.delete.old
    }
}

# To be run from calendar entry to send reports by email
proc report::schedule::calendar { args } {

    foreach { name value } $description { set $name $value }

    if { [ossweb::db::multivalue sql:reports.read] } {
      ns_log Error report::schedule::calendar: Unable to retrieve report $description
      return
    }
    ossweb::form form_report -action [ossweb::html::url -app_name reports generator]
    ossweb::widget form_report.category_name -type label -label "Report Type"
    ossweb::widget form_report.report_name -type label -label "Report Name"
    eval $form_script

    foreach widget [ossweb::form form_report widgets] {
      switch [ossweb::widget form_report.$widget name] {
       start_date {
         set start_date [ossweb::coalesce start_date]
         switch $repeat {
          Weekly {
            # Runs every week
            if { $start_date != "" } {
              set now [expr [ns_time]-86400*7]
              set start_date [ossweb::date -set "" clock $now]
            }
          }
          Monthly {
            # Runs every 1st of each month
            if { $start_date != "" } {
              set now [expr [ns_time]-86400]
              set now [clock scan "[ns_fmttime $now "%m"]/01/[ns_fmttime $now "%Y"]"]
              set start_date [ossweb::date -set "" clock $now]
            }
          }
          Daily {
            # Runs every day
            if { $start_date != "" } {
              set start_date [ossweb::date -set "" clock [ns_time]]
            }
          }
         }
       }

       end_date {
         set end_date [ossweb::coalesce end_date]
         switch $repeat {
          Weekly {
            # Runs every week
            if { $end_date != "" } {
              set end_date [ossweb::date -set "" clock [ns_time]]
            }
          }
          Monthly {
            # Runs every 1st of each month
            if { $end_date != "" } {
              set end_date [ossweb::date -set "" clock [ns_time]]
            }
          }
          Daily {
            # Runs every day
            if { $end_date != "" } {
              set end_date [ossweb::date -set "" clock [ns_time]]
            }
          }
         }
       }

       default {
         switch [ossweb::widget form_report.$widget type] {
          select { set field_widget labelselect }
          default { set field_widget label }
         }
         ossweb::widget form_report.$widget -type $field_widget -nohidden
       }
      }
    }
    ossweb::form form_report set_values
    set output [report::run $xql_id \
                     -dbpool_name $dbpool_name \
                     -before_script $before_script \
                     -after_script $after_script \
                     -eval_script $eval_script \
                     -form form_report]
    ossweb::sendmail $user_email calendar $subject $output \
         -headers "Cc {$remind_email}" \
         -content_type text/html
}

# Runs one report in batch mode, returns output
proc report::run { xql_id args } {

    ns_parseargs { {-template ""}
                   {-dbpool_name ""}
                   {-before_script ""}
                   {-eval_script ""}
                   {-after_script ""}
                   {-report_mode schedule}
                   {-spreadsheet 0}
                   {-underline 1}
                   {-header 1}
                   {-norow 1}
                   {-border1 0}
                   {-border2 0}
                   {-class1 ""}
                   {-class2 ""}
                   {-width 100%}
                   {-data_none "No data available"}
                   {-data_text ""}
                   {-data_body ""}
                   {-data_title ""}
                   {-data_header ""}
                   {-data_footer ""}
                   {-cellspacing 1}
                   {-cellpadding 2}
                   {-tr_params VALIGN=TOP}
                   {-td_params ""}
                   {-th_params ""}
                   {-master ../index/index.title}
                   {-form ""}
                   {-debug f}
                   {-stack 10}
                   {-maxrows 1000}
                   {-vars ""}
                   {-level {=$expr [info level]-1}} } $args

    set defaults { report_mode $report_mode
                   spreadsheet $spreadsheet
                   underline $underline
                   header $header
                   class1 $class1
                   border1 $border1
                   class2 $class2
                   border2 $border2
                   width $width
                   norow $norow
                   data_none $data_none
                   data_text $data_text
                   data_body $data_body
                   data_title $data_title
                   data_header $data_header
                   data_footer $data_footer
                   cellspacing $cellspacing
                   cellpadding $cellpadding
                   data_opts(th.params) $th_params
                   data_opts(td.params) $td_params
                   data_opts(tr.params) $tr_params }

    foreach { name value } $defaults {
      upvar #$level $name var
      set var [subst $value]
    }
    foreach { name value } $vars {
      upvar #$level $name var
      set var [subst $value]
    }
    upvar #$level data:rowcount data_rowconut
    set data_rowcount 0
    ossweb::conn -append html:head "<BASE HREF=[ossweb::conn::hostname]>"
    ossweb::conn -set adp:stack:size $stack

    ns_log Notice report::run: $xql_id: level=$level

    if { [catch {
      if { $dbpool_name != "" } {
        set db [ossweb::db::handle $dbpool_name]
      }
      if { $before_script != "" } {
        uplevel #$level $before_script
      }
      # XQL with Tcl proc name
      switch -glob -- $xql_id {
       "" {
       }

       tcl:* {
          uplevel #$level $eval_script
       }

       select* -
       SELECT* {
          ossweb::db::multirow data $xql_id -db $db -debug $debug -level $level -maxrows $maxrows -eval $eval_script
       }

       default {
          ossweb::db::multirow data sql:$xql_id -db $db -debug $debug -level $level -maxrows $maxrows -eval $eval_script
       }
      }
      if { $after_script != "" } {
        uplevel #$level $after_script
      }
    } errmsg] } {
      if { $errmsg != "STOP" } {
        global errorInfo
        ns_log Error report::run: $xql_id: $errmsg: $errorInfo
      }
    }
    # Default template as simple table
    if { $template == "" } {
      if { $spreadsheet == 1 } {
        set color2 black
        set cellspacing 1
        set cellpadding 2
        set underline 0
        set norow 1
      }
      if { $master != "" } {
        set template "<master src=$master>"
      }
      if { $data_title != "" } {
        append template [ossweb::html::title $data_title]<BR>
      }
      if { $form != "" } {
        append template "<formtemplate id=$form nohelp=1></formtemplate>"
      }
      append template {
         <if @data:rowcount@ le 0 and @data_body@ eq "">
            <B>@data_none@</B>
            <return>
         </if>
         @data_title@
         <border border1=@border1@ border2=@border2@ width=@width@ class1=@class1@ class2=@class2@ cellspacing=@cellspacing@ cellpadding=@cellpadding@>
         @data_header@
         <multirow name=data norow=@norow@ underline=@underline@ header=@header@ options=data_opts></multirow>
         @data_footer@
         </border>
         @data_body@}
    }
    return [ossweb::adp::Evaluate $template $level]
}

# Generates Excel report from datasource, requires Aware Reports http://www.awaresw.com
proc report::excel { tmpl args } {

    ossweb::util::parse_args {
                      -data data
                      -header_data ""
                      -sheet_name report
                      -sheet_title "Excel Report"
                      -xls_file {/[ossweb::conn project_name]/reports/[ossweb::conn user_id].xls}
                      -csv_file {/tmp/[ossweb::conn user_id].csv}
                      -window t
                      -eval2 ""
                      -eval { foreach name \$data_columns {
                                if { \[string index \$row(\$name) 0] == "_" } { continue }
                                if { \[regexp {\[,\\n\\r\\t\\"\]} \$row(\$name)] } {
                                  append csv \\"\[string map { {\"} {} } \$row(\$name)\]\\",
                                } else {
                                  append csv \$row(\$name),
                                }
                              }
                            }
                      } {} $args

    upvar header header ${data}_body data_body ${data}:columns data_columns ${data}:rowcount data_rowcount

    set csv "document\n"
    append csv "$sheet_name,\"$sheet_title\"\n"
    append csv "header$header_data\n"
    for { set i 1 } { $i <= $data_rowcount } { incr i } {
      upvar $data:$i row
      append csv "row,"
      eval $eval
      append csv "\n"
    }
    if { $eval2 != "" } {
      eval $eval2
    }
    append csv "end$sheet_name\n"
    append csv "enddocument\n"
    ossweb::write_file $csv_file $csv
    exec /usr/local/bin/awrtp -t xls [ns_info home]/modules/xls/$tmpl.xls <$csv_file >[ns_info pageroot]/$xls_file
    if { $window == "t" } {
      set header 0
      set data_columns ""
      set data_rowcount 0
      set data_body "<SCRIPT>window.open('$xls_file','XLS')</SCRIPT>"
    }
    append data_body "<A HREF=$xls_file>Download Excel File</A>"
    return $xls_file
}
