/* Author: Vlad Seryakov vlad@crystalballinc.com
   August 2001
*/

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('OSSMON', '*', 'ossmon', 'ossmon', 'ossmon.gif');

INSERT INTO ossweb_groups (short_name,group_name,description)
       VALUES('ossmon','ossmon','OSSMON administrative group');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES((SELECT group_id FROM ossweb_groups WHERE group_name='ossmon'),'G','*','ossmon','*','*','*','Y');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title)
       VALUES('ossmon',
              'device_types',
              'ossmon_device_types',
              'type',
              'Device Types');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Unknown',
              'Unknown',
              'Unknown Device');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Unix',
              'Unix',
              'Unix Server');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Router',
              'Router',
              'Network router');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Switch',
              'Switch',
              'Network switch');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Windows',
              'Windows',
              'Windows server');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Computer',
              'Computer',
              'PC computer');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Satellite',
              'Satellite',
              'Satellite dish');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('SetTopBox',
              'SetTopBox',
              'Settop box for cable television');

INSERT INTO ossmon_device_types (type_id,type_name,description)
       VALUES('Modem',
              'Modem','Modem');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('ossmon:config','Initialized','OSSMON','Should not be remove, OSSMON will not run without it');

/*
   Alert templates
*/

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (1, 'No Connectivity',
'No connectivity
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (2, 'Interface Down',
'Interface @ifDescr@:@ifIndex@ (@ifType@) is down on @monitor:host@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (3, 'Unix Process Problem',
'@monitor:host@:   @prNames@:   @prErrMessage@:   @prFixMessage@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (5, 'DNS Resolve Error',
'@dnsHost@ @dnsStatus@ @ossmon:status@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (6, 'SMTP Error',
'@smtpStatus@ @ossmon:status@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
      VALUES (7, 'Runtime Error',
'There is runtime error @ossmon:status@:
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@</if>
@-dump@');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (8, 'Syslog Message',
'@syslogMsg@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (9, 'POP3 Error',
'@pop3Status@ @ossmon:status@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (10, 'IMAP4 Error',
'@imapStatus@ @ossmon:status@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (11, 'Disk Space Problem',
'Total Space: @dskTotal@   Free Space: @dskAvail@   Percent Used: @dskPercent@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (12, 'Interface Errors',
'Too many errors on @ifDescr@:@ifIndex@ (@ifType@) for the last <%=[ossweb::date uptime @interface:time:delta@]%> secs:
Input: @ifInErrors@ bytes   Rate: @interface:rate:in:error@ bytes/sec
Output: @ifOutErrors@ bytes   Rate: @interface:rate:out:error@ bytes/sec
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (13, 'Interface High Transfer Rate',
'Too high transfer rate on @ifDescr@:@ifIndex@ (@ifType@) for the last <%=[ossweb::date uptime @interface:time:delta@]%> secs:
Input: @ifInOctets@ bytes  Transfered: @interface:rate:in:transfer@ bytes
Output: @ifOutOctets@ bytes  Transfered: @interface:rate:out:transfer@ bytes
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (15, 'No Response',
'@ossmon:status@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (16, 'Storage Space Problem',
'Device: @hrStorageType@ @hrStorageDescr@   Size: @hrStorageSize@    Used: @hrStorageUsed@    Use%: <%=[expr (@hrStorageUsed@*100)/@hrStorageSize@]%>%
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (17, 'High Processor Load',
'Processor Load @hrProcessorLoad@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (19, 'Log File Alert',
'@fileLine@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (22, 'Interface Utilization',
'Utilization is @interface:utilization@% on @ifDescr@:@ifIndex@ (@ifType@)
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (23, 'Email Alert',
'From: @mailboxFrom@
Subject: @mailboxSubject@
Files: @mailboxFiles@

@mailboxFiles@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (25, 'Process is not Running',
'Required processes are not running on @monitor:host@.
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
Rule: @-alert:rule@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (26, 'FTP Error',
'@ftpStatus@ @ossmon:status@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (27, 'TCP Error',
'Wrong reply @tcpReply@ @ossmon:status@ for @tcpRequest@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (28, 'UDP Error',
'Wrong reply @udpReply@ @ossmon:status@ for @udpRequest@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (29, 'Exec Error',
'@execLine@
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (30, 'Router Memory Utilization',
'There is problem with router memory pools on @monitor:host@:

Pool Name: @ciscoMemoryPoolName@
Memory Used: @ciscoMemoryPoolUsed@
Free Memory: @ciscoMemoryPoolFree@
Percent Used: <%=[expr @ciscoMemoryPoolUsed^0@.0*100/(@ciscoMemoryPoolUsed^0@.0+@ciscoMemoryPoolFree^1@.0)]%>
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');

INSERT INTO ossmon_templates (template_id, template_name, template_actions)
       VALUES (31, 'Router CPU Utilization',
'CPU utilization is too high @avgBusy5@ on @monitor:host@:
<if @alert:rownum@ le 1 and @alert:result@ eq 1>
@-info:object@
</if>');


/*
   Process alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence, status, "mode")
       VALUES (10, 'Unix Process Problem', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@prErrorFlag@', '=', '1', 'AND', 10);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 3, 10);


/*
    Interface alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence, status, "mode")
       VALUES (20, 'Interface Down', 1, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ifAdminStatus@', '=', 'up', 'AND', 20);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ifOperStatus@', '!regexp', '^(up|dormant)$', 'AND', 20);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('(@ifInOctets -double@', '>', '0', 'AND', 20);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ifOutOctets -double@', '>', '0)', 'OR', 20);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 2, 20);

/*
    Interface down trap
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (30, 'Interface Down Alarm', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@trap:oid@', '=', 'linkDown', 'AND', 30);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ossmon:type@', '=', 'trap', 'AND', 30);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 2, 30);

/*
    DNS resolving alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (40, 'DNS Resolve Problem', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@dnsStatus@', '=', 'noResponse', 'AND', 40);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 5, 40);

/*
    Interface alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (50, 'No Connectivity', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ossmon:type@', '=', 'noConnectivity', 'AND', 50);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 1, 50);

/*
    Interface alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (60, 'Runtime Error', 99, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ossmon:type@', '=', 'error', 'AND', 60);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 7, 60);

/*
    Syslog alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (70, 'Syslog Message', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@syslogMsg@', 'regexp', 'noActivity|port down|failure|refused|denied|reject|su:', 'AND', 70);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 8, 70);

/*
    Interface alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (75, 'IMAP4 Problem', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@imapStatus@', '!=', '""', 'AND', 75);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@imapStatus@', '!=', 'OK', 'AND', 75);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 10, 75);

/*
    SMTP alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (80, 'SMTP Problem', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@smtpStatus@', '!=', '""', 'AND', 80);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@smtpStatus@', '!=', 'OK', 'AND', 80);


INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 6, 80);

/*
    POP3 alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (85, 'POP3 Problem', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@pop3Status@', '!=', '""', 'AND', 85);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@pop3Status@', '!=', 'OK', 'AND', 85);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 9, 85);

/*
    Disk alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (95, 'Disk Usage Problem', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@dskPercent@', '>', '90', 'AND', 95);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@dskErrorFlag@', '>', '0', 'OR', 95);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 11, 95);

/*
    Interface Errors alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (100, 'Interface Errors', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@interface:rate:in:error@', '>=', '100', 'OR', 100);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@interface:rate:out:error@', '>=', '100', 'AND', 100);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 12, 100);

/*
    Interface transfer rate alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (105, 'Interface Transfer Rates', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@interface:rate:in:transfer@', '>=', '10000000', 'OR', 105);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@interface:rate:out:transfer@', '>=', '10000000', 'AND', 105);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 13, 105);

/*
    No response alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (120, 'No Response', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ossmon:type@', '=', 'noResponse', 'AND', 120);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 15, 120);

/*
    Storage disk alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode", "level")
       VALUES (130, 'Storage Disk Problem', 0, 'Active', 'ALERT', 'Warning');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@hrStorageType@', '=', 'hrStorageFixedDisk', 'AND', 130);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@hrStorageSize@ - @hrStorageUsed@', '>', '0', 'AND', 130);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@hrStorageSize@ - @hrStorageUsed@', '<', '1000000', 'AND', 130);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 16, 130);

/*
    Storage memory alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode", "level")
       VALUES (140, 'Storage Memory Problem', 0, 'Active', 'ALERT', 'Warning');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@hrStorageType@', 'contains', '{hrStorageRam hrStorageVirtualMemory}', 'AND', 140);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('(@hrStorageUsed@*100)/@hrStorageSize@', '>', '90', 'AND', 140);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 16, 140);

/*
    Processor Load alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode", "level")
       VALUES (150, 'High Processor Load', 0, 'Active', 'ALERT', 'Warning');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@hrProcessorLoad@', '>', '90', 'AND', 150);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 17, 150);

/*
   Process is not Running
 */

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence, status, "mode")
       VALUES (155, 'Process is not Running', 0, 'Active', 'FINAL');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@monitor:name@', '=', 'hrSWRunTable', 'AND', 155);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@device:type@', '=', 'Windows', 'AND', 155);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('hrSWRunName', '!gregexp', '@ossmon:hrProcessList^svchost.exe@', 'AND', 155);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 25, 155);


/*
    Interface utilization alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (205, 'Interface Utilization', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@interface:utilization@', '>=', '@interface:utilization:threshold^75@', 'AND', 205);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 22, 205);

/*
    File alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (160, 'Log File Alert', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@fileLine@', '!=', '""', 'AND', 160);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 19, 160);

/*
   Action rule, alert keep alive
*/

INSERT INTO ossmon_action_rules (rule_id, rule_name, status, precedence, "mode", description)
       VALUES (170, 'Alert Keep-Alive', 'Disabled', 0, 'BEFORE', 'Keeps alert active all the time, therefore only notes are added to the same alert id');

INSERT INTO ossmon_action_match (name, "operator", value, "mode", rule_id)
       VALUES ('ossmon:type', '=', 'mailbox', 'AND', 170);

INSERT INTO ossmon_action_script (value, rule_id)
       VALUES ('ossmon::monitor $name -alert:keepalive', 170);

/*
    FTP alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (171, 'FTP Error', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ftpStatus@', '!=', '""', 'AND', 171);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ftpStatus@', '!=', 'OK', 'AND', 171);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 26, 171);

/*
    TCP alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (172, 'TCP Error', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@monitor:type@', '=', 'tcp', 'AND', 172);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@tcpReply@', '!=', 'OK', 'AND', 172);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 27, 172);

/*
    UDP alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (173, 'UDP Error', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@monitor:type@', '=', 'udp', 'AND', 173);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@udpReply@', '!=', 'OK', 'AND', 173);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 27, 173);

/*
    Exec alerts
*/

INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence,  status, "mode")
       VALUES (175, 'Exec Alarm', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@monitor:type@', '=', 'exec', 'AND', 175);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@execLine@', 'regexp', 'noActivity|port down|failure|refused|denied|reject|su:', 'AND', 175);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 29, 175);

/*
   Router memory
*/
INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence, status, "mode")
       VALUES (178, 'Router Memory Utilization', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@monitor:name@', '=', 'ciscoMemoryPoolTable', 'AND', 178);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@ciscoMemoryPoolUsed@', '>', '(@ciscoMemoryPoolUsed^0@+@ciscoMemoryPoolFree^0@)/5*4', 'AND', 178);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 30, 178);

/*
   Router CPU
*/
INSERT INTO ossmon_alert_rules (rule_id, rule_name, precedence, status, "mode")
       VALUES (179, 'Router CPU Utilization', 0, 'Active', 'ALERT');

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@monitor:name@', '=', 'avgBusy5.0', 'AND', 179);

INSERT INTO ossmon_alert_match (name, "operator", value, "mode", rule_id)
       VALUES ('@avgBusy5@', '>', '90', 'AND', 179);

INSERT INTO ossmon_alert_run (action_type, template_id, rule_id) VALUES ('email', 31, 179);
