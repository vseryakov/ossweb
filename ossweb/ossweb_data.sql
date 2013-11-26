/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001

  $Id: ossweb_data.sql 2864 2007-01-26 05:02:59Z vlad $

*/

INSERT INTO ossweb_apps (app_id, title, project_name, app_name, image, sort)
       VALUES (1, 'Setup', '*', 'admin', 'open.gif', 9990);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image,sort)
       VALUES ('Search', '*', 'main', 'search', 'search.gif', 9991);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image,sort)
       VALUES ('Prefs', '*', 'main', 'prefs', 'prefs.gif', 9995);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, sort)
       VALUES ('Logout', '*', 'pub', 'logout', 'logout.gif', 9999);

INSERT INTO ossweb_schedule (task_name,task_proc,task_time,task_thread,description)
       VALUES('Daily Maintenance','ossweb::schedule::daily','0:30','Y',
              'Daily maintanence, like session cleanup and etc.');

INSERT INTO ossweb_schedule (task_name,task_proc,task_time,task_thread,task_wday,description)
       VALUES('Weekly Maintenance','ossweb::schedule::weekly','1:0','Y','0',
              'Weekly maintanence, like session cleanup and etc.');

INSERT INTO ossweb_schedule (task_name,task_proc,task_time,task_thread,task_mday,description)
       VALUES('Monthly Maintenance','ossweb::schedule::monthly','1:0','Y','1',
              'Monthly maintanence, like session cleanup and etc.');

INSERT INTO ossweb_user_types (type_id,type_name,description)
       VALUES('employee','Employee','Employee user');

INSERT INTO ossweb_user_types (type_id,type_name,description)
       VALUES('user','Web User','Regular Web user');

INSERT INTO ossweb_user_types (type_id,type_name,description)
       VALUES('customer','Customer','Customer user');

INSERT INTO ossweb_groups (group_id,short_name,group_name,description)
       VALUES(0,'public','public','Public group');

INSERT INTO ossweb_groups (group_id,short_name,group_name,description)
       VALUES(1,'admin','admin','Administrative group');

INSERT INTO ossweb_groups (group_id,short_name,group_name,description)
       VALUES(2,'customer','customer','Customers group');

INSERT INTO ossweb_users (user_id,user_name,password,salt,salt2,status,first_name,last_name,user_email)
       VALUES(0,'admin',
              'B44960518E86CF54835077847DF3AE2F528D5312',
              '1A82A95CC696CC921F8C66A0A87F7ED8998BC38F',
              'DD94709528BB1C83D08F3088D4043F4742891F4F',
              'active','System','Administrator','admin@foo.com');

INSERT INTO ossweb_user_groups (user_id,group_id) VALUES(0,1);

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(1,'G','*','*','*','*','*','Y');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(0,'G','*','main','*','*','*','Y');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(0,'G','*','admin','apps','open','*','Y');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(0,'G','*','admin','apps','close','*','Y');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(0,'G','*','admin','index','view','*','Y');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(2,'G','*','customercare','*','*','*','Y');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(2,'G','*','main','*','*','*','Y');

INSERT INTO ossweb_projects (project_id,project_name,project_url,project_logo,
                             project_footer,project_logo_bg,description,menu_x,menu_y,menu_height)
       VALUES('*','OSSWEB','http://www.crystalballinc.com/vlad/software/ossweb/','logos/ossweb.gif',
              'Copyright 2006 OSSWEB Team','bg/navbar.gif','',0,67,18);

