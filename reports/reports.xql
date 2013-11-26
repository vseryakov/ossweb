<?xml version="1.0"?>

<xql>

<query name="reports.read">
  <description>
    Selects the correct xql id from the system that will run the query
  </description>
  <sql>
    SELECT report_name,
           report_type,
           report_version,
           report_acl,
           xql_id,
           dbpool_name,
           disable_flag,
           form_script,
           before_script,
           eval_script,
           after_script,
           template,
           category_name,
           run_count,
           TO_CHAR(run_date,'YYYY-MM-DD HH24:MI') AS run_date
    FROM report_types t
         LEFT OUTER JOIN report_categories c
           ON report_type=category_id
    WHERE report_id = $report_id
  </sql>
</query>

<query name="reports.read.all">
  <description>
     Gets a list of all reports
  </description>
  <sql>
    SELECT report_id,
           report_name,
           report_type,
           report_version,
           report_acl,
           xql_id,
           dbpool_name,
           form_script,
           before_script,
           eval_script,
           after_script,
           category_name,
           category_path,
           1 AS type
    FROM report_types t
         LEFT OUTER JOIN report_categories c
           ON report_type=category_id
    ORDER BY report_type,
             report_name
  </sql>
</query>

<query name="reports.read.form_script">
  <description>
  </description>
  <sql>
    SELECT form_script FROM report_types WHERE report_id=$report_id
  </sql>
</query>

<query name="reports.read.by.xql_id">
  <description>
    Selects the correct xql id from the system that will run the query
  </description>
  <sql>
    SELECT report_name,
           report_type,
           report_version,
           report_acl,
           xql_id,
           dbpool_name,
           form_script,
           before_script,
           eval_script,
           after_script,
           template,
           category_name
    FROM report_types t
         LEFT OUTER JOIN report_categories c
           ON report_type=category_id
    WHERE xql_id = '$xql_id'
    LIMIT 1
  </sql>
</query>

<query name="reports.search">
  <description>
    Read record
  </description>
  <sql>
    SELECT report_id
    FROM report_types
    WHERE [ossweb::sql::filter \
          { report_type "" ""
            report_name "" ""
            report_version int ""
            xql_id "" "" }]
  </sql>
</query>

<query name="reports.create">
  <description>
    Create record
  </description>
  <sql>
    INSERT INTO report_types
    [ossweb::sql::insert_values -skip_null t -full t \
          { report_id int ""
            report_name "" ""
            report_type "" ""
            report_acl "" ""
            report_version int ""
            xql_id "" ""
            dbpool_name "" ""
            disable_flag "" "" }]
  </sql>
</query>

<query name="reports.update">
  <description>
  </description>
  <sql>
    UPDATE report_types
    SET [ossweb::sql::update_values \
              { report_type "" ""
                report_name "" ""
                report_acl "" ""
                report_version int ""
                xql_id "" ""
                dbpool_name "" ""
                disable_flag "" "" }]
    WHERE report_id = $report_id
  </sql>
</query>

<query name="reports.update.script">
  <description>
  </description>
  <sql>
    UPDATE report_types
    SET [ossweb::sql::update_values "${tab}_script {} {}"]
    WHERE report_id = $report_id
  </sql>
</query>

<query name="reports.update.stats">
  <description>
  </description>
  <sql>
    UPDATE report_types
    SET run_date=NOW(),
        run_count=run_count+1,
        run_user=[ossweb::conn user_id 0]
    WHERE report_id = $report_id
  </sql>
</query>

<query name="reports.delete">
  <description>
  </description>
  <sql>
    DELETE FROM report_types WHERE report_id = $report_id
  </sql>
</query>

<query name="reports.delete.old">
  <description>
    Delete old reports
  </description>
  <sql>
    DELETE FROM report_types
    WHERE NOT EXISTS(SELECT 1 FROM report_categories c WHERE c.category_id=report_types.report_type)
  </sql>
</query>

<query name="reports.copy">
  <description>
  </description>
  <sql>
    INSERT INTO report_types
                (report_id,report_name,report_type,report_acl,
                 xql_id,dbpool_name,disable_flag,
                 form_script,before_script,eval_script,after_script)
    SELECT $report_id,'COPY:'||report_name,report_type,report_acl,
           xql_id,dbpool_name,disable_flag,
           form_script,before_script,eval_script,after_script
    FROM report_types
    WHERE report_id=$old_report_id
  </sql>
</query>

<query name="reports.tree">
  <description>
     Gets a list of all reports
  </description>
  <sql>
    SELECT report_id,
           report_name,
           report_type,
           report_acl,
           xql_id,
           dbpool_name,
           before_script,
           eval_script,
           after_script,
           category_name,
           category_path,
           1 AS type
    FROM report_types t,
         report_categories c
    WHERE report_type=category_id AND
          report_version>0 AND
          disable_flag = FALSE
    UNION
    SELECT 0,
           NULL,
           category_id,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           NULL,
           category_name,
           category_path,
           0
    FROM report_categories c
    ORDER BY category_path,
             type,
             report_name
  </sql>
</query>

<query name="reports.category.select.read">
  <description>
    Selects report categories for select box
  </description>
  <sql>
    SELECT str_repeat('&nbsp;&nbsp;',str_length(category_path,'/')-2)||category_name,
           category_id
    FROM report_categories
    ORDER BY category_path
  </sql>
</query>

<query name="reports.category.list">
  <description>
    List of report categories
  </description>
  <sql>
    SELECT category_name,
           category_parent,
           category_id,
           description,
           category_path
    FROM report_categories
    ORDER BY category_path
  </sql>
</query>

<query name="reports.category.edit">
  <description>
    List of report categories
  </description>
  <sql>
    SELECT category_name,
           category_parent,
           category_id,
           description,
           category_path
    FROM report_categories
    WHERE category_id='$category_id'
  </sql>
</query>

<query name="reports.category.create">
  <description>
    Create category
  </description>
  <sql>
    INSERT INTO report_categories
    [ossweb::sql::insert_values -full t \
          { category_name "" ""
            category_parent "" ""
            category_id "" ""
            description "" "" }]
  </sql>
</query>

<query name="reports.category.update">
  <description>
    Update category
  </description>
  <sql>
    UPDATE report_categories
    SET [ossweb::sql::update_values \
              { category_name "" ""
                category_parent "" ""
                category_id "" ""
                description "" "" }]
    WHERE category_id='${category_id:old}'
  </sql>
</query>

<query name="reports.category.delete">
  <description>
    Delete category
  </description>
  <sql>
    DELETE FROM report_categories WHERE category_id='$category_id'
  </sql>
</query>

<query name="reports.category.delete.old">
  <description>
    Delete old reports
  </description>
  <sql>
    DELETE FROM report_categories
    WHERE NOW() - create_date > '$category_days days'::INTERVAL AND
          category_parent='$category_parent'
  </sql>
</query>

<query name="reports.calendar.read">
  <description>
    Read assigned calendar types for this report
  </description>
  <sql>
    SELECT repeat
    FROM ossweb_calendar
         WHERE user_id=[ossweb::conn user_id] AND
         description LIKE '% report_id $report_id %'
  </sql>
</query>

<query name="reports.calendar.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossweb_calendar
    WHERE description LIKE '% report_id $report_id %' AND
          user_id=[ossweb::conn user_id] AND
          remind_proc='report::schedule::calendar'
  </sql>
</query>

</xql>

