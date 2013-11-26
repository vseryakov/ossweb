<?xml version="1.0"?>

<xql>

<query name="problem.tree">
  <description>
  </description>
  <vars>
  </vars>
  <sql>
    SELECT 0 AS type,
           project_id AS id,
           project_name AS name,
           NULL AS owner,
           NULL AS status,
           NULL AS update_date,
           NULL AS percent_completed,
           NULL AS due_date
    FROM problem_projects
    WHERE problem_project_avail(project_id,[ossweb::conn user_id -1]) AND
          str_lexists('[ossweb::conn problem_projects]',project_id) AND
          status='active'
    UNION ALL
    SELECT 1 AS type,
           problem_id AS id,
           title AS name,
           project_id AS owner,
           state_machine_name('problem',problem_status) AS status,
           TO_CHAR(update_date,'YYYY-MM-DD') AS update_date,
           p.percent_completed,
           TO_CHAR(due_date,'YYYY-MM-DD') AS due_date
    FROM problems p
    WHERE problem_project_avail(project_id,[ossweb::conn user_id -1]) AND
          str_lexists('[ossweb::conn problem_projects]',project_id) AND
          problem_status IN ('open','inprogress','pending')
    ORDER BY type,
             due_date,
             id
  </sql>
</query>

<query name="problem.search1">
  <description>
   First part of problem search
  </description>
  <vars>
   problem_columns ""
   problem_limit 9999
   problem_sort "p.due_date"
  </vars>
  <sql>
    SELECT problem_id
           [ossweb::iftrue { $problem_columns == "" } {} { ,[join $problem_columns ,] }]
    FROM problems p,
         ossweb_users u,
         problem_projects r,
         problem_types t,
         ossweb_state_machine s
    WHERE str_lexists('[ossweb::conn problem_projects]',p.project_id) AND
          p.user_id=u.user_id AND
          p.project_id=r.project_id AND
          p.problem_type=t.type_id AND
          p.problem_status=s.status_id AND
          module='problem' AND
          (p.user_id = [ossweb::conn user_id -1] OR problem_project_avail(p.project_id,[ossweb::conn user_id -1]))
    [ossweb::sql::filter \
          { problem_id "" ""
            user_id ilist ""
            owner_id ilist ""
            belong_id ilist ""
            project_id ilist ""
            problem_type list ""
            problem_status list ""
            unassigned_flag int ""
            problem_tags tsearch ""
            priority "" ""
            severity "" ""
            create_date date ""
            due_date date ""
            title Text ""
            description Text ""
            close_on_complete "" "" } \
          -map { problem_tags "problem_tags_idx @@ %value"
                 belong_id "(p.owner_id IN (%value) OR (EXISTS(SELECT 1 FROM problem_users u WHERE p.project_id=u.project_id AND u.user_id IN (%value))))"
                 unassigned_flag "(p.owner_id=[ossweb::conn user_id -1] OR p.owner_id IS NULL)"
                 owner_id "((-1 IN (%value) AND p.owner_id IS NULL) OR p.owner_id IN (%value))" } \
          -alias "p." \
          -before AND]
    ORDER BY $problem_sort
    LIMIT $problem_limit
  </sql>
</query>

