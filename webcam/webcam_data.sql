/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   August 2004
*/

INSERT INTO ossweb_config_types (type_id,type_name,description)
       VALUES ('webcam:path','Webcam Path','Path to webcam images');
INSERT INTO ossweb_config_types (type_id,type_name,description)
       VALUES ('webcam:history','Webcam History','For how long to keep images, in seconds');
INSERT INTO ossweb_config_types (type_id,type_name,description)
       VALUES ('webcam:refresh','Webcam Refresh','How often to refresh webcam page, in seconds');
INSERT INTO ossweb_config_types (type_id,type_name,description)
       VALUES ('webcam:devices','Webcam Devices','Video devices in format: device[:width:height:brightness:contrast:input:norm] ...');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Web Camera', '*', 'webcam', 'webcam', 'webcam.gif');

INSERT INTO ossweb_schedule (task_name,task_proc,task_interval,task_thread,description)
       VALUES('Webcam Grabber','webcam::schedule',60,'N',
              'Grabs images from web camera.');
