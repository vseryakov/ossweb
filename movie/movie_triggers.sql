/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

CREATE OR REPLACE FUNCTION movie_files_trigger_func() RETURNS TRIGGER AS '
DECLARE
   id INTEGER;
BEGIN
   NEW.file_name := str_index(NEW.file_name,''end'',''/'');
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER movie_files_trigger ON movie_files;
CREATE TRIGGER movie_files_trigger BEFORE INSERT OR UPDATE ON movie_files
    FOR EACH ROW EXECUTE PROCEDURE movie_files_trigger_func();
