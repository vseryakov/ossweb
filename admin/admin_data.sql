/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title,refresh)
       VALUES('admin','msgs','ossweb_msgs','msg','Standard Message','msg:std');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title)
       VALUES('admin','usertypes','ossweb_user_types','type','User Types');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title)
       VALUES('admin','datatypes','ossweb_data_types','type','Input Data Type');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title,extra_name,extra_label,extra_name2,extra_label2)
       VALUES('admin','configtypes','ossweb_config_types','type','Config Type','widget','Widget','module','Module');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Config', '*', 'admin', 'config', 'config.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Users', '*', 'admin', 'users', 'user.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Groups', '*', 'admin', 'groups', 'user.gif',1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Menu', '*', 'admin', 'apps', 'go.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Projects', '*', 'admin', 'projects', 'multirow.gif',1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Msg Queue', '*', 'admin', 'mqueue', 'send.gif',1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Scheduler', '*', 'admin', 'schedule', 'show.gif',1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Help', '*', 'admin', 'helpadm', 'help.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Categories', '*', 'admin', 'categories', 'details.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('User Types', '*', 'admin', 'usertypes', 'abook.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Config Types', '*', 'admin', 'configtypes', 'abook.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('State Machine', '*', 'admin', 'states', 'checked.gif', 1);

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Page Generator', '*', 'admin', 'generator', 'pencil.gif', 1);

/* Categories for departments */

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Employees','Employees','Department',NULL,'0','FFCC00');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('CSR/Tier1','Call center support Tier 1','Department',NULL,'1','00FF00');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('CSR/Tier2','Call center support Tier 2','Department',NULL,'2','006600');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('FieldOps','Field technicians','Department',NULL,'3','660000');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Billing','Billing/accounting dept','Department',NULL,'4','FFFF00');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Engineering','Engineering and software dept','Department',NULL,'6','3300FF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Operations','Operations and network dept','Department',NULL,'7','CC0000');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Marketing','Marketing SCS dept','Department',NULL,'8','FF66FF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Consulting','Consulting employees','Department',NULL,'9','333300');

/* Categories for escalation levels */

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('None','No escalation level','Escalation',NULL,'0',NULL);

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Tier1','Tier1 escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1000','99FF33');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Tier2','Tier2 escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1010','99FFFF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Tier3','Tier3 escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1020','00CCFF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Engineer','Engineering escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1040','0066FF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('GroupLeader','Group leader scalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1050','0000FF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Supervisor','Superviser/project manager escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1060','996600');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Manager','Manager escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1070','FF0000');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('Director','Drirector escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1800','FF66FF');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('VicePresident','VP/General manager escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1900','FFFF00');

INSERT INTO ossweb_categories (category_name, description, module, category_parent, sort, bgcolor)
       VALUES('CEO','CEO/President escalation level','Escalation',(SELECT category_id FROM ossweb_categories WHERE category_name='None' AND module='Escalation'),'1999','330000');

