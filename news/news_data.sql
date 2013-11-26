/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   September 2003
*/

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('News', '*', 'news', 'news', 'news.gif');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('news:country',
               'News Country',
               'News',
               'Country for which to receive news');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('news:enabled',
               'News Enabled',
               'News',
               'Enable the module, run in the schedule',
               '-type boolean');
