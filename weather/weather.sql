/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   December 2002
*/

CREATE TABLE weather (
   weather_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   weather_type VARCHAR(32) NOT NULL CHECK(weather_type IN ('Zone','Zipcode','Metar')),
   weather_id VARCHAR(32) NOT NULL,
   weather_data VARCHAR NOT NULL,
   CONSTRAINT weather_pk PRIMARY KEY (weather_date,weather_type,weather_id)
);
