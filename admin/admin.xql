<?xml version="1.0"?>

<xql>

<query name="ossweb.admin.apps.move_up">
  <description>
    Move the given app up
  </description>
  <sql>
    SELECT ossweb_app_move($app_id,TRUE)
  </sql>
</query>

<query name="ossweb.admin.apps.move_down">
  <description>
    Move the specified app down
  </description>
  <sql>
    SELECT ossweb_app_move($app_id,FALSE)
  </sql>
</query>

<query name="ossweb.admin.apps.copy">
  <description>
  </description>
  <sql>
    INSERT INTO ossweb_apps (title,project_name,app_name,page_name,
                          url,image,path,target,group_id,condition,sort)
    SELECT title,project_name,app_name,page_name,
           url,image,path,target,group_id,condition,sort
    FROM ossweb_apps
    WHERE app_id=$app_id
  </sql>
</query>

<query name="ossweb.admin.apps.group_list">
  <description>
  </description>
  <sql>
    SELECT title[ossweb::decode $project_name "" "||' ('||project_name||')'" ""],
           app_id
    FROM ossweb_apps
    WHERE page_name IS NULL AND
          url IS NULL
          [ossweb::decode $project_name "" "" "AND project_name=[ossweb::sql::quote $project_name]"]
    ORDER BY tree_path
  </sql>
</query>

<query name="ossweb.admin.help.delete">
  <description>
    Delete help record
  </description>
  <sql>
    DELETE FROM ossweb_help WHERE help_id=$help_id
  </sql>
</query>

<query name="ossweb.admin.help.create">
  <description>
    Create new help record
  </description>
  <sql>
    INSERT INTO ossweb_help
    [ossweb::sql::insert_values -full t \
          { title "" ""
            text "" ""
            project_name "" "unknown"
            app_name "" "unknown"
            page_name "" "unknown"
            cmd_name "" "unknown"
            ctx_name "" "unknown" } ]
  </sql>
</query>

<query name="ossweb.admin.help.update">
  <description>
    Update help record
  </description>
  <sql>
    UPDATE ossweb_help
    SET [ossweb::sql::update_values \
              { help_id int ""
                title "" ""
                text "" ""
                project_name "" "unknown"
                app_name "" "unknown"
                page_name "" "unknown"
                cmd_name "" "unknown"
                ctx_name "" "unknown" } ]
    WHERE help_id=$help_id
  </sql>
</query>

<query name="ossweb.admin.help.read_all">
  <description>
    Read all help records
  </description>
  <sql>
    SELECT help_id,
           project_name,
           app_name,
           page_name,
           cmd_name,
           ctx_name,
           title,
           text
    FROM ossweb_help
    ORDER BY project_name,
             app_name,
             page_name,
             cmd_name,
             ctx_name
  </sql>
</query>

<query name="ossweb.admin.reftable.create">
  <description>
    Create reference table record
  </description>
  <sql>
    INSERT INTO $ref_table (${ref_object}_name,description [ossweb::decode $ref_precedence Y ",precedence" ""])
    VALUES([ossweb::sql::quote $name],
           [ossweb::sql::quote $description]
           [ossweb::decode $ref_precedence Y ",'$precedence'" ""])
  </sql>
</query>

<query name="ossweb.admin.reftable.update">
  <description>
    Update reference table record
  </description>
  <sql>
    UPDATE $ref_table
    SET ${ref_object}_name=[ossweb::sql::quote $name],
        description=[ossweb::sql::quote $description]
        [ossweb::decode $ref_precedence Y ",precedence='$precedence'" ""]
    WHERE ${ref_object}_id=$id
  </sql>
</query>

<query name="ossweb.admin.reftable.delete">
  <description>
    Delete reference table record
  </description>
  <sql>
    DELETE FROM $ref_table WHERE ${ref_object}_id=$id
  </sql>
</query>

