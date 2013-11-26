/*
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2004
*/

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image)
       VALUES ('Catalog', '*', 'shopping', 'catalog', 'book.gif');

INSERT INTO ossweb_apps (title, project_name, app_name, page_name, image, group_id)
       VALUES ('Product Catalog', '*', 'shopping', 'products', 'book.gif', (SELECT app_id FROM ossweb_apps WHERE title='Setup'));

INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Books');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Electronics');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Video');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Toys');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Music');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Computers');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Software');
INSERT INTO ossweb_categories (module,category_name)
       VALUES('Shopping','Hardtware');
