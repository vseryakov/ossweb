<?xml version="1.0"?>

<xql>

<query name="ossweb.location.type.list.select">
  <description>
    Read address units for select box
  </description>
  <sql>
    SELECT type_name,type_id FROM ossweb_location_types ORDER BY precedence
  </sql>
</query>

<query name="oswweb.location.list.js">
  <description>
  </description>
  <sql>
    SELECT ossweb_location_name([ossweb::sql::quote $address_id int],'jsarray')
  </sql>
</query>

<query name="ossweb.location.list.street">
  <description>
  </description>
  <sql>
    SELECT DISTINCT(street||COALESCE(' '||street_type)) AS street FROM ossweb_locations WHERE street ILIKE '$street%' LIMIT 25
  </sql>
</query>

<query name="ossweb.location.list.city">
  <description>
  </description>
  <sql>
    SELECT DISTINCT city FROM ossweb_locations WHERE city ILIKE '$city%' LIMIT 25
  </sql>
</query>

<query name="ossweb.location.list.name">
  <description>
  </description>
  <sql>
    SELECT location_name||
           COALESCE('-'||street,'')||
           COALESCE('-'||unit_type,'')||
           COALESCE(unit,'')||
           COALESCE('-'||city,'')||
           COALESCE('-'||country,'') AS address_name,
           address_id,
           location_name
    FROM ossweb_locations
    WHERE location_name ILIKE '$location_name%'
    LIMIT 25
  </sql>
</query>

<query name="ossweb.location.search">
  <description>
   First part of address search
  </description>
  <sql>
    SELECT location_name,
           address_id
    FROM ossweb_locations
         [ossweb::sql::filter \
               { number Text ""
                 street Text ""
                 street_type "" ""
                 unit_type "" ""
                 unit Text ""
                 city Text ""
                 state "" ""
                 zip_code "" ""
                 country "" ""
                 location_type list ""
                 location_name Text ""
                 address_notes Text "" } \
               -where WHERE]
    ORDER BY 1
  </sql>
</query>

<query name="ossweb.location.search1">
  <description>
   First part of address search
  </description>
  <sql>
    SELECT address_id
    FROM ossweb_locations
         [ossweb::sql::filter \
               { number Text ""
                 street Text ""
                 street_type "" ""
                 unit_type "" ""
                 unit Text ""
                 city Text ""
                 state "" ""
                 zip_code "" ""
                 country "" ""
                 location_type list ""
                 location_name Text ""
                 longitude float ""
                 latitude float ""
                 long_start float ""
                 lat_start float ""
                 long_end float ""
                 lat_end float ""
                 address_notes Text "" } \
               -map {
                      long_start "longitude >= %value"
                      long_end "longitude <= %value"
                      lat_start "latitude >= %value"
                      lat_end "latitude <= %value"
                    } \
               -where WHERE]
    ORDER BY state,city,street,number
  </sql>
</query>

<query name="ossweb.location.search2">
  <description>
    Second part of address search
  </description>
  <sql>
    SELECT address_id,
           number,
           street,
           street_type,
           unit_type,
           unit,
           city,
           state,
           zip_code,
           country,
           country_name,
           unit_name,
           location_type,
           location_name,
           address_notes,
           longitude,
           latitude
    FROM ossweb_locations a
         LEFT OUTER JOIN ossweb_address_units u
           ON unit_type=unit_id
         LEFT OUTER JOIN ossweb_countries c
           ON a.country=c.country_id
    WHERE address_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="ossweb.location.search.match">
  <description>
    Match similar addresses
  </description>
  <sql>
    SELECT number||' '||street||' '||COALESCE(unit_name,'')||' '||COALESCE(unit,'')||' '||city||' '||state::TEXT||' '||zip_code AS address,
           address_id
    FROM ossweb_locations
         LEFT OUTER JOIN ossweb_address_units u
           ON unit_type=unit_id
    WHERE location_type='Address' AND
          SOUNDEX(number) = SOUNDEX([ossweb::sql::quote $number string]) AND
          SOUNDEX(street) = SOUNDEX([ossweb::sql::quote $street string]) AND
          COALESCE(unit_type,'') = [ossweb::sql::quote $unit_type string] AND
          SOUNDEX(COALESCE(unit,'')) = SOUNDEX([ossweb::sql::quote $unit string]) AND
          SOUNDEX(city) = SOUNDEX([ossweb::sql::quote $city string]) AND
          SOUNDEX(state) = SOUNDEX([ossweb::sql::quote $state string]) AND
          SOUNDEX(zip_code) = SOUNDEX([ossweb::sql::quote $zip_code string])
    ORDER BY 1
  </sql>
