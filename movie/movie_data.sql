/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   June 2004
*/


INSERT INTO ossweb_user_types(type_id,type_name,description
       VALUES('children','Children','Kids');

INSERT INTO ossweb_user_types(type_id,type_name,description
       VALUES('teen','Teen','Teenager');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Movies', '*', 'movie', 'movie', 'film.gif');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('movie:disk:size','Movie Disk Size','Movie','Size of the one disk where movie files are kept');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('movie:player','Movie Player','Movie','Command for playback movies');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('movie:image','Movie Image','Movie','Default image for movies without cover');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('movie:informer','Movie Informer','Movie','Command for retrieving codec information from movie file');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES('movie:access:remote','Remote Access','Movie','Remote access enabled(1) or disabled(0)');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('movie:dirs','Movie Directories','Movie','List of directories with movies');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('movie:player','mplayer -really-quiet -vo xv,x11 @file@','Movie','Command for playback recorded shows');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('movie:informer','mplayer -quiet -vo null -ao null -frames 0 @file@','Movie','Command for retrieving codec information from movie file');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('movie:image','0.jpg','Movie','Default image for movies without cover');

