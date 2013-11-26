<query name="maverix.cache.users">
  <description>
    Search for user records
  </description>
  <sql>
    SELECT user_type,
           user_email,
           spam_status,
           spam_score_white,
           spam_score_black,
           spam_autolearn_flag,
           anti_virus_flag,
           spam_subject
    FROM maverix_users
  </sql>
</query>

<query name="maverix.cache.senders">
  <description>
  </description>
  <sql>
    SELECT s.sender_email,
           s.sender_type,
           s.user_email
    FROM maverix_senders s,
         maverix_users u
    WHERE s.user_email=u.user_email AND
          sender_email LIKE '@%'
  </sql>
</query>

<query name="maverix.user.list">
  <description>
    Search for user records
  </description>
  <sql>
    SELECT user_type,
           user_email
    FROM maverix_users
  </sql>
</query>

<query name="maverix.user.search">
  <description>
    Search for recipient
  </description>
  <sql>
    SELECT user_type,
           user_email,
           digest_id,
           TO_CHAR(digest_date,'YYYY-MM-DD HH24:MI') AS digest_date,
           TO_CHAR(digest_update,'YYYY-MM-DD HH24:MI') AS digest_update,
           EXTRACT(EPOCH FROM digest_date) AS digest_time,
           digest_start,
           digest_end,
           digest_interval,
           sender_digest_flag,
           spam_status, 
           spam_score_white,
           spam_score_black,
           spam_autolearn_flag,
           anti_virus_flag,
           spam_subject
    FROM maverix_users
    WHERE user_email=[ossweb::sql::quote $user_email]
    UNION
    SELECT u.user_type,
           u.user_email,
           u.digest_id,
           TO_CHAR(digest_date,'YYYY-MM-DD HH24:MI') AS digest_date,
           TO_CHAR(digest_update,'YYYY-MM-DD HH24:MI') AS digest_update,
           EXTRACT(EPOCH FROM u.digest_date) AS digest_time,
           u.digest_start,
           u.digest_end,
           u.digest_interval,
           u.sender_digest_flag,
           u.spam_status, 
           u.spam_score_white,
           u.spam_score_black,
           u.spam_autolearn_flag,
           u.anti_virus_flag,
           u.spam_subject
    FROM maverix_users u,
         maverix_user_aliases a
    WHERE a.alias_email=[ossweb::sql::quote $user_email] AND
          a.user_email=u.user_email
    LIMIT 1
  </sql>
</query>

<query name="maverix.user.search1">
  <description>
    Search for user records
  </description>
  <sql>
    SELECT user_email
    FROM maverix_users
    WHERE maverix_user_access(user_email,[ossweb::conn user_id 0])
    [ossweb::sql::filter \
          { user_email Text "" 
            user_type list "" 
            user_domain list "" 
            sender_digest_flag boolean ""
            anti_virus_flag "" "" } \
          -before AND]
    ORDER BY user_email
  </sql>
</query>

<query name="maverix.user.search2">
  <description>
    Search for user records
  </description>
  <sql>
    SELECT user_email,
           user_type,
           digest_id,
           TO_CHAR(digest_date,'YYYY-MM-DD HH24:MI') AS digest_date,
           TO_CHAR(digest_update,'YYYY-MM-DD HH24:MI') AS digest_update,
           EXTRACT(EPOCH FROM digest_date) AS digest_time,
           digest_interval,
           digest_start,
           digest_end,
           sender_digest_flag
    FROM maverix_users
    WHERE user_email IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="maverix.user.create">
  <description>
    Create recipient record
  </description>
  <sql>
    INSERT INTO maverix_users
    [ossweb::sql::insert_values -full t -skip_null t \
          { user_type "" ""
            user_email "" ""
            page_size int ""
            body_size int ""
            digest_id "" ""
            digest_email "" ""
            digest_start time ""
            digest_end time ""
            digest_interval int ""
            sender_digest_flag boolean ""
            spam_autolearn_flag boolean ""
            spam_status "" ""
            spam_score_white int ""
            spam_score_black int ""
            anti_virus_flag "" ""
            spam_subject "" "" }]
  </sql>
</query>

