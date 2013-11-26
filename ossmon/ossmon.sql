/* Author: Vlad Seryakov vlad@crystalballinc.com
   August 2001
*/

CREATE SEQUENCE ossmon_seq START 1;
CREATE SEQUENCE ossmon_device_seq START 1;
CREATE SEQUENCE ossmon_object_seq START 1;
CREATE SEQUENCE ossmon_alert_seq START 1;
CREATE SEQUENCE ossmon_log_seq START 1;
CREATE SEQUENCE ossmon_model_seq START 1;
CREATE SEQUENCE ossmon_dco_seq START 1;
CREATE SEQUENCE ossmon_util_seq START 1000;

CREATE TABLE ossmon_device_types (
   type_id VARCHAR NOT NULL,
   type_name VARCHAR NOT NULL,
   description TEXT NULL,
   CONSTRAINT ossmon_device_type_pk PRIMARY KEY(type_id),
   CONSTRAINT ossmon_device_type_un UNIQUE(type_name)
);

CREATE TABLE ossmon_device_models (
   model_id INTEGER NOT NULL DEFAULT NEXTVAL('ossmon_model_seq') PRIMARY KEY,
   device_model VARCHAR NOT NULL,
   device_vendor INTEGER NOT NULL REFERENCES ossweb_companies(company_id),
   device_type VARCHAR NOT NULL REFERENCES ossmon_device_types(type_id),
   description TEXT NULL,
   CONSTRAINT ossmon_model_type_un UNIQUE(device_vendor,model_id)
);

CREATE TABLE ossmon_devices (
   device_id INTEGER DEFAULT NEXTVAL('ossmon_device_seq') NOT NULL,
   device_name VARCHAR NOT NULL,
   device_type VARCHAR NOT NULL REFERENCES ossmon_device_types(type_id),
   device_host VARCHAR NULL,
   device_parent INTEGER NULL,
   device_path VARCHAR NULL,
   device_vendor INTEGER NULL REFERENCES ossweb_companies(company_id),
   device_model INTEGER NULL REFERENCES ossmon_device_models(model_id),
   device_software VARCHAR NULL,
   device_serialnum VARCHAR NULL,
   device_count INTEGER DEFAULT 0 NOT NULL,
   object_count INTEGER DEFAULT 0 NOT NULL,
   description VARCHAR NULL,
   disable_flag BOOLEAN DEFAULT FALSE NOT NULL,
   priority INTEGER DEFAULT 0 NOT NULL,
   address_id INTEGER NULL REFERENCES ossweb_locations(address_id),
   project_id INTEGER NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
   update_time TIMESTAMP WITH TIME ZONE NULL,
   update_user INTEGER NULL,
   CONSTRAINT ossmon_device_pk PRIMARY KEY(device_id),
   CONSTRAINT ossmon_device_un UNIQUE(device_name,device_type),
   CONSTRAINT ossmon_devicesn_un UNIQUE(device_serialnum)
);

CREATE INDEX ossmon_device_idx1 ON ossmon_devices(device_path);
CREATE INDEX ossmon_device_idx2 ON ossmon_devices(device_parent);

CREATE TABLE ossmon_device_properties (
   device_id INTEGER NOT NULL REFERENCES ossmon_devices(device_id) ON DELETE CASCADE,
   property_id VARCHAR NOT NULL,
   value VARCHAR NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT ossmon_deviceprop_pk PRIMARY KEY(device_id,property_id)
);

CREATE TABLE ossmon_maps (
    map_id INTEGER DEFAULT NEXTVAL('ossmon_seq') NOT NULL,
    map_name VARCHAR NOT NULL,
    map_image VARCHAR NOT NULL,
    CONSTRAINT ossmon_map_pk PRIMARY KEY (map_id)
);

CREATE TABLE ossmon_map_devices (
    map_id INTEGER NOT NULL REFERENCES ossmon_maps(map_id) ON DELETE CASCADE,
    device_id INTEGER NOT NULL REFERENCES ossmon_devices(device_id) ON DELETE CASCADE,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    CONSTRAINT ossmon_devices_pk PRIMARY KEY (map_id,device_id)
);

