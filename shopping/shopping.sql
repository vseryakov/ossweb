/* 
   Author: Vlad Seryakov vlad@crystalballinc.com
   April 2004
*/

CREATE SEQUENCE shopping_product_seq START 1;
CREATE SEQUENCE shopping_cart_seq START 1;
CREATE SEQUENCE shopping_cart_product_seq START 1;

CREATE TABLE shopping_products (
   product_id INTEGER DEFAULT NEXTVAL('shopping_product_seq') NOT NULL,
   product_name VARCHAR NOT NULL,
   category_id INTEGER NOT NULL REFERENCES ossweb_categories(category_id),
   price FLOAT DEFAULT 0 NOT NULL,
   sale_price FLOAT NULL,
   description VARCHAR NULL,
   quantity INTEGER DEFAULT 0 NOT NULL,
   icon VARCHAR NULL,
   image VARCHAR NULL,
   start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
   CONSTRAINT shopping_products_pk PRIMARY KEY (product_id),
   CONSTRAINT shopping_products_un UNIQUE (product_name,category_id)
);

CREATE TABLE shopping_product_properties (
   product_id INTEGER NOT NULL REFERENCES shopping_products(product_id),
   name VARCHAR NOT NULL,
   value VARCHAR NULL,
   CONSTRAINT shopping_products_prop_pk PRIMARY KEY (product_id,name),
   CONSTRAINT shopping_products_prop_un UNIQUE (name,product_id)
);

CREATE INDEX shopping_products_prop_idx ON shopping_product_properties(value);

CREATE TABLE shopping_cart (
   cart_id INTEGER DEFAULT NEXTVAL('shopping_cart_seq') NOT NULL,
   ipaddr VARCHAR NULL,
   first_name VARCHAR NULL,
   last_name VARCHAR NULL,
   email VARCHAR NULL,
   phone VARCHAR NULL,
   notes VARCHAR NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   update_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   submit_time TIMESTAMP WITH TIME ZONE NULL,
   charge_name VARCHAR NULL,
   charge_price FLOAT DEFAULT 0 NOT NULL,
   billing_time TIMESTAMP WITH TIME ZONE NULL,
   billing_tax FLOAT DEFAULT 0 NOT NULL,
   billing_name VARCHAR NULL,
   billing_number VARCHAR NULL,
   billing_street VARCHAR NULL,
   billing_city VARCHAR NULL,
   billing_state VARCHAR NULL,
   billing_zip_code VARCHAR NULL,
   billing_country VARCHAR NULL,
   billing_card_type VARCHAR NULL,
   billing_card_num VARCHAR NULL,
   billing_card_exp VARCHAR NULL,
   shipping_time TIMESTAMP WITH TIME ZONE NULL,
   shipping_price FLOAT DEFAULT 0 NOT NULL,
   shipping_method VARCHAR NULL,
   shipping_number VARCHAR NULL,
   shipping_street VARCHAR NULL,
   shipping_city VARCHAR NULL,
   shipping_state VARCHAR NULL,
   shipping_zip_code VARCHAR NULL,
   shipping_country VARCHAR NULL,
   shipping_tracking_id VARCHAR NULL,
   CONSTRAINT shopping_carts_pk PRIMARY KEY (cart_id)
);

CREATE TABLE shopping_cart_products (
   cart_product_id INTEGER DEFAULT NEXTVAL('shopping_cart_product_seq') NOT NULL,
   cart_id INTEGER NOT NULL REFERENCES shopping_cart(cart_id),
   product_id INTEGER NOT NULL REFERENCES shopping_products(product_id),
   price FLOAT NOT NULL,
   quantity INTEGER DEFAULT 1 NOT NULL,
   promotion VARCHAR NULL,
   create_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
   CONSTRAINT shopping_items_pk PRIMARY KEY (cart_product_id)
);

CREATE INDEX shopping_cart_products_idx ON shopping_cart_products(cart_id,product_id);