<query name="maverix.user.update">
  <description>
    Update recipient record
  </description>
  <sql>
    UPDATE maverix_users
    SET [ossweb::sql::update_values -skip_null t \
              { user_type "" ""
                page_size int ""
                body_size int ""
                digest_id "" ""
                digest_email "" ""
                digest_date datetime ""
                digest_update datetime ""
                digest_start time ""
                digest_end time ""
                digest_interval int ""
                digest_count int ""
                sender_digest_flag boolean ""
                spam_status "" ""
                spam_autolearn_flag boolean ""
                spam_score_white int ""
                spam_score_black int ""
                anti_virus_flag "" ""
                spam_subject "" ""
                user_name "" ""
                password "" ""
                session_id "" "" }]
    WHERE maverix_user_access(user_email,[ossweb::conn user_id 0]) AND
          user_email = [ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="maverix.user.update.prefs">
  <description>
    Update recipient record
  </description>
  <sql>
    UPDATE maverix_users
    SET [ossweb::sql::update_values \
              { user_type "" VRFY
                page_size int 20
                body_size int ""
                digest_email "" ""
                digest_start time ""
                digest_end time ""
                digest_interval int ""
                sender_digest_flag boolean f
                spam_status "" ""
                spam_autolearn_flag boolean t
                spam_score_white int ""
                spam_score_black int ""
                anti_virus_flag "" PASS
                spam_subject "" ""
                user_name "" ""
                password "" "" }]
    WHERE maverix_user_access(user_email,[ossweb::conn user_id 0]) AND
          user_email = [ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="maverix.user.update.digest_count">
  <description>
    Update recipient record
  </description>
  <sql>
    UPDATE maverix_users SET 
    digest_count=digest_count+1 
    WHERE user_email = [ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="maverix.user.delete">
  <description>
    Delete the recipient
  </description>
  <sql>
    DELETE FROM maverix_users
    WHERE user_email = [ossweb::sql::quote $user_email] AND
          maverix_user_access(user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.user.read">
  <description>
    Search for recipient
  </description>
  <sql>
    SELECT user_email,
           user_type,
           digest_id,
           digest_email,
           EXTRACT(EPOCH FROM digest_date) AS digest_time,
           TO_CHAR(digest_date,'YYYY-MM-DD HH24:MI') AS digest_date,
           TO_CHAR(digest_update,'YYYY-MM-DD HH24:MI') AS digest_update,
           digest_start,
           digest_end,
           digest_interval,
           digest_count,
           sender_digest_flag,
           spam_status,
           spam_autolearn_flag,
           spam_score_white,
           spam_score_black,
           spam_subject,
           anti_virus_flag,
           user_name,
           password,
           session_id,
           body_size,
           COALESCE(page_size,40) AS page_size
    FROM maverix_users u
    WHERE maverix_user_access(user_email,[ossweb::conn user_id 0]) AND
          [ossweb::sql::filter \
                { user_email "" ""
                  user_name "" "" } \
                -single t]
  </sql>
</query>

<query name="maverix.user.sender.search1">
  <description>
  </description>
  <sql>
    SELECT sender_email
    FROM maverix_senders
    WHERE user_email=[ossweb::sql::quote $user_email]
          [ossweb::sql::filter \
                { sender_type list "" 
                  sender_email Text "" } \
                -before AND]
    ORDER BY CASE WHEN [ossweb::coalesce sort 0] = 1
                  THEN str_index(sender_email,1,'@')
                  WHEN [ossweb::coalesce sort 0] = 2
                  THEN TO_CHAR(update_date,'YYYY-MM-DD HH24:MI')
                  ELSE sender_email
             END
  </sql>
</query>

<query name="maverix.user.sender.search2">
  <description>
  </description>
  <sql>
    SELECT sender_email,
           sender_type,
           TO_CHAR(update_date,'MM/DD/YY HH24:MI') AS update_date
    FROM maverix_senders
    WHERE user_email=[ossweb::sql::quote $user_email] AND
          sender_email IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="maverix.user.alias.list">
  <description>
  </description>
  <sql>
    SELECT alias_email
    FROM maverix_user_aliases 
    WHERE user_email = [ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="maverix.user.alias.create">
  <description>
  </description>
  <sql>
    INSERT INTO maverix_user_aliases
    [ossweb::sql::insert_values -full t \
          { user_email "" "" 
            alias_email "" "" }]
  </sql>
</query>

<query name="maverix.user.alias.delete">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_user_aliases 
    WHERE user_email=[ossweb::sql::quote $user_email] AND
          alias_email=[ossweb::sql::quote $alias_email] AND
          maverix_user_access(user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.user.message.search1">
  <description>
  </description>
  <sql>
    SELECT msg_id
    FROM maverix_user_messages um
    WHERE user_email=[ossweb::sql::quote $user_email]
    ORDER BY create_date
  </sql>
</query>

<query name="maverix.user.message.search2">
  <description>
  </description>
  <sql>
    SELECT um.msg_id,
           um.msg_status,
           m.sender_email,
           m.subject,
           m.body_offset,
           TO_CHAR(um.spam_score,'90.999') AS spam_score,
           um.spam_status,
           SUBSTRING(m.body,0,m.body_offset+[ossweb::config maverix:body:size 128]) AS body,
           TO_CHAR(um.create_date,'MM/DD/YY HH24:MI:SS') AS create_date
    FROM maverix_user_messages um,
         maverix_messages m
    WHERE um.user_email=[ossweb::sql::quote $user_email] AND
          um.msg_id=m.msg_id AND
          m.msg_id IN (CURRENT_PAGE_SET)
    ORDER BY um.create_date
  </sql>
</query>

<query name="maverix.user.message.list">
  <description>
  </description>
  <sql>
    SELECT m.msg_id,
           m.sender_email,
           m.body_offset,
           SUBSTRING(m.body,0,m.body_offset+[ossweb::coalesce body_size [ossweb::config maverix:body:size 256]]) AS body,
           m.subject,
           m.attachments,
           m.virus_status,
           TO_CHAR(um.spam_score,'90.999') AS spam_score,
           um.spam_status,
           um.msg_status,
           TO_CHAR(um.create_date,'MM/DD/YY HH24:MI:SS') AS create_date,
           u.digest_id
    FROM maverix_user_messages um,
         maverix_messages m,
         maverix_senders s,
         maverix_users u
    WHERE u.user_email=[ossweb::sql::quote $user_email] AND
          u.user_email=um.user_email AND
          u.user_email=s.user_email AND
          um.msg_id=m.msg_id AND
          m.sender_email=s.sender_email AND
          s.sender_type='VRFY' AND
          um.msg_status IN ('NEW','NTFY')
    ORDER BY um.user_email,
             um.update_date
  </sql>
</query>

<query name="maverix.user.message.read">
  <description>
  </description>
  <sql>
    SELECT m.msg_id,
           m.sender_email,
           m.body_offset,
           SUBSTRING(m.body,0,m.body_offset+[ossweb::config maverix:body:size 128]) AS body,
           m.subject,
           m.attachments,
           m.virus_status,
           TO_CHAR(um.spam_score,'90.999') AS spam_score,
           um.spam_status,
           um.msg_status,
           um.deliver_count,
           um.deliver_error,
           TO_CHAR(um.create_date,'MM/DD/YY HH24:MI:SS') AS create_date
    FROM maverix_user_messages um,
         maverix_messages m
    WHERE um.user_email=[ossweb::sql::quote $user_email] AND
          um.msg_id=$msg_id AND
          um.msg_id=m.msg_id
    LIMIT 1
  </sql>
</query>

<query name="maverix.user.message.create">
  <description>
  </description>
  <sql>
    INSERT INTO maverix_user_messages
    [ossweb::sql::insert_values -full t -skip_null t \
          { msg_id int ""
            msg_status "" ""
            user_email "" ""
            deliver_email "" ""
            spam_status "" ""
            spam_score float "" }]
  </sql>
</query>

<query name="maverix.user.message.update">
  <description>
  </description>
  <sql>
    UPDATE maverix_user_messages
    SET [ossweb::sql::update_values -skip_null t \
              { msg_status "" ""
                digest_id "" ""
                digest_date datetime ""
                deliver_count int ""
                deliver_error "" ""
                update_date const {[ns_fmttime [ns_time] "%Y-%m-%d %T"]} }]
    WHERE msg_id=$msg_id AND
          user_email=[ossweb::sql::quote $user_email] AND
          maverix_user_access(user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.user.message.update.status">
  <description>
  </description>
  <sql>
    UPDATE maverix_user_messages
    SET [ossweb::sql::update_values -skip_null t \
              { msg_status "" ""
                update_date const {[ns_fmttime [ns_time] "%Y-%m-%d %T"]} }]
    WHERE user_email=[ossweb::sql::quote $user_email] AND
          msg_id=$msg_id
  </sql>
</query>

<query name="maverix.user.message.delete">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_user_messages
    WHERE user_email=[ossweb::sql::quote $user_email] AND
          msg_id=$msg_id AND
          maverix_user_access(user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.user.message.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_user_messages WHERE user_email=[ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="maverix.sender.create">
  <description>
    Create sender record
  </description>
  <sql>
    INSERT INTO maverix_senders (user_email,sender_type,sender_email,sender_digest_flag,digest_id)
    SELECT [ossweb::sql::insert_values \
                 { user_email "" ""
                   sender_type "" ""
                   sender_email "" ""
                   sender_digest_flag boolean "f" 
                   digest_id "" NULL }]
    WHERE NOT EXISTS(SELECT 1
                     FROM maverix_senders
                     WHERE sender_email=[ossweb::sql::quote $sender_email] AND
                           user_email=[ossweb::sql::quote $user_email])
    LIMIT 1
  </sql>
</query>

<query name="maverix.sender.update">
  <description>
    Update sender record
  </description>
  <sql>
    UPDATE maverix_senders
    SET [ossweb::sql::update_values -skip_null t \
          { sender_type "" ""
            sender_method "" ""
            digest_id "" ""
            digest_date datetime ""
            digest_update datetime ""
            sender_digest_flag boolean ""
            update_date const {[ns_fmttime [ns_time] "%Y-%m-%d %T"]} }]
    WHERE user_email=[ossweb::sql::quote $user_email] AND
          sender_email=[ossweb::sql::quote $sender_email] AND
          maverix_user_access(user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.sender.update.type">
  <description>
    Update sender record
  </description>
  <sql>
    UPDATE maverix_senders
    SET [ossweb::sql::update_values -skip_null t \
          { sender_type "" ""
            sender_method "" ""
            digest_update datetime ""
            update_date const {[ns_fmttime [ns_time] "%Y-%m-%d %T"]} }]
    WHERE user_email=[ossweb::sql::quote $user_email] AND
          sender_email=[ossweb::sql::quote $sender_email]
  </sql>
</query>

<query name="maverix.sender.update.timestamp">
  <description>
    Update sender record
  </description>
  <sql>
    UPDATE maverix_senders
    SET update_date='$update_date'
    WHERE sender_email=[ossweb::sql::quote $sender_email]
  </sql>
</query>

<query name="maverix.sender.update.digest_count">
  <description>
    Update sender record
  </description>
  <sql>
    UPDATE maverix_senders 
    SET digest_count=digest_count+1 
    WHERE sender_email=[ossweb::sql::quote $sender_email]
  </sql>
</query>

<query name="maverix.sender.drop">
  <description>
    Update sender record
  </description>
  <sql>
    UPDATE maverix_senders
    SET [ossweb::sql::update_values -skip_null t \
              { sender_type "" DROP
                sender_method "" ""
                update_date const {[ns_fmttime [ns_time] "%Y-%m-%d %T"]} } ]
    WHERE sender_email=[ossweb::sql::quote $sender_email] AND
          sender_type NOT IN ('PASS')
  </sql>
</query>

<query name="maverix.sender.delete">
  <description>
    Delete the sender
  </description>
  <sql>
    DELETE FROM maverix_senders 
    WHERE sender_email=[ossweb::sql::quote $sender_email] AND
          maverix_user_access(user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.sender.delete.by.user">
  <description>
    Delete the sender
  </description>
  <sql>
    DELETE FROM maverix_senders
    WHERE user_email=[ossweb::sql::quote $user_email]
          [ossweb::sql::filter \
                { sender_type list "" } \
                -before AND]
  </sql>
</query>

<query name="maverix.sender.read">
  <description>
    Read sender/recipient record
  </description>
  <sql>
    SELECT u.user_email,
           s.sender_type,
           s.sender_method,
           s.sender_email,
           s.sender_digest_flag,
           s.digest_id,
           s.digest_count,
           EXTRACT(EPOCH FROM s.digest_date) AS digest_time,
           TO_CHAR(s.digest_date,'MM/DD/YYYY HH24:MI') AS digest_date,
           TO_CHAR(s.digest_update,'MM/DD/YYYY HH24:MI') AS digest_update,
           TO_CHAR(s.update_date,'MM/DD/YYYY HH24:MI') AS update_date,
           u.digest_id AS user_digest_id,
           EXTRACT(EPOCH FROM u.digest_date) AS user_digest_time
    FROM maverix_users u,
         maverix_senders s
    WHERE s.sender_email=[ossweb::sql::quote $sender_email] AND
          s.user_email=[ossweb::sql::quote $user_email] AND
          s.user_email=u.user_email AND
          maverix_user_access(s.user_email,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.sender.check.email">
  <description>
    Read sender email
  </description>
  <sql>
    SELECT 1
    FROM maverix_senders 
    WHERE sender_email=[ossweb::sql::quote $sender_email] AND
          user_email=[ossweb::sql::quote $user_email]
  </sql>
</query>

<query name="maverix.sender.search">
  <description>
    Search for sender/recipient pair
  </description>
  <sql>
    SELECT u.user_email,
           s.sender_type
    FROM maverix_users u,
         maverix_senders s
    WHERE u.user_email=[ossweb::sql::quote $user_email] AND
          s.sender_email=[ossweb::sql::quote $sender_email] AND
          u.user_email=s.user_email
    UNION
    SELECT u.user_email,
           s.sender_type
    FROM maverix_user_aliases u,
         maverix_senders s
    WHERE u.alias_email=[ossweb::sql::quote $user_email] AND
          s.sender_email=[ossweb::sql::quote $sender_email] AND
          u.user_email=s.user_email
    LIMIT 1
  </sql>
</query>

<query name="maverix.sender.search1">
  <description>
    Search for sender/recipient pair
  </description>
  <sql>
    SELECT sender_email
    FROM maverix_senders
    WHERE maverix_user_access(user_email,[ossweb::conn user_id 0])
          [ossweb::sql::filter \
                { user_email Text "" 
                  sender_type list "" 
                  sender_email Text "" } \
                -before AND]
    ORDER BY sender_email
  </sql>
</query>

<query name="maverix.sender.search2">
  <description>
    Search for sender/recipient pair
  </description>
  <sql>
    SELECT s.sender_email,
           s.sender_type,
           s.sender_method,
           s.digest_id,
           TO_CHAR(s.digest_date,'MM/DD/YY HH24:MI') AS digest_date,
           TO_CHAR(s.update_date,'MM/DD/YY HH24:MI') AS update_date,
           s.user_email
    FROM maverix_senders s
    WHERE sender_email IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="maverix.sender.list">
  <description>
  </description>
  <sql>
    SELECT sender_email,
           sender_type,
           user_email
    FROM maverix_senders s,
         maverix_users u
    WHERE s.user_email=u.user_email
          [ossweb::sql::filter \
                { sender_type list "" 
                  sender_email text "" } \
                -aliasmap { u. } \
                -before AND]
  </sql>
</query>

<query name="maverix.sender.user.list">
  <description>
  </description>
  <sql>
    SELECT DISTINCT
           u.user_email,
           s.digest_id
    FROM maverix_senders s,
         maverix_users u
    WHERE u.user_email=s.user_email AND
          u.user_type='VRFY' AND
          s.sender_type='VRFY' AND
          s.sender_email=[ossweb::sql::quote $sender_email]
  </sql>
</query>

<query name="maverix.sender.log.list">
  <description>
  </description>
  <sql>
    SELECT TO_CHAR(create_date,'MM/DD/YYYY HH24:MI') AS create_date,
           sender_email,
           subject,
           reason,
           TO_CHAR(spam_score,'09.999') AS spam_score,
           spam_status,
           virus_status
    FROM maverix_sender_log
    WHERE user_email=[ossweb::sql::quote $user_email]
    ORDER BY create_date DESC
  </sql>
</query>

<query name="maverix.sender.log.create">
  <description>
  </description>
  <sql>
    INSERT INTO maverix_sender_log
    [ossweb::sql::insert_values -full t -skip_null t \
          { user_email "" ""
            sender_email "" ""
            reason "" ""
            subject "" ""
            spam_score int ""
            spam_status "" ""
            virus_status "" "" }]
  </sql>
</query>

<query name="maverix.sender.message.list">
  <description>
    Update sender record
  </description>
  <sql>
    SELECT msg_id,
           user_email
    FROM maverix_user_messages
    WHERE msg_status='NEW' AND
          msg_id IN (SELECT msg_id
                     FROM maverix_messages
                     WHERE sender_email=[ossweb::sql::quote $sender_email])
  </sql>
</query>

<query name="maverix.sender.message.delete">
  <description>
    Update sender record
  </description>
  <sql>
    DELETE FROM maverix_user_messages
    WHERE msg_status='NEW' AND
          msg_id IN (SELECT msg_id
                     FROM maverix_messages
                     WHERE sender_email=[ossweb::sql::quote $sender_email])
  </sql>
</query>

<query name="maverix.message.create">
  <description>
  </description>
  <sql>
    INSERT INTO maverix_messages
    [ossweb::sql::insert_values -full t -skip_null t \
          { msg_id int ""
            sender_email "" ""
            body "" "" 
            body_size int ""
            body_offset int 0
            subject "" ""
            signature "" ""
            virus_status "" ""
            attachments "" "" }]
  </sql>
</query>

<query name="maverix.message.delete">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_messages 
    WHERE msg_id=$msg_id AND
          NOT EXISTS(SELECT 1 FROM maverix_user_messages um WHERE um.msg_id=$msg_id)
  </sql>
</query>

<query name="maverix.message.read">
  <description>
  </description>
  <sql>
    SELECT msg_id,
           sender_email,
           body_offset,
           body,
           subject,
           signature,
           attachments,
           virus_status,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI:SS') AS create_date,
           maverix_msg_users(msg_id) AS user_email
    FROM maverix_messages
    WHERE msg_id=$msg_id AND
          maverix_msg_access(msg_id,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.message.read.body">
  <description>
  </description>
  <sql>
    SELECT body,
           signature
    FROM maverix_messages
    WHERE msg_id=$msg_id AND
          maverix_msg_access(msg_id,[ossweb::conn user_id 0])
  </sql>
</query>

<query name="maverix.message.search1">
  <description>
  </description>
  <sql>
    SELECT msg_id
    FROM maverix_messages m
    WHERE maverix_msg_access(msg_id,[ossweb::conn user_id 0])
    [ossweb::sql::filter \
          { msg_id ilist ""
            sender_email text ""
            subject Text ""
            user_email text } \
          -map { user_email "EXISTS(SELECT 1 FROM maverix_user_messages um 
                                    WHERE um.msg_id=m.msg_id AND
                                          um.user_email ILIKE %value)" } \
          -before AND]
    ORDER BY create_date
  </sql>
</query>

<query name="maverix.message.search2">
  <description>
  </description>
  <sql>
    SELECT msg_id,
           sender_email,
           subject,
           SUBSTRING(body,0,body_offset) AS body,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI:SS') AS create_date,
           maverix_msg_users(msg_id) AS user_email
    FROM maverix_messages m
    WHERE msg_id IN (CURRENT_PAGE_SET)
    ORDER BY create_date
  </sql>
</query>

<query name="maverix.schedule.deliver.list">
  <description>
  </description>
  <sql>
    SELECT m.msg_id,
           m.sender_email,
           m.body,
           um.msg_status,
           um.user_email,
           um.deliver_email,
           um.deliver_count
    FROM maverix_user_messages um,
         maverix_messages m,
         maverix_users u
    WHERE m.msg_id=um.msg_id AND
          u.user_email=um.user_email AND
          deliver_count BETWEEN 0 AND 10 AND
          (u.user_type='PASS' OR
           um.msg_status='PASS' OR
           EXISTS(SELECT 1 FROM maverix_senders s
                  WHERE s.user_email=u.user_email AND
                        s.sender_type='PASS' AND
                        (s.sender_email=m.sender_email OR
                         s.sender_email='@'||str_index(m.sender_email,1,'@') OR
                         s.sender_email='@'||str_index(m.sender_email,'end-1','.')||'.'||
                                             str_index(m.sender_email,'end','.'))))
    ORDER BY um.update_date
  </sql>
</query>

<query name="maverix.schedule.digest.list">
  <description>
  </description>
  <sql>
    SELECT DISTINCT
           u.user_email,
           CASE WHEN TRIM(COALESCE(u.digest_email,'')) = '' THEN u.user_email
                ELSE digest_email
           END AS digest_email,
           u.body_size
    FROM maverix_user_messages um,
         maverix_users u
    WHERE u.user_type='VRFY' AND
          u.user_email=um.user_email AND
          um.msg_status IN ('NEW','NTFY') AND
          ((NOW()::TIME BETWEEN COALESCE(u.digest_start,'[ossweb::config maverix:digest:start 7:0]'::TIME) AND
                                COALESCE(u.digest_end,'[ossweb::config maverix:digest:end 23:0]'::TIME) AND
           EXTRACT(EPOCH FROM NOW()-um.create_date) < [ossweb::config maverix:digest:history 86400] AND
           EXTRACT(EPOCH FROM NOW()-u.digest_date) >= COALESCE(u.digest_interval,[ossweb::config maverix:user:interval 86400]) AND
           u.digest_count < 10 AND
           ((u.digest_update > u.digest_date AND EXTRACT(EPOCH FROM NOW()-u.digest_update) > 600) OR
            EXTRACT(EPOCH FROM NOW()-u.digest_date) > [ossweb::config maverix:digest:interval 43200]))
           [ossweb::sql::filter \
                 { user_list list "" } \
                 -map { user_list "u.user_email IN (%value)" } \
                 -before OR])
  </sql>
</query>

<query name="maverix.schedule.sender.list">
  <description>
  </description>
  <sql>
    SELECT DISTINCT
           s.sender_email
    FROM maverix_senders s,
         maverix_users u
    WHERE u.user_email=s.user_email AND
          COALESCE(s.sender_digest_flag,COALESCE(u.sender_digest_flag,'[ossweb::config maverix:digest:sender f]')) AND
          s.sender_type='VRFY' AND
          u.user_type='VRFY' AND
          s.sender_email !~ '[ossweb::config maverix:sender:ignore {^<>$}]' AND
          NOW()::TIME BETWEEN '[ossweb::config maverix:digest:start 7:0]'::TIME AND
                              '[ossweb::config maverix:digest:end 23:0]'::TIME AND
          EXTRACT(EPOCH FROM NOW()-s.digest_date) >= [ossweb::config maverix:sender:interval 604800] AND
          s.digest_count < 10 AND
          u.digest_count < 10 AND
          (s.digest_update >= s.digest_date OR
           EXTRACT(EPOCH FROM NOW()-u.digest_date) > [ossweb::config maverix:digest:interval 43200])
  </sql>
</query>

<query name="maverix.schedule.cleanup.users">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_users
    WHERE NOW() - create_date > '1 day'::INTERVAL AND
          NOT EXISTS(SELECT 1 FROM maverix_senders s
                     WHERE s.user_email=maverix_users.user_email)
  </sql>
</query>

<query name="maverix.schedule.cleanup.senders">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_senders
    WHERE NOW() - update_date > '30 days'::INTERVAL AND
          ((sender_type='DROP' AND sender_method='Bounced') OR
           sender_type='VRFY')
  </sql>
</query>

<query name="maverix.schedule.cleanup.sender.log">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_sender_log
    WHERE EXTRACT(EPOCH FROM NOW() - create_date) > [ossweb::config maverix:history 604800]
  </sql>
</query>

<query name="maverix.schedule.cleanup.messages">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_messages
    WHERE NOT EXISTS(SELECT 1 FROM maverix_user_messages um
                     WHERE um.msg_id=maverix_messages.msg_id)
  </sql>
</query>

<query name="maverix.schedule.cleanup.user.messages">
  <description>
  </description>
  <sql>
    DELETE FROM maverix_user_messages
    WHERE EXTRACT(EPOCH FROM NOW() - update_date) > [ossweb::config maverix:history 604800]
  </sql>
</query>