</query>

<query name="ossweb.location.read">
  <description>
    Record address record
  </description>
  <sql>
    SELECT location_type,
           location_name,
           number,
           street,
           street_type,
           unit_type,
           unit,
           city,
           state,
           zip_code,
           country,
           unit_name,
           country_name,
           address_notes,
           longitude,
           latitude,
           update_user,
           ossweb_user_name(update_user) AS update_user_name,
           TO_CHAR(create_date,'YYYY-MM-DD HH24:MI') AS create_date,
           TO_CHAR(update_date,'YYYY-MM-DD HH24:MI') AS update_date
    FROM ossweb_locations a
         LEFT OUTER JOIN ossweb_address_units u
           ON unit_type=unit_id
         LEFT OUTER JOIN ossweb_countries c
           ON a.country=c.country_id
    WHERE address_id=$address_id
  </sql>
</query>

<query name="ossweb.location.update">
  <description>
    Create new address record
  </description>
  <sql>
    SELECT ossweb_location_update(
    [ossweb::sql::insert_values -skip_null f \
          { address_id int ""
            location_type "" ""
            location_name "" ""
            number "" ""
            street "" ""
            street_type "" ""
            unit_type "" ""
            unit "" ""
            city "" ""
            state "" ""
            zip_code "" ""
            country "" "" }])
  </sql>
</query>

<query name="ossweb.location.update.params">
  <description>
    Update address record
  </description>
  <sql>
    UPDATE ossweb_locations
    SET [ossweb::sql::update_values -skip_null [ossweb::coalesce skip_null t] \
              { address_id int ""
                address_notes "" ""
                longitude float ""
                latitude float ""
                update_user const {[ossweb::conn user_id 0]}
                update_date "" NOW() }]
    WHERE address_id=$address_id
  </sql>
</query>

<query name="ossweb.location.delete">
  <description>
    Delete address record
  </description>
  <sql>
    DELETE FROM ossweb_locations WHERE address_id=$address_id
  </sql>
</query>

<query name="ossweb.address.country.list.select">
  <description>
    Read countries for select box
  </description>
  <sql>
    SELECT country_name,country_id FROM ossweb_countries ORDER BY 1
  </sql>
</query>

<query name="ossweb.address.state.list.select">
  <description>
    Read US states for select box
  </description>
  <sql>
    SELECT state_name,state_id FROM ossweb_address_states ORDER BY precedence,state_name
  </sql>
</query>

<query name="ossweb.address.unit.list.select">
  <description>
    Read address units for select box
  </description>
  <sql>
    SELECT unit_name,unit_id FROM ossweb_address_units ORDER BY 1
  </sql>
</query>

<query name="ossweb.address.street.type.create">
  <description>
    Create new street type record
  </description>
  <sql>
    INSERT INTO ossweb_street_types
    [ossweb::sql::insert_values -full t \
          { type_id "" ""
            type_name "" ""
            description "" "" } ]
  </sql>
</query>

<query name="ossweb.address.street.type.search">
  <description>
    Read street types for select box
  </description>
  <sql>
    SELECT type_id FROM ossweb_street_types
    WHERE type_id ILIKE '$street_type' OR
          short_name ILIKE '$street_type'
  </sql>
</query>

<query name="ossweb.address.street.type.list.select">
  <description>
    Read street types for select box
  </description>
  <sql>
    SELECT type_name,type_id FROM ossweb_street_types ORDER BY 1
  </sql>
</query>

<query name="ossweb.address.unit.list.select">
  <description>
    Read address units for select box
  </description>
  <sql>
    SELECT unit_name,unit_id FROM ossweb_address_units WHERE unit_id <> '' ORDER BY 1
  </sql>
</query>

