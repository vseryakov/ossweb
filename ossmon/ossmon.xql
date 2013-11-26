<?xml version="1.0"?>

<xql>

<query name="ossmon.timestamp">
  <description>
  </description>
  <sql>
    SELECT ROUND(EXTRACT(EPOCH FROM NOW()))
  </sql>
</query>

<query name="ossmon.poll.interval.min">
  <description>
    Returns minimal polling interval
  </description>
  <sql>
    SELECT MIN(value)
    FROM (SELECT MIN(value) AS value
          FROM ossmon_object_properties
          WHERE property_id='ossmon:interval' and
                value IS NOT NULL
          UNION ALL
          SELECT MIN(value)
          FROM ossmon_device_properties
          WHERE property_id='ossmon:interval' and
                value IS NOT NULL) m
    WHERE value IS NOT NULL
  </sql>
</query>

<query name="ossmon.poll.objects">
  <description>
   Read all objects to be polled
  </description>
  <sql>
    SELECT o.obj_id,
           o.obj_type,
           o.obj_host,
           o.device_id
    FROM ossmon_devices d,
         ossmon_objects o
    WHERE d.device_id=o.device_id AND
          o.disable_flag=FALSE AND
          d.disable_flag=FALSE
    ORDER BY device_path,
             o.priority
  </sql>
</query>

<query name="ossmon.schedule.cleanup.nat">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_nat WHERE timestamp < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL
  </sql>
</query>

<query name="ossmon.schedule.cleanup.iftable">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_iftable WHERE timestamp < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL
  </sql>
</query>

<query name="ossmon.schedule.cleanup.ping">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_ping WHERE timestamp < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL
  </sql>
</query>

<query name="ossmon.schedule.cleanup.collect">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_collect WHERE timestamp < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL
  </sql>
</query>

<query name="ossmon.schedule.cleanup.alerts">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_alerts
    WHERE update_time < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL AND
          alert_status='Closed'
  </sql>
</query>

<query name="ossmon.schedule.cleanup.alert_log">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_alert_log WHERE log_date < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL
  </sql>
</query>

<query name="ossmon.schedule.cleanup.mac">
  <description>
    Cleanup old records
  </description>
  <sql>
    DELETE FROM ossmon_mac WHERE timestamp < NOW() - '[ossweb::config ossmon:collect:history:time "2 month"]'::INTERVAL
  </sql>
</query>

<query name="ossmon.schedule.collect">
  <description>
    Read objects configured for collection
  </description>
  <sql>
    SELECT o.obj_id,
           obj_name,
           obj_host,
           obj_type,
           o.poll_time,
           o.update_time,
           o.collect_time,
           a.alert_time,
           a.alert_name,
           a.alert_type,
           a.alert_count,
           device_name,
           ROUND(EXTRACT(EPOCH FROM NOW()-collect_time)) AS collect_interval
    FROM ossmon_objects o
         LEFT OUTER JOIN ossmon_alerts a ON o.alert_id=a.alert_id,
         ossmon_devices d,
         ossmon_object_properties p
    WHERE o.device_id=d.device_id AND
          o.obj_id=p.obj_id AND
          o.disable_flag <> TRUE AND
          p.property_id='ossmon:collect' AND
          p.value IS NOT NULL
  </sql>
</query>

<query name="ossmon.schedule.polling">
  <description>
    Read objects configured for collection
  </description>
  <sql>
    SELECT o.obj_id,
           obj_name,
           obj_host,
           obj_type,
           o.poll_time,
           o.update_time,
           a.alert_time,
           a.alert_name,
           a.alert_type,
           a.alert_count,
           device_name,
           ROUND(EXTRACT(EPOCH FROM NOW()-poll_time)) AS poll_interval
    FROM ossmon_objects o
         LEFT OUTER JOIN ossmon_alerts a ON o.alert_id=a.alert_id,
         ossmon_devices d
    WHERE o.device_id=d.device_id AND
          o.disable_flag <> TRUE
  </sql>
</query>

<query name="ossmon.device.type.read">
  <description>
  </description>
  <sql>
    SELECT type_name FROM ossmon_device_types WHERE type_id='$type_id'
  </sql>
</query>

<query name="ossmon.device.type.list">
  <description>
  </description>
  <sql>
    SELECT type_name,type_id FROM ossmon_device_types ORDER BY 1
  </sql>
</query>

<query name="ossmon.device.type.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_device_types
    [ossweb::sql::insert_values -full t \
          { type_id "" ""
            type_name "" ""
            description "" "" }]
  </sql>
</query>

<query name="ossmon.device.vendor.list">
  <description>
  </description>
  <sql>
    SELECT company_name,
           company_name
    FROM ossweb_companies
    WHERE access_type IN ('Public','Open')
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.device.vendor.create">
  <description>
  </description>
  <sql>
    SELECT ossweb_company_create([ossweb::sql::quote $device_vendor])
  </sql>
</query>

<query name="ossmon.device.vendor.model.list">
  <description>
   Retrieves all of the vendor model relationships in the system
  </description>
  <sql>
    SELECT model_id,
           device_model,
           device_vendor,
           ossweb_company_name(device_vendor) AS device_vendor_name,
           device_type,
           description
    FROM ossmon_device_models
    [ossweb::sql::filter \
          { device_model Text ""
            device_vendor ilist ""
            device_vendor_name Text ""
            device_type "" "" } \
          -map { device_vendor_name "ossweb_company_name(device_vendor) ILIKE %value" } \
          -where WHERE]
    ORDER BY device_vendor,
             device_model
  </sql>
</query>

<query name="ossmon.device.vendor.model.read">
  <description>
   Retrieves a specific record
  </description>
  <sql>
    SELECT device_model,
           device_vendor,
           ossweb_company_name(device_vendor) AS device_vendor_name,
           device_type,
           description
    FROM ossmon_device_models
    WHERE model_id = $model_id
  </sql>
</query>

<query name="ossmon.device.vendor.model.create">
  <description>
   Creates a new record in the system
  </description>
  <sql>
    INSERT INTO ossmon_device_models
    [ossweb::sql::insert_values -full t \
          { device_model "" ""
            device_vendor "" ""
            device_type "" ""
            description "" ""}]
  </sql>
</query>

<query name="ossmon.device.vendor.model.update">
  <description>
   Updates an existing record in the system
  </description>
  <sql>
   UPDATE ossmon_device_models
   SET [ossweb::sql::update_values \
           { device_model "" ""
             device_type "" ""
             device_vendor "" ""
             description "" "" }]
   WHERE model_id = $model_id
  </sql>
</query>

<query name="ossmon.device.vendor.model.delete">
  <description>
   Removes a record from the system
  </description>
  <sql>
   DELETE FROM ossmon_device_models WHERE model_id = $model_id
  </sql>
</query>

<query name="ossmon.device.list">
  <description>
    Read objects for select box
  </description>
  <sql>
    SELECT device_name,
           device_id
    FROM ossmon_devices
    WHERE disable_flag = FALSE
          [ossweb::sql::filter { device_id ilist "" } \
                -before AND]
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.device.list.active">
  <description>
    List of all devices
  </description>
  <sql>
    SELECT device_id,
           device_name,
           device_host,
           device_type,
           device_vendor,
           ossweb_company_name(device_vendor) AS device_vendor_name,
           device_model,
           device_software,
           disable_flag,
           description,
           ossmon_device_location(device_id,address_id) AS device_location,
           ossmon_device_alerts(device_id) AS device_alerts,
           ossmon_device_objects(device_id) AS device_objects,
           device_parent,
           device_path,
           (SELECT count(*) FROM ossmon_devices d2
            WHERE d2.device_path LIKE d.device_path||'%' AND
                  d2.device_id <> d.device_id) AS device_count
    FROM ossmon_devices d
    WHERE disable_flag = FALSE
          [ossweb::sql::filter \
                { device_id ilist ""
                  device_filter ilist ""
                  device_parent int ""
                  device_path text ""
                  filter Text "" } \
                -map { device_filter "device_id IN (%value)"
                       device_parent "(device_parent=%value OR device_id=%value)"
                       filter "(device_type ILIKE %value OR device_name ILIKE %value)" } \
                -before AND]
    ORDER BY device_path
  </sql>
</query>

<query name="ossmon.device.list.collect">
  <description>
    Read objects for select box
  </description>
  <sql>
    SELECT DISTINCT
           d.device_name,
           d.device_id
    FROM ossmon_devices d,
         ossmon_objects o,
         ossmon_object_properties p
    WHERE o.device_id=d.device_id AND
          o.obj_id=p.obj_id AND
          p.property_id='ossmon:collect' AND
          o.disable_flag = FALSE
          [ossweb::sql::filter { obj_type list "" } \
                -before AND]
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.device.list.objects">
  <description>
    List objects for the device
  </description>
  <sql>
    SELECT o.obj_id,
           o.obj_name,
           o.obj_type,
           o.obj_host,
           o.obj_stats,
           o.disable_flag,
           COALESCE(a.alert_count,0) AS alert_count,
           a.alert_type,
           a.alert_name,
           TO_CHAR(o.poll_time,'MM/DD/YY HH24:MI') AS poll_time,
           TO_CHAR(a.alert_time,'MM/DD/YY HH24:MI') AS alert_time
    FROM ossmon_objects o
         LEFT OUTER JOIN ossmon_alerts a
           ON o.alert_id=a.alert_id
    WHERE o.device_id=$device_id
    ORDER BY priority
  </sql>
