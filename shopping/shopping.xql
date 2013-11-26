
<xql>

<query name="shopping.category.list">
  <description>
  </description>
  <sql>
    SELECT category_name,
           category_id
    FROM ossweb_categories
    WHERE module='Shopping'
    ORDER BY tree_path
  </sql>
</query>

<query name="shopping.category.list.top">
  <description>
  </description>
  <sql>
    SELECT category_name,
           category_id
    FROM ossweb_categories
    WHERE category_parent IS NULL AND
          module='Shopping'
    ORDER BY sort
  </sql>
</query>

<query name="shopping.category.list.children">
  <description>
  </description>
  <sql>
    SELECT category_name,
           category_parent,
           category_id,
           sort
    FROM ossweb_categories
    WHERE category_id=$category_id AND
          module='Shopping'
    UNION
    SELECT category_name,
           category_parent,
           category_id,
           sort
    FROM ossweb_categories
    WHERE category_parent=$category_id AND
          module='Shopping'
    ORDER BY sort
  </sql>
</query>

<query name="shopping.product.search1">
  <description>
  </description>
  <sql>
    SELECT product_id
    FROM shopping_products
    [ossweb::sql::filter \
          { product_name Text ""
            category_id ilist ""
            description Text "" } \
          -where WHERE]
    ORDER BY product_name
  </sql>
</query>

<query name="shopping.product.search2">
  <description>
  </description>
  <sql>
    SELECT p.product_id,
           p.product_name,
           p.category_id,
           c.category_name,
           p.price,
           p.sale_price,
           p.quantity,
           p.start_date,
           p.end_date,
           p.image,
           p.icon
    FROM shopping_products p,
         ossweb_categories c
    WHERE product_id IN (CURRENT_PAGE_SET) AND
          p.category_id=c.category_id
  </sql>
</query>

<query name="shopping.product.create">
  <description>
  </description>
  <sql>
    INSERT INTO shopping_products
    [ossweb::sql::insert_values -full t -skip_null t \
          { product_name "" ""
            category_id int ""
            price float ""
            sale_price float ""
            quantity int ""
            description "" ""
            icon "" ""
            image "" ""
            start_date datetime ""
            end_date datetime "" }]
  </sql>
</query>

<query name="shopping.product.update">
  <description>
  </description>
  <sql>
    UPDATE shopping_products
    SET [ossweb::sql::update_values \
              { product_name "" ""
                category_id int ""
                price float ""
                sale_price float ""
                quantity int ""
                description "" ""
                icon "" ""
                image "" ""
                start_date datetime ""
            end_date datetime "" }]
    WHERE product_id=$product_id
  </sql>
</query>

<query name="shopping.product.read">
  <description>
  </description>
  <sql>
    SELECT p.product_id,
           p.product_name,
           p.category_id,
           c.category_name,
           p.price,
           p.sale_price,
           p.quantity,
           p.icon,
           p.image,
           p.description,
           p.start_date,
           p.end_date
    FROM shopping_products p,
         ossweb_categories c
    WHERE product_id=$product_id AND
          p.category_id=c.category_id
  </sql>
</query>

<query name="shopping.product.delete">
  <description>
  </description>
  <sql>
    DELETE FROM shopping_products WHERE product_id=$product_id
  </sql>
</query>

<query name="shopping.product.property.list">
  <description>
  </description>
  <sql>
    SELECT name,
           value
    FROM shopping_product_properties
    WHERE product_id=$product_id
    ORDER BY name
  </sql>
</query>

<query name="shopping.product.property.create">
  <description>
  </description>
  <sql>
    INSERT INTO shopping_product_properties
    [ossweb::sql::insert_values -full t \
          { product_id int "" 
            name "" ""
            value "" "" }]
  </sql>
</query>

<query name="shopping.product.property.delete">
  <description>
  </description>
  <sql>
    DELETE FROM shopping_product_properties 
    WHERE product_id=$product_id AND
          name=[ossweb::sql::quote $name]
  </sql>
</query>

