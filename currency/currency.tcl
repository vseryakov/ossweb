#
# Author: Alex Stetsyuk alex@tmatex.com
# Oct 2006
#
# $Id:
#
#     Managing Currencies
#

ossweb::conn::callback  currency_list {} {


  ossweb::lookup::form form_currency
  ossweb::widget form_currency.name -type text -size 15 -optional
  ossweb::widget form_currency.iso_code_alpha -type text -size 8 -optional
  ossweb::widget form_currency.iso_code_num -type text -size 8 -optional
  ossweb::widget form_currency.entity -type text -size 30 -optional
  ossweb::widget form_currency.description -type text -size 30 -optional
  ossweb::widget form_currency.search -type submit -label Search
  ossweb::widget form_currency.reset -type reset -label Reset -clear
  ossweb::widget form_currency.close -type button -label Close \
   -onClick window.close()
  
  ossweb::form form_currency get_values
  
#  ns_log Notice ---vars--- $iso_code_alpha
  ossweb::db::multirow currencies sql:currency.list.search \
  -eval {
    ossweb::lookup::row iso_code_alpha
#      ns_log Notice [array get row]
  }
    
}



ossweb::conn::callback  currency_autocomplete {} {
  # Autocomplete search of currency
  set data ""
#  ns_log Notice ----- iso alpha --- $iso_code_alpha $currency_search
  ossweb::db::foreach sql:currency.search {
    set rec "{name:'$iso_code_alpha - $name',currency_iso_alpha:'$iso_code_alpha', value:'$iso_code_alpha'}"
    lappend data $rec
  } -vars { limit 25 } -map { ' "" }
  # Stop template processing
  ossweb::adp::Exit [join $data "\n"]
  return
}

set columns { currency_id int ""
              iso_code_alpha "" ""
              name "" ""
              currency_search "" ""
            }

ossweb::conn::process -columns $columns \
          -on_error_set_cmd "" \
          -on_error { -cmd_name error } \
          -debug t \
          -eval {
            error {
            }
            accurrency {
              -exec { currency_autocomplete }
            }
            view -
            lookup -
            list -
            default {
              -exec { currency_list }
            }
          }
