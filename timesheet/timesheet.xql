
<query name="timesheet.create">
  <description>
  </description>
  <sql>
    INSERT INTO ts_timesheets
    [ossweb::sql::insert_values -full t \
          { ts_date "" ""
            ts_time "" ""
            user_id int {ossweb::conn user_id}
            costcode_id "" ""
            hour_code "" "R"
            job_id int ""
            hours "" "" }]
  </sql>
</query>

<query name="timesheet.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ts_timesheets WHERE ts_id=$ts_id
  </sql>
</query>

<query name="timesheet.read.user">
  <description>
    Read user name
  </description>
  <sql>
    SELECT first_name||' '||last_name as user_name,
           department
    FROM ossweb_users 
    WHERE user_id=$user_id
  </sql>
</query>

<query name="timesheet.read.day">
  <description>
  </description>
  <sql>
    SELECT ts_id,
           type_name,
           hour_code,
           job_name||'  ('||j.job_no||COALESCE(','||j.subjob_no,'')||')' AS job_name,
           costcode_code||'  ('||COALESCE(c.costcode_name||',','')||c.costcode_type||')' AS costcode_name,
           EXTRACT(hour FROM ts_time)||':'||EXTRACT(minute FROM ts_time) AS ts_time,
           EXTRACT(hour FROM hours) AS hours
    FROM ts_timesheets h,
         ts_hour_types ht,
         ts_costcodes c,
         ts_jobs j
    WHERE h.user_id=$user_id AND
          h.ts_date='$ts_date' AND
          h.hour_code=ht.type_id AND
          h.costcode_id=c.costcode_id AND
          h.job_id=j.job_id
    ORDER BY j.job_no,
             j.subjob_no
  </sql>
</query>

<query name="timesheet.read.week">
  <description>
  </description>
  <sql>
    SELECT EXTRACT(dow FROM t.ts_date) AS dow,
           t.ts_id,
           t.hour_code,
           ht.type_name,
           job_name||'  ('||j.job_no||COALESCE(','||j.subjob_no,'')||')' AS job_name,
           costcode_code||'  ('||COALESCE(c.costcode_name||',','')||c.costcode_type||')' AS costcode_name,
           EXTRACT(hour FROM ts_time)||':'||EXTRACT(minute FROM ts_time) AS ts_time,
           EXTRACT(hour FROM hours) AS hours
    FROM ts_timesheets t
         LEFT OUTER JOIN ts_hour_types ht
           ON t.hour_code=ht.type_id
         LEFT OUTER JOIN ts_costcodes c
           ON t.costcode_id=c.costcode_id
         LEFT OUTER JOIN ts_jobs j
           ON t.job_id=j.job_id
    WHERE t.user_id=$user_id AND
          t.ts_date IN ([ossweb::sql::list $week])
    ORDER BY t.ts_date,
             t.job_id
  </sql>
</query>

<query name="timesheet.costcode.list">
  <description>
  </description>
  <sql>
    SELECT job_id,
           costcode_id,
           costcode_code||COALESCE('-'||costcode_name,'') AS costcode_name
    FROM ts_costcodes 
    ORDER by costcode_code
  </sql>
</query>

<query name="timesheet.hour_type.list">
  <description>
  </description>
  <sql>
    SELECT type_name,type_id FROM ts_hour_types ORDER BY type_id
  </sql>
</query>

<query name="timesheet.job.list">
  <description>
  </description>
  <sql>
    SELECT job_name||'  ('||job_no||COALESCE('/'||subjob_no,'')||')',job_id
    FROM ts_jobs
    ORDER BY job_no,
             subjob_no
  </sql>
</query>
