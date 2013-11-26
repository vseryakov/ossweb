# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2004

ossweb::conn::callback property_add {} {

    if { [ossweb::db::exec sql:shopping.product.property.delete] ||
         [ossweb::db::exec sql:shopping.product.property.create] } {
      error "OSSWEB: Unable to add product property"
    }
    ossweb::conn::set_msg "Property has been added"
    ossweb::form form_property reset -vars t -skip product_id
}

ossweb::conn::callback property_delete {} {

    if { [ossweb::db::exec sql:shopping.product.property.delete] } {
      error "OSSWEB: Unable to delete product property"
    }
    ossweb::conn::set_msg "Property has been deleted"
    ossweb::form form_property reset -vars t -skip product_id
}

ossweb::conn::callback product_update {} {

    # Upload small icon
    if { $iconfile != "" } { set icon [lindex [split $iconfile "\\/"] end] }
    set iconpath [ns_info pageroot]/[ossweb::conn project_name]/shopping/img/$icon
    set tmpfile [ns_queryget iconfile.tmpfile]
    if { [file exists $tmpfile] && [file size $tmpfile] } {
      catch { file copy -force -- $tmpfile $iconpath }
    }
    if { ![file exists $iconpath] } { set icon "" }
    # Upload full image
    if { $imagefile != "" } { set image [lindex [split $imagefile "\\/"] end] }
    set imagepath [ns_info pageroot]/[ossweb::conn project_name]/shopping/img/$image
    set tmpfile [ns_queryget imagefile.tmpfile]
    if { [file exists $tmpfile] && [file size $tmpfile] } {
      catch { file copy -force -- $tmpfile $imagepath }
    }
    if { ![file exists $imagepath] } { set image "" }

    if { $product_id > 0 } {
      if { [ossweb::db::exec sql:shopping.product.update] } {
        error "OSSWEB: Unable to update the product"
      }
    } else {
      if { [ossweb::db::exec sql:shopping.product.create] } {
        error "OSSWEB: Unable to create the product"
      }
      set product_id [ossweb::db::currval shopping_product]
    }
    ossweb::conn::set_msg "Product updated"
}

ossweb::conn::callback product_delete {} {

    if { [ossweb::db::exec sql:shopping.product.delete] } {
      error "OSSWEB: Unable to delete the product"
    }
    ossweb::conn::set_msg "Product has been deleted"
}

ossweb::conn::callback product_edit {} {

    if { $product_id != "" && [ossweb::db::multivalue sql:shopping.product.read] } {
      error "OSSWEB: Product $product_id not found"
    }
    if { $icon != "" } {
      ossweb::widget form_product.iconfile -info "<IMG SRC=img/$icon BORDER=0>"
    }
    if { $image != "" } {
      ossweb::widget form_product.description -info "<IMG SRC=img/$image BORDER=0>"
    }
    if { $product_id != "" } {
      ossweb::db::multirow properties sql:shopping.product.property.list -eval {
        set row(delete) [ossweb::html::link -image trash.gif cmd delete.property product_id $product_id name $row(name)]
      }
    }
    ossweb::form form_product set_values
    ossweb::form form_property set_values
}

ossweb::conn::callback product_list {} {

    switch -- ${ossweb:cmd} {
     search {
       set force t
       if { $category_id != "" } { set category_id [ossweb::db::list sql:ossweb.category.subtree] }
       ossweb::form form_product set_values
       ossweb::conn::set_property SHOPPING:PROD:FILTER "" -forms form_search -global t -cache t
     }

     error {
       ossweb::form form_search set_values
       return
     }

     default {
       ossweb::conn::get_property SHOPPING:PROD:FILTER -skip page -columns t -global t -cache t
     }
    }
    ossweb::form form_search set_values
    ossweb::db::multipage products \
         sql:shopping.product.search1 \
         sql:shopping.product.search2 \
         -query [ossweb::lookup::property query] \
         -force $force \
         -page $page \
         -pagesize $pagesize \
         -eval {
      if { [ossweb::lookup::row url -id user_id -script t] } {
        set row(url) [ossweb::lookup::url cmd edit product_id $row(product_id) page $page]
      }
    }
}

