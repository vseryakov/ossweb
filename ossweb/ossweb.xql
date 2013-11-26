<?xml version="1.0"?>

<xql>

<query name="ossweb.db.database.list">
  <description>
  </description>
  <sql dbtype="postgresql">
    SELECT datname AS name FROM pg_database
  </sql>
</query>

<query name="ossweb.db.table.list">
  <description>
  </description>
  <sql dbtype="postgresql">
    SELECT relname AS name
    FROM pg_class
    WHERE relkind IN ('r') AND
          relname NOT LIKE 'pg_%' AND
          pg_catalog.pg_table_is_visible(oid)
    ORDER BY 1
  </sql>

  <sql dbtype="sqlite">
    SELECT name FROM sqlite_master WHERE type='table'
  </sql>
</query>

<query name="ossweb.db.table.indexes">
  <description>
  </description>
  <vars>
  </vars>
  <sql dbtype="postgresql">
    SELECT indexname,
           indexdef
    FROM pg_indexes
    WHERE tablename='$table_name'
  </sql>
</query>

<query name="ossweb.db.table.column.names">
  <description>
  </description>
  <sql dbtype="postgresql">
    SELECT DISTINCT 
           a.attname AS name,
           a.attnum
    FROM pg_class c,
         pg_attribute a,
         pg_type t
    WHERE c.relname = '$table_name' AND
          a.attnum > [ossweb::coalesce attnum 0] AND
          a.attrelid = c.oid AND
          a.atttypid = t.oid AND
          attisdropped = FALSE
    ORDER BY a.attnum
  </sql>

  <sql dbtype="sqlite">
    PRAGMA table_info($table_name)
  </sql>
</query>

<query name="ossweb.db.table.column.types">
  <description>
  </description>
  <sql dbtype="postgresql">
    SELECT DISTINCT 
           a.attname AS name,
           t.typname AS type,
           a.attnum
    FROM pg_class c,
         pg_attribute a,
         pg_type t
    WHERE c.relname = '$table_name' AND
          a.attnum > [ossweb::coalesce attnum 0] AND
          a.attrelid = c.oid AND
          a.atttypid = t.oid AND
          attisdropped = FALSE
    ORDER BY a.attnum
  </sql>

  <sql dbtype="sqlite">
    PRAGMA table_info($table_name)
  </sql>
</query>

<query name="ossweb.sendmail">
  <description>
    Submits email message to the queue
  </description>
  <sql>
    INSERT INTO ossweb_message_queue
    [ossweb::sql::insert_values -full t \
          { message_type "" email
            rcpt_to "" ""
            mail_from "" ""
            subject "" ""
            body "" ""
            args "" ""}]
  </sql>
</query>

<query name="ossweb.seq.nextval">
  <description>
    Generates new id using sequences
  </description>
  <sql>
   SELECT NEXTVAL('${name}_seq')
  </sql>
</query>

<query name="ossweb.seq.currval">
  <description>
    Generates new id using sequences
  </description>
  <sql>
   SELECT CURRVAL('${name}_seq')
  </sql>
</query>


<query name="ossweb.tsearch.search1">
  <description>
  </description>
  <vars>
   tsearch_text ""
   tsearch_type ""
   tsearch_filter ""
  </vars>
  <sql>
   SELECT tsearch_key,
          ROUND(rank_cd(tsearch_idx,to_tsquery([ossweb::sql::quote $tsearch_text]),1)::NUMERIC,1|4) AS tsearch_rank
   FROM ossweb_tsearch
   WHERE tsearch_idx @@ to_tsquery([ossweb::sql::quote $tsearch_text])
         [ossweb::sql::filter \
               { tsearch_type list "" } \
               -filter [subst $tsearch_filter] \
               -where AND \
               -before AND]
   ORDER BY tsearch_rank DESC
  </sql>
</query>

<query name="ossweb.tsearch.search2">
  <description>
  </description>
  <vars>
   search_text ""
  </vars>
  <sql>
   SELECT tsearch_key,
          tsearch_id,
          tsearch_type,
          tsearch_text,
          tsearch_date,
          tsearch_data,
          tsearch_value,
          ROUND(rank_cd(tsearch_idx,to_tsquery([ossweb::sql::quote $tsearch_text]),1)::NUMERIC,2) AS tsearch_rank
   FROM ossweb_tsearch
   WHERE tsearch_key IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossweb.tsearch.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossweb_tsearch
    [ossweb::sql::insert_values -full t \
          { tsearch_id "" ""
            tsearch_type "" ""
            tsearch_data "" ""
            tsearch_value "" ""
            tsearch_text "" "" }]
  </sql>
</query>

<query name="ossweb.tsearch.update">
  <description>
  </description>
  <sql>
    UPDATE ossweb_tsearch
    SET [ossweb::sql::update_values \
              { tsearch_text "" ""
                tsearch_data "" ""
                tsearch_value "" ""
                tsearch_date "" NOW() }]
    WHERE tsearch_id=[ossweb::sql::quote $tsearch_id] AND
          tsearch_type=[ossweb::sql::quote $tsearch_type]
  </sql>
</query>

<query name="ossweb.tsearch.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossweb_tsearch
    WHERE tsearch_id=[ossweb::sql::quote $tsearch_id] AND
          tsearch_type=[ossweb::sql::quote $tsearch_type]
  </sql>
