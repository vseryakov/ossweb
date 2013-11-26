/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   May 2002
*/

/*
  Returns company name
*/
CREATE OR REPLACE FUNCTION ossweb_company_name(INTEGER) RETURNS VARCHAR AS '
DECLARE
   _company_id ALIAS FOR $1;
BEGIN
   RETURN (SELECT company_name FROM ossweb_companies WHERE company_id=_company_id);
END;' LANGUAGE 'plpgsql' STRICT;

/*
   Company contacts
 */
CREATE OR REPLACE FUNCTION ossweb_company_entries(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT entry_name,
                     entry_value,
                     TO_CHAR(entry_date,''MM/DD/YYYY'') AS entry_date
              FROM ossweb_company_entries
              WHERE company_id=$1 AND
                    (entry_value IS NOT NULL OR entry_date IS NOT NULL)
              ORDER BY update_date LOOP
     result := result||''{''||rec.entry_name||''} {''||COALESCE(rec.entry_value,rec.entry_date)||''} '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;

/*
   Create new company or return existing company id
*/
CREATE OR REPLACE FUNCTION ossweb_company_create(VARCHAR) RETURNS INTEGER AS '
DECLARE
   _company_name ALIAS FOR $1;
   rec RECORD;
   _company_id INTEGER;
BEGIN
   SELECT company_id INTO _company_id FROM ossweb_companies WHERE company_name ILIKE _company_name LIMIT 1;
   IF NOT FOUND AND TRIM(_company_name) <> '''' THEN
     _company_id := NEXTVAL(''ossweb_company_seq'');
     INSERT INTO ossweb_companies(company_id,company_name) VALUES(_company_id,_company_name);
   END IF;
   RETURN _company_id;
END;' LANGUAGE 'plpgsql' STRICT;

/*
   Returns string text with address information
*/
CREATE OR REPLACE FUNCTION ossweb_country_name(INTEGER) RETURNS VARCHAR AS '
DECLARE
  rec RECORD;
  result VARCHAR := '''';
BEGIN
       SELECT c.country_name
       INTO rec
       FROM ossweb_countries c, ossweb_locations l
       WHERE l.address_id=$1
       AND l.country=c.country_id;
       result:= COALESCE(rec.country_name,''none'');
       RETURN result;
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION ossweb_location_name(INTEGER) RETURNS VARCHAR AS '
BEGIN
   RETURN ossweb_location_name($1,NULL,'''');
END;' LANGUAGE 'plpgsql' STRICT;

CREATE OR REPLACE FUNCTION ossweb_location_name(INTEGER,VARCHAR) RETURNS VARCHAR AS '
BEGIN
   RETURN ossweb_location_name($1,$2,'''');
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION ossweb_location_name(INTEGER,VARCHAR,VARCHAR) RETURNS VARCHAR AS '
DECLARE
   _address_id ALIAS FOR $1;
   _type ALIAS FOR $2;
   _prefix ALIAS FOR $3;
   rec RECORD;
BEGIN
   SELECT * INTO rec
   FROM ossweb_locations pa
        LEFT OUTER JOIN ossweb_street_types t ON street_type=type_id
        LEFT OUTER JOIN ossweb_address_units ut ON unit_type=ut.unit_id
        LEFT OUTER JOIN ossweb_countries c ON country=country_id
   WHERE pa.address_id=COALESCE(_address_id,-1);

   IF _type = ''tclarray'' THEN
     RETURN _prefix||''address_id ''||COALESCE(_address_id,-1)||'' ''||
            _prefix||''number {''||COALESCE(rec.number,'''')||''} ''||
            _prefix||''street {''||COALESCE(rec.street,'''')||''} ''||
            _prefix||''street_type {''||COALESCE(rec.street_type,'''')||''} ''||
            _prefix||''unit_type {''||COALESCE(rec.unit_type,'''')||''} ''||
            _prefix||''unit {''||COALESCE(rec.unit,'''')||''} ''||
            _prefix||''city {''||COALESCE(rec.city,'''')||''} ''||
            _prefix||''state {''||COALESCE(rec.state,'''')||''} ''||
            _prefix||''zip_code {''||COALESCE(rec.zip_code,'''')||''} ''||
            _prefix||''country {''||COALESCE(rec.country,'''')||''} ''||
            _prefix||''country_name {''||COALESCE(rec.country_name,'''')||''} ''||
            _prefix||''longitude {''||COALESCE(rec.longitude||'''','''')||''} ''||
            _prefix||''latitude {''||COALESCE(rec.latitude||'''','''')||''} ''||
            _prefix||''location_name {''||COALESCE(rec.location_name,'''')||''} ''||
            _prefix||''location_type {''||COALESCE(rec.location_type,'''')||''} ''||
            _prefix||''address_notes {''||COALESCE(rec.address_notes,'''')||''}'';
   END IF;

   IF _type = ''jsarray'' THEN
     RETURN ''{''||
               _prefix||''address_id:''||COALESCE(_address_id,-1)||'',''||
               _prefix||''number:"''||COALESCE(rec.number,'''')||''",''||
               _prefix||''street:"''||COALESCE(rec.street,'''')||''",''||
               _prefix||''street_type:"''||COALESCE(rec.street_type,'''')||''",''||
               _prefix||''unit_type:"''||COALESCE(rec.unit_type,'''')||''",''||
               _prefix||''unit:"''||COALESCE(rec.unit,'''')||''",''||
               _prefix||''city:"''||COALESCE(rec.city,'''')||''",''||
               _prefix||''state:"''||COALESCE(rec.state,'''')||''",''||
               _prefix||''zip_code:"''||COALESCE(rec.zip_code,'''')||''",''||
               _prefix||''country:"''||COALESCE(rec.country,'''')||''",''||
               _prefix||''country_name:"''||COALESCE(rec.country_name,'''')||''",''||
               _prefix||''longitude:"''||COALESCE(rec.longitude||'''','''')||''",''||
               _prefix||''latitude:"''||COALESCE(rec.latitude||'''','''')||''",''||
               _prefix||''location_name:"''||COALESCE(rec.location_name,'''')||''",''||
               _prefix||''location_type:"''||COALESCE(rec.location_type,'''')||''",''||
               _prefix||''address_notes:"''||COALESCE(rec.address_notes,'''')||''"''||
            ''}'';
   END IF;

   IF NOT FOUND THEN
     RETURN NULL;
   END IF;

   IF _type IS NULL OR  _type = ''plain'' THEN
     RETURN CASE WHEN rec.reverse_flag
                 THEN COALESCE(rec.street||'' '','''')||
                      COALESCE(rec.street_type||'' '','''')||
                      COALESCE(rec.number||'' '','''')
                 ELSE COALESCE(rec.number||'' '','''')||
                      COALESCE(rec.street||'' '','''')||COALESCE(rec.street_type||'' '','''')
            END||
            CASE WHEN rec.unit_name IS NULL THEN ''''
                 ELSE rec.unit_name||'' ''||COALESCE(rec.unit,'''')||'' ''
            END||
            CASE WHEN rec.city IS NULL THEN ''''
                 ELSE '' ''||rec.city
            END||
            CASE WHEN rec.state IS NULL THEN ''''
                 ELSE '' ''||rec.state::varchar
            END||
            CASE WHEN rec.zip_code IS NULL THEN ''''
                 ELSE '' ''||rec.zip_code
            END||
            CASE WHEN rec.country_name IS NULL THEN ''''
                 ELSE '' ''||rec.country_name
            END||
            CASE WHEN rec.latitude IS NULL THEN ''''
                 ELSE '' Lat:''||rec.latitude
            END||
            CASE WHEN rec.longitude IS NULL THEN ''''
                 ELSE '' Long:''||rec.longitude
            END||
            CASE WHEN rec.location_name IS NULL THEN ''''
                 ELSE '' (''||rec.location_name||'')''
            END||
            CASE WHEN rec.address_notes IS NULL THEN ''''
                 ELSE '' Notes: ''||rec.address_notes
            END;

   END IF;

   IF _type = ''html'' THEN
     RETURN CASE WHEN rec.location_type IS NULL THEN ''''
                 ELSE rec.location_type
            END||
            CASE WHEN rec.location_name IS NULL THEN ''''
                 ELSE '' <B>''||rec.location_name||''</B>''
            END||
            CASE WHEN rec.reverse_flag
                 THEN COALESCE('' ''||rec.street||'' '','''')||
                      COALESCE(rec.street_type||'' '','''')||
                      COALESCE(rec.number||'' '','''')
                 ELSE COALESCE('' ''||rec.number||'' '','''')||
                      COALESCE(rec.street||'' '','''')||COALESCE(rec.street_type||'' '','''')
            END||
            CASE WHEN rec.unit_name IS NULL THEN ''''
                 ELSE rec.unit_name||'' ''||COALESCE(rec.unit,'''')||'' ''
            END||
            CASE WHEN rec.city IS NULL THEN ''''
                 ELSE '' ''||rec.city
            END||
            CASE WHEN rec.state IS NULL THEN ''''
                 ELSE '' ''||rec.state::varchar
            END||
            CASE WHEN rec.zip_code IS NULL THEN ''''
                 ELSE '' ''||rec.zip_code
            END||
            CASE WHEN rec.country_name IS NULL THEN ''''
                 ELSE '' ''||rec.country_name
            END||
            CASE WHEN rec.latitude IS NULL THEN ''''
                 ELSE '' Lat:''||rec.latitude
            END||
            CASE WHEN rec.longitude IS NULL THEN ''''
                 ELSE '' Long:''||rec.longitude
            END||
            CASE WHEN rec.address_notes IS NULL THEN ''''
                 ELSE '' Notes: ''||rec.address_notes
            END;

   END IF;
   IF _type = ''namevalue'' THEN
     RETURN CASE WHEN rec.number IS NULL THEN '',''
                 ELSE ''Number=''||rec.number||'',''
            END||
            CASE WHEN rec.street IS NULL THEN '',''
                 ELSE ''Street=''||rec.street||'',''
            END||
            CASE WHEN rec.street_type IS NULL THEN '',''
                 ELSE ''StreetType=''||rec.street_type||'',''
            END||
            CASE WHEN rec.unit_name IS NULL THEN ''''
                 ELSE rec.unit_name||''=''||COALESCE(rec.unit,'''')||'',''
            END||
            CASE WHEN rec.city IS NULL THEN ''''
                 ELSE ''City=''||rec.city||'',''
            END||
            CASE WHEN rec.state IS NULL THEN ''''
                 ELSE ''State=''||rec.state::varchar||'',''
            END||
            CASE WHEN rec.zip_code IS NULL THEN ''''
                 ELSE ''Zip=''||rec.zip_code||'',''
            END||
            CASE WHEN rec.country_name IS NULL THEN ''''
                 ELSE ''Country=''||rec.country_name||'',''
            END||
            CASE WHEN rec.latitude IS NULL THEN ''''
                 ELSE ''Latitude=''||rec.latitude||'',''
            END||
            CASE WHEN rec.longitude IS NULL THEN ''''
                 ELSE ''Longitude=''||rec.longitude||'',''
            END||
            CASE WHEN rec.location_name IS NULL THEN ''''
                 ELSE ''Name=''||rec.location_name||'',''
            END||
            CASE WHEN rec.location_type IS NULL THEN ''''
                 ELSE ''Type=''||rec.location_type||'',''
            END||
            CASE WHEN rec.address_notes IS NULL THEN ''''
                 ELSE ''Notes=''||rec.address_notes||'',''
            END;
   END IF;
   IF _type = ''name'' THEN
     RETURN CASE WHEN rec.location_name IS NULL THEN ''''
                 ELSE rec.location_name
            END;
   END IF;
   IF _type = ''type'' THEN
     RETURN CASE WHEN rec.location_type IS NULL THEN ''''
                 ELSE rec.location_type
            END;
   END IF;
   IF _type = ''short'' THEN
     RETURN CASE WHEN rec.location_name IS NULL THEN '''' ELSE rec.location_name END||
            CASE WHEN rec.city IS NULL THEN '''' ELSE ''-''||rec.city END||
            CASE WHEN rec.state IS NULL THEN '''' ELSE ''-''||rec.state END||
            CASE WHEN rec.country IS NULL THEN '''' ELSE ''-''||rec.country END;
   END IF;
   IF _type = ''wh_short'' THEN
     RETURN CASE WHEN rec.location_name IS NULL THEN '''' ELSE rec.location_name||'' '' END||
            CASE WHEN rec.city IS NULL THEN '''' ELSE rec.city END||
            CASE WHEN rec.state IS NULL THEN '''' ELSE ''-''||rec.state END||
            CASE WHEN rec.country IS NULL THEN '''' ELSE ''-''||rec.country END;
   END IF;
   RETURN '''';
END;' LANGUAGE 'plpgsql' STABLE;

CREATE OR REPLACE FUNCTION ossweb_location_update(INTEGER,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR,VARCHAR) RETURNS INTEGER AS '
DECLARE
   _address_id ALIAS FOR $1;
   _type ALIAS FOR $2;
   _name ALIAS FOR $3;
   _number ALIAS FOR $4;
   _street ALIAS FOR $5;
   _street_type ALIAS FOR $6;
   _unit_type ALIAS FOR $7;
   _unit ALIAS FOR $8;
   _city ALIAS FOR $9;
   _state ALIAS FOR $10;
   _zip_code ALIAS FOR $11;
   _country ALIAS FOR $12;
   addr_id INTEGER;
   streetName VARCHAR;
   streetType VARCHAR;
   rec RECORD;
   chk RECORD;
   pos INTEGER;
   ltype VARCHAR;
   stype VARCHAR;
   slast VARCHAR;
BEGIN
   ltype := COALESCE(_type,''Address'');
   SELECT * INTO chk FROM ossweb_location_types WHERE type_id=ltype;
   IF NOT FOUND THEN
     RAISE EXCEPTION ''OSSWEB: Invalid location type %'',ltype;
   END IF;

   /* Name uniqueness */
   IF chk.name_check THEN
     /* Columns first */
     IF COALESCE(TRIM(_name),'''') = '''' THEN
       RAISE EXCEPTION ''OSSWEB: Location name should not be empty'';
     END IF;

     /* Check database for duplicate */
     SELECT address_id,number,street,street_type,city,state INTO rec
     FROM ossweb_locations
     WHERE COALESCE(_address_id,-1) <> address_id AND
           location_type = (CASE WHEN chk.type_check THEN ltype ELSE location_type END) AND
           location_name ILIKE TRIM(_name)
     LIMIT 1;

     IF _address_id IS NOT NULL AND addr_id IS NOT NULL THEN
       RAISE EXCEPTION ''OSSWEB: ADDRESS: %: Such address already exists in the database % % % % %'',
                         rec.address_id,rec.number,rec.street,rec.street_type,rec.city,rec.state;
     END IF;
     addr_id = rec.address_id;
   END IF;

   /* Address uniqueness */
   IF chk.address_check THEN
     /* Columns first */
     IF chk.number_check AND
        COALESCE(TRIM(_number),'''') = '''' THEN
       RAISE EXCEPTION ''OSSWEB: Number should not be empty'';
     END IF;

     IF chk.street_check AND
        COALESCE(TRIM(_street),'''') = '''' AND
        NOT COALESCE((SELECT nostreet_flag FROM ossweb_street_types WHERE type_id=_street_type),FALSE) THEN
       RAISE EXCEPTION ''OSSWEB: Street should not be empty'';
     END IF;

     IF chk.city_check AND
        COALESCE(TRIM(_city),'''') = '''' THEN
       RAISE EXCEPTION ''OSSWEB: City should not be empty'';
     END IF;

     /* Check unique constraints */
     IF NOT(_unit_type IS NULL AND _unit IS NULL OR _unit_type IS NOT NULL AND _unit IS NOT NULL AND _unit <> '''') THEN
       RAISE EXCEPTION ''OSSWEB: Unit Type and Unit should be specified'';
     END IF;

     /* Parse street, split into street and type */
     IF chk.street_check THEN
       streetType := TRIM(COALESCE(_street_type,''''));
       streetName = TRANSLATE(INITCAP(TRIM(_street)),'';:,.'','''');
       /* Here we handle all types of special addresses */
       stype := UPPER(str_index(streetName,''end'','' ''));
       IF streetName ~* ''p.?o.?.*box'' THEN
         stype := ''PO BOX'';
       END IF;
       IF stype IN (''NE'',''NW'',''SE'',''SW'',''SOUTH'',''NORTH'',''EAST'',''WEST'',''BOX'') THEN
         slast := stype;
         stype := UPPER(str_index(streetName,''end-1'','' ''));
       END IF;
       pos := POSITION(stype IN UPPER(streetName));
       IF pos > 1 THEN
         pos := pos - 1;
       END IF;
       SELECT type_id,nostreet_flag INTO rec FROM ossweb_street_types WHERE type_id ILIKE stype OR short_name ILIKE stype;
       /* Verify street type */
       IF streetType = '''' THEN
         IF NOT FOUND THEN
           RAISE EXCEPTION ''OSSWEB: Street type "%" is not valid in address "%", please select Street Type'',stype,streetName;
         END IF;
         /* Reconstruct street name */
         streetName := TRIM(SUBSTRING(streetName,1,pos));
         IF slast IS NOT NULL THEN
           streetName := streetName||'' ''||slast;
         END IF;
         streetType := rec.type_id;
       ELSE
         /* Strip street type from the name only if both are equal for cases like: Lees Mill Drive */
         IF FOUND AND stype ILIKE streetType THEN
           streetName := TRIM(SUBSTRING(streetName,1,pos));
         END IF;
         SELECT nostreet_flag INTO rec FROM ossweb_street_types WHERE type_id=streetType;
       END IF;
       /* Address does not require street name, type says it all */
       IF rec.nostreet_flag THEN
         streetName := '''';
       END IF;
     END IF;
     /* Check database for duplicate */
     SELECT address_id,number,street,street_type,city,state INTO rec
     FROM ossweb_locations
     WHERE COALESCE(_address_id,-1) <> address_id AND
           location_type = (CASE WHEN chk.type_check THEN ltype ELSE location_type END) AND
           COALESCE(location_name,'''') ILIKE COALESCE(CASE WHEN chk.name_check THEN TRIM(_name) ELSE location_name END,'''') AND
           COALESCE(number,'''') ILIKE COALESCE(CASE WHEN chk.number_check THEN TRIM(_number) ELSE number END,'''') AND
           COALESCE(street,'''') ILIKE COALESCE(CASE WHEN chk.street_check THEN streetName ELSE street END,'''') AND
           COALESCE(street_type,'''') ILIKE COALESCE(CASE WHEN chk.street_check THEN streetType ELSE street_type END,'''') AND
           COALESCE(unit_type,'''') ILIKE COALESCE(CASE WHEN chk.unit_check THEN _unit_type ELSE unit_type END,'''') AND
           COALESCE(unit,'''') ILIKE COALESCE(CASE WHEN chk.unit_check THEN UPPER(TRIM(_unit)) ELSE unit END,'''') AND
           COALESCE(city,'''') ILIKE COALESCE(CASE WHEN chk.city_check THEN TRIM(_city) ELSE city END,'''') AND
           COALESCE(state,'''') ILIKE COALESCE(CASE WHEN chk.state_check THEN UPPER(_state) ELSE state END,'''') AND
           COALESCE(zip_code,'''') ILIKE COALESCE(CASE WHEN chk.zip_check THEN UPPER(TRIM(_zip_code)) ELSE zip_code END,'''') AND
           COALESCE(country,'''') ILIKE COALESCE(CASE WHEN chk.country_check THEN UPPER(TRIM(_country)) ELSE country END,'''')
     LIMIT 1;
     IF _address_id IS NOT NULL AND FOUND THEN
       RAISE EXCEPTION ''OSSWEB: ADDRESS: %: Such address already exists in the database % % % % %'',
                         rec.address_id,rec.number,rec.street,rec.street_type,rec.city,rec.state;
     END IF;
     addr_id = rec.address_id;
   END IF;

   /* Add operation requested */
   IF _address_id IS NULL THEN
     IF addr_id IS NOT NULL THEN
       RETURN addr_id;
     END IF;
     INSERT INTO ossweb_locations(location_name,location_type,number,street,street_type,city,unit_type,unit,state,zip_code,country)
     VALUES (TRIM(_name),
             ltype,
             TRIM(_number),
             COALESCE(streetName,_street),
             COALESCE(streetType,_street_type),
             INITCAP(TRIM(_city)),
             _unit_type,
             UPPER(TRIM(_unit)),
             UPPER(_state),
             UPPER(TRIM(_zip_code)),
             UPPER(TRIM(_country)));
     RETURN CURRVAL(''ossweb_address_seq'');
   END IF;

   /* Update operation requested */
   UPDATE ossweb_locations
   SET location_type=ltype,
       location_name=TRIM(_name),
       number=TRIM(_number),
       street=COALESCE(streetName,_street),
       street_type=COALESCE(streetType,_street_type),
       city=INITCAP(TRIM(_city)),
       unit_type=_unit_type,
       unit=UPPER(TRIM(_unit)),
       state=UPPER(_state),
       zip_code=UPPER(TRIM(_zip_code)),
       country=UPPER(TRIM(_country))
   WHERE address_id=_address_id;
   RETURN _address_id;
END;' LANGUAGE 'plpgsql' VOLATILE;


/*
   People contacts
 */
CREATE OR REPLACE FUNCTION ossweb_people_entries(INTEGER) RETURNS VARCHAR AS '
DECLARE
   rec RECORD;
   result VARCHAR := '''';
BEGIN
   FOR rec IN SELECT entry_name,entry_value,TO_CHAR(entry_date,''MM/DD/YYYY'') AS entry_date
              FROM ossweb_people_entries
              WHERE people_id=$1 AND
                    (entry_value IS NOT NULL OR entry_date IS NOT NULL)
              ORDER BY update_date LOOP
     result := result||''{''||rec.entry_name||''} {''||COALESCE(rec.entry_value,rec.entry_date)||''} '';
   END LOOP;
   RETURN result;
END;' LANGUAGE 'plpgsql' STABLE STRICT;


