/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Forums', '*', 'forum', 'msgs', 'register.gif');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Forum Setup', '*', 'forum', 'forums', 'sheet.gif', 1);

INSERT INTO forums (forum_name,description,create_user)
       VALUES('OSSWEB Forum','Talk about OSSWEB',0);

INSERT INTO ossweb_config_types(type_id,type_name,module,description)
       VALUES('forum:prefix','Forums Prefix','Forum','Prefix to be used in forum emails');

INSERT INTO ossweb_config_types(type_id,type_name,module,description)
       VALUES('forum:url','Forums Url','Forum','Url to forum server');

INSERT INTO ossweb_config_types(type_id,type_name,module,description,widget)
       VALUES('forum:richtext','Forums Richtext','Forum','Use richtext web controls or just plain text', '-type boolean');
