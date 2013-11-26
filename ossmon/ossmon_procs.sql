/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   August 2001
*/


/*!
   @function
   OSSMON object name
   @abstract
     ossmon_object_name(obj_id)
     FUNCTION ossmon_object_name(INTEGER) RETURNS VARCHAR
   @result
     Returns object name
*/
CREATE OR REPLACE FUNCTION ossmon_object_name(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _obj_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   SELECT obj_name,
          device_name
   INTO rec
   FROM ossmon_objects o,
        ossmon_devices d
   WHERE obj_id=_obj_id AND
         o.device_id=d.device_id;
   IF FOUND THEN
     RETURN rec.obj_name||''/''||rec.device_name;
   END IF;
   RETURN NULL;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/*!
   @function
   OSSMON object property information
   @abstract
     ossmon_object_properties(obj_id)
     FUNCTION ossmon_object_properties(INTEGER) RETURNS VARCHAR
   @result
     Returns object properties as a list in format:
     property_name value
*/
CREATE OR REPLACE FUNCTION ossmon_object_properties(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _obj_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT property_id, str_tclescape(value) AS value 
              FROM ossmon_object_properties 
              WHERE obj_id=_obj_id LOOP
      result := result||''"''||rec.property_id||''" "''||rec.value||''" '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/*!
   @function
   OSSMON action rule alerts
   @abstract
     ossmon_rule_alerts(rule_id)
     FUNCTION ossmon_rule_alerts(INTEGER) RETURNS VARCHAR
   @result
     Returns action rule alerts as a list in format:
     alert_type alert_name template_id template_name
*/
CREATE OR REPLACE FUNCTION ossmon_rule_alerts(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _rule_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT r.action_type,
                     t.template_name,
                     t.template_id
              FROM ossmon_alert_run r,
                   ossmon_templates t
              WHERE rule_id=_rule_id AND
                    r.template_id=t.template_id LOOP
      result := result||''"''||rec.action_type||''" ''||rec.template_id||'' "''||rec.template_name||''" '' ;
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/*!
   @function
   OSSMON alert data
   @abstract
     ossmon_alert_data(alert_id)
     FUNCTION ossmon_alert_data(INTEGER) RETURNS VARCHAR
   @result
     Returns last alert message
*/
CREATE OR REPLACE FUNCTION ossmon_alert_data(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _alert_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT log_data
              FROM ossmon_alert_log
              WHERE log_alert=_alert_id
              ORDER BY log_date DESC
              LIMIT 1 LOOP
     result := rec.log_data;
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/*!
   @function
   checks for critical alert
   @abstract
     ossmon_alert_critical(text,config)
     FUNCTION ossmon_alert_critical(VARCHAR,VARCHAR) RETURNS BOOLEAN
   @result
     Returns TRUE if alert critical
*/

CREATE OR REPLACE FUNCTION ossmon_alert_critical(VARCHAR,VARCHAR) RETURNS BOOLEAN AS '
DECLARE
   _text ALIAS FOR $1;
   _config ALIAS FOR $2;
   cfg VARCHAR;
BEGIN
   cfg := COALESCE(_config,ossweb_config(''ossmon:alert:critical'',''''));
   IF _text IS NULL OR cfg = '''' THEN RETURN FALSE; END IF;
   RETURN CASE WHEN _text ~* cfg THEN TRUE ELSE FALSE END;
END;' LANGUAGE 'plpgsql' STABLE;

/*!
   @function
   Builds OSSMON device path
   @abstract
     ossmon_device_path(obj_id)
     FUNCTION ossmon_device_path(INTEGER) RETURNS VARCHAR
   @result
     Returns object path
*/
CREATE OR REPLACE FUNCTION ossmon_device_path2(INTEGER,VARCHAR,INTEGER,INTEGER) RETURNS INTEGER AS '
DECLARE
   _device_id ALIAS FOR $1;
   _device_path ALIAS FOR $2;
   _idx ALIAS FOR $3;
   _priority ALIAS FOR $4;
   rec RECORD;
   path VARCHAR;
   idx INTEGER;
   count INTEGER := 0;
BEGIN
   idx := _idx;
   path := COALESCE(_device_path,'''')||_priority||LPAD(idx::TEXT,10,''0'')||''/'';
   /* Update all children as well */
   FOR rec IN SELECT device_id,
                     priority
              FROM ossmon_devices
              WHERE device_parent=_device_id
              ORDER BY priority,
                       device_name LOOP
      idx := idx + 1;
      count := count + ossmon_device_path2(rec.device_id,path,idx,rec.priority) + 1;
   END LOOP;
   UPDATE ossmon_devices
   SET device_path=path,
       device_count=count
   WHERE device_id=_device_id AND
         COALESCE(device_path,'''') <> path;
   RETURN count;
END;' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ossmon_device_path(INTEGER) RETURNS INTEGER AS '
DECLARE
   _device_id ALIAS FOR $1;
   rec RECORD;
BEGIN
   SELECT d1.device_path,
          d1.priority,
          d1.device_parent,
          d2.device_path AS device_path2
   INTO rec
   FROM ossmon_devices d1
        LEFT OUTER JOIN ossmon_devices d2
          ON d1.device_parent=d2.device_id
   WHERE d1.device_id=_device_id;
   IF NOT FOUND OR _device_id = rec.device_parent THEN
     RETURN 0;
   END IF;
   RETURN ossmon_device_path2(_device_id,rec.device_path2,_device_id,rec.priority);
END;' LANGUAGE 'plpgsql';

/*!
   @function
   OSSMON device location
   @abstract
     ossmon_device_location(device_id,address_id,full_flag)
     FUNCTION ossmon_device_location(INTEGER,INTEGER,BOOLEAN) RETURNS VARCHAR
   @result
     Returns device location
*/
CREATE OR REPLACE FUNCTION ossmon_device_location(INTEGER,INTEGER,BOOLEAN) RETURNS VARCHAR AS '
DECLARE
   _device_id ALIAS FOR $1;
   _address_id ALIAS FOR $2;
   _full ALIAS FOR $3;
   result VARCHAR := '''';
BEGIN
   IF _address_id IS NOT NULL THEN
     SELECT CASE WHEN NOT _full THEN
                 city||
                 CASE WHEN state IS NULL THEN '''' ELSE ''-''||state END||
                 CASE WHEN country IS NULL THEN '''' ELSE ''-''||country END
            ELSE
                 CASE WHEN country IS NULL THEN '''' ELSE country END||
                 CASE WHEN state IS NULL THEN '''' ELSE ''-''||state END||
                 ''-''||city||
                 ''-''||SUBSTRING(street,1,1)||number::TEXT

            END
     INTO result
     FROM ossweb_locations WHERE address_id=_address_id;
     RETURN result;
   END IF;
   IF _device_id IS NOT NULL THEN
     SELECT CASE WHEN NOT _full THEN
                 city||
                 CASE WHEN state IS NULL THEN '''' ELSE ''-''||state END||
                 CASE WHEN country IS NULL THEN '''' ELSE ''-''||country END
            ELSE
                 CASE WHEN country IS NULL THEN '''' ELSE country END||
                 CASE WHEN state IS NULL THEN '''' ELSE ''-''||state END||
                 ''-''||city||
                 ''-''||SUBSTRING(street,1,1)||number::TEXT
            END
     INTO result
     FROM ossmon_devices d,
          ossweb_locations a
     WHERE d.device_id=_device_id AND
           d.address_id=a.address_id;
   END IF;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION ossmon_device_location(INTEGER,INTEGER) RETURNS VARCHAR AS '
BEGIN
   RETURN ossmon_device_location($1,$2,FALSE);
END;' LANGUAGE 'plpgsql' STABLE;

/*!
   @function
   OSSMON device name
   @abstract
     ossmon_device_name(obj_id)
     FUNCTION ossmon_device_name(INTEGER) RETURNS VARCHAR
   @result
     Returns device name
*/
CREATE OR REPLACE FUNCTION ossmon_device_name(INTEGER,BOOLEAN) RETURNS VARCHAR AS '
DECLARE
   _device_id ALIAS FOR $1;
   _location ALIAS FOR $2;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   IF _location THEN
     RETURN (SELECT device_name||COALESCE(''/''||ossmon_device_location(device_id,address_id),'''')
             FROM ossmon_devices WHERE device_id=_device_id);
   ELSE
     RETURN (SELECT device_name FROM ossmon_devices WHERE device_id=_device_id);
   END IF;
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION ossmon_device_name(INTEGER) RETURNS VARCHAR AS '
BEGIN
   RETURN ossmon_device_name($1,FALSE);
END;' LANGUAGE 'plpgsql' STABLE;

/*!
   @function
   OSSMON object property information
   @abstract
     ossmon_object_properties(obj_id)
     FUNCTION ossmon_object_properties(INTEGER) RETURNS VARCHAR
   @result
     Returns object properties as a list in format:
     property_name value
*/
CREATE OR REPLACE FUNCTION ossmon_device_properties(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _device_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT property_id,value FROM ossmon_device_properties WHERE device_id=_device_id LOOP
      result := result||''"''||rec.property_id||''" "''||rec.value||''" '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE RETURNS NULL ON NULL INPUT;

/*!
   @function
   OSSMON device last alerts
   @abstract
     ossmon_device_alerts(device_id)
     FUNCTION ossmon_device_alerts(INTEGER) RETURNS VARCHAR
   @result
     Returns device alerts as list of
     alert_id alert_type alert_status alert_level alert_time alert_count alert_name
*/
CREATE OR REPLACE FUNCTION ossmon_device_alerts(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _device_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT alert_id,
                     alert_type,
                     alert_status,
                     alert_level,
                     EXTRACT(EPOCH FROM alert_time) AS alert_time,
                     alert_count,
                     alert_name
              FROM ossmon_alerts
              WHERE device_id=_device_id AND
                    alert_count > 0 AND
                    alert_status IN (''Active'',''Pending'')
              ORDER BY alert_time DESC LOOP
     result := rec.alert_id||'' ''||rec.alert_type||'' ''||
               rec.alert_status||'' ''||rec.alert_level||'' ''||
               rec.alert_time||'' ''||rec.alert_count||'' "''||
               rec.alert_name||''"'';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE RETURNS NULL ON NULL INPUT;

/*!
   @function
   Device active objects
   @abstract
     ossmon_device_objects(device_id)
     FUNCTION ossmon_device_objects(INTEGER) RETURNS INTEGER
   @result
     Returns list of device objects
*/

CREATE OR REPLACE FUNCTION ossmon_device_objects(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _device_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT obj_id,
                     obj_type,
                     COALESCE(obj_name,'''') AS obj_name,
                     COALESCE(TO_CHAR(poll_time,''MM/DD/YY HH24:MI:SS''),'''') AS poll_time
              FROM ossmon_objects
              WHERE device_id=_device_id AND
                    disable_flag = FALSE
              ORDER BY obj_type LOOP
     result := result||'' "''||rec.poll_time||''" ''||rec.obj_id||'' ''||rec.obj_type||'' {''||rec.obj_name||''} '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/*!
   @function
   OSSMON device object count
   @abstract
     ossmon_device_monitors(device_id)
     FUNCTION ossmon_device_monitors(INTEGER) RETURNS INTEGER
   @result
     Returns number of device objects
*/
CREATE OR REPLACE FUNCTION ossmon_device_object_count(INTEGER,INTEGER) RETURNS BOOLEAN AS '
DECLARE
   _device_id ALIAS FOR $1;
   _counter ALIAS FOR $2;
   _device_parent INTEGER;
BEGIN
   IF _counter = 0 THEN
     UPDATE ossmon_devices
     SET object_count=(SELECT COUNT(*) FROM ossmon_objects o WHERE ossmon_devices.device_id=o.device_id)
     WHERE device_id=_device_id;
     RETURN TRUE;
   END IF;
   UPDATE ossmon_devices SET object_count=object_count+_counter WHERE device_id=_device_id;
   _device_parent := (SELECT device_parent FROM ossmon_devices WHERE device_id=_device_id);
   IF _device_parent IS NOT NULL THEN
     PERFORM ossmon_device_object_count(_device_parent,_counter);
   END IF;
   RETURN TRUE;
END;' LANGUAGE 'plpgsql' STRICT VOLATILE;

