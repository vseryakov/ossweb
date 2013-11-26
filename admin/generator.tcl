# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2006

proc showColumns { table_name { table_skip "" } } {

    if { $table_name != "" } {
      append data "$table_name columns:"
      append data "<UL>"
      foreach column [ossweb::db::multilist sql:ossweb.db.table.column.types] {
        foreach { cname ctype } $column {}
        if { [lsearch -exact $table_skip $cname] > -1 } { continue }
        set link [ossweb::html::link -image minus.gif -url "javascript:;" -onClick "crm('$cname')" -align absbottom -title "Remove column"]
        append data "<LI ID=$cname> $cname $ctype $link"
      }
      append data "</UL>"
      return $data
    }
}

proc showBorder { border_style } {

    if { $border_style != "" } {
      append data "<border style=$border_style title=Test>"
      append data "<TR><TD>Column1</TD><TD>Column2</TD></TR>"
      append data "<TR><TD>Column1</TD><TD>Column2</TD></TR>"
      append data "</border>"
      return [ossweb::adp::Evaluate $data]
    }
}

proc showFormtab { formtab_style } {

    if { $formtab_style != "" } {
      ossweb::widget form_tab1.adp -type link -label Edit
      ossweb::widget form_tab1.tcl -type link -label Details
      append data "<formtab id=form_tab1 style=$formtab_style>"
      return [ossweb::adp::Evaluate $data [expr [info level] - 1]]
    }
}

# Convert types into SQL filter format
proc convertToFilter { columns } {

    set sql ""
    foreach column $columns {
      foreach { cname ctype } $column {}
      switch -regexp -- $ctype {
       bool { set ctype boolean }
       int { set ctype int }
       numeric - float { set ctype double }
       timestamp { set ctype datetime }
       time { set ctype time }
       date { set ctype date }
       default { set ctype {} }
      }
      lappend sql [list $cname $ctype ""]
    }
    return $sql
}

# Convert types into form widget format
proc convertToForm { columns primary_key primary_key_type } {

    set form ""
    foreach column $columns {
      set cparams ""
      foreach { cname ctype } $column {}
      switch -regexp -- $ctype {
       bool { set ctype boolean }
       date - timestamp {
         set ctype date
         set cparams -calendar
       }
       time { set ctype {date -format  {HH24 : MI}} }
       default {
         set ctype text
         set cparams "-size 50"
         if { [regexp -nocase description $cname] } {
           set ctype textarea
           set cparams "-cols 50 -rows 2 -resize"
         }
       }
      }
      if { $cname == $primary_key && $primary_key_type == "int" } {
        set ctype hidden
      }
      lappend form $cname [ossweb::util::totitle $cname] $ctype $cparams
    }
    return $form
}

ossweb::conn::callback show {} {

    set data ""
    switch -- ${ossweb:ctx} {
     columns {
        set data [showColumns $table_name $table_skip]
     }

     border {
        set data [showBorder $border_style]
     }

     formtab {
        set data [showFormtab $formtab_style]
     }
    }
    ossweb::conn::response $data
}