<query name="problem.search2">
  <description>
    Second part of problem search
  </description>
  <vars>
   problem_sort "p.due_date"
  </vars>
  <sql>
    SELECT p.problem_id,
           p.project_id,
           p.problem_type,
           p.problem_status,
           p.problem_tags,
           TO_CHAR(p.create_date,'MM/DD/YYYY') AS create_date,
           TO_CHAR(p.update_date,'MM/DD/YYYY HH24:MI') AS update_date,
           ROUND(EXTRACT(EPOCH FROM (NOW() - update_date))) AS update_time,
           TO_CHAR(p.due_date,'MM/DD/YYYY') AS due_date,
           (SELECT priority_name FROM problem_priorities WHERE priority_id=priority) AS priority_name,
           (SELECT severity_name FROM problem_severities WHERE severity_id=severity) AS severity_name,
           p.priority,
           p.severity,
           p.title,
           p.description,
           p.user_id,
           p.owner_id,
           p.percent_completed,
           r.project_name,
           p.cal_id,
           TO_CHAR(p.cal_date,'MM/DD/YYYY HH24:MI') AS cal_date,
           p.cal_repeat,
           t.type_name AS problem_type_name,
           state_machine_name('problem',problem_status) AS problem_status_name,
           u.first_name||' '||u.last_name AS user_name,
           u2.first_name||' '||u2.last_name AS owner_name,
           problem_notes_count(p.problem_id,[ossweb::conn user_id -1]) AS count,
           (SELECT COUNT(*) FROM problem_files f WHERE f.problem_id=p.problem_id) AS file_count,
           CASE WHEN problem_status <> 'closed' THEN NOW() > due_date ELSE 'f' END AS overdue,
           last_note_text,
           last_note_id
    FROM problems p
         LEFT OUTER JOIN ossweb_users u2
           ON p.owner_id=u2.user_id,
         ossweb_users u,
         problem_projects r,
         problem_types t,
         ossweb_state_machine s
    WHERE p.user_id=u.user_id AND
          p.project_id=r.project_id AND
          p.problem_type=t.type_id AND
          p.problem_status=s.status_id AND
          s.module='problem' AND
          problem_id in (CURRENT_PAGE_SET)
    ORDER BY $problem_sort
  </sql>
</query>

<query name="problem.create">
  <description>
    Create problem record
  </description>
  <sql>
    INSERT INTO problems
    [ossweb::sql::insert_values -full t \
          { project_id int ""
            problem_type "" ""
            problem_status "" ""
            priority "" ""
            severity "" ""
            due_date datetime ""
            title "" ""
            description "" ""
            owner_id int ""
            problem_cc "" ""
            close_on_complete boolean ""
            alert_on_complete boolean ""
            hours_required float ""
            user_id const {[ossweb::conn user_id 0]} }]
  </sql>
</query>

<query name="problem.update">
  <description>
    Update problem record
  </description>
  <sql>
    UPDATE problems
    SET [ossweb::sql::update_values -skip_null t \
              { problem_id int ""
                project_id int ""
                problem_type "" ""
                problem_status "" ""
                priority "" ""
                severity "" ""
                due_date date ""
                problem_cc "" ""
                problem_tags "" ""
                title "" ""
                owner_id int ""
                cal_date datetime ""
                cal_repeat "" ""
                hours_required float ""
                last_note_date datetime ""
                last_note_text "" ""
                close_on_complete boolean ""
                alert_on_complete boolean "" }]
    WHERE problem_id=$problem_id AND
          str_lexists('[ossweb::conn problem_projects]',project_id) AND
          (user_id = [ossweb::conn user_id -1] OR problem_project_avail(project_id,[ossweb::conn user_id -1]))
  </sql>
</query>

<query name="problem.delete">
  <description>
    Delete problem record
  </description>
  <sql>
    DELETE FROM problems
    WHERE problem_id=$problem_id AND
          str_lexists('[ossweb::conn problem_projects]',project_id) AND
          problem_project_avail(project_id,[ossweb::conn user_id -1])
  </sql>
</query>

<query name="problem.reopen">
  <description>
    Re-opens problem
  </description>
  <sql>
    SELECT problems_reopen($problem_id)
  </sql>
</query>

<query name="problem.email">
  <description>
    Delete problem record
  </description>
  <sql>
    SELECT problem_email($problem_id,[ossweb::conn user_id 0],NULL,[ossweb::sql::quote $problem_cc],[ossweb::sql::quote $quiet_flag]);
  </sql>
</query>

<query name="problem.email">
  <description>
  </description>
  <sql>
    SELECT problem_email([ossweb::sql::insert_values -skip_null f \
                               { problem_id int ""
                                 user_id int {[ossweb::conn user_id]}
                                 description "" ""
                                 problem_cc "" ""
                                 quiet_flag boolean "" }])
  </sql>
</query>

