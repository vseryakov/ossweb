<?xml version="1.0"?>

<xql>

<query name="tvguide.needs.refresh">
  <description>
  </description>
  <sql>
    SELECT COALESCE(MAX(start_time) - NOW() < '2days'::INTERVAL,TRUE) FROM tvguide_schedules
  </sql>
</query>

<query name="tvguide.station.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_stations
    [ossweb::sql::insert_values -full t \
          { station_id int ""
            station_name "" ""
            station_label "" ""
            channel_id int ""
            affiliate "" "" }]
  </sql>
</query>

<query name="tvguide.station.read">
  <description>
  </description>
  <sql>
    SELECT station_id,
           station_name,
           station_label,
           affiliate
    FROM tvguide_stations
    WHERE station_id='$station_id'
  </sql>
</query>

<query name="tvguide.station.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_stations
  </sql>
</query>

<query name="tvguide.lineup.list">
  <description>
  </description>
  <sql>
    SELECT lineup_name||'/'||lineup_type||'/'||lineup_location,
           lineup_id
    FROM tvguide_lineups
    ORDER BY lineup_id
  </sql>
</query>

<query name="tvguide.lineup.read">
  <description>
  </description>
  <sql>
    SELECT lineup_id,
           lineup_name,
           lineup_type,
           lineup_location,
           lineup_device,
           lineup_zipcode
    FROM tvguide_lineups
    WHERE lineup_id='$lineup_id'
  </sql>
</query>

<query name="tvguide.lineup.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_lineups
    [ossweb::sql::insert_values -full t \
          { lineup_id "" ""
            lineup_name "" ""
            lineup_type "" ""
            lineup_location "" ""
            lineup_device "" ""
            lineup_zipcode "" "" }]
  </sql>
</query>

<query name="tvguide.lineup.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_lineups
  </sql>
</query>

<query name="tvguide.channel.read">
  <description>
  </description>
  <sql>
    SELECT start_date
    FROM tvguide_channels c
    WHERE c.channel_id='$channel_id' AND
          c.station_id='$station_id' AND
          c.lineup_id='$lineup_id'
  </sql>
</query>

<query name="tvguide.channel.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_channels
    [ossweb::sql::insert_values -full t \
          { lineup_id "" ""
            station_id int ""
            channel_id int ""
            start_date "" "" }]
  </sql>
</query>

<query name="tvguide.channel.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_channels
  </sql>
</query>

<query name="tvguide.schedule.list">
  <description>
  </description>
  <sql>
    SELECT s.station_id,
           s.station_name,
           s.station_label,
           c.channel_id,
           p.program_id,
           p.program_title,
           p.program_subtitle,
           part_number,
           episode_number,
           tvrating,
           mpaarating,
           starrating,
           CASE WHEN stereo THEN 'Stereo' ELSE '' END AS stereo,
           CASE WHEN closecaptioned THEN 'CC' ELSE '' END AS closecaptioned,
           sc.schedule_id,
           sc.duration,
           TO_CHAR(sc.start_time,'MM/DD/YY HH24:MI') AS start_time,
           EXTRACT(hour FROM sc.start_time) AS hour,
           EXTRACT(minute FROM sc.start_time) AS minute,
           EXTRACT(EPOCH FROM sc.start_time) AS time,
           tvguide_program_genre(p.program_id) AS genre
    FROM tvguide_stations s,
         tvguide_schedules sc,
         tvguide_channels c,
         tvguide_programs p
    WHERE lineup_id='$lineup_id' AND
          s.station_id=sc.station_id AND
          p.program_id=sc.program_id AND
          c.station_id=s.station_id
          [ossweb::sql::filter \
                { program_id list ""
                  start_date datetime ""
                  end_date datetime ""
                  current_flag int ""
                  search_text Text ""
                  search_actor Text "" } \
                -before AND \
                -aliasmap { p. } \
                -map { start_date "sc.start_time >= '%value'"
                       end_date "sc.start_time <= '%value'"
                       search_text "program_title ILIKE %value"
                       current_flag "NOW() BETWEEN sc.start_time AND sc.start_time+sc.duration" }]
    ORDER BY [ossweb::decode [ossweb::coalesce search_flag] 1 sc.start_time c.channel_id]
  </sql>
</query>

