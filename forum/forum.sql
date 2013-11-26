/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   March 2004
*/

CREATE SEQUENCE forum_seq;
CREATE SEQUENCE forum_msg_seq;
CREATE SEQUENCE forum_topic_seq;

CREATE TABLE forums (
   forum_id INTEGER DEFAULT NEXTVAL('forum_seq') NOT NULL,
   forum_name VARCHAR NOT NULL,
   forum_type VARCHAR(32) DEFAULT 'Public' NOT NULL,
   forum_status VARCHAR(32) DEFAULT 'Active' NOT NULL,
   description VARCHAR NULL,
   msg_count INTEGER DEFAULT 0 NOT NULL,
   msg_timestamp TIMESTAMP WITH TIME ZONE NULL,
   create_user INTEGER NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(forum_id)
);

ALTER SEQUENCE forum_seq OWNED BY forums.forum_id;

CREATE TABLE forum_topics (
   topic_id INTEGER DEFAULT NEXTVAL('forum_topic_seq') NOT NULL,
   forum_id INTEGER NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE,
   subject VARCHAR NOT NULL,
   msg_count INTEGER DEFAULT 0 NOT NULL,
   msg_timestamp TIMESTAMP WITH TIME ZONE NULL,
   msg_text VARCHAR NULL,
   user_id INTEGER NULL,
   user_name VARCHAR NULL,
   hidden_flag BOOLEAN DEFAULT FALSE NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(topic_id)
);

ALTER SEQUENCE forum_topic_seq OWNED BY forum_topics.topic_id;

CREATE INDEX forum_topics_idx ON forum_topics(forum_id,create_date);

CREATE TABLE forum_messages (
   msg_id INTEGER DEFAULT NEXTVAL('forum_msg_seq') NOT NULL,
   topic_id INTEGER NOT NULL REFERENCES forum_topics(topic_id) ON DELETE CASCADE,
   forum_id INTEGER NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE,
   msg_parent INTEGER NULL REFERENCES forum_messages(msg_id) ON DELETE CASCADE,
   body VARCHAR NULL,
   user_id INTEGER NULL,
   user_name VARCHAR NULL,
   tree_path VARCHAR NULL,
   hidden_flag BOOLEAN DEFAULT FALSE NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(msg_id)
);

ALTER SEQUENCE forum_msg_seq OWNED BY forum_messages.msg_id;

CREATE INDEX forum_messages_idx ON forum_messages(topic_id,create_date);

CREATE TABLE forum_emails (
   email VARCHAR NOT NULL,
   forum_id INTEGER NOT NULL REFERENCES forums(forum_id) ON DELETE CASCADE,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   user_id INTEGER NULL,
   PRIMARY KEY(forum_id,email)
);

