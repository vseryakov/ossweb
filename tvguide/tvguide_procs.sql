/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   July 2001
*/

CREATE OR REPLACE FUNCTION tvguide_schedule_info(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT program_title,
                     program_subtitle,
                     description,
                     tvguide_program_genre(p.program_id) AS genre,
                     tvguide_program_crew(p.program_id) AS crew
              FROM tvguide_schedules sc,
                   tvguide_programs p
              WHERE schedule_id=$1 AND
                    sc.program_id=p.program_id LOOP
     result := rec.program_title||'' ''||
               COALESCE(rec.program_subtitle,'''')||
               COALESCE(rec.description,'''')||'' ''||
               COALESCE(rec.genre,'''')||'' ''||
               COALESCE(rec.crew,'''');
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION tvguide_program_genre(VARCHAR) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT genre FROM tvguide_genre WHERE program_id=$1 LOOP
     result := result||''"''||rec.genre||''" '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION tvguide_program_crew(VARCHAR) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT role,
                     COALESCE(givenname,'''') AS givenname,
                     COALESCE(surname,'''') AS surname
              FROM tvguide_crew
              WHERE program_id=$1 LOOP
     result := result||''"''||rec.role||''" "''||rec.givenname||''" "''||rec.surname||''" '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;