<query name="tvguide.schedule.search">
  <description>
  </description>
  <sql>
    SELECT s.station_id,
           s.station_name,
           s.station_label,
           s.affiliate,
           c.channel_id,
           p.program_id,
           p.program_title,
           p.program_subtitle,
           p.description,
           part_number,
           episode_number,
           tvrating,
           mpaarating,
           starrating,
           CASE WHEN stereo THEN 'Stereo' ELSE '' END AS stereo,
           CASE WHEN closecaptioned THEN 'CC' ELSE '' END AS closecaptioned,
           sc.schedule_id,
           sc.duration,
           TO_CHAR(sc.start_time,'MM/DD/YY HH24:MI') AS start_time,
           tvguide_program_genre(p.program_id) AS genre,
           tvguide_program_crew(p.program_id) AS crew
    FROM tvguide_stations s,
         tvguide_schedules sc,
         tvguide_channels c,
         tvguide_programs p
    WHERE lineup_id='$lineup_id' AND
          s.station_id=sc.station_id AND
          p.program_id=sc.program_id AND
          c.station_id=s.station_id
          [ossweb::sql::filter \
                { program_id list ""
                  start_date datetime ""
                  end_date datetime ""
                  search_text Text ""
                  search_actor Text "" } \
                -before AND \
                -aliasmap { p. } \
                -map { start_date "sc.start_time >= '%value'"
                       end_date "sc.start_time <= '%value'"
                       search_text "program_title ILIKE %value"
                       search_actor "EXISTS(SELECT 1 FROM tvguide_crew c WHERE p.program_id=c.program_id AND givenname||' '||surname ILIKE %value)" }]
    ORDER BY sc.start_time
    LIMIT [ossweb::coalesce search_limit 99]
  </sql>
</query>

<query name="tvguide.schedule.read">
  <description>
  </description>
  <sql>
    SELECT duration,
           tvrating,
           CASE WHEN stereo THEN 'Stereo' ELSE '' END AS stereo,
           CASE WHEN closecaptioned THEN 'CC' ELSE '' END AS closecaptioned,
           part_number,
           part_total,
           TO_CHAR(start_time,'MM/DD/YY HH12:MI PM') AS start_time,
           EXTRACT(EPOCH FROM start_time) AS start_seconds,
           EXTRACT(EPOCH FROM start_time+duration) AS end_seconds
    FROM tvguide_schedules
    WHERE program_id='$program_id' AND
          station_id='$station_id' AND
          start_time='$start_time'
  </sql>
</query>

<query name="tvguide.schedule.channel">
  <description>
  </description>
  <sql>
    SELECT p.program_title,
           p.program_subtitle,
           part_number,
           episode_number,
           tvrating,
           mpaarating,
           starrating,
           sc.duration,
           TO_CHAR(sc.start_time,'MM/DD/YY HH24:MI') AS start_time
    FROM tvguide_schedules sc,
         tvguide_channels c,
         tvguide_stations s,
         tvguide_programs p
    WHERE c.lineup_id='$lineup_id' AND
          c.station_id=s.station_id AND
          s.station_label='$channel' AND
          sc.station_id=s.station_id AND
          sc.program_id=p.program_id AND
          NOW() BETWEEN sc.start_time AND sc.start_time+sc.duration
  </sql>
</query>

<query name="tvguide.schedule.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_schedules
    [ossweb::sql::insert_values -full t \
          { program_id "" ""
            station_id int ""
            start_time "" ""
            duration "" ""
            tvrating "" ""
            closecaptioned boolean ""
            stereo boolean ""
            part_number int ""
            part_total int "" }]
  </sql>
</query>

<query name="tvguide.schedule.cleanup">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_schedules
    WHERE start_time < NOW() - '[ossweb::config tvguide:history "2 days"]'::INTERVAL
  </sql>
</query>

<query name="tvguide.schedule.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_schedules
  </sql>
</query>

<query name="tvguide.program.read">
  <description>
  </description>
  <sql>
   SELECT program_id,
          program_title,
          program_subtitle,
          program_type,
          program_date,
          program_year,
          episode_number,
          series_id,
          runtime_id,
          mpaarating,
          starrating,
          description
   FROM tvguide_programs
   WHERE program_id='$program_id'
  </sql>
</query>

