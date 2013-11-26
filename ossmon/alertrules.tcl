# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback match_action {} {

    switch ${ossweb:cmd} {
     add -
     update {
       if { $match_id == "" } {
         if { [ossweb::db::exec sql:ossmon.alert_rule.match.create] } {
           error "OSS: Could not insert the record"
         }
       } else {
         if { [ossweb::db::exec sql:ossmon.alert_rule.match.update] } {
           error "OSS: Could not update the record"
         }
       }
       ossweb::conn::set_msg "The record has been updated, click on [ossweb::html::image refresh.gif] or Refresh button to refresh rules local cache"
     }

     delete {
       if { [ossweb::db::exec sql:ossmon.alert_rule.match.delete] } {
         error "OSS: Could not delete the record"
       }
       set match_id ""
       ossweb::conn::set_msg "The record has been deleted, click on [ossweb::html::image refresh.gif] or Refresh button to refresh rules local cache"
     }
    }
    # Refersh local cache
    ossmon::alert::refresh
}

ossweb::conn::callback run_action {} {

    switch ${ossweb:cmd} {

     add -
     update {
       if { $run_id == "" } {
         if { [ossweb::db::exec sql:ossmon.alert_rule.run.create] } {
           error "OSS: Could not insert the record"
         }
       } else {
         if { [ossweb::db::exec sql:ossmon.alert_rule.run.update] } {
           error "OSS: Could not update the record"
         }
       }
       ossweb::conn::set_msg "The record has been updated"
     }

     delete {
       if { [ossweb::db::exec sql:ossmon.alert_rule.run.delete] } {
         error "OSS: Could not delete the record"
       }
       ossweb::conn::set_msg "The record has been removed"
     }
    }
    # Refersh local cache
    ossmon::alert::refresh
}

ossweb::conn::callback rule_action {} {

    switch ${ossweb:cmd} {

     update {
       if { $rule_id == "" } {
         if { [ossweb::db::exec sql:ossmon.alert_rule.create] } {
           error "OSS: Could not insert the record"
         }
         set rule_id [ossweb::db::currval ossmon_util]
       } else {
         if { [ossweb::db::exec sql:ossmon.alert_rule.update] } {
           error "OSS: Could not update the record"
         }
       }
       ossweb::conn::set_msg "The record has been updated"
     }

     delete {
       ossweb::db::begin
       if { [ossweb::db::exec sql:ossmon.alert_rule.match.delete_all] ||
            [ossweb::db::exec sql:ossmon.alert_rule.run.delete_all] ||
            [ossweb::db::exec sql:ossmon.action.rule.delete] } {
         error "OSS: Could not delete the record"
       }
       ossweb::db::commit
       ossweb::conn::set_msg "The record has been removed"
     }

     copy {
       ossweb::db::begin
       set new_rule_id [ossweb::db::nextval ossmon_util]
       if { [ossweb::db::exec sql:ossmon.alert_rule.copy] ||
            [ossweb::db::exec sql:ossmon.alert_rule.copy.run] ||
            [ossweb::db::exec sql:ossmon.alert_rule.copy.match] } {
         error "OSS: Could not copy the record"
       }
       set rule_id $new_rule_id
       ossweb::db::commit
       ossweb::conn::set_msg "The record has been removed"
     }
    }
    # Refersh local cache
    ossmon::alert::refresh
}

ossweb::conn::callback rule_edit { } {

    if { $rule_id == "" } {
      ossweb::form form_rule set_values
      return
    }
    if { [ossweb::db::multivalue sql:ossmon.alert_rule.read] } {
      error "OSS: Record not found"
    }
    set rule_link [ossweb::html::link -text "<B>\[$rule_id\]</B>" cmd edit rule_id $rule_id]
    ossweb::form form_rule set_values
    ossweb::form form_rule.interval -info [ossweb::date uptime $interval]
    ossweb::form form_match reset -vars f
    ossweb::form form_run reset -vars f
    ossweb::widget form_match.rule_id -value $rule_id
    ossweb::widget form_run.rule_id -value $rule_id

    switch -- ${ossweb:ctx} {
     match {
       ossweb::db::multivalue sql:ossmon.alert_rule.match.read
       ossweb::form form_match set_values
       ossweb::widget form_match.cmd -label Update
     }
    }
    ossweb::db::multirow match sql:ossmon.alert_rule.match_list -eval {
      set row(edit) [ossweb::html::link -image edit.gif -alt Edit cmd edit.match match_id $row(match_id) rule_id $rule_id]
      append row(edit) [ossweb::html::link -image trash.gif -alt Delete cmd delete.match match_id $row(match_id) rule_id $rule_id]
    }

    ossweb::db::multirow run sql:ossmon.alert_rule.run_list -eval {
      set row(delete) [ossweb::html::link -image trash.gif -alt Delete cmd delete.run run_id $row(run_id) rule_id $rule_id]
      set row(template_name) [ossweb::html::link -text $row(template_name) templates cmd edit template_id $row(template_id)]
      set row(type_name) [ossmon::alert::action::get_title $row(action_type)]
    }
}

