/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   March 2004
*/

CREATE OR REPLACE FUNCTION forum_topics_trigger_func() RETURNS TRIGGER AS '
BEGIN
   IF TG_OP = ''DELETE'' THEN
     UPDATE forums
     SET msg_count=msg_count-1
     WHERE forum_id=(SELECT forum_id FROM forum_topics WHERE topic_id=OLD.topic_id);
   END IF;

   IF TG_OP = ''UPDATE'' THEN
     IF NEW.hidden_flag <> OLD.hidden_flag THEN
       UPDATE forum_messages SET hidden_flag=NEW.hidden_flag WHERE topic_id=NEW.topic_id;
     END IF;
   END IF;
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER forum_topics_trigger ON forum_topics;
CREATE TRIGGER forum_topics_trigger BEFORE INSERT OR UPDATE ON forum_topics
FOR EACH ROW EXECUTE PROCEDURE forum_topics_trigger_func();

CREATE OR REPLACE FUNCTION forum_messages_trigger_func() RETURNS TRIGGER AS '
DECLARE
   path VARCHAR;
BEGIN
   IF TG_OP = ''DELETE'' THEN
     UPDATE forum_topics SET msg_count=msg_count-1 WHERE topic_id=OLD.topic_id;
     UPDATE forums
     SET msg_count=msg_count-1
     WHERE forum_id=(SELECT forum_id FROM forum_topics WHERE topic_id=OLD.topic_id);
   END IF;

   IF TG_OP = ''UPDATE'' THEN
     IF NEW.hidden_flag <> OLD.hidden_flag THEN
       UPDATE forum_topics
       SET msg_count=CASE WHEN NEW.hidden_flag THEN msg_count-1 ELSE msg_count+1 END
       WHERE topic_id=NEW.topic_id;
       UPDATE forums
       SET msg_count=CASE WHEN NEW.hidden_flag THEN msg_count-1 ELSE msg_count+1 END
       WHERE forum_id=(SELECT forum_id FROM forum_topics WHERE topic_id=NEW.topic_id);
     END IF;
   END IF;

   IF TG_OP = ''INSERT'' THEN
     IF NEW.hidden_flag = FALSE THEN
       UPDATE forum_topics
       SET msg_timestamp=NOW(),msg_count=msg_count+1,msg_text=NEW.body
       WHERE topic_id=NEW.topic_id;
       UPDATE forums
       SET msg_timestamp=NOW(),msg_count=msg_count+1
       WHERE forum_id=(SELECT forum_id FROM forum_topics WHERE topic_id=NEW.topic_id);
     END IF;
     IF NEW.msg_parent IS NOT NULL THEN
       SELECT tree_path INTO path FROM forum_messages WHERE msg_id=NEW.msg_parent;
     END IF;
     NEW.tree_path := COALESCE(path,'''')||TO_CHAR(NOW(),''YYYYMMDDHH24MI'')||NEW.msg_id||''/'';
   END IF;
   RETURN NEW;
END;' LANGUAGE 'plpgsql' VOLATILE;

DROP TRIGGER forum_messages_trigger ON forum_messages;
CREATE TRIGGER forum_messages_trigger BEFORE INSERT OR UPDATE ON forum_messages
FOR EACH ROW EXECUTE PROCEDURE forum_messages_trigger_func();

