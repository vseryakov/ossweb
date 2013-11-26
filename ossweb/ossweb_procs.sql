/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001

   Modified: Darren Ferguson darren@crystalballinc.com
   August 2002

  $Id: ossweb_procs.sql 2338 2006-11-21 17:38:20Z vlad $
*/


CREATE OR REPLACE FUNCTION ossweb_app_move(INTEGER,BOOLEAN) RETURNS BOOLEAN AS $$
DECLARE
   _app_id ALIAS FOR $1;
   _up ALIAS FOR $2;
   rec RECORD;
BEGIN
   IF _up THEN
     SELECT a2.app_id AS app_id2,
            a2.sort AS sort2,
            COALESCE(a2.group_id,0) AS group_id2,
            a1.sort,
            COALESCE(a1.group_id,0) AS group_id
     INTO rec
     FROM ossweb_apps AS a1,
          ossweb_apps AS a2
     WHERE a1.app_id=_app_id AND
           a2.tree_path < a1.tree_path AND
           COALESCE(a1.group_id,0)=COALESCE(a2.group_id,0)
     ORDER BY a2.tree_path DESC
     LIMIT 1;
   ELSE
     SELECT a2.app_id AS app_id2,
            a2.sort AS sort2,
            COALESCE(a2.group_id,0) AS group_id2,
            a1.sort,
            COALESCE(a1.group_id,0) AS group_id
     INTO rec
     FROM ossweb_apps AS a1,
          ossweb_apps AS a2
     WHERE a1.app_id=_app_id AND
           a2.tree_path > a1.tree_path AND
           COALESCE(a1.group_id,0)=COALESCE(a2.group_id,0)
     ORDER BY a2.tree_path
     LIMIT 1;
   END IF;
   IF NOT FOUND THEN
     RETURN FALSE;
   END IF;
   /* do not allow to move items outside of the group or to move group title itself */
   IF rec.group_id2 <> rec.group_id OR
      rec.app_id2 = rec.group_id2 OR
      _app_id = rec.group_id THEN
     RETURN FALSE;
   END IF;
   /* sort is unique, so first we assign it with our app id and
      then exchange sorting keys
    */
   UPDATE ossweb_apps SET sort=_app_id WHERE app_id=_app_id;
   UPDATE ossweb_apps SET sort=rec.sort WHERE app_id=rec.app_id2;
   UPDATE ossweb_apps SET sort=rec.sort2 WHERE app_id=_app_id;
   RETURN TRUE;
END;$$ LANGUAGE 'plpgsql';

