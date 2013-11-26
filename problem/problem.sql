/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

CREATE SEQUENCE problem_seq;

CREATE TABLE problem_types (
   type_id VARCHAR NOT NULL CHECK(type_id <> ''),
   type_name VARCHAR NOT NULL,
   description VARCHAR NULL,
   precedence INTEGER NULL,
   PRIMARY KEY(type_id),
   UNIQUE(type_name)
);

CREATE TABLE problem_priorities (
   priority_id SMALLINT NOT NULL,
   priority_name VARCHAR NOT NULL,
   description VARCHAR NULL,
   PRIMARY KEY(priority_id),
   UNIQUE(priority_name)
);

CREATE TABLE problem_severities (
   severity_id SMALLINT NOT NULL,
   severity_name VARCHAR NOT NULL,
   description VARCHAR NULL,
   PRIMARY KEY(severity_id),
   UNIQUE(severity_name)
);

CREATE TABLE problem_projects (
   project_id INTEGER DEFAULT NEXTVAL('problem_seq') NOT NULL,
   project_name VARCHAR NOT NULL,
   problem_type VARCHAR NULL REFERENCES problem_types(type_id),
   status VARCHAR DEFAULT 'active' NOT NULL,
   type VARCHAR DEFAULT 'Public' NOT NULL,
   description VARCHAR NULL,
   owner_id INTEGER NULL REFERENCES ossweb_users(user_id),
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   close_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   email_on_update BOOLEAN DEFAULT TRUE NOT NULL,
   app_name VARCHAR NULL,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id),
   PRIMARY KEY(project_id)
);

CREATE TABLE problem_users (
   project_id INTEGER NOT NULL REFERENCES problem_projects(project_id) ON DELETE CASCADE,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id),
   job_no INTEGER DEFAULT 0 NOT NULL,
   role VARCHAR NULL,
   precedence INTEGER NULL,
   PRIMARY KEY(project_id,user_id)
);

CREATE TABLE problems (
   problem_id INTEGER DEFAULT NEXTVAL('problem_seq') NOT NULL,
   project_id INTEGER NOT NULL REFERENCES problem_projects(project_id),
   problem_status VARCHAR NOT NULL,
   problem_type VARCHAR DEFAULT 'Problem' NOT NULL REFERENCES problem_types(type_id),
   priority SMALLINT DEFAULT 0 NOT NULL,
   severity SMALLINT DEFAULT 0 NOT NULL,
   title VARCHAR NOT NULL,
   due_date TIMESTAMP WITH TIME ZONE NULL,
   close_on_complete BOOLEAN DEFAULT FALSE NOT NULL,
   alert_on_complete BOOLEAN DEFAULT FALSE NOT NULL,
   owner_id INTEGER NULL REFERENCES ossweb_users(user_id),
   description VARCHAR NULL,
   hours_required FLOAT NULL,
   percent_completed FLOAT NULL,
   problem_cc VARCHAR NULL,
   last_note_id INTEGER NULL,
   last_note_date TIMESTAMP WITH TIME ZONE NULL,
   last_note_text VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NULL,
   close_date TIMESTAMP WITH TIME ZONE NULL,
   cal_date TIMESTAMP WITH TIME ZONE NULL,
   cal_repeat VARCHAR NULL,
   cal_id INTEGER NULL,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id),
   problem_tags VARCHAR NULL,
   problem_tags_idx TSVECTOR NULL,
   PRIMARY KEY(problem_id)
);

ALTER SEQUENCE problem_seq OWNED BY problems.problem_id;

CREATE INDEX problem_tags_idx ON problems USING GIST(problem_tags_idx);

CREATE TABLE problem_notes (
   problem_note_id INTEGER DEFAULT NEXTVAL('problem_seq') NOT NULL,
   problem_id INTEGER NOT NULL REFERENCES problems(problem_id) ON DELETE CASCADE,
   problem_status VARCHAR NULL,
   description TEXT NULL,
   hours FLOAT NULL,
   percent FLOAT NULL,
   svn_file VARCHAR NULL,
   svn_revision INTEGER NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id),
   owner_id INTEGER NULL REFERENCES ossweb_users(user_id),
   PRIMARY KEY(problem_note_id)
);

CREATE TABLE problem_files (
   problem_id INTEGER NOT NULL REFERENCES problems(problem_id) ON DELETE CASCADE,
   name VARCHAR NOT NULL,
   problem_note_id INTEGER NULL REFERENCES problem_notes(problem_note_id),
   precedence INTEGER NULL,
   PRIMARY KEY(problem_id,name)
);

CREATE TABLE problem_favorites (
   owner INTEGER NOT NULL,
   name VARCHAR NOT NULL,
   filter VARCHAR NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id) ON DELETE CASCADE,
   PRIMARY KEY(owner,name)
);