</query>

<query name="ossmon.device.list.children">
  <description>
  </description>
  <sql>
    SELECT d2.device_id,
           d2.device_name,
           d2.device_type,
           d2.device_path,
           d2.device_parent,
           d2.device_vendor,
           ossweb_company_name(d2.device_vendor) AS device_vendor_name,
           d2.device_model,
           d2.device_software,
           d2.disable_flag,
           d2.device_host,
           d2.description,
           ossmon_device_location(d2.device_id,d2.address_id) AS device_location,
           ossmon_device_alerts(d2.device_id) AS device_alerts,
           ossmon_device_objects(d2.device_id) AS device_objects
    FROM ossmon_devices d1,
         ossmon_devices d2
    WHERE d1.device_id=$device_id AND
          d2.device_id <> d1.device_id AND
          d2.device_path LIKE d1.device_path||'%'
    ORDER BY d2.device_path
  </sql>
</query>

<query name="ossmon.device.search1">
  <description>
    List of all devices
  </description>
  <sql>
    SELECT device_id
    FROM ossmon_devices d
    [ossweb::sql::filter \
          { device_id ilist ""
            device_name Text ""
            device_model Text ""
            device_vendor list ""
            company_name Text ""
            device_serialnum "" ""
            device_type list ""
            description Text ""
            inventory_flag int ""
            disable_flag boolean ""
            object_type list ""
            location_name Text "" } \
          -map { inventory_flag "object_count > 0"
                 device_name "(device_name ILIKE %value OR device_host ILIKE %value OR EXISTS(SELECT 1 FROM ossmon_objects o WHERE d.device_id=o.device_id AND obj_host ILIKE %value))"
                 device_serialnum "(device_serialnum ~* %value)"
                 location_name "ossmon_device_location(device_id,address_id) ILIKE %value"
                 object_type "EXISTS(SELECT 1 FROM ossmon_objects o WHERE o.device_id=d.device_id AND obj_type IN (%value))"
                 company_name "ossweb_company_name(device_vendor) ~* %value" } \
          -where WHERE]
    ORDER BY [ossweb::coalesce device_sort device_path]
  </sql>
</query>

<query name="ossmon.device.search2">
  <description>
    List of all devices
  </description>
  <sql>
    SELECT device_id,
           device_name,
           device_host,
           device_type,
           device_path,
           device_parent,
           device_vendor,
           ossweb_company_name(device_vendor) AS device_vendor_name,
           (SELECT m.device_model FROM ossmon_device_models m WHERE model_id=d.device_model) AS device_model_name,
           device_model,
           device_software,
           disable_flag,
           description,
           ossmon_device_location(device_id,address_id) AS device_location,
           ossmon_device_alerts(device_id) AS device_alerts,
           ossmon_device_objects(device_id) AS device_objects
    FROM ossmon_devices d
    WHERE device_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossmon.device.search.by.ipaddr">
  <description>
    Resolve device id by device IP address
  </description>
  <sql>
    SELECT device_id,
           device_name,
           device_type,
           description,
           ossmon_device_location(device_id,address_id) AS location_name
    FROM ossmon_devices
    WHERE device_host='$device_host'
    LIMIT 1
  </sql>
</query>

<query name="ossmon.device.search.by.name">
  <description>
    Read device name by id
  </description>
  <sql>
    SELECT device_id FROM ossmon_devices WHERE device_name=[ossweb::sql::quote $device_name]
  </sql>
</query>

<query name="ossmon.device.name">
  <description>
    Read device name by id
  </description>
  <sql>
    SELECT device_name FROM ossmon_devices WHERE device_id='$device_id'
  </sql>
</query>

<query name="ossmon.device.name.parent">
  <description>
    Read device name by id
  </description>
  <sql>
    SELECT ossmon_device_name('$device_parent')
  </sql>
</query>

<query name="ossmon.device.ipaddr">
  <description>
    Read IP address by device id
  </description>
  <sql>
    SELECT device_host FROM ossmon_devices WHERE device_id='$device_id'
  </sql>
</query>

<query name="ossmon.device.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_devices
    [ossweb::sql::insert_values -full t \
          { device_name "" ""
            device_type "" ""
            device_vendor "" ""
            device_parent "" ""
            device_model "" ""
            device_software "" ""
            description "" ""
            device_host "" ""
            address_id int ""
            priority int 0
            disable_flag "" f }]
  </sql>
</query>

<query name="ossmon.device.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_devices
    SET [ossweb::sql::update_values \
              { device_name "" ""
                device_type "" ""
                device_vendor int ""
                device_parent int ""
                device_model "" ""
                device_software "" ""
                device_serialnum "" ""
                description "" ""
                device_host "" ""
                address_id int ""
                disable_flag "" f
                update_user const {[ossweb::conn user_id]} }]
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.update.params">
  <description>
  </description>
  <sql>
    UPDATE ossmon_devices
    SET [ossweb::sql::update_values -skip_null t \
              { device_name "" ""
                device_type "" ""
                device_host "" ""
                device_parent int ""
                device_vendor int ""
                device_model "" ""
                device_software "" ""
                device_serialnum "" ""
                description "" ""
                address_id int ""
                disable_flag "" f
                priority int 0
                update_user const {[ossweb::conn user_id]} }]
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.update.address">
  <description>
  </description>
  <sql>
    UPDATE ossmon_devices SET address_id=[ossweb::sql::quote $address_id int] WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.update.path">
  <description>
    Update device path
  </description>
  <sql>
    SELECT ossmon_device_path($device_id)
  </sql>
</query>

<query name="ossmon.device.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_devices
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.read">
  <description>
  </description>
  <sql>
    SELECT device_id,
           device_name,
           device_type,
           device_serialnum,
           device_vendor,
           ossweb_company_name(device_vendor) AS device_vendor_name,
           device_model,
           (SELECT m.device_model FROM ossmon_device_models m WHERE model_id=d.device_model) AS device_model_name,
           device_parent,
           device_path,
           device_software,
           description,
           device_host,
           priority,
           address_id,
           disable_flag,
           TO_CHAR(create_time,'YYYY-MM-DD HH24:MI') AS create_time,
           TO_CHAR(update_time,'YYYY-MM-DD HH24:MI') AS update_time,
           ossmon_device_name(device_parent,TRUE) AS device_parent_name,
           ossweb_location_name(address_id,NULL) AS device_address,
           ossmon_device_location(device_id,address_id) as location_name,
           ossmon_device_alerts(device_id) AS device_alerts,
           ossmon_device_properties(device_id) AS device_properties,
           ROUND(EXTRACT(EPOCH FROM NOW())) AS now
    FROM ossmon_devices d
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.read.alerts">
  <description>
  </description>
  <sql>
    SELECT ossmon_device_alerts(device_id) AS device_alerts
    FROM ossmon_devices
    WHERE [ossweb::sql::filter \
                { device_id int ""
                  device_name "" "" }]
  </sql>
</query>

<query name="ossmon.device.copy">
  <description>
    Copy ossmon device record
  </description>
  <sql>
    INSERT INTO ossmon_devices (device_id,device_type,device_name,device_host,
                             device_vendor,device_model,device_software,device_parent,
                             disable_flag,description,address_id)
    SELECT $new_device_id,
           device_type,
           'COPY:'||device_name,
           device_host,
           device_vendor,
           device_model,
           device_software,
           device_parent,
           disable_flag,
           description,
           address_id
    FROM ossmon_devices
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.copy.properties">
  <description>
    Copy device properties
  </description>
  <sql>
    INSERT INTO ossmon_device_properties (device_id,property_id,value)
    SELECT $new_device_id,property_id,value
    FROM ossmon_device_properties p
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.property.list">
  <description>
    Read all object properties
  </description>
  <sql>
    SELECT p.device_id,
           p.property_id,
           p.value
    FROM ossmon_device_properties p
    WHERE device_id=$device_id
    ORDER BY create_date
  </sql>
</query>

<query name="ossmon.device.property.read">
  <description>
    Read all object property
  </description>
  <sql>
    SELECT value
    FROM ossmon_device_properties
    WHERE property_id=[ossweb::sql::quote $property_id] AND
          device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.property.update">
  <description>
    Update object property
  </description>
  <sql>
    UPDATE ossmon_device_properties
    SET value=[ossweb::sql::quote $value]
    WHERE device_id=$device_id AND
          property_id=[ossweb::sql::quote $property_id]
  </sql>
</query>

<query name="ossmon.device.property.create">
  <description>
    Create object property
  </description>
  <sql>
    INSERT INTO ossmon_device_properties
    [ossweb::sql::insert_values -full t \
          { device_id int ""
            property_id "" ""
            value "" "" }]
  </sql>
