/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   January 2002
*/

CREATE SEQUENCE ossweb_contact_seq START 1;
CREATE SEQUENCE ossweb_address_seq START 1;
CREATE SEQUENCE ossweb_company_seq START 1;

/*
  Type of street
*/
CREATE TABLE ossweb_street_types (
   type_id VARCHAR(32) NOT NULL CHECK(type_id != ''),
   type_name VARCHAR(64) NOT NULL,
   short_name VARCHAR NULL,
   reverse_flag BOOLEAN DEFAULT FALSE,
   nostreet_flag BOOLEAN DEFAULT FALSE,
   description TEXT NULL,
   CONSTRAINT ossweb_street_type_pk PRIMARY KEY(type_id),
   CONSTRAINT ossweb_street_type_un UNIQUE(type_name)
);
CREATE INDEX ossweb_street_type_idx ON ossweb_street_types(short_name);

/*
  Type of contact
*/
CREATE TABLE ossweb_contact_types (
   type_id VARCHAR(32) NOT NULL CHECK(type_id != ''),
   type_name VARCHAR(64) NOT NULL,
   type_format VARCHAR NULL,
   description TEXT NULL,
   CONSTRAINT ossweb_contact_type_pk PRIMARY KEY(type_id),
   CONSTRAINT ossweb_contact_type_un UNIQUE(type_name)
);

/*
  Postal states/provinces
*/
CREATE TABLE ossweb_address_states (
   state_id VARCHAR(32) NOT NULL CHECK(state_id != ''),
   state_name VARCHAR(64) NOT NULL,
   description TEXT NULL,
   precedence SMALLINT DEFAULT 0 NULL,
   CONSTRAINT ossweb_states_pk PRIMARY KEY(state_id),
   CONSTRAINT ossweb_states_un UNIQUE(state_name)
);

/*
  Countries
*/
CREATE TABLE ossweb_countries (
   country_id VARCHAR(32) NOT NULL CHECK(country_id != ''),
   country_name VARCHAR(64) NOT NULL,
   description TEXT NULL,
   CONSTRAINT ossweb_countries_pk PRIMARY KEY(country_id),
   CONSTRAINT ossweb_countries_un UNIQUE(country_name)
);

/*
  Address units: apt, floor, suite
*/
CREATE TABLE ossweb_address_units (
   unit_id VARCHAR(32) NOT NULL CHECK(unit_id != ''),
   unit_name VARCHAR(64) NOT NULL,
   description TEXT NULL,
   CONSTRAINT ossweb_addr_unit_pk PRIMARY KEY(unit_id),
   CONSTRAINT ossweb_addr_unit_un UNIQUE(unit_name)
);

/*
  Type of location
*/
CREATE TABLE ossweb_location_types (
   type_id VARCHAR(32) NOT NULL CHECK(type_id != ''),
   type_name VARCHAR(64) NOT NULL,
   description TEXT NULL,
   precedence SMALLINT DEFAULT 0 NULL,
   type_check BOOLEAN DEFAULT FALSE NOT NULL,
   name_check BOOLEAN DEFAULT FALSE NOT NULL,
   address_check BOOLEAN DEFAULT FALSE NOT NULL,
   number_check BOOLEAN DEFAULT FALSE NOT NULL,
   street_check BOOLEAN DEFAULT FALSE NOT NULL,
   city_check BOOLEAN DEFAULT FALSE NOT NULL,
   unit_check BOOLEAN DEFAULT FALSE NOT NULL,
   state_check BOOLEAN DEFAULT FALSE NOT NULL,
   zip_check BOOLEAN DEFAULT FALSE NOT NULL,
   country_check BOOLEAN DEFAULT FALSE NOT NULL,
   CONSTRAINT ossweb_location_type_pk PRIMARY KEY(type_id),
   CONSTRAINT ossweb_location_type_un UNIQUE(type_name)
);

/*
   Location
*/
CREATE TABLE ossweb_locations (
   address_id INTEGER DEFAULT NEXTVAL('ossweb_address_seq') NOT NULL,
   location_name VARCHAR NULL,
   location_type VARCHAR NOT NULL,
   number VARCHAR NULL,
   street VARCHAR NULL,
   street_type VARCHAR NULL REFERENCES ossweb_street_types(type_id),
   unit_type VARCHAR NULL REFERENCES ossweb_address_units(unit_id),
   unit VARCHAR NULL,
   city VARCHAR NULL,
   state VARCHAR NULL,
   zip_code VARCHAR NULL,
   country VARCHAR NULL REFERENCES ossweb_countries(country_id),
   address_notes VARCHAR NULL,
   longitude FLOAT NULL,
   latitude FLOAT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_user INTEGER NULL,
   CONSTRAINT ossweb_location_pk PRIMARY KEY(address_id)
);