<query name="ossweb.contact.type.create">
  <description>
    Create new contact type record
  </description>
  <sql>
    INSERT INTO ossweb_contact_types
    [ossweb::sql::insert_values -full t \
          { type_id "" ""
            type_name "" ""
            type_format "" ""
            description "" "" } ]
  </sql>
</query>

<query name="ossweb.contact.type.update">
  <description>
    Update contact type record
  </description>
  <sql>
    UPDATE ossweb_contact_types
    SET [ossweb::sql::update_values \
              { type_id "" ""
                type_name "" ""
                type_format "" ""
                description "" "" } ]
    WHERE type_id='$type_id'
  </sql>
</query>

<query name="ossweb.contact.type.delete">
  <description>
    Delete contact type record
  </description>
  <sql>
    DELETE FROM ossweb_contact_types WHERE type_id='$type_id'
  </sql>
</query>

<query name="ossweb.contact.type.read">
  <description>
    Read contact types for select box
  </description>
  <sql>
    SELECT type_id,type_name,type_format,description
    FROM ossweb_contact_types
    WHERE type_id='$type_id'
  </sql>
</query>

<query name="ossweb.contact.type.list">
  <description>
    Read contact types for select box
  </description>
  <sql>
    SELECT type_name,type_id,type_format,description
    FROM ossweb_contact_types
    ORDER BY 1
  </sql>
</query>

<query name="ossweb.contact.type.list.select">
  <description>
    Read contact types for select box
  </description>
  <sql>
    SELECT type_name,type_id FROM ossweb_contact_types ORDER BY 1
  </sql>
</query>

<query name="people.read">
  <description>
    Read people record
  </description>
  <sql>
    SELECT people_id,
           access_type,
           first_name,
           last_name,
           middle_name,
           salutation,
           suffix,
           birthday,
           description,
           company_id,
           CASE WHEN p.company_id IS NOT NULL
                THEN (SELECT company_name FROM ossweb_companies c WHERE p.company_id=c.company_id)
                ELSE NULL
           END AS company_name
    FROM ossweb_people p
    WHERE people_id=$people_id
  </sql>
</query>

<query name="people.create">
  <description>
    Create people record
  </description>
  <sql>
    INSERT INTO ossweb_people
    [ossweb::sql::insert_values -full t -skip_null t \
          { access_type "" ""
            people_id int ""
            first_name "" ""
            last_name "" ""
            middle_name "" ""
            salutation "" ""
            suffix "" ""
            birthday date ""
            description "" ""
            company_id int ""
            create_user const {[ossweb::conn user_id -1]} }]
  </sql>
</query>

<query name="people.update">
  <description>
    Update people record
  </description>
  <sql>
    UPDATE ossweb_people
    SET [ossweb::sql::update_values \
              { access_type "" ""
                first_name "" ""
                last_name "" ""
                middle_name "" ""
                salutation "" ""
                suffix "" ""
                birthday date ""
                description "" ""
                company_id int "" }]
    WHERE people_id=$people_id
  </sql>
</query>

<query name="people.update.notify">
  <description>
    Update people entry record
  </description>
  <sql>
    UPDATE ossweb_people SET notify_date=NOW() WHERE people_id=$people_id
  </sql>
</query>

<query name="people.delete">
  <description>
    Delete people record
  </description>
  <sql>
    DELETE FROM ossweb_people WHERE people_id=$people_id
  </sql>
</query>

<query name="people.access">
  <description>
    Returns 1 if user has access to people record
  </description>
  <sql>
    SELECT 1 FROM ossweb_people p
    WHERE people_id=$people_id AND
          (create_user=[ossweb::conn user_id -1] OR
           access_type IN ('Public') OR
           (access_type IN ('Open') AND [ossweb::conn user_id -1] <> -1) OR
           (access_type IN ('Group') AND
            EXISTS(SELECT 1
                   FROM ossweb_user_groups g1,
                        ossweb_user_groups g2
                   WHERE g1.group_id=g2.group_id AND
                         g1.user_id=[ossweb::conn user_id -1] AND
                         g2.user_id=create_user)))
  </sql>
</query>