</query>

<query name="ossmon.device.property.delete">
  <description>
    Delete object property
  </description>
  <sql>
    DELETE FROM ossmon_device_properties
    WHERE [ossweb::sql::filter { device_id int "" property_id list "" }]
  </sql>
</query>

<query name="ossmon.device.alert.list">
  <description>
    Read all object's alerts
  </description>
  <sql>
    SELECT a.alert_id,
           a.alert_status,
           a.alert_name,
           a.alert_type,
           a.alert_level,
           a.alert_count,
           TO_CHAR(a.alert_time,'MM/DD/YY HH24:MI') AS alert_time,
           TO_CHAR(a.update_time,'MM/DD/YY HH24:MI') AS update_time,
           TO_CHAR(a.create_time,'MM/DD/YY HH24:MI') AS create_time
    FROM ossmon_alerts a
    WHERE device_id=$device_id
          [ossweb::sql::filter \
                { alert_id int ""
                  alert_status "" "" } \
                -alias { a. } \
                -before AND]
    ORDER BY a.alert_time DESC
  </sql>
</query>

<query name="ossmon.device.alert.clear">
  <description>
    Updates alert status
  </description>
  <sql>
    UPDATE ossmon_alerts
    SET alert_status='Closed',
        update_user=[ossweb::conn user_id 0]
    WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.alert.delete">
  <description>
    Updates alert status
  </description>
  <sql>
    DELETE FROM ossmon_alerts WHERE device_id=$device_id
  </sql>
</query>

<query name="ossmon.device.alert.noconnectivity">
  <description>
  </description>
  <sql>
    SELECT a.alert_id
    FROM ossmon_alerts a
    WHERE a.device_id=$device_id AND
          a.alert_status='Active' AND
          a.log_status LIKE 'noConnectivity%'
  </sql>
</query>

<query name="ossmon.chart.read">
  <description>
    Read data for chart
  </description>
  <sql>
    SELECT ROUND(EXTRACT(EPOCH FROM timestamp)) AS timestamp,
           $column_name1 AS name1,
           $column_name2 AS name2,
           $column_value1 AS value1,
           $column_value2 AS value2
    FROM $table
    WHERE timestamp BETWEEN '[ns_fmttime $start_date "%Y-%m-%d %H:%M:%S"]' AND
          '[ns_fmttime $end_date "%Y-%m-%d %H:%M:%S"]'
          [ossweb::sql::filter \
                { obj_id int ""
                  host regexp ""
                  name regexp "" } \
                -before AND]
    ORDER BY timestamp
  </sql>
</query>

<query name="ossmon.object.search1">
  <description>
    Search objects
  </description>
  <sql>
    SELECT obj_id
    FROM ossmon_objects
    [ossweb::sql::filter \
          { obj_name Regexp ""
            obj_type list ""
            obj_host Text ""
            device_id ilist ""
            disable_flag boolean "" } \
          -where WHERE]
    ORDER BY priority
  </sql>
</query>

<query name="ossmon.object.search2">
  <description>
    Search objects
  </description>
  <sql>
    SELECT o.obj_id,
           o.obj_type,
           o.obj_name,
           o.obj_host,
           o.obj_stats,
           o.disable_flag,
           d.device_id,
           d.device_name,
           d.device_type,
           COALESCE(a.alert_count,0) AS alert_count,
           a.alert_type,
           a.alert_name,
           a.alert_level,
           TO_CHAR(o.poll_time,'MM/DD/YY HH24:MI') AS poll_time,
           TO_CHAR(a.alert_time,'MM/DD/YY HH24:MI') AS alert_time,
           TO_CHAR(o.update_time,'MM/DD/YY HH24:MI') AS update_time,
           ossmon_device_location(d.device_id,d.address_id) AS location_name
    FROM ossmon_objects o
         LEFT OUTER JOIN ossmon_alerts a
           ON o.alert_id=a.alert_id,
         ossmon_devices d
    WHERE o.device_id=d.device_id AND
          o.obj_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossmon.object.read">
  <description>
    Read ossmon object record
  </description>
  <sql>
    SELECT o.obj_id,
           o.obj_type,
           COALESCE(o.obj_name,o.obj_type) AS obj_name,
           COALESCE(o.obj_host,d.device_host) AS obj_host,
           o.obj_parent,
           o.obj_stats,
           ossmon_object_name(o.obj_parent) AS obj_parent_name,
           o.description,
           o.priority,
           o.disable_flag,
           o.console_flag,
           o.charts_flag,
           ossmon_object_properties(o.obj_id) AS obj_properties,
           a.alert_id,
           COALESCE(a.alert_count,0) AS alert_count,
           a.alert_type,
           a.alert_name,
           a.alert_level,
           ossmon_alert_data(a.alert_id) AS alert_data,
           TO_CHAR(a.alert_time,'MM/DD/YY HH24:MI') AS alert_time,
           TO_CHAR(o.poll_time,'MM/DD/YY HH24:MI') AS poll_time,
           TO_CHAR(o.update_time,'MM/DD/YY HH24:MI') AS update_time,
           ROUND(EXTRACT(EPOCH FROM o.poll_time)) AS poll_secs,
           ROUND(EXTRACT(EPOCH FROM a.alert_time)) AS alert_secs,
           ROUND(EXTRACT(EPOCH FROM o.update_time)) AS update_secs,
           d.device_id,
           d.device_name,
           d.device_type,
           d.device_vendor,
           ossweb_company_name(d.device_vendor) AS device_vendor_name,
           d.device_path,
           d.description AS device_descr,
           ossmon_device_properties(d.device_id) AS device_properties,
           ossmon_device_location(d.device_id,d.address_id) AS location_name,
           ROUND(EXTRACT(EPOCH FROM NOW())) AS now
    FROM ossmon_objects o
         LEFT OUTER JOIN ossmon_alerts a ON o.alert_id=a.alert_id,
         ossmon_devices d
    WHERE o.obj_id=$obj_id AND
          o.device_id=d.device_id
  </sql>
</query>

<query name="ossmon.object.read.host">
  <description>
    Read ossmon object host
  </description>
  <sql>
    SELECT obj_name||'('||device_name||')' as obj_name,
           obj_host
    FROM ossmon_objects o,
         ossmon_devices d
    WHERE obj_id=$obj_id AND
          o.device_id=d.device_id
  </sql>
</query>

<query name="ossmon.object.read.parent">
  <description>
  </description>
  <sql>
    SELECT obj_parent FROM ossmon_objects WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.read.device">
  <description>
  </description>
  <sql>
    SELECT device_id FROM ossmon_objects WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.list">
  <description>
    Read objects for select box
  </description>
  <sql>
    SELECT obj_name||'('||device_name||', '||obj_host||')',
           obj_id
    FROM ossmon_objects o,
         ossmon_devices d
    WHERE o.disable_flag = FALSE AND
          d.disable_flag = FALSE AND
          o.device_id=d.device_id
          [ossweb::sql::filter { obj_type list "" } -before AND]
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.object.list.hosts">
  <description>
    Read objects for select box
  </description>
  <sql>
    SELECT DISTINCT obj_host,obj_host FROM ossmon_objects ORDER BY 1
  </sql>
</query>

<query name="ossmon.object.list.charts">
  <description>
    Read objects for select box
  </description>
  <sql>
    SELECT obj_id,
           (SELECT value FROM ossmon_object_properties p
            WHERE p.obj_id=m.obj_id AND
                  property_id='ossmon:charts:interval') AS interval
    FROM ossmon_objects m
    WHERE charts_flag IS NOT NULL AND NOT disable_flag
  </sql>
</query>

<query name="ossmon.object.list.collect">
  <description>
    Read objects for select box
  </description>
  <sql>
    SELECT obj_name||'('||device_name||', '||obj_host||','||obj_type||')',
           o.obj_id
    FROM ossmon_objects o,
         ossmon_devices d,
         ossmon_object_properties p
    WHERE o.obj_id=p.obj_id AND
          o.disable_flag = FALSE AND
          d.disable_flag = FALSE AND
          o.device_id=d.device_id AND
          p.property_id='ossmon:collect'
          [ossweb::sql::filter { obj_type list "" } -before AND]
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.object.create">
  <description>
    Create ossmon object
  </description>
  <sql>
    INSERT INTO ossmon_objects
    [ossweb::sql::insert_values -full t \
          { obj_host "" ""
            obj_name "" ""
            obj_type "" ""
            obj_parent int ""
            priority int 0
            charts_flag "" ""
            disable_flag boolean FALSE
            device_id int ""
            description "" ""}]
  </sql>
</query>