</query>

<query name="ossweb.tsearch.template">
  <description>
   Columns order is predefined and used in ossweb::schedule::tsearch as well
  </description>
  <vars>
  tsearch_id ""
  tsearch_text ""
  tsearch_date ""
  tsearch_data ""
  tsearch_value ""
  tsearch_type ""
  tsearch_table ""
  tsearch_limit 1000
  tsearch_noupdate 0
  tsearch_nodelete 0
  tsearch_noinsert 0
  </vars>
  <sql>
    [ossweb::iftrue $tsearch_noinsert {} {
    SELECT 'A' AS tsearch_op,
           '$tsearch_type' AS tsearch_type,
           ${tsearch_id}::TEXT AS tsearch_id,
           $tsearch_text AS tsearch_text,
           [ossweb::nvl $tsearch_data NULL] AS tsearch_data,
           [ossweb::nvl $tsearch_value NULL] AS tsearch_value
    FROM $tsearch_table tt,
         (SELECT ${tsearch_id} AS tsearch_id
          FROM $tsearch_table tt
          EXCEPT
          SELECT ${tsearch_id}
          FROM ossweb_tsearch ot,
               $tsearch_table tt
          WHERE tsearch_id=${tsearch_id}::TEXT AND
                tsearch_type='$tsearch_type') a
    WHERE ${tsearch_id}=tsearch_id
    }]
    [ossweb::iftrue $tsearch_noupdate {} {
    UNION ALL
    SELECT 'U' AS tsearch_op,
           '$tsearch_type' AS tsearch_type,
           ${tsearch_id}::TEXT AS tsearch_id,
           $tsearch_text AS tsearch_text,
           [ossweb::nvl $tsearch_data NULL] AS tsearch_data,
           [ossweb::nvl $tsearch_value NULL] AS tsearch_value
    FROM $tsearch_table tt,
         ossweb_tsearch ot
    WHERE tsearch_id=${tsearch_id}::TEXT AND
          tsearch_type='$tsearch_type' AND
          tsearch_date<$tsearch_date
    }]
    [ossweb::iftrue $tsearch_nodelete {} {
    UNION ALL
    SELECT 'D' AS tsearch_op,
            '$tsearch_type' AS tsearch_type,
            tsearch_id,
            NULL AS tsearch_text,
            NULL AS tsearch_data,
            NULL AS tsearch_value
    FROM (SELECT tsearch_id
          FROM ossweb_tsearch ot
          WHERE tsearch_type='$tsearch_type'
          EXCEPT
          SELECT ${tsearch_id}::TEXT
          FROM ossweb_tsearch ot,
               $tsearch_table tt
          WHERE tsearch_id=${tsearch_id}::TEXT AND
                tsearch_type='$tsearch_type') a
    }]
    LIMIT $tsearch_limit
  </sql>
</query>

<query name="ossweb.apps.list">
  <description>
    Retrieve configured applications for building menu items
  </description>
  <sql>
    SELECT *
    FROM ossweb_apps
    ORDER BY project_name,
             tree_path
  </sql>
</query>

<query name="ossweb.user_types.list">
  <description>
    Read user types for using in select box
  </description>
  <sql>
    SELECT type_name,type_id FROM ossweb_user_types ORDER BY 1
  </sql>
</query>

<query name="ossweb.config_types.list">
  <description>
    Read config types for using in select box
  </description>
  <sql>
    SELECT type_name,type_id FROM ossweb_config_types ORDER BY 1
  </sql>
</query>

<query name="ossweb.config_types.read">
  <description>
    Read config types for using in select box
  </description>
  <sql>
    SELECT type_id,
           type_name,
           description,
           module,
           widget
    FROM ossweb_config_types
    WHERE type_id=[ossweb::sql::quote $type_id]
  </sql>
</query>

<query name="ossweb.state_machine.select.list">
  <description>
  </description>
  <sql>
    SELECT status_name,
           status_id
    FROM ossweb_state_machine
    WHERE module='$module'
    ORDER BY sort
  </sql>
</query>

<query name="ossweb.state_machine.select.allowed">
  <description>
  </description>
  <sql>
    SELECT state_machine_next('$module','$status_id',TRUE)
  </sql>
</query>

<query name="ossweb.state_machine.create">
  <description>
    Create state machine record
  </description>
  <sql>
    INSERT INTO ossweb_state_machine
    [ossweb::sql::insert_values -full t \
          { status_id name ""
            type name ""
            module name ""
            status_name "" ""
            states "" ""
            sort int 0
            description "" "" }]
  </sql>
</query>

<query name="ossweb.state_machine.update">
  <description>
    Update state machine record
  </description>
  <sql>
    UPDATE ossweb_state_machine
    SET [ossweb::sql::update_values \
              { status_id name ""
                type name ""
                module name ""
                status_name "" ""
                states "" ""
                sort int 0
                description "" "" }]
    WHERE status_id=[ossweb::sql::quote $status_id] AND
          module=[ossweb::sql::quote $module]
  </sql>
</query>

