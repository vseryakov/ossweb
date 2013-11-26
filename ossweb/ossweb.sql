/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001

  $Id: ossweb.sql 2873 2007-01-27 23:18:38Z vlad $

*/

CREATE SEQUENCE ossweb_user_seq START 10;
CREATE SEQUENCE ossweb_session_seq START 10;
CREATE SEQUENCE ossweb_util_seq START 1;
CREATE SEQUENCE ossweb_reftable_seq START 1;
CREATE SEQUENCE ossweb_apps_seq START 10;
CREATE SEQUENCE ossweb_acl_seq START 10;
CREATE SEQUENCE ossweb_message_seq START 1;
CREATE SEQUENCE ossweb_file_seq START 1;
CREATE SEQUENCE ossweb_category_seq START 1;
CREATE SEQUENCE ossweb_resource_seq START 1;
CREATE SEQUENCE ossweb_tsearch_seq START 1;

CREATE TABLE ossweb_msgs (
   msg_id INTEGER DEFAULT NEXTVAL('ossweb_util_seq') NOT NULL,
   msg_name VARCHAR NOT NULL,
   description VARCHAR NOT NULL,
   PRIMARY KEY(msg_name),
   UNIQUE (msg_id)
);

CREATE TABLE ossweb_groups (
   group_id INTEGER DEFAULT NEXTVAL('ossweb_user_seq') NOT NULL,
   group_name VARCHAR NOT NULL,
   short_name VARCHAR NULL,
   description VARCHAR NULL,
   precedence INTEGER NULL,
   PRIMARY KEY(group_id),
   UNIQUE(group_name)
);

CREATE TABLE ossweb_user_types (
   type_id VARCHAR NOT NULL CHECK(type_id != ''),
   type_name VARCHAR NOT NULL,
   description VARCHAR NULL,
   PRIMARY KEY(type_id),
   UNIQUE(type_name)
);

CREATE TABLE ossweb_users (
   user_id INTEGER DEFAULT NEXTVAL('ossweb_user_seq') NOT NULL,
   user_type VARCHAR DEFAULT 'user' NOT NULL REFERENCES ossweb_user_types(type_id),
   user_name VARCHAR NOT NULL,
   password VARCHAR NOT NULL,
   salt VARCHAR NOT NULL,
   salt2 VARCHAR NULL,
   status VARCHAR DEFAULT 'active' NOT NULL,
   first_name VARCHAR NOT NULL,
   middle_name VARCHAR NULL,
   last_name VARCHAR NOT NULL,
   user_email VARCHAR NOT NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   start_page VARCHAR NULL,
   PRIMARY KEY(user_id),
   UNIQUE(user_name)
);

ALTER SEQUENCE ossweb_user_seq OWNED BY ossweb_users.user_id;

CREATE TABLE ossweb_user_sessions (
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id) ON DELETE CASCADE,
   session_id VARCHAR NOT NULL,
   ipaddr VARCHAR(16) NOT NULL,
   login_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
   access_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
   create_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
   logout_time TIMESTAMP WITH TIME ZONE NULL,
   PRIMARY KEY(user_id,session_id)
);

CREATE TABLE ossweb_user_properties (
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id) ON DELETE CASCADE,
   session_id VARCHAR NOT NULL,
   name VARCHAR NOT NULL,
   value VARCHAR NULL,
   timeout INTERVAL NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(user_id,session_id,name)
);

CREATE TABLE ossweb_user_groups (
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id) ON DELETE CASCADE,
   group_id INTEGER NOT NULL REFERENCES ossweb_groups(group_id),
   PRIMARY KEY(user_id,group_id)
);

CREATE TABLE ossweb_prefs (
   obj_id INTEGER NOT NULL,
   obj_type CHAR(1) NOT NULL CHECK(obj_type IN ('U','G')),
   name VARCHAR NOT NULL,
   value VARCHAR NULL,
   PRIMARY KEY(obj_id,obj_type,name)
);

CREATE TABLE ossweb_acls (
   acl_id INTEGER DEFAULT NEXTVAL('ossweb_acl_seq') NOT NULL,
   obj_id INTEGER NOT NULL,
   obj_type CHAR(1) NOT NULL CHECK(obj_type IN ('U','G')),
   project_name VARCHAR NOT NULL,
   app_name VARCHAR NOT NULL,
   page_name VARCHAR NOT NULL,
   cmd_name VARCHAR NOT NULL,
   ctx_name VARCHAR NOT NULL,
   value CHAR(1) NOT NULL CHECK(value IN ('Y','N')),
   query VARCHAR NULL,
   handlers VARCHAR NULL,
   precedence INTEGER NULL,
   PRIMARY KEY(acl_id)
);

