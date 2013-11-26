/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   July 2001
*/

CREATE OR REPLACE FUNCTION movie_files(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT file_path FROM movie_files WHERE movie_id=$1 ORDER BY file_name LOOP
     result := result||''"''||rec.file_path||''" '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION movie_disk_files(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT file_path FROM movie_files WHERE disk_id=$1 ORDER BY file_name LOOP
     result := result||''"''||rec.file_path||''" '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION movie_files2(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT file_path||COALESCE(file_params,'''') AS file_path,
                     file_info,
		     disk_id 
	      FROM movie_files 
	      WHERE movie_id=$1 ORDER BY file_name LOOP
     result := result||''"''||rec.file_path||''" {''||COALESCE(rec.file_info,'''')||''} ''||COALESCE(rec.disk_id,-1)||'' '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

CREATE OR REPLACE FUNCTION movie_disks(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT DISTINCT disk_id FROM movie_files WHERE movie_id=$1 LOOP
     result := result||rec.disk_id||'' '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;