<query name="people.access.update">
  <description>
    Returns 1 if user has access to people record
  </description>
  <sql>
    SELECT 1 FROM ossweb_people
    WHERE people_id=$people_id AND
          (create_user=[ossweb::conn user_id -1] OR
           access_type IN ('Public') OR
           (access_type IN ('Open') AND [ossweb::conn user_id -1] <> -1) OR
           (access_type IN ('Group') AND
            EXISTS(SELECT 1
                   FROM ossweb_user_groups g1,
                        ossweb_user_groups g2
                   WHERE g1.group_id=g2.group_id AND
                         g1.user_id=[ossweb::conn user_id -1] AND
                         g2.user_id=create_user)))
  </sql>
</query>

<query name="people.search1">
  <description>
   First part of people search
  </description>
  <sql>
    SELECT people_id
    FROM ossweb_people p
    WHERE (create_user=[ossweb::conn user_id -1] OR
           access_type IN ('Public') OR
           (access_type IN ('Open') AND [ossweb::conn user_id -1] <> -1) OR
           (access_type IN ('Group') AND
            EXISTS(SELECT 1
                   FROM ossweb_user_groups g1,
                        ossweb_user_groups g2
                   WHERE g1.group_id=g2.group_id AND
                         g1.user_id=[ossweb::conn user_id -1] AND
                         g2.user_id=create_user)))
    [ossweb::sql::filter \
          { people_id ilist ""
            first_name text ""
            middle_name text ""
            last_name text ""
            birth_day int ""
            birth_month int ""
            birth_year int ""
            company_name Text ""
            entry_name Text "" } \
          -alias "p." \
          -before AND \
          -map { company_name "EXISTS(SELECT 1 FROM ossweb_companies c
                                      WHERE c.company_id=p.company_id AND
                                            c.company_name ILIKE %value)"
                 entry_name "EXISTS(SELECT 1 FROM ossweb_people_entries e
                                    WHERE e.people_id=p.people_id AND
                                          (entry_name ILIKE %value OR
                                           entry_value ILIKE %value))"
                 birth_day "EXTRACT(day FROM birthday) = %value"
                 birth_month "EXTRACT(month FROM birthday) = %value"
                 birth_year "EXTRACT(year FROM birthday) = %value" } \
          -filter \
          [ossweb::sql::filter \
                { number "" ""
                  street text ""
                  unit_type "" ""
                  unit "" ""
                  city text ""
                  state "" ""
                  zip_code "" ""
                  country "" "" } \
               -before AND \
               -alias "pa." \
               -embed "EXISTS(SELECT people_id
                              FROM ossweb_people_addresses ca,
                                   ossweb_locations pa
                              WHERE p.people_id=ca.people_id AND
                                    pa.address_id=ca.address_id AND
                                    %sql)"]]
    ORDER BY first_name,last_name
  </sql>
</query>

<query name="people.search2">
  <description>
    Second part of people search
  </description>
  <sql>
    SELECT people_id,
           first_name,
           last_name,
           middle_name,
           salutation,
           suffix,
           TO_CHAR(birthday,'Mon DD YYYY') AS birthday,
           p.company_id,
           SUBSTRING(description,1,40) AS description,
           CASE WHEN p.company_id IS NOT NULL
                THEN (SELECT company_name FROM ossweb_companies c WHERE p.company_id=c.company_id)
                ELSE NULL
           END AS company_name,
           (SELECT entry_value FROM ossweb_people_entries e
            WHERE e.people_id=p.people_id AND
                  entry_name ILIKE '%Email%' AND
                  entry_value IS NOT NULL
            LIMIT 1) AS email,
           (SELECT entry_value FROM ossweb_people_entries e
            WHERE e.people_id=p.people_id AND
                  entry_name ILIKE '%Phone%' AND
                  entry_value IS NOT NULL
            LIMIT 1) AS phone
    FROM ossweb_people p
    WHERE people_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="people.export">
  <description>
    Export people records
  </description>
  <sql>
    SELECT people_id AS id,
           ROUND(EXTRACT(EPOCH FROM update_date)) AS timestamp,
           first_name,
           last_name,
           (SELECT ossweb_location_name(a.address_id,'tclarray')
            FROM ossweb_people_addresses a
            WHERE a.people_id=p.people_id
            ORDER BY create_date
            LIMIT 1) AS address,
           CASE WHEN company_id IS NOT NULL
                THEN (SELECT company_name FROM ossweb_companies c WHERE p.company_id=c.company_id)
                ELSE NULL
           END AS company,
           TO_CHAR(birthday,'Mon DD YYYY') AS birthday,
           description AS notes,
           ossweb_people_entries(people_id) AS entries
    FROM ossweb_people p
  </sql>