<query name="ossmon.object.update">
  <description>
    Update ossmon object
  </description>
  <sql>
    UPDATE ossmon_objects
    SET [ossweb::sql::update_values \
              { obj_host "" ""
                obj_name "" ""
                obj_type "" ""
                obj_parent int ""
                priority int 0
                charts_flag "" ""
                disable_flag boolean FALSE
                console_flag boolean FALSE
                device_id int ""
                description "" ""}]
    WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.update.status">
  <description>
    Update ossmon object
  </description>
  <sql>
    UPDATE ossmon_objects
    SET alert_id=[ossmon::object $name alert:id -default NULL],
        collect_time=[ossmon::object $name time:collect -default collect_time -time "'%Y-%m-%d %H:%M:%S'"],
        obj_stats='[ossmon::object $name obj:stats]',
        poll_time=NOW()
    WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.delete">
  <description>
    Delete ossmon object
  </description>
  <sql>
    DELETE FROM ossmon_objects WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.clear">
  <description>
    Update ossmon object
  </description>
  <sql>
    UPDATE ossmon_objects SET alert_id=NULL WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.copy">
  <description>
    Copy ossmon object record
  </description>
  <sql>
    INSERT INTO ossmon_objects (obj_id,obj_type,obj_name,obj_host,description,priority,device_id)
    SELECT $new_obj_id,
           obj_type,
           'COPY:'||obj_name,
           obj_host,
           description,
           priority,
           device_id
    FROM ossmon_objects
    WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.copy.properties">
  <description>
    Copy object properties
  </description>
  <sql>
    INSERT INTO ossmon_object_properties (obj_id,property_id,value)
    SELECT $new_obj_id,property_id,value
    FROM ossmon_object_properties p
    WHERE obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.alert.list">
  <description>
    Read all object's alerts
  </description>
  <sql>
    SELECT a.alert_id,
           a.alert_status,
           o.obj_host,
           o.device_id,
           o.obj_name,
           a.alert_name,
           a.alert_level,
           a.alert_type,
           a.alert_count,
           TO_CHAR(o.poll_time,'MM/DD/YY HH24:MI') AS poll_time,
           TO_CHAR(a.alert_time,'MM/DD/YY HH24:MI') AS alert_time,
           TO_CHAR(a.update_time,'MM/DD/YY HH24:MI') AS update_time,
           TO_CHAR(a.create_time,'MM/DD/YY HH24:MI') AS create_time
    FROM ossmon_alerts a,
         ossmon_objects o
    WHERE o.obj_id=$obj_id AND
          a.device_id=o.device_id
          [ossweb::sql::filter \
                { alert_id int ""
                  alert_status "" "" } \
                -alias { a. } \
                -before AND]
    ORDER BY COALESCE(a.alert_time,'1900-01-01'::DATE) DESC
  </sql>
</query>

<query name="ossmon.object.property.read">
  <description>
    Read all object property
  </description>
  <sql>
    SELECT value
    FROM ossmon_object_properties
    WHERE property_id=[ossweb::sql::quote $property_id] AND
          obj_id=$obj_id
  </sql>
</query>

<query name="ossmon.object.property.value">
  <description>
    Read all object properties
  </description>
  <sql>
    SELECT value
    FROM ossmon_object_properties
    WHERE obj_id=$obj_id AND
          property_id='$property_id'
  </sql>
</query>

<query name="ossmon.object.property.list">
  <description>
    Read all object properties
  </description>
  <sql>
    SELECT p.obj_id,
           p.property_id,
           p.value
    FROM ossmon_object_properties p
    WHERE obj_id=$obj_id
    ORDER BY create_date
  </sql>
</query>

<query name="ossmon.object.property.update">
  <description>
    Update object property
  </description>
  <sql>
    UPDATE ossmon_object_properties
    SET value=[ossweb::sql::quote $value]
    WHERE obj_id=$obj_id AND
          property_id=[ossweb::sql::quote $property_id]
  </sql>
</query>

<query name="ossmon.object.property.create">
  <description>
    Create object property
  </description>
  <sql>
    INSERT INTO ossmon_object_properties
    [ossweb::sql::insert_values -full t { obj_id int ""
                                       property_id "" ""
                                       value "" "" }]
  </sql>
</query>

<query name="ossmon.object.property.delete">
  <description>
    Delete object property
  </description>
  <sql>
    DELETE FROM ossmon_object_properties
    WHERE [ossweb::sql::filter { obj_id int "" property_id list "" }]
  </sql>
</query>

<query name="ossmon.alert.list.active">
  <description>
    Read all alert alerts
  </description>
  <sql>
    SELECT a.alert_id,
           a.alert_name,
           a.alert_type,
           a.alert_level,
           d.device_id,
           d.device_path,
           d.device_name,
           d.device_host
    FROM ossmon_alerts a,
         ossmon_devices d
    WHERE a.alert_status='Active' AND
          d.device_id=a.device_id
    ORDER BY CASE WHEN a.alert_level = 'Error' THEN 0
                  WHEN a.alert_level = 'Warning' THEN 1
                  WHEN a.alert_level = 'Critical' THEN 2
                  WHEN a.alert_level = 'Advise' THEN 3
                  ELSE 4
             END,
             a.alert_time
  </sql>
</query>

<query name="ossmon.alert.search1">
  <description>
    Read all alert alerts
  </description>
  <sql>
    SELECT a.alert_id
    FROM ossmon_alerts a,
         ossmon_devices d
    WHERE a.device_id=d.device_id
          [ossweb::sql::filter \
                { device_name regexp ""
                  device_id ilist ""
                  alert_type list ""
                  alert_status list ""
                  alert_name Text ""
                  alert_object ilist "" } \
                -aliasmap { d. d. } \
                -before AND]
    ORDER BY COALESCE(a.alert_time,'1900-01-10'::DATE) DESC
  </sql>
</query>

<query name="ossmon.alert.search2">
  <description>
    Read all alert alerts
  </description>
  <sql>
    SELECT a.alert_id,
           a.alert_status,
           a.alert_name,
           a.alert_type,
           a.alert_count,
           a.alert_level,
           TO_CHAR(a.alert_time,'MM/DD/YY HH24:MI') AS alert_time,
           TO_CHAR(a.update_time,'MM/DD/YY HH24:MI') AS update_time,
           TO_CHAR(a.create_time,'MM/DD/YY HH24:MI') AS create_time,
           d.device_id,
           d.device_name
    FROM ossmon_alerts a,
         ossmon_devices d
    WHERE a.device_id=d.device_id AND
          a.alert_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossmon.alert.read.count">
  <description>
    Read the most recent active alert record for the given device and alert type
  </description>
  <sql>
    SELECT alert_id,
           CASE WHEN alert_status = 'Pending' THEN 0
                ELSE alert_count
           END AS alert_count,
           CASE WHEN alert_status = 'Pending' THEN ROUND(EXTRACT(EPOCH FROM NOW()))
                ELSE COALESCE(ROUND(EXTRACT(EPOCH FROM alert_time)),0)
           END AS alert_time
    FROM ossmon_alerts
    WHERE device_id=$device_id AND
          alert_type=[ossweb::sql::quote $alert_type] AND
          alert_name=[ossweb::sql::quote $alert_name] AND
          alert_status IN ('Active','Pending')
    ORDER BY alert_status,
             alert_time DESC
    LIMIT 1
  </sql>
</query>

<query name="ossmon.alert.read.active">
  <description>
  </description>
  <sql>
    SELECT alert_id,
           alert_type,
           alert_status,
           alert_count,
           device_id,
           ROUND(EXTRACT(EPOCH FROM (NOW()-update_time)::INTERVAL)) AS interval
    FROM ossmon_alerts
    WHERE alert_status IN ('Active','Pending')
          [ossweb::sql::filter { alert_id ilist "" } -before AND]
  </sql>
</query>

<query name="ossmon.alert.read">
  <description>
    Read alert record
  </description>
  <sql>
    SELECT a.alert_status,
           a.alert_type,
           a.alert_name,
           a.alert_count,
           a.alert_level,
           a.alert_object,
           TO_CHAR(a.alert_time,'YYYY-MM-DD HH24:MI') AS alert_time,
           TO_CHAR(a.update_time,'YYYY-MM-DD HH24:MI') AS update_time,
           TO_CHAR(a.create_time,'YYYY-MM-DD HH24:MI') AS create_time,
           d.device_id,
           d.device_type,
           d.device_name,
           d.device_host,
           ossweb_user_name(a.update_user) AS update_user,
           ossmon_alert_data(a.alert_id) AS alert_data,
           ossmon_device_location(d.device_id,address_id) AS device_location
    FROM ossmon_alerts a,
         ossmon_devices d
    WHERE a.alert_id=$alert_id AND
          a.device_id=d.device_id
  </sql>
</query>

<query name="ossmon.alert.create">
  <description>
    Create alert record
  </description>
  <sql>
    INSERT INTO ossmon_alerts
    [ossweb::sql::insert_values -full t -skip_null t \
                 { alert_id int ""
                   device_id int ""
                   alert_type "" ""
                   alert_level "" Error
                   alert_name "" ""
                   alert_object int "" }]
  </sql>
</query>

<query name="ossmon.alert.update.status">
  <description>
    Updates alert status
  </description>
  <sql>
    UPDATE ossmon_alerts
    SET alert_status='$alert_status',
        update_user=[ossweb::conn user_id 0]
    WHERE alert_id=$alert_id
  </sql>
