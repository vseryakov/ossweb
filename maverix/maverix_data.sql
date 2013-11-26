/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   March 2003
*/

INSERT INTO oss_schedule (task_name,task_proc,task_time,task_thread,description)
       VALUES('Maverix Daily Maintenance','maverix::schedule::daily','1:0','Y',
              'Daily mantenance');
INSERT INTO oss_schedule (task_name,task_proc,task_interval,task_thread,description)
       VALUES('Maverix Hourly Maintenance','maverix::schedule::hourly',3600,'Y',
              'Hourly mantenance');

INSERT INTO oss_apps (title,project_name,app_name,app_context,image,sort)
       VALUES('Maverix','ossweb','maverix','index','mail.gif',1);

INSERT INTO oss_config (name,value) VALUES('maverix:database','');
INSERT INTO oss_config (name,value) VALUES('maverix:hostname','');
INSERT INTO oss_config (name,value) VALUES('maverix:hostname:pop3','');
INSERT INTO oss_config (name,value) VALUES('maverix:stale','86400');
INSERT INTO oss_config (name,value) VALUES('maverix:history','172800');
INSERT INTO oss_config (name,value) VALUES('maverix:body:size','256');
INSERT INTO oss_config (name,value) VALUES('maverix:cache:size','15M');
INSERT INTO oss_config (name,value) VALUES('maverix:domain:relay','localhost');
INSERT INTO oss_config (name,value) VALUES('maverix:domain:local','');
INSERT INTO oss_config (name,value) VALUES('maverix:digest:history','86400');
INSERT INTO oss_config (name,value) VALUES('maverix:digest:start','7:00');
INSERT INTO oss_config (name,value) VALUES('maverix:digest:end','23:00');
INSERT INTO oss_config (name,value) VALUES('maverix:digest:sender','t');
INSERT INTO oss_config (name,value) VALUES('maverix:digest:interval','86400');
INSERT INTO oss_config (name,value) VALUES('maverix:user:admin','maverix@'||oss_hostname());
INSERT INTO oss_config (name,value) VALUES('maverix:user:type','VRFY');
INSERT INTO oss_config (name,value) VALUES('maverix:user:relay','');
INSERT INTO oss_config (name,value) VALUES('maverix:user:interval','600');
INSERT INTO oss_config (name,value) VALUES('maverix:sender:admin','maverix-sender@'||oss_hostname());
INSERT INTO oss_config (name,value) VALUES('maverix:sender:type','VRFY');
INSERT INTO oss_config (name,value) VALUES('maverix:sender:ignore','^<>$');
INSERT INTO oss_config (name,value) VALUES('maverix:sender:relay','');
INSERT INTO oss_config (name,value) VALUES('maverix:sender:interval','600');
INSERT INTO oss_config (name,value) VALUES('maverix:schedule:digest','60');
INSERT INTO oss_config (name,value) VALUES('maverix:schedule:sender','60');
INSERT INTO oss_config (name,value) VALUES('maverix:schedule:deliver','60');
