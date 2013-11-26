# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2004

# Add product to the shopping cart
ossweb::conn::callback cart_add {} {

    # Add product into the cart cart
    if { $product_id == "" || [ossweb::db::multivalue sql:shopping.product.read] } {
      error "OSSWEB: Unable to add invalid product to the shopping cart"
    }
    # Check if cart record exists, create new if not
    if { [ossweb::db::multivalue sql:shopping.cart.read] } {
      ossweb::db::exec sql:shopping.cart.create
    }
    set price [ossweb::nvl $sale_price $price]
    if { [ossweb::db::exec sql:shopping.cart.product.create] } {
      error "OSSWEB: Unable to add to the shopping cart"
    }
}

# Remove product from the shopping cart
ossweb::conn::callback cart_empty {} {

    if { [ossweb::db::exec sql:shopping.cart.product.delete.all] } {
      error "OSSWEB: Unable to empty the shopping cart"
    }
}

# Remove product from the shopping cart
ossweb::conn::callback cart_delete {} {

    if { $cart_id > 0 && [ossweb::db::exec sql:shopping.cart.product.delete] } {
      error "OSSWEB: Unable to delete from the shopping cart"
    }
}

# Update shopping cart with new quantities
ossweb::conn::callback cart_update {} {

    foreach rec [ossweb::conn::query -regexp {^Q[0-9]+} -return t] {
      foreach { cart_product_id quantity } $rec {}
      set cart_product_id [string range $cart_product_id 1 end]
      if { [ossweb::util::money $quantity] <= 0 } {
        ossweb::db::exec sql:shopping.cart.product.delete
      } else {
        ossweb::db::exec sql:shopping.cart.product.update
      }
    }
}

# Show shopping cart
ossweb::conn::callback cart_edit {} {

    if { [ossweb::db::multivalue sql:shopping.cart.read] } { return }
    ossweb::db::multirow products sql:shopping.cart.product.list -eval {
      set row(delete) [ossweb::html::link -image trash.gif cmd delete cart_product_id $row(cart_product_id)]
      set row(total) [expr $row(price)*$row(quantity)]
      set row(quantity) "<INPUT TYPE=TEXT NAME=Q$row(cart_product_id) VALUE=$row(quantity) SIZE=3>"
      if { $row(icon) != "" } { set row(icon) "<IMG SRC=img/$row(icon) BORDER=0>" }
    }
}

# Checkout process
ossweb::conn::callback cart_shipping {} {

    if { [ossweb::db::value sql:shopping.cart.product.count] == 0 } {
      ossweb::conn::next -cmd_name cart
      return
    }
    ossweb::db::multivalue sql:shopping.cart.read
    ossweb::form form_shipping set_values
}

# Payment process
ossweb::conn::callback cart_billing {} {

    if { [ossweb::db::value sql:shopping.cart.product.count] == 0 } {
      ossweb::conn::next -cmd_name cart
      return
    }
    ossweb::db::exec sql:shopping.cart.update
    ossweb::db::multivalue sql:shopping.cart.read
    set shipping_address "$shipping_number $shipping_street $shipping_city $shipping_state $shipping_zip_code"
    set total [expr $total+$charge_price]
    set total [expr $total+$billing_tax]
    set total [expr $total+$shipping_price]
    # Retrieve shopping cart products and show them with total tax and shipping cost calculated
    ossweb::db::multirow products sql:shopping.cart.product.list -eval {
      set row(total) [expr $row(price)*$row(quantity)]
      set total [expr $total+$row(total)]
    }
    ossweb::form form_billing set_values
}

# Order submition
ossweb::conn::callback cart_submit {} {

    # Expiration format does not include day so we set it to 1
    set billing_card_exp [ossweb::date -set [ossweb::coalesce billing_card_exp] day 1]
    ossweb::db::exec sql:shopping.cart.update
    ossweb::db::multivalue sql:shopping.cart.read
}

