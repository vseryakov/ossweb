/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   March 2001
*/

/*!
   @function
   Returns number of topics/messages for the given forum
   @abstract
     forum_topic_count(forum_id)
     FUNCTION forum_topic_count(INTEGER) RETURNS VARCHAR
   @result
     TRUE
*/

CREATE OR REPLACE FUNCTION forum_topic_count(INTEGER) RETURNS VARCHAR AS '
DECLARE
  _forum_id ALIAS FOR $1;
  rec RECORD;
BEGIN
  SELECT COUNT(*) AS topic_count,
         SUM(msg_count) AS msg_count,
         MAX(ROUND(EXTRACT(EPOCH FROM create_date))) AS msg_timestamp
  INTO rec
  FROM forum_topics
  WHERE forum_id=_forum_id;
  RETURN rec.topic_count||'' ''||rec.msg_count||'' ''||COALESCE(rec.msg_timestamp,0);
END;' LANGUAGE 'plpgsql' STABLE;

/*!
   @function
   Returns number of messages for the given topic
   @abstract
     forum_message_count(topic_id)
     FUNCTION forum_message_count(INTEGER) RETURNS VARCHAR
   @result
     TRUE
*/

CREATE OR REPLACE FUNCTION forum_message_count(INTEGER) RETURNS VARCHAR AS '
DECLARE
  _topic_id ALIAS FOR $1;
  rec RECORD;
BEGIN
  SELECT COUNT(*) AS msg_count,
         MAX(ROUND(EXTRACT(EPOCH FROM create_date))) AS msg_timestamp
  INTO rec
  FROM forum_messages
  WHERE topic_id=_topic_id;
  RETURN rec.msg_count||'' ''||COALESCE(rec.msg_timestamp,0);
END;' LANGUAGE 'plpgsql' STABLE;

/*!
   @function
   Returns t if access is allowed for given mode
   @abstract
     forum_access(forum_id,user_id,mode)
     FUNCTION forum_message_count(INTEGER) RETURNS VARCHAR
   @result
     TRUE
*/

CREATE OR REPLACE FUNCTION forum_access(INTEGER,INTEGER,VARCHAR) RETURNS BOOLEAN AS '
DECLARE
  _forum_id ALIAS FOR $1;
  _user_id ALIAS FOR $2;
  _mode ALIAS FOR $3;
  rec RECORD;
BEGIN
  RETURN CASE
  WHEN _mode IS NULL OR _mode = ''r'' THEN
       (SELECT (forum_type IN (''Public'',''Personal'') OR
               (forum_type IN (''Private'') AND _user_id = create_user) OR
               (forum_type IN (''Group'') AND ossweb_same_groups(create_user,_user_id)))
        FROM forums
        WHERE forum_status=''Active'' AND
              forum_id=_forum_id)

  WHEN _mode = ''w'' THEN
       (SELECT (forum_type IN (''Public'') OR
               (forum_type IN (''Private'',''Personal'') AND _user_id = create_user) OR
               (forum_type IN (''Group'') AND ossweb_same_groups(create_user,_user_id)))
        FROM forums
        WHERE forum_status=''Active'' AND
              forum_id=_forum_id)

  ELSE
       FALSE
  END;
END;' LANGUAGE 'plpgsql' STABLE;


