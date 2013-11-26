
<query name="webmail.contacts.create">
  <description>
    Create address book record
  </description>
  <sql>
    INSERT INTO webmail_contacts
    [ossweb::sql::insert_values -full t \
          { first_name "" ""
            last_name "" ""
            email "" ""
            user_id int "" }]
  </sql>
</query>

<query name="webmail.contacts.add">
  <description>
    Create address book record
  </description>
  <sql>
    INSERT INTO webmail_contacts (email,user_id)
    SELECT [ossweb::sql::quote $email],[ossweb::conn user_id]
    WHERE NOT EXISTS(SELECT 1
                     FROM webmail_contacts b
                     WHERE b.email='$email' AND
                           user_id=[ossweb::conn user_id])
  </sql>
</query>

<query name="webmail.contacts.update">
  <description>
    Update address book record
  </description>
  <sql>
    UPDATE webmail_contacts
    SET [ossweb::sql::update_values \
          { first_name "" ""
            last_name "" ""
            email "" ""}]
    WHERE contact_id=$contact_id AND
          user_id IN (-1,[ossweb::conn user_id])
  </sql>
</query>

<query name="webmail.contacts.delete">
  <description>
    Delete address book record
  </description>
  <sql>
    DELETE FROM webmail_contacts
    WHERE contact_id=$contact_id AND
          user_id IN (-1,[ossweb::conn user_id])
  </sql>
</query>

<query name="webmail.contacts.read">
  <description>
    Read address book record
  </description>
  <sql>
    SELECT contact_id,
           first_name,
           last_name,
           email,
           user_id
    FROM webmail_contacts
    WHERE contact_id=$contact_id AND
          user_id IN (-1,[ossweb::conn user_id])
  </sql>
</query>

<query name="webmail.contacts.search">
  <description>
    Search address book with contacts
  </description>
  <sql>
    SELECT contact_id,
           first_name||' '||last_name AS name,
           email,
           user_id
    FROM webmail_contacts
    WHERE user_id in (-1,[ossweb::conn user_id])
          [ossweb::sql::filter \
                { first_name Text ""
                  last_name Text ""
                  email Text ""
                  filter Text "" } \
                -map { filter "(first_name ILIKE %value OR last_name ILIKE %value OR email ILIKE %value)" } \
                -before AND]
    UNION
    SELECT -1,
           first_name||' '||last_name,
           entry_value,
           -1
    FROM ossweb_people p,
         ossweb_people_entries c
    WHERE p.access_type IN ('Public','Open') AND
          p.people_id=c.people_id AND
          c.entry_name ILIKE 'Email' AND
          c.entry_value LIKE '%@%'
          [ossweb::sql::filter \
                { first_name Text ""
                  last_name Text ""
                  email Text ""
                  filter Text "" } \
                -namemap { email entry_value } \
                -map { filter "(first_name ILIKE %value OR last_name ILIKE %value OR entry_name ILIKE %value)" } \
                -before AND]
    ORDER BY 2
  </sql>
</query>

<query name="webmail.message.create">
  <description>
  </description>
  <sql>
    INSERT INTO webmail_messages
    [ossweb::sql::insert_values -full t \
          { mailbox "" ""
            msg_id int ""
            msg_uidvalidity "" ""
            msg_type "" ""
            msg_flags "" ""
            msg_size "" ""
            msg_date "" ""
            msg_from "" ""
            msg_subject "" ""
            user_id const {[ossweb::conn user_id]} }]
  </sql>
</query>

<query name="webmail.message.update">
  <description>
  </description>
  <sql>
    UPDATE webmail_messages
    SET [ossweb::sql::update_values -skip_null t -keep msg_flags \
          { msg_id int ""
            msg_uidvalidity "" ""
            msg_type "" ""
            msg_flags "" ""
            msg_size "" ""
            msg_date "" ""
            msg_from "" ""
            msg_subject "" "" }]
    WHERE msg_id=$msg_id AND
          mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="webmail.message.delete">
  <description>
  </description>
  <sql>
    DELETE FROM webmail_messages
    WHERE msg_id IN ([ossweb::sql::list $msg_id int]) AND
          mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="webmail.message.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM webmail_messages
    WHERE mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="webmail.message.count">
  <description>
  </description>
  <sql>
    SELECT COUNT(*)
    FROM webmail_messages
    WHERE mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="webmail.message.uid.last">
  <description>
  </description>
  <sql>
    SELECT msg_id,
           msg_uidvalidity
    FROM webmail_messages
    WHERE mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
    ORDER BY msg_id DESC
    LIMIT 1
  </sql>
</query>

<query name="webmail.message.read">
  <description>
  </description>
  <sql>
    SELECT msg_id,
           TO_CHAR(msg_date,'Dy, DD Mon YYYY HH24:MI') AS msg_date,
           msg_type,
           msg_flags,
           msg_size,
           msg_from,
           msg_subject
    FROM webmail_messages
    WHERE msg_id=$msg_id AND
          mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
  </sql>
</query>

<query name="webmail.message.list">
  <description>
  </description>
  <vars>
    msg_sort msg_date
  </vars>
  <sql>
    SELECT msg_id,
           TO_CHAR(msg_date,'Dy, DD Mon YYYY HH24:MI') AS msg_time,
           ROUND(EXTRACT(EPOCH FROM msg_date)) AS msg_date,
           msg_type,
           msg_flags,
           msg_size,
           msg_from,
           msg_subject
    FROM webmail_messages
    WHERE mailbox=[ossweb::sql::quote $mailbox] AND
          user_id=[ossweb::conn user_id]
          [ossweb::sql::filter \
                { show_deleted boolean ""
                  msg_start int ""
                  filter "" "" } \
                -before AND \
                -map { show_deleted "(msg_flags IS NULL OR msg_flags !~ 'D' OR msg_flags ~ 'D' = %value)"
                       filter "(msg_from ~* %value OR msg_subject ~* %value)"
                       msg_start "msg_id >= %value" }]
    ORDER BY $msg_sort
  </sql>
</query>