<query name="ossweb.admin.reftable.read_all">
  <description>
    Read all reference table records
  </description>
  <sql>
    SELECT ${ref_object}_id AS id,
           ${ref_object}_name AS name,
           description
           [ossweb::decode $ref_precedence Y ",precedence" ""]
    FROM $ref_table
    ORDER BY [ossweb::decode $ref_precedence Y "precedence," ""]
             ${ref_object}_name
  </sql>
</query>

<query name="ossweb.admin.reftable.read">
  <description>
    Read one record from reference table
  </description>
  <sql>
    SELECT ${ref_object}_id AS id,
           ${ref_object}_name AS name,
           description
           [ossweb::decode $ref_precedence Y ",precedence" ""]
           [ossweb::decode $ref_extra_name "" "" ",$ref_extra_name"]
    FROM $ref_table
    WHERE ${ref_object}_id=$id
  </sql>
</query>

<query name="ossweb.admin.reftable2.create">
  <description>
    Create reference table record
  </description>
  <sql>
    INSERT INTO $ref_table
          (${ref_object}_id,
           ${ref_object}_name,
           description
           [ossweb::decode $ref_precedence Y ",precedence" ""]
           [ossweb::decode $ref_extra_name "" "" ",$ref_extra_name"]
           [ossweb::decode $ref_extra_name2 "" "" ",$ref_extra_name2"])
    VALUES([ossweb::sql::quote [string trim $id]],
           [ossweb::sql::quote $name],
           [ossweb::sql::quote $description]
           [ossweb::decode $ref_precedence Y ",'$precedence'" ""]
           [ossweb::decode $ref_extra_name "" "" ",[subst \$$ref_extra_name]"]
           [ossweb::decode $ref_extra_name2 "" "" ",[subst \$$ref_extra_name2]"])
  </sql>
</query>

<query name="ossweb.admin.reftable2.update">
  <description>
    Update reference table record
  </description>
  <sql>
    UPDATE $ref_table
    SET ${ref_object}_name=[ossweb::sql::quote $name],
        description=[ossweb::sql::quote $description]
        [ossweb::decode $ref_precedence Y ",precedence='$precedence'" ""]
        [ossweb::decode $ref_extra_name "" "" ",$ref_extra_name=[ossweb::sql::quote [subst \$$ref_extra_name]]"]
        [ossweb::decode $ref_extra_name2 "" "" ",$ref_extra_name2=[ossweb::sql::quote [subst \$$ref_extra_name2]]"]
    WHERE ${ref_object}_id=[ossweb::sql::quote $id]
  </sql>
</query>

<query name="ossweb.admin.reftable2.delete">
  <description>
    Delete reference table record
  </description>
  <sql>
    DELETE FROM $ref_table WHERE ${ref_object}_id=[ossweb::sql::quote $id]
  </sql>
</query>

<query name="ossweb.admin.reftable2.read_all">
  <description>
    Read all reference table records
  </description>
  <sql>
    SELECT ${ref_object}_id AS id,
           ${ref_object}_name AS name,
           description
           [ossweb::decode $ref_precedence Y ",precedence" ""]
           [ossweb::decode $ref_extra_name "" "" ",$ref_extra_name"]
           [ossweb::decode $ref_extra_name2 "" "" ",$ref_extra_name2"]
    FROM $ref_table
    ORDER BY [ossweb::decode $ref_precedence Y "precedence," ""]
             ${ref_object}_name
  </sql>
</query>

<query name="ossweb.admin.reftable2.read">
  <description>
    Read one record from reference table
  </description>
  <sql>
    SELECT ${ref_object}_id AS id,
           ${ref_object}_name AS name,
           description
           [ossweb::decode $ref_precedence Y ",precedence" ""]
           [ossweb::decode $ref_extra_name "" "" ",$ref_extra_name"]
           [ossweb::decode $ref_extra_name2 "" "" ",$ref_extra_name2"]
    FROM $ref_table
    WHERE ${ref_object}_id=[ossweb::sql::quote $id]
  </sql>
</query>


</xql>
