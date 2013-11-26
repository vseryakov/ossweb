/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   May 2008
*/

CREATE SEQUENCE youtube_seq;

CREATE TABLE youtube (
   id INTEGER NOT NULL DEFAULT NEXTVAL('youtube_seq'),
   episode VARCHAR NOT NULL,
   imageurl VARCHAR NULL,
   playurl VARCHAR NOT NULL,
   duration INTEGER NULL,
   category VARCHAR NULL,
   author VARCHAR NOT NULL,
   title VARCHAR NOT NULL,
   description VARCHAR NULL,
   views INTEGER NULL,
   rating FLOAT NULL,
   sort SMALLINT NULL,
   load_time TIMESTAMP WITH TIME ZONE NOT NULL,
   create_time TIMESTAMP WITH TIME ZONE NOT NULL,
   update_time TIMESTAMP WITH TIME ZONE NOT NULL,
   PRIMARY KEY(category,id)
);

CREATE INDEX youtube_idx ON youtube(episode);