</query>

<query name="ossmon.alert.update.count">
  <description>
    Updates alert count
  </description>
  <sql>
    UPDATE ossmon_alerts
    SET alert_status='Active',
        alert_count=$alert_count,
        alert_level='$alert_level',
        alert_time='[ns_fmttime $alert_time "%Y-%m-%d %H:%M:%S"]'
    WHERE alert_id=$alert_id
  </sql>
</query>

<query name="ossmon.alert.update.all">
  <description>
    Updates alert status
  </description>
  <sql>
    UPDATE ossmon_alerts
    SET alert_status='$alert_status',
        update_user=[ossweb::conn user_id 0]
    WHERE alert_status IN ('Active','Pending')
  </sql>
</query>

<query name="ossmon.alert.delete">
  <description>
    Delete alert record
  </description>
  <sql>
    DELETE FROM ossmon_alerts WHERE alert_id=$alert_id
  </sql>
</query>

<query name="ossmon.alert.delete.all">
  <description>
    Updates alert status
  </description>
  <sql>
    DELETE FROM ossmon_alerts WHERE alert_status IN ('Active','Pending')
  </sql>
</query>

<query name="ossmon.alert.objects">
  <description>
    Read all object for the given alert
  </description>
  <sql>
    SELECT obj_id,
           obj_host,
           obj_name,
           obj_type
    FROM ossmon_objects
    WHERE device_id=$device_id
    ORDER BY obj_name
  </sql>
</query>

<query name="ossmon.alert.property.read_all">
  <description>
    Read all alert properties
  </description>
  <sql>
    SELECT property_id,value
    FROM ossmon_alert_properties
    WHERE alert_id=$alert_id
    ORDER BY create_date
  </sql>
</query>

<query name="ossmon.alert.property.update">
  <description>
    Update alert property
  </description>
  <sql>
    UPDATE ossmon_alert_properties
    SET value=[ossweb::sql::quote $value]
    WHERE alert_id=$alert_id AND
          property_id='$property_id'
  </sql>
</query>

<query name="ossmon.alert.property.delete">
  <description>
    Update alert property
  </description>
  <sql>
    DELETE FROM ossmon_alert_properties
    WHERE alert_id=$alert_id AND
          property_id='$property_id'
  </sql>
</query>

<query name="ossmon.alert.property.create">
  <description>
    Create alert property
  </description>
  <sql>
    INSERT INTO ossmon_alert_properties
    [ossweb::sql::insert_values -full t \
          { property_id "" ""
            alert_id int ""
            value "" ""}]
  </sql>
</query>

<query name="ossmon.alert.log.create">
  <description>
    Create log entry for the alert
  </description>
  <sql>
    INSERT INTO ossmon_alert_log
    [ossweb::sql::insert_values -full t \
          { log_alert int ""
            log_status "" ""
            log_data "" "" }]
  </sql>
</query>

<query name="ossmon.alert.log.list">
  <description>
  </description>
  <sql>
    SELECT TO_CHAR(l.log_date,'MM/DD/YY HH24:MI') AS alert_time,
           a.alert_status,
           a.alert_type,
           a.alert_level,
           a.alert_name,
           ossmon_device_name(device_id,TRUE) AS device_name,
           SUBSTRING(log_data,1,CASE WHEN POSITION('\n' IN log_data) = 0
                                       THEN LENGTH(log_data)
                                       ELSE POSITION('\n' IN log_data)
                                  END) AS alert_data
    FROM ossmon_alert_log l,
         ossmon_alerts a
    WHERE a.alert_id=l.log_alert AND
          l.log_date > NOW()-'1 hour'::interval
    ORDER BY l.log_date DESC
    LIMIT [ossweb::config ossmon:console:alerts 5]
  </sql>
</query>

<query name="ossmon.alert.log.search1">
  <description>
    Read alert log records
  </description>
  <sql>
    SELECT log_id
    FROM ossmon_alert_log
    WHERE log_alert=$alert_id
    ORDER BY log_date DESC
    LIMIT 10
  </sql>
</query>

<query name="ossmon.alert.log.search2">
  <description>
    Read alert log records
  </description>
  <sql>
    SELECT log_id,log_date,log_data FROM ossmon_alert_log WHERE log_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossmon.alert.problem.create">
  <description>
    Problem create
  </description>
  <sql>
    SELECT problem_create(
           $project_id,
           [ossweb::sql::quote [ossmon::monitor $name ossmon:alert:problem:type -config problem]],
           [ossweb::sql::quote [ossmon::monitor $name ossmon:alert:problem:status -config open]],
           [ossweb::sql::quote $subject],
           [ossweb::sql::quote $body],
           [ossmon::monitor $name ossmon:user:id -config 0])
  </sql>
</query>

<query name="ossmon.alert.problem.close">
  <description>
    Problem close
  </description>
  <sql>
    SELECT problem_notes(
           $problem_id,
           [ossweb::sql::quote [ossmon::object $name ossmon:alert:problem:closed:status -config completed]],
           [ossweb::sql::quote [ossmon::object $name ossmon:alert:problem:closed:notes -config "Problem resolved"]],
           [ossmon::object $name ossmon:user_id -config 0])
  </sql>
</query>

<query name="ossmon.alert.problem.notes">
  <description>
    Problem notes
  </description>
  <sql>
    SELECT problem_notes($problem_id,NULL,[ossweb::sql::quote $body],[ossmon::object $name ossmon:user_id -config 0])
  </sql>
</query>

<query name="ossmon.alert.problem.active">
  <description>
    Return 1 if problem is still active
  </description>
  <sql>
    SELECT 1
    FROM problems
    WHERE problem_id='$problem_id' AND
          problem_status NOT IN ('complete','closed','cancelled','deleted')
  </sql>
</query>

<query name="ossmon.alert_rule.list">
  <description>
    Action rule list
  </description>
  <sql>
     SELECT rule_id,
            rule_name,
            precedence,
            level,
            threshold,
            interval,
            COALESCE(mode,'ALERT') AS mode,
            ossmon_type,
            ossmon_rule_alerts(rule_id) AS alerts
     FROM ossmon_alert_rules
     WHERE [ossweb::sql::filter \
                 { status list "" }]
     ORDER BY mode,
              precedence,
              rule_name
  </sql>
</query>

<query name="ossmon.alert_rule.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_alert_rules
    [ossweb::sql::insert_values -full t \
          { rule_name "" ""
            status "" "Active"
            precedence int 0
            threshold int ""
            interval int ""
            level "" Error
            ossmon_type "" ""
            mode "" "ALERT" }]
  </sql>
</query>

<query name="ossmon.alert_rule.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_alert_rules
    SET [ossweb::sql::update_values \
          { rule_id int ""
            rule_name "" ""
            status "" "Active"
            precedence int 0
            threshold int ""
            interval int ""
            level "" Error
            ossmon_type "" ""
            mode "" "ALERT" }]
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_alert_rules WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.read">
  <description>
  </description>
  <sql>
    SELECT rule_id,
           rule_name,
           status,
           precedence,
           threshold,
           interval,
           level,
           mode,
           ossmon_type
    FROM ossmon_alert_rules
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.copy">
  <description>
    Copy ossmon object record
  </description>
  <sql>
    INSERT INTO ossmon_alert_rules (rule_id,rule_name,status,precedence,threshold,interval,level,mode,ossmon_type)
    SELECT $new_rule_id,
           'COPY:'||rule_name,
           status,
           precedence,
           threshold,
           interval,
           level,
           mode,
           ossmon_type
    FROM ossmon_alert_rules
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.copy.match">
  <description>
    Copy object properties
  </description>
  <sql>
    INSERT INTO ossmon_alert_match (rule_id,name,operator,value,mode)
    SELECT $new_rule_id,name,operator,value,mode
    FROM ossmon_alert_match
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.copy.run">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_alert_run (rule_id,action_type,template_id)
    SELECT $new_rule_id,action_type,template_id
    FROM ossmon_alert_run
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.match.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_alert_match
    [ossweb::sql::insert_values -full t\
          { rule_id int ""
            name "" ""
            operator "" ""
            value "" ""
            mode "" "AND" }]
  </sql>
</query>

<query name="ossmon.alert_rule.match.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_alert_match
    SET [ossweb::sql::update_values \
          { rule_id int ""
            match_id int ""
            name "" ""
            operator "" ""
            value "" ""
            mode "" "AND" }]
    WHERE match_id=$match_id
  </sql>
</query>

<query name="ossmon.alert_rule.match.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_alert_match WHERE match_id=$match_id
  </sql>
</query>

<query name="ossmon.alert_rule.match">
  <description>
    Match part of action rules
  </description>
  <sql>
    SELECT name,
           operator,
           value,
           mode
    FROM ossmon_alert_match
    WHERE rule_id=$rule_id
    ORDER BY match_id
  </sql>
</query>

<query name="ossmon.alert_rule.match.read">
  <description>
    Match part of action rules
  </description>
  <sql>
    SELECT name,
           operator,
           value,
           mode
    FROM ossmon_alert_match
    WHERE match_id=$match_id
  </sql>