CREATE TABLE ossmon_objects (
   obj_id INTEGER DEFAULT NEXTVAL('ossmon_object_seq') NOT NULL,
   obj_type VARCHAR NOT NULL,
   obj_host VARCHAR NULL,
   obj_name VARCHAR NULL,
   obj_stats VARCHAR NULL,
   obj_parent INTEGER NULL,
   obj_count INTEGER DEFAULT 0 NOT NULL,
   device_id INTEGER NOT NULL REFERENCES ossmon_devices(device_id) ON DELETE CASCADE,
   priority INTEGER DEFAULT 0 NOT NULL,
   disable_flag BOOLEAN DEFAULT FALSE NOT NULL,
   console_flag BOOLEAN DEFAULT FALSE NOT NULL,
   charts_flag VARCHAR NULL,
   description VARCHAR NULL,
   alert_id INTEGER NULL,
   poll_time TIMESTAMP WITH TIME ZONE NULL,
   update_time TIMESTAMP WITH TIME ZONE NULL,
   collect_time TIMESTAMP WITH TIME ZONE NULL,
   CONSTRAINT ossmon_object_pk PRIMARY KEY(obj_id),
   CONSTRAINT ossmon_object_un UNIQUE(obj_name,obj_host,obj_type)
);

CREATE INDEX ossmon_object_parent_idx ON ossmon_objects(obj_parent);
CREATE INDEX ossmon_object_device_idx ON ossmon_objects(device_id,obj_id);

CREATE TABLE ossmon_object_properties (
   obj_id INTEGER NOT NULL REFERENCES ossmon_objects(obj_id) ON DELETE CASCADE,
   property_id VARCHAR NOT NULL,
   value VARCHAR NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT ossmon_objprop_pk PRIMARY KEY(obj_id,property_id)
);

CREATE TABLE ossmon_templates (
   template_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   template_name VARCHAR(64) NOT NULL,
   template_actions text NOT NULL,
   CONSTRAINT ossmon_templates_pk PRIMARY KEY(template_id),
   CONSTRAINT ossmon_templates_uk UNIQUE(template_actions)
);

CREATE TABLE ossmon_alert_rules (
   rule_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   rule_name VARCHAR(128) NOT NULL,
   status VARCHAR DEFAULT 'Active' NOT NULL,
   precedence INTEGER NULL,
   threshold INTEGER NULL,
   interval INTEGER NULL,
   timeout INTEGER NULL,
   description VARCHAR NULL,
   ossmon_type VARCHAR NULL,
   level VARCHAR DEFAULT 'Error' NOT NULL,
   mode VARCHAR(16) DEFAULT 'ALERT' NOT NULL CHECK(mode IN ('ALERT','FINAL')),
   CONSTRAINT ossmon_alert_rules_pk PRIMARY KEY(rule_id),
   CONSTRAINT ossmon_alert_rules_uk UNIQUE(rule_name)
);

CREATE TABLE ossmon_alert_match (
   match_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   name VARCHAR(128) NOT NULL,
   operator VARCHAR(10) NOT NULL,
   value VARCHAR(255) NOT NULL,
   mode VARCHAR(16) DEFAULT 'AND' NOT NULL CHECK(mode IN ('AND','OR','AND NOT','OR NOT')),
   rule_id INTEGER NOT NULL REFERENCES ossmon_alert_rules(rule_id) ON DELETE CASCADE,
   CONSTRAINT ossmon_alert_match_pk PRIMARY KEY(match_id),
   CONSTRAINT ossmon_alert_match_un UNIQUE(name,operator,value,rule_id)
);