# Show selected product
ossweb::conn::callback catalog_edit {} {

    if { $product_id == "" || [ossweb::db::multivalue sql:shopping.product.read] } {
      error "OSSWEB: Invalid product id specified in the request"
    }
    catalog_menu
    ossweb::conn -set title $product_name
    ossweb::db::multirow properties sql:shopping.product.property.list
}

# Catalog browser routine
ossweb::conn::callback catalog_view {} {

    catalog_menu
    # Perform multipage search
    ossweb::db::multipage products \
         sql:shopping.product.search1 \
         sql:shopping.product.search2 \
         -page $page \
         -eval {
      if { $row(icon) != "" } {
        set row(icon) [ossweb::html::link -text "<IMG SRC=img/$row(icon) BORDER=0>" cmd edit product_id $row(product_id) page $page tab $tab]
      }
      set row(url) [ossweb::html::link -text $row(product_name) cmd edit product_id $row(product_id) page $page tab $tab]
    }
}

# Category id given, build menu with subcategories and resolve all
# children under given category to show all available products
ossweb::conn::callback catalog_menu {} {

    if { $category_id == "" } { return }
    ossweb::db::foreach sql:shopping.category.list.children {
      if { $_category_id == $category_id && $_category_parent != "" } {
        ossweb::multirow append menu [ossweb::html::link -text "Up..." -alt Up category_id $_category_parent tab $tab]
      }
      ossweb::multirow append menu [ossweb::html::link -text $_category_name category_id $_category_id tab $tab]
    } -prefix _
    set category_id [ossweb::db::list sql:ossweb.category.subtree]
}

ossweb::conn::callback create_form_shipping {} {

    ossweb::form form_shipping -title "Checkout Step 1: Shipping Information"
    ossweb::widget form_shipping.cmd -type hidden -value billing -freeze
    ossweb::widget form_shipping.first_name -type text -label "First Name"
    ossweb::widget form_shipping.last_name -type text -label "Last Name"
    ossweb::widget form_shipping.email -type text -label "Email" \
         -datatype email
    ossweb::widget form_shipping.phone -type text -label "Contact Phone" \
         -datatype phone
    ossweb::widget form_shipping.shipping_address -type address -label "Shipping Address" \
         -nobuttons \
         -street_type 0 \
         -unit 0 \
         -name_prefix shipping_
    ossweb::widget form_shipping.shipping_method -type select -label "Shipping Method" \
         -options { { "Ground" Ground }
                    { "Second Day" "Second Day" }
                    { "Next Day" "Next Day" } }
    ossweb::widget form_shipping.fake1 -type inform -label "&nbsp;" -value "&nbsp;"
    ossweb::widget form_shipping.continue -type submit -label Continue
    ossweb::widget form_shipping.back -type button -label Back \
         -url [ossweb::html::url cmd cart] \
         -leftside
}

ossweb::conn::callback create_form_billing {} {

    ossweb::form form_billing -title "Checkout Step 2: Billing Information"
    ossweb::widget form_billing.billing_card_name -type text -label "Name as appears on Card"
    ossweb::widget form_billing.billing_card_num -type text -label "Number"
    ossweb::widget form_billing.billing_card_type -type select -label "Type" \
         -options { { Visa Visa }
                    { Mastercard Mastercard }
                    { Discover Discover } }
    ossweb::widget form_billing.billing_card_exp -type date -label "Expires" \
         -format "MON / YYYY"
    ossweb::widget form_billing.billing_address -type address -label "Billing Address" \
         -nobuttons \
         -street_type 0 \
         -unit 0 \
         -name_prefix billing_ \
         -freeze \
         -optional
    ossweb::widget form_billing.notes -type textarea -label "Special Instructions/notes" \
         -optional \
         -html { cols 50 rows 2 }
    ossweb::widget form_billing.submit -type submit -name cmd -label Submit \
         -help "Submit the order"
    ossweb::widget form_billing.back -type button -label Back \
         -url [ossweb::html::url cmd shipping] \
         -leftside
}

