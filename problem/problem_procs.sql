/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

/*
   Send notification email about problem ticket

    If quiet_flag == t which means notify only assigned person
    If quiet_flag == f that means notify everybody
    If quiet_flag == NULL send only to assigned and admins
*/

CREATE OR REPLACE FUNCTION problem_email(INTEGER,INTEGER,VARCHAR,VARCHAR) RETURNS INTEGER AS $$
BEGIN
   RETURN problem_email($1,$2,$3,$4,FALSE);
END;$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION problem_email(INTEGER,INTEGER,VARCHAR,VARCHAR,BOOLEAN) RETURNS INTEGER AS $$
DECLARE
   _problem_id ALIAS FOR $1;
   _user_id ALIAS FOR $2;
   _description ALIAS FOR $3;
   _cc_list ALIAS FOR $4;
   _quiet_flag ALIAS FOR $5;
   rec RECORD;
   pbm RECORD;
   usr RECORD;
   alert_url VARCHAR;
   subject VARCHAR;
   body VARCHAR;
   email VARCHAR := '';
   email_cc VARCHAR := '';
   quiet VARCHAR := '';
BEGIN
   SELECT first_name||' '||last_name AS name,user_email INTO usr FROM ossweb_users WHERE user_id=_user_id;
   IF NOT FOUND THEN
     RETURN -1;
   END IF;
   IF _quiet_flag IS NOT NULL THEN
      IF _quiet_flag THEN
         quiet = 't';
      ELSE
         quiet = 'f';
      END IF;
   END IF;
   SELECT problem_id,
          project_name,
          b.problem_type,
          b.problem_status,
          b.project_id,
          b.user_id,
          b.owner_id,
          b.due_date,
          b.title,
          b.description,
          b.alert_on_complete,
          b.problem_cc,
          b.last_note_text,
          s.status_name,
          t.type_name,
          p.email_on_update,
          problem_files(problem_id,NULL) AS files,
          p.owner_id AS project_owner_id,
          ossweb_user_email(p.owner_id) AS project_owner_email,
          u1.user_email AS user_email,
          u1.first_name||' '||u1.last_name AS user_name,
          u2.user_email AS owner_email,
          u2.first_name||' '||u2.last_name AS owner_name
   INTO pbm
   FROM problems b
        LEFT OUTER JOIN ossweb_users u2
          ON u2.user_id=b.owner_id,
        ossweb_users u1,
        problem_projects p,
        problem_types t,
        ossweb_state_machine s
   WHERE u1.user_id=b.user_id AND
         b.project_id=p.project_id AND
         b.problem_status=s.status_id AND
         b.problem_type=t.type_id AND
         module='problem' AND
         b.problem_id=_problem_id;
   IF NOT FOUND THEN
     RETURN -2;
   END IF;
   /* Determine should we send alert or not */
   IF (pbm.email_on_update = FALSE) OR
      (POSITION(pbm.problem_status IN ossweb_config('problem:alert:status','open')) = 0 AND
       POSITION(pbm.problem_type IN ossweb_config('problem:alert:type','problem,feature')) = 0 AND
       (pbm.problem_status = 'completed' AND pbm.alert_on_complete <> TRUE) AND _cc_list IS NULL) THEN
     RETURN -3;
   END IF;
   /* If problem url is configured create link by id */
   alert_url := ossweb_config('problem:url',NULL);

   subject := '['||ossweb_config('problem:email:prefix','OSSWEB')||': '||pbm.type_name||']: '||
              pbm.status_name||': '||
              pbm.title;

   body := '<STYLE> .t {font-family:Verdana,Arial,Helvetica;} '||
           '.d {font-family:Verdana,Arial,Helvetica;background-color:#EEEEEE;} '||
           '.l {color:green;} </STYLE>'||
           CASE WHEN alert_url IS NOT NULL THEN
           '<SPAN CLASS=l>ID</SPAN>: <A HREF='||alert_url||'&problem_id='||pbm.problem_id||'>'||pbm.problem_id||'</A><BR>'
           ELSE
           '<SPAN CLASS=l>ID</SPAN>: '||pbm.problem_id||'<BR>'
           END ||
           '<SPAN CLASS=l>TYPE</SPAN>: '||pbm.type_name||'<BR>'||
           '<SPAN CLASS=l>STATUS</SPAN>: '||pbm.status_name||'<BR>'||
           '<SPAN CLASS=l>PROJECT</SPAN>: '||pbm.project_name||'<BR>'||
           '<SPAN CLASS=l>OPENED BY</SPAN>: '||pbm.user_name||'<BR>'||
           '<SPAN CLASS=l>SUBMITTED BY</SPAN>: '||usr.name||'<BR>'||
           CASE WHEN pbm.owner_name IS NOT NULL THEN
           '<SPAN CLASS=l>ASSIGNED TO</SPAN>: '||COALESCE(pbm.owner_name,'')||'<BR>'
           ELSE ''
           END||
           CASE WHEN pbm.due_date IS NOT NULL THEN
           '<SPAN CLASS=l>DUE DATE</SPAN>: '||COALESCE(pbm.due_date,NOW()+'1 day')||'<BR>'
           ELSE ''
           END||
           CASE WHEN pbm.files <> '' THEN
           '<SPAN CLASS=l>FILES</SPAN>: '||pbm.files||'<BR>'
           ELSE ''
           END||
           '<SPAN CLASS=l>SUBJECT</SPAN>: <SPAN CLASS=t>'||pbm.title||'</SPAN><BR><BR>'||
           '<DIV CLASS=d>'||COALESCE(_description,COALESCE(pbm.last_note_text,pbm.description))||'</DIV>';

   /*  Build email list, do not include the user who is submitting */
   IF _user_id <> pbm.user_id THEN
     email := email||pbm.user_email||',';
   END IF;
   IF _user_id <> COALESCE(pbm.owner_id,_user_id) THEN
     email := email||pbm.owner_email||',';
   END IF;
   /* Notify everybody on the project */
   IF quiet = 'f' THEN
     FOR rec IN SELECT user_email
                FROM problem_users p,
                     ossweb_users u
                WHERE p.project_id=pbm.project_id AND
                      p.user_id <> _user_id AND
                      p.user_id=u.user_id AND
                      status='active' LOOP
       email := email||rec.user_email||',';
     END LOOP;
   END IF;
   /* Project level cc email list */
   IF COALESCE(pbm.problem_cc,'') <> '' AND quiet <> 't' THEN
     email_cc := email_cc||pbm.problem_cc||',';
   END IF;
   /* Add optional CC list */
   IF COALESCE(_cc_list,'') <> '' THEN
     email_cc := email_cc||_cc_list||',';
   END IF;
   IF email = '' THEN
     email := email_cc;
   END IF;
   /* Safety checks */
   IF email = '' THEN
     RETURN -4;
   END IF;
   IF body IS NULL THEN
     RETURN -5;
   END IF;
   email_cc := 'MIME-Version 1.0 Content-Type text/html Cc {'||email_cc||'}';
   /* Bcc to project manager and all admins */
   IF quiet <> 't' THEN
     IF COALESCE(pbm.project_owner_id,_user_id) <> _user_id THEN
       email_cc := email_cc||' Bcc {'||pbm.project_owner_email||'}';
     END IF;
     FOR rec IN SELECT user_email
                FROM problem_users p,
                     ossweb_users u
                WHERE p.project_id=pbm.project_id AND
                      p.user_id <> _user_id AND
                      p.user_id=u.user_id AND
                      status='active' AND
                      role='Admin' LOOP
        email_cc := email_cc||' Bcc {'||rec.user_email||'}';
     END LOOP;
   END IF;
   RAISE NOTICE 'PROBLEM:NOTE: %, Quiet: %, Subject: %, Sent:%,%', _problem_id, quiet, subject, email, email_cc;
   RETURN ossweb_message_event('email',email,usr.user_email,subject,body,email_cc);