CREATE TABLE ossmon_alert_run (
   run_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   action_type VARCHAR(32) NOT NULL,
   template_id INTEGER NOT NULL REFERENCES ossmon_templates(template_id),
   rule_id INTEGER NOT NULL REFERENCES ossmon_alert_rules(rule_id) ON DELETE CASCADE,
   CONSTRAINT ossmon_alert_run_pk PRIMARY KEY(run_id),
   CONSTRAINT ossmon_alert_run_uk UNIQUE(action_type,template_id,rule_id)
);

CREATE TABLE ossmon_action_rules (
   rule_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   rule_name VARCHAR(128) NOT NULL,
   status VARCHAR DEFAULT 'Active' NOT NULL,
   precedence INTEGER NULL,
   description VARCHAR NULL,
   mode VARCHAR(16) DEFAULT 'BEFORE' NOT NULL CHECK(mode IN ('BEFORE','AFTER','FINAL')),
   CONSTRAINT ossmon_action_rules_pk PRIMARY KEY(rule_id),
   CONSTRAINT ossmon_action_rules_uk UNIQUE(rule_name)
);

CREATE TABLE ossmon_action_match (
   match_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   name VARCHAR(128) NOT NULL,
   operator VARCHAR(10) NOT NULL,
   value VARCHAR(255) NOT NULL,
   mode VARCHAR(16) DEFAULT 'AND' NOT NULL CHECK(mode IN ('AND','OR','AND NOT','OR NOT')),
   rule_id INTEGER NOT NULL REFERENCES ossmon_action_rules(rule_id) ON DELETE CASCADE,
   CONSTRAINT ossmon_action_match_pk PRIMARY KEY(match_id),
   CONSTRAINT ossmon_action_match_un UNIQUE(name,operator,value,rule_id)
);

CREATE TABLE ossmon_action_script (
   script_id INTEGER DEFAULT NEXTVAL('ossmon_util_seq') NOT NULL,
   value VARCHAR NOT NULL,
   rule_id INTEGER NOT NULL REFERENCES ossmon_action_rules(rule_id) ON DELETE CASCADE,
   CONSTRAINT ossmon_action_script_pk PRIMARY KEY(script_id)
);

CREATE TABLE ossmon_alerts (
   alert_id INTEGER DEFAULT NEXTVAL('ossmon_alert_seq') NOT NULL,
   device_id INTEGER NOT NULL REFERENCES ossmon_devices(device_id) ON DELETE CASCADE,
   alert_object INTEGER NULL REFERENCES ossmon_objects(obj_id) ON DELETE CASCADE,
   alert_type VARCHAR(255) NOT NULL,
   alert_name VARCHAR(255) NOT NULL,
   alert_status VARCHAR(64) DEFAULT 'Active' NOT NULL CHECK(alert_status IN ('Active','Pending','Closed')),
   alert_count INTEGER NULL,
   alert_level VARCHAR DEFAULT 'Error' NOT NULL,
   alert_time TIMESTAMP WITH TIME ZONE NULL,
   log_date TIMESTAMP WITH TIME ZONE NULL,
   log_status VARCHAR NULL,
   create_time TIMESTAMP WITH TIME ZONE NULL,
   closed_time TIMESTAMP WITH TIME ZONE NULL,
   pending_time TIMESTAMP WITH TIME ZONE NULL,
   update_time TIMESTAMP WITH TIME ZONE NULL,
   update_user INTEGER NULL,
   CONSTRAINT ossmon_alert_pk PRIMARY KEY(alert_id)
);

CREATE INDEX ossmon_alert_dev_idx ON ossmon_alerts(device_id);

CREATE TABLE ossmon_alert_log (
   log_id INTEGER DEFAULT NEXTVAL('ossmon_log_seq') NOT NULL,
   log_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   log_alert INTEGER NOT NULL,
   log_status VARCHAR NULL,
   log_data VARCHAR NOT NULL,
   log_user INTEGER NULL,
   CONSTRAINT ossmon_alert_log_pk PRIMARY KEY(log_id)
);

CREATE INDEX ossmon_alertlog_alrt_idx ON ossmon_alert_log(log_alert);
CREATE INDEX ossmon_alertlog_dt_idx ON ossmon_alert_log(log_date);

