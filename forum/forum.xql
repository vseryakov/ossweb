<?xml version="1.0"?>

<xql>

<query name="forum.topic.search1">
  <description>
    List topics
  </description>
  <vars>
   topic_columns ""
   topic_limit 999
  </vars>
  <sql>
    SELECT topic_id
           [ossweb::iftrue { $topic_columns == "" } {} { ,[join $topic_columns ,] }]
    FROM forum_topics
    WHERE hidden_flag=FALSE
          [ossweb::sql::filter \
                { forum_id ilist ""
                  last_timestamp datetime "" } \
                -before AND \
                -map { last_timestamp "msg_timestamp > '%value'" }]
    ORDER BY msg_timestamp DESC
    LIMIT $topic_limit
  </sql>
</query>

<query name="forum.topic.search2">
  <description>
    List topics
  </description>
  <sql>
    SELECT t.topic_id,
           t.subject,
           f.forum_name,
           f.forum_id,
           t.msg_count,
           t.msg_text AS body,
           COALESCE(user_name,ossweb_user_name(t.user_id)) AS user_name,
           TO_CHAR(t.msg_timestamp,'MM/DD/YY HH24:MI') AS msg_timestamp,
           TO_CHAR(t.create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM forum_topics t,
         forums f
    WHERE topic_id IN (CURRENT_PAGE_SET) AND
          t.forum_id=f.forum_id
  </sql>
</query>

<query name="forum.topic.read">
  <description>
    List topics
  </description>
  <sql>
    SELECT topic_id,
           subject,
           forum_name,
           t.msg_count,
           COALESCE(t.user_name,ossweb_user_name(t.user_id)) AS user_name,
           TO_CHAR(t.msg_timestamp,'MM/DD/YY HH24:MI') AS msg_timestamp,
           TO_CHAR(t.create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM forum_topics t,
         forums f
    WHERE f.forum_id=$forum_id AND
          f.forum_id=t.forum_id AND
          topic_id=$topic_id AND
          t.hidden_flag=FALSE
    ORDER BY create_date DESC
  </sql>
</query>

<query name="forum.topic.create">
  <description>
    Create forum topic record
  </description>
  <sql>
    INSERT INTO forum_topics
    [ossweb::sql::insert_values -full t \
          { forum_id int ""
            subject "" ""
            hidden_flag boolean f
            user_name "" ""
            user_id int {[ossweb::conn user_id]} }]
  </sql>
</query>

<query name="forum.topic.update">
  <description>
    Update forum topic record
  </description>
  <sql>
    UPDATE forum_topics
    SET [ossweb::sql::update_values \
              { hidden_flag boolean f
                subject "" "" }]
    WHERE topic_id=$topic_id
  </sql>
</query>

<query name="forum.topic.delete">
  <description>
    Update forum topic record
  </description>
  <sql>
    DELETE FROM forum_topics WHERE topic_id=$topic_id
  </sql>
</query>

<query name="forum.message.create">
  <description>
    Create forum note record
  </description>
  <sql>
    INSERT INTO forum_messages
    [ossweb::sql::insert_values -full t \
          { topic_id int ""
            forum_id int ""
            msg_parent int ""
            body "" ""
            hidden_flag boolean f
            user_name "" ""
            user_id int {[ossweb::conn user_id]} }]
  </sql>
</query>

<query name="forum.message.read">
  <description>
  </description>
  <sql>
    SELECT msg_id,
           msg_parent,
           body,
           user_id,
           forum_id,
           COALESCE(user_name,ossweb_user_name(user_id)) AS user_name,
           TO_CHAR(create_date,'Mon DD YYYY, HH24:MI') AS create_date
    FROM forum_messages m
    WHERE msg_id=$msg_id
  </sql>
</query>

<query name="forum.message.list">
  <description>
  </description>
  <vars>
   message_limit 999
   message_orderby tree_path
  </vars>
  <sql>
    SELECT msg_id,
           msg_parent,
           body,
           user_id,
           tree_path,
           COALESCE(user_name,ossweb_user_name(user_id)) AS user_name,
           TO_CHAR(create_date,'Mon DD YYYY, HH24:MI') AS create_date
    FROM forum_messages m
    WHERE hidden_flag=FALSE
          [ossweb::sql::filter \
                { topic_id ilist ""
                  msg_parent ilist "" } \
                -map { msg_parent "msg_id IN (%value)" } \
                -before AND]
    ORDER BY $message_orderby
    LIMIT $message_limit
  </sql>
</query>

<query name="forum.message.update">
  <description>
    Update forum message record
  </description>
  <sql>
    UPDATE forum_messages
    SET [ossweb::sql::update_values -skip_null t \
              { body "" ""
                hidden_flag boolean f }]
    WHERE msg_id=$msg_id
  </sql>
</query>

<query name="forum.message.delete">
  <description>
    Delete forum topic record
  </description>
  <sql>
    DELETE FROM forum_messages WHERE topic_id=$topic_id AND msg_id=$msg_id
  </sql>
</query>

<query name="forum.create">
  <description>
    Create forum record
  </description>
  <sql>
    INSERT INTO forums
    [ossweb::sql::insert_values -full t \
          { forum_name "" ""
            forum_status "" ""
            forum_type "" ""
            description "" ""
            create_user const {[ossweb::conn user_id -1]}}]
  </sql>
</query>

<query name="forum.update">
  <description>
    Update forum record
  </description>
  <sql>
    UPDATE forums
    SET [ossweb::sql::update_values \
              { forum_name "" ""
                forum_status "" ""
                forum_type "" ""
                description "" "" }]
    WHERE forum_id=$forum_id
  </sql>
</query>

<query name="forum.delete">
  <description>
    Delete topic record
  </description>
  <sql>
    DELETE FROM forums WHERE forum_id=$forum_id
  </sql>
</query>

<query name="forum.list">
  <description>
    Read all forum topics
  </description>
  <sql>
    SELECT forum_id,
           forum_name,
           forum_type,
           forum_status,
           description,
           msg_count,
           TO_CHAR(msg_timestamp,'MM/DD/YY HH24:MI') AS msg_timestamp,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM forums
    ORDER BY forum_name
  </sql>
</query>

<query name="forum.list.available">
  <description>
    Read all forum topics
  </description>
  <sql>
    SELECT forum_id,
           forum_name,
           forum_type,
           forum_status,
           description,
           msg_count,
           TO_CHAR(msg_timestamp,'MM/DD/YY HH24:MI') AS msg_timestamp,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM forums
    WHERE forum_access(forum_id,[ossweb::conn user_id -1],'r') = TRUE
    ORDER BY forum_name
  </sql>
</query>

<query name="forum.search1">
  <description>
    List topics
  </description>
  <sql>
    SELECT msg_id
    FROM forum_topics t,
         forum_messages m,
         forums f
    WHERE f.forum_id=t.forum_id AND
          t.topic_id=m.topic_id AND
          t.hidden_flag=FALSE AND
          m.hidden_flag=FALSE AND
          forum_access(f.forum_id,[ossweb::conn user_id -1],'r') = TRUE
          [ossweb::sql::filter \
                { forum_id ilist ""
                  body Text "" } \
                -aliasmap { f. } \
                -before AND \
                -map { body "(subject ILIKE %value OR body ILIKE %value)" }]
    ORDER BY t.create_date DESC
  </sql>
</query>

<query name="forum.search2">
  <description>
    List topics
  </description>
  <sql>
    SELECT m.msg_id,
           t.topic_id,
           t.forum_id,
           t.subject,
           m.body,
           COALESCE(m.user_name,ossweb_user_name(m.user_id)) AS user_name,
           TO_CHAR(m.create_date,'MM/DD/YY HH24:MI') AS create_date,
           forum_name
    FROM forum_topics t,
         forum_messages m,
         forums f
    WHERE m.msg_id IN (CURRENT_PAGE_SET) AND
          t.forum_id=f.forum_id AND
          t.topic_id=m.topic_id
  </sql>
</query>

<query name="forum.read">
  <description>
  </description>
  <vars>
   forum_access r
  </vars>
  <sql>
    SELECT forum_name,
           forum_id,
           forum_status,
           forum_type,
           description,
           msg_count,
           TO_CHAR(msg_timestamp,'MM/DD/YY HH24:MI') AS msg_timestamp,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM forums
    WHERE forum_id=$forum_id AND
          forum_access(forum_id,[ossweb::conn user_id -1],'$forum_access') = TRUE
  </sql>
</query>

<query name="forum.email.subscribe">
  <description>
  </description>
  <sql>
    INSERT INTO forum_emails (forum_id,email,user_id)
    SELECT $forum_id,
           [ossweb::sql::quote $email],
           [ossweb::conn user_id 0]
    WHERE NOT EXISTS(SELECT 1 FROM forum_emails e
                     WHERE e.forum_id=$forum_id AND
                           e.email ILIKE [ossweb::sql::quote $email])
  </sql>
</query>

<query name="forum.email.unsubscribe">
  <description>
  </description>
  <sql>
    DELETE FROM forum_emails
    WHERE forum_id=$forum_id AND
          email ILIKE [ossweb::sql::quote $email] AND
          user_id=[ossweb::conn user_id 0]
  </sql>
</query>

<query name="forum.email.list">
  <description>
  </description>
  <sql>
    SELECT email FROM forum_emails WHERE forum_id=$forum_id
  </sql>
</query>

</xql>