/*
   Put message event into message event queue
*/
CREATE OR REPLACE FUNCTION ossweb_message_event(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS INTEGER AS $$
DECLARE
   _message_type ALIAS FOR $1;
   _rcpt_to ALIAS FOR $2;
   _mail_from ALIAS FOR $3;
   _subject ALIAS FOR $4;
   _body ALIAS FOR $5;
   _args ALIAS FOR $6;
BEGIN
   INSERT INTO ossweb_message_queue (message_type,rcpt_to,mail_from,subject,body,args)
   VALUES(_message_type,_rcpt_to,_mail_from,_subject,_body,_args);
   RETURN CURRVAL('ossweb_message_seq');
END;$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ossweb_message_event(VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS INTEGER AS $$
BEGIN
    RETURN ossweb_message_event($1,$2,$3,$4,$5,'');
END;$$ LANGUAGE 'plpgsql';

/*
   Business day calculation
   Result
     new DATE with specified number of days added, if days is NULL,
     just find next business date
*/
CREATE OR REPLACE FUNCTION ossweb_business_day(DATE,INTEGER) RETURNS DATE AS $$
DECLARE
   _date ALIAS FOR $1;
   _days ALIAS FOR $2;
   d DATE;
   wd INTEGER;
   i INTEGER;
BEGIN
   IF _date IS NULL THEN RETURN NULL; END IF;
   d := _date;
   IF _days IS NULL AND EXTRACT(dow FROM d) NOT IN (6,0) THEN
     RETURN d;
   END IF;
   i := ABS(COALESCE(_days,1));
   WHILE i > 0 LOOP
     IF _days < 0 THEN
       d := d - 1;
     ELSE
       d := d + 1;
     END IF;
     IF EXTRACT(dow FROM d) NOT IN (6,0) THEN
       i := i - 1;
     END IF;
   END LOOP;
   RETURN d;
END;$$ LANGUAGE 'plpgsql' IMMUTABLE;

CREATE OR REPLACE FUNCTION ossweb_business_day(TIMESTAMP WITH TIME ZONE,INTEGER) RETURNS DATE AS $$
BEGIN
   RETURN ossweb_business_day($1::DATE,$2);
END;$$ LANGUAGE 'plpgsql' IMMUTABLE;


/*
   Returns full user name by id
*/
CREATE OR REPLACE FUNCTION ossweb_user_name(INTEGER,BOOLEAN) RETURNS VARCHAR AS $$
DECLARE
   _user_id ALIAS FOR $1;
   _details ALIAS FOR $2;
   rec RECORD;
BEGIN
   SELECT first_name,last_name,user_name INTO rec FROM ossweb_users WHERE user_id=_user_id;
   IF NOT FOUND THEN
     RETURN NULL;
   END IF;
   IF _details THEN
     RETURN rec.first_name||' '||rec.last_name||' ('||rec.user_name||','||_user_id||')';
   ELSE
     RETURN rec.first_name||' '||rec.last_name;
   END IF;
END;$$ LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION ossweb_user_name(INTEGER) RETURNS VARCHAR AS $$
BEGIN
   RETURN ossweb_user_name($1,FALSE);
END;$$ LANGUAGE 'plpgsql' STRICT;

/*
   Returns user login name
*/

CREATE OR REPLACE FUNCTION ossweb_user_login(INTEGER) RETURNS VARCHAR AS $$
BEGIN
   RETURN (SELECT user_name FROM ossweb_users WHERE user_id=$1);
END;$$ LANGUAGE 'plpgsql' STRICT;

/*
   Returns user type
*/

CREATE OR REPLACE FUNCTION ossweb_user_type(INTEGER) RETURNS VARCHAR AS $$
BEGIN
   RETURN (SELECT user_type FROM ossweb_users WHERE user_id=$1);
END;$$ LANGUAGE 'plpgsql' STRICT;

/*
   Returns user email by id
*/

CREATE OR REPLACE FUNCTION ossweb_user_email(INTEGER) RETURNS VARCHAR AS $$
DECLARE
   _user_id ALIAS FOR $1;
   rec RECORD;
BEGIN
   SELECT user_email INTO rec FROM ossweb_users WHERE user_id=_user_id;
   IF FOUND THEN
     RETURN rec.user_email;
   END IF;
   RETURN NULL;
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns configration paramers
*/

CREATE OR REPLACE FUNCTION ossweb_config(VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
DECLARE
   _name ALIAS FOR $1;
   _default ALIAS FOR $2;
   rec RECORD;
BEGIN
   SELECT value INTO rec FROM ossweb_config WHERE name=_name;
   IF FOUND THEN
     RETURN rec.value;
   END IF;
   RETURN _default;
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns hostname
*/

CREATE OR REPLACE FUNCTION ossweb_hostname() RETURNS VARCHAR AS $$
   return [info hostname]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

/*
   Formats datetime from seconds
*/

CREATE OR REPLACE FUNCTION ossweb_fmttime(INTEGER,VARCHAR) RETURNS VARCHAR AS $$
   if { $2 != "" } {
     return [clock format $1 -format "$2"]
   } else {
     return [clock format $1]
   }
$$ LANGUAGE 'pltcl' IMMUTABLE;

/*
   Returns seconds from the datetime
*/

CREATE OR REPLACE FUNCTION ossweb_seconds(TIMESTAMP WITH TIME ZONE) RETURNS INTEGER AS $$
BEGIN
   RETURN ROUND(EXTRACT(EPOCH FROM $1));
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

/*
   Returns user preferences
*/

CREATE OR REPLACE FUNCTION ossweb_user_prefs(INTEGER) RETURNS VARCHAR AS $$
   set user_id $1
   set cache user_prefs_$user_id
   if { ![info exists GD($cache)] } {
     set GD($cache) [spi_prepare "
          SELECT 1 AS type,name,value FROM ossweb_prefs WHERE obj_id=\$1 AND obj_type='U'
          UNION
          SELECT 0 AS type,name,value FROM ossweb_prefs p,ossweb_user_groups g WHERE obj_id=\$1 AND obj_type='G' AND p.obj_id=g.group_id
          ORDER BY 1" integer]
   }
   spi_execp $GD($cache) $user_id { set prefs($name) $value }
   return [array get prefs]
$$ LANGUAGE 'pltcl' STABLE STRICT;

/*
   Returns list of values for given table, columns, key and id
*/

CREATE OR REPLACE FUNCTION ossweb_values(VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
   set cache values_$1$2$3
   if { ![info exists GD($cache)] } {
     set GD($cache) [spi_prepare "SELECT $2 AS value FROM $1 WHERE $3=\$1 ORDER BY 1" integer]
   }
   set data ""
   spi_execp $GD($cache) $4 { if { [info exists value] } { lappend data $value } }
   return $data
$$ LANGUAGE 'pltcl' STABLE STRICT;

CREATE OR REPLACE FUNCTION ossweb_values(VARCHAR,VARCHAR,VARCHAR,INTEGER) RETURNS VARCHAR AS $$
   set cache values_$1$2$3
   if { ![info exists GD($cache)] } {
     set GD($cache) [spi_prepare "SELECT $2 AS value FROM $1 WHERE $3=\$1 ORDER BY 1" int4]
   }
   set data ""
   spi_execp $GD($cache) $4 { if { [info exists value] } { lappend data $value } }
   return $data
$$ LANGUAGE 'pltcl' STABLE STRICT;

/*
   Returns user sessions
*/

CREATE OR REPLACE FUNCTION ossweb_user_sessions(INTEGER) RETURNS VARCHAR AS $$
DECLARE
   _user_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '';
BEGIN
   FOR rec IN SELECT session_id,
                     ROUND(EXTRACT(EPOCH FROM login_time)) AS login_time,
                     ROUND(EXTRACT(EPOCH FROM access_time)) AS access_time,
                     ipaddr
              FROM ossweb_user_sessions
              WHERE user_id=_user_id AND
                    logout_time IS NULL
              ORDER BY access_time DESC LOOP
     result := result||rec.session_id||' '||rec.login_time||' '||rec.access_time||' '||rec.ipaddr||' ';
   END LOOP;
   RETURN result;
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

/*
   Returns user last access time
*/

CREATE OR REPLACE FUNCTION ossweb_user_access_time(INTEGER) RETURNS TIMESTAMP WITH TIME ZONE AS $$
DECLARE
   _user_id ALIAS FOR $1;
BEGIN
   RETURN (SELECT MAX(access_time) FROM ossweb_user_sessions WHERE user_id=_user_id);
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;


/*
   Returns user groups
*/

CREATE OR REPLACE FUNCTION ossweb_user_groups(INTEGER) RETURNS VARCHAR AS $$
DECLARE
   _user_id ALIAS FOR $1;
   rec RECORD;
   result VARCHAR := '';
BEGIN
   FOR rec IN SELECT group_name
              FROM ossweb_user_groups ug,
                   ossweb_groups g
              WHERE user_id=_user_id AND
                    g.group_id=ug.group_id LOOP
     result := result||rec.group_name||' ';
   END LOOP;
   RETURN result;
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

/*
   Returns concatenated field from all user groups
*/

CREATE OR REPLACE FUNCTION ossweb_user_groups_value(INTEGER,VARCHAR) RETURNS VARCHAR AS $$
   set _data ""
   if { ![info exists GD(user_groups_$2)] } {
     set GD(user_groups_$2) [spi_prepare "
             SELECT $2
             FROM ossweb_groups g,
                  ossweb_user_groups ug
             WHERE ug.user_id=\$1 AND
                   ug.group_id=g.group_id" integer]
   }
   spi_execp $GD(user_groups_$2) $1 {
     if { [info exists $2] } { append _data [set $2] " " }
   }
   return [string trim $_data]
END;$$ LANGUAGE 'pltcl' STABLE STRICT;

/*
   Returns true if users belong to the same group(s)
*/
CREATE OR REPLACE FUNCTION ossweb_same_groups(INTEGER,INTEGER) RETURNS BOOLEAN AS $$
DECLARE
   _user1 ALIAS FOR $1;
   _user2 ALIAS FOR $2;
BEGIN
   RETURN EXISTS(SELECT 1
                 FROM ossweb_user_groups g1,
                      ossweb_user_groups g2
                 WHERE g1.group_id=g2.group_id AND
                       g1.user_id=_user1 AND
                       g2.user_id=_user2);
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION ossweb_same_groups(INTEGER,INTEGER,INTEGER) RETURNS BOOLEAN AS $$
DECLARE
   _user1 ALIAS FOR $1;
   _user2 ALIAS FOR $2;
   _group ALIAS FOR $3;
BEGIN
   RETURN EXISTS(SELECT 1
                 FROM ossweb_user_groups g1,
                      ossweb_user_groups g2
                 WHERE g1.group_id=g2.group_id AND
                       g1.user_id=_user1 AND
                       g2.user_id=_user2 AND
                       g1.group_id=_group);
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

/*
   Returns category name by id
*/

CREATE OR REPLACE FUNCTION ossweb_category_name(INTEGER) RETURNS VARCHAR AS $$
BEGIN
   RETURN (SELECT category_name FROM ossweb_categories WHERE category_id=$1);
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION ossweb_category_sort(INTEGER) RETURNS INTEGER AS $$
BEGIN
   RETURN (SELECT sort FROM ossweb_categories WHERE category_id=$1);
END;$$ LANGUAGE 'plpgsql' STABLE STRICT;

/*
   Resource reservation verification.
   Returns id of the first conflicting record or 0 if no conflicts
*/
CREATE OR REPLACE FUNCTION ossweb_resource_check(VARCHAR,VARCHAR,TIMESTAMP WITH TIME ZONE,TIMESTAMP WITH TIME ZONE) RETURNS INTEGER AS $$
DECLARE
   _rs_type ALIAS FOR $1;
   _rs_name ALIAS FOR $2;
   _rs_start ALIAS FOR $3;
   _rs_end ALIAS FOR $4;
   rec RECORD;
BEGIN
   SELECT rs_id
   INTO rec
   FROM ossweb_resources
   WHERE rs_type=_rs_type AND
         rs_name=_rs_name AND
         (COALESCE(_rs_start,NOW()) BETWEEN rs_start AND COALESCE(rs_end,'2100-12-31 23:59:59') OR
          COALESCE(_rs_end,'2100-12-31 23:59:59') BETWEEN rs_start AND COALESCE(rs_end,'2100-12-31 23:59:59'))
   LIMIT 1;
   IF FOUND THEN
     RAISE NOTICE 'Resource taken: % % % % = %',_rs_type,_rs_name,_rs_start,_rs_end,rec.rs_id;
     RETURN rec.rs_id;
   END IF;
   RETURN 0;
END;$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION ossweb_resource_lock(VARCHAR,VARCHAR,TIMESTAMP WITH TIME ZONE,TIMESTAMP WITH TIME ZONE,VARCHAR,INTEGER) RETURNS INTEGER AS $$
DECLARE
   _rs_type ALIAS FOR $1;
   _rs_name ALIAS FOR $2;
   _rs_start ALIAS FOR $3;
   _rs_end ALIAS FOR $4;
   _rs_data ALIAS FOR $5;
   _rs_user ALIAS FOR $6;
BEGIN
   INSERT INTO ossweb_resources (rs_type,rs_name,rs_start,rs_end,rs_data,rs_user)
   VALUES(_rs_type,_rs_name,COALESCE(_rs_start,NOW()),_rs_end,_rs_data,_rs_user);
   RETURN CURRVAL('ossweb_resource_seq');
END;$$ LANGUAGE 'plpgsql' VOLATILE;

CREATE OR REPLACE FUNCTION ossweb_resource_trylock(VARCHAR,VARCHAR,TIMESTAMP WITH TIME ZONE,TIMESTAMP WITH TIME ZONE,VARCHAR,INTEGER) RETURNS INTEGER AS $$
DECLARE
   _rs_type ALIAS FOR $1;
   _rs_name ALIAS FOR $2;
   _rs_start ALIAS FOR $3;
   _rs_end ALIAS FOR $4;
   _rs_data ALIAS FOR $5;
   _rs_user ALIAS FOR $6;
BEGIN
   LOCK TABLE ossweb_resources IN ACCESS EXCLUSIVE MODE;
   IF ossweb_resource_check(_rs_type,_rs_name,_rs_start,_rs_end) > 0 THEN
     RETURN -1;
   END IF;
   RETURN ossweb_resource_lock(_rs_type,_rs_name,_rs_start,_rs_end,_rs_data,_rs_user);
END;$$ LANGUAGE 'plpgsql' VOLATILE;

CREATE OR REPLACE FUNCTION ossweb_resource_unlock(INTEGER,VARCHAR,VARCHAR,TIMESTAMP WITH TIME ZONE,TIMESTAMP WITH TIME ZONE) RETURNS BOOLEAN AS $$
DECLARE
   _rs_id ALIAS FOR $1;
   _rs_type ALIAS FOR $2;
   _rs_name ALIAS FOR $3;
   _rs_start ALIAS FOR $4;
   _rs_end ALIAS FOR $5;
BEGIN
   IF _rs_id IS NOT NULL THEN
     DELETE FROM ossweb_resources WHERE rs_id=_rs_id;
   ELSE
     DELETE FROM ossweb_resources
     WHERE rs_type=_rs_type AND
           rs_name=_rs_name AND
           rs_start=COALESCE(_rs_start,NOW()) AND
           COALESCE(rs_end,'2100-12-31 23:59:59')=COALESCE(_rs_end,'2100-12-31 23:59:59');
   END IF;
   IF FOUND THEN
     RETURN TRUE;
   END IF;
   RETURN FALSE;
END;$$ LANGUAGE 'plpgsql' VOLATILE;

/*
   State machine status verification, fires exception if given new status is not valid
   according to state machine rules.
*/

CREATE OR REPLACE FUNCTION state_machine_check(VARCHAR,VARCHAR,VARCHAR,BOOLEAN) RETURNS BOOLEAN AS $$
DECLARE
   _module ALIAS FOR $1;
   _new_status ALIAS FOR $2;
   _old_status ALIAS FOR $3;
   _exception ALIAS FOR $4;
   nrec RECORD;
   orec RECORD;
BEGIN
   SELECT status_name,
          COALESCE(states,'') AS states
   INTO nrec
   FROM ossweb_state_machine
   WHERE status_id=_new_status AND
         module=_module;
   IF NOT FOUND THEN
     IF NOT _exception THEN RETURN FALSE; END IF;
     RAISE EXCEPTION 'OSS: Unable to locate state "%.%".',_module,_new_status;
   END IF;
   /* Same state */
   IF _new_status = _old_status THEN
     RETURN TRUE;
   END IF;
   /* Verify correct state order */
   IF _old_status IS NOT NULL THEN
     SELECT status_name,
            COALESCE(states,'') AS states
     INTO orec
     FROM ossweb_state_machine
     WHERE status_id=_old_status AND
           module=_module;
     IF NOT FOUND THEN
       IF NOT _exception THEN RETURN FALSE; END IF;
       RAISE EXCEPTION 'OSS: Unable to locate state "%.%"',_module,_old_status;
     END IF;
     IF POSITION('<'||_new_status||'>' IN orec.states) = 0 THEN
       IF NOT _exception THEN RETURN FALSE; END IF;
       RAISE EXCEPTION 'OSS: Unable to set to "%" state after "%", incorrect state order for "%".',
                       nrec.status_name,orec.status_name,_module;
     END IF;
   ELSE
     /* Just check for initial status */
     IF POSITION('<'||_new_status||'>' IN nrec.states) = 0 THEN
       IF NOT _exception THEN RETURN FALSE; END IF;
       RAISE EXCEPTION 'OSS: "%.%" is not an initial state.',_module,nrec.status_name;
     END IF;
   END IF;
   RETURN TRUE;
END;$$ LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION state_machine_check(VARCHAR,VARCHAR,VARCHAR) RETURNS BOOLEAN AS $$
BEGIN
   RETURN state_machine_check($1,$2,$3,TRUE);
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns next state(s) from state machine, if all is TRUE returns a list with all
   allowed states
*/

CREATE OR REPLACE FUNCTION state_machine_next(VARCHAR,VARCHAR,BOOLEAN) RETURNS VARCHAR AS $$
   set _module $1
   set _status_id $2
   set _all $3
   set result ""

   if { ![info exists GD(state_machine_$_module)] } {
     set GD(state_machine_$_module) [spi_prepare "
             SELECT status_id,
                    status_name,
                    LTRIM(TRANSLATE(states,'<>',' ')) AS next
             FROM ossweb_state_machine
             WHERE module= \$1" varchar]
   }
   spi_execp $GD(state_machine_$_module) $_module {
     set status($status_id) $status_name
     if { ![info exists next] } { set next "" }
     set states($status_id) $next
   }
   if { ![info exists status($_status_id)] } { return "" }
   if { $_all != "t" } {
     # First state may be itself for initial states
     set state $states($_status_id)
     if { [lindex $state 0] == $_status_id } {
       set state [lindex $state 1]
     } else {
       set state [lindex $state 0]
     }
     if { [info exists status($state)] } {
       return "{$status($state)} $state"
     }
     return
   }
   # Return list of items in format for select boxes
   foreach state $states($_status_id) {
     if { [info exists status($state)] } {
       append result "{{$status($state)} $state} "
     }
   }
   return $result
$$ LANGUAGE 'pltcl' STABLE;

/*
   Returns TRUE if given state1 is after state2 in state machine states order.
*/

CREATE OR REPLACE FUNCTION state_machine_after(VARCHAR,VARCHAR,VARCHAR) RETURNS BOOLEAN AS $$
DECLARE
   _module ALIAS FOR $1;
   _status1 ALIAS FOR $2;
   _status2 ALIAS FOR $3;
   state VARCHAR;
BEGIN
   IF _status1 IS NULL OR
      _status2 IS NULL OR
      _status1 = _status2 OR
      state_machine_check(_module,_status1,_status2,FALSE) THEN
     RETURN TRUE;
   END IF;
   RETURN FALSE;
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns title for the given state id
*/

CREATE OR REPLACE FUNCTION state_machine_name(VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
DECLARE
   _module ALIAS FOR $1;
   _id ALIAS FOR $2;
   state VARCHAR;
BEGIN
   RETURN (SELECT status_name FROM ossweb_state_machine WHERE module=_module AND status_id=_id);
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns type for the given state id
*/

CREATE OR REPLACE FUNCTION state_machine_type(VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
DECLARE
   _module ALIAS FOR $1;
   _id ALIAS FOR $2;
   state VARCHAR;
BEGIN
   RETURN (SELECT type FROM ossweb_state_machine WHERE module=_module AND status_id=_id);
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Replaces given str1 in string str with new substring str2
*/

CREATE OR REPLACE FUNCTION str_replace(VARCHAR,VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
DECLARE
   _str ALIAS FOR $1;
   _str1 ALIAS FOR $2;
   _str2 ALIAS FOR $3;
   result VARCHAR;
   pos INTEGER;
   i INTEGER := 0;
BEGIN
   IF _str1 = '' THEN RETURN _str; END IF;
   result := _str;
   pos := POSITION(_str1 IN result);
   WHILE pos > 0 LOOP
     result := SUBSTR(result,1,pos-1) || _str2 || SUBSTR(result,pos+CHAR_LENGTH(_str1));
     pos := POSITION(_str1 IN result);
   END LOOP;
   RETURN result;
END;$$ LANGUAGE 'plpgsql' IMMUTABLE;

/*
   Returns nth element from string separated by given char
*/

CREATE OR REPLACE FUNCTION str_index(VARCHAR,INTEGER,VARCHAR) RETURNS VARCHAR AS $$
   set str $1
   set idx $2
   set delimiter $3

   return [lindex [split $str $delimiter] $idx]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

CREATE OR REPLACE FUNCTION str_index(VARCHAR,VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
   set str $1
   set idx $2
   set delimiter $3

   return [lindex [split $1 $3] $2]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

/* Returns specified word range from the string */

CREATE OR REPLACE FUNCTION str_range(VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
   set str $1
   set idx1 $2
   set idx2 $3
   set delimiter $4

   return [lrange [split $str $delimiter] $idx1 $idx2]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

/* Reformats given date */

CREATE OR REPLACE FUNCTION str_date(VARCHAR) RETURNS DATE AS $$
   if { [catch { set now [clock scan $1] }] } { set now 0 }
   return [clock format $now -format "%Y-%m-%d"]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

/* Return string with each word capitalized */

CREATE OR REPLACE FUNCTION str_totitle(VARCHAR,VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
   set str $1
   set upperwords $2
   set lowerwords $3

   set title ""
   foreach w $upperwords { set upper($w) 1 }
   foreach w $lowerwords { set lower($w) 1 }
   foreach word $str {
     set word [string totitle $word]
     if { [info exists lower($word)] } {
       set word [string tolower $word]
     } elseif { [info exists upper($word)] } {
       set word [string toupper $word]
     }
     lappend title $word
   }
   return [join $title]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

CREATE OR REPLACE FUNCTION str_totitle(VARCHAR) RETURNS VARCHAR AS $$
BEGIN
   RETURN str_totitle($1,NULL,NULL);
END;$$ LANGUAGE 'plpgsql' IMMUTABLE;

/*
 * Return hex representation of the string
 */
CREATE OR REPLACE FUNCTION str_tohex(VARCHAR) RETURNS VARCHAR AS $$
   set data $1
   set result ""
   for { set i 0 } { $i < [string length $data] } { incr i } {
     if { [scan [string index $data $i] "%c" val] } {
       append result [format "%02X" $val]
     }
   }
   return $result
$$ LANGUAGE 'pltcl' IMMUTABLE;


/*
   Returns length of the array from string separated by given char
*/

CREATE OR REPLACE FUNCTION str_length(VARCHAR,VARCHAR) RETURNS INTEGER AS $$
   set str $1
   set delimiter $2

   return [llength [split $str $delimiter]]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

/*
   Returns string repeated count number of times.
*/

CREATE OR REPLACE FUNCTION str_repeat(VARCHAR,INTEGER) RETURNS VARCHAR AS $$
   set str $1
   set repeat $2

   return [string repeat $str $repeat]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

/*
   Returns 1 if given value exists in given list
*/

CREATE OR REPLACE FUNCTION str_lexists(VARCHAR,VARCHAR) RETURNS BOOLEAN AS $$
   set list $1
   set word $2

   if { $list == "" || $word == "" } { return 1 }
   return [expr [lsearch -exact $list $word] > -1]
$$ LANGUAGE 'pltcl' IMMUTABLE;

CREATE OR REPLACE FUNCTION str_lexists(VARCHAR,INTEGER) RETURNS BOOLEAN AS $$
BEGIN
   IF $1 IS NULL OR $2 IS NULL THEN
     RETURN TRUE;
   END IF;
   RETURN str_lexists($1,$2::VARCHAR);
END;$$ LANGUAGE 'plpgsql' IMMUTABLE;

/*
   Perform convertion of substring based on map
*/

CREATE OR REPLACE FUNCTION str_map(VARCHAR,VARCHAR) RETURNS VARCHAR AS $$
   set str $1
   set map $2

   return [string map $map $str]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

CREATE OR REPLACE FUNCTION str_tclescape(VARCHAR) RETURNS VARCHAR AS $$
   set str $1

   return [string map { {[} {\[} {$} {\$} } $str]
END;$$ LANGUAGE 'pltcl' IMMUTABLE;

