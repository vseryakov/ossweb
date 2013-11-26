# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001


ossweb::conn::callback projects_action {} {

    switch -exact ${ossweb:cmd} {

     update {
       set count 0
       if { ${project_id:old} != "" } {
         if { [ossweb::db::update ossweb_projects project_id ${project_id:old}] } {
           error "OSS: Operation failed"
         }
         set count [ossweb::db::rowcount]
       }
       if { !$count && [ossweb::db::insert ossweb_projects] } {
         error "OSS: Operation failed"
       }
       # Replace index.adp is permissions allow
       if { $index_style != "" } {
         set path [ns_info pageroot]/[ossweb::conn project_name]/index
         if { [file exists $path/$index_style] } {
           file delete $path/index.adp
           file link -symbolic $path/index.adp $path/$index_style
         }
       }
       ossweb::conn::set_msg "Project updated"
     }

     delete {
       ossweb::db::begin
       if { [ossweb::db::delete ossweb_projects project_id $project_id] } {
         error "OSS: operation failed"
       }
       ossweb::db::commit
       ossweb::conn::set_msg "Record deleted"
     }
    }
    # Refresh project cache
    ossweb::cache flush ossweb:projects
}

# Application list
ossweb::conn::callback projects_list {} {

    set project_id ""
    set projects:add [ossweb::html::link -image add.gif -alt Add cmd edit]
    ossweb::db::read ossweb_projects -type "multirow projects" -eval {
      set row(project_logo) [ossweb::html::image $row(project_logo) -width "" -height ""]
      set row(project_name) [ossweb::html::link -text $row(project_name) cmd edit project_id $row(project_id)]
    }
}

ossweb::conn::callback projects_edit {} {

    if { $project_id != "" } {
      if { ![ossweb::db::read ossweb_projects project_id $project_id] } {
        set project_id:old $project_id
      }
    }
    ossweb::form form_project set_values
}

ossweb::conn::callback create_form_project {} {

    set index_styles [list]
    foreach file [glob -nocomplain [ns_info pageroot]/[ossweb::conn project_name]/index/index.menu.*.adp] {
      set file [file tail $file]
      set name [string range $file 11 end-4]
      lappend index_styles [list $name $file]
    }

    ossweb::widget form_project.project_id -type text -label "Project ID" \
         -old

    ossweb::widget form_project.project_name -type text -label "Name"

    ossweb::widget form_project.project_url -type text -label "Web Site URL" \
         -optional \
         -size 60 \
         -datatype url

    ossweb::widget form_project.project_info -type textarea -label "Info" \
         -optional

    ossweb::widget form_project.project_footer -type text -label "Project Footer" \
         -optional

    ossweb::widget form_project.project_logo -type imageselect -label "Logo Image" \
         -show \
         -optional

    ossweb::widget form_project.project_logo_bg -type imageselect -label "Logo Background Image" \
         -optional \
         -show \
         -width 100 \
         -height 40

    ossweb::widget form_project.project_bg -type imageselect -label "Page Background Image" \
         -optional \
         -show \
         -width 100 \
         -height 40

    ossweb::widget form_project.project_style -type text -label "Stylesheet Name" \
         -optional \

    ossweb::widget form_project.index_style -type select -label "Menu Style" \
         -optional \
         -empty -- \
         -options $index_styles

    ossweb::widget form_project.login_url -type text -label "Login URL" \
         -optional \
         -size 60

    ossweb::widget form_project.error_url -type text -label "Error URL" \
         -optional \
         -size 60

    ossweb::widget form_project.description -type textarea -label Description \
         -html { rows 5 cols 50 } \
         -empty -- \
         -optional

    ossweb::widget form_project.back -type button -label Back \
         -url "cmd view"

    ossweb::widget form_project.update -type submit -name cmd -label Update

    ossweb::widget form_project.delete -type submit -name cmd -label Delete \
         -eval { if { $project_id == "" } return } \
         -confirmtext "Record will be deleted, continue?"
}

# Table/form columns
set columns { project_id "" ""
              index_style "" ""
              project_id:old "" "" }

# Process request parameters
ossweb::conn::process -columns $columns \
           -forms { form_project } \
           -on_error { -cmd_name view } \
           -eval {
            refresh -
            update -
            add -
            remove {
              -exec { projects_action }
              -next { -cmd_name edit }
            }
            delete {
              -exec { projects_action }
              -next { -cmd_name view }
            }
            edit {
              -exec { projects_edit }
            }
            default {
              -exec { projects_list }
              -on_error { index.index }
            }
           }