ossweb::conn::callback build {} {

    set columns ""
    set sql_columns ""
    set form_columns ""
    set column_types ""

    foreach cname [ossweb::db::multilist sql:ossweb.db.table.columns] {
      if { [lsearch -exact $table_skip $cname] == -1 } {
        lappend columns $cname
      }
    }
    foreach column [ossweb::db::multilist sql:ossweb.db.table.column.types] {
      if { [lsearch -exact $table_skip [lindex $column 0]] == -1 } {
        lappend column_types $column
      }
    }
    set indexes [ossweb::db::multilist sql:ossweb.db.table.indexes]
    set primary_key [lindex $columns 0]
    set primary_key_type int
    # Determine primary key
    foreach index $indexes {
      foreach { idxname idxdef } $index {}
      if { [regexp -nocase {UNIQUE INDEX} $idxdef] &&
           [regexp -nocase {_pkey$|_pk$} $idxname] } {
        regexp {\((.+)\)} $idxdef d primary_key
      }
    }

    # Determine primary key type
    foreach col $column_types {
      foreach { cname ctype } $col {}
      if { $cname == $primary_key } {
        set primary_key_type $ctype
        break
      }
    }

    set sql_columns [convertToFilter $column_types]
    set form_columns [convertToForm $column_types $primary_key $primary_key_type]

    # Dependent table
    set column_types ""
    set columns_depend ""
    set sql_columns_depend ""
    set form_columns_depend ""
    set primary_key_depend ""

    if { $table_depend != "" } {
      foreach cname [ossweb::db::multilist sql:ossweb.db.table.columns -vars "table_name $table_depend"] {
        if { [lsearch -exact $table_depend_skip $cname] == -1 } {
          lappend columns_depend $cname
        }
      }
      foreach column [ossweb::db::multilist sql:ossweb.db.table.column.types -vars "table_name $table_depend"] {
        if { [lsearch -exact $table_depend_skip [lindex $column 0]] == -1 } {
          lappend column_types $column
        }
      }
      set indexes [ossweb::db::multilist sql:ossweb.db.table.indexes -vars "table_name $table_depend"]
      set primary_key_depend [lindex $columns_depend 0]
      set primary_key_depend_type int
      # Determine primary key
      foreach index $indexes {
        foreach { idxname idxdef } $index {}
        if { [regexp -nocase {UNIQUE INDEX} $idxdef] && [regexp -nocase {_pkey$|_pk$} $idxname] } {
          regexp {\((.+)\)} $idxdef d primary_key_depend
        }
      }

      # Determine primary key type
      foreach col $columns_depend {
        foreach { cname ctype } $col {}
        if { $cname == $primary_key_depend } {
          set primary_key_depend_type $ctype
          break
        }
      }
      set sql_columns_depend [convertToFilter $column_types]
      set form_columns_depend [convertToForm $column_types $primary_key $primary_key_depend_type]
    }

    append adp "
    <if @ossweb:cmd@ eq error>
       <ossweb:msg>
       <return>
    </if>

    <master mode=lookup>

    <if @ossweb:cmd@ eq edit>
    "

    if { $formtab_style != "" } {
      append adp "
       <if @$primary_key@ ne \"\">
         <DIV ALIGN=RIGHT><formtab id=form_tab style=$formtab_style width=20%></DIV>
       </if>
       "
    }

    append adp "
       <formtemplate id=form_$table_name></formtemplate>
       "

    if { $table_depend != "" } {

    if { $formtab_style != "" } {
      append adp "
       <if @tab@ eq details>
       "
    }

    append adp "
          <ossweb:title>[ossweb::util::totitle $table_depend]</ossweb:title>

          <border style=[ossweb::nvl $border_style curved4]>
          <rowfirst>"

    foreach column $columns_depend {
      append adp "
          <TH>[ossweb::util::totitle $column]</TH>"
    }


    append adp "
          </rowfirst>

          <multirow name=children>
          <row type=plain underline=1 VALIGN=TOP>"

    foreach column $columns_depend {
      append adp "
            <TD>@children.$column@</TD>"
    }

    append adp "
          </row>
          </multirow>
          </border>
          "

    if { $formtab_style != "" } {
      append adp "
       </if>"
    }

    }

    append adp "
       <return>
    </if>

    <ossweb:title>[ossweb::util::totitle $table_name]</ossweb:title>
    <BR>
    "

    if { $filter_flag == 1 } {
      set cols [expr [llength $form_columns]/4]
      if { $cols > 4 } {
        set cols 4
      }
      append adp "
    <formtemplate id=form_filter style=horizontal columns=$cols horiz_buttons=1></formtemplate>
      "
    } else {
      append adp "

    <DIV ALIGN=RIGHT><ossweb:link -text {Create new record} -class osswebSmallText cmd edit></DIV>
    "

    }

    append adp "
    <multipage name=records>
    <border [ossweb::decode $border_style "" "" "style=$border_style"]>
    <rowfirst>"

    foreach column $columns {
      append adp "
      <TH>[ossweb::util::totitle $column]</TH>"
    }

    append adp "
    </rowfirst>

    <multirow name=records>
    <row>"

    foreach column $columns {
      append adp "
       <TD>@records.$column@</TD>"
    }

    append adp "
    </row>
    </multirow>
    </border>

    <multipage name=records>
    "

    append tcl "
    #
    # Author [ossweb::conn full_name] [ossweb::conn user_email]
    # [ns_fmttime [ns_time] "%B %Y"]
    #

    ossweb::conn::callback delete {} {
    "
    if { $xql_flag  == 1 } {
      append tcl "
        if { \[ossweb::db::exec sql:$table_name.delete\] } {
          error \"OSSWEB: Unable to delete record\"
        }"
    } else {
      append tcl "
        if { \[ossweb::db::delete $table_name $primary_key \$$primary_key\] } {
          error \"OSSWEB: Unable to delete record\"
        }"
    }

    append tcl "
        ossweb::conn::set_msg \"Record has been deleted\"
        ossweb::conn::next cmd view
    }

    ossweb::conn::callback update {} {

        if { \$$primary_key == \"\" } {
        "
    if { $xql_flag == 1 } {
      append tcl "
           if { \[ossweb::db::exec sql:$table_name.create\] } {
             error \"OSSWEB: Unable to create record\"
           }"
    } else {
      append tcl "
           if { \[ossweb::db::insert $table_name\] } {
             error \"OSSWEB: Unable to create record\"
           }"
    }

    if { $primary_key_type == "int" } {
      append tcl "
           # Get newly created id from the sequence, CHECK FOR SEQUENCE NAME
           set $primary_key \[ossweb::db::currval $table_name\]
           "
    }
    append tcl "
           ossweb::conn::set_msg \"Record has been created\"
        } else {
        "

    if { $xql_flag == 1 } {
      append tcl "
           if { \[ossweb::db::exec sql:$table_name.update\] } {
             error \"OSSWEB: Unable to update record\"
           }"
    } else {
      append tcl "
           if { \[ossweb::db::update $table_name $primary_key \$$primary_key\] } {
             error \"OSSWEB: Unable to create record\"
           }"
    }

    append tcl "
           ossweb::conn::set_msg \"Record has been updated\"
        }
        ossweb::conn::next cmd view
    }

    ossweb::conn::callback edit {} {

        # Raise error if we cannot read record by primary key"

    if { $xql_flag == 1 } {
      append tcl "
        if { \$$primary_key != \"\" && \[ossweb::db::multivalue sql:$table_name.read\] } {
          error \"OSSWEB: Unable to read record\"
        }"
    } else {
      append tcl "
        if { \$$primary_key != \"\" && \[ossweb::db::read $table_name $primary_key \$$primary_key\] } {
          error \"OSSWEB: Unable to read record\"
        }"
    }

    if { $formtab_style != "" } {
      append tcl "
        switch -- \$tab {
         details {
            # Make form widgets readonly
            ossweb::form form_$table_name readonly -skip {back}"

    if { $table_depend != "" } {
      append tcl "
            # Retrieve all children records"

      if { $xql_flag == 1 } {
        append tcl "
            ossweb::db::multirow children sql:$table_depend.list\n"
      } else {
        append tcl "
            ossweb::db::read $table_depend -type {multirow children} $primary_key \\$$primary_key\n"
      }
    }

    append tcl "
         }
        }
        "
    }

    append tcl "
        # Update form with values from Tcl variables
        ossweb::form form_$table_name set_values
    }

    ossweb::conn::callback view {
    "

    if { $xql_flag == 1 } {
      append tcl "
        switch \${ossweb:cmd} {
         search {
           # Save new filter settings
           ossweb::conn::set_property [string toupper $table_name]:FILTER {} -forms form_$table_name -global t
         }
        }

        # Read saved filter settings
        ossweb::conn::get_property [string toupper $table_name]:FILTER -skip { page } -columns t -global t

        # Update form fields with filter values
        ossweb::form form_$table_name set_values

        # Search for records using multipage dividor
        ossweb::db::multipage records \\
             sql:$table_name.search1 \\
             sql:$table_name.search2 \\
             -force \[ossweb::decode \${ossweb:cmd} search t f\] \\
             -page \$page \\
             -eval {
          set row($primary_key) \[ossweb::html::link -text \$row($primary_key) cmd edit $primary_key \$row($primary_key)\]
        }"
    } else {
      append tcl "
        ossweb::db::read $table_name -type \"multirow records\" -eval {
          set row($primary_key) \[ossweb::html::link -text \$row($primary_key) cmd edit $primary_key \$row($primary_key)\]
        }
      "
    }

    append tcl "
    }

    ossweb::conn::callback create_form_$table_name {} {

        ossweb::form form_$table_name -title \"[ossweb::util::totitle $table_name]\"
        "

    foreach { cname clabel ctype cparams } $form_columns {
      append tcl "
        ossweb::widget form_$table_name.$cname -type $ctype -label {$clabel} \\
             -optional \\
             $cparams
        "
    }

    append tcl "
        ossweb::widget form_$table_name.back -type button -label Back \\
             -url \[ossweb::html::url cmd view\]

        ossweb::widget form_$table_name.update -type submit -name cmd -label Update

        ossweb::widget form_$table_name.delete -type button -label Delete \\
             -eval { if { \$$primary_key == {} } { return } } \\
                -url \[ossweb::html::url cmd delete $primary_key \$$primary_key\]
    }"

    if { $filter_flag == 1 } {
      append tcl "

    ossweb::conn::callback create_form_filter {} {

        ossweb::form form_filter -title \"Search [ossweb::util::totitle $table_name]\"
        "

    foreach { cname clabel ctype cparams } $form_columns {
      append tcl "
        ossweb::widget form_filter.$cname -type $ctype -label {$clabel} \\
             -optional $cparams
        "
    }

    append tcl "
        ossweb::widget form_filter.cmd -type submit -label Search

        ossweb::widget form_filter.reset -type reset -label Reset \\
             -clear

        ossweb::widget form_filter.new -type button -label New \\
             -url \[ossweb::html::url cmd edit]
    }"

    }

    if { $formtab_style != "" } {
      append tcl "

    ossweb::conn::callback create_form_tab {} {

        set url \[ossweb::lookup::url cmd edit $primary_key \$$primary_key\]

        ossweb::widget form_tab.edit -type link -label Edit -url \$url

        ossweb::widget form_tab.details -type link -label Details -url \$url
    }"

    }

    set forms form_$table_name
    if { $formtab_style != "" } {
      lappend forms form_tab
    }
    if { $filter_flag != "" } {
      lappend forms form_filter
    }

    append tcl "

    set columns { $primary_key $primary_key_type \"\"
                  page int 1 [ossweb::decode $formtab_style "" "" "\n                  tab \"\" \"\""] }

    ossweb::conn::process \\
            -columns \$columns \\
            -forms { $forms } \\
            -on_error { cmd view } \\
            -default view"

    append xql "
    <xql>

    <query name=\"$table_name.list\">
      <description>
        List of all records
      </description>
      <sql>
        SELECT [join $columns ",\n[string repeat { } 15]"]
        FROM $table_name
        ORDER BY $primary_key
      </sql>
    </query>

    <query name=\"$table_name.search1\">
      <description>
        List of all records
      </description>
      <sql>
        SELECT $primary_key
        FROM $table_name
        \[ossweb::sql::filter \\
               { [join $sql_columns "\n[string repeat { } 17]"]  } \\
               -where WHERE \]
        ORDER BY $primary_key
      </sql>
    </query>

    <query name=\"$table_name.search2\">
      <description>
        List of all records
      </description>
      <sql>
        SELECT [join $columns ",\n[string repeat { } 15]"]
        FROM $table_name
        WHERE $primary_key IN (CURRENT_PAGE_SET)
      </sql>
    </query>

    <query name=\"$table_name.read\">
      <description>
        Read record details
      </description>
      <sql>
        SELECT [join $columns ",\n[string repeat { } 15]"]
        FROM $table_name
        WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
      </sql>
    </query>

    <query name=\"$table_name.create\">
      <description>
        Create new record
      </description>
      <sql>
        INSERT INTO $table_name
        \[ossweb::sql::insert_values -full t \\
               { [join $sql_columns "\n[string repeat { } 17]"] } \]
      </sql>
    </query>

    <query name=\"$table_name.update\">
      <description>
        Update existing record
      </description>
      <sql>
        UPDATE $table_name
        SET \[ossweb::sql::update_values \\
                   { [join $sql_columns "\n[string repeat { } 21]"] } \]
        WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
      </sql>
    </query>

    <query name=\"$table_name.delete\">
      <description>
        Delete record
      </description>
      <sql>
        DELETE FROM $table_name WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
      </sql>
    </query>

    <query name=\"$table_name.copy\">
      <description>
        Copy the record
      </description>
      <sql>
        INSERT INTO $table_name ([join $columns ,])
        SELECT \$new_$primary_key,[join [string map "{$primary_key} {}" $columns] ,]
        FROM $table_name
        WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
      </sql>
    </query>
    "

    if { $table_depend != "" } {
      append xql "
    <query name=\"$table_depend.list\">
      <description>
        Children records
      </description>
      <sql>
        SELECT [join $columns_depend ",\n[string repeat { } 15]"]
        FROM $table_depend
        WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
        ORDER BY 1
      </sql>
    </query>

    <query name=\"$table_depend.read\">
      <description>
        Read record details
      </description>
      <sql>
        SELECT [join $columns_depend ",\n[string repeat { } 15]"]
        FROM $table_depend
        WHERE $primary_key_depend=\[ossweb::sql::quote \$$primary_key_depend $primary_key_type_depend\]
      </sql>
    </query>

    <query name=\"$table_depend.create\">
      <description>
        Create new record
      </description>
      <sql>
        INSERT INTO $table_depend
        \[ossweb::sql::insert_values -full t \\
               { [join $sql_columns_depend "\n[string repeat { } 17]"] } \]
      </sql>
    </query>

    <query name=\"$table_depend.update\">
      <description>
        Update existing record
      </description>
      <sql>
        UPDATE $table_depend
        SET \[ossweb::sql::update_values \\
                   { [join $sql_columns_depend "\n[string repeat { } 21]"] } \]
        WHERE $primary_key_depend=\[ossweb::sql::quote \$$primary_key_depend $primary_key_type_depend\]
      </sql>
    </query>

    <query name=\"$table_depend.delete\">
      <description>
        Delete record
      </description>
      <sql>
        DELETE FROM $table_depend WHERE $primary_key_depend=\[ossweb::sql::quote \$$primary_key_depend $primary_key_type_depend\]
      </sql>
    </query>

    <query name=\"$table_depend.delete.all\">
      <description>
        Delete record
      </description>
      <sql>
        DELETE FROM $table_depend WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
      </sql>
    </query>

    <query name=\"$table_depend.copy\">
      <description>
        Copy the record
      </description>
      <sql>
        INSERT INTO $table_depend ([join [string map "{$primary_key_depend} {}" $columns_depend] ,])
        SELECT [join [string map "{$primary_key} \"\$new_$primary_key\" {$primary_key_depend} {}" $columns_depend] ,]
        FROM $table_depend
        WHERE $primary_key=\[ossweb::sql::quote \$$primary_key $primary_key_type\]
      </sql>
    </query>"
    }

    append xql "

    </xql>
    "
}

