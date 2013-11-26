
INSERT INTO report_categories (category_id,category_name)
       VALUES ('Customer','Customer Management');
INSERT INTO report_categories (category_id,category_name)
       VALUES ('Order','Order Management');
INSERT INTO report_categories (category_id,category_name)
       VALUES ('Tickets','Trouble Tickets');
INSERT INTO report_categories (category_id,category_name)
       VALUES ('WorkOrders','Work Orders');
INSERT INTO report_categories (category_id,category_name)
       VALUES ('Billing','Billing System');
INSERT INTO report_categories (category_id,category_name)
       VALUES ('Provisioning','Provisioning');
INSERT INTO report_categories (category_id,category_name)
       VALUES ('Inventory','Intentory System');

INSERT INTO ossweb_reftable (app_name,page_name,table_name,object_name,title)
       VALUES('reports','reportcategories','report_categories','category','Categories');

