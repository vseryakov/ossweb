/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   March 2003
*/

CREATE OR REPLACE FUNCTION maverix_user_email(VARCHAR) RETURNS VARCHAR AS '
DECLARE
   _user_email ALIAS FOR $1;
   email VARCHAR;
BEGIN
   SELECT user_email INTO email FROM maverix_user_aliases WHERE alias_email=_user_email;
   IF FOUND THEN
     RETURN email;
   END IF;
   RETURN _user_email;
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION maverix_user_access(VARCHAR,INTEGER) RETURNS BOOLEAN AS '
DECLARE
   _user_email ALIAS FOR $1;
   _oss_user_id ALIAS FOR $2;
   config VARCHAR;
BEGIN
   IF _oss_user_id = 0 THEN RETURN TRUE; END IF;
   config := oss_config(''maverix:user:domain:''||_oss_user_id,NULL);
   IF config IS NULL THEN RETURN TRUE; END IF;
   IF POSITION(''|''||str_index(_user_email,1,''@'')||''|'' IN config) > 0 THEN
     RETURN TRUE;
   END IF;
   RETURN FALSE;
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION maverix_msg_users(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _msg_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT u.user_email
              FROM maverix_user_messages um,
                   maverix_users u
              WHERE msg_id=_msg_id AND
                    u.user_email=um.user_email LOOP
     result := result||rec.user_email||'' '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION maverix_msg_access(INTEGER,INTEGER) RETURNS BOOLEAN AS '
DECLARE
   _msg_id ALIAS FOR $1;
   _oss_user_id ALIAS FOR $2;
   config VARCHAR;
   rec RECORD;
BEGIN
   IF _oss_user_id = 0 THEN RETURN TRUE; END IF;
   config := oss_config(''maverix:user:domain:''||_oss_user_id,NULL);
   IF config IS NULL THEN RETURN TRUE; END IF;
   FOR rec IN SELECT user_email
              FROM maverix_user_messages m,
                   maverix_users u
              WHERE msg_id=_msg_id AND
                    m.user_email=u.user_email LOOP
     IF POSITION(''|''||str_index(rec.user_email,1,''@'')||''|'' IN config) > 0 THEN
       RETURN TRUE;
     END IF;
   END LOOP;
   RETURN FALSE;
END;' LANGUAGE 'plpgsql' STABLE;