ossweb::conn::callback generate {} {

    set app_name [ossweb::nvl $app_name $table_name]
    set page_name [ossweb::nvl $page_name $table_name]

    set path [ns_info pageroot]/[ossweb::conn project_name]/$app_name
    if { [catch { file mkdir $path } errmsg] } {
      error "OSSWEB: $errmsg"
    }

    build

    set data ""
    foreach line [split $adp "\n"] { append data "[string range $line 4 end]\n" }
    ossweb::write_file $path/$page_name.adp $data

    set data ""
    foreach line [split $tcl "\n"] { append data "[string range $line 4 end]\n" }
    ossweb::write_file $path/$page_name.tcl $data

    set xql ""
    if { $xql_flag } {
      set data ""
      foreach line [split $xql "\n"] { append data "[string range $line 4 end]\n" }
      ossweb::write_file [ns_info home]/xql/$page_name.xql $data
      set xql "[ns_info home]/xql/$page_name.xql, [file size [ns_info home]/xql/$page_name.xql] bytes"
    }

    set adp "$path/$page_name.adp, [file size $path/$page_name.adp] bytes"
    set tcl "$path/$page_name.tcl, [file size $path/$page_name.tcl] bytes"
    set link /[ossweb::conn project_name]/$app_name/$page_name.oss
}