</query>

<query name="ossmon.alert_rule.match_list">
  <description>
    Match part of action rules
  </description>
  <sql>
    SELECT match_id,
           name,
           operator,
           value,
           mode
    FROM ossmon_alert_match
    WHERE rule_id=$rule_id
    ORDER BY match_id
  </sql>
</query>

<query name="ossmon.alert_rule.match.delete_all">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_alert_match WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.run">
  <description>
    Run part of action rule
  </description>
  <sql>
    SELECT action_type,
           template_id
    FROM ossmon_alert_run
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.run.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_alert_run
    [ossweb::sql::insert_values -full t \
          { rule_id int ""
            action_type "" ""
            template_id int ""
            template_name var "" }]

  </sql>
</query>

<query name="ossmon.alert_rule.run.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_alert_run
    SET [ossweb::sql::update_values \
          { rule_id int ""
            run_id int ""
            action_type "" ""
            template_id int ""
            template_name var "" }]
    WHERE run_id=$run_id
  </sql>
</query>

<query name="ossmon.alert_rule.run.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_alert_run WHERE run_id=$run_id
  </sql>
</query>

<query name="ossmon.alert_rule.run_list">
  <description>
    Run part of action rule
  </description>
  <sql>
    SELECT run_id,
           action_type,
           m.template_id,
           template_name
    FROM ossmon_alert_run m,
         ossmon_templates tm
    WHERE rule_id=$rule_id AND
          m.template_id=tm.template_id
  </sql>
</query>

<query name="ossmon.alert_rule.template_list">
  <description>
    Run part of action rule
  </description>
  <sql>
    SELECT r.rule_id,
           r.rule_name,
           m.action_type
    FROM ossmon_alert_run m,
         ossmon_alert_rules r
    WHERE template_id=$template_id AND
          m.rule_id=r.rule_id
  </sql>
</query>

<query name="ossmon.alert_rule.run.delete_all">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_alert_run WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.action_rule.active">
  <description>
    List of action rules
  </description>
  <sql>
    SELECT rule_id,
           rule_name,
           mode
    FROM ossmon_action_rules
    WHERE status='Active'
    ORDER BY precedence
  </sql>
</query>

<query name="ossmon.action_rule.list">
  <description>
    List of action rules
  </description>
  <sql>
    SELECT rule_id,
           rule_name,
           status,
           precedence,
           mode
    FROM ossmon_action_rules
    ORDER BY mode,
             precedence
  </sql>
</query>

<query name="ossmon.action_rule.read">
  <description>
    Read action rule
  </description>
  <sql>
    SELECT rule_id,
           rule_name,
           status,
           precedence,
           mode
    FROM ossmon_action_rules
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.action_rule.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_action_rules
    [ossweb::sql::insert_values -full t \
          { rule_name "" ""
            status "" "Active"
            precedence int 0
            mode "" "" }]
  </sql>
</query>

<query name="ossmon.action_rule.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_action_rules
    SET [ossweb::sql::update_values \
          { rule_id int ""
            rule_name "" ""
            status "" "Active"
            precedence int 0
            mode "" "" }]
    WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.action_rule.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_action_rules WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.action_rule.match">
  <description>
    Match part of rules
  </description>
  <sql>
    SELECT name,
           operator,
           value,
           mode
    FROM ossmon_action_match
    WHERE rule_id=$rule_id
    ORDER BY match_id
  </sql>
</query>

<query name="ossmon.action_rule.match_list">
  <description>
    Match part of rules
  </description>
  <sql>
    SELECT match_id,
           name,
           operator,
           value,
           mode
    FROM ossmon_action_match
    WHERE rule_id=$rule_id
    ORDER BY match_id
  </sql>
</query>

<query name="ossmon.action_rule.match_read">
  <description>
    Match part of rules
  </description>
  <sql>
    SELECT match_id,
           name,
           operator,
           value,
           mode
    FROM ossmon_action_match
    WHERE match_id=$match_id
  </sql>
</query>

<query name="ossmon.action_rule.match_create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_action_match
    [ossweb::sql::insert_values -full t \
          { rule_id int ""
            name "" ""
            operator "" ""
            value "" ""
            mode "" "" }]
  </sql>
</query>

<query name="ossmon.action_rule.match_update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_action_match
    SET [ossweb::sql::update_values \
              { rule_id int ""
                name "" ""
                operator "" ""
                value "" ""
                mode "" "" }]
    WHERE match_id=$match_id
  </sql>
</query>

<query name="ossmon.action_rule.match_delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_action_match WHERE match_id=$match_id
  </sql>
</query>

<query name="ossmon.action_rule.match_delete_all">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_action_match WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.action_rule.script">
  <description>
    Script for action rule
  </description>
  <sql>
    SELECT value FROM ossmon_action_script WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.action_rule.script_list">
  <description>
    Script for action rule
  </description>
  <sql>
    SELECT script_id,value FROM ossmon_action_script WHERE rule_id=$rule_id ORDER BY script_id
  </sql>
</query>

<query name="ossmon.action_rule.script_create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_action_script
    [ossweb::sql::insert_values -full t \
          { rule_id int ""
            value "" "" }]
  </sql>
</query>

<query name="ossmon.action_rule.script_update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_action_script
    SET [ossweb::sql::update_values \
              { rule_id int ""
                value "" "" }]
    WHERE script_id=$script_id
  </sql>
</query>

<query name="ossmon.action_rule.script_delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_action_script WHERE script_id=$script_id
  </sql>
</query>

<query name="ossmon.action_rule.script_delete_all">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_action_script WHERE rule_id=$rule_id
  </sql>
</query>

<query name="ossmon.template.list">
  <description>
    All templates
  </description>
  <sql>
    SELECT template_name,
           template_id,
           template_actions
    FROM ossmon_templates
    ORDER BY template_name
  </sql>
</query>

<query name="ossmon.template.read">
  <description>
    Read record
  </description>
  <sql>
    SELECT template_id,
           template_name,
           template_actions
    FROM ossmon_templates
    WHERE template_id=$template_id
  </sql>
</query>

<query name="ossmon.template.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_templates
    [ossweb::sql::insert_values -full t \
          { template_name "" ""
            template_actions "" "" }]
  </sql>
</query>

<query name="ossmon.template.copy">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_templates(template_id,template_name,template_actions)
    SELECT $template_id,'COPY:'||template_name,template_actions||'\n'
    FROM ossmon_templates
    WHERE template_id=$old_template_id
  </sql>
</query>

<query name="ossmon.template.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_templates
    SET [ossweb::sql::update_values \
              { template_id "" ""
                template_name "" ""
                template_actions "" "" }]
    WHERE template_id=$template_id
  </sql>
</query>

<query name="ossmon.template.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_templates WHERE template_id=$template_id
  </sql>
</query>

<query name="ossmon.map.list">
  <description>
  </description>
  <sql>
    SELECT map_name,
           map_id,
           map_image
    FROM ossmon_maps
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.map.read">
  <description>
  </description>
  <sql>
    SELECT map_name,
           map_id,
           map_image
    FROM ossmon_maps
    WHERE map_id=$map_id
  </sql>
</query>

<query name="ossmon.map.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_maps
    [ossweb::sql::insert_values -full t \
          { map_name "" ""
            map_image "" "" }]
  </sql>
</query>

<query name="ossmon.map.update">
  <description>
  </description>
  <sql>
    UPDATE ossmon_maps
    SET [ossweb::sql::update_values -skip_null t \
              { map_name "" ""
                map_image "" "" }]
    WHERE map_id=$map_id
  </sql>
</query>

<query name="ossmon.map.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_maps WHERE map_id=$map_id
  </sql>
</query>

<query name="ossmon.map.device.list">
  <description>
  </description>
  <sql>
    SELECT d.device_id,
           d.device_name,
           d.device_host,
           ossweb_company_name(d.device_vendor) AS device_vendor,
           d.device_type,
           d.device_path,
           x,
           y
    FROM ossmon_devices d
         LEFT OUTER JOIN ossmon_map_devices m
           ON m.device_id=d.device_id AND
              m.map_id=$map_id
    WHERE disable_flag = FALSE
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.map.device.list.active">
  <description>
  </description>
  <sql>
    SELECT d.device_id,
           d.device_name,
           d.device_host,
           ossweb_company_name(d.device_vendor) AS device_vendor,
           d.device_type,
           d.device_path,
           x,
           y
    FROM ossmon_devices d,
         ossmon_map_devices m
    WHERE disable_flag = FALSE AND
          m.device_id=d.device_id AND
          m.map_id=$map_id
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.map.device.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_map_devices (map_id,device_id,x,y)
    VALUES($map_id,$device_id,$x,$y)
  </sql>
</query>

<query name="ossmon.map.device.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossmon_map_devices WHERE map_id=$map_id
  </sql>
</query>

<query name="ossmon.report.read">
  <description>
    Read record
  </description>
  <sql>
    SELECT report_id
    FROM report_types
    WHERE [ossweb::sql::filter \
          { report_type "" ""
            report_name "" ""
            xql_id "" "" }]
  </sql>