<query name="problem.read">
  <description>
    Read problem record
  </description>
  <sql>
    SELECT t.problem_id,
           t.user_id,
           t.owner_id,
           t.project_id,
           t.problem_status,
           t.problem_type,
           t.problem_tags,
           problem_cc,
           state_machine_name('problem',problem_status) AS problem_status_name,
           type_name AS problem_type_name,
           TO_CHAR(t.create_date,'MM/DD/YYYY HH24:MI') AS create_date,
           TO_CHAR(t.update_date,'MM/DD/YYYY HH24:MI') AS update_date,
           due_date,
           COALESCE(hours_required,0) AS hours_required,
           percent_completed,
           t.priority,
           t.severity,
           t.title,
           t.description,
           t.close_on_complete,
           t.alert_on_complete,
           problem_files(t.problem_id,NULL) AS files,
           t.cal_id,
           TO_CHAR(t.cal_date,'MM/DD/YYYY HH24:MI') AS cal_date,
           t.cal_repeat,
           p.project_name,
           p.owner_id AS project_owner_id,
           ossweb_user_name(t.user_id) AS user_name,
           ossweb_user_name(t.owner_id) AS owner_name,
           problem_users(t.problem_id) AS owner_users
    FROM problems t,
         problem_projects p,
         problem_types pt
    WHERE str_lexists('[ossweb::conn problem_projects]',t.project_id) AND
          t.project_id=p.project_id AND
          t.problem_type=pt.type_id AND
          t.problem_id=$problem_id AND
          (p.user_id = [ossweb::conn user_id -1] OR problem_project_avail(t.project_id,[ossweb::conn user_id -1]))
  </sql>
</query>

<query name="problem.check">
  <description>
    Check problem record
  </description>
  <sql>
    SELECT CASE WHEN user_id = [ossweb::conn user_id -1] THEN 't'
                ELSE problem_project_avail(project_id,[ossweb::conn user_id -1]) AND
                     str_lexists('[ossweb::conn problem_projects]',project_id)
           END
    FROM problems
    WHERE problem_id=$problem_id
  </sql>
</query>

<query name="problem.merge.notes">
  <description>
    Merge problem notes
  </description>
  <sql>
    UPDATE problem_notes
    SET problem_id=$problem_id
    WHERE problem_id in ([ossweb::sql::list $merge_id]) AND
          problem_status IN ('open','inprogress') AND
          EXISTS(SELECT 1
                 FROM problems p,
                      problem_projects r
                 WHERE p.project_id=r.project_id AND
                       problem_notes.problem_id=p.problem_id AND
                       r.owner_id=[ossweb::conn user_id -1])
  </sql>
</query>

<query name="problem.merge.files">
  <description>
    Merge problem notes
  </description>
  <sql>
    UPDATE problem_files
    SET problem_id=$problem_id
    WHERE problem_id in ([ossweb::sql::list $merge_id]) AND
          EXISTS(SELECT 1
                 FROM problems p,
                      problem_projects r
                 WHERE p.project_id=r.project_id AND
                       problem_files.problem_id=p.problem_id AND
                       r.owner_id=[ossweb::conn user_id -1])
  </sql>
</query>

<query name="problem.merge.problems">
  <description>
    Merge problems
  </description>
  <sql>
    UPDATE problems
    SET problem_status='cancelled'
    WHERE problem_id in ([ossweb::sql::list $merge_id]) AND
          problem_status IN ('open','inprogress') AND
          EXISTS(SELECT 1
                 FROM problems p,
                      problem_projects r
                 WHERE p.project_id=r.project_id AND
                       problem_files.problem_id=p.problem_id AND
                       r.owner_id=[ossweb::conn user_id -1])
  </sql>
</query>

<query name="problem.close_all_completed">
  <description>
    Close all completed problems
  </description>
  <sql>
    UPDATE problems
    SET problem_status='closed'
    WHERE problem_status='completed' AND
          problem_project_avail(project_id,[ossweb::conn user_id -1])
          [ossweb::sql::filter \
                { problem_id int ""
                  user_id ilist ""
                  owner_id ilist ""
                  project_id ilist ""
                  problem_type list ""
                  problem_status list ""
                  priority "" ""
                  severity "" ""
                  create_date date ""
                  due_date date ""
                  title Text ""
                  description Text ""
                  close_on_complete "" "" } \
                 -before "AND"]
  </sql>
