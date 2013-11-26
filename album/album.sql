/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   May 2004
*/

CREATE SEQUENCE album_seq;

CREATE TABLE albums (
   album_id INTEGER DEFAULT NEXTVAL('album_seq') NOT NULL,
   album_name VARCHAR NOT NULL,
   album_type VARCHAR(32) DEFAULT 'Public' NOT NULL
     CONSTRAINT album_type_ck CHECK(album_type IN ('Public','Private','Group')),
   album_status VARCHAR(32) DEFAULT 'Active' NOT NULL
     CONSTRAINT album_status_ck CHECK (album_status IN ('Active','Inactive')),
   description VARCHAR NULL,
   user_id INTEGER NOT NULL REFERENCES ossweb_users(user_id),
   row_size INTEGER NULL,
   page_size INTEGER NULL,
   photo_count INTEGER DEFAULT 0 NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT albums_pk PRIMARY KEY(album_id)
);

ALTER SEQUENCE album_seq OWNED BY albums.album_id;

CREATE TABLE album_photos (
   photo_id INTEGER DEFAULT NEXTVAL('album_seq') NOT NULL,
   album_id INTEGER NOT NULL
     CONSTRAINT album_photo_fk REFERENCES albums(album_id) ON DELETE CASCADE,
   image VARCHAR NOT NULL,
   width SMALLINT NULL,
   height SMALLINT NULL,
   description VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT album_photos_pk PRIMARY KEY(photo_id)
);

CREATE INDEX album_photos_idx ON album_photos(album_id,create_date);