ossweb::conn::callback create_form_product {} {

    ossweb::lookup::form form_product
    ossweb::form form_product -title "Product Details #$product_id"
    ossweb::widget form_product.product_id -type hidden -optional
    ossweb::widget form_product.category_id -type lookup -label Category \
         -mode 2 \
         -title_name category_name \
         -url [ossweb::html::url -app_name admin categories cmd view] \
         -map { form_product.category_id category_id form_product.category_name category_name }
    ossweb::widget form_product.product_name -type text -label Name
    ossweb::widget form_product.price -type text -label Price \
         -datatype float \
         -html { size 5 } \
         -prefix "\$"
    ossweb::widget form_product.sale_price -type text -label "Sale Price" \
         -optional \
         -datatype float \
         -html { size 5 } \
         -prefix "\$"
    ossweb::widget form_product.quantity -type text -label Quantity \
         -datatype integer \
         -html { size 5 }
    ossweb::widget form_product.start_date -type date -label "Start Date" \
         -optional \
         -format " MON / DD / YYYY" \
         -calendar
    ossweb::widget form_product.end_date -type date -label "End Date" \
         -optional \
         -format " MON / DD / YYYY" \
         -calendar
    ossweb::widget form_product.description -type textarea -label "Full Description" \
         -optional \
         -html { cols 60 rows 10 }
    ossweb::widget form_product.icin -type hidden -optional
    ossweb::widget form_product.iconfile -type file -label "Small Icon" \
         -optional
    ossweb::widget form_product.image -type hidden -optional
    ossweb::widget form_product.imagefile -type file -label "Full Image" \
         -optional
    ossweb::widget form_product.back -type button -label Back \
         -url [ossweb::html::url cmd view]
    ossweb::widget form_product.update -type submit -name cmd -label Update
    ossweb::widget form_product.delete -type submit -name cmd -label Delete \
         -html { onClick "return confirm('Record will be deleted, continue?')" }
}

ossweb::conn::callback create_form_property {} {

    ossweb::lookup::form form_property
    ossweb::form form_property -title "Product Property"
    ossweb::widget form_property.ctx -type hidden -value property -freeze
    ossweb::widget form_property.product_id -type hidden
    ossweb::widget form_property.name -type text -label Name
    ossweb::widget form_property.value -type text -label Value \
         -optional
    ossweb::widget form_property.add -type submit -name cmd -label Add
}

ossweb::conn::callback create_form_search {} {

    ossweb::lookup::form form_search
    ossweb::form form_search -title "Product Search"
    ossweb::widget form_search.product_id -type text -label ID \
         -optional \
         -html { size 10 }
    ossweb::widget form_search.product_name -type text -label Name \
         -optional \
         -html { size 15 }
    ossweb::widget form_search.description -type text -label Description \
         -optional \
         -html { size 15 }
    ossweb::widget form_search.category_id -type multiselect -label Category \
         -optional \
         -html { size 5 } \
         -options [ossweb::db::multilist sql:shopping.category.list -cache CATEGORY:LIST]
    ossweb::widget form_search.search -type submit -name cmd -label Search
    ossweb::widget form_search.reset -type reset -label Reset -clear
    ossweb::widget form_search.new -type button -label New \
         -url [ossweb::lookup::url cmd edit]
}

# Local variables
set columns { product_id int ""
              product_name "" ""
              category_id "" ""
              name "" ""
              icon "" ""
              image "" ""
              page int 1
              pagesize int 30
              force const f }

ossweb::conn::process \
     -columns $columns \
     -form_recreate t \
     -forms { form_product form_property } \
     -on_error { index.index } \
     -eval {
       error {
       }
       add.property {
         -exec { property_add }
         -next { -cmd_name edit }
         -on_error { -cmd_name edit }
       }
       delete.property {
         -exec { property_delete }
         -next { -cmd_name edit }
         -on_error { -cmd_name edit }
       }
       update {
         -exec { product_update }
         -next { -cmd_name edit }
         -on_error { -cmd_name edit }
       }
       delete {
         -exec { product_delete }
         -next { -cmd_name view }
         -on_error { -cmd_name edit }
       }
       edit {
         -exec { product_edit }
         -on_error { -cmd_name view }
       }
       default {
         -forms { form_search }
         -exec { product_list }
       }
     }