</query>

<query name="problem.type.select.read">
  <description>
    Read problem types
  </description>
  <sql>
    SELECT type_name,type_id
    FROM problem_types
    ORDER BY precedence,
             type_name
  </sql>
</query>

<query name="problem.project_status.select.read">
  <description>
    Read problem project status
  </description>
  <sql>
    SELECT status_name,
           status_id
    FROM ossweb_state_machine
    WHERE module='problem:project'
    ORDER BY sort,
             status_name
  </sql>
</query>

<query name="problem.status.select.read">
  <description>
    Read problem status states
  </description>
  <vars>
   type_filter ""
  </vars>
  <sql>
    SELECT status_name,
           status_id
    FROM ossweb_state_machine
    WHERE module='problem'
          $type_filter
    ORDER BY sort,
             status_name
  </sql>
</query>

<query name="problem.status.allowed.read">
  <description>
    Read problem status states
  </description>
  <sql>
    SELECT state_machine_next('problem','$problem_status',TRUE)
  </sql>
</query>

<query name="problem.status.select.read_new">
  <description>
    Read problem status for new record
  </description>
  <sql>
    SELECT status_name,status_id
    FROM ossweb_state_machine
    WHERE type IN ('open') AND
          module='problem'
    ORDER BY status_name
  </sql>
</query>

<query name="problem.notes.create">
  <description>
    Create problem note record
  </description>
  <sql>
    INSERT INTO problem_notes
    [ossweb::sql::insert_values -full t \
          { problem_id int ""
            problem_status "" ""
            description "" ""
            user_id int {[ossweb::conn user_id 0]}
            owner_id int ""
            hours float ""
            percent float ""
            svn_file "" ""
            svn_revision int "" }]
  </sql>
</query>

<query name="problem.notes.update">
  <description>
    Update problem note record
  </description>
  <sql>
    UPDATE problem_notes
    SET [ossweb::sql::update_values -skip_null t \
          { problem_status "" ""
            description "" ""
            hours float ""
            owner_id int ""
            percent float ""
            svn_file "" ""
            svn_revision int "" }]
    WHERE user_id=[ossweb::conn user_id -1] AND
          problem_id=$problem_id AND
          problem_note_id=$problem_note_id
  </sql>
</query>

<query name="problem.notes.delete">
  <description>
    Delete problem note record
  </description>
  <sql>
    DELETE FROM problem_notes
    WHERE user_id=[ossweb::conn user_id -1] AND
          problem_id=$problem_id AND
          problem_note_id=$problem_note_id
  </sql>
</query>

<query name="problem.notes.read">
  <description>
  </description>
  <sql>
    SELECT problem_status,
           TO_CHAR(create_date,'YYYY-MM-DD HH24:MI') AS create_date,
           description,
           hours,
           percent
    FROM problem_notes
    WHERE problem_id=$problem_id AND
          problem_note_id=$problem_note_id
  </sql>
</query>

<query name="problem.notes.read_all">
  <description>
  </description>
  <vars>
   problem_note_sort b.create_date
  </vars>
  <sql>
    SELECT problem_note_id,
           u.first_name||' '||u.last_name AS user_name,
           state_machine_name('problem',b.problem_status) AS status_name,
           TO_CHAR(b.create_date,'MM/DD/YY HH24:MI') AS create_date,
           b.description,
           b.hours,
           b.percent,
           b.user_id,
           b.svn_file,
           b.svn_revision,
           problem_files(problem_id,problem_note_id) AS files
    FROM problem_notes b,
         ossweb_users u
    WHERE problem_id=$problem_id AND
          b.user_id=u.user_id
    ORDER BY $problem_note_sort
  </sql>
</query>

<query name="problem.user.select.read">
  <description>
  </description>
  <sql>
    SELECT first_name||' '||last_name,
           u.user_id
    FROM ossweb_users u,
         ossweb_groups g,
         ossweb_user_groups ug
    WHERE (g.group_name='problem' OR g.short_name='problem') AND
          g.group_id=ug.group_id AND
          ug.user_id=u.user_id AND
          u.status='active'
    ORDER BY 1
  </sql>
