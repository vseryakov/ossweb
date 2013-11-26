# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001


ossweb::conn::callback category_action {} {

    switch ${ossweb:cmd} {

      update {
         if { $category_id == "" } {
           if { [ossweb::db::exec sql:ossweb.category.create] } {
             error "OSSWEB: Operation failed"
           }
         } else {
           if { [ossweb::db::exec sql:ossweb.category.update] } {
             error "OSSWEB: Operation failed"
           }
         }
         ossweb::conn::set_msg "Record updated"
      }

      delete {
         if { [ossweb::db::exec sql:ossweb.category.delete] } {
           error "OSSWEB: Operation failed"
         }
         ossweb::conn::set_msg "Record deleted"
      }
    }
    ossweb::form form_category reset
}

ossweb::conn::callback category_edit {} {

    if { $category_id > 0 } {
      if { [ossweb::db::multivalue sql:ossweb.category.read] } {
        error "OSSWEB: Record not found"
      }
      if { $color != "" } {
        ossweb::widget form_category.color -info "<DIV STYLE=\"width:10;height:10;background-color:$color;\"></DIV>"
      }
      if { $bgcolor != "" } {
        ossweb::widget form_category.bgcolor -info "<DIV STYLE=\"width:10;height:10;background-color:$bgcolor;\"></DIV>"
      }
    }
    ossweb::form form_category set_values
}

ossweb::conn::callback category_list {} {

    ossweb::db::multirow categories sql:ossweb.category.list -eval {
      if { [ossweb::lookup::row url -id user_id -script t] } {
        set row(url) [ossweb::lookup::url cmd edit category_id $row(category_id)]
      }
      set level [expr [llength [split $row(tree_path) /]] - 3]
      set row(category_name) "[string repeat "&nbsp;&nbsp;&nbsp;" $level] $row(category_name)"
      if { $row(color) != "" } {
        set row(category_name) "<FONT COLOR=$row(color)>$row(category_name)</FONT>"
      }
    }
    # Convert form into search filter
    ossweb::widget form_category.module -type select \
         -empty -- \
         -sql_cache CATEGORY:MODULES \
         -sql sql:ossweb.category.select.module
    ossweb::widget form_category.search -type submit -name cmd -label Search
    ossweb::widget form_category.reset -type reset -label Reset -clear
    ossweb::widget form_category.add -type button -label Add \
         -url [ossweb::lookup::link -image add.gif -alt Add cmd edit]
}

ossweb::conn::callback create_form_category {} {

    ossweb::lookup::form form_category
    ossweb::form form_category -title "Category Details"
    ossweb::widget form_category.category_id -type hidden -optional
    ossweb::widget form_category.module -type text -label Module
    ossweb::widget form_category.category_name -type text -label Name \
         -html { size 20 }
    ossweb::widget form_category.category_parent -type lookup -label Parent \
         -mode 2 \
         -title_name parent_name \
         -url [ossweb::html::url cmd view] \
         -map { form_category.category_parent category_id form_category.parent_name category_name } \
         -optional
    ossweb::widget form_category.description -type textarea -label Description \
         -html { rows 5 cols 50} \
         -optional
    ossweb::widget form_category.sort -type text -label Sort \
         -html { size 5 } \
         -optional
    ossweb::widget form_category.color -type colorselect -label Color \
         -html { size 7 } \
         -optional
    ossweb::widget form_category.bgcolor -type colorselect -label "Background Color" \
         -html { size 7 } \
         -optional
    ossweb::widget form_category.back -type button -label Back \
         -url [ossweb::html::url cmd view]
    ossweb::widget form_category.update -type submit -name cmd -label Update
    ossweb::widget form_category.delete -type button -label Delete \
         -eval { if { $category_id <= 0 } { return } } \
         -confirm "confirm('Record will be deleted, continue?')" \
         -url [ossweb::html::url cmd delete category_id $category_id]

    if { ${ossweb:cmd} == "search" } {
      ossweb::form form_category optional
    }
}

# Table/form columns
set columns { category_id int ""
              category_name "" ""
              color "" ""
              bgcolor "" ""
              module name ""
              description "" "" }

# Process request parameters
ossweb::conn::process -columns $columns \
                   -forms form_category \
                   -on_error { index.index } \
                   -eval {
                      update -
                      delete {
                         -exec { category_action }
                         -next { -cmd_name view }
                         -on_error { -cmd_name edit }
                      }
                      edit {
                         -exec { category_edit }
                         -on_error { -cmd_name view }
                      }
                      default {
                         -exec { category_list }
                      }
                   }