</query>

<query name="people.search.birthday">
  <description>
  </description>
  <sql>
    SELECT p.people_id,
           p.first_name,
           p.last_name,
           TO_CHAR(p.birthday,'Month DD') AS birthday,
           (SELECT entry_Value FROM ossweb_people_entries e WHERE p.people_id=e.people_id AND entry_name ILIKE '%PHone' LIMIT 1) AS phone,
           u.user_email
    FROM ossweb_people p,
         ossweb_users u
    WHERE p.create_user=u.user_id AND
          (TO_CHAR(p.birthday,'2000-MM-DD')::DATE=TO_CHAR(NOW(),'2000-MM-DD')::DATE OR
           TO_CHAR(p.birthday,'2000-MM-DD')::DATE=TO_CHAR(NOW()+'1 week'::INTERVAL,'2000-MM-DD')::DATE)
	  [ossweb::sql::filter \
	        { notify_flag int "" } \
		-before AND \
		-map { notify_flag "COALESCE(p.notify_date,'2000-1-1')::DATE<>NOW()::DATE" }]
    ORDER BY 1
  </sql>
</query>

<query name="people.search.notify">
  <description>
  </description>
  <sql>
    SELECT u.user_email,
           p.first_name,
           p.last_name,
           e.entry_id,
           e.entry_notify,
           e.entry_name,
           e.entry_value,
           TO_CHAR(e.entry_date,'Mon DD YYYY') AS entry_date
    FROM ossweb_people p,
         ossweb_people_entries e,
         ossweb_users u
    WHERE p.create_user=u.user_id AND
          p.people_id=e.people_id AND
          COALESCE(e.notify_date,'2000-1-1')::DATE<>NOW()::DATE AND
          EXTRACT(hour FROM entry_date)<=EXTRACT(hour FROM NOW()) AND
          EXTRACT(minute FROM entry_date)<=EXTRACT(minute FROM NOW()) AND
          ((entry_notify='Once' AND e.notify_date IS NULL) OR
           (entry_notify='Daily') OR
           (entry_notify='Weekly' AND EXTRACT(dow FROM entry_date)=EXTRACT(dow FROM NOW())) OR
           (entry_notify='Monthly' AND EXTRACT(day FROM entry_date)=EXTRACT(day FROM NOW())) OR
           (entry_notify='Yearly' AND TO_CHAR(entry_date,'MM-DD')=TO_CHAR(NOW(),'MM-DD')))
    ORDER BY 1
  </sql>
</query>

<query name="people.select.list">
  <description>
  </description>
  <sql>
    SELECT first_name||' '||last_name,
           people_id
    FROM ossweb_people
    [ossweb::sql::filter \
          "people_id ilist {[ossweb::conn contact_people]}" \
          -where WHERE]
    ORDER BY 1
  </sql>
</query>

<query name="people.address.list">
  <description>
    Read all people addresses
  </description>
  <sql>
    SELECT a.address_id,
           number,
           street,
           street_type,
           unit_name||' '||unit AS unit,
           city,
           state,
           zip_code,
           country,
           country_name,
           location_name AS description
    FROM ossweb_people_addresses a,
         ossweb_locations pa
         LEFT OUTER JOIN ossweb_address_units u ON unit_type=unit_id
         LEFT OUTER JOIN ossweb_countries c ON country=country_id
    WHERE a.people_id=$people_id AND
          a.address_id=pa.address_id
  </sql>
</query>

<query name="people.address.read">
  <description>
    Read people address record
  </description>
  <sql>
    SELECT a.address_id,
           number,
           street,
           street_type,
           unit_type,
           unit,
           city,
           state,
           zip_code,
           country,
           location_name AS description
    FROM ossweb_people_addresses a,
         ossweb_locations pa
    WHERE a.address_id=pa.address_id AND
          a.people_id=$people_id AND
          a.address_id=$address_id
  </sql>
</query>

