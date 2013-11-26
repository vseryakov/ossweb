/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   Sptember 2003
*/

CREATE SEQUENCE news_seq;

CREATE TABLE news (
   news_id INTEGER NOT NULL,
   category VARCHAR DEFAULT 'GENERAL' NOT NULL,
   pubdate TIMESTAMP WITH TIME ZONE NOT NULL,
   link VARCHAR NOT NULL,
   title VARCHAR NOT NULL,
   description VARCHAR NULL
);

ALTER SEQUENCE news_seq OWNED BY news.news_id;

CREATE INDEX news_date_idx ON news(news_id);
CREATE INDEX news_title_idx ON news(title);