END;$$ LANGUAGE 'plpgsql';

/*
   Returns problem files
*/
CREATE OR REPLACE FUNCTION problem_files(INTEGER,INTEGER) RETURNS VARCHAR AS $$
DECLARE
  _problem_id ALIAS FOR $1;
  _problem_note_id ALIAS FOR $2;
  result VARCHAR := '';
  rec RECORD;
BEGIN
  FOR rec IN SELECT name
             FROM problem_files
             WHERE problem_id=_problem_id AND
                   (_problem_note_id IS NULL OR
                    _problem_note_id=problem_note_id)
             ORDER BY precedence LOOP
    result := result||' "'||rec.name||'" ';
  END LOOP;
  RETURN result;
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns problem users
*/
CREATE OR REPLACE FUNCTION problem_users(INTEGER) RETURNS VARCHAR AS $$
DECLARE
  _problem_id ALIAS FOR $1;
  result VARCHAR := '';
  rec RECORD;
BEGIN
  FOR rec IN SELECT r.user_id,
                    first_name||' '||last_name AS user_name,
                    user_email,
                    r.role
             FROM problem_users r,
                  problems p,
                  ossweb_users u
             WHERE p.problem_id=_problem_id AND
                   p.project_id=r.project_id AND
                   r.user_id=u.user_id LOOP
    result := result||' '||rec.user_id||' "'||rec.user_name||'" "'||rec.user_email||'" "'||COALESCE(rec.role,'')||'"';
  END LOOP;
  RETURN result;
