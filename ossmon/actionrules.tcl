# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback match_action {} {

    switch ${ossweb:cmd} {

     add -
     update {
       if { $match_id == "" } {
         if { [ossweb::db::exec sql:ossmon.action_rule.match_create] } {
           error "OSS: Could not insert the record"
         }
       } else {
         if { [ossweb::db::exec sql:ossmon.action_rule.match_update] } {
           error "OSS: Could not update the record"
         }
       }
       ossweb::conn::set_msg "The record has been updated, click on [ossweb::html::image refresh.gif] or Refresh button to refresh rules local cache"
     }

     delete {
       if { [ossweb::db::exec sql:ossmon.action_rule.match_delete] } {
         error "OSS: Could not delete the record"
       }
       set match_id ""
       ossweb::conn::set_msg "The record has been removed, click on [ossweb::html::image refresh.gif] or Refresh button to refresh rules local cache"
     }
    }
    # Refersh local cache
    ossmon::action::refresh
}

ossweb::conn::callback script_action {} {

    switch ${ossweb:cmd} {
     add -
     update {
       if { $script_id == "" } {
         if { [ossweb::db::exec sql:ossmon.action_rule.script_create] } {
           error "OSS: Could not insert the record"
         }
       } else {
         if { [ossweb::db::exec sql:ossmon.action_rule.script_update] } {
           error "OSS: Could not update the record"
         }
       }
       set script_id ""
       ossweb::conn::set_msg "The record has been updated"
     }

     delete {
       if { [ossweb::db::exec sql:ossmon.action_rule.script_delete] } {
         error "OSS: Could not delete the record"
       }
       ossweb::conn::set_msg "The record has been removed"
     }
    }
    # Refersh local cache
    ossmon::action::refresh
}


ossweb::conn::callback rule_action {} {

    switch ${ossweb:cmd} {

     update {
       if { $rule_id == "" } {
         if { [ossweb::db::exec sql:ossmon.action_rule.create] } {
           error "OSS: Could not insert the record"
         }
         set rule_id [ossweb::db::currval ossmon_util]
       } else {
         if { [ossweb::db::exec sql:ossmon.action_rule.update] } {
           error "OSS: Could not update the record"
         }
       }
       ossweb::conn::set_msg "The record has been updated"
     }

     delete {
       ossweb::db::begin
       if { [ossweb::db::exec sql:ossmon.action_rule.match_delete_all] ||
            [ossweb::db::exec sql:ossmon.action_rule.script_delete_all] ||
            [ossweb::db::exec sql:ossmon.action_rule.delete] } {
         error "OSS: Could not delete the record"
       }
       ossweb::db::commit
       ossweb::conn::set_msg "The record has been removed"
     }
    }
    # Refersh local cache
    ossmon::action::refresh
}

ossweb::conn::callback rule_edit { } {

    if { $rule_id == "" } {
      ossweb::form form_rule set_values
      return
    }
    if { [ossweb::db::multivalue sql:ossmon.action_rule.read] } {
      error "OSS: Record not found"
    }
    set rule_link [ossweb::html::link -text "<B>\[$rule_id\]</B>" cmd edit rule_id $rule_id]
    ossweb::form form_rule set_values
    ossweb::form form_match reset -vars f
    ossweb::form form_script reset -vars f
    ossweb::widget form_match.rule_id -value $rule_id
    ossweb::widget form_script.rule_id -value $rule_id

    switch -- ${ossweb:ctx} {
     match {
       ossweb::db::multivalue sql:ossmon.action_rule.match_read
       ossweb::form form_match set_values
       ossweb::widget form_match.cmd -label Update
     }
    }
    ossweb::db::multirow match sql:ossmon.action_rule.match_list -eval {
      set row(edit) [ossweb::html::link -image edit.gif -alt Edit cmd edit.match match_id $row(match_id) rule_id $rule_id]
      append row(edit) [ossweb::html::link -image trash.gif -alt Delete cmd delete.match match_id $row(match_id) rule_id $rule_id]
    }
    ossweb::db::multirow script sql:ossmon.action_rule.script_list -eval {
      # Update existing script
      if { ${ossweb:ctx} == "script" && $row(script_id) == $script_id } {
        ossweb::widget form_script.value -value $row(value)
        ossweb::widget form_script.script_id -value $script_id
        ossweb::widget form_script.cmd -label Update
      }
      regsub -all {\n} $row(value) {<BR>} row(value)
      set row(delete) [ossweb::html::link -image trash.gif -alt Delete cmd delete.script script_id $row(script_id) rule_id $rule_id]
      set row(edit) [ossweb::html::link -image edit.gif -alt Edit cmd edit.script script_id $row(script_id) rule_id $rule_id]
    }
}

