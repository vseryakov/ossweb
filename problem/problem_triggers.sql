/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

CREATE OR REPLACE FUNCTION problem_projects_trigger_func() RETURNS TRIGGER AS $$
DECLARE
   rec RECORD;
   uid INTEGER;
BEGIN
   IF TG_OP = 'INSERT' THEN
     PERFORM state_machine_check('problem:project',NEW.status,NULL);
     NEW.create_date := NOW();
   ELSE
     IF NEW.status <> OLD.status THEN
       PERFORM state_machine_check('problem:project',NEW.status,OLD.status);
     END IF;
     NEW.create_date := OLD.create_date;
     IF NEW.status = 'closed' THEN
       NEW.close_date := NOW();
     END IF;
     /* Only owner can do such things */
     IF OLD.owner_id IS NOT NULL THEN
       IF NEW.user_id <> OLD.owner_id OR
          NEW.user_id NOT IN (SELECT user_id FROM problem_users WHERE role='Admin' AND project_id=NEW.project_id) THEN
         IF NEW.owner_id <> OLD.owner_id THEN
           RAISE EXCEPTION 'OSS: Only project owner can change the owner of the project';
         END IF;
         IF NEW.status <> OLD.status THEN
           RAISE EXCEPTION 'OSS: Only project owner can change the status of the project';
         END IF;
       END IF;
     END IF;
   END IF;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER problem_projects_trigger ON problem_projects;
CREATE TRIGGER problem_projects_trigger BEFORE INSERT OR UPDATE ON problem_projects
FOR EACH ROW EXECUTE PROCEDURE problem_projects_trigger_func();

CREATE OR REPLACE FUNCTION problems_trigger_func() RETURNS TRIGGER AS $$
DECLARE
   rec RECORD;
   uid INTEGER;
   ptype VARCHAR;
BEGIN
   IF TG_OP = 'DELETE' THEN
     IF OLD.problem_status NOT IN ('cancelled','deleted') THEN
       RAISE EXCEPTION 'OSSWEB: Unable to delete active problem';
     END IF;
     DELETE FROM problem_notes WHERE problem_id=OLD.problem_id;
     DELETE FROM problem_files WHERE problem_id=OLD.problem_id;
     IF OLD.cal_id IS NOT NULL THEN
       DELETE FROM ossweb_calendar WHERE cal_id=OLD.cal_id;
     END IF;
     RETURN OLD;
   END IF;

   IF NEW.owner_id IS NOT NULL THEN
     SELECT user_id INTO uid FROM problem_users WHERE project_id=NEW.project_id AND user_id=NEW.owner_id;
     IF NOT FOUND THEN
       RAISE EXCEPTION 'OSSWEB: Assigned person is not responsible for specified project';
     END IF;
   END IF;

   IF TG_OP = 'INSERT' THEN
     PERFORM state_machine_check('problem',NEW.problem_status,NULL);
     IF NEW.owner_id IS NULL THEN
       /* Get next available developer */
       IF ossweb_config('problem:policy','') = 'next' THEN
         LOCK TABLE problem_users IN ACCESS EXCLUSIVE MODE;
         SELECT user_id INTO uid FROM problem_users WHERE project_id=NEW.project_id ORDER BY job_no LIMIT 1;
         IF NOT FOUND THEN
           RAISE EXCEPTION 'OSSWEB: Problem should be assigned to someone directly or via projects';
         END IF;
         UPDATE problem_users SET job_no=job_no+1 WHERE user_id=uid AND project_id=NEW.project_id;
       END IF;

       /* Take one with least precedence */
       IF ossweb_config('problem:policy','') = 'priority' THEN
         SELECT user_id INTO uid FROM problem_users WHERE project_id=NEW.project_id ORDER BY COALESCE(precedence,0) DESC LIMIT 1;
       END IF;
       NEW.owner_id := uid;
     END IF;
   END IF;

   IF TG_OP = 'UPDATE' THEN
     SELECT type INTO ptype FROM ossweb_state_machine WHERE status_id=NEW.problem_status AND module='problem';
     IF NEW.problem_status <> OLD.problem_status THEN
       IF state_machine_after('problem',NEW.problem_status,OLD.problem_status) THEN
         PERFORM state_machine_check('problem',NEW.problem_status,OLD.problem_status);
       END IF;

       IF ptype = 'complete' THEN
         /* Auto complete */
         IF NEW.close_on_complete = TRUE THEN
           NEW.problem_status := 'closed';
           ptype := 'close';
         END IF;
       END IF;

       /* Cleanup calendar entry on close */
       IF ptype = 'close' THEN
         /* Cleanup calendar links */
         IF NEW.cal_id IS NOT NULL THEN
           DELETE FROM ossweb_calendar WHERE cal_id=NEW.cal_id;
           NEW.cal_id := NULL;
         END IF;

         /* Keep last closed date */
         NEW.close_date := NOW();
       END IF;
     END IF;

     /* Create/delete calendar reminder */
     IF NEW.cal_repeat = 'Unset' THEN
       NEW.cal_date := NULL;
     END IF;

     IF COALESCE(NEW.cal_date,NOW()) <> COALESCE(OLD.cal_date,NOW()) THEN
       IF NEW.cal_id IS NOT NULL THEN
         DELETE FROM ossweb_calendar WHERE cal_id=NEW.cal_id;
         NEW.cal_id := NULL;
       END IF;

       IF NEW.cal_date IS NOT NULL THEN
         INSERT INTO ossweb_calendar(cal_date,cal_time,subject,description,remind,remind_proc,remind_args,repeat,user_id)
         VALUES(NEW.cal_date::DATE,NEW.cal_date::TIME,NEW.title,NEW.description,
                '1 min','problem::tracker','problem_id '||NEW.problem_id,
                COALESCE(NEW.cal_repeat,'None'),NEW.user_id);
         NEW.cal_id := CURRVAL('ossweb_calendar_seq');
       END IF;
     END IF;
   END IF;

   NEW.problem_tags_idx := TO_TSVECTOR(NEW.problem_tags);
   NEW.update_date := NOW();
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER problems_trigger ON problems;
CREATE TRIGGER problems_trigger BEFORE INSERT OR UPDATE OR DELETE ON problems
FOR EACH ROW EXECUTE PROCEDURE problems_trigger_func();

