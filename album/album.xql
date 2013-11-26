<?xml version="1.0"?>

<xql>

<query name="album.photo.list">
  <description>
    List photos
  </description>
  <sql>
    SELECT photo_id,image,width,height FROM album_photos WHERE album_id=$album_id ORDER BY 1
  </sql>
</query>

<query name="album.photo.search1">
  <description>
    List photos
  </description>
  <sql>
    SELECT photo_id
    FROM album_photos
    WHERE album_id=$album_id
    ORDER BY photo_id
  </sql>
</query>

<query name="album.photo.search2">
  <description>
    List photos
  </description>
  <sql>
    SELECT photo_id,
           description,
           image,
           width,
           height,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM album_photos
    WHERE photo_id IN (CURRENT_PAGE_SET)
    ORDER BY photo_id
  </sql>
</query>

<query name="album.photo.read">
  <description>
    List photos
  </description>
  <sql>
    SELECT photo_id,
           description,
           image,
           width,
           height,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date
    FROM album_photos
    WHERE album_id=$album_id AND
          photo_id=$photo_id
  </sql>
</query>

<query name="album.photo.read.image">
  <description>
    List photos
  </description>
  <sql>
    SELECT image,
           width,
           height
    FROM album_photos
    WHERE album_id=$album_id AND
          photo_id=$photo_id
  </sql>
</query>

<query name="album.photo.create">
  <description>
    Create album photo record
  </description>
  <sql>
    INSERT INTO album_photos
    [ossweb::sql::insert_values -full t \
          { album_id int ""
            image "" ""
            description "" ""
            width int ""
            height int ""  }]
  </sql>
</query>

<query name="album.photo.create.image">
  <description>
    Create album photo record
  </description>
  <sql>
    INSERT INTO album_photos
    [ossweb::sql::insert_values -full t \
          { album_id int ""
            width int ""
            height int ""
            image "" "" }]
  </sql>
</query>

<query name="album.photo.update">
  <description>
    Create album photo record
  </description>
  <sql>
    UPDATE album_photos
    SET [ossweb::sql::update_values -skip_null t \
          { description "" ""
            width int ""
            height int ""
            image "" "" }]
    WHERE album_id=$album_id AND
          photo_id=$photo_id
  </sql>
</query>

<query name="album.photo.delete">
  <description>
    Update album photo record
  </description>
  <sql>
    DELETE FROM album_photos
    WHERE photo_id=$photo_id AND
          album_id=$album_id
  </sql>
</query>

<query name="album.create">
  <description>
    Create album record
  </description>
  <sql>
    INSERT INTO albums 
    [ossweb::sql::insert_values -full t \
          { album_name "" ""
            album_status "" ""
            album_type "" ""
            description "" ""
            row_size int ""
            page_size int ""
            user_id const {[ossweb::conn user_id 0]}}]
  </sql>
</query>

<query name="album.update">
  <description>
    Update album record
  </description>
  <sql>
    UPDATE albums 
    SET [ossweb::sql::update_values \
              { album_name "" ""
                album_status "" ""
                album_type "" ""
                description "" ""
                row_size int ""
                page_size int ""
                update_date const NOW()}]
    WHERE album_id=$album_id AND
          user_id=[ossweb::conn user_id 0]
  </sql>
</query>

<query name="album.update.photo_count">
  <description>
    Update album record
  </description>
  <sql>
    UPDATE albums 
    SET photo_count=(SELECT COUNT(*) FROM album_photos p WHERE p.album_id=albums.album_id),
        update_date=NOW()
    WHERE album_id=$album_id
  </sql>
</query>

<query name="album.delete">
  <description>
    Delete photo record
  </description>
  <sql>
    DELETE FROM albums 
    WHERE album_id=$album_id AND 
          user_id=[ossweb::conn user_id 0]
  </sql>
</query>

<query name="album.list">
  <description>
    Read all album photos
  </description>
  <sql>
    SELECT album_id,
           album_name,
           album_type,
           album_status,
           description,
           photo_count,
           user_id,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date,
           TO_CHAR(update_date,'MM/DD/YY HH24:MI') AS update_date
    FROM albums a
    WHERE (album_status='Active' AND
           user_id=[ossweb::conn user_id 0] OR album_type='Public')
    ORDER BY album_name
  </sql>
</query>

<query name="album.read">
  <description>
  </description>
  <sql>
    SELECT album_name,
           album_id,
           album_status,
           album_type,
           description,
           user_id,
           row_size,
           page_size,
           photo_count,
           TO_CHAR(create_date,'MM/DD/YY HH24:MI') AS create_date,
           TO_CHAR(update_date,'MM/DD/YY HH24:MI') AS update_date
    FROM albums
    WHERE (album_id=$album_id AND
           album_status='Active' AND
          (user_id=[ossweb::conn user_id 0] OR album_type='Public'))
  </sql>
</query>

<query name="album.check.view">
  <description>
  </description>
  <sql>
    SELECT user_id
    FROM albums
    WHERE album_id=$album_id AND
          album_status='Active' AND
          (user_id=[ossweb::conn user_id 0] OR album_type='Public')
  </sql>
</query>

<query name="album.check.edit">
  <description>
  </description>
  <sql>
    SELECT user_id 
    FROM albums 
    WHERE album_id=$album_id AND 
          user_id=[ossweb::conn user_id 0]
  </sql>
</query>

</xql>