END;$$ LANGUAGE 'plpgsql' STABLE;

/*
   Returns TRUE if given user has access to given project
*/

/*
   Returns number of folowups for the given problem
*/

CREATE OR REPLACE FUNCTION problem_notes_count(INTEGER,INTEGER) RETURNS VARCHAR AS $$
DECLARE
  _problem_id ALIAS FOR $1;
  _user_id ALIAS FOR $2;
  rec RECORD;
  count INTEGER := 0;
  timestamp INTEGER := 0;
  new BOOLEAN := FALSE;
BEGIN
  FOR rec IN SELECT user_id,
                    ROUND(EXTRACT(EPOCH FROM create_date)) AS create_time
             FROM problem_notes
             WHERE problem_id=_problem_id
             ORDER BY create_date LOOP
    count := count + 1;
    new := CASE WHEN rec.user_id <> _user_id THEN TRUE ELSE FALSE END;
    timestamp := rec.create_time;
  END LOOP;
  RETURN count||' '||CASE WHEN new THEN 't' ELSE 'f' END||' '||timestamp;
END;$$ LANGUAGE 'plpgsql' STABLE;


/*
   Re-open problem
*/

CREATE OR REPLACE FUNCTION problem_reopen(INTEGER) RETURNS BOOLEAN AS $$
DECLARE
  _problem_id ALIAS FOR $1;
  rec RECORD;
BEGIN
   SELECT user_id INTO rec
   FROM problems
   WHERE problem_id=_problem_id AND
         state_machine_after('problem','open',problem_status);
   IF FOUND THEN
     UPDATE problems SET problem_status='open' WHERE problem_id=_problem_id;
     PERFORM problem_email(_problem_id,rec.user_id,NULL,NULL,TRUE);
     RETURN TRUE;
  END IF;
  RETURN FALSE;
END;$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION problem_project_avail(INTEGER,INTEGER,INTEGER) RETURNS BOOLEAN AS $$
DECLARE
  _project_id ALIAS FOR $1;
  _user_id ALIAS FOR $2;
  _problem_id ALIAS FOR $3;
  rec RECORD;
BEGIN
  SELECT 1 INTO rec
  FROM problem_projects p
  WHERE project_id=_project_id AND
        (type='Public' OR
         owner_id=_user_id OR
         (type='Private' AND
          EXISTS(SELECT 1
                 FROM problem_users u
                 WHERE p.project_id=u.project_id AND
                       u.user_id=_user_id)));
  IF FOUND THEN
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END;$$ LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION problem_project_avail(INTEGER,INTEGER) RETURNS BOOLEAN AS $$
BEGIN
  RETURN problem_project_avail($1,$2,NULL);
END;$$ LANGUAGE 'plpgsql' STABLE;
