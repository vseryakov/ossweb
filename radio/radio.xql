<?xml version="1.0"?>

<xql>

<query name="radio.create">
  <description>
  </description>
  <sql>
    INSERT INTO radio
    [ossweb::sql::insert_values -full t \
          { radio_title "" ""
            radio_genre "" ""
            radio_url "" "" }]
  </sql>
</query>

<query name="radio.list">
  <description>
  </description>
  <sql>
    SELECT radio_url,
           radio_title,
           radio_genre
    FROM radio
    ORDER BY create_time
  </sql>
</query>

<query name="radio.delete">
  <description>
  </description>
  <sql>
    DELETE FROM radio
  </sql>
</query>

</xql>
