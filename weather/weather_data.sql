/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   December 2002
*/

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('weather:alerts',
               'Weather Alerts',
               'Weather',
               'Keywords to be used to identify alerts');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('weather:enabled',
               'Weather Enabled',
               'Weather',
               'Enable the module, run in the schedule',
               '-type boolean');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('weather:zone',
               'Weather Zones',
               'Weather',
               'Zone list for Zone Forecasts, updates weather for every zone.
                To get zone go to http://iwin.nws.noaa.gov/iwin/??/zone.html,
                where ?? is lowercase US state. Zone format is ??Z??? (first 2
                chars are state code, followed by "Z", followed by 3 digit zone code)');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('weather:zipcode',
               'Weather Zipcodes',
               'Weather',
               'Updates current weather conditions by zip code');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('weather:radar',
               'Weather Radar LAX',
               'Weather',
               'Radar LAX code, to find it go to weather.com, find your zip code, switch to radar section
                and view radar image url. The LAX code is in the location
                http://image.weather.com/web/radar/us_lax_closeradar_large_usen.jpg');

INSERT INTO ossweb_config_types (type_id,type_name,module,description)
       VALUES ('weather:station',
               'Weather Stations',
               'Weather',
               'Updates current weather conditions by weather station (http://www.nws.noaa.gov/oso/siteloc.shtml)');

INSERT INTO ossweb_config_types (type_id,type_name,module,description,widget)
       VALUES ('weather:history',
               'Weather History',
               'Weather',
               'For how long we keep weather history, as INTERVAL. For example: 30 days',
               '-type intervalselect');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Weather', '*', 'weather', 'weather', 'weather.gif');