</query>

<query name="ossmon.report.create">
  <description>
    Create record
  </description>
  <sql>
    INSERT INTO report_types
                [ossweb::sql::insert_values -full t \
                      { report_type "" ""
                        report_name "" ""
                        xql_id "" ""}]
  </sql>
</query>

<query name="ossmon.report.category.create">
  <description>
    Create catetory
  </description>
  <sql>
    INSERT INTO report_categories
    [ossweb::sql::insert_values -full t \
          { category_id "" ""
            category_name "" ""
            category_parent "" "" }]
  </sql>
</query>

<query name="ossmon.report.category.read">
  <description>
    Read record
  </description>
  <sql>
    SELECT category_id
    FROM report_categories
    WHERE [ossweb::sql::filter \
                { category_id "" ""
                  category_name "" "" }]
  </sql>
</query>

<query name="ossmon.report.category.delete.old">
  <description>
    Delete old reports
  </description>
  <sql>
    DELETE FROM report_categories
    WHERE NOW() - create_date > '31 days'::INTERVAL AND
          category_parent='$category_parent'
  </sql>
</query>

<query name="ossmon.report.nat.records">
  <description>
   NAT records
  </description>
  <sql>
    SELECT TO_CHAR(timestamp,'MM/DD/YY HH24:MI:SS') AS "Date",
           private_ip AS "Private IP",
           public_ip AS "Public IP",
           flows AS "Flows"
    FROM ossmon_nat
    WHERE [ossweb::sql::filter \
                { start_date datetime ""
                  end_date datetime ""
                  private_ip int ""
                  public_ip int ""
                  flows int "" } \
                -map { start_date "timestamp >= '%value'"
                       end_date "timestamp <= '%value'"
                       private_ip "private_ip <<= '%value'"
                       public_ip "public_ip <<= '%value'"
                       flows "flows >= %value" }]
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.report.nat.last.record">
  <description>
   NAT records
  </description>
  <sql>
    SELECT TO_CHAR(timestamp,'MM/DD/YY HH24:MI:SS') AS timestamp,
           private_ip,
           public_ip,
           flows
    FROM ossmon_nat
    WHERE [ossweb::sql::filter \
                { start_date date ""
                  end_date date ""
                  private_ip int ""
                  public_ip int "" } \
                -map { start_date "timestamp >= '%value 0:0'"
                       end_date "timestamp <= '%value 23:59'"
                       private_ip "private_ip <<= '%value'"
                       public_ip "public_ip <<= '%value'" }]
    ORDER BY timestamp DESC
    LIMIT 1
  </sql>
</query>

<query name="ossmon.report.nat.lifetime">
  <description>
    NAT Streams lifetime
  </description>
  <sql>
    SELECT ROUND(EXTRACT(EPOCH FROM timestamp)) AS timestamp,
           private_ip,
           public_ip,
           flows
    FROM ossmon_nat
    WHERE [ossweb::sql::filter \
                { start_date datetime ""
                  end_date datetime ""
                  private_ip int ""
                  public_ip int ""
                  flows int "" } \
                -map { start_date "timestamp >= '%value'"
                       end_date "timestamp <= '%value'"
                       private_ip "private_ip <<= '%value'"
                       public_ip "public_ip <<= '%value'"
                       flows "flows >= %value" }]
    ORDER BY 1,2
  </sql>
</query>

<query name="ossmon.report.mac.last.record">
  <description>
   NAT records
  </description>
  <sql>
    SELECT TO_CHAR(timestamp,'MM/DD/YY HH24:MI:SS') AS timestamp,
           ipaddr,
           macaddr,
           discover_count
    FROM ossmon_mac
    WHERE [ossweb::sql::filter \
                { start_date date ""
                  end_date date ""
                  ipaddr "" ""
                  macaddr str "" } \
                -map { start_date "timestamp >= '%value 0:0'"
                       end_date "timestamp <= '%value 23:59'" }]
    ORDER BY timestamp DESC
    LIMIT 1
  </sql>
</query>

<query name="ossmon.report.mac.records">
  <description>
   MAC records
  </description>
  <sql>
    SELECT TO_CHAR(timestamp,'MM/DD/YY HH24:MI:SS') AS "Date",
           ipaddr AS "IP Address",
           macaddr AS "MAC Address",
           host AS "Switch",
           discover_count AS "Discover Count"
    FROM ossmon_mac
    WHERE [ossweb::sql::filter \
                { start_date datetime ""
                  end_date datetime ""
                  ipaddr int ""
                  macaddr Text ""
                  discover_count int "" } \
                -map { start_date "timestamp >= '%value'"
                       end_date "timestamp <= '%value'"
                       ipaddr "ipaddr <<= '%value'"
                       discover_count "discover_count >= %value" }]
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.report.ip.node.failure">
  <description>
    IP Node failure
  </description>
  <sql>
    SELECT ossmon_device_name(device_id) AS "Device",
           ROUND(EXTRACT(EPOCH FROM l.log_date)) AS timestamp,
           l.log_status AS _log_status,
           CASE WHEN a.alert_status = 'Pending' THEN ROUND(EXTRACT(EPOCH FROM a.pending_time))
                WHEN a.alert_status = 'Closed' THEN ROUND(EXTRACT(EPOCH FROM a.closed_time))
                ELSE NULL
           END AS _alert_timestamp
    FROM ossmon_alerts a,
         ossmon_alert_log l
    WHERE a.alert_id=l.log_alert AND
          l.log_status ~ '^noConnectivity|^(OK|Closed)$' AND
          [ossweb::sql::filter \
                { device_id ilist ""
                  start_date date ""
                  end_date date "" } \
                -map { start_date "l.log_date >= '%value 0:0'"
                       end_date "l.log_date <= '%value 23:59'" }]
    ORDER BY 1,2
  </sql>
</query>

<query name="ossmon.report.ip.rate.summary">
  <description>
   interface records
  </description>
  <sql>
    SELECT ROUND((SUM(in_rate)/1024)::NUMERIC,0) AS in_rate,
           ROUND((SUM(out_rate)/1024)::NUMERIC,0) AS out_rate,
           ROUND((SUM(in_trans)/1024)::NUMERIC,0) AS in_trans,
           ROUND((SUM(out_trans)/1024)::NUMERIC,0) AS out_trans,
           SUM(in_err) AS in_err,
           SUM(out_err) AS out_err
    FROM ossmon_iftable
    WHERE [ossweb::sql::filter \
                { start_date date ""
                  end_date date ""
                  ifDescr int ""
                  obj_id int "" } \
                -map { start_date "timestamp >= '%value 0:0'"
                       end_date "timestamp <= '%value 23:59'"
                       ifDescr "name = '%value'" }]
  </sql>
</query>

<query name="ossmon.report.dco_report">
  <description>
   MAC records
  </description>
  <sql>
    SELECT TO_CHAR(collect_time,'MM/DD/YY HH24:MI') AS "Collect",
           TO_CHAR(complete_time,'MM/DD/YY HH24:MI') AS "Complete",
           olosz,
           odd3s,
           olous,
           otous,
           ollus,
           oltat,
           oltec,
           oltnp,
           ollat,
           ollec,
           ollnp,
           ocnen,
           ocnfa,
           ocnfm,
           ocnte,
           ocnof,
           gicnp60,
           gicnp61,
           gicnp62,
           gicnp63,
           gtius60,
           gtius61,
           gtius62,
           gtius63,
           gtius80,
           gtius81,
           gtius82,
           gtius83,
           gocnp70,
           gocnp80,
           gocnp71,
           gocnp81,
           gocnp72,
           gocnp82,
           gocnp73,
           gocnp83,
           gocnp38,
           gocnp79,
           gocnp37,
           gocnp103,
           gocnp104,
           gtous70,
           gtous80,
           gtous71,
           gtous81,
           gtous72,
           gtous82,
           gtous73,
           gtous83,
           gtous38,
           gtous79,
           gtous37,
           gtous103,
           gtous104
    FROM ossmon_dco
    WHERE name LIKE 'dco_report%' AND
          [ossweb::sql::filter \
                { start_date date ""
                  end_date date "" } \
                -map { start_date "collect_time >= '%value 0:0'"
                       end_date "collect_time <= '%value 23:59'" }]
    ORDER BY collect_time
  </sql>
</query>

<query name="ossmon.report.dco_alarm">
  <description>
   MAC records
  </description>
  <sql>
    SELECT TO_CHAR(COALESCE(collect_time,timestamp),'MM/DD/YY HH24:MI:SS') AS "Timestamp",
           log_severity AS "Severity",
           log_type AS "Alarm Type",
           name AS "Alarm Name",
           log_data AS "Data"
    FROM ossmon_dco
    WHERE name NOT LIKE 'dco_report%' AND
          [ossweb::sql::filter \
                { start_date date ""
                  end_date date ""
                  name Text ""
                  mask int ""
                  log_type Text ""
                  log_severity Text ""
                  log_data Text "" } \
                -map { start_date "collect_time >= '%value 0:0'"
                       end_date "collect_time <= '%value 23:59'"
                       mask "(log_type !~ '%value' AND name !~ '%value')" }]
    ORDER BY COALESCE(collect_time,timestamp)
  </sql>
