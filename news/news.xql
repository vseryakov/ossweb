<?xml version="1.0"?>

<xql>

<query name="news.create">
  <description>
    Create news record
  </description>
  <sql>
    INSERT INTO news
    [ossweb::sql::insert_values -full t \
          { news_id int ""
            pubdate "" ""
            category "" ""
            link "" ""
            title "" ""
            description "" }]
  </sql>
</query>

<query name="news.update.history">
  <description>
    Delete all unnecessary news records according to setup
  </description>
  <sql>
    DELETE FROM news
    WHERE pubdate < NOW() - '[ossweb::config news:history "24 hours"]'::INTERVAL
  </sql>
</query>

<query name="news.read">
  <description>
    Read all latest news records
  </description>
  <sql>
    SELECT TO_CHAR(n.pubdate,'MM/DD/YY HH24:MI') AS pubdate,
           n.category,
           n.link,
           n.title,
           n.description,
           (SELECT 1
            FROM news n2
            WHERE n2.title=n.title AND
                  n2.news_id <> n.news_id
            LIMIT 1) AS old_flag
    FROM news n
    WHERE news_id=(SELECT MAX(news_id) FROM news)
    ORDER BY CASE WHEN category='GENERAL' THEN 0
                  WHEN category='WORLD' THEN 1
                  WHEN category='REGION' THEN 2
                  WHEN category='BUSINESS' THEN 3
                  WHEN category='TECH' THEN 4
                  WHEN category='SCIENCE' THEN 5
                  WHEN category='SCITECH' THEN 5
                  WHEN category='SPORTS' THEN 6
                  WHEN category='ENTERTAINMENT' THEN 7
                  WHEN category='HEALTH' THEN 8
                  ELSE 9
                  END
  </sql>
</query>

</xql>
