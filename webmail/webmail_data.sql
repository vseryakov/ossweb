/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2001
*/

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('mail:host',
               'Mail Host',
               'Webmail',
               'Host of IMAP mail server');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('mail:options',
               'Mail Options',
               'Webmail',
               'Options to be passed to IMAP driver');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('mail:dir',
               'Mail Directory',
               'Webmail',
               'Directory on the server with mailbox');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('mail:suffix',
               'Mail Suffix',
               'Webmail',
               'Suffix to be appended to user name, usually domain name');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Web Mail', '*', 'webmail', 'webmail', 'mail.gif');