CREATE TABLE ossmon_alert_properties (
   property_id VARCHAR(64) NOT NULL,
   alert_id INTEGER NOT NULL REFERENCES ossmon_alerts(alert_id) ON DELETE CASCADE,
   value VARCHAR NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT ossmon_alert_prop_pk PRIMARY KEY(alert_id,property_id,value)
);

CREATE TABLE ossmon_iftable (
   timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   obj_id INTEGER NOT NULL,
   host VARCHAR NOT NULL,
   name VARCHAR NOT NULL,
   delta INTEGER DEFAULT 0 NOT NULL,
   utilization FLOAT DEFAULT 0 NOT NULL,
   in_rate FLOAT DEFAULT 0 NOT NULL,
   out_rate FLOAT DEFAULT 0 NOT NULL,
   in_drop FLOAT DEFAULT 0 NOT NULL,
   out_drop FLOAT DEFAULT 0 NOT NULL,
   in_err FLOAT DEFAULT 0 NOT NULL,
   out_err FLOAT DEFAULT 0 NOT NULL,
   in_trans FLOAT DEFAULT 0 NOT NULL,
   out_trans FLOAT DEFAULT 0 NOT NULL,
   in_pkt FLOAT DEFAULT 0 NOT NULL,
   out_pkt FLOAT DEFAULT 0 NOT NULL
);

CREATE INDEX ossmon_iftbl1_idx ON ossmon_iftable(obj_id,timestamp);
CREATE INDEX ossmon_iftbl2_idx ON ossmon_iftable(host,timestamp);

CREATE TABLE ossmon_ping (
   timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   obj_id INTEGER NOT NULL,
   host VARCHAR NOT NULL,
   sent SMALLINT DEFAULT 0 NOT NULL,
   received SMALLINT DEFAULT 0 NOT NULL,
   loss FLOAT DEFAULT 0 NOT NULL,
   rtt_min FLOAT DEFAULT 0 NOT NULL,
   rtt_avg FLOAT DEFAULT 0 NOT NULL,
   rtt_max FLOAT DEFAULT 0 NOT NULL
);

CREATE INDEX ossmon_ping1_idx ON ossmon_ping(timestamp,obj_id);
CREATE INDEX ossmon_ping2_idx ON ossmon_ping(timestamp,host);

CREATE TABLE ossmon_collect (
   timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   obj_id INTEGER NOT NULL,
   host VARCHAR NOT NULL,
   name VARCHAR NOT NULL,
   value FLOAT DEFAULT 0 NOT NULL,
   name2 VARCHAR NOT NULL,
   value2 FLOAT DEFAULT 0 NOT NULL
);

CREATE INDEX ossmon_collect1_idx ON ossmon_collect (timestamp,obj_id,name);
CREATE INDEX ossmon_collect2_idx ON ossmon_collect (timestamp,host,name);

CREATE TABLE ossmon_nat (
   timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   obj_id INTEGER NOT NULL,
   host VARCHAR NOT NULL,
   private_ip INET NOT NULL,
   public_ip INET NOT NULL,
   flows INTEGER DEFAULT 0 NOT NULL
);

CREATE INDEX ossmon_nat_idx ON ossmon_nat (timestamp,obj_id);
CREATE INDEX ossmon_nat2_idx ON ossmon_nat (timestamp,host,public_ip);
CREATE INDEX ossmon_nat3_idx ON ossmon_nat (timestamp,host,private_ip);
CREATE INDEX ossmon_nat4_idx ON ossmon_nat (public_ip,timestamp);
CREATE INDEX ossmon_nat5_idx ON ossmon_nat (private_ip,timestamp);

CREATE TABLE ossmon_mac (
   timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   host VARCHAR NOT NULL,
   ipaddr INET NOT NULL,
   macaddr VARCHAR NOT NULL,
   discover_count INTEGER NULL
);

