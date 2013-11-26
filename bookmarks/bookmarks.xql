<?xml version="1.0"?>

<xql>

<query name="bookmarks.section.list">
  <description>
    List of all bookmark sections
  </description>
  <sql>
    SELECT title,
           bm_id
    FROM ossweb_bookmarks
    WHERE user_id=$user_id AND
          url IS NULL
    ORDER BY 1
  </sql>
</query>

<query name="bookmarks.list">
  <description>
    List of all bookmarks
  </description>
  <sql>
    SELECT bm_id,
           url,
           title,
           section,
           path,
           sort
    FROM ossweb_bookmarks
    WHERE user_id=$user_id
    ORDER BY path
  </sql>
</query>

<query name="bookmarks.read">
  <description>
    Read bookmark record
  </description>
  <sql>
    SELECT bm_id,
           url,
           title,
           section,
           sort
    FROM ossweb_bookmarks
    WHERE bm_id=$bm_id
  </sql>
</query>

<query name="bookmarks.create">
  <description>
  </description>
  <sql>
    INSERT INTO ossweb_bookmarks
    [ossweb::sql::insert_values -full t \
          { user_id const {[ossweb::conn user_id]}
            url "" ""
            title "" ""
            section "" ""
            sort int "" }]
  </sql>
</query>

<query name="bookmarks.update">
  <description>
  </description>
  <sql>
    UPDATE ossweb_bookmarks
    SET [ossweb::sql::update_values \
              { url "" ""
                title "" ""
                section "" ""
                sort int "" }]
    WHERE bm_id=$bm_id
  </sql>
</query>

<query name="bookmarks.delete">
  <description>
  </description>
  <sql>
    DELETE FROM ossweb_bookmarks WHERE user_id=$user_id AND bm_id=$bm_id
  </sql>
</query>

<query name="bookmarks.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM ossweb_bookmarks WHERE user_id=$user_id
  </sql>
</query>

</xql>