<query name="people.address.create">
  <description>
    Create address record for people
  </description>
  <sql>
    INSERT INTO ossweb_people_addresses
    [ossweb::sql::insert_values -full t \
          { people_id int ""
            address_id int ""
            description "" "" }]
  </sql>
</query>

<query name="people.address.update">
  <description>
    Update address record for people
  </description>
  <sql>
    UPDATE ossweb_people_addresses
    SET description=[ossweb::sql::quote $description]
    WHERE people_id=$people_id AND
          address_id=$address_id
  </sql>
</query>

<query name="people.address.delete">
  <description>
    Delete people address record
  </description>
  <sql>
    DELETE FROM ossweb_people_addresses WHERE people_id=$people_id AND address_id=$address_id
  </sql>
</query>

<query name="people.entry.list">
  <description>
    Read all people properties
  </description>
  <sql>
    SELECT entry_id,
           entry_name,
           entry_value,
           entry_file,
           entry_notify,
           TO_CHAR(entry_date,'Mon DD YYYY HH24:MI') AS entry_date,
           (SELECT user_name FROM ossweb_users WHERE user_id=update_user) AS update_user_name,
           TO_CHAR(update_date,'MM/DD/YY HH24:MI') AS update_date
    FROM ossweb_people_entries
    WHERE people_id=$people_id
          [ossweb::sql::filter \
                { entry_filter Text "" } \
                -map { entry_filter "(entry_name ILIKE %value OR entry_value ILIKE %value)" } \
                -before AND]
    ORDER BY [ossweb::coalesce entry_sort update_date]
  </sql>
</query>

<query name="people.entry.read">
  <description>
    Read all people properties
  </description>
  <sql>
    SELECT entry_id,
           entry_name,
           entry_value,
           entry_file,
           entry_date,
           entry_notify,
           TO_CHAR(notify_date,'MM/DD/YY HH24:MI') AS notify_date
    FROM ossweb_people_entries
    WHERE entry_id=$entry_id
  </sql>
</query>

<query name="people.entry.update">
  <description>
    Update people entry record
  </description>
  <sql>
    UPDATE ossweb_people_entries
    SET [ossweb::sql::update_values \
              { entry_name "" ""
                entry_value "" ""
                entry_file "" ""
                entry_notify "" ""
                entry_date datetime ""
                update_date Const NOW()
                update_user Const {[ossweb::conn user_id -1]} }]
    WHERE entry_id=$entry_id
  </sql>
</query>

<query name="people.entry.update.notify">
  <description>
    Update people entry record
  </description>
  <sql>
    UPDATE ossweb_people_entries SET notify_date=NOW() WHERE entry_id=$entry_id
  </sql>
</query>

<query name="people.entry.create">
  <description>
    Create entry record for people
  </description>
  <sql>
    INSERT INTO ossweb_people_entries
    [ossweb::sql::insert_values -full t \
          { people_id int ""
            entry_name "" ""
            entry_value "" ""
            entry_file "" ""
            entry_notify "" ""
            entry_date datetime ""
            update_user Const {[ossweb::conn user_id -1]} }]
  </sql>
</query>

<query name="people.entry.delete">
  <description>
    Delete people entry record
  </description>
  <sql>
    DELETE FROM ossweb_people_entries WHERE entry_id=$entry_id
  </sql>
</query>

<query name="company.read">
  <description>
    Read people record
  </description>
  <sql>
    SELECT company_id,
           access_type,
           company_name,
           company_url,
           description
    FROM ossweb_companies p
    WHERE company_id=$company_id
  </sql>
</query>

<query name="company.read.name">
  <description>
    Read people record
  </description>
  <sql>
    SELECT company_id FROM ossweb_companies p WHERE company_name=[ossweb::sql::quote $company_name]
  </sql>
</query>

<query name="company.create">
  <description>
    Create people record
  </description>
  <sql>
    INSERT INTO ossweb_companies
    [ossweb::sql::insert_values -full t -skip_null t \
          { access_type "" ""
            company_id int ""
            company_name "" ""
            company_url "" ""
            description "" ""
            create_user const {[ossweb::conn user_id -1]} }]
  </sql>
</query>

<query name="company.create.name">
  <description>
  </description>
  <sql>
    SELECT ossweb_company_create([ossweb::sql::quote $company_name])
  </sql>
