/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   November 2004
*/

CREATE TABLE radio (
   radio_url VARCHAR NOT NULL,
   radio_title VARCHAR NOT NULL,
   radio_genre VARCHAR NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   PRIMARY KEY(radio_url)
);