</query>

<query name="problem.user.select.by.problem">
  <description>
    Read all users for specified project
  </description>
  <sql>
    SELECT first_name||' '||last_name,
           u.user_id
    FROM ossweb_users u,
         ossweb_groups g,
         ossweb_user_groups ug,
         problem_users pu,
         problems p
    WHERE (g.group_name='problem' OR g.short_name='problem') AND
          g.group_id=ug.group_id AND
          ug.user_id=u.user_id AND
          u.user_id=pu.user_id AND
          p.problem_id=$problem_id AND
          p.project_id=pu.project_id AND
          u.status='active'
    ORDER BY pu.precedence DESC,1
  </sql>
</query>

<query name="problem.user.select.by.project">
  <description>
    Read problem users for select box
  </description>
  <sql>
    SELECT first_name||' '||last_name,
           u.user_id
    FROM ossweb_users u,
         ossweb_groups g,
         ossweb_user_groups ug,
         problem_users pu
    WHERE (g.group_name='problem' OR g.short_name='problem') AND
          g.group_id=ug.group_id AND
          ug.user_id=u.user_id AND
          u.status='active' AND
          pu.project_id=$project_id AND
          pu.user_id=u.user_id
    ORDER BY pu.precedence DESC,1
  </sql>
</query>

<query name="problem.user.select.allowed">
  <description>
    Read problem users for select box
  </description>
  <sql>
    SELECT DISTINCT
           first_name||' '||last_name,
           u.user_id,
           pu.precedence
    FROM ossweb_users u,
         ossweb_groups g,
         ossweb_user_groups ug,
         problem_users pu
    WHERE (g.group_name='problem' OR g.short_name='problem') AND
          g.group_id=ug.group_id AND
          u.status='active' AND
          ug.user_id=u.user_id AND
          ug.user_id=pu.user_id AND
          problem_project_avail(pu.project_id,[ossweb::conn user_id -1]) AND
          str_lexists('[ossweb::conn problem_projects]',pu.project_id)
    ORDER BY pu.precedence DESC,1
  </sql>
</query>

<query name="problem.user.read_all">
  <description>
    Read all problem users
  </description>
  <sql>
    SELECT p.user_id,
           ossweb_user_name(p.user_id) AS user_name,
           precedence,
           role
    FROM problem_users p
    WHERE project_id=$project_id
    ORDER BY p.precedence DESC,2
  </sql>
</query>

<query name="problem.user.create">
  <description>
    Create problem user record
  </description>
  <sql>
    INSERT INTO problem_users
    [ossweb::sql::insert_values -full t \
          { project_id int ""
            precedence int NULL
            role "" ""
            user_id int "" }]
  </sql>
</query>

<query name="problem.user.delete.projects">
  <description>
    Delete all user records for problem project
  </description>
  <sql>
    DELETE FROM problem_users WHERE user_id=$user_id
  </sql>
</query>

<query name="problem.user.delete">
  <description>
    Delete problem user record
  </description>
  <sql>
    DELETE FROM problem_users
    WHERE project_id=$project_id AND
          user_id=$user_id
  </sql>
</query>

<query name="problem.project.owner">
  <description>
    Returns owner of the project for the problem
  </description>
  <sql>
    SELECT r.owner_id
    FROM problems p,
         problem_projects r
    WHERE p.project_id=r.project_id AND
          p.problem_id=$problem_id
  </sql>
</query>

<query name="problem.project.check">
  <description>
    Check project
  </description>
  <sql>
    SELECT problem_project_avail($project_id,[ossweb::conn user_id -1]) AND
           str_lexists('[ossweb::conn problem_projects]',$project_id)
  </sql>
</query>

<query name="problem.project.create">
  <description>
    Create problem project record
  </description>
  <sql>
    INSERT INTO problem_projects
    [ossweb::sql::insert_values -full t \
          { project_name "" ""
            status "" ""
            type "" ""
            owner_id int ""
            problem_type "" ""
            email_on_update boolean ""
            description "" ""
            app_name "" ""
            user_id const {[ossweb::conn user_id]} }]
  </sql>
