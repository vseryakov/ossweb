<!-- 
  Author: Alex Stetsyuk alex@tmatex.com
  Oct 2006

$Id:

-->

<xql>

<query name="currency.search">
  <description>
  Used for autocomplete
  </description>
  <sql>
    SELECT DISTINCT name,
           iso_code_alpha
    FROM currencies
    WHERE disabled = 'f'
    [ossweb::sql::filter \
          { currency_search Text "" } \
          -map {
            currency_search "(iso_code_alpha ILIKE %value OR name ILIKE %value)"
          } \
          -before AND]
    ORDER BY name
    LIMIT [ossweb::coalesce limit 99]
  </sql>
</query>


<query name="currency.list.search">
  <description>
  List of currencies for lookup
  </description>
  <sql>
    SELECT name,
           iso_code_alpha,
           iso_code_num,
           symbol_html,
           description,
           entity,
           currency_get_entity_for_iso_alpha2(iso_code_alpha) AS entities
    FROM   currencies
           WHERE disabled = 'f' AND currency_id IN
             (SELECT currency_get_id_for_iso_alpha(iso_code_alpha) AS currency_id
               WHERE iso_code_alpha IN
                 (SELECT DISTINCT iso_code_alpha
                  FROM currencies))
            [ossweb::sql::filter \
                    { currency_id ilist {}
                      name Text {}
                      iso_code_alpha Text {}
                      iso_code_num Text {}
                      description Text {}
                      entity Text {} 
                    } \
             -map {
               entity "currency_get_entity_for_iso_alpha2(iso_code_alpha) ILIKE %value"
             } \
             -before AND ]
    ORDER  BY name
  </sql>
</query>

</xql>