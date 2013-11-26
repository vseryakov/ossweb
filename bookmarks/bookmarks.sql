/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   December 2002
*/

CREATE SEQUENCE ossweb_bookmarks_seq;

CREATE TABLE ossweb_bookmarks (
   bm_id INTEGER DEFAULT NEXTVAL('ossweb_bookmarks_seq') NOT NULL,
   user_id INTEGER NOT NULL,
   title VARCHAR NOT NULL,
   url VARCHAR NULL,
   section INTEGER NULL,
   path VARCHAR NULL,
   sort INTEGER NULL,
   CONSTRAINT bookmark_pk PRIMARY KEY (bm_id),
   CONSTRAINT bookmark_un UNIQUE (user_id,title,section)
);

ALTER SEQUENCE ossweb_bookmarks_seq OWNED BY ossweb_bookmarks.bm_id;