ossweb::conn::callback create_form_cart {} {

    ossweb::widget form_cart.update -type submit -name cmd -label Update \
         -help "Update quantities"
    ossweb::widget form_cart.shipping -type button -label Checkout \
         -url [ossweb::html::url cmd shipping] \
         -help "Proceed with checkout"
    ossweb::widget form_cart.empty -type button -label Empty \
         -url [ossweb::html::url cmd empty] \
         -help "Remove allitems from the shopping cart"
}

ossweb::conn::callback create_form_product {} {

    ossweb::widget form_product.buy -type button -label Buy \
         -url [ossweb::html::url cmd add product_id $product_id]
}

# Build top level form with tabs
ossweb::conn::callback create_form_tab {} {

    ossweb::widget form_tab.home -type link -label Home -value [ossweb::html::url cmd view]
    foreach rec [ossweb::db::multilist sql:shopping.category.list.top -cache CATEGORY:TOP:LIST] {
      foreach { cname cid } $rec {}
      set url [ossweb::html::url cmd view category_id $cid]
      ossweb::widget form_tab.t$cid -type link -label $cname -value $url
    }
}

# Build search form
ossweb::conn::callback create_form_search {} {

    ossweb::form form_search -title "Product Search"
    ossweb::widget form_search.product_name -type text -label Search \
         -optional \
         -html { size 10 }
    ossweb::widget form_search.search -type submit -name cmd -label Search
}

# Perform catalog initialization, cart cookies and global variables
ossweb::conn::callback catalog_init {} {

    if { [set cart_id [ossweb::conn session_id]] == "" } {
      error "OSSWEB: Catalog requires session support"
    }
    set cart_text "[ossweb::html::image cart.gif -align top] <B>View Cart</B>"
    set cart_link [ossweb::html::link -text $cart_text cmd cart]
    set checkout_text "[ossweb::html::image pay.gif -align top] <B>Checkout</B>"
    set checkout_link [ossweb::html::link -text $checkout_text cmd shipping]
    ossweb::multirow create menu title
}

# Local variables
set columns { cart_id const ""
              product_id int ""
              category_id "" ""
              cart_product_id int ""
              menu:rowcount const 0
              products:rowcount const 0
              total const 0
              tab "" home
              page int 1 }

ossweb::conn::process \
     -columns $columns \
     -forms { form_search form_tab } \
     -on_error { index.index } \
     -on_error_set_cmd "" \
     -exec { catalog_init } \
     -eval {
       error {
       }
       shipping {
         -forms { form_search form_tab form_product form_cart form_shipping }
         -exec { cart_shipping }
         -on_error { -cmd_name cart }
       }
       billing {
         -forms { form_search form_tab form_product form_shipping form_billing }
         -exec { cart_billing }
         -on_error { -cmd_name shipping }
       }
       submit {
         -forms { form_search form_tab form_product form_billing }
         -exec { cart_submit }
         -on_error { -cmd_name billing }
       }
       empty {
         -forms { form_search form_tab form_product form_cart }
         -exec { cart_empty }
         -on_error { -cmd_name edit }
         -next { -cmd_name cart }
       }
       add {
         -forms { form_search form_tab form_product form_cart }
         -exec { cart_add }
         -on_error { -cmd_name edit }
         -next { -cmd_name cart }
       }
       delete {
         -forms { form_search form_tab form_product form_cart }
         -exec { cart_delete }
         -on_error { -cmd_name edit }
         -next { -cmd_name cart }
       }
       update {
         -forms { form_search form_tab form_product form_cart }
         -exec { cart_update }
         -on_error { -cmd_name edit }
         -next { -cmd_name cart }
       }
       cart {
         -forms { form_search form_tab form_product form_cart }
         -exec { cart_edit }
         -on_error { -cmd_name view }
       }
       edit {
         -forms { form_search form_tab form_product }
         -exec { catalog_edit }
         -on_error { -cmd_name view }
       }
       default {
         -forms { form_search form_tab }
         -exec { catalog_view }
       }
     }
