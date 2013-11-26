/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   February 2002

   $Id: ossmon_triggers.sql 2195 2006-11-09 23:55:51Z vlad $
*/

CREATE OR REPLACE FUNCTION ossmon_alerts_trigger_func() RETURNS TRIGGER AS '
BEGIN
   IF TG_OP = ''DELETE'' THEN
     /* Keep connectivity alerts for reports */
     IF OLD.log_status ~* ''^noConnectivity|^OK$'' THEN
        RETURN NULL;
     END IF;
     RETURN OLD;
   END IF;

   IF TG_OP = ''INSERT'' THEN
     /* New alert is always active */
     NEW.alert_count := 1;
     NEW.alert_time := NOW();
     NEW.create_time := NOW();
     NEW.alert_status = ''Active'';
   END IF;

   IF TG_OP = ''UPDATE'' THEN
     IF NEW.alert_count IS NULL OR NEW.alert_count <= 0 THEN
       NEW.alert_count := 1;
     END IF;
     IF NEW.alert_status = ''Pending'' AND OLD.alert_status <> ''Pending'' THEN
       NEW.pending_time := NOW();
     END IF;
     IF NEW.alert_status = ''Closed'' AND OLD.alert_status <> ''Closed'' THEN
       NEW.closed_time := NOW();
     END IF;
   END IF;

   NEW.update_time := NOW();
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossmon_alerts_trigger ON ossmon_alerts;
CREATE TRIGGER ossmon_alerts_trigger BEFORE INSERT OR UPDATE ON ossmon_alerts
FOR EACH ROW EXECUTE PROCEDURE ossmon_alerts_trigger_func();

CREATE OR REPLACE FUNCTION ossmon_alertlog_trigger_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
BEGIN
   SELECT log_date,log_status INTO rec FROM ossmon_alerts WHERE alert_id=NEW.log_alert;
   /* Ignore duplicate log records */
   IF NEW.log_status = rec.log_status AND NOW() - rec.log_date < ''30 mins''::INTERVAL THEN
     RETURN NULL;
   END IF;
   UPDATE ossmon_alerts SET log_status=NEW.log_status,log_date=NEW.log_date WHERE alert_id=NEW.log_alert;
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossmon_alertlog_trigger ON ossmon_alert_log;
CREATE TRIGGER ossmon_alertlog_trigger BEFORE INSERT ON ossmon_alert_log
FOR EACH ROW EXECUTE PROCEDURE ossmon_alertlog_trigger_func();

CREATE OR REPLACE FUNCTION ossmon_objects_trigger_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
BEGIN
   IF TG_OP = ''DELETE'' THEN
     PERFORM ossmon_device_object_count(OLD.device_id,-1);
     RETURN OLD;
   END IF;
   IF TG_OP = ''INSERT'' THEN
     PERFORM ossmon_device_object_count(NEW.device_id,1);
   END IF;
   NEW.update_time = NOW();
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossmon_objects_trigger ON ossmon_objects;
CREATE TRIGGER ossmon_objects_trigger BEFORE INSERT OR UPDATE ON ossmon_objects
FOR EACH ROW EXECUTE PROCEDURE ossmon_objects_trigger_func();

CREATE OR REPLACE FUNCTION ossmon_devices_trigger_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
BEGIN
   IF TG_OP = ''UPDATE'' THEN
     IF NEW.device_parent = NEW.device_id THEN
       NEW.device_parent = OLD.device_parent;
     END IF;
     IF NEW.device_host <> OLD.device_host THEN
       UPDATE ossmon_objects SET obj_host=NEW.device_host WHERE device_id=NEW.device_id AND obj_host=OLD.device_host;
     END IF;
   END IF;
   NEW.update_time = NOW();
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossmon_devices_trigger ON ossmon_devices;
CREATE TRIGGER ossmon_devices_trigger BEFORE INSERT OR UPDATE ON ossmon_devices
FOR EACH ROW EXECUTE PROCEDURE ossmon_devices_trigger_func();

