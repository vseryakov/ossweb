# Author: Vlad Seryakov vlad@crystalballinc.com
# April 2001

ossweb::conn::callback parse_query {} {

    switch -glob -- $q {
     {*|*} {
       # Any word
       set tsearch_text $q
     }

     default {
       # All words
       set tsearch_text [join [split $q] " & "]
     }
    }
    # Return only allowed types or use invalid type to make search fail
    set tsearch_filter [ossweb::tsearch filters $t]
    set tsearch_type [ossweb::nvl [ossweb::tsearch types $t] None]
}

ossweb::conn::callback page {} {

    set start [clock clicks -milliseconds]
    ossweb::db::multipage result \
         sql:ossweb.tsearch.search1 \
         sql:ossweb.tsearch.search2 \
         -page $page \
         -cmd_name page \
         -query "q=[ns_urlencode $q]" \
         -eval {
      set row(tsearch_url) [ossweb::tsearch url $row(tsearch_type) $row(tsearch_id) $row(tsearch_data) $row(tsearch_value)]
      set row(tsearch_type) [ossweb::tsearch name $row(tsearch_type) $row(tsearch_id) $row(tsearch_data) $row(tsearch_value)]
      set row(tsearch_link) [ossweb::html::link -text $row(tsearch_text) -url $row(tsearch_url)]
    }
    set elapsed [expr [clock clicks -milliseconds] - $start]
    set found [ossweb::sql::multipage result -return rowcount]
}

ossweb::conn::callback search {} {

    set start [clock clicks -milliseconds]
    ossweb::db::multipage result \
         sql:ossweb.tsearch.search1 \
         sql:ossweb.tsearch.search2 \
         -page 1 \
         -force t \
         -cmd_name page \
         -query "q=[ns_urlencode $q]" \
         -eval {
      set row(tsearch_url) [ossweb::tsearch url $row(tsearch_type) $row(tsearch_id) $row(tsearch_data) $row(tsearch_value)]
      set row(tsearch_type) [ossweb::tsearch name $row(tsearch_type) $row(tsearch_id) $row(tsearch_data) $row(tsearch_value)]
      set row(tsearch_link) [ossweb::html::link -text $row(tsearch_text) -url $row(tsearch_url)]
    }
    set elapsed [expr [clock clicks -milliseconds] - $start]
    set found [ossweb::sql::multipage result -return rowcount]
}

ossweb::conn::callback rss {} {

    search
    ossweb::adp::Trim 1
    ossweb::adp::ContentType application/xhtml+xml
}

ossweb::conn::callback view {} {

}

ossweb::conn::callback create_form_search {} {

    ossweb::form form_search -method GET -tracking 0

    ossweb::widget form_search.q -type text -label "Keyword(s)" \
         -size 60 \
         -focus \
         -error "Please specify search criteria."

    ossweb::widget form_search.t -type select -label "Section(s)" \
         -empty All \
         -optional \
         -options [ossweb::tsearch sections ""]

    ossweb::widget form_search.cmd -type submit -label "Search"

}

ossweb::conn::process \
     -columns { q "" ""
                t "" ""
                page int 0
                found const 0
                elapsed const 0
                result:rowcount const 0 } \
     -exec { parse_query } \
     -forms form_search \
     -default view