ossweb::conn::callback rule_list {} {

    set rules:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    ossweb::db::multirow rules sql:ossmon.action_rule.list -replace_null "&nbsp;" -eval {
      set row(rule_name) [ossweb::html::link -text $row(rule_name) cmd edit rule_id $row(rule_id)]
    }
}

ossweb::conn::callback create_form_rule {} {

    ossweb::widget form_rule.rule_id -type hidden -optional
    ossweb::widget form_rule.rule_name -type text -label "Rule Name"
    ossweb::widget form_rule.status -type select -label "Status" \
         -options { { Active Active } { Disabled Disabled } }
    ossweb::widget form_rule.mode -type select -label "Mode" \
         -options { { Before BEFORE } { After AFTER } { Final FINAL } }
    ossweb::widget form_rule.precedence -type text -label "Priority" -datatype integer
    ossweb::widget form_rule.back -type button -label "Back" -url [ossweb::html::url cmd view]
    ossweb::widget form_rule.update -type submit -name cmd -label "Update"
    ossweb::widget form_rule.delete -type submit -name cmd -label "Delete" \
                -html { onClick "return confirm('Are you sure?')" }
    ossweb::widget form_rule.refresh -type button -label "Refresh" \
         -url [ossweb::html::url cmd refresh]
    ossweb::widget form_rule.help -type helpbutton -url doc/manual.html#t48

    ossweb::widget form_match.rule_id -type hidden
    ossweb::widget form_match.match_id -type hidden -optional
    ossweb::widget form_match.ctx -type hidden -value match -freeze
    ossweb::widget form_match.name -type text -label Name \
         -resize
    ossweb::widget form_match.operator -type select -label Name \
         -options [ossmon::property operators]
    ossweb::widget form_match.value -type text -label Value \
         -resize
    ossweb::widget form_match.mode -type select -label Mode \
         -options { { AND AND } { OR OR } { "NOT AND" "NOT AND" } { "NOT OR" "NOT OR" } }
    ossweb::widget form_match.cmd -type submit -label Add

    ossweb::widget form_script.rule_id -type hidden
    ossweb::widget form_script.script_id -type hidden -optional
    ossweb::widget form_script.ctx -type hidden -value script -freeze
    ossweb::widget form_script.value -type textarea -label Script \
         -html { cols 50 rows 5 wrap off } \
         -resize
    ossweb::widget form_script.func -type select -label Functions \
         -empty -- \
         -optional \
         -html { onChange "this.form.value.value+='ossmon::object $name -set '+this.options[this.selectedIndex].value+' '" } \
         -options { { ossmon:type ossmon:type }
                    { obj:rowcount rowcount }
                    { obj:type obj:type }
                    { obj:name obj:name }
                    { obj:host obj:host }
                    { obj:type obj:type }
                    { parent:id parent:id }
                    { parent:name parent:name }
                    { ossmon:columns ossmon:columns }
                    { ossmon:status ossmon:status }
                    { device:id device:id }
                    { device:id device:id }
                    { device:name device:name }
                    { device:type device:type }
                    { device:description device:description }
                    { location:id location:id }
                    { location:name location:name }
                    { template:id template:id }
                    { alert:type alert:type }
                    { alert:name alert:name }
                    { alert:status alert:status }
                    { ossmon:alert:threshold ossmon:alert:threshold }
                    { ossmon:alert:interval ossmon:alert:interval } }
    ossweb::widget form_script.cmd -type submit -label Add
}

# Table/form columns
set columns { rule_id int ""
              rule_name "" ""
              script_id int ""
              match_id int ""
              status "" "Active"
              precedence int 0
              mode "" ""
              rule_link var "" }

# Process request parameters takes columns and form name and calls the function to create the form
ossweb::conn::process -columns $columns \
           -forms { form_rule form_match form_script } \
           -eval {
             add -
             update {
              -exec {
                 switch ${ossweb:ctx} {
                   match { match_action }
                   script { script_action }
                   default { rule_action }
                 }
              }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             delete {
              -exec {
                 switch ${ossweb:ctx} {
                   match {
                      match_action
                      ossweb::conn::next -cmd_name edit -ctx_name view
                   }
                   script {
                      script_action
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
               -exec { ossmon::action::refresh }
               -on_error { -cmd_name view }
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
