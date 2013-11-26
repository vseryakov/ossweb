/* Author: Alex Stetsyuk alex@tmatex.com
   Oct 2006

$Id:

*/


/* List of Currencies ISO 4217 */

CREATE SEQUENCE currencies_seq START 10000;

CREATE TABLE currencies (
  "currency_id" INTEGER DEFAULT NEXTVAL('currencies_seq') NOT NULL,
  "entity" VARCHAR NULL,
  "name" VARCHAR NULL,
  "iso_code_alpha" VARCHAR NULL,
  "iso_code_num" VARCHAR NULL,
  "symbol_html" VARCHAR NULL,
  "symbol_ascii" VARCHAR NULL,
  "description" VARCHAR NULL,
  "disabled" BOOLEAN DEFAULT 'f',
  "create_time" TIMESTAMP(0) WITH TIME ZONE DEFAULT now() NOT NULL, 
  "update_time" TIMESTAMP(0) WITH TIME ZONE, 
  "create_user" INTEGER NOT NULL, 
  "update_user" INTEGER,
  CONSTRAINT "currencies_pkey" PRIMARY KEY("currency_id"),
  CONSTRAINT "currencies_create_user_fk" FOREIGN KEY ("create_user")
    REFERENCES "public"."ossweb_users"("user_id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT "currencies_update_user_fk" FOREIGN KEY ("update_user")
    REFERENCES "public"."ossweb_users"("user_id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
);
