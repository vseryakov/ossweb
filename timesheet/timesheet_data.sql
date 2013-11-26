/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   October 2001
*/

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image) 
       VALUES ('Timesheet', '*', 'timesheet', 'timesheet', 'sheet.gif');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title)
       VALUES('timesheet','hourtypes','ts_hour_types','type','Hour Type');

INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('R','Regular');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('V','Vacation');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('S','Sick');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('H','Holiday');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('L','Leave w/o Pay');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('AL','Arrived Late');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('BE','Bereavement');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('FM','FMLA');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('JD','Jury Day');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('LE','Left Early');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('OV','Overtime');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('TN','Training');
INSERT INTO ts_hour_types (type_id,type_name)
       VALUES('TR','Travel');

INSERT INTO ts_costcode_types (type_id,type_name)
       VALUES('CA','Company Account');

INSERT INTO ts_jobs (job_id,job_name,job_no)
       VALUES(1,'Full-Time Salary','000');

INSERT INTO ts_jobs (job_id,job_name,job_no)
       VALUES(2,'Contractor','001');

INSERT INTO ts_costcodes (costcode_id,costcode_code,costcode_type,costcode_name,job_id)
       VALUES(3,'000','CA','Salary',1);

INSERT INTO ts_costcodes (costcode_id,costcode_code,costcode_type,costcode_name,job_id)
       VALUES(4,'001','CA','Leave',1);

INSERT INTO ts_costcodes (costcode_id,costcode_code,costcode_type,costcode_name,job_id)
       VALUES(5,'000','CA','Hourly',2);