ossweb::conn::callback rule_list {} {

    set rules:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    set rules:refresh [ossweb::html::link -image refresh.gif -alt Refresh cmd refresh]
    ossweb::db::multirow rules sql:ossmon.alert_rule.list -set_null "&nbsp;" -eval {
      set row(rule_name) [ossweb::html::link -text $row(rule_name) cmd edit rule_id $row(rule_id)]
      if { $row(interval) != "" } {
        append row(interval) " ([ossweb::date uptime $row(interval)])"
      }
      set alerts ""
      foreach { atype aid atmpl } $row(alerts) {
        append alerts "[ossmon::alert::action::get_title $atype]/$atmpl<BR>"
      }
      set row(alerts) $alerts
    }
}

ossweb::conn::callback create_form_rule {} {

    ossweb::widget form_rule.rule_id -type hidden -optional
    ossweb::widget form_rule.rule_name -type text -label "Rule Name"
    ossweb::widget form_rule.status -type select -label "Status" \
         -options { { Active Active } { Disabled Disabled } }
    ossweb::widget form_rule.mode -type select -label "Mode" \
         -options { { Alert ALERT } { Final FINAL } }
    ossweb::widget form_rule.ossmon_type -type text -label "OSSMON Type" \
         -optional
    ossweb::widget form_rule.precedence -type text -label "Priority" -datatype integer
    ossweb::widget form_rule.level -type select -label Level \
         -options { { Error Error } { Critical Critical } { Warning Warning } { Advise Advise } }
    ossweb::widget form_rule.threshold -type text -label "Threshold" -datatype integer -optional
    ossweb::widget form_rule.interval -type text -label "Interval" -datatype integer -optional
    ossweb::widget form_rule.back -type button -label "Back" -url [ossweb::html::url cmd view]
    ossweb::widget form_rule.update -type submit -name cmd -label "Update"
    ossweb::widget form_rule.delete -type submit -name cmd -label "Delete" \
         -html { onClick "return confirm('Are you sure?')" }
    ossweb::widget form_rule.copy -type submit -name cmd -label "Copy" \
         -html { onClick "return confirm('Copy the alert rule?')" }
    ossweb::widget form_rule.refresh -type button -label "Refresh" \
         -url [ossweb::html::url cmd refresh]


    ossweb::widget form_match.rule_id -type hidden

    ossweb::widget form_match.match_id -type hidden -optional

    ossweb::widget form_match.ctx -type hidden -value match -freeze

    ossweb::widget form_match.name -type text -label Name \
         -size 40 \
         -resize
         
    ossweb::widget form_match.operator -type select -label Name \
         -options [ossmon::property operators]

    ossweb::widget form_match.value -type text -label Value \
         -size 40 \
         -resize
         
    ossweb::widget form_match.mode -type select -label Mode \
         -options { { AND AND } { OR OR } { "NOT AND" "NOT AND" } { "NOT OR" "NOT OR" } }

    ossweb::widget form_match.cmd -type submit -label Add

    ossweb::widget form_run.rule_id -type hidden
    ossweb::widget form_run.ctx -type hidden -value run -freeze
    ossweb::widget form_run.action_type -type select -label "Action Type" \
         -options [ossmon::alert::action::get_types] \
         -empty --
    ossweb::widget form_run.template_id -type select -label Template \
         -options [ossweb::db::multilist sql:ossmon.template.list] \
         -empty --
    ossweb::widget form_run.cmd -type submit -label Add
}
# Table/form columns
set columns { rule_id int ""
              rule_link var ""
              match_id int ""
              run_id int ""
              status "" "Active Disabled" }

ossweb::conn::process -columns $columns \
           -forms { form_rule form_match form_run } \
           -eval {
             add -
             copy -
             update {
              -exec {
                 switch -- ${ossweb:ctx} {
                   match { match_action }
                   run { run_action }
                   default { rule_action }
                 }
              }
              -on_error { -cmd_name edit -ctx_name rule }
              -next { -cmd_name edit -ctx_name rule }
             }
             delete {
              -exec {
                 switch ${ossweb:ctx} {
                   match {
                      match_action
                      ossweb::conn::next -cmd_name edit -ctx_name view
                   }
                   run {
                      run_action
                      ossweb::conn::next -cmd_name edit -ctx_name view
                   }
                   default {
                      rule_action
                      ossweb::conn::next -cmd_name view
                   }
                 }
              }
              -on_error { -cmd_name edit }
             }
             refresh {
               -exec { ossmon::alert::refresh }
               -next { -cmd_name view }
             }
             edit {
              -exec { rule_edit }
              -on_error { -cmd_name view }
             }
             default {
              -form_validate { none }
              -exec { rule_list }
              -on_error { index.index }
             }
           }
