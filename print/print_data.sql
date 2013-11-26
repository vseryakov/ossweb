/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   September 2003
*/

INSERT INTO ossweb_schedule (task_name,task_proc,task_interval,task_thread,description)
       VALUES('Print Spooler','print::schedule',60,'Y',
              'Prints files from the queue.');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Print', '*', 'print', 'print', 'print.gif');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Print Queue', '*', 'print', 'queue', 'print.gif',(SELECT app_id FROM ossweb_apps WHERE title='Setup'));