</query>

<query name="problem.project.update">
  <description>
    Update problem project record
  </description>
  <sql>
    UPDATE problem_projects
    SET [ossweb::sql::update_values \
              { project_name "" ""
                status "" ""
                type "" ""
                owner_id int ""
                problem_type "" ""
                email_on_update boolean ""
                description "" ""
                app_name "" ""
                user_id const {[ossweb::conn user_id]} }]
    WHERE project_id=$project_id
  </sql>
</query>

<query name="problem.project.select.read">
  <description>
    Read problem projects
  </description>
  <sql>
    SELECT project_name,
           project_id
    FROM problem_projects p
    WHERE status IN ('active') AND
          problem_project_avail(project_id,[ossweb::conn user_id -1]) AND
          str_lexists('[ossweb::conn problem_projects]',project_id)
    ORDER BY project_name
  </sql>
</query>

<query name="problem.project.select.all">
  <description>
    Read problem projects
  </description>
  <sql>
    SELECT p.project_name||'('||type||')' AS project_name,
           p.project_id
    FROM problem_projects p
    WHERE status IN ('active')
    ORDER BY project_name
  </sql>
</query>

<query name="problem.project.read.by.app_name">
  <description>
    Read problem projects
  </description>
  <sql>
    SELECT project_id
    FROM problem_projects
    WHERE [ossweb::sql::quote $app_name] ~* app_name AND
          str_lexists('[ossweb::conn problem_projects]',project_id)
    LIMIT 1
  </sql>
</query>

<query name="problem.project.read.by.user">
  <description>
    Read problem projects by user
  </description>
  <sql>
    SELECT p.project_name,
           p.project_id,
           p.owner_id,
           p.type
    FROM problem_projects p,
         problem_users u
    WHERE status IN ('active') AND
          u.user_id=$user_id AND
          u.project_id=p.project_id
    ORDER BY project_name
  </sql>
</query>

<query name="problem.project.delete">
  <description>
    Delete project record
  </description>
  <sql>
    DELETE FROM problem_projects WHERE project_id=$project_id
  </sql>
</query>

<query name="problem.project.delete.users">
  <description>
    Delete all user records for problem project
  </description>
  <sql>
    DELETE FROM problem_users WHERE project_id=$project_id
  </sql>
</query>

