/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   December 2002
*/

CREATE OR REPLACE FUNCTION ossweb_bookmarks_trigger_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
BEGIN
   IF NEW.section IS NOT NULL THEN
     SELECT path INTO rec FROM ossweb_bookmarks WHERE bm_id=NEW.section;
     IF FOUND THEN
       NEW.path := rec.path||COALESCE(NEW.sort,NEW.bm_id)||''/'';
     END IF;
   ELSE
     NEW.path := ''0/''||COALESCE(NEW.sort,NEW.bm_id)||''/'';
   END IF;
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_bookmarks_trigger ON ossweb_bookmarks;
CREATE TRIGGER ossweb_bookmarks_trigger BEFORE INSERT OR UPDATE ON ossweb_bookmarks
FOR EACH ROW EXECUTE PROCEDURE ossweb_bookmarks_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_bookmarks_trigger2_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
BEGIN
   IF TG_OP = ''DELETE'' THEN
     IF OLD.url IS NULL THEN
       UPDATE ossweb_bookmarks SET section=NULL WHERE section=OLD.bm_id;
     END IF;
     RETURN NULL;
   END IF;
   /* Update children if folder has been moved */
   IF NEW.url IS NULL THEN
     UPDATE ossweb_bookmarks SET url=url WHERE section=NEW.bm_id;
   END IF;
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_bookmarks_trigger2 ON ossweb_bookmarks;
CREATE TRIGGER ossweb_bookmarks_trigger2 AFTER UPDATE OR DELETE ON ossweb_bookmarks
FOR EACH ROW EXECUTE PROCEDURE ossweb_bookmarks_trigger2_func();

