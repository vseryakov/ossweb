<?xml version="1.0"?>

<xql>

<query name="calendar.create">
  <description>
    Create calendar record
  </description>
  <sql>
    INSERT INTO ossweb_calendar
    [ossweb::sql::insert_values -full t \
               { user_id int ""
                 cal_date "" ""
                 cal_time "" ""
                 cal_owner int ""
                 duration "" ""
                 remind "" ""
                 remind_type "" ""
                 remind_email "" ""
                 remind_proc "" ""
                 remind_args "" ""
                 repeat "" ""
                 type "" ""
                 subject "" ""
                 description "" ""
                 update_user const {[ossweb::conn user_id]} }]
  </sql>
</query>

<query name="calendar.update">
  <description>
    Update calendar record
  </description>
  <sql>
    UPDATE ossweb_calendar
    SET [ossweb::sql::update_values -skip_null $skip_null \
              { cal_time "" ""
                cal_date "" ""
                cal_owner int ""
                duration "" ""
                remind "" ""
                remind_type "" ""
                remind_proc "" ""
                remind_email "" ""
                remind_args "" ""
                repeat "" ""
                type "" ""
                subject "" ""
                description "" ""
                update_user const {[ossweb::conn user_id]} }]
    WHERE cal_id=$cal_id AND
          user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="calendar.delete.user">
  <description>
    Delete calendar record
  </description>
  <sql>
    DELETE FROM ossweb_calendar WHERE cal_id=$cal_id AND user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="calendar.delete">
  <description>
    Delete calendar record
  </description>
  <sql>
    DELETE FROM ossweb_calendar WHERE cal_id=$cal_id
  </sql>
</query>

<query name="calendar.read">
  <description>
    Read one entry for the day
  </description>
  <sql>
    SELECT user_id,
           cal_date,
           cal_time,
           cal_owner,
           CASE WHEN EXTRACT(day FROM duration) > 0 THEN
                EXTRACT(day FROM duration)||' day'||
                CASE WHEN EXTRACT(day FROM duration) > 1 THEN 's ' ELSE ' ' END
                ELSE '' END||
           CASE WHEN EXTRACT(hour FROM duration) > 0 THEN
                EXTRACT(hour FROM duration)||' hour'||
                CASE WHEN EXTRACT(hour FROM duration) > 1 THEN 's' ELSE '' END
                ELSE ''
           END AS duration,
           remind,
           EXTRACT(EPOCH FROM remind) AS remind_seconds,
           remind_type,
           remind_email,
           remind_proc,
           remind_args,
           repeat,
           type,
           subject,
           description,
           update_user,
           TO_CHAR(update_time,'MM/DD/YY HH24:MI') AS update_time,
           ossweb_user_name(user_id) as user_name,
           ossweb_user_name(update_user) as update_user_name
    FROM ossweb_calendar c
    WHERE c.cal_id=$cal_id AND
          (c.user_id = [ossweb::conn user_id -1] OR
           (c.user_id != [ossweb::conn user_id -1] AND
            c.type != 'Private'))
  </sql>
</query>

<query name="calendar.read.day">
  <description>
    Read calendar entries for the given day
  </description>
  <sql>
    SELECT cal_id,
           subject,
           TO_CHAR(cal_date,'MM/DD/YYYY') AS cal_date,
           TO_CHAR(cal_time,'HH24:MI') AS time,
           CASE WHEN EXTRACT(day FROM duration) > 0 THEN
                EXTRACT(day FROM duration)||' day'||
                CASE WHEN EXTRACT(day FROM duration) > 1 THEN 's ' ELSE ' ' END
                ELSE '' END||
           CASE WHEN EXTRACT(hour FROM duration) > 0 THEN
                EXTRACT(hour FROM duration)||' hour'||
                CASE WHEN EXTRACT(hour FROM duration) > 1 THEN 's' ELSE '' END
                ELSE ''
           END AS duration,
           repeat,
           description
    FROM ossweb_calendar
    WHERE (user_id IN ([ossweb::sql::list [ossweb::nvl $user_id -1] int]) OR type='Public') AND
          (cal_date = '$Year-$Month-$Day' OR
           cal_date BETWEEN '$Year-$Month-$Day'::DATE-COALESCE(duration,'0 sec') AND '$Year-$Month-$Day' OR
           (cal_date <= '$Year-$Month-$Day' AND
            ((repeat IN ('Daily') AND $Dow NOT IN (0,6)) OR
             (repeat IN ('Yearly','Monthly') AND EXTRACT(day FROM cal_date)=$Day) OR
             (repeat IN ('Weekly') AND EXTRACT(dow FROM cal_date)=$Dow))))
    ORDER BY cal_time
  </sql>
</query>

<query name="calendar.read.month">
  <description>
    Read calendar entries for the given month
  </description>
  <sql>
    SELECT cal_id,
           subject,
           TO_CHAR(cal_date,'MM/DD/YYYY') AS cal_date,
           TO_CHAR(cal_time,'HH24:MI') AS cal_time,
           EXTRACT(day FROM duration) AS duration,
           repeat
    FROM ossweb_calendar
    WHERE (user_id IN ([ossweb::sql::list [ossweb::nvl $user_id -1] int]) OR type='Public') AND
          (cal_date BETWEEN '$Year-$Month-1' AND '$Year-$Month-$Days' OR
           cal_date BETWEEN '$Year-$Month-1'::DATE-COALESCE(duration,'0 sec') AND '$Year-$Month-$Days' OR
           (cal_date <= '$Year-$Month-1' AND
            ((repeat IN ('Monthly','Weekly','Daily') OR
             (repeat IN ('Yearly') AND EXTRACT(month FROM cal_date)=$Month)))))
    ORDER BY cal_time
  </sql>