<query name="problem.project.read_all">
  <description>
    Read all problem projects
  </description>
  <sql>
    SELECT p.project_name,
           p.project_id,
           p.status,
           p.type,
           p.problem_type,
           p.description,
           ossweb_user_name(p.owner_id) AS owner_name,
           pu.user_id,
           pu.role,
           ossweb_user_name(pu.user_id) AS user_name,
           s.status_name
    FROM problem_projects p
         LEFT OUTER JOIN problem_users pu
           ON p.project_id=pu.project_id,
         ossweb_state_machine s
    WHERE p.status=s.status_id AND
          s.module='problem:project'
          [ossweb::sql::filter \
                { project_name Text ""
                  status list ""
                  type list ""
                  user_name "" "" } \
                -aliasmap { p. p. p. } \
                -map { user_name "EXISTS(SELECT 1 FROM problem_users pu
                                         WHERE p.project_id=pu.project_id AND
                                               ossweb_user_name(user_id) ~* %value)" } \
                -before AND]
    ORDER BY project_name
  </sql>
</query>

<query name="problem.project.stats">
  <description>
  </description>
  <sql>
    SELECT s.status_name AS status,
           COUNT(*) AS count
    FROM problems p,
         ossweb_state_machine s
    WHERE project_id=$project_id AND
          problem_status=s.status_id AND
          s.module='problem'
    GROUP BY s.status_name
  </sql>
</query>

<query name="problem.project.read">
  <description>
  </description>
  <sql>
    SELECT project_name,
           project_id,
           app_name,
           status,
           type,
           owner_id,
           problem_type,
           email_on_update,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date,
           TO_CHAR(close_date,'MM/DD/YY HH24:MI') AS close_date,
           description
    FROM problem_projects
    WHERE project_id=$project_id
  </sql>
</query>

<query name="problem.file.create">
  <description>
    Create problem attachement record
  </description>
  <sql>
    INSERT INTO problem_files
    [ossweb::sql::insert_values -full t \
          { problem_id int ""
            problem_note_id int ""
            name "" "" }]
  </sql>
</query>

<query name="problem.file.update">
  <description>
    Update problem file with last note id
  </description>
  <sql>
    UPDATE problem_files
    SET [ossweb::sql::update_values \
              { problem_note_id int "" }]
    WHERE problem_id=$problem_id AND
          name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="problem.file.delete">
  <description>
    Delete file from a problem
  </description>
  <sql>
    DELETE FROM problem_files
    WHERE problem_id=$problem_id AND
          name=[ossweb::sql::quote [ns_queryget name]]
  </sql>
</query>

<query name="problem.schedule.report">
  <description>
    Produce reports
  </description>
  <sql>
    SELECT b.problem_id,
           b.owner_id,
           b.user_id,
           b.problem_status,
           b.problem_type,
           b.priority,
           b.severity,
           (SELECT priority_name FROM problem_priorities WHERE priority_id=priority) AS priority_name,
           (SELECT severity_name FROM problem_severities WHERE severity_id=severity) AS severity_name,
           b.title,
           b.description,
           p.project_name,
           s.status_name,
           u.user_email,
           ossweb_user_name(b.user_id) AS user_name,
           ossweb_user_name(b.owner_id) AS owner_name,
           problem_users(b.problem_id) AS problem_users,
           TO_CHAR(b.create_date,'MM/DD/YY HH24:MI') AS create_date,
           TO_CHAR(b.update_date,'MM/DD/YY HH24:MI') AS update_date,
           TO_CHAR(b.due_date,'MM/DD/YY') AS due_date,
           COALESCE((SELECT value FROM ossweb_prefs WHERE obj_id=u.user_id and obj_type='U' AND name='problem_wday'),'1') AS problem_wday,
           (SELECT count(*) FROM problem_notes n WHERE n.problem_id=b.problem_id) AS count,
           ((CASE WHEN s.type IN ('complete') THEN b.update_date ELSE NOW() END) > due_date) AS overdue
     FROM problems b,
          problem_projects p,
          ossweb_users u,
          ossweb_state_machine s
     WHERE b.project_id=p.project_id AND
           b.problem_status=s.status_id AND
           module='problem'
           [ossweb::sql::filter \
                 { unassigned_flag int ""
                   due_flag int ""
                   completed_flag int "" } \
                 -before AND \
                 -map { unassigned_flag "s.type IN ('open','work') AND b.owner_id IS NULL AND b.user_id=u.user_id"
                        due_flag "s.type IN ('open','work') AND b.owner_id=u.user_id AND NOW() + '1 day' >= due_date"
                        completed_flag "s.type IN ('complete') AND b.user_id=u.user_id" }]
     ORDER BY user_email,
              problem_type,
              project_name,
              status_name,
              severity,
              priority
  </sql>
</query>

<query name="problem.favorites.add">
  <description>
  </description>
  <sql>
   INSERT INTO problem_favorites
   [ossweb::sql::insert_values -full t \
         { owner int ""
           name "" ""
           filter "" ""
           user_id const {[ossweb::conn user_id 0]} }]
  </sql>
</query>

<query name="problem.favorites.delete">
  <description>
  </description>
  <sql>
   DELETE FROM problem_favorites
   WHERE owner=[ossweb::sql::quote $owner int] AND
         name=[ossweb::sql::quote $name] AND
         user_id=[ossweb::conn user_id 0]
  </sql>
</query>

<query name="problem.favorites.list">
  <description>
  </description>
  <sql>
   SELECT owner,
          name,
          filter,
          user_id,
          ossweb_user_name(user_id) AS user_name
   FROM problem_favorites
   WHERE owner IN (0,[ossweb::conn user_id 0])
   ORDER BY name
  </sql>
</query>

</xql>