</query>

<query name="company.update">
  <description>
    Update people record
  </description>
  <sql>
    UPDATE ossweb_companies
    SET [ossweb::sql::update_values \
              { access_type "" ""
                company_name "" ""
                company_url "" ""
                description "" "" }]
    WHERE company_id=$company_id
  </sql>
</query>

<query name="company.delete">
  <description>
    Delete people record
  </description>
  <sql>
    DELETE FROM ossweb_companies WHERE company_id=$company_id
  </sql>
</query>

<query name="company.list.select">
  <description>
  </description>
  <sql>
    SELECT company_name,company_id
    FROM ossweb_companies
    WHERE access_type IN ('Public','Open')
    ORDER BY 1
  </sql>
</query>

<query name="company.access">
  <description>
    Returns 1 if user has access to company record
  </description>
  <sql>
    SELECT 1 FROM ossweb_companies
    WHERE company_id=$company_id AND
          (create_user=[ossweb::conn user_id -1] OR
           access_type IN ('Public') OR
           (access_type IN ('Open') AND [ossweb::conn user_id -1] <> -1) OR
           (access_type IN ('Group') AND
            EXISTS(SELECT 1
                   FROM ossweb_user_groups g1,
                        ossweb_user_groups g2
                   WHERE g1.group_id=g2.group_id AND
                         g1.user_id=[ossweb::conn user_id -1] AND
                         g2.user_id=create_user)))
  </sql>
</query>

<query name="company.access.update">
  <description>
    Returns 1 if user has access to company record
  </description>
  <sql>
    SELECT 1 FROM ossweb_companies
    WHERE company_id=$company_id AND
          (create_user=[ossweb::conn user_id -1] OR
           access_type IN ('Public') OR
           (access_type IN ('Open') AND [ossweb::conn user_id -1] <> -1) OR
           (access_type IN ('Group') AND
            EXISTS(SELECT 1
                   FROM ossweb_user_groups g1,
                        ossweb_user_groups g2
                   WHERE g1.group_id=g2.group_id AND
                         g1.user_id=[ossweb::conn user_id -1] AND
                         g2.user_id=create_user)))
  </sql>
</query>

<query name="company.search1">
  <description>
   First part of people search
  </description>
  <sql>
    SELECT company_id,
           company_name
    FROM ossweb_companies p
    WHERE (create_user=[ossweb::conn user_id -1] OR
           access_type IN ('Public') OR
           (access_type IN ('Open') AND [ossweb::conn user_id -1] <> -1) OR
           (access_type IN ('Group') AND
            EXISTS(SELECT 1
                   FROM ossweb_user_groups g1,
                        ossweb_user_groups g2
                   WHERE g1.group_id=g2.group_id AND
                         g1.user_id=[ossweb::conn user_id -1] AND
                         g2.user_id=create_user)))
    [ossweb::sql::filter \
          { company_id ilist ""
            company_name Text ""
            description Text ""
            entry_name Text "" } \
          -alias "p." \
          -before AND \
          -map { entry_name "EXISTS(SELECT 1 FROM ossweb_company_entries e
                                    WHERE e.company_id=p.company_id AND
                                          (entry_name ILIKE %value OR
                                           entry_value ILIKE %value))" } \
          -filter \
          [ossweb::sql::filter \
                { number "" ""
                  street text ""
                  unit_type "" ""
                  unit "" ""
                  city text ""
                  state "" ""
                  zip_code "" ""
                  country "" "" } \
               -before AND \
               -alias "pa." \
               -embed "EXISTS(SELECT company_id
                              FROM ossweb_company_addresses ca,
                                   ossweb_locations pa
                              WHERE p.company_id=ca.company_id AND
                                    pa.address_id=ca.address_id AND
                                    %sql)"]]
    ORDER BY company_name
    LIMIT [ossweb::coalesce company_limit 9999]
  </sql>
</query>

<query name="company.search2">
  <description>
    Second part of people search
  </description>
  <sql>
    SELECT company_id,
           company_name,
           company_url,
           description
    FROM ossweb_companies p
    WHERE company_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="company.select.list">
  <description>
  </description>
  <sql>
    SELECT company_name,
           company_id
    FROM ossweb_companies
    [ossweb::sql::filter \
          "company_id ilist {[ossweb::conn contact_companies]}" \
          -where WHERE]
    ORDER BY 1
  </sql>
