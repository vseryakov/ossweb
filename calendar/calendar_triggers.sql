/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   July 2002
*/

CREATE OR REPLACE FUNCTION ossweb_calendar_trigger_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
BEGIN
   IF TG_OP = ''UPDATE'' THEN
     /* Update all linked calendar entries if they has not been changed */
     IF NEW.cal_date <> OLD.cal_date OR NEW.cal_time <> OLD.cal_time THEN
       UPDATE ossweb_calendar
       SET cal_date=NEW.cal_date,
           cal_time=NEW.cal_time
       WHERE cal_owner=NEW.cal_id AND
             cal_date=OLD.cal_date AND
             cal_time=OLD.cal_time;
     END IF;
     NEW.user_id := OLD.user_id;
     NEW.cal_owner := OLD.cal_owner;
   END IF;
   NEW.update_time := NOW();
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_calendar_trigger ON ossweb_calendar;
CREATE TRIGGER ossweb_calendar_trigger BEFORE INSERT OR UPDATE ON ossweb_calendar
FOR EACH ROW EXECUTE PROCEDURE ossweb_calendar_trigger_func();
