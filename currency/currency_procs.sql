/*
   Author: Alex Stetsyuk alex@tmatex.com
   Oct 2006

$Id:
*/


/* Returns Currency by ID */
CREATE OR REPLACE FUNCTION currency_get_name_for_id(INTEGER) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT name FROM currencies WHERE currency_id=$1);
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/* Returns Currency by ISO numeric code */
CREATE OR REPLACE FUNCTION currency_get_name_for_iso_num(VARCHAR) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT DISTINCT name FROM currencies WHERE iso_code_num=UPPER($1));
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/* Returns Currency by ISO alpha code */
CREATE OR REPLACE FUNCTION currency_get_name_for_iso_alpha(VARCHAR) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT DISTINCT name FROM currencies WHERE iso_code_alpha=UPPER($1));
END;' LANGUAGE 'plpgsql' STABLE STRICT;


/* Returns ISO alpha code by ID  */
CREATE OR REPLACE FUNCTION currency_get_iso_alpha_for_id(INTEGER) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT iso_code_alpha FROM currencies WHERE currency_id=$1);
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/* Returns ISO alpha code by ISO numeric code */
CREATE OR REPLACE FUNCTION currency_get_iso_alpha_for_iso_num(VARCHAR) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT DISTINCT iso_code_alpha FROM currencies WHERE iso_code_num=UPPER($1));
END;' LANGUAGE 'plpgsql' STABLE STRICT;


/* Returns ISO numeric code by ID  */
CREATE OR REPLACE FUNCTION currency_get_iso_num_for_id(INTEGER) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT iso_code_num FROM currencies WHERE currency_id=$1);
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/* Returns ISO alpha code by ISO numeric code */
CREATE OR REPLACE FUNCTION currency_get_iso_num_for_iso_alpha(VARCHAR) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT DISTINCT COALESCE(iso_code_num,''Nil'') FROM currencies WHERE iso_code_alpha=UPPER($1));
END;' LANGUAGE 'plpgsql' STABLE STRICT;



/* Returns list of Entities for ISO numeric code */
CREATE OR REPLACE FUNCTION currency_get_entity_for_iso_num(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _iso_code_num ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT entity
              FROM currencies
              WHERE iso_code_num = UPPER(_iso_code_num)
              ORDER BY entity LOOP
              result := result||'' { ''||COALESCE(value.entity,''Nil'')||'' } '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

/* Returns list of Entities for ISO alpha code */
CREATE OR REPLACE FUNCTION currency_get_entity_for_iso_alpha(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _iso_code_alpha ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT entity
              FROM currencies
              WHERE iso_code_alpha = UPPER(_iso_code_alpha)
              ORDER BY entity LOOP
              result := result||'' { ''||COALESCE(value.entity,''Nil'')||'' } '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

/* Returns list of Entities for ISO alpha code (for html)*/
CREATE OR REPLACE FUNCTION currency_get_entity_for_iso_alpha2(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _iso_code_alpha ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT entity
              FROM currencies
              WHERE iso_code_alpha = UPPER(_iso_code_alpha)
              ORDER BY entity LOOP
              result := result||COALESCE(value.entity,''Nil'')||'' :: '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;


/* Returns list of ISO numeric codes for Entity */
CREATE OR REPLACE FUNCTION currency_get_iso_num_for_entity(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _entity ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT iso_code_num
              FROM currencies
              WHERE UPPER(entity) ILIKE ''%''||UPPER(_entity)||''%''
              ORDER BY entity LOOP
              result := result||'' { ''||value.iso_code_num||'' } '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

/* Returns list of ISO alpha codes for Entity */
CREATE OR REPLACE FUNCTION currency_get_iso_alpha_for_entity(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _entity ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT iso_code_alpha
              FROM currencies
              WHERE UPPER(entity) ILIKE ''%''||UPPER(_entity)||''%''
              ORDER BY entity LOOP
              result := result||'' { ''||value.iso_code_alpha||'' } '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

/* Returns list of ISO numeric codes for Currency Name */
CREATE OR REPLACE FUNCTION currency_get_iso_num_for_name(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _name ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT DISTINCT iso_code_num
              FROM currencies
              WHERE UPPER(name) ILIKE ''%''||UPPER(_name)||''%''
              ORDER BY iso_code_num LOOP
              result := result||'' { ''||COALESCE(value.iso_code_num,''Nil'')||'' } '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

/* Returns list of ISO alpha codes for Currency Name */
CREATE OR REPLACE FUNCTION currency_get_iso_alpha_for_name(VARCHAR) RETURNS VARCHAR AS '
DECLARE
  _name ALIAS FOR $1;
  value RECORD;
  result VARCHAR := '''';
BEGIN
   FOR value IN SELECT DISTINCT iso_code_alpha
              FROM currencies
              WHERE UPPER(name) ILIKE ''%''||UPPER(_name)||''%''
              ORDER BY iso_code_alpha LOOP
              result := result||'' { ''||value.iso_code_alpha||'' } '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

/* Returns first matched Currency ID for ISO alpha code */
CREATE OR REPLACE FUNCTION currency_get_id_for_iso_alpha(VARCHAR) RETURNS INTEGER AS '
BEGIN
   RETURN (SELECT currency_id FROM currencies WHERE iso_code_alpha=$1 LIMIT 1);
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/* Returns matched Currency html symbol ISO alpha code */
CREATE OR REPLACE FUNCTION currency_get_html_for_iso_alpha(VARCHAR) RETURNS VARCHAR AS '
BEGIN
   RETURN (SELECT symbol_html FROM currencies WHERE iso_code_alpha=$1 LIMIT 1);
END;' LANGUAGE 'plpgsql' STABLE STRICT;


