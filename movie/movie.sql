/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   July 2004
*/

CREATE SEQUENCE movie_seq;

CREATE TABLE movies (
   movie_id INTEGER DEFAULT NEXTVAL('movie_seq') NOT NULL,
   movie_title VARCHAR NOT NULL,
   movie_descr VARCHAR NULL,
   movie_genre VARCHAR NULL,
   movie_lang VARCHAR NULL,
   movie_year INTEGER NULL,
   movie_age INTEGER NULL,
   movie_image VARCHAR NULL,
   imdb_id INTEGER NULL,
   watch_count INTEGER NULL,
   watch_time TIMESTAMP WITH TIME ZONE NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_time TIMESTAMP WITH TIME ZONE NULL,
   PRIMARY KEY(movie_id),
   UNIQUE(movie_title)
);

ALTER SEQUENCE movie_seq OWNED BY movies.movie_id;

CREATE TABLE movie_files (
   movie_id INTEGER NOT NULL REFERENCES movies(movie_id) ON DELETE CASCADE,
   disk_id INTEGER NULL,
   file_path VARCHAR NOT NULL,
   file_name VARCHAR NOT NULL,
   file_title VARCHAR NULL,
   file_params VARCHAR NULL,
   file_info VARCHAR NULL,
   file_size BIGINT NULL,
   file_pos INTEGER NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(movie_id,file_name)
);
