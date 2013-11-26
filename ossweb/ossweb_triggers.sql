/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001

  $Id: ossweb_triggers.sql 2432 2006-12-05 23:59:24Z vlad $

*/

/*
   Trigger for checking for valid object id for ACL
*/
CREATE OR REPLACE FUNCTION ossweb_acl_trigger_func() RETURNS TRIGGER AS $$
DECLARE
   id INTEGER;
BEGIN
   SELECT user_id INTO id FROM ossweb_users WHERE user_id=NEW.obj_id;
   IF NOT FOUND THEN
     SELECT group_id INTO id FROM ossweb_groups WHERE group_id=NEW.obj_id;
     IF NOT FOUND THEN
       RAISE EXCEPTION 'OSSWEB:Invalid obj_id for acl, should be user_id or group_id';
     END IF;
   END IF;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_acl_trigger ON ossweb_acls;
CREATE TRIGGER ossweb_acl_trigger BEFORE INSERT OR UPDATE ON ossweb_acls
    FOR EACH ROW EXECUTE PROCEDURE ossweb_acl_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_apps_trigger_func() RETURNS TRIGGER AS $$
DECLARE
   rec RECORD;
BEGIN
   IF NEW.group_id IS NOT NULL THEN
     SELECT tree_path INTO rec FROM ossweb_apps WHERE app_id=NEW.group_id;
     IF FOUND THEN
       NEW.tree_path := rec.tree_path||NEW.sort||'/';
     END IF;
   ELSE
     NEW.tree_path := '0/'||NEW.sort||'/';
   END IF;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_apps_trigger ON ossweb_apps;
CREATE TRIGGER ossweb_apps_trigger BEFORE INSERT OR UPDATE ON ossweb_apps
    FOR EACH ROW EXECUTE PROCEDURE ossweb_apps_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_apps_trigger2_func() RETURNS TRIGGER AS $$
BEGIN
   IF NEW.page_name IS NULL AND NEW.url IS NULL THEN
     /* Update all folder children */
     UPDATE ossweb_apps SET tree_path=NULL WHERE group_id=NEW.app_id;
   END IF;
   RETURN NULL;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_apps_trigger2 ON ossweb_apps;
CREATE TRIGGER ossweb_apps_trigger2 AFTER UPDATE ON ossweb_apps
    FOR EACH ROW EXECUTE PROCEDURE ossweb_apps_trigger2_func();

CREATE OR REPLACE FUNCTION ossweb_task_trigger_func() RETURNS TRIGGER AS $$
BEGIN
   IF NEW.task_interval IS NULL AND
      NEW.task_time IS NULL THEN
     RAISE EXCEPTION 'OSS: Either Interval or Time should be specified';
   END IF;
   IF NEW.task_time IS NOT NULL AND NOT NEW.task_time ~ E'[0-9]+\:[0-9]+' THEN
     RAISE EXCEPTION 'OSS: Invalid Time';
   END IF;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_task_trigger ON ossweb_schedule;
CREATE TRIGGER ossweb_task_trigger BEFORE INSERT OR UPDATE ON ossweb_schedule
    FOR EACH ROW EXECUTE PROCEDURE ossweb_task_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_projects_trigger_func() RETURNS TRIGGER AS $$
DECLARE
   id INTEGER;
BEGIN
   IF TG_OP = 'DELETE' THEN
     RETURN OLD;
   END IF;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_projects_trigger ON ossweb_projects;
CREATE TRIGGER ossweb_projects_trigger BEFORE UPDATE OR DELETE ON ossweb_projects
    FOR EACH ROW EXECUTE PROCEDURE ossweb_projects_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_categories_trigger_func() RETURNS TRIGGER AS $$
BEGIN
   IF TG_OP = 'UPDATE' THEN
     IF NEW.sort <> OLD.sort THEN
       NEW.tree_path := NULL;
     END IF;
   END IF;
   NEW.sort := COALESCE(NEW.sort,NEW.category_id);
   IF NEW.category_parent IS NOT NULL THEN
     NEW.tree_path := (SELECT tree_path FROM ossweb_categories WHERE category_id=NEW.category_parent)||NEW.sort||'/';
   ELSE
     NEW.tree_path := NULL;
   END IF;
   NEW.tree_path := COALESCE(NEW.tree_path,'0/'||NEW.sort||'/');
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql' VOLATILE;

DROP TRIGGER ossweb_categories_trigger ON ossweb_categories;
CREATE TRIGGER ossweb_categories_trigger BEFORE INSERT OR UPDATE ON ossweb_categories
FOR EACH ROW EXECUTE PROCEDURE ossweb_categories_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_categories_trigger2_func() RETURNS TRIGGER AS $$
BEGIN
   IF NEW.tree_path <> OLD.tree_path THEN
     UPDATE ossweb_categories SET tree_path=NULL WHERE category_parent=NEW.category_id;
   END IF;
   RETURN NULL;
END;$$ LANGUAGE 'plpgsql' VOLATILE;

DROP TRIGGER ossweb_categories_trigger2 ON ossweb_categories;
CREATE TRIGGER ossweb_categories_trigger2 AFTER UPDATE ON ossweb_categories
FOR EACH ROW EXECUTE PROCEDURE ossweb_categories_trigger2_func();

CREATE OR REPLACE FUNCTION ossweb_resources_trigger_func() RETURNS TRIGGER AS $$
BEGIN
   IF NEW.rcs_start >= NEW.rcs_end THEN
     RAISE EXCEPTION 'OSSWEB: Start date should be before end date';
   END IF;
   IF ossweb_resource_check(NEW.rcs_type,NEW.rcs_name,NEW.rcs_start,NEW.rcs_end) > 0 THEN
     RAISE EXCEPTION 'OSSWEB: %:% cannot be reserved for % / % period',
           NEW.rcs_name,NEW.rcs_type,NEW.rcs_start,NEW.rcs_end;
   END IF;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql' VOLATILE;

DROP TRIGGER ossweb_resources_trigger ON ossweb_resources;
CREATE TRIGGER ossweb_resources_trigger BEFORE INSERT ON ossweb_resources
FOR EACH ROW EXECUTE PROCEDURE ossweb_resources_trigger_func();

CREATE OR REPLACE FUNCTION ossweb_tsearch_trigger_func() RETURNS TRIGGER AS $$
BEGIN
   NEW.tsearch_idx := TO_TSVECTOR(NEW.tsearch_text);
   NEW.tsearch_text := SUBSTRING(NEW.tsearch_text,1,128);
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_tsearch_trigger ON ossweb_tsearch;
CREATE TRIGGER ossweb_tsearch_trigger BEFORE UPDATE OR INSERT ON ossweb_tsearch
FOR EACH ROW EXECUTE PROCEDURE ossweb_tsearch_trigger_func();
