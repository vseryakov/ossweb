/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   June 2004
*/


INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Music', '*', 'music', 'music', 'music.gif');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('music:player','Music Player','Music','Command for playback music files');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('music:player','mplayer -really-quiet -vo null @file@','Music','Command for playback music files');
