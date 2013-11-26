/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   March 2003
*/

CREATE SEQUENCE maverix_seq START 1;
CREATE SEQUENCE maverix_msg_seq START 1;
CREATE SEQUENCE maverix_sender_seq START 1;

CREATE TABLE maverix_messages (
   msg_id INTEGER DEFAULT NEXTVAL('maverix_msg_seq') NOT NULL,
   sender_email VARCHAR NOT NULL,
   body VARCHAR NOT NULL,
   body_size INTEGER NOT NULL,
   body_offset INTEGER DEFAULT 0 NOT NULL,
   subject VARCHAR NULL,
   attachments VARCHAR NULL,
   virus_status VARCHAR NULL,
   signature VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(msg_id)
);
CREATE INDEX maverix_messages_snd_idx ON maverix_messages(sender_email);

CREATE TABLE maverix_users (
   user_email VARCHAR NOT NULL,
   user_type VARCHAR(32) DEFAULT 'VRFY' NOT NULL CHECK (user_type IN ('VRFY','PASS','DROP')),
   digest_id VARCHAR NULL,
   digest_email VARCHAR NULL,
   digest_date TIMESTAMP WITH TIME ZONE DEFAULT '2000-01-01' NOT NULL,
   digest_update TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   digest_interval INTEGER NULL,
   digest_count INTEGER DEFAULT 0 NOT NULL,
   digest_start TIME NULL,
   digest_end TIME NULL,
   sender_digest_flag BOOLEAN NULL,
   page_size INTEGER DEFAULT 40 NOT NULL,
   body_size INTEGER NULL,
   spam_autolearn_flag BOOLEAN NULL,
   spam_status VARCHAR NULL,
   spam_score_white FLOAT NULL,
   spam_score_black FLOAT NULL,
   anti_virus_flag VARCHAR DEFAULT 'PASS' NOT NULL CHECK (anti_virus_flag IN ('DROP','VRFY','PASS')),
   user_name VARCHAR NULL,
   password VARCHAR NULL,
   session_id VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(user_email)
);

CREATE TABLE maverix_user_aliases (
   user_email VARCHAR NOT NULL REFERENCES maverix_users(user_email) ON DELETE CASCADE,
   alias_email VARCHAR NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(user_email,alias_email),
   UNIQUE(alias_email,user_email)
);

CREATE TABLE maverix_user_messages (
   user_email VARCHAR NOT NULL REFERENCES maverix_users(user_email) ON DELETE CASCADE,
   msg_id INTEGER NOT NULL REFERENCES maverix_messages(msg_id),
   msg_status VARCHAR(32) DEFAULT 'NEW' NOT NULL CHECK(msg_status IN ('NEW','PASS','DROP')),
   deliver_email VARCHAR NOT NULL,
   deliver_count SMALLINT DEFAULT 0 NOT NULL,
   deliver_error VARCHAR NULL,
   spam_score FLOAT NULL,
   spam_status VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(user_email,msg_id,deliver_email)
);

CREATE TABLE maverix_senders (
   user_email VARCHAR NOT NULL REFERENCES maverix_users(user_email) ON DELETE CASCADE,
   sender_email VARCHAR NOT NULL,
   sender_type VARCHAR(32) DEFAULT 'VRFY' NOT NULL CHECK (sender_type IN ('VRFY','PASS','DROP')),
   sender_method VARCHAR(32) DEFAULT 'Default' NOT NULL,
   sender_digest_flag BOOLEAN NULL,
   digest_id VARCHAR NULL,
   digest_date TIMESTAMP WITH TIME ZONE DEFAULT '2000-01-01' NOT NULL,
   digest_update TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   digest_count INTEGER DEFAULT 0 NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(user_email,sender_email),
   UNIQUE(sender_email,user_email)
);

CREATE TABLE maverix_sender_log (
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   user_email VARCHAR NOT NULL REFERENCES maverix_users(user_email) ON DELETE CASCADE,
   sender_email VARCHAR NOT NULL,
   subject VARCHAR NULL,
   spam_score FLOAT NULL,
   spam_status VARCHAR NULL,
   virus_status VARCHAR NULL,
   reason VARCHAR NULL
);

CREATE INDEX maverix_sender_log_idx ON maverix_sender_log(user_email,sender_email);
