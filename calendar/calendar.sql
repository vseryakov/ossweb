/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   December 2001
*/

CREATE SEQUENCE ossweb_calendar_seq;

CREATE TABLE ossweb_calendar (
   cal_id INTEGER DEFAULT NEXTVAL('ossweb_calendar_seq') NOT NULL,
   cal_date DATE NOT NULL,
   cal_time TIME DEFAULT '0:0' NOT NULL,
   cal_owner INTEGER NULL,
   duration INTERVAL NULL,
   remind INTERVAL NULL,
   remind_type VARCHAR NULL,
   remind_email VARCHAR NULL,
   remind_proc VARCHAR NULL,
   remind_args VARCHAR NULL,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id),
   repeat VARCHAR DEFAULT 'None' NOT NULL CHECK(repeat IN ('None','Weekly','Monthly','Yearly','Daily')),
   type VARCHAR DEFAULT 'Normal' NOT NULL CHECK(type IN ('Private','Public','Normal')),
   subject VARCHAR NOT NULL,
   description TEXT NULL,
   update_user INTEGER NULL,
   update_time TIMESTAMP WITH TIME ZONE NULL,
   PRIMARY KEY(cal_id)
);

ALTER SEQUENCE ossweb_calendar_seq OWNED BY ossweb_calendar.cal_id;

CREATE INDEX ossweb_calendar_idx ON ossweb_calendar(cal_date,user_id);
CREATE INDEX ossweb_calendar_owner_idx ON ossweb_calendar(cal_owner,cal_date);

CREATE TABLE ossweb_calendar_reminders (
   cal_id INTEGER NOT NULL,
   cal_date DATE NOT NULL,
   cal_time TIME NOT NULL,
   user_id INTEGER NOT NULL,
   PRIMARY KEY(cal_id,cal_date,cal_time,user_id)
);

CREATE TABLE ossweb_calendar_tracker (
   tracker_id VARCHAR NOT NULL,
   tracker_interval INTERVAL DEFAULT '1 min' NOT NULL,
   tracker_redirect VARCHAR NULL,
   tracker_type VARCHAR NULL,
   tracker_key VARCHAR NULL,
   tracker_time TIMESTAMP WITH TIME ZONE NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   send_time TIMESTAMP WITH TIME ZONE NULL,
   update_time TIMESTAMP WITH TIME ZONE NULL,
   status VARCHAR DEFAULT 'New' NOT NULL,
   cal_id INTEGER NOT NULL,
   user_id INTEGER NOT NULL,
   precedence INTEGER NOT NULL,
   PRIMARY KEY(tracker_id)
);

CREATE INDEX ossweb_calendar_tracker_idx ON ossweb_calendar_tracker(cal_id);
CREATE INDEX ossweb_calendar_tracker_idx2 ON ossweb_calendar_tracker(status);
CREATE INDEX ossweb_calendar_tracker_idx3 ON ossweb_calendar_tracker(tracker_key);