CREATE INDEX ossmon_mac_idx ON ossmon_mac (timestamp,host);
CREATE INDEX ossmon_mac2_idx ON ossmon_mac (timestamp,ipaddr);
CREATE INDEX ossmon_mac4_idx ON ossmon_mac (macaddr,timestamp);

CREATE TABLE ossmon_dco (
   log_id INTEGER NOT NULL DEFAULT NEXTVAL('ossmon_dco_seq'),
   TIMESTAMP TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   name VARCHAR NOT NULL,
   collect_time TIMESTAMP WITH TIME ZONE,
   complete_time TIMESTAMP WITH TIME ZONE,
   log_severity VARCHAR NULL,
   log_type VARCHAR NULL,
   log_data VARCHAR NULL,
   olosz DOUBLE PRECISION,
   odd3s DOUBLE PRECISION,
   olous DOUBLE PRECISION,
   otous DOUBLE PRECISION,
   ollus DOUBLE PRECISION,
   oltat DOUBLE PRECISION,
   oltec DOUBLE PRECISION,
   oltnp DOUBLE PRECISION,
   ollat DOUBLE PRECISION,
   ollec DOUBLE PRECISION,
   ollnp DOUBLE PRECISION,
   ocnen DOUBLE PRECISION,
   ocnfa DOUBLE PRECISION,
   ocnfm DOUBLE PRECISION,
   ocnte DOUBLE PRECISION,
   ocnof DOUBLE PRECISION,
   gicnp60 DOUBLE PRECISION,
   gicnp61 DOUBLE PRECISION,
   gicnp62 DOUBLE PRECISION,
   gicnp63 DOUBLE PRECISION,
   gtius60 DOUBLE PRECISION,
   gtius61 DOUBLE PRECISION,
   gtius62 DOUBLE PRECISION,
   gtius63 DOUBLE PRECISION,
   gtius80 DOUBLE PRECISION,
   gtius81 DOUBLE PRECISION,
   gtius82 DOUBLE PRECISION,
   gtius83 DOUBLE PRECISION,
   gocnp70 DOUBLE PRECISION,
   gocnp80 DOUBLE PRECISION,
   gocnp71 DOUBLE PRECISION,
   gocnp81 DOUBLE PRECISION,
   gocnp72 DOUBLE PRECISION,
   gocnp82 DOUBLE PRECISION,
   gocnp73 DOUBLE PRECISION,
   gocnp83 DOUBLE PRECISION,
   gocnp38 DOUBLE PRECISION,
   gocnp79 DOUBLE PRECISION,
   gocnp37 DOUBLE PRECISION,
   gocnp103 DOUBLE PRECISION,
   gocnp104 DOUBLE PRECISION,
   gtous70 DOUBLE PRECISION,
   gtous80 DOUBLE PRECISION,
   gtous71 DOUBLE PRECISION,
   gtous81 DOUBLE PRECISION,
   gtous72 DOUBLE PRECISION,
   gtous82 DOUBLE PRECISION,
   gtous73 DOUBLE PRECISION,
   gtous83 DOUBLE PRECISION,
   gtous38 DOUBLE PRECISION,
   gtous79 DOUBLE PRECISION,
   gtous37 DOUBLE PRECISION,
   gtous103 DOUBLE PRECISION,
   gtous104 DOUBLE PRECISION
);

CREATE INDEX ossmon_dco_idx ON ossmon_dco (collect_time,name);
CREATE INDEX ossmon_dco_idx2 ON ossmon_dco (name);
CREATE INDEX ossmon_dco_idx3 ON ossmon_dco (log_type);

CREATE TABLE ossmon_dhcpd_pools (
   port VARCHAR NOT NULL,
   ipaddr1 INET NOT NULL,
   ipaddr2 INET NOT NULL,
   CONSTRAINT ossmon_dhcpd_pools_pk PRIMARY KEY(ipaddr1,ipaddr2,port)
);

CREATE INDEX ossmon_dhcpd_pools_idx ON ossmon_dhcpd_pools(port);