</query>

<query name="company.address.list">
  <description>
    Read all people addresses
  </description>
  <sql>
    SELECT a.address_id,
           number,
           street,
           street_type,
           unit_name||' '||unit AS unit,
           city,
           state,
           zip_code,
           country,
           country_name,
           a.description
    FROM ossweb_company_addresses a,
         ossweb_locations pa
         LEFT OUTER JOIN ossweb_address_units u ON unit_type=unit_id
         LEFT OUTER JOIN ossweb_countries c ON country=country_id
    WHERE a.company_id=$company_id AND
          a.address_id=pa.address_id
  </sql>
</query>

<query name="company.address.read">
  <description>
    Read people address record
  </description>
  <sql>
    SELECT a.address_id,
           number,
           street,
           street_type,
           unit_type,
           unit,
           city,
           state,
           zip_code,
           country,
           a.description
    FROM ossweb_company_addresses a,
         ossweb_locations pa
    WHERE a.address_id=pa.address_id AND
          a.company_id=$company_id AND
          a.address_id=$address_id
  </sql>
</query>

<query name="company.address.create">
  <description>
    Create address record for people
  </description>
  <sql>
    INSERT INTO ossweb_company_addresses
    [ossweb::sql::insert_values -full t \
          { company_id int ""
            address_id int ""
            description "" "" }]
  </sql>
</query>

<query name="company.address.update">
  <description>
    Update address record for people
  </description>
  <sql>
    UPDATE ossweb_company_addresses
    SET description=[ossweb::sql::quote $description]
    WHERE company_id=$company_id AND
          address_id=$address_id
  </sql>
</query>

<query name="company.address.delete">
  <description>
    Delete people address record
  </description>
  <sql>
    DELETE FROM ossweb_company_addresses WHERE company_id=$company_id AND address_id=$address_id
  </sql>
</query>

<query name="company.entry.list">
  <description>
    Read all people properties
  </description>
  <sql>
    SELECT entry_id,
           entry_name,
           entry_value,
           entry_file,
           entry_notify,
           TO_CHAR(entry_date,'Mon DD YYYY HH24:MI') AS entry_date,
           (SELECT user_name FROM ossweb_users WHERE user_id=update_user) AS update_user_name,
           TO_CHAR(update_date,'MM/DD/YY HH24:MI') AS update_date
    FROM ossweb_company_entries
    WHERE company_id=$company_id
          [ossweb::sql::filter \
                { entry_filter Text "" } \
                -map { entry_filter "(entry_name ILIKE %value OR entry_value ILIKE %value)" } \
                -before AND]
    ORDER BY [ossweb::coalesce entry_sort update_date]
  </sql>
</query>

<query name="company.entry.read">
  <description>
    Read all people properties
  </description>
  <sql>
    SELECT entry_id,
           entry_name,
           entry_value,
           entry_file,
           entry_date,
           entry_notify
    FROM ossweb_company_entries
    WHERE entry_id=$entry_id
  </sql>
</query>

<query name="company.entry.update">
  <description>
    Update people entry record
  </description>
  <sql>
    UPDATE ossweb_company_entries
    SET [ossweb::sql::update_values \
              { entry_name "" ""
                entry_value "" ""
                entry_file "" ""
                entry_notify "" ""
                entry_date datetime ""
                update_date Const NOW()
                update_user Const {[ossweb::conn user_id -1]} }]
    WHERE entry_id=$entry_id
  </sql>
</query>

<query name="company.entry.create">
  <description>
    Create entry record for people
  </description>
  <sql>
    INSERT INTO ossweb_company_entries
    [ossweb::sql::insert_values -full t \
          { company_id int ""
            entry_name "" ""
            entry_value "" ""
            entry_file "" ""
            entry_notify "" ""
            entry_date datetime ""
            update_user Const {[ossweb::conn user_id -1]} }]
  </sql>
</query>

<query name="company.entry.delete">
  <description>
    Delete people entry record
  </description>
  <sql>
    DELETE FROM ossweb_company_entries WHERE entry_id=$entry_id
  </sql>
</query>

</xql>