<query name="ossweb.state_machine.delete">
  <description>
    Delete state machine record
  </description>
  <sql>
    DELETE FROM ossweb_state_machine
    WHERE status_id=[ossweb::sql::quote $status_id] AND
          module=[ossweb::sql::quote $module]
  </sql>
</query>

<query name="ossweb.state_machine.list">
  <description>
    Read all state machine records
  </description>
  <sql>
    SELECT status_id,
           type,
           module,
           status_name,
           states,
           sort,
           description
    FROM ossweb_state_machine
    ORDER BY module,
             sort,
             status_name
  </sql>
</query>

<query name="ossweb.state_machine.read">
  <description>
    Read one state machine record
  </description>
  <sql>
    SELECT status_id,
           type,
           module,
           status_name,
           states,
           sort,
           description
    FROM ossweb_state_machine
    WHERE status_id=[ossweb::sql::quote $status_id] AND
          module=[ossweb::sql::quote $module]
  </sql>
</query>

<query name="ossweb.reftable.read">
  <description>
    General purpose reftable facility, retrieve table setup for requested page
  </description>
  <sql>
    SELECT table_name,
           object_name,
           title,
           refresh,
           precedence,
           extra_name,
           extra_label,
           extra_name2,
           extra_label2
    FROM ossweb_reftable
    WHERE page_name=[ossweb::sql::quote $page_name] AND
          (app_name = '' OR app_name=[ossweb::sql::quote $app_name])
    LIMIT 1
  </sql>
</query>

<query name="ossweb.schedule.list">
  <description>
    Retrieve all scheduled tasks
  </description>
  <sql>
    SELECT task_id,
           task_name,
           task_proc,
           task_args,
           task_wday,
           task_mday,
           task_time,
           task_interval,
           task_thread,
           task_once,
           task_server
    FROM ossweb_schedule
    ORDER BY task_name
  </sql>
</query>

<query name="ossweb.schedule.list_enabled">
  <description>
    Retrieve all enabled scheduled tasks
  </description>
  <sql>
    SELECT task_id,
           task_name,
           task_proc,
           task_args,
           task_wday,
           task_mday,
           task_time,
           task_interval,
           task_thread,
           task_once,
           task_server
    FROM ossweb_schedule
    WHERE task_disabled = FALSE
          [ossweb::sql::filter { task_id ilist "" } \
                -before AND]
  </sql>
</query>

<query name="ossweb.schedule.read">
  <description>
    Read task schedule record
  </description>
  <sql>
    SELECT task_id,
           task_name,
           task_proc,
           task_args,
           task_wday,
           task_mday,
           task_time,
           task_interval,
           task_thread,
           task_once,
           task_disabled,
           task_server,
           description
    FROM ossweb_schedule
    WHERE task_id=$task_id
  </sql>
</query>

<query name="ossweb.schedule.delete">
  <description>
    Delete task schedule record
  </description>
  <sql>
    DELETE FROM ossweb_schedule WHERE task_id=$task_id
  </sql>
</query>

<query name="ossweb.schedule.update">
  <description>
   Update task schedule record
  </description>
  <sql>
    UPDATE ossweb_schedule
    SET [ossweb::sql::update_values { task_id int -2
                                   task_name "" ""
                                   task_proc "" ""
                                   task_args "" ""
                                   task_wday list ""
                                   task_mday list ""
                                   task_time "" ""
                                   task_interval int ""
                                   task_thread "" ""
                                   task_once "" ""
                                   task_disabled "" "f"
                                   task_server "" ""
                                   description "" "" }]
    WHERE task_id=$task_id
  </sql>
</query>

<query name="ossweb.schedule.create">
  <description>
    Create new task schedule record
  </description>
  <sql>
    INSERT INTO ossweb_schedule
    [ossweb::sql::insert_values -full t \
          { task_name "" ""
            task_proc "" ""
            task_args "" ""
            task_wday list ""
            task_mday list ""
            task_time "" ""
            task_interval int ""
            task_thread "" ""
            task_once "" ""
            task_disabled "" "N"
            task_server "" ""
            description "" "" }]
  </sql>
</query>

<query name="ossweb.message_queue.list">
  <description>
    Runs periodically and scans for new messages to be sent
  </description>
  <sql>
    SELECT message_id,
           message_type,
           rcpt_to,
           mail_from,
           subject,
           body,
           args
    FROM ossweb_message_queue
    WHERE sent_flag='N' AND
          try_count <= [ossweb::config server:message_queue:try_count 10] AND
          create_date >= NOW() - '1 day'::INTERVAL
    ORDER BY create_date
  </sql>
</query>

<query name="ossweb.message_queue.search1">
  <description>
    First part of message search, returns message id
  </description>
  <sql>
    SELECT message_id
    FROM ossweb_message_queue
    [ossweb::sql::filter \
          { message_id int ""
            message_type "" ""
            sent_flag "" ""
            create_date date ""
            try_count int ""
            error_msg Text ""
            rcpt_to Text ""
            mail_from Text ""
            subject Text ""
            body Text "" } \
         -where WHERE]
    ORDER BY create_date DESC,
             rcpt_to,
             mail_from
  </sql>
</query>