<query name="tvguide.program.create">
  <description>
  </description>
  <sql>
   INSERT INTO tvguide_programs
   [ossweb::sql::insert_values -full t\
         { program_id "" ""
           program_type "" ""
           program_title "" ""
           program_subtitle "" ""
           program_date "" ""
           program_year "" ""
           episode_number "" ""
           series_id "" ""
           runtime_id "" ""
           mpaarating "" ""
           starrating "" ""
           description "" "" }]
  </sql>
</query>

<query name="tvguide.program.cleanup">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_programs
    WHERE program_id IN (SELECT p.program_id
                         FROM tvguide_programs p
                         WHERE NOT EXISTS(SELECT 1
                                          FROM tvguide_schedules s
                                          WHERE s.program_id=p.program_id))
  </sql>
</query>

<query name="tvguide.program.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_programs
  </sql>
</query>

<query name="tvguide.programGenre.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_genre
    [ossweb::sql::insert_values -full t \
          { program_id "" ""
            genre "" ""
            relevance int 0 }]
  </sql>
</query>

<query name="tvguide.programGenre.read">
  <description>
  </description>
  <sql>
   SELECT relevance
   FROM tvguide_genre
   WHERE program_id='$program_id' AND
         genre=[ossweb::sql::quote $genre]
  </sql>
</query>

<query name="tvguide.programGenre.list">
  <description>
  </description>
  <sql>
   SELECT genre,
          relevance
   FROM tvguide_genre
   WHERE program_id='$program_id'
  </sql>
</query>

<query name="tvguide.programGenre.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_genre
  </sql>
</query>

<query name="tvguide.crew.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_crew
    [ossweb::sql::insert_values -full t -skip_null t \
          { program_id "" ""
            role "" ""
            givenname "" ""
            surname "" "" }]
  </sql>
</query>

<query name="tvguide.crew.read">
  <description>
  </description>
  <sql>
   SELECT role,
          givenname,
          surname
   FROM tvguide_crew
   WHERE program_id='$program_id' AND
         role=[ossweb::sql::quote $role] AND
         givenname=[ossweb::sql::quote [ossweb::coalesce givenname ""] string] AND
         surname=[ossweb::sql::quote [ossweb::coalesce surname ""] string]
  </sql>
</query>

<query name="tvguide.crew.list">
  <description>
  </description>
  <sql>
   SELECT role,
          givenname,
          surname
   FROM tvguide_crew
   WHERE program_id='$program_id'
   ORDER BY role
  </sql>
</query>

<query name="tvguide.crew.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_crew
  </sql>
</query>

<query name="tvguide.recorder.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_recorder
    [ossweb::sql::insert_values -full t \
          { lineup_id "" ""
            lineup_name "" ""
            lineup_type "" ""
            lineup_location "" ""
            lineup_device "" ""
            lineup_zipcode "" ""
            program_id "" ""
            station_id int ""
            station_name "" ""
            station_label "" ""
            affiliate "" ""
            channel_id int ""
            start_time "" ""
            duration "" ""
            program_type "" ""
            program_title "" ""
            program_subtitle "" ""
            program_date "" ""
            program_year "" ""
            program_genre "" ""
            program_crew "" ""
            episode_number "" ""
            series_id "" ""
            runtime_id "" ""
            mpaarating "" ""
            starrating "" ""
            tvrating "" ""
            closecaptioned boolean ""
            stereo boolean ""
            part_number int ""
            part_total int ""
            description "" ""
            user_id const {[ossweb::conn user_id 0]} }]
  </sql>
</query>

<query name="tvguide.recorder.read">
  <description>
  </description>
  <sql>
    SELECT recorder_id,
           TO_CHAR(start_time,'MM/DD/YY HH12:MI PM') AS start_time,
           EXTRACT(EPOCH FROM start_time) AS start_seconds,
           EXTRACT(EPOCH FROM start_time+duration) AS end_seconds,
           lineup_id,
           lineup_name,
           lineup_type,
           lineup_location,
           lineup_device,
           lineup_zipcode,
           program_id,
           station_id,
           station_name,
           station_label,
           affiliate,
           channel_id,
           duration,
           program_type,
           program_title,
           program_subtitle,
           program_genre,
           program_crew,
           program_date,
           program_year,
           episode_number,
           series_id,
           runtime_id,
           mpaarating,
           starrating,
           tvrating,
           CASE WHEN stereo THEN 'Stereo' ELSE '' END AS stereo,
           CASE WHEN closecaptioned THEN 'CC' ELSE '' END AS closecaptioned,
           part_number,
           part_total,
           description,
           device_name,
           file_name,
           file_status,
           file_log,
           user_id
    FROM tvguide_recorder
    WHERE recorder_id=$recorder_id
  </sql>
