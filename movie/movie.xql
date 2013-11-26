<?xml version="1.0"?>

<xql>

<query name="movie.create">
  <description>
  </description>
  <sql>
    INSERT INTO movies
    [ossweb::sql::insert_values -full t \
          { movie_title "" ""
            movie_descr "" ""
            movie_genre "" ""
            movie_lang "" ""
            movie_year int ""
            movie_age "" ""
            imdb_id int "" }]
  </sql>
</query>

<query name="movie.update">
  <description>
  </description>
  <sql>
    UPDATE movies
    SET [ossweb::sql::update_values \
              { movie_title "" ""
                movie_descr "" ""
                movie_genre "" ""
                movie_lang "" ""
                movie_year "" ""
                movie_age "" ""
                imdb_id int ""
                update_time const "NOW()"}]
    WHERE movie_id=$movie_id
  </sql>
</query>

<query name="movie.update.watch_count">
  <description>
  </description>
  <sql>
    UPDATE movies
    SET [ossweb::sql::update_values \
              { watch_time "" ""
                watch_count int "" }]
    WHERE movie_id=$movie_id
  </sql>
</query>

<query name="movie.read">
  <description>
  </description>
  <sql>
    SELECT movie_id,
           movie_title,
           movie_descr,
           movie_genre,
           movie_lang,
           movie_year,
           movie_age,
           imdb_id,
           watch_count,
           TO_CHAR(watch_time,'MM/DD/YY HH12:MI PM') AS watch_time,
           TO_CHAR(create_time,'MM/DD/YY HH12:MI PM') AS create_time
    FROM movies
    WHERE movie_id=$movie_id
  </sql>
</query>

<query name="movie.search1">
  <description>
  </description>
  <sql>
    SELECT movie_id
    FROM movies m
    [ossweb::sql::filter \
          { movie_title Text ""
            movie_descr Text ""
            movie_year int ""
	    movie_age int ""
            movie_lang "" ""
            imdb_id ilist ""
            disk_id int ""
            create_time datetime ""
            nodisk_flag int ""
            nofile_flag int ""
            nodescr_flag int ""
            nomovie_genre int ""
            movie_genre int ""
            neverwatched_flag int "" } \
          -where WHERE \
          -map { create_time "create_time >= '%value'"
                 disk_id "EXISTS(SELECT 1 FROM movie_files f WHERE m.movie_id=f.movie_id AND disk_id=%value)"
                 nodisk_flag "EXISTS(SELECT 1 FROM movie_files f WHERE m.movie_id=f.movie_id AND disk_id IS NULL)"
                 nofile_flag "NOT EXISTS(SELECT 1 FROM movie_files f WHERE m.movie_id=f.movie_id)"
                 nodescr_flag "(movie_descr IS NULL OR imdb_id IS NULL)"
                 neverwatched_flag "watch_time IS NULL"
                 movie_genre %value
                 movie_age "movie_age <= %value" }]
    ORDER BY movie_title
  </sql>
</query>

<query name="movie.search2">
  <description>
  </description>
  <sql>
    SELECT movie_id,
           movie_title,
           movie_descr,
           movie_genre,
           movie_lang,
           movie_year,
           movie_age,
           imdb_id,
           watch_count,
           TO_CHAR(watch_time,'MM/DD/YY HH12:MI PM') AS watch_time,
           movie_files(movie_id) AS movie_files
    FROM movies
    WHERE movie_id IN (CURRENT_PAGE_SET)
  </sql>
</query>

<query name="movie.delete">
  <description>
  </description>
  <sql>
    DELETE FROM movies WHERE movie_id=$movie_id
  </sql>
</query>

<query name="movie.file.create">
  <description>
  </description>
  <sql>
    INSERT INTO movie_files
    [ossweb::sql::insert_values -full t \
          { movie_id int ""
            disk_id int ""
            file_size int ""
            file_info "" ""
            file_name "" ""
            file_params "" ""
	    file_path "" "" }]
  </sql>
</query>

<query name="movie.file.update">
  <description>
  </description>
  <sql>
    UPDATE movie_files
    SET [ossweb::sql::update_values \
          { disk_id int ""
            file_size int ""
            file_info "" ""
	    file_params "" ""
            file_path "" "" }]
    WHERE movie_id=$movie_id AND
          file_name=[ossweb::sql::quote $file_name]
  </sql>
</query>

<query name="movie.file.delete">
  <description>
  </description>
  <sql>
    DELETE FROM movie_files
    WHERE movie_id=$movie_id AND
          file_name=[ossweb::sql::quote $file_name]
  </sql>
</query>

<query name="movie.file.list">
  <description>
  </description>
  <sql>
    SELECT movie_id,
           disk_id,
           file_name,
           file_path,
	   file_params,
           file_info,
           file_size
    FROM movie_files
    WHERE movie_id=$movie_id
  </sql>
</query>

<query name="movie.file.names">
  <description>
  </description>
  <sql>
    SELECT file_path FROM movie_files WHERE movie_id=$movie_id
    LIMIT 1
  </sql>
</query>

<query name="movie.file.read">
  <description>
  </description>
  <sql>
    SELECT disk_id,
           file_size,
           file_path,
	   file_params,
           file_info
    FROM movie_files
    WHERE movie_id=$movie_id AND
          file_name=[ossweb::sql::quote $file_name]
  </sql>
</query>

<query name="movie.disk.list">
  <description>
  </description>
  <sql>
    SELECT disk_id,
           file_size,
           file_path,
           file_name,
           file_size
    FROM movie_files
    [ossweb::sql::filter \
          { disk_id int "" } \
          -where WHERE \
          -map { disk_id "(disk_id=%value) OR (disk_id IS NULL AND %value = -1)" }]
    ORDER BY 1,2
  </sql>
</query>

<query name="movie.disk.files">
  <description>
  </description>
  <sql>
    SELECT file_path,
           file_name,
           file_size
    FROM movie_files
    WHERE disk_id=$disk_id
  </sql>
</query>

<query name="movie.disk.max">
  <description>
  </description>
  <sql>
    SELECT MAX(disk_id) FROM movie_files
  </sql>
</query>

<query name="movie.files">
  <description>
  </description>
  <sql>
    SELECT movie_id,
           disk_id,
           file_name,
           file_path,
	   file_params,
           file_info,
           file_size
    FROM movie_files
  </sql>
</query>

<query name="movie.export">
  <description>
  </description>
  <sql>
   SELECT movie_id,
          movie_title,
          movie_genre,
          movie_lang,
          movie_descr,
          movie_year,
          movie_age,
          movie_files2(movie_id) AS movie_files,
          ROUND(EXTRACT(EPOCH FROM create_time)) AS create_time,
          ROUND(EXTRACT(EPOCH FROM (SELECT MAX(create_time)
                                    FROM movie_files f
                                    WHERE f.movie_id=m.movie_id))) AS update_time
   FROM movies m
   ORDER BY movie_title
  </sql>
</query>

</xql>