CREATE OR REPLACE FUNCTION problem_notes_trigger_func() RETURNS TRIGGER AS $$
DECLARE
   rec RECORD;
BEGIN
   SELECT r.project_id,
          p.problem_status,
          p.user_id,
          p.owner_id,
          r.owner_id AS project_owner_id
   INTO rec
   FROM problems p,
        problem_projects r
   WHERE problem_id=NEW.problem_id AND
         p.project_id=r.project_id;

   /* Only who submitted or owner or admins can update with admin/close status */
   IF NEW.user_id <> rec.user_id AND
      NEW.user_id <> rec.project_owner_id AND
      NEW.user_id NOT IN (SELECT user_id FROM problem_users WHERE role='Admin' AND project_id=rec.project_id) AND
      state_machine_type('problem',NEW.problem_status) IN ('open','close') THEN
     RAISE EXCEPTION 'OSSWEB: Invalid status "%", only owner can set it',NEW.problem_status;
   END IF;

   /* Update problem status and/or owner */
   IF NEW.problem_status IS NOT NULL OR NEW.owner_id IS NOT NULL THEN
     /* Reset owner to project-wide responsibility */
     IF NEW.owner_id = -1 THEN
       NEW.owner_id := NULL;
       rec.owner_id := NULL;
     END IF;
     UPDATE problems
     SET problem_status=COALESCE(NEW.problem_status,rec.problem_status),
         owner_id=COALESCE(NEW.owner_id,rec.owner_id)
     WHERE problem_id=NEW.problem_id;
   END IF;

   NEW.problem_status := COALESCE(NEW.problem_status,rec.problem_status);
   NEW.owner_id := COALESCE(NEW.owner_id,rec.owner_id);

   /* Update last noe in the problem for qucik access */
   UPDATE problems
   SET last_note_text=NEW.description,
       last_note_date=NOW(),
       last_note_id=NEW.problem_note_id,
       percent_completed=CASE WHEN NEW.percent IS NOT NULL AND
                                   NEW.percent > COALESCE(percent_completed,0)
                              THEN NEW.percent
                              ELSE percent_completed
                         END
   WHERE problem_id=NEW.problem_id;
   RETURN NEW;
END;$$ LANGUAGE 'plpgsql';

DROP TRIGGER problem_notes_trigger ON problem_notes;
CREATE TRIGGER problem_notes_trigger BEFORE INSERT OR UPDATE ON problem_notes
FOR EACH ROW EXECUTE PROCEDURE problem_notes_trigger_func();

