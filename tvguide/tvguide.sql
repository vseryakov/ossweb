/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   June 2004
*/

CREATE SEQUENCE tvguide_seq;
CREATE SEQUENCE tvguide_alert_seq;
CREATE SEQUENCE tvguide_schedule_seq;

CREATE TABLE tvguide_lineups (
   lineup_id VARCHAR NOT NULL,
   lineup_name VARCHAR NOT NULL,
   lineup_type VARCHAR NOT NULL,
   lineup_location VARCHAR NULL,
   lineup_device VARCHAR NULL,
   lineup_zipcode VARCHAR NULL,
   PRIMARY KEY(lineup_id)
);

CREATE TABLE tvguide_stations (
   station_id INTEGER NOT NULL,
   station_name VARCHAR NOT NULL,
   station_label VARCHAR NOT NULL,
   affiliate VARCHAR NULL,
   channel_id SMALLINT NULL,
   PRIMARY KEY(station_id),
   UNIQUE(station_name),
   UNIQUE(station_label)
);

CREATE TABLE tvguide_channels (
   lineup_id VARCHAR NOT NULL REFERENCES tvguide_lineups(lineup_id) ON DELETE CASCADE,
   station_id INTEGER NOT NULL REFERENCES tvguide_stations(station_id) ON DELETE CASCADE,
   channel_id SMALLINT NOT NULL,
   start_date TIMESTAMP WITH TIME ZONE NOT NULL,
   PRIMARY KEY(lineup_id,station_id,channel_id)
);

CREATE TABLE tvguide_schedules (
   schedule_id INTEGER NOT NULL DEFAULT NEXTVAL('tvguide_schedule_seq'),
   station_id INTEGER NOT NULL REFERENCES tvguide_stations(station_id) ON DELETE CASCADE,
   program_id VARCHAR NOT NULL,
   start_time TIMESTAMP WITH TIME ZONE NOT NULL,
   duration INTERVAL NOT NULL,
   repeat BOOLEAN DEFAULT FALSE NOT NULL,
   stereo BOOLEAN DEFAULT FALSE NOT NULL,
   dolby BOOLEAN DEFAULT FALSE NOT NULL,
   dolby_digital BOOLEAN DEFAULT FALSE NOT NULL,
   hdtv BOOLEAN DEFAULT FALSE NOT NULL,
   subtitled BOOLEAN DEFAULT FALSE NOT NULL,
   closecaptioned BOOLEAN DEFAULT FALSE NOT NULL,
   tv_rating VARCHAR NULL REFERENCES tv_ratings(rating_id),
   part_number SMALLINT NULL,
   part_total SMALLINT NULL,
   PRIMARY KEY(station_id,program_id,start_time),
   UNIQUE(start_time,station_id,program_id),
   UNIQUE(schedule_id)
);

CREATE INDEX tvguide_sch_prog_idx ON tvguide_schedules(program_id);

CREATE TABLE tvguide_programs (
   program_id VARCHAR NOT NULL,
   program_title VARCHAR NOT NULL,
   program_subtitle VARCHAR NULL,
   program_type VARCHAR NULL,
   program_date TIMESTAMP WITH TIME ZONE NULL,
   program_year SMALLINT NULL,
   episode_number VARCHAR NULL,
   series_id VARCHAR NULL,
   runtime_id VARCHAR NULL,
   mpaarating VARCHAR NULL,
   starrating VARCHAR NULL,
   description VARCHAR NULL,
   PRIMARY KEY(program_id)
);

CREATE TABLE tvguide_crew (
   program_id VARCHAR NOT NULL REFERENCES tvguide_programs(program_id) ON DELETE CASCADE,
   role VARCHAR NOT NULL,
   givenname VARCHAR DEFAULT '' NOT NULL,
   surname VARCHAR DEFAULT '' NOT NULL,
   PRIMARY KEY(program_id,role,givenname,surname)
);

CREATE TABLE tvguide_genre (
   program_id VARCHAR NOT NULL REFERENCES tvguide_programs(program_id) ON DELETE CASCADE,
   genre VARCHAR NOT NULL,
   relevance SMALLINT DEFAULT 0 NULL,
   PRIMARY KEY(program_id,genre)
);

CREATE TABLE tvguide_recorder (
   recorder_id INTEGER DEFAULT NEXTVAL('tvguide_seq') NOT NULL,
   device_name VARCHAR NULL,
   file_status VARCHAR DEFAULT 'Scheduled' NOT NULL,
   file_name VARCHAR NULL,
   file_log VARCHAR NULL,
   user_id INTEGER NULL,
   lineup_id VARCHAR NOT NULL,
   lineup_name VARCHAR NOT NULL,
   lineup_type VARCHAR NOT NULL,
   lineup_location VARCHAR NULL,
   lineup_device VARCHAR NULL,
   lineup_zipcode VARCHAR NULL,
   station_id INTEGER NOT NULL,
   station_name VARCHAR NOT NULL,
   station_label VARCHAR NOT NULL,
   affiliate VARCHAR NULL,
   program_id VARCHAR NOT NULL,
   program_title VARCHAR NOT NULL,
   program_subtitle VARCHAR NULL,
   program_type VARCHAR NULL,
   program_date TIMESTAMP WITH TIME ZONE NULL,
   program_year SMALLINT NULL,
   program_genre VARCHAR NULL,
   program_crew VARCHAR NULL,
   episode_number VARCHAR NULL,
   series_id VARCHAR NULL,
   runtime_id VARCHAR NULL,
   mpaarating VARCHAR NULL,
   starrating VARCHAR NULL,
   description VARCHAR NULL,
   channel_id INTEGER NOT NULL,
   start_time TIMESTAMP WITH TIME ZONE NOT NULL,
   duration INTERVAL NOT NULL,
   tvrating VARCHAR NULL,
   stereo BOOLEAN NULL,
   closecaptioned BOOLEAN NULL,
   part_number SMALLINT NULL,
   part_total SMALLINT NULL,
   watch_count INTEGER NULL,
   watch_time TIMESTAMP WITH TIME ZONE NULL,
   PRIMARY KEY(recorder_id),
   UNIQUE(start_time,lineup_id,channel_id,station_id,program_id)
);

CREATE TABLE tvguide_alerts (
   alert_id INTEGER DEFAULT NEXTVAL('tvguide_alert_seq') NOT NULL,
   program VARCHAR NULL,
   actor VARCHAR NULL,
   email VARCHAR NOT NULL,
   user_id INTEGER NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(alert_id)
);
