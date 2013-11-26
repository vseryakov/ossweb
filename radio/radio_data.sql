/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   November 2004
*/


INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Radio', '*', 'radio', 'radio', 'radio.gif');

INSERT INTO ossweb_config_types (type_id,type_name,description,module)
       VALUES ('radio:player','Radio Player','Command for playback radio urls','Radio');

INSERT INTO ossweb_config (name,value,description,module)
       VALUES('radio:player','vlc ''@file@''','Command for playback rado urls','Radio');