</query>

<query name="tvguide.recorder.search">
  <description>
  </description>
  <sql>
    SELECT recorder_id,
           file_status
    FROM tvguide_recorder
    WHERE program_id='$program_id' AND
          station_id='$station_id' AND
          start_time='$start_time' AND
          lineup_id='$lineup_id' AND
          channel_id='$channel_id'
  </sql>
</query>

<query name="tvguide.recorder.conflict">
  <description>
  </description>
  <sql>
    SELECT TO_CHAR(start_time,'MM/DD/YYYY HH24:MI')||', '||duration||', #'||channel_id||': '||program_title
    FROM tvguide_recorder r
    WHERE start_time BETWEEN '$start_time' AND '$start_time'::TIMESTAMP WITH TIME ZONE + '$duration'::INTERVAL OR
          start_time+duration BETWEEN '$start_time'::TIMESTAMP WITH TIME ZONE + '1 sec'::INTERVAL AND '$start_time'::TIMESTAMP WITH TIME ZONE + '$duration'::INTERVAL
  </sql>
</query>

<query name="tvguide.recorder.list">
  <description>
  </description>
  <sql>
    SELECT recorder_id,
           lineup_id,
           lineup_name,
           station_id,
           station_name,
           station_label,
           program_id,
           program_title,
           program_subtitle,
           part_number,
           episode_number,
           channel_id,
           tvrating,
           mpaarating,
           starrating,
           CASE WHEN stereo THEN 'Stereo' ELSE '' END AS stereo,
           CASE WHEN closecaptioned THEN 'CC' ELSE '' END AS closecaptioned,
           duration,
           TO_CHAR(start_time,'MM/DD/YY HH12:MI PM') AS start_time,
           file_name,
           file_status,
           device_name,
           watch_count,
           TO_CHAR(watch_time,'MM/DD/YY HH12:MI PM') AS watch_time,
           user_id
    FROM tvguide_recorder
    [ossweb::sql::filter \
                { file_status list ""
                  future_flag int ""
                  start_date datetime ""
                  end_date datetime "" } \
                -map { future_flag "start_time > NOW()"
                       start_date "start_time >= '%value'"
                       end_date "start_time <= '%value'" } \
                -where WHERE]
    ORDER BY TO_CHAR(start_time,'YYYY-MM-DD HH24:MI')
  </sql>
</query>

<query name="tvguide.recorder.list.recording">
  <description>
  </description>
  <sql>
    SELECT recorder_id FROM tvguide_recorder WHERE file_status='Recording'
  </sql>
</query>

<query name="tvguide.recorder.update">
  <description>
  </description>
  <sql>
    UPDATE tvguide_recorder
    SET [ossweb::sql::update_values -skip_null t \
              { file_name "" ""
                file_log "" ""
                file_status "" ""
                device_name "" ""
                watch_count int ""
                watch_time int "" }]
    WHERE recorder_id=$recorder_id
  </sql>
</query>

<query name="tvguide.recorder.delete">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_recorder WHERE recorder_id=$recorder_id
  </sql>
</query>

<query name="tvguide.alert.list">
  <description>
  </description>
  <sql>
    SELECT alert_id,
           program,
           actor,
           email
    FROM tvguide_alerts
    ORDER BY create_date
  </sql>
</query>

<query name="tvguide.alert.list.user">
  <description>
  </description>
  <sql>
    SELECT alert_id,
           program,
           actor,
           email
    FROM tvguide_alerts
    WHERE user_id=$user_id
    ORDER BY create_date
  </sql>
</query>

<query name="tvguide.alert.create">
  <description>
  </description>
  <sql>
    INSERT INTO tvguide_alerts
    [ossweb::sql::insert_values -full t \
          { program "" ""
            actor "" ""
            email "" {[ossweb::conn user_id]}
            user_id int {[ossweb::conn user_id]} }]
  </sql>
</query>

<query name="tvguide.alert.delete">
  <description>
  </description>
  <sql>
    DELETE FROM tvguide_alerts WHERE alert_id=$alert_id AND user_id=$user_id
  </sql>
</query>

</xql>
