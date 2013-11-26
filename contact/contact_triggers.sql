/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   January 2002
*/

CREATE OR REPLACE FUNCTION ossweb_location_trigger_func() RETURNS TRIGGER AS '
DECLARE
   addr VARCHAR;
BEGIN
   NEW.update_date = NOW();
   RETURN NEW;
END;' LANGUAGE 'plpgsql';

DROP TRIGGER ossweb_location_trigger ON ossweb_locations;
CREATE TRIGGER ossweb_location_trigger BEFORE INSERT OR UPDATE ON ossweb_locations
FOR EACH ROW EXECUTE PROCEDURE ossweb_location_trigger_func();