</query>

<query name="calendar.remind.list">
  <description>
    Retrieves pending calendar reminders
  </description>
  <sql>
    SELECT user_id,
           cal_id,
           (NOW()+remind)::DATE AS cal_date,
           cal_time,
           cal_owner,
           subject,
           description,
           duration,
           repeat,
           remind,
           remind_type,
           remind_email,
           remind_proc,
           remind_args,
           ossweb_user_email(user_id) AS user_email
    FROM ossweb_calendar c
    WHERE remind IS NOT NULL AND
          CURRENT_TIME BETWEEN cal_time-remind-'5 mins'::INTERVAL AND cal_time AND
          (((cal_date = CURRENT_DATE OR cal_date+cal_time-remind = CURRENT_DATE) AND
            repeat IN ('None')) OR
           (cal_date < CURRENT_DATE AND
            (repeat IN ('Daily') AND EXTRACT(dow FROM NOW()) NOT IN (0,6)) OR
            (repeat IN ('Yearly','Monthly') AND EXTRACT(day FROM cal_date)=EXTRACT(day FROM NOW())) OR
            (repeat IN ('Weekly') AND EXTRACT(dow FROM cal_date)=EXTRACT(dow FROM NOW())))) AND
          NOT EXISTS(SELECT cal_id
                     FROM ossweb_calendar_reminders cr
                     WHERE cr.cal_id=c.cal_id AND
                           cr.cal_time=c.cal_time AND
                           cr.user_id=c.user_id AND
                           cr.cal_date+cr.cal_time BETWEEN
                           CURRENT_DATE+cal_time-remind-'5 mins'::INTERVAL AND CURRENT_DATE+cal_time)
         ORDER BY cal_time
  </sql>
</query>

<query name="calendar.remind.create">
  <description>
    Marks sent calendar reminder
  </description>
  <sql>
    INSERT INTO ossweb_calendar_reminders (cal_id,cal_date,cal_time,user_id)
    VALUES($cal_id,NOW()::DATE,'$cal_time',$user_id)
  </sql>
</query>

<query name="calendar.tracker.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossweb_calendar_tracker
    [ossweb::sql::insert_values -full t \
          { tracker_id "" ""
            tracker_type "" ""
            tracker_key "" ""
            tracker_time "" ""
            tracker_redirect "" ""
            tracker_interval "" "1 min"
            cal_id int ""
            user_id int ""
            precedence int "" } ]
  </sql>
</query>

<query name="calendar.tracker.update.status">
  <description>
  </description>
  <sql>
    UPDATE ossweb_calendar_tracker
    SET status='$status',
        send_time=CASE WHEN '$status' = 'Sent' THEN NOW() ELSE send_time END,
        update_time=NOW()
    WHERE tracker_id='$tracker_id'
  </sql>
</query>

<query name="calendar.tracker.update.unused">
  <description>
  </description>
  <sql>
    UPDATE ossweb_calendar_tracker
    SET status='Unused',
        update_time=NOW()
    WHERE cal_id=$cal_id AND
          status='New'
  </sql>
</query>

<query name="calendar.tracker.update.precedence">
  <description>
  </description>
  <sql>
    UPDATE ossweb_calendar_tracker
    SET precedence=precedence-1,
        update_time=NOW()
    WHERE cal_id=$cal_id AND
          status='New'
  </sql>
</query>

<query name="calendar.tracker.read">
  <description>
  </description>
  <sql>
    SELECT t.tracker_id,
           t.tracker_type,
           t.tracker_key,
           t.tracker_redirect,
           t.tracker_interval,
           t.tracker_time,
           t.create_time,
           t.send_time,
           t.update_time,
           t.precedence,
           t.status,
           t.user_id,
           c.cal_id,
           c.cal_date,
           c.cal_time,
           ossweb_user_email(t.user_id) AS user_email,
           c.subject,
           c.description
    FROM ossweb_calendar_tracker t,
         ossweb_calendar c
    WHERE c.cal_id=t.cal_id AND
          t.tracker_id='$tracker_id'
  </sql>
</query>

<query name="calendar.tracker.accepted">
  <description>
  </description>
  <vars>
   tracker_last 0
   tracker_key ""
   cal_id -1
  </vars>
  <sql>
    SELECT 1
    FROM ossweb_calendar_tracker
    WHERE status='Accepted' AND
          [ossweb::iftrue { $tracker_last != 0 } {
            cal_id=(SELECT MAX(cal_id) FROM ossweb_calendar_tracker WHERE tracker_key=[ossweb::sql::quote $tracker_key])
          } {
            cal_id=$cal_id
          }]
    LIMIT 1
  </sql>
</query>

<query name="calendar.tracker.list">
  <description>
   Make adjustment on how often tracker proc is running, if every 2 mins, then add 1 min
  </description>
  <sql>
    SELECT t.tracker_id,
           t.create_time,
           t.tracker_redirect,
           t.tracker_interval,
           t.tracker_time,
           t.send_time,
           t.update_time,
           t.precedence,
           t.status,
           t.user_id,
           c.cal_id,
           c.cal_date,
           c.cal_time,
           ossweb_user_email(t.user_id) AS user_email,
           c.subject,
           c.description
    FROM ossweb_calendar_tracker t,
         ossweb_calendar c
    WHERE c.cal_id=t.cal_id AND
          t.status='New' AND
          c.cal_date+c.cal_time >= NOW() AND
          t.create_time+t.tracker_interval*t.precedence+CASE WHEN t.precedence > 0 THEN '1 min'::INTERVAL ELSE '0 min'::INTERVAL END <= NOW()
    ORDER BY precedence
  </sql>
</query>

</xql>
