
CREATE SEQUENCE reports_seq START 1;

CREATE TABLE report_categories (
   category_id VARCHAR NOT NULl,
   category_name VARCHAR NOT NULL,
   category_parent VARCHAR NULL,
   category_path VARCHAR NULL,
   description VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT report_cat_pk PRIMARY KEY(category_id)
);

CREATE TABLE report_types (
   report_id INTEGER DEFAULT NEXTVAL('reports_seq') NOT NULL,
   report_name VARCHAR NOT NULL,
   report_type VARCHAR NOT NULL,
   report_version SMALLINT DEFAULT 1 NOT NULL,
   report_acl VARCHAR NULL,
   xql_id VARCHAR NOT NULL,
   dbpool_name VARCHAR NULL,
   form_script VARCHAR NULL,
   before_script VARCHAR NULL,
   eval_script VARCHAR NULL,
   after_script VARCHAR NULL,
   template VARCHAR NULL,
   disable_flag BOOLEAN NOT NULL DEFAULT FALSE,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   run_date TIMESTAMP WITH TIME ZONE NULL,
   run_user INTEGER NULL,
   run_count INTEGER DEFAULT 0 NULL,
   CONSTRAINT report_pk PRIMARY KEY(report_id)
);