ossweb::conn::callback preview {} {

    build

    set adp [string trim [string map { < {&lt;} > {&gt;} } $adp]]
    set tcl [string trim [string map { < {&lt;} > {&gt;} } $tcl]]
    set xql [string trim [string map { "{}" {""} < {&lt;} > {&gt;} } $xql]]

    set preview_table [showColumns $table_name $table_skip]
    set preview_depend [showColumns $table_depend $table_depend_skip]
    set preview_border [showBorder $border_style]
    set preview_formtab [showFormtab $formtab_style]
}

ossweb::conn::callback view {} {

}

ossweb::conn::callback create_form_generator {} {

    ossweb::form form_generator -title "Code Generator"

    ossweb::widget form_generator.table_skip -type hidden \
         -optional

    ossweb::widget form_generator.table_depend_skip -type hidden \
         -optional

    ossweb::widget form_generator.app_name -type text -label "Application Name" \
         -optional

    ossweb::widget form_generator.page_name -type text -label "Page Name" \
         -optional

    ossweb::widget form_generator.table_name -type select -label "Main Table" \
         -empty -- \
         -sql sql:ossweb.db.table.list \
         -sql_cache TABLES:CACHE \
         -popup \
         -popuptext " " \
         -popupname PreviewTable \
         -onClick:after "this.form.table_skip.value=''" \
         -urlargs this.value+'&table_skip='+this.form.table_skip.value \
         -url [ossweb::html::url cmd show.columns table_name ""]

    ossweb::widget form_generator.table_depend -type select -label "Children Table" \
         -optional \
         -empty -- \
         -sql sql:ossweb.db.table.list \
         -sql_cache TABLES:CACHE \
         -popup \
         -popuptext " " \
         -popupname PreviewDepend \
         -onClick:after "this.form.table_depend_skip.value=''" \
         -urlargs this.value+'&table_depend_skip='+this.form.table_depend_skip.value \
         -url [ossweb::html::url cmd show.columns table_name ""]

    ossweb::widget form_generator.border_style -type radio -label "Border Style" \
         -optional \
         -separator /img/misc/brightpixel.gif \
         -horizontal \
         -horizontal_cols 4 \
         -options { {None ""} {Class class} {Div div} {Shadow shadow} {Curved curved}
                    {Curved2 curved2} {Curved3 curved3} {Curved4 curved4} {Curved5 curved5}
                    {Curved6 curved6} {White white} {Gray gray} {Table table} {Fieldset fieldset} } \
         -popup \
         -popuptext " " \
         -popupname PreviewBorder \
         -urlargs this.value \
         -url [ossweb::html::url cmd show.border border_style ""]

    ossweb::widget form_generator.formtab_style -type radio -label "Form Tab Style" \
         -optional \
         -horizontal \
         -options { {None ""} {Oval oval} {Oval2 oval2} {Blue blue} {Square square}
                    {Text text} {Ebay ebay} } \
         -popup \
         -popuptext " " \
         -popupname PreviewFormtab \
         -urlargs this.value \
         -url [ossweb::html::url cmd show.formtab formtab_style ""]

    ossweb::widget form_generator.filter_flag -type checkbox -label "&nbsp;" \
         -optional \
         -separator /img/misc/brightpixel.gif \
         -options { {"Generate Filter Form" 1 } }

    ossweb::widget form_generator.files_flag -type checkbox -label "&nbsp;" \
         -optional \
         -options { {"Create Files in the application directory" 1 } }

    ossweb::widget form_generator.xql_flag -type checkbox -label "&nbsp;" \
         -optional \
         -options { {"Generate all SQL statements in the .xql file" 1 } }

    ossweb::widget form_generator.preview -type submit -name cmd -label Preview \
         -help "Preview generated code"

    ossweb::widget form_generator.generate -type submit -name cmd -label Generate \
         -help "Create application files"
}

ossweb::conn::callback create_form_tab {} {

    ossweb::widget form_tab.adp -type link -label ADP -url "javascript:;" -onClick "varSet('Code', varGet('ADP'))"
    ossweb::widget form_tab.tcl -type link -label Tcl -url "javascript:;" -onClick "varSet('Code', varGet('Tcl'))"
    ossweb::widget form_tab.xql -type link -label XQL -url "javascript:;" -onClick "varSet('Code', varGet('XQL'))"
}

set columns { app_name "" ""
              page_name "" ""
              table_name "" ""
              table_depend "" ""
              table_skip "" ""
              table_depend_skip "" ""
              formtab_style "" ""
              border_style "" ""
              files_flag int 0
              filter_flag int 0
              xql_flag int 0
              preview_table const ""
              preview_depend const ""
              preview_border const ""
              preview_formtab const "" }

ossweb::conn::process \
           -debug t \
           -columns $columns \
           -forms { form_tab form_generator }