ALTER SEQUENCE ossweb_acl_seq OWNED BY ossweb_acls.acl_id;

CREATE TABLE ossweb_apps (
   app_id INTEGER DEFAULT NEXTVAL('ossweb_apps_seq') NOT NULL,
   app_version smallint DEFAULT 1 NOT NULL,
   title VARCHAR NOT NULL,
   host_name VARCHAR NULL,
   project_name VARCHAR NOT NULL,
   app_name VARCHAR NULL,
   page_name VARCHAR NULL,
   url VARCHAR NULL,
   image VARCHAR NULL,
   path VARCHAR NULL,
   sort INTEGER DEFAULT NEXTVAL('ossweb_apps_seq') NOT NULL,
   target VARCHAR NULL,
   group_id INTEGER NULL REFERENCES ossweb_apps(app_id),
   tree_path VARCHAR NULL,
   condition VARCHAR NULL,
   PRIMARY KEY(app_id),
   UNIQUE(title,project_name,app_name)
);

ALTER SEQUENCE ossweb_apps_seq OWNED BY ossweb_apps.app_id;

CREATE TABLE ossweb_projects (
   project_id VARCHAR NOT NULL,
   project_name VARCHAR NOT NULL,
   project_url VARCHAR NULL,
   project_logo VARCHAR NULL,
   project_info VARCHAR NULL,
   project_footer VARCHAR NULL,
   project_logo_bg VARCHAR NULL,
   project_bg VARCHAR NULL,
   project_style VARCHAR NULL,
   menu_x INTEGER NULL,
   menu_y INTEGER NULL,
   menu_height INTEGER NULL,
   login_url VARCHAR NULL,
   error_url VARCHAR NULL,
   description VARCHAR NULL,
   PRIMARY KEY(project_id)
);

CREATE TABLE ossweb_help (
   help_id INTEGER DEFAULT NEXTVAL('ossweb_util_seq') NOT NULL,
   project_name VARCHAR DEFAULT '*' NOT NULL,
   app_name VARCHAR DEFAULT '*' NOT NULL,
   page_name VARCHAR DEFAULT '*' NOT NULL,
   cmd_name VARCHAR DEFAULT '*' NOT NULL,
   ctx_name VARCHAR DEFAULT '*' NOT NULL,
   title VARCHAR NOT NULL,
   text VARCHAR NOT NULL,
   UNIQUE(project_name,app_name,page_name,cmd_name,ctx_name),
   PRIMARY KEY(help_id)
);

CREATE TABLE ossweb_reftable (
   app_name VARCHAR NULL,
   page_name VARCHAR NOT NULL,
   table_name VARCHAR NOT NULL,
   object_name VARCHAR NOT NULL,
   title VARCHAR NOT NULL,
   refresh VARCHAR NULL,
   extra_name VARCHAR NULL,
   extra_label VARCHAR NULL,
   extra_name2 VARCHAR NULL,
   extra_label2 VARCHAR NULL,
   precedence CHAR(1) DEFAULT 'N' CHECK (precedence IN ('Y','N')),
   PRIMARY KEY(app_name,page_name,table_name)
);

/*
   Background schedule tasks
*/
CREATE TABLE ossweb_schedule (
   task_id INTEGER DEFAULT NEXTVAL('ossweb_util_seq') NOT NULL,
   task_name VARCHAR NOT NULL,
   task_proc VARCHAR NOT NULL,
   task_args VARCHAR NULL,
   task_day VARCHAR NULL,
   task_time VARCHAR NULL,
   task_wday VARCHAR NULL,
   task_mday VARCHAR NULL,
   task_interval INTEGER NULL,
   task_thread BOOLEAN DEFAULT FALSE,
   task_once BOOLEAN DEFAULT FALSE,
   task_disabled BOOLEAN DEFAULT FALSE,
   task_server VARCHAR NULL,
   description VARCHAR NULL,
   schedule_id INTEGER NULL,
   PRIMARY KEY(task_id),
   UNIQUE(task_name,task_proc,task_server)
);

ALTER SEQUENCE ossweb_util_seq OWNED BY ossweb_schedule.task_id;

/*
   Global config parameters
*/
CREATE TABLE ossweb_config (
   name VARCHAR NOT NULL,
   value VARCHAR NULL,
   module VARCHAR NULL,
   description VARCHAR NULL,
   PRIMARY KEY(name)
);

