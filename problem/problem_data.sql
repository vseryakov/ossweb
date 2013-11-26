/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

INSERT INTO ossweb_groups (group_name,description)
       VALUES('problem','Problem Tracking Group');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title,precedence)
       VALUES('problem','types','problem_types','type','Problem Type','Y');

/* Config parameters */

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('problem:email:prefix',
               'Problem Email Prefix',
               'Problem',
               'Prefix in email subject, be default OSS');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('problem:email:unassigned',
               'Problem Unassigned Email',
               'Problem',
               'Email address to whom send unassigned report');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('problem:email:notify',
               'Problem Notification Mode',
               'Problem',
               'Default aemail notification mode',
               '-type select -options { {Quiet t} {{Notify All} f} {{Notify Assigned} t} }');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('problem:project',
               'Problem Project',
               'Problem',
               'Project for problem submission from NMS',
               '-type select -sql sql:problem.project.select.read');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('problem:alert:type',
               'Problem Alert Type',
               'Problem',
               'List of problem types for which alert should be sent upon new follow up',
               '-type multiselect -sql sql:problem.type.select.read');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('problem:alert:status',
               'Problem Alert Status',
               'Problem',
               'List of problem statuses for which alert should be sent upon new follow up',
               '-type multiselect -sql sql:problem.status.select.read');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('problem:policy',
               'Problem Policy',
               'Problem',
               'Policy how problems are assigned to developers: next or all',
               '-type select -options { {Next next} { All all} }');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('problem:url',
               'Problem Url',
               'Problem',
               'Url to the problem application');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('problem:svn:path',
               'Problem SVN Path',
               'Problem',
               'Path to the SVN working directry');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('problem:svn:config',
               'Problem SVN Config Dir',
               'Problem',
               'Path to the SVN configuration directry');

/* Problem types */

INSERT INTO problem_types (type_id,type_name,description,precedence)
       VALUES('problem','Problem','Problem',0),
             ('task','Task','Task',1),
             ('feature','Feature Request','Feature Request',2),
             ('discussion','Discussion','Discussion',3),
             ('wish','Wish List','Wish List',4);

/* Problem priorities */

INSERT INTO problem_priorities (priority_id,priority_name,description)
       VALUES(0,'Low','Low'),
             (1,'Mediaum','Medium'),
             (2,'High', 'High');

/* Problem severities */

INSERT INTO problem_severities (severity_id,severity_name,description)
       VALUES(0,'Normal','Normal'),
             (1,'Critical','Critical');

/* Problem state machine */

INSERT INTO ossweb_state_machine (status_id,status_name,type,module,states,sort,description)
       VALUES('open','Open','open','problem','<open><completed><cancelled><pending><inprogress>',0,'New problem'),
             ('completed','Completed','complete','problem','<closed><open><cancelled>',0,'Problem completed'),
             ('pending','Pending','work','problem','<completed><inprogress><open><cancelled>',0,'Pending problem'),
             ('inprogress','In Progress','work','problem','<open><completed><pending><cancelled>',0,'Problem in progress'),
             ('closed','Closed','close','problem','<open><deleted>',0,'Problem closed'),
             ('cancelled','Cancelled','close','problem','<open><deleted>',0,'Problem cancelled'),
             ('deleted','Deleted','close','problem','',0,'Problem deleted');

/* Project state machine */

INSERT INTO ossweb_state_machine (status_id,status_name,type,module,states,sort,description)
       VALUES('active','Active','active','problem:project','<active><closed><inactive>',0,'Active problem project'),
             ('inactive','Inactive','inactive','problem:project','<closed><active>',0,'Problem project inactive'),
             ('closed','Closed','closed','problem:project','',0,'Problem project closed');

/* App menu */

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES('Tasks', '*', 'problem', 'problem', 'register.gif', NULL),
             ('Tasks Setup', '*', 'problem', 'projects', 'sheet.gif', (SELECT app_id FROM ossweb_apps WHERE title='Setup')),
             ('Task Types', '*', 'problem', 'types', 'link.gif', (SELECT app_id FROM ossweb_apps WHERE title='Setup'));

