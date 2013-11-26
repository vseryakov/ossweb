/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

CREATE OR REPLACE FUNCTION timesheet_week(DATE) RETURNS VARCHAR AS '
DECLARE
   _ts_date ALIAS FOR $1;
   result VARCHAR;
   d INTEGER;
   d0 INTEGER;
   i INTEGER;
BEGIN
   result := TO_CHAR(_ts_date,''YYYY-MM-DD'');
   d0 := EXTRACT(dow FROM _ts_date);
   d := 1;
   i := d0 - 1;
   WHILE i >= 1 LOOP
     result := TO_CHAR(_ts_date-d,''YYYY-MM-DD'')||'' ''||result;
     i := i - 1;
     d := d + 1;
   END LOOP;
   d := 1;
   i := d0 + 1;
   WHILE i > d0 AND i < 8 LOOP
     result := result||'' ''||TO_CHAR(_ts_date+d,''YYYY-MM-DD'');
     i := i + 1;
     d := d + 1;
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' IMMUTABLE;