INSERT INTO ossweb_msgs (msg_name,description)
       VALUES('accessdenied','<FONT COLOR=black>Access Denied</FONT><P>
                              It means you do not have enough permissions to access this page.');

INSERT INTO ossweb_msgs (msg_name,description)
       VALUES('onetime','<FONT COLOR=red>Onetime Password Used!<BR>
                         You''ve just logged in using onetime password, you
                         need to change your password now. the password you just
                         used is no longer valid.
                        </FONT>');

INSERT INTO ossweb_msgs (msg_name,description)
       VALUES('internalerror','<FONT COLOR=black>Internal Server Error</FONT><BR>
                               The server encountered an internal error or
                               misconfiguration and was unable to complete
                               your request.<P>
                               Please contact the server administrator
                               and inform them of the time the error occurred
                               and anything you might have done that may have
                               caused the error.');

INSERT INTO ossweb_msgs (msg_name,description)
       VALUES('register','<FONT COLOR=black>Thank you for registration</FONT><BR>
                          <FONT COLOR=blue>Now you can use your user name and password
                           to access our system.</FONT>');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:admin',
               'Admin Email',
               'OSSWEB',
               'Email address of the server administrator');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:maintenance',
               'Maintenance Template',
               'OSSWEB',
               'Path to the maintenance template');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('security:filter',
               'Security Filter',
               'OSSWEB',
               'name of the security filter: secure or public');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('security:directory',
               'Security Directory',
               'OSSWEB',
               'Directory to be protected by security filter');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('security:filter:list',
               'Security Directory Filters',
               'OSSWEB',
               'Filter and Directory pair');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('security:encrypt:password',
               'Encrypt Password On Login',
               'OSSWEB',
               'If true, login form will encrypt password during login process',
               '-type select -options { {Yes t} {No f} {None None} }');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('security:pam:service',
               'PAM Service for Auth',
               'OSSWEB',
               'PAM service name to use when ns_pamauth modul eis installed');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('security:auth:list',
               'Authentication Modules',
               'OSSWEB',
               'List of auth modules to run on login, default is local');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:database',
               'Server Database',
               'OSSWEB',
               'Database to be used, should be set in nsd.tcl file');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:extension',
               'Web Page Extension',
               'OSSWEB',
               'Virtual template extension');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:project',
               'Default Project',
               'OSSWEB',
               'Default Project to switch to if no project in the url');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:error',
               'Error Page',
               'OSSWEB',
               'Error page to redirect in case of runtime error');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:storage',
               'Storage Path',
               'OSSWEB',
               'Path to file storage root directory');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:cluster',
               'Server Cluster',
               'OSSWEB',
               'List of IP addresses involved in the cluster');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:cluster:master',
               'Main Server in Cluster',
               'OSSWEB',
               'IP addresses of the main server in the cluster');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:secret',
               'Shared Secret',
               'OSSWEB',
               'Shared secret to be used for session encryption');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:root',
               'Server Web Page Root',
               'OSSWEB',
               'Root of web server pages');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:sound',
               'Path to Sound files',
               'OSSWEB',
               'Path to directory with sound files');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:images',
               'Path to images',
               'OSSWEB',
               'Path to directory with images or icons');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:include',
               'Path to includes',
               'OSSWEB',
               'Path to directory with global masters and includes');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:path:xql',
               'Path to XQL files',
               'OSSWEB',
               'Path to directory with .xql files');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('server:style:border',
               'Default border style',
               'OSSWEB',
               'Type of border style by default',
               '-type select -options [ossweb::tag::info border]');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('server:message_queue:try_count',
               'Message Queue Retries',
               'OSSWEB',
               'Number of retries to be made for failed messages',
               '-type numberselect');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('server:thread:jobs',
               'Max Job Threads',
               'OSSWEB',
               'Number of threads to use for background jobs',
               '-type numberselect');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('server:thread:cluster',
               'Max Cluster Threads',
               'OSSWEB',
               'Number of threads to use for cluster updates',
               '-type numberselect');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('server:check:xql',
               'XQL Check',
               'OSSWEB',
               'If set to never XQL engine will not check files for modification time',
               '-type boolean');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('server:check:popup',
               'Popups Enabled',
               'OSSWEB',
               'If set the system will enable popup notfications',
               '-type boolean');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('server:host:images',
               'Image Hostname',
               'OSSWEB',
               'Host to be used in image urls');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('logwatcher:config',
               'Logwatcher Files',
               'OSSWEB',
               'List of servers and log files to watch');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('logwatcher:email',
               'Logwatcher Email',
               'OSSWEB',
               'Email address for log watcher alerts');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('logwatcher:ignore',
               'Logwatcher Ignore List',
               'OSSWEB',
               'Ignore lines which contains this pattern');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('session:cookie:id',
               'Session Cookie Name',
               'OSSWEB Session',
               'Cookie name for session id');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('session:cookie:public',
               'Session Public Cookie',
               'OSSWEB Session',
               'If non-empty, public sessions will be assigned with session cookie');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('session:check:ip',
               'Session IP Verify',
               'OSSWEB Session',
               'Verify IP Address of session',
               '-type boolean');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('session:domain',
               'Session Domain',
               'OSSWEB Session',
               'Domain for cookies');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('session:new',
               'Session Regeneration',
               'OSSWEB Session',
               'If set to 1 it will make web server to create new session for each request',
               '-type boolean');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('session:multiple',
               'Session Allow Multiple',
               'OSSWEB Session',
               'If set to 1 it will allow multiple sessions with the same user id',
               '-type boolean');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('session:renew',
               'Session Renewal Period',
               'OSSWEB Session',
               'Number of seconds before session expiration for session renewal',
               '-type intervalselect');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('session:timeout',
               'Session Timeout',
               'OSSWEB Session',
               'Session expiration timeout',
               '-type intervalselect');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('session:cookie:user',
               'User Cookie Name',
               'OSSWEB Session',
               'Cookie name for user id');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('session:user:public',
               'Public User',
               'OSSWEB Session',
               'Id of the user to use for public sessions');

