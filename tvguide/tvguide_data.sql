/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   June 2004
*/


INSERT INTO ossweb_groups (group_name,description) VALUES('tvguide','TV Guide access');

INSERT INTO ossweb_acls (obj_id,obj_type,project_name,app_name,page_name,cmd_name,ctx_name,value)
       VALUES(CURRVAL('ossweb_user_seq'),'G','*','tvguide','*','*','*','Y');

INSERT INTO ossweb_schedule (task_name,task_proc,task_interval,task_thread,description)
       VALUES('TV Guide Export','tvguide::export',900,'Y',
              'Exports tvguide playlist to text file');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('TV Guide', '*', 'tvguide', 'tvguide', 'tv.gif');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('tvguide:user','TV Guide User','TV Guide','Username to login for TV Guide lineup');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('tvguide:lineup','TV Guide Lineup','TV Guide','Default liuneup');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('tvguide:passwd','TV Guide Passwd','TV Guide','Password to login for TV Guide lineup');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('tvguide:recorder','TV Guide Recorder','TV Guide','Command for TV recording');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('tvguide:player','TV Guide Player','TV Guide','Command for playback recorded shows');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('tvguide:home','TV Guide Home','TV Guide','Home directory for PVR software');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES('tvguide:devices','TV Guide Devices','TV Guide','List of video devices available for TV recording, format vdevice:adevice');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('tvguide:recorder','mencoder tv:// -tv driver=v4l2:device=@videodev@:adevice=@audiodev@:input=0:normid=1:chanlist=us-cable:channel=@channel@ -oac lavc -ovc lavc -lavcopts vcodec=mpeg4:acodec=mp2:abitrate=128 -vop pp=lb -quiet -endpos @duration@ -o @file@','TV Guide','Command for TV recording');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('tvguide:devices','/dev/video0:/dev/dsp0','TV Guide','List of video devices available for TV recording');

INSERT INTO ossweb_config (name,value,module,description)
       VALUES('tvguide:player','mplayer -really-quiet -vo xv,x11 @file@','TV Guide','Command for playback recorded shows');