<query name="shopping.cart.read">
  <description>
  </description>
  <sql>
    SELECT cart_id,
           ipaddr,
           first_name,
           last_name,
           email,
           phone,
           notes,
           create_time,
           submit_time,
           charge_name,
           charge_price,
           billing_time,
           billing_tax,
           billing_name,
           billing_number,
           billing_street,
           billing_city,
           billing_state,
           billing_zip_code,
           billing_country,
           billing_card_num,
           billing_card_exp,
           shipping_time,
           shipping_price,
           shipping_method,
           shipping_number,
           shipping_street,
           shipping_city,
           shipping_state,
           shipping_zip_code,
           shipping_country,
           shipping_tracking_id
   FROM shopping_cart
   WHERE cart_id=$cart_id
  </sql>
</query>

<query name="shopping.cart.update">
  <description>
  </description>
  <sql>
    UPDATE shopping_cart
    SET [ossweb::sql::update_values -skip_null t \
              { first_name "" ""
                last_name "" ""
                email "" ""
                phone "" ""
                notes "" ""
                update_time int NOW()
                submit_time datetime ""
                charge_name "" ""
                charge_price float ""
                billing_time datetime ""
                billing_tax float ""
                billing_name "" ""
                billing_card_type "" ""
                billing_card_num "" ""
                billing_card_exp date ""
                billing_number "" ""
                billing_street "" ""
                billing_city "" ""
                billing_state "" ""
                billing_zip_code "" ""
                billing_country "" ""
                shipping_time datetime ""
                shipping_price float ""
                shipping_method "" ""
                shipping_number "" ""
                shipping_street "" ""
                shipping_city "" ""
                shipping_state "" ""
                shipping_zip_code "" ""
                shipping_country "" ""
                shipping_tracking_id "" "" }]
   WHERE cart_id=$cart_id
  </sql>
</query>

<query name="shopping.cart.create">
  <description>
  </description>
  <sql>
    INSERT INTO shopping_cart(cart_id,ipaddr) 
    VALUES($cart_id,'[ossweb::conn peeraddr]')
  </sql>
</query>

<query name="shopping.cart.product.list">
  <description>
  </description>
  <sql>
    SELECT s.cart_product_id,
           p.product_id,
           p.product_name,
           p.icon,
           p.image,
           s.price,
           s.quantity,
           s.promotion,
           s.create_time
    FROM shopping_cart_products s,
         shopping_products p
    WHERE cart_id=$cart_id AND
          p.product_id=s.product_id
    ORDER BY create_time
  </sql>
</query>

<query name="shopping.cart.product.count">
  <description>
  </description>
  <sql>
    SELECT COUNT(*) FROM shopping_cart_products WHERE cart_id=$cart_id
  </sql>
</query>

<query name="shopping.cart.product.read">
  <description>
  </description>
  <sql>
    SELECT s.cart_product_id,
           p.product_id,
           p.product_name,
           p.icon,
           p.image,
           s.price,
           s.quantity,
           s.promotion,
           s.create_time
    FROM shopping_cart_products s,
         shopping_products p
    WHERE cart_id=$cart_id AND
          cart_id=$cart_id AND
          p.product_id=$product_id
  </sql>
</query>

<query name="shopping.cart.product.create">
  <description>
  </description>
  <sql>
    INSERT INTO shopping_cart_products
    [ossweb::sql::insert_values -full t \
          { cart_id int ""
            product_id int ""
            price float ""
            quantity int 1
            promotion "" "" }]
  </sql>
</query>

<query name="shopping.cart.product.update">
  <description>
  </description>
  <sql>
    UPDATE shopping_cart_products
    SET quantity=$quantity
    WHERE cart_product_id=$cart_product_id AND
          cart_id=$cart_id
  </sql>
</query>

<query name="shopping.cart.product.delete">
  <description>
  </description>
  <sql>
    DELETE FROM shopping_cart_products 
    WHERE cart_product_id=$cart_product_id AND
          cart_id=$cart_id
  </sql>
</query>

<query name="shopping.cart.product.delete.all">
  <description>
  </description>
  <sql>
    DELETE FROM shopping_cart_products WHERE cart_id=$cart_id
  </sql>
</query>

</xql>
