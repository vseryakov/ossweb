# Author Vlad Seryakov : vlad@crystalballinc.com
# October 2001

ossweb::conn::callback template_refresh { } {

    ossmon::template::flush
    ossweb::conn::set_msg "Templates have been refreshed"
}

ossweb::conn::callback template_update { } {

    if { $template_id != "" } {
      if { [ossweb::db::exec sql:ossmon.template.update] } {
        error "OSS: Could not update template record"
      }
    } else {
      if { [ossweb::db::exec sql:ossmon.template.create] } {
        error "OSS: Could not update template record"
      }
    }
    ossweb::conn::set_msg "The record has been updated, click on [ossweb::html::image refresh.gif] or Refresh button to refresh rules local cache"
}

ossweb::conn::callback template_delete {} {

    if { [ossweb::db::exec sql:ossmon.template.delete] } {
       error "OSS: Could not delete the record"
    }
    ossweb::conn::set_msg "The record has been deleted, click on [ossweb::html::image refresh.gif] or Refresh button to refresh rules local cache"
}

ossweb::conn::callback template_copy {} {

    set old_template_id $template_id
    set template_id [ossweb::db::nextval ossmon_util]
    if { [ossweb::db::exec sql:ossmon.template.copy] } {
       set template_id $old_template_id
       error "OSS: Could not copy the record"
    }
    ossweb::conn::set_msg "The template has been copied"
}

ossweb::conn::callback template_edit { } {

    if { $template_id != "" && [ossweb::db::multivalue sql:ossmon.template.read] } {
      error "OSS: Invalid template id received by the system"
    }
    ossweb::db::multirow rules sql:ossmon.alert_rule.template_list -eval {
      set row(rule_name) [ossweb::html::link -text $row(rule_name) alertrules cmd edit rule_id $row(rule_id)]
    }
    ossweb::form form_template set_values
}

ossweb::conn::callback template_list {} {

    set templates:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    set templates:refresh [ossweb::html::link -image refresh.gif -alt Refresh cmd refresh]
    ossweb::db::multirow templates sql:ossmon.template.list -eval {
      set row(template_name) [ossweb::html::link -text $row(template_name) cmd edit template_id $row(template_id)]
      set row(template_actions) [ns_quotehtml $row(template_actions)]
    }
}

ossweb::conn::callback create_form_template {} {

    ossweb::widget form_template.template_id -type hidden -optional
    ossweb::widget form_template.template_name -type text -label "Template Name"
    ossweb::widget form_template.template_actions -type textarea -label "Template Actions" \
         -html { cols 80 rows 15 wrap off } \
         -resize
    ossweb::widget form_template.back -type button -label "Back" -url [ossweb::html::url cmd view]
    ossweb::widget form_template.update -type submit -name "cmd" -label "Update"
    ossweb::widget form_template.delete -type submit -name "cmd" -label "Delete" \
         -html { onClick "return confirm('Are you sure?');" } \
         -eval { if { $template_id == "" } { return } }
    ossweb::widget form_template.copy -type submit -name "cmd" -label "Copy" \
         -html { onClick "return confirm('Copy template?');" } \
         -eval { if { $template_id == "" } { return } }
    ossweb::widget form_template.help -type helpbutton -url doc/manual.html#t46
}

ossweb::conn::process -columns { template_id "" "" } \
           -forms { form_template } \
           -eval {
             refresh {
              -exec { template_refresh }
              -on_error { -cmd_name default }
              -next { -cmd_name default }
             }
             delete {
              -exec { template_delete }
              -on_error { -cmd_name edit }
              -next { -cmd_name default }
             }
             copy {
              -exec { template_copy }
              -on_error { -cmd_name edit }
              -next { -cmd_name edit }
             }
             update {
              -exec { template_update }
              -on_error { -cmd_name edit }
              -next { -cmd_name default }
             }
             edit {
              -exec { template_edit }
              -on_error { -cmd_name default }
             }
             default {
              -exec { template_list }
              -on_error { -cmd_name default index }
             }
           }