</query>

<query name="ossmon.report.dco_alarm.totally">
  <description>
   MAC records
  </description>
  <sql>
    SELECT [ossweb::decode $daily 1 "collect_time::DATE AS \"Date\"," ""]
           log_type AS "Alarm Type",
           COUNT(*) AS "Total"
    FROM ossmon_dco
    WHERE name NOT LIKE 'dco_report%' AND
          [ossweb::sql::filter \
                { start_date date ""
                  end_date date ""
                  name Text ""
                  mask int ""
                  log_type Text ""
                  log_severity Text ""
                  log_data Text "" } \
                -map { start_date "collect_time >= '%value 0:0'"
                       end_date "collect_time <= '%value 23:59'"
                       mask "(log_type !~ '%value' AND name !~ '%value')" }]
    GROUP BY [ossweb::decode $daily 1 "collect_time::DATE," ""]
             log_type
    ORDER BY 1
  </sql>
</query>

<query name="ossmon.collect.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_collect (timestamp,obj_id,host,name,value)
    VALUES('[ns_fmttime [ossmon::object $name time:now] "%Y-%m-%d %H:%M:%S"]',
           [ossmon::object $name obj:id],
           '[ossmon::object $name obj:host]',
           [ossweb::sql::quote $key],
           $value,
           [ossweb::sql::quote [ossweb::coalesce key]],
           [ossweb::coalesce value2 NULL])
  </sql>
</query>

<query name="ossmon.dco.create.report">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_dco
              (name,collect_time,complete_time,olosz,odd3s,olous,
               otous,ollus,oltat,oltec,oltnp,ollat,ollec,ollnp,
               ocnen,ocnfa,ocnfm,ocnte,ocnof,gicnp60,gicnp61,
               gicnp62,gicnp63,gtius60,gtius61,gtius62,gtius63,
               gocnp70,gocnp80,gocnp71,gocnp81,gocnp72,gocnp82,
               gocnp73,gocnp83,gocnp38,gocnp79,gocnp37,gocnp103,
               gocnp104,gtous70,gtous80,gtous71,gtous81,gtous72,
               gtous82, gtous73,gtous83,gtous38,gtous79,gtous37,
               gtous103,gtous104,gtius80,gtius81,gtius82,gtius83,
               log_type,log_severity,log_data)
          SELECT [ossweb::sql::insert_values \
                       { name "" ""
                         collect_time "" ""
                         complete_time "" ""
                         olosz int ""
                         odd3s int ""
                         olous int ""
                         otous int ""
                         ollus int ""
                         oltat int ""
                         oltec int ""
                         oltnp int ""
                         ollat int ""
                         ollec int ""
                         ollnp int ""
                         ocnen int ""
                         ocnfa int ""
                         ocnfm int ""
                         ocnte int ""
                         ocnof int ""
                         gicnp60 int ""
                         gicnp61 int ""
                         gicnp62 int ""
                         gicnp63 int ""
                         gtius60 int ""
                         gtius61 int ""
                         gtius62 int ""
                         gtius63 int ""
                         gocnp70 int ""
                         gocnp80 int ""
                         gocnp71 int ""
                         gocnp81 int ""
                         gocnp72 int ""
                         gocnp82 int ""
                         gocnp73 int ""
                         gocnp83 int ""
                         gocnp38 int ""
                         gocnp79 int ""
                         gocnp37 int ""
                         gocnp103 int ""
                         gocnp104 int ""
                         gtous70 int ""
                         gtous80 int ""
                         gtous71 int ""
                         gtous81 int ""
                         gtous72 int ""
                         gtous82 int ""
                         gtous73 int ""
                         gtous83 int ""
                         gtous38 int ""
                         gtous79 int ""
                         gtous37 int ""
                         gtous103 int ""
                         gtous104 int ""
                         gtius80 int ""
                         gtius81 int ""
                         gtius82 int ""
                         gtius83 int ""
                         log_type "" ""
                         log_severity "" ""
                         log_data "" "" }]
          WHERE NOT EXISTS(SELECT 1
                           FROM ossmon_dco
                           WHERE [ossweb::sql::filter \
                                       { name "" ""
                                         collect_time "" ""
                                         complete_time "" ""
                                         olosz int ""
                                         odd3s int ""
                                         olous int ""
                                         otous int ""
                                         ollus int ""
                                         oltat int ""
                                         oltec int ""
                                         oltnp int ""
                                         ollat int ""
                                         ollec int ""
                                         ollnp int ""
                                         ocnen int ""
                                         ocnfa int ""
                                         ocnfm int ""
                                         ocnte int ""
                                         ocnof int ""
                                         gicnp60 int ""
                                         gicnp61 int ""
                                         gicnp62 int ""
                                         gicnp63 int ""
                                         gtius60 int ""
                                         gtius61 int ""
                                         gtius62 int ""
                                         gtius63 int ""
                                         gocnp70 int ""
                                         gocnp80 int ""
                                         gocnp71 int ""
                                         gocnp81 int ""
                                         gocnp72 int ""
                                         gocnp82 int ""
                                         gocnp73 int ""
                                         gocnp83 int ""
                                         gocnp38 int ""
                                         gocnp79 int ""
                                         gocnp37 int ""
                                         gocnp103 int ""
                                         gocnp104 int ""
                                         gtous70 int ""
                                         gtous80 int ""
                                         gtous71 int ""
                                         gtous81 int ""
                                         gtous72 int ""
                                         gtous82 int ""
                                         gtous73 int ""
                                         gtous83 int ""
                                         gtous38 int ""
                                         gtous79 int ""
                                         gtous37 int ""
                                         gtous103 int ""
                                         gtous104 int ""
                                         gtius80 int ""
                                         gtius81 int ""
                                         gtius82 int ""
                                         gtius83 int ""
                                         log_type "" ""
                                         log_severity "" ""
                                         log_data "" "" }])
  </sql>
</query>

<query name="ossmon.nat.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_nat (timestamp,obj_id,host,private_ip,public_ip,flows)
    VALUES('[ns_fmttime [ossmon::object $name time:now] "%Y-%m-%d %H:%M:%S"]',
           [ossmon::object $name obj:id],
           '[ossmon::object $name obj:host]',
           '$private_ip',
           '$public_ip',
           $flows)
  </sql>
</query>

<query name="ossmon.nat.collect.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_collect (timestamp,obj_id,host,name,value)
    VALUES('[ns_fmttime [ossmon::object $name time:now] "%Y-%m-%d %H:%M:%S"]',
           [ossmon::object $name obj:id],
           '[ossmon::object $name obj:host]',
           'NAT Stat: $pool_name',
           '$pool_count')
  </sql>
</query>

<query name="ossmon.ping.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_ping (timestamp,obj_id,host,sent,received,loss,rtt_min,rtt_avg,rtt_max)
    VALUES('[ns_fmttime [ossmon::object $name time:now] "%Y-%m-%d %H:%M:%S"]',
           [ossmon::object $name obj:id],
           '[ossmon::object $name obj:host]',
           [ossweb::sql::quote $sent int],
           [ossweb::sql::quote $received int],
           [ossweb::sql::quote $loss int],
           [ossweb::sql::quote $rttMin int],
           [ossweb::sql::quote $rttAvg int],
           [ossweb::sql::quote $rttMax int])
  </sql>
</query>

<query name="ossmon.ifTable.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_iftable (timestamp,obj_id,host,name,delta,utilization,in_rate,
                                out_rate,in_drop,out_drop,in_err,out_err,
                                in_trans,out_trans,in_pkt,out_pkt)
    VALUES('[ns_fmttime [ossmon::object $name time:now] "%Y-%m-%d %H:%M:%S"]',
           [ossmon::object $name obj:id],
           '[ossmon::object $name obj:host]',
           [ossweb::sql::quote $ifDescr],
           [ossweb::sql::quote $deltaUp int],
           [ossweb::sql::quote $util int],
           [ossweb::sql::quote $inRate int],
           [ossweb::sql::quote $outRate int],
           [ossweb::sql::quote $inDrop int],
           [ossweb::sql::quote $outDrop int],
           [ossweb::sql::quote $inErr int],
           [ossweb::sql::quote $outErr int],
           [ossweb::sql::quote $inTrans int],
           [ossweb::sql::quote $outTrans int],
           [ossweb::sql::quote $inPkt int],
           [ossweb::sql::quote $outPkt int])
  </sql>
</query>

<query name="ossmon.mac.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossmon_mac (timestamp,host,macaddr,ipaddr,discover_count)
    VALUES('[ns_fmttime [ossmon::object $name time:now] "%Y-%m-%d %H:%M:%S"]',
           '$host',
           '$macaddr',
           '$ipaddr',
           [ossweb::sql::quote $discover_count int])
  </sql>
</query>

</xql>