/*
   Config parameters with description
*/
CREATE TABLE ossweb_config_types (
   type_id VARCHAR NOT NULL,
   type_name VARCHAR NOT NULL,
   description VARCHAR NULL,
   module VARCHAR NULL,
   widget VARCHAR NULL,
   PRIMARY KEY(type_id),
   UNIQUE(type_name)
);

/*
   Pending message queue
*/
CREATE TABLE ossweb_message_queue (
   message_id INTEGER DEFAULT NEXTVAL('ossweb_message_seq') NOT NULL,
   message_type VARCHAR NOT NULL,
   sent_flag VARCHAR DEFAULT 'N' NOT NULL CHECK(sent_flag IN ('Y','N')),
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   lifetime INTERVAL NULL,
   try_count SMALLINT DEFAULT 0 NOT NULL,
   error_msg VARCHAR NULL,
   rcpt_to VARCHAR NOT NULL,
   mail_from VARCHAR NOT NULL,
   subject VARCHAR NOT NULL,
   body VARCHAR NOT NULL,
   args VARCHAR NULL,
   PRIMARY KEY(message_id)
);

ALTER SEQUENCE ossweb_message_seq OWNED BY ossweb_message_queue.message_id;

/*
   State machine
*/
CREATE TABLE ossweb_state_machine (
   status_id VARCHAR NOT NULL CHECK(status_id != ''),
   module VARCHAR NOT NULL,
   status_name VARCHAR NOT NULL,
   type VARCHAR NOT NULL,
   states VARCHAR NULL,
   sort SMALLINT NOT NULL,
   description VARCHAR NULL,
   PRIMARY KEY(status_id,module)
);

/*
   General purpose categories
*/
CREATE TABLE ossweb_categories (
   category_id INTEGER DEFAULT NEXTVAL('ossweb_category_seq') NOT NULL,
   category_name VARCHAR NOT NULL,
   category_parent INTEGER NULL,
   module VARCHAR NULL,
   tree_path VARCHAR NULL,
   sort INTEGER NOT NULL,
   color VARCHAR NULL,
   bgcolor VARCHAR NULL,
   description VARCHAR NULL,
   PRIMARY KEY(category_id),
   UNIQUE(category_name,module)
);

ALTER SEQUENCE ossweb_category_seq OWNED BY ossweb_categories.category_id;

CREATE INDEX ossweb_category_idx ON ossweb_categories(sort,module);

/*
   Resource locking
*/

CREATE TABLE ossweb_resources (
   rs_id INTEGER DEFAULT NEXTVAL('ossweb_resource_seq') NOT NULL,
   rs_name VARCHAR NOT NULL,
   rs_type VARCHAR NOT NULL,
   rs_start TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
   rs_end TIMESTAMP WITH TIME ZONE NULL,
   rs_data VARCHAR NULL,
   rs_user INTEGER NULL,
   PRIMARY KEY(rs_id)
);

ALTER SEQUENCE ossweb_resource_seq OWNED BY ossweb_resources.rs_id;

CREATE INDEX ossweb_resources_name_idx ON ossweb_resources(rs_name,rs_type);
CREATE INDEX ossweb_resources_type_idx ON ossweb_resources(rs_type,rs_name);
CREATE INDEX ossweb_resources_date_idx ON ossweb_resources(rs_start,rs_end);

/*
   Full text search
*/

CREATE TABLE ossweb_tsearch (
   tsearch_key INTEGER NOT NULL DEFAULT NEXTVAL('ossweb_tsearch_seq'),
   tsearch_id VARCHAR NOT NULL,
   tsearch_type VARCHAR NOT NULL,
   tsearch_text VARCHAR NULL,
   tsearch_data VARCHAR NULL,
   tsearch_value VARCHAR NULL,
   tsearch_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
   tsearch_idx TSVECTOR NULL,
   PRIMARY KEY(tsearch_key)
);

ALTER SEQUENCE ossweb_tsearch_seq OWNED BY ossweb_tsearch.tsearch_key;

CREATE INDEX ossweb_tsearch_idx ON ossweb_tsearch USING GIST(tsearch_idx);
CREATE INDEX ossweb_tsearch_id_idx ON ossweb_tsearch(tsearch_id,tsearch_type);
CREATE INDEX ossweb_tsearch_type_idx ON ossweb_tsearch(tsearch_type,tsearch_id);
