/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   October 2001
*/

CREATE SEQUENCE timesheet_seq START 100;

CREATE TABLE ts_jobs (
   job_id INTEGER DEFAULT NEXTVAL('timesheet_seq') NOT NULL,
   job_name VARCHAR NOT NULL,
   job_no VARCHAR NOT NULL,
   subjob_no VARCHAR NULL,
   description TEXT NULL,
   CONSTRAINT ts_job_pk PRIMARY KEY(job_id)
);

CREATE TABLE ts_hour_types (
   type_id VARCHAR NOT NULL,
   type_name VARCHAR NOT NULL,
   description TEXT NULL,
   CONSTRAINT ts_hour_types_pk PRIMARY KEY(type_id)
);

CREATE TABLE ts_costcode_types (
   type_id VARCHAR NOT NULL,
   type_name VARCHAR NOT NULL,
   description TEXT NULL,
   CONSTRAINT ts_costcode_types_pk PRIMARY KEY(type_id)
);

CREATE TABLE ts_costcodes (
   costcode_id INTEGER DEFAULT NEXTVAL('timesheet_seq') NOT NULL,
   costcode_code VARCHAR NOT NULL,
   costcode_type VARCHAR NOT NULL 
     CONSTRAINT ts_costcodetype_fk REFERENCES ts_costcode_types(type_id),
   costcode_name VARCHAR NULL,
   job_id INTEGER NOT NULL
     CONSTRAINT ts_costcodejob_fk REFERENCES ts_jobs(job_id),
   description TEXT,
   CONSTRAINT ts_costcodes_pk PRIMARY KEY(costcode_id),
   CONSTRAINT ts_costcodes_un UNIQUE(costcode_code,costcode_type,job_id)
);

CREATE TABLE ts_timesheets (
   ts_id INTEGER DEFAULT NEXTVAL('timesheet_seq') NOT NULL,
   ts_date DATE NOT NULL,
   ts_time TIME WITH TIME ZONE NULL,
   user_id INTEGER NOT NULL,
   job_id INTEGER NOT NULL
   CONSTRAINT ts_hour_job_fk REFERENCES ts_jobs(job_id),
   costcode_id INTEGER NOT NULL
     CONSTRAINT ts_tm_costcode_fk REFERENCES ts_costcodes(costcode_id),
   hour_code VARCHAR DEFAULT 'R' NOT NULL
     CONSTRAINT ts_tm_hourcode_fk REFERENCES ts_hour_types(type_id),
   hours INTERVAL NOT NULL,
   CONSTRAINT ts_timesheets_pk PRIMARY KEY(ts_id)
);

CREATE INDEX ts_timesheet_idx ON ts_timesheets(ts_date,user_id);