ALTER SEQUENCE ossweb_address_seq OWNED BY ossweb_locations.address_id;

CREATE INDEX ossweb_location_type_idx ON ossweb_locations(location_type);
CREATE INDEX ossweb_location_name_idx ON ossweb_locations(location_name);
CREATE INDEX ossweb_location_number_idx ON ossweb_locations(number);
CREATE INDEX ossweb_location_street_idx ON ossweb_locations(street);

/*
  Companies
*/
CREATE TABLE ossweb_companies (
   company_id INTEGER DEFAULT NEXTVAL('ossweb_company_seq') NOT NULL,
   company_name VARCHAR(255) NOT NULL,
   company_url VARCHAR NULL,
   access_type VARCHAR DEFAULT 'Open' NOT NULL,
   description VARCHAR NULL,
   create_user INTEGER DEFAULT 0 NOT NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NULL,
   CONSTRAINT ossweb_company_pk PRIMARY KEY(company_id),
   CONSTRAINT ossweb_company_un UNIQUE(company_name)
);

ALTER SEQUENCE ossweb_company_seq OWNED BY ossweb_companies.company_id;

/*
  Company addresses
*/
CREATE TABLE ossweb_company_addresses (
   company_id INTEGER NOT NULL REFERENCES ossweb_companies(company_id) ON DELETE CASCADE,
   address_id INTEGER NOT NULL REFERENCES ossweb_locations(address_id),
   description VARCHAR NULL,
   CONSTRAINT ossweb_company_address_pk PRIMARY KEY(company_id,address_id)
);

/*
   Company properties
*/
CREATE TABLE ossweb_company_entries (
   entry_id INTEGER DEFAULT NEXTVAL('ossweb_contact_seq') NOT NULL,
   company_id INTEGER NOT NULL REFERENCES ossweb_companies(company_id) ON DELETE CASCADE,
   entry_name VARCHAR NOT NULL,
   entry_value VARCHAR NULL,
   entry_date TIMESTAMP WITH TIME ZONE NULL,
   entry_file VARCHAR NULL,
   entry_notify VARCHAR NULL,
   update_user INTEGER NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   notify_date TIMESTAMP WITH TIME ZONE NULL,
   CONSTRAINT ossweb_company_entries_pk PRIMARY KEY(entry_id)
);

CREATE INDEX ossweb_company_entries_idx ON ossweb_company_entries(company_id,entry_name);

/*
   Contact people
*/
CREATE TABLE ossweb_people (
   people_id INTEGER DEFAULT NEXTVAL('ossweb_contact_seq') NOT NULL,
   access_type VARCHAR DEFAULT 'Open' NOT NULL,
   first_name VARCHAR NOT NULL,
   middle_name VARCHAR NULL,
   last_name VARCHAR NULL,
   salutation VARCHAR NULL,
   suffix VARCHAR NULL,
   birthday DATE NULL,
   description VARCHAR NULL,
   company_id INTEGER NULL REFERENCES ossweb_companies(company_id),
   create_user INTEGER NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NULL,
   notify_date TIMESTAMP WITH TIME ZONE NULL,
   CONSTRAINT people_pk PRIMARY KEY(people_id)
);

ALTER SEQUENCE ossweb_contact_seq OWNED BY ossweb_people.people_id;

/*
  People addresses
*/
CREATE TABLE ossweb_people_addresses (
   people_id INTEGER NOT NULL REFERENCES ossweb_people(people_id) ON DELETE CASCADE,
   address_id INTEGER NOT NULL REFERENCES ossweb_locations(address_id),
   description VARCHAR NULL,
   create_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT ossweb_people_addres_pk PRIMARY KEY(people_id,address_id)
);

/*
   People properties
*/
CREATE TABLE ossweb_people_entries (
   entry_id INTEGER DEFAULT NEXTVAL('ossweb_contact_seq') NOT NULL,
   people_id INTEGER NOT NULL REFERENCES ossweb_people(people_id) ON DELETE CASCADE,
   entry_name VARCHAR NOT NULL,
   entry_value VARCHAR NULL,
   entry_date TIMESTAMP WITH TIME ZONE NULL,
   entry_file VARCHAR NULL,
   entry_notify VARCHAR NULL,
   update_user INTEGER DEFAULT 0 NOT NULL,
   update_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   notify_date TIMESTAMP WITH TIME ZONE NULL,
   CONSTRAINT ossweb_people_entries_pk PRIMARY KEY(entry_id)
);

CREATE INDEX ossweb_people_entries_idx ON ossweb_people_entries(people_id,entry_name);

