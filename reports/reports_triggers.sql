
CREATE OR REPLACE FUNCTION report_categories_trigger_func() RETURNS TRIGGER AS '
DECLARE
   rec RECORD;
   path_flag BOOLEAN := FALSE;
BEGIN
   IF NEW.category_parent = NEW.category_id THEN
     NEW.category_parent := NULL;
   END IF;
   IF TG_OP = ''INSERT'' THEN
     path_flag := TRUE;
   END IF;
   IF TG_OP = ''UPDATE'' THEN
     IF COALESCE(NEW.category_parent,'''') <> COALESCE(OLD.category_parent,'''') OR
        NEW.category_id <> OLD.category_id THEN
       path_flag := TRUE;
     END IF;
   END IF;
   IF path_flag THEN
     IF NEW.category_parent IS NOT NULL THEN
       SELECT category_path INTO rec FROM report_categories WHERE category_id=NEW.category_parent;
       IF FOUND THEN
         NEW.category_path := rec.category_path||NEW.category_id||''|'';
       END IF;
     ELSE
       NEW.category_path := NEW.category_id||''|'';
     END IF;
   END IF;
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER report_categories_trigger ON report_categories;
CREATE TRIGGER report_categories_trigger BEFORE INSERT OR UPDATE ON report_categories
FOR EACH ROW EXECUTE PROCEDURE report_categories_trigger_func();

CREATE OR REPLACE FUNCTION report_categories_trigger2_func() RETURNS TRIGGER AS '
BEGIN
   /* Update all children */
   IF COALESCE(NEW.category_parent,'''') <> COALESCE(OLD.category_parent,'''') OR
      NEW.category_id <> OLD.category_id THEN
     UPDATE report_categories SET category_path=NULL WHERE category_parent=NEW.category_id;
   END IF;
   RETURN NULL;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER report_categories_trigger2 ON report_categories;
CREATE TRIGGER report_categories_trigger2 AFTER UPDATE ON report_categories
    FOR EACH ROW EXECUTE PROCEDURE report_categories_trigger2_func();
