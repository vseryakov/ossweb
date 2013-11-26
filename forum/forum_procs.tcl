# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2004

namespace eval forum {
  variable version {Forums version 1.3 $Revision: 3211 $}
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

proc ossweb::html::toolbar::forum {} {

    if { [ossweb::conn::check_acl -acl *.forum.msgs.view.*] } { return }
    return [ossweb::html::link -image forum.gif -status Forums -alt Forums -app_name forum msgs]
}

# Full text search provider for forum records
proc ossweb::tsearch::forum { cmd args } {

    switch -- $cmd {
     get {
       # Returns records for indexing
       set tsearch_type forum
       set tsearch_id msg_id
       set tsearch_data "forum_id||' '||topic_id"
       set tsearch_table forum_messages
       set tsearch_date create_date
       set tsearch_noupdate 1
       set tsearch_nodelete 1
       set tsearch_text body
       return [ossweb::db::multilist sql:ossweb.tsearch.template]
     }

     url {
       # Returns full url to the record
       set data [lindex $args 1]
       return [ossweb::html::url forum.msgs cmd topic forum_id [lindex $data 0] topic_id [lindex $data 1] msg_id [lindex $args 0]]
     }
    }
}

# Tracker support
proc ossweb::tracker::forum { cmd args } {

    ns_parseargs { {-limit ""} {-id ""} {-title ""} {-data ""} } $args

    switch -- $cmd {
     new {
        set topic_limit $limit
        set last_timestamp [ossweb::date parse2 [expr [ns_time]-86400*30]]
        set topic_columns { subject
                            msg_text
                            TO_CHAR(msg_timestamp,'YYYY-MM-DD HH24:MI')
                            "ROUND(EXTRACT(EPOCH FROM (NOW() - msg_timestamp)))"
                            topic_id }
        return [ossweb::db::multilist sql:forum.topic.search1]
     }

     title {
        return "Forum Posts"
     }

     url {
        return [ossweb::html::url forum.msgs cmd forum forum_id $id topic_id $data]
     }
    }
}
