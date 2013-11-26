/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   December 2001
*/

INSERT INTO ossweb_schedule (task_name,task_proc,task_interval,description)
       VALUES('Calendar Tracker','calendar::schedule::tracker',120,
              'Delivers calendar tracker notifications.');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Calendar', '*', 'calendar', 'calendar', 'calendar.gif');
