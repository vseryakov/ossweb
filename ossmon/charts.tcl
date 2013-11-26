# Author Darren Ferguson : darren@crystalballinc.com
# June 2001
# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback chart_action {} {

    if { $chart_date != "" } {
      set start_date [ossweb::date parse2 $chart_date]
      set end_date [ossweb::date -set $start_date hours 23 minutes 59 seconds 59]
    }
    set image ""
    foreach obj_id $objects {
      append image [ossmon::chart::exec $obj_id $type \
                      -debug f \
                      -start_date [ossweb::date clock $start_date] \
                      -end_date [ossweb::date clock $end_date] \
                      -filter $filter] " "
    }
    ns_log Debug $image
    if { [string trim $image] == "" } {
      set html "<B>No data available<B><P>"
      return
    }
    foreach name $image {
      append html "<CENTER><IMG SRC=$name BORDER=0></CENTER><P>"
    }
}

ossweb::conn::callback chart_edit {} {

   ossweb::form form_chart set_values
}

ossweb::conn::callback create_form_chart { } {

    ossweb::widget form_chart.chart_date -type hidden -optional
    ossweb::widget form_chart.objects -type multiselect -label "Objects(s)" \
         -options [ossweb::db::multilist sql:ossmon.object.list.collect] \
         -html { size 6 } \
         -optional
    ossweb::widget form_chart.hosts -type multiselect -label "Host(s)" \
         -options [ossweb::db::multilist sql:ossmon.object.list.hosts] \
         -html { size 6 } \
         -optional
    ossweb::widget form_chart.type -type select -label "Type" \
         -options [ossmon::chart::get_types]
    ossweb::widget form_chart.start_date -type date -datatype date \
         -format "DD MONTH YYYY HH24 MI" -label "Start Date"
    ossweb::widget form_chart.end_date -type date -datatype date \
         -format "DD MONTH YYYY HH24 MI" -label "End Date" -optional
    ossweb::widget form_chart.filter -type text -label "Filter" -optional
    ossweb::widget form_chart.cmd -type button -label Create \
         -html { onClick chartSubmit(this.form,'') }
}

# Table/form columns
set columns { objects list ""
              hosts list ""
              chart_date "" ""
              start_date date {[ossweb::date -set [ossweb::date -set "" clock [expr [ns_time]-60*60*24]] minutes 0]}
              end_date date {[ossweb::date -set [ossweb::date now] minutes 0]}
              winopts const "menubar=0,width=800,height=600,location=0,scrollbars=1"
              type "" ""
              filter "" ""
              trend "" ""
              html var "" }

# Process request parameters takes columns and form name and calls the function to create the form
ossweb::conn::process -columns $columns \
           -forms { form_chart } \
           -on_error_set_cmd "" \
           -eval {
             chart {
              -exec { chart_action }
              -on_error { -cmd_name default }
             }
             default {
              -exec { chart_edit }
              -on_error { -cmd_name default index }
             }
           }