<query name="ossweb.message_queue.search2">
  <description>
    Second part of message search, returns all columns
  </description>
  <sql>
    SELECT message_id,message_type,sent_flag,create_date,rcpt_to,mail_from,subject,
           CASE WHEN error_msg IS NULL THEN 'N' ELSE 'Y' END AS error_msg
    FROM ossweb_message_queue
    WHERE message_id in (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossweb.message_queue.list.unsent.yesterday">
  <description>
    List of all unsent messages for yesterday
  </description>
  <sql>
    SELECT message_id,
           message_type,
           rcpt_to,
           mail_from,
           subject,
           body,
           args,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM ossweb_message_queue
    WHERE sent_flag='N' AND
          create_date::DATE=NOW()::DATE-1
    ORDER BY create_date
  </sql>
</query>

<query name="ossweb.message_queue.update.try_count">
  <description>
    Updates message status after each delivery attempt
  </description>
  <sql>
    UPDATE ossweb_message_queue
    SET sent_flag=[ossweb::sql::quote $sent_flag],
        try_count=try_count+1,
        error_msg=[ossweb::sql::quote $errmsg]
    WHERE message_id=$message_id
  </sql>
</query>

<query name="ossweb.message_queue.update.resend">
  <description>
    Re-schedule message for delivery
  </description>
  <sql>
    UPDATE ossweb_message_queue
    SET sent_flag='N',
        try_count=0
    WHERE message_id=$message_id
  </sql>
</query>

<query name="ossweb.message_queue.read">
  <description>
    Read message record
  </description>
  <sql>
    SELECT message_id,
           message_type,
           sent_flag,
           create_date,
           try_count,
           error_msg,
           rcpt_to,
           mail_from,
           subject,
           body,
           args
    FROM ossweb_message_queue
    WHERE message_id=$message_id
  </sql>
</query>

<query name="ossweb.message_queue.delete">
  <description>
    Delete message
  </description>
  <sql>
    DELETE FROM ossweb_message_queue WHERE message_id=$message_id
  </sql>
</query>

<query name="ossweb.config.list">
  <description>
    Reads all config records
  </description>
  <sql>
    SELECT c.name,
           c.value,
           COALESCE(c.module,'OSSWEB') AS module,
           c.description,
           t.type_name,
           t.widget
    FROM ossweb_config c
         LEFT OUTER JOIN ossweb_config_types t
           ON c.name=t.type_id
    ORDER BY module,
             COALESCE(type_id,c.name),
             COALESCE(type_name,c.name)
  </sql>
</query>

<query name="ossweb.config.update">
  <description>
  </description>
  <sql>
    UPDATE ossweb_config
    SET [ossweb::sql::update_values -skip_null t \
              { value "" ""
                module "" ""
                description "" "" }]
    WHERE name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="ossweb.config.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossweb_config WHERE name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="ossweb.config.create">
  <description>
    Create new config record
  </description>
  <sql>
    INSERT INTO ossweb_config
    [ossweb::sql::insert_values -full t \
          { name "" ""
            value "" ""
            module "" ""
            description "" "" }]
  </sql>
</query>

<query name="ossweb.user.read_email">
  <description>
    Read user email address
  </description>
  <sql>
    SELECT user_email FROM ossweb_users WHERE user_id=$user_id
  </sql>
</query>

<query name="ossweb.user.read_username">
  <description>
    Read user login name
  </description>
  <sql>
    SELECT user_name FROM ossweb_users WHERE user_id=$user_id
  </sql>
</query>

<query name="ossweb.user.read_name">
  <description>
    Read user name
  </description>
  <sql>
    SELECT first_name||' '||last_name as user_name FROM ossweb_users WHERE user_id=$user_id
  </sql>
</query>

<query name="ossweb.user.read">
  <description>
    Reads user record
  </description>
  <sql>
    SELECT *,
           TO_CHAR(create_time,'MM/DD/YY HH24:MI') AS create_time,
           ossweb_user_sessions(user_id) AS user_sessions,
           ossweb_user_prefs(user_id) AS user_prefs
    FROM ossweb_users
    WHERE [ossweb::sql::filter \
                { user_id int ""
                  user_name "" ""
                  user_email "" "" }]
    LIMIT 1
  </sql>
</query>

<query name="ossweb.user.search">
  <description>
   Quick search
  </description>
  <sql>
    SELECT first_name||' '||last_name AS full_name,
           user_id,
           first_name,
           last_name,
           user_email
    FROM ossweb_users u
    [ossweb::sql::filter \
                { user_id int ""
                  user_type "" employee
                  user_name Text ""
                  email_search "" ""
                  first_name Text ""
                  last_name Text ""
                  user_email Text ""
                  status list active
                  full_name int ""
                  groups ilist ""
                  groupnames list "" } \
               -where WHERE \
               -prefix [ossweb::coalesce user_prefix] \
               -map { full_name "first_name||' '||last_name ILIKE '%value%'"
                      email_search "(first_name ~* %value OR last_name ~* %value OR user_email ~* %value)"
                      groups sql:ossweb.user.group.map
                      groupnames sql:ossweb.user.group.map.names }]
    ORDER BY [ossweb::coalesce user_sort 2,3]
    LIMIT [ossweb::coalesce user_limit 999]
  </sql>
</query>

<query name="ossweb.user.search.by.name">
  <description>
    Returns user ID by user name
  </description>
  <sql>
    SELECT user_id FROM ossweb_users WHERE user_name=[ossweb::sql::quote $user_name]
  </sql>
</query>

<query name="ossweb.user.search.by.email">
  <description>
    Returns user ID by user name
  </description>
  <sql>
    SELECT user_id FROM ossweb_users WHERE user_name=[ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="ossweb.user.search1">
  <description>
    First part of user search
  </description>
  <vars>
   user_sort "user_type,user_name"
   user_limit 9999
  </vars>
  <sql>
    SELECT user_id
    FROM ossweb_users u,
         ossweb_user_types ut
    WHERE user_type=type_id
          [ossweb::sql::filter \
                { user_id int ""
                  user_type "" ""
                  user_name Text ""
                  email_search "" ""
                  first_name Text ""
                  middle_name Text ""
                  last_name Text ""
                  user_email Text ""
                  status list ""
                  full_name int ""
                  groups ilist ""
                  groupnames list "" } \
               -before AND \
               -alias u. \
               -map { full_name "first_name||' '||last_name ILIKE '%value%'"
                      email_search "(first_name ~* %value OR last_name ~* %value OR user_email ~* %value)"
                      groups sql:ossweb.user.group.map
                      groupnames sql:ossweb.user.group.map.names }]
    ORDER BY $user_sort
    LIMIT $user_limit
  </sql>
</query>

<query name="ossweb.user.search2">
  <description>
    Second part of user search
  </description>
  <sql>
    SELECT user_id,
           user_type,
           user_name,
           first_name,
           middle_name,
           last_name,
           user_email,
           status,
           create_time,
           start_page,
           type_name,
           ossweb_user_prefs(user_id) AS user_prefs,
           ossweb_user_groups(user_id) AS groups,
           TO_CHAR(ossweb_user_access_time(user_id),'YYYY-MM-DD HH24:MI') AS access_time
    FROM ossweb_users u,
         ossweb_user_types ut
    WHERE user_type=type_id AND
          user_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossweb.user.select.read">
  <description>
    Read users for select box
  </description>
  <sql>
    SELECT first_name||' '||last_name,
           user_id
    FROM ossweb_users
    WHERE status='active'
          [ossweb::sql::filter \
                { user_type_filter "" "" } \
                -before AND \
                -namemap { user_type_filter user_type }]
    ORDER BY 1
  </sql>
</query>

<query name="ossweb.user.select.read.email">
  <description>
    Read users for select box
  </description>
  <sql>
    SELECT first_name||' '||last_name,
           user_email
    FROM ossweb_users
    WHERE status='active'
          [ossweb::sql::filter \
                { user_type_filter "" "" } \
                -before AND \
                -namemap { user_type_filter user_type }]
    ORDER BY 1
  </sql>
</query>

<query name="ossweb.user.session.cleanup">
  <description>
    Runs periodically and deletes expired user properties
  </description>
  <sql>
    DELETE FROM ossweb_user_sessions
    WHERE NOW() - access_time > '[ossweb::config session:timeout 16070400] secs'
  </sql>
</query>


<query name="ossweb.user.group.list">
  <description>
  </description>
  <sql>
    SELECT g.group_id,
           g.group_name,
           g.description
    FROM ossweb_groups g,
         ossweb_user_groups ug
    WHERE ug.group_id=g.group_id AND
          ug.user_id=$user_id
    ORDER BY 2
  </sql>
</query>

<query name="ossweb.user.group.belong">
  <description>
    check if user belongs to a group
  </description>
  <sql>
    SELECT g.group_id
    FROM ossweb_user_groups ug,
         ossweb_groups g
    WHERE ug.group_id=g.group_id AND
          ug.user_id=$user_id
          [ossweb::sql::filter \
                { group_id ilist ""
                  group_name list "" } \
                -alias g. \
                -before AND]
  </sql>
</query>

<query name="ossweb.user.group.create.by.name">
  <description>
    Adds the user to the group using group name
  </description>
  <sql>
    INSERT INTO ossweb_user_groups (user_id,group_id)
           SELECT $user_id,group_id
           FROM ossweb_groups
           WHERE group_name=[ossweb::sql::quote $group_name]
  </sql>
</query>

<query name="ossweb.user.group.read.by.id">
  <description>
    Read all users for specified group(s)
  </description>
  <sql>
    SELECT user_id
    FROM ossweb_user_groups
    WHERE group_id IN ([ossweb::sql::list $groups])
  </sql>
</query>

<query name="ossweb.user.group.map">
  <description>
    User search filter, mapping groups list into SQL statement
  </description>
  <sql>
    EXISTS(SELECT user_id
           FROM ossweb_user_groups ug
           WHERE u.user_id=ug.user_id AND
           ug.group_id IN (%value))
  </sql>
</query>

<query name="ossweb.user.group.map.names">
  <description>
    User search filter, mapping groups list into SQL statement
  </description>
  <sql>
    EXISTS(SELECT user_id
           FROM ossweb_user_groups ug,
                ossweb_groups g
           WHERE u.user_id=ug.user_id AND
                 ug.group_id=g.group_id AND
                 (g.group_name IN (%value) OR g.short_name IN (%value)))
  </sql>
</query>

<query name="ossweb.user.property.read">
  <description>
    Read value of specified property
  </description>
  <sql>
    SELECT value,
           EXTRACT(EPOCH FROM timeout) AS timeout
    FROM ossweb_user_properties
    WHERE user_id=$user_id AND
          session_id=[ossweb::sql::quote $session_id] AND
          name=[ossweb::sql::quote $name] AND
          (timeout IS NULL OR create_time+timeout >= NOW())
  </sql>
</query>

<query name="ossweb.user.property.create">
  <description>
    Creates new user proprty record
  </description>
  <sql>
    INSERT INTO ossweb_user_properties(user_id,session_id,name,value,timeout)
    SELECT [ossweb::sql::insert_values -skip_null f \
                 { user_id int ""
                   session_id "" ""
                   name "" ""
                   value "" ""
                   timeout "" "" }]
    WHERE NOT EXISTS(SELECT 1 FROM ossweb_user_properties
                     WHERE user_id=$user_id AND
                           session_id=[ossweb::sql::quote $session_id] AND
                           name=[ossweb::sql::quote $name])
  </sql>
</query>

<query name="ossweb.user.property.update">
  <description>
    Updates user property with new value
  </description>
  <sql>
    UPDATE ossweb_user_properties
    SET value=[ossweb::sql::quote $value],
        create_time=NOW()
    WHERE user_id=$user_id AND
          session_id=[ossweb::sql::quote $session_id] AND
          name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="ossweb.user.property.append">
  <description>
    Updates user property with new value
  </description>
  <sql>
    UPDATE ossweb_user_properties
    SET value=value||[ossweb::sql::quote $value],
        create_time=NOW()
    WHERE user_id=$user_id AND
          session_id=[ossweb::sql::quote $session_id] AND
          name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="ossweb.user.property.delete">
  <description>
    Deletes user property record
  </description>
  <sql>
    DELETE FROM ossweb_user_properties
    WHERE user_id=$user_id AND
          session_id=[ossweb::sql::quote $session_id] AND
          name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="ossweb.user.property.cleanup">
  <description>
    Runs periodically and deletes expired user properties
  </description>
  <sql>
    DELETE FROM ossweb_user_properties
    WHERE (session_id <> '0' AND NOW() - create_time > '[ossweb::config session:timeout 16070400] secs') OR
          (timeout IS NOT NULL AND create_time+timeout < NOW())
  </sql>
</query>

<query name="ossweb.prefs.list">
  <description>
    Reads all config records
  </description>
  <sql>
    SELECT name,
           value
    FROM ossweb_prefs
    WHERE obj_id=[ossweb::sql::quote $obj_id int] AND
          obj_type=[ossweb::sql::quote $obj_type]
    ORDER BY 1
  </sql>
</query>

<query name="ossweb.prefs.read">
  <description>
    Reads all config records
  </description>
  <sql>
    SELECT value
    FROM ossweb_prefs
    WHERE name=[ossweb::sql::quote $name] AND
          obj_id=[ossweb::sql::quote $obj_id int] AND
          obj_type=[ossweb::sql::quote $obj_type]
  </sql>
</query>

<query name="ossweb.prefs.update">
  <description>
  </description>
  <sql>
    UPDATE ossweb_prefs
    SET value=[ossweb::sql::quote $value]
    WHERE name=[ossweb::sql::quote $name] AND
          obj_id=[ossweb::sql::quote $obj_id int] AND
          obj_type=[ossweb::sql::quote $obj_type]
  </sql>
</query>

<query name="ossweb.prefs.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossweb_prefs
    WHERE name=[ossweb::sql::quote $name] AND
          obj_id=[ossweb::sql::quote $obj_id] AND
          obj_type=[ossweb::sql::quote $obj_type]
  </sql>
</query>

<query name="ossweb.prefs.create">
  <description>
    Create new config record
  </description>
  <sql>
    INSERT INTO ossweb_prefs(obj_id,obj_type,name,value)
    VALUES([ossweb::sql::quote $obj_id int],[ossweb::sql::quote $obj_type],
           [ossweb::sql::quote $name],[ossweb::sql::quote $value])
  </sql>
</query>

<query name="ossweb.acls.delete">
  <description>
    Delet all ACLs
  </description>
  <sql>
    DELETE FROM ossweb_acls WHERE acl_id=$acl_id
  </sql>
</query>

<query name="ossweb.acls.create">
  <description>
    Creates new ACL record
  </description>
  <sql>
    INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value,query,handlers,precedence)
    VALUES([ossweb::sql::quote $obj_id int],
           [ossweb::sql::quote $obj_type],
           [ossweb::sql::quote [ossweb::nvl $project_name *]],
           [ossweb::sql::quote [ossweb::nvl $app_name *]],
           [ossweb::sql::quote [ossweb::nvl $page_name *]],
           [ossweb::sql::quote [ossweb::nvl $cmd_name *]],
           [ossweb::sql::quote [ossweb::nvl $ctx_name *]],
           [ossweb::sql::quote $value],
           [ossweb::sql::quote $query],
           [ossweb::sql::quote $handlers],
           [ossweb::sql::quote $precedence int])
  </sql>
</query>

<query name="ossweb.acls.list">
  <description>
    Read all user ACL records
  </description>
  <vars>
   obj_type U
  </vars>
  <sql>
    SELECT acl_id,
           project_name,
           app_name,
           page_name,
           cmd_name,
           ctx_name,
           query,
           handlers,
           value,
           obj_type,
           NULL AS group_name,
           0 AS group_id,
           COALESCE(precedence,0) AS precedence
    FROM ossweb_acls
    WHERE obj_id=$obj_id AND
          obj_type='$obj_type'
    [ossweb::iftrue {$obj_type == "U"} {
    UNION
    SELECT acl_id,
           project_name,
           app_name,
           page_name,
           cmd_name,
           ctx_name,
           query,
           handlers,
           value,
           obj_type,
           group_name,
           g.group_id,
           CASE WHEN a.precedence IS NOT NULL THEN a.precedence
                WHEN g.precedence IS NOT NULL THEN g.precedence
                ELSE 0
           END AS precedence
    FROM ossweb_acls a,
         ossweb_user_groups u,
         ossweb_groups g
    WHERE a.obj_id=u.group_id AND
          u.user_id=$obj_id AND
          a.obj_type='G' AND
          u.group_id=g.group_id
    }]
    ORDER BY precedence DESC,
             ctx_name DESC,
             cmd_name DESC,
             page_name DESC,
             app_name DESC,
             project_name DESC
  </sql>
</query>

<query name="ossweb.group.update">
  <description>
    Update group columns
  </description>
  <sql>
    UPDATE ossweb_groups
    SET [ossweb::sql::update_values -skip_null t \
               { group_name "" ""
                 short_name "" ""
                 description "" ""
                 precedence int "" }]
    WHERE group_id=$group_id
  </sql>
</query>

<query name="ossweb.group.create">
  <description>
    Create new group
  </description>
  <sql>
    INSERT INTO ossweb_groups
         [ossweb::sql::insert_values -full t \
               { group_name "" ""
                 short_name "" ""
                 description "" ""
                 precedence int "" }]
  </sql>
</query>

<query name="ossweb.group.delete">
  <description>
    Delete the group record
  </description>
  <sql>
    DELETE FROM ossweb_groups WHERE group_id=$group_id
  </sql>
</query>

<query name="ossweb.group.delete.users">
  <description>
    Delete all user groups by group id
  </description>
  <sql>
    DELETE FROM ossweb_user_groups WHERE group_id=$group_id
  </sql>
</query>

<query name="ossweb.group.delete.acls">
  <description>
    Delete all ACLs for the given group
  </description>
  <sql>
    DELETE FROM ossweb_acls WHERE obj_id=$group_id AND obj_type='G'
  </sql>
</query>

<query name="ossweb.group.read_all">
  <description>
    Read all group records
  </description>
  <sql>
    SELECT group_id,
           group_name,
           short_name,
           description,
           precedence
    FROM ossweb_groups
    ORDER BY precedence DESC,
             group_name
  </sql>
</query>

<query name="ossweb.group.read">
  <description>
    Read one group record by ID
  </description>
  <sql>
    SELECT group_id,
           group_name,
           short_name,
           description
    FROM ossweb_groups
    WHERE group_id=$group_id
  </sql>
</query>

<query name="ossweb.group.select.read">
  <description>
    Read groups for using in select box
  </description>
  <sql>
    SELECT group_name,group_id FROM ossweb_groups ORDER BY 1
  </sql>
</query>

<query name="ossweb.category.select.read">
  <description>
    Read categories for using in select box
  </description>
  <sql>
    SELECT category_name||'('||module||')',
           category_id
    FROM ossweb_categories
    ORDER BY module,
             tree_path
  </sql>
</query>

<query name="ossweb.category.select.list">
  <description>
    Read all records
  </description>
  <sql>
    SELECT category_name,
           category_id
    FROM ossweb_categories
    [ossweb::sql::filter \
          { module list "" } \
          -where WHERE]
    ORDER BY module,
             tree_path
  </sql>
</query>

<query name="ossweb.category.select.name">
  <description>
    Read categories for using in select box
  </description>
  <sql>
    SELECT category_name,
           category_name
    FROM ossweb_categories
    [ossweb::sql::filter \
          { module list "" } \
          -where WHERE]
    ORDER BY module,
             tree_path
  </sql>
</query>

<query name="ossweb.category.select.module">
  <description>
  </description>
  <sql>
     SELECT DISTINCT
            INITCAP(module),
            module
     FROM ossweb_categories
     ORDER BY 1
  </sql>
</query>

<query name="ossweb.category.subtree">
  <description>
    Read subcategories for given category
  </description>
  <sql>
    SELECT c2.category_id
    FROM ossweb_categories c1,
         ossweb_categories c2
    WHERE c1.category_id=$category_id AND
          c2.tree_path LIKE c1.tree_path||'%'
  </sql>
</query>

<query name="ossweb.category.list">
  <description>
    Read all records
  </description>
  <sql>
    SELECT category_id,
           category_parent,
           category_name,
           module,
           description,
           tree_path,
           color,
           bgcolor,
           sort
    FROM ossweb_categories
    [ossweb::sql::filter \
          { module list ""
            category_name Text "" } \
          -where WHERE]
    ORDER BY module,
             tree_path
  </sql>
</query>

<query name="ossweb.category.create">
  <description>
    Create state machine record
  </description>
  <sql>
    INSERT INTO ossweb_categories
    [ossweb::sql::insert_values -full t \
          { category_parent int ""
            category_name "" ""
            module name ""
            description "" ""
            color "" ""
            bgcolor "" ""
            sort int "" }]
  </sql>
</query>

<query name="ossweb.category.update">
  <description>
    Update state machine record
  </description>
  <sql>
    UPDATE ossweb_categories
    SET [ossweb::sql::update_values \
              { category_parent int ""
                module name ""
                category_name "" ""
                description "" ""
                color "" ""
                bgcolor "" ""
                sort int "" }]
    WHERE category_id=$category_id
  </sql>
</query>

<query name="ossweb.category.delete">
  <description>
    Delete state machine record
  </description>
  <sql>
    DELETE FROM ossweb_categories WHERE category_id=$category_id
  </sql>
</query>

<query name="ossweb.category.read">
  <description>
    Read one record
  </description>
  <sql>
    SELECT c.category_id,
           c.category_parent,
           c.category_name,
           p.category_name AS parent_name,
           c.module,
           c.description,
           c.tree_path,
           c.color,
           c.bgcolor,
           c.sort
    FROM ossweb_categories c
         LEFT OUTER JOIN ossweb_categories p
           ON c.category_parent=p.category_id
    WHERE c.category_id=$category_id
  </sql>
</query>

<query name="ossweb.help.search">
  <description>
    Search for closest help text
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
    WHERE (project_name IN ([ossweb::sql::quote $project_name],'unknown') OR project_name LIKE [ossweb::sql::quote $project_name Text]) AND
          (app_name IN ([ossweb::sql::quote $app_name],'unknown') OR app_name LIKE [ossweb::sql::quote $app_name Text]) AND
          (page_name IN ([ossweb::sql::quote $page_name],'unknown') OR page_name LIKE [ossweb::sql::quote $page_name Text]) AND
          (cmd_name IN ([ossweb::sql::quote $cmd_name],'unknown') OR cmd_name LIKE [ossweb::sql::quote $cmd_name Text]) AND
          (ctx_name IN ([ossweb::sql::quote $ctx_name],'unknown') OR ctx_name LIKE [ossweb::sql::quote $ctx_name Text])
    ORDER BY CASE WHEN project_name='unknown' THEN NULL ELSE project_name END,
             CASE WHEN app_name='unknown' THEN NULL ELSE app_name END,
             CASE WHEN page_name='unknown' THEN NULL ELSE page_name END,
             CASE WHEN cmd_name='unknown' THEN NULL ELSE cmd_name END,
             CASE WHEN ctx_name='unknown' THEN NULL ELSE ctx_name END
    LIMIT 1
  </sql>
</query>

<query name="ossweb.help.read">
  <description>
    Read specified help text
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
    WHERE help_id=$help_id
  </sql>
</query>

<query name="ossweb.resource.lock">
  <description>
  </description>
  <sql>
    SELECT ossweb_resource_lock([ossweb::sql::quote $rcs_type],
                                [ossweb::sql::quote $rcs_name],
                                [ossweb::sql::quote $rcs_start],
                                [ossweb::sql::quote $rcs_end],
                                [ossweb::sql::quote $rcs_data],
                                [ossweb::sql::quote $rcs_user])
  </sql>
</query>

<query name="ossweb.resource.trylock">
  <description>
  </description>
  <sql>
    SELECT ossweb_resource_trylock([ossweb::sql::quote $rcs_type],
                                   [ossweb::sql::quote $rcs_name],
                                   [ossweb::sql::quote $rcs_start],
                                   [ossweb::sql::quote $rcs_end],
                                   [ossweb::sql::quote $rcs_data],
                                   [ossweb::sql::quote $rcs_user])
  </sql>
</query>

<query name="ossweb.resource.unlock">
  <description>
  </description>
  <sql>
    SELECT ossweb_resource_unlock([ossweb::sql::quote $rcs_id int],
                                  [ossweb::sql::quote $rcs_type],
                                  [ossweb::sql::quote $rcs_name],
                                  [ossweb::sql::quote $rcs_start],
                                  [ossweb::sql::quote $rcs_end])
  </sql>
</query>

<query name="ossweb.resource.check">
  <description>
   Returns id specified resource cannot be reserved
  </description>
  <sql>
    SELECT ossweb_resource_check([ossweb::sql::quote $rcs_type],[ossweb::sql::quote $rcs_name],[ossweb::sql::quote $rcs_start],[ossweb::sql::quote $rcs_end])
  </sql>
</query>

<query name="ossweb.resource.list">
  <description>
    Read list of resources
  </description>
  <sql>
    SELECT rcs_id,
           rcs_name,
           rcs_type,
           rcs_start,
           rcs_end,
           rcs_data
    FROM ossweb_resources
    [ossweb::sql::filter \
          { rcs_id ilist ""
            rcs_type list ""
            rcs_name "" ""
            rcs_start datetime ""
            rcs_end datetime "" } \
          -where WHERE \
          -map { rsc_start "rcs_start >= '%value'"
                 rcs_end ""rcs_end <= '%value'" }]
    ORDER BY rcs_type,
             rcs_start
  </sql>
</query>

</xql>
