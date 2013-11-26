INSERT INTO ossweb_config_Types (type_id,type_name,description,module)
 VALUES('icq:logevents','ICQ Log Events','Do ICQ event logging','IM'),
       ('icq:contacts','ICQ Contacts','List og ICQ UINs','IM'),
       ('icq:user','ICQ User','User name for ICQ login','IM'),
       ('icq:passwd','ICQ Password','Password for ICQ login','IM'),
       ('modem:device','Modem Device','Device name for modem CallerID','IM'),
       ('modem:init','Modem Init','Init string for modem device','IM'),
       ('modem:mode','Modem Mode','Init string for modem device: like 9600,8,n,1','IM'),
       ('callerid:ipaddr','Modem Ipaddr','List of IP where to send CallerID packets','IM'),
       ('callerid:icq','Modem ICQ','List of ICQ uins where to send CallerID packets','IM');
