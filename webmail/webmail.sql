/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   January 2002
*/

CREATE SEQUENCE webmail_seq;

CREATE TABLE webmail_contacts (
   contact_id INTEGER DEFAULT NEXTVAL('webmail_seq') NOT NULL,
   email VARCHAR NOT NULL,
   first_name VARCHAR NULL,
   last_name VARCHAR NULL,
   description TEXT NULL,
   user_id INTEGER DEFAULT -1 NOT NULL, /* -1 - public email, otherwise belongs to user_id */
   PRIMARY KEY(contact_id),
   UNIQUE(user_id,email)
);

CREATE TABLE webmail_messages (
   mailbox VARCHAR NOT NULL,
   msg_id INTEGER NOT NULL,
   msg_date TIMESTAMP WITH TIME ZONE NOT NULL,
   msg_uidvalidity VARCHAR NULL,
   msg_from VARCHAR NULL,
   msg_subject VARCHAR NULL,
   msg_flags VARCHAR NULL,
   msg_type VARCHAR NULL,
   msg_size INTEGER NULL,
   user_id INTEGER NOT NULL,
   PRIMARY KEY(msg_id,mailbox,user_id),
   UNIQUE(mailbox,user_id,msg_id)
);

