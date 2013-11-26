/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   September 2003
*/

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('YouTube', '*', 'youtube', 'youtube', 'youtube.gif');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('youtube:enabled', 'YouTube Enabled', 'YouTube', 'Enable the module, run in the schedule', '-type boolean'),
              ('youtube:history', 'YouTube History', 'YouTube', 'How many days to keep records', '-type numberselect'),
              ('youtube:time', 'YouTube Time', 'YouTube', 'Period for feeds', '-type select -options { {AllTime {}} {Today today } {ThisWeek this_week} {ThisMonth this_month}}'),
              ('youtube:maxresults', 'YouTube Max Results', 'YouTube', 'Max results in the feed', '-type numberselect'),
              ('youtube:feed:standard', 'YouTube Feed Standard', 'YouTube', 'List of standard feeds, one of: top_rated, top_favorites, most_viewed, most_discussed, most_recent, most_linked, most_responded, recently_featured, watch_on_mobile', NULL),
              ('youtube:feed:custom', 'YouTube Feed Custom', 'YouTube', 'List of keywords', NULL),
              ('youtube:feed:api', 'YouTube Feed API', 'YouTube', 'List of API feeds, standard categories are: Animals Autos Comedy Music Education Entertainment Games Howto News People Sports Tech Travel', NULL);

INSERT INTO ossweb_config (name, value, module, description)
       VALUES ('youtube:feed:standard', 'top_rated top_favorites most_viewed', 'YouTube', 'Youtube standard feeds'),
              ('youtube:feed:custom', 'funny', 'YouTube', 'Youtube custom feeds'),
              ('youtube:feed:api', 'Animals Autos Comedy Music Education Entertainment Games Howto News People Sports Tech Travel', 'YouTube', 'Youtube API feeds');
