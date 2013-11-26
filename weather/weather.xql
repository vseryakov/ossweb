<?xml version="1.0"?>

<xql>

<query name="weather.create">
  <description>
    Create weather record
  </description>
  <sql>
    INSERT INTO weather
    [ossweb::sql::insert_values -full t \
          { weather_id "" ""
            weather_type "" ""
            weather_data "" }]
  </sql>
</query>

<query name="weather.update.history">
  <description>
    Delete all unnecessar weather records according to setup
  </description>
  <sql>
    DELETE FROM weather
    WHERE weather_date < NOW() - '[ossweb::config weather:history "2 days"]'::INTERVAL
  </sql>
</query>

<query name="weather.read">
  <description>
    Read all latest weather records
  </description>
  <sql>
    SELECT w.weather_id,
           w.weather_type,
           w.weather_date,
           w.weather_data
    FROM weather w
    ORDER BY weather_date DESC
    LIMIT 5
  </sql>
</query>

</xql>
