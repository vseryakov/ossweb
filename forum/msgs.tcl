# Author: Vlad Seryakov vlad@crystalballinc.com
# March 2004

ossweb::conn::callback send_email {} {

    # Send email notifications
    if { [set user_name [ossweb::conn full_name $user_name]] != "" } {
      set body "From: $user_name<P>$body"
    }
    # Link to the forums
    if { [set url [ossweb::config forum:url]] != "" } {
      append url &cmd=topic&forum_id=$forum_id&topic_id=$topic_id#$msg_id
      if { ![ossweb::true $richtext] } {
        set body [string map { "\n" "<BR>" } $body]
      }
      set body "Link: [ossweb::html::link -text $url -url $url]<P>$body"
    }
    if { $subject == "" } {
      ossweb::db::multivalue sql:forum.topic.read
    }
    # Send to all subscribers
    foreach email [ossweb::db::list sql:forum.email.list] {
      ossweb::sendmail $email support "$prefix: $forum_name: $subject" $body \
           -content_type text/html
    }
}

ossweb::conn::callback topic_action {} {

    if { [ossweb::db::multilist sql:forum.read] == "" } {
      error "OSSWEB: Unable to access forum record"
    }
    # Format message into HTML
    #set body [ossweb::util::wrap_text [string trim $body]]
    regsub -all -nocase {<SCRIPT|</SCRIPT|<IFRAME|</IFRAME>|<FRAME|<EMBED} $body {} body
    switch -exact ${ossweb:cmd} {
     update {
       if { [ossweb::conn::check_acl -acl $forum_acl] } {
         error "OSS: Access denied"
       }
       set body [string trim $body " \r\n\t"]
       if { [ossweb::db::exec sql:forum.message.update] } {
         error "OSSWEB: Unable to post a message"
       }
       ossweb::conn::set_msg "Message has been updated"
       return
     }

     delete {
       if { [ossweb::conn::check_acl -acl $forum_acl] } {
         error "OSSWEB: Access denied"
       }
       set body ""
       set hidden_flag t
       if { $msg_id != "" } {
         if { [ossweb::db::exec sql:forum.message.delete] } {
           error "OSSWEB: Unable to post a message"
         }
         ossweb::conn::set_msg "Message has been deleted"
       } elseif { $topic_id != "" } {
         if { [ossweb::db::exec sql:forum.topic.delete] } {
           error "OSSWEB: Unable to post a message"
         }
         ossweb::conn::set_msg "Topic has been deleted"
         ossweb::conn::next -cmd_name forum
       }
       ossweb::sql::multipage topics -flush t
     }

     post {
       if { $editable != "t" } {
         error "OSSWEB: No permissions to post new messages"
       }
       ossweb::db::begin
       if { $topic_id == "" } {
         if { [ossweb::db::exec sql:forum.topic.create] } {
           error "OSSWEB: Unable to post a message"
         }
         set topic_id [ossweb::db::currval forum_topic]
       }
       if { ![ossweb::true $richtext] } {
         set body [string trim $body " \r\n\t"]
       }
       if { [ossweb::db::exec sql:forum.message.create] } {
         error "OSSWEB: Unable to post a message"
       }
       set msg_id [ossweb::db::currval forum_msg]
       ossweb::db::commit
       ossweb::conn::set_msg "Message has been posted"
       ossweb::sql::multipage topics -flush t
       # Send email notifications
       send_email
     }

     reply {
       if { [ossweb::db::exec sql:forum.message.create] } {
         error "OSSWEB: Unable to post a message"
       }
       set msg_id [ossweb::db::currval forum_msg]
       ossweb::conn::set_msg "Message has been posted"
       # Send email notifications
       send_email
       set msg_parent ""
     }
    }
    set body ""
}

ossweb::conn::callback topic_edit {} {

    if { [ossweb::db::multivalue sql:forum.read] } {
      error "OSSWEB: Unable to access forum record"
    }
    if { $topic_id != "" } {
      ossweb::db::multivalue sql:forum.topic.read
      switch -- ${ossweb:ctx} {
       reply {
         set message_limit 1
         ossweb::db::foreach sql:forum.message.list {
           if { ![ossweb::true $richtext] } {
             set body [string map { "\n" "<BR>" } $body]
           }
           ossweb::widget form_reply.info \
                -value $body \
                -css { font-size 7pt }
         }
       }

       update {
         if { [ossweb::conn::check_acl -acl $forum_acl] } {
           error "OSSWEB: Access denied"
         }
         ossweb::db::multivalue sql:forum.message.read
         ossweb::widget form_post.msg_id -type hidden -optional
         ossweb::widget form_post.cmd -type submit -label Update
         ossweb::form form_post set_values
       }
      }
    }
}

ossweb::conn::callback topic_view {} {

    if { [ossweb::db::multilist sql:forum.read] == "" } {
      error "OSSWEB: Unable to access forum record"
    }
    # Save last time we accessed any topic
    ossweb::conn::set_property FORUM:TIMESTAMP [ns_time] -global t -cache t
    # Forum details
    ossweb::db::multivalue sql:forum.topic.read
    # All messages
    ossweb::db::multirow msgs sql:forum.message.list -eval {
      set row(url) [ossweb::html::url -hash $row(msg_id) cmd topic forum_id $forum_id topic_id $topic_id]
      set row(user_name) [lindex $row(user_name) 0]
      set row(action) [ossweb::html::link -text Reply -title Reply -class forumLink cmd edit.reply msg_parent $row(msg_id) topic_id $topic_id forum_id $forum_id]
      if { ![ossweb::conn::check_acl -acl $forum_acl] } {
        append row(action) " | " [ossweb::html::link -text Edit -title Edit -class forumLink cmd edit.update msg_id $row(msg_id) topic_id $topic_id forum_id $forum_id]
        append row(action) " | " [ossweb::html::link -text Delete -class forumLink -confirm "confirm('Are you sure?')" cmd delete msg_id $row(msg_id) topic_id $topic_id forum_id $forum_id]
      }
      if { ![ossweb::true $richtext] } {
        set row(body) [string map { "\n" "<BR>" } $row(body)]
      }
      set row(padding) 5
      if { $row(msg_parent) != "" } {
        if { $parent != $row(msg_parent) } {
          set row(padding) [expr [llength [split $row(tree_path) /]]*5]
          set parent $row(msg_parent)
        }
      }
    }
    ossweb::widget form_forum.body -value ""
}

ossweb::conn::callback forum_unsubscribe {} {

    if { [ossweb::db::exec sql:forum.email.unsubscribe] } {
      error "OSSWEB: Unable to unsubscribe"
    }
    ossweb::conn::set_msg "$email has been unsubscribed"
}

ossweb::conn::callback forum_subscribe {} {

    # Spammer attack check
    set ipaddr [ns_conn peeraddr]
    if { ![nsv_exists forum:sub $ipaddr] } {
      nsv_set forum:sub $ipaddr 0
    }
    if { [nsv_incr forum:sub $ipaddr] > 2 } {
      error "OSSWEB: Too many subscribtions"
    }
    if { [llength [split $email ,]] > 1 } {
      error "OSSWEB: Only one email allowed"
    }
    if { [ossweb::db::exec sql:forum.email.subscribe] } {
      error "OSSWEB: Unable to subscribe"
    }
    ossweb::conn::set_msg "$email has been subscribed"
}

ossweb::conn::callback forum_sub {} {

    if { [ossweb::db::multivalue sql:forum.read] } {
      error "OSSWEB: Invalid forum id"
    }
    ossweb::form form_subscribe -title "Subscribe/unsubscribe yourself for receiving email notification every time a message is posted into the $forum_name"
}

ossweb::conn::callback forum_view {} {

    if { [ossweb::db::multivalue sql:forum.read] } {
      error "OSSWEB: Unable to read forum topics"
    }
    switch -- ${ossweb:ctx} {
     unseen {
       # Unseen since last forums access
       set last_timestamp [ossweb::date parse2 [ossweb::conn::get_property FORUM:TIMESTAMP -global t]]
       # Back to all messages
       ossweb::widget form_forum.top -url "cmd forum forum_id $forum_id"
     }
     recent {
       # Last 3 days
       set last_timestamp [ossweb::date parse2 [expr [ns_time]-86400*7]]
       # Back to all messages
       ossweb::widget form_forum.top -url "cmd forum forum_id $forum_id"
     }
    }
    ossweb::db::multipage topics \
         sql:forum.topic.search1 \
         sql:forum.topic.search2 \
         -cmd_name forum \
         -page $page \
         -query "forum_id=$forum_id" \
         -eval {
      set row(url) [ossweb::html::url cmd topic forum_id $forum_id topic_id $row(topic_id)]
      set row(link) [ossweb::html::link -text $row(subject) -url $row(url)]
      set row(user_name) [lindex $row(user_name) 0]
      set row(action) ""
      if { ![ossweb::conn::check_acl -acl $forum_acl] } {
        set row(action) [ossweb::html::link -text {Delete} -class forumLink -confirm "confirm('Are you sure?')" -class osswebSmallText cmd delete topic_id $row(topic_id) forum_id $forum_id]
      }
    }
    ossweb::widget form_forum.body -value ""
}

ossweb::conn::callback forum_search {} {

    switch -- ${ossweb:ctx} {
     unseen {
       # Unseen since last forums access
       set last_timestamp [ossweb::date parse2 [ossweb::conn::get_property FORUM:TIMESTAMP -global t]]
       ossweb::db::multipage topics \
            sql:forum.topic.search1 \
            sql:forum.topic.search2 \
            -pagesize 999 \
            -eval {
         set row(url) [ossweb::html::url cmd topic forum_id $row(forum_id) topic_id $row(topic_id)]
         set row(link) [ossweb::html::link -text $row(subject) -url $row(url)]
       }
     }

     recent {
       # Last 7 days
       set last_timestamp [ossweb::date parse2 [expr [ns_time]-86400*7]]
       ossweb::db::multipage topics \
            sql:forum.topic.search1 \
            sql:forum.topic.search2 \
            -pagesize 999 \
            -eval {
         set row(url) [ossweb::html::url cmd topic forum_id $row(forum_id) topic_id $row(topic_id)]
         set row(link) [ossweb::html::link -text $row(subject) -url $row(url)]
       }
     }

     default {
       if { $body == "" } {
         ossweb::conn::set_msg -color red "Please, specify search condition"
         ossweb::conn::next cmd [ossweb::decode $forum_id "" view forum]
         return
       }
       # Forum global search
       ossweb::db::multipage topics \
            sql:forum.search1 \
            sql:forum.search2 \
            -pagesize 999 \
            -eval {
         set row(url) [ossweb::html::url -hash $row(msg_id) cmd topic forum_id $row(forum_id) topic_id $row(topic_id)]
         set row(link) [ossweb::html::link -text $row(subject) -url $row(url)]
       }
     }
    }
}

ossweb::conn::callback forum_list {} {

    ossweb::db::multirow forums sql:forum.list.available -eval {
      set row(forum_name) [ossweb::html::link -text $row(forum_name) cmd forum forum_id $row(forum_id)]
    }
}

ossweb::conn::callback forum_init {} {

    set html_url [ossweb::conn::hostname][ossweb::conn -url -skip format]
    set rss_link [ossweb::html::link -image feed.png -url [ossweb::conn -url] format rss]

    switch -- $format {
     rss {
        ossweb::adp::Trim 1
        ossweb::adp::ContentType application/xhtml+xml
     }
    }
    # Read access rights
    if { $forum_id != "" && [ossweb::db::value sql:forum.read -vars {forum_access w}] == "" } {
      set editable f
    }
}

ossweb::conn::callback create_form_post {} {

    ossweb::widget form_post.forum_id -type hidden

    ossweb::widget form_post.topic_id -type hidden -optional

    ossweb::widget form_post.subject -type text -label "Subject" \
         -size 60

    ossweb::widget form_post.body -type textarea -label "Message" \
         -cols 80 \
         -rows 20

    if { [ossweb::true $richtext] } {
      ossweb::widget form_post.body -rich
    }

    if { [ossweb::conn user_id] == "" } {
      ossweb::widget form_post.user_name -type text -label "Your Name or Email"
    }

    ossweb::widget form_post.forum -type button -label "Back" \
         -url "cmd forum forum_id {$forum_id}"

    ossweb::widget form_post.cmd -type submit -label Post
}

ossweb::conn::callback create_form_reply {} {

    ossweb::widget form_reply.ctx -type hidden -value reply -freeze

    ossweb::widget form_reply.forum_id -type hidden

    ossweb::widget form_reply.topic_id -type hidden

    ossweb::widget form_reply.msg_parent -type hidden -optional

    ossweb::widget form_reply.info -type inform -label "&nbsp;" \
         -no_label \
         -class_row forumQuote

    ossweb::widget form_reply.body -type textarea -label "&nbsp;" \
         -no_label \
         -cols 80 \
         -rows 20

    if { [ossweb::true $richtext] } {
      ossweb::widget form_reply.body -rich
    }

    if { [ossweb::conn user_id] == "" } {
      ossweb::widget form_reply.user_name -type text -label "Your Name or Email"
    }

    ossweb::widget form_reply.forum -type button -label "Back" \
         -url "cmd topic forum_id {$forum_id} topic_id {$topic_id}"

    ossweb::widget form_reply.cmd -type submit -label Reply
}

ossweb::conn::callback create_form_forum {} {

    ossweb::form form_forum -cmd search

    ossweb::widget form_forum.forum_id -type hidden -optional

    ossweb::widget form_forum.body -type text -label "Text" \
         -optional \
         -size 20

    ossweb::widget form_forum.search -type submit -label "Search"

    ossweb::widget form_forum.top -type button -label "Back" \
         -url "cmd view"

    ossweb::widget form_forum.forum -type button -label "Back" \
         -url "cmd forum forum_id {$forum_id}"

    ossweb::widget form_forum.topic -type button -label "Back" \
         -url "cmd topic forum_id {$forum_id} topic_id {$topic_id}"

    ossweb::widget form_forum.unseen -type button -label "View Unseen Posts" \
         -url "cmd forum.unseen forum_id {$forum_id}"

    ossweb::widget form_forum.recent -type button -label "View Recent Posts" \
         -url "cmd forum.recent forum_id {$forum_id}"

    ossweb::widget form_forum.sub -type button -label "Subscribe/Unsubscribe" \
         -url "cmd sub forum_id {$forum_id}"

    ossweb::widget form_forum.reply -type button -label "Post a Reply" \
         -url "cmd edit.reply forum_id $forum_id topic_id {$topic_id}"

    if { $editable == "t" } {
      ossweb::widget form_forum.post -type button -label "Post a New Message" \
           -url "cmd edit forum_id {$forum_id}"
    }
}

ossweb::conn::callback create_form_search {} {

    ossweb::form form_search -cmd search -method GET

    ossweb::widget form_search.body -type text -label "Text" \
         -optional \
         -size 20

    ossweb::widget form_search.search -type submit -label "Search"

    ossweb::widget form_search.top -type button -label "Back" \
         -url "cmd view"

    ossweb::widget form_search.unseen -type button -label "View Unseen Posts" \
         -url "cmd search.unseen"

    ossweb::widget form_search.recent -type button -label "View Recent Posts" \
         -url "cmd search.recent"
}

ossweb::conn::callback create_form_subscribe {} {

    ossweb::widget form_subscribe.forum_id -type hidden -optional

    ossweb::widget form_subscribe.email -type text -label "Your Email" -datatype email

    ossweb::widget form_subscribe.subscribe -type submit -name cmd -label Subscribe

    ossweb::widget form_subscribe.unsubscribe -type submit -name cmd -label Unsubscribe

    ossweb::widget form_subscribe.forum -type button -label "Back" \
         -url "cmd forum forum_id {$forum_id}"
}

set columns { forum_id int ""
              forum_name "" ""
              topic_id ilist ""
              msg_id ilist ""
              msg_parent int ""
              subject "" ""
              body "" ""
              email "" ""
              options "" ""
              user_name "" ""
              format "" ""
              page int 1
              parent const ""
              editable const t
              richtext const {[ossweb::config forum:richtext 1]}
              forum_acl const *.*.*.*.*
              prefix const {[ossweb::config forum:prefix OSSWEB]}
              user_id const {[ossweb::conn user_id]} }

ossweb::conn::process \
             -columns $columns \
             -forms { form_search form_forum form_post form_reply } \
             -form_recreate t \
             -on_error { index.index } \
             -exec { forum_init } \
             -eval {
               unsubscribe {
                 -validate { { forum_id int } }
                 -exec { forum_unsubscribe }
                 -on_error { -cmd_name sub }
                 -next { -cmd_name forum }
               }
               subscribe {
                 -validate { { forum_id int } }
                 -exec { forum_subscribe }
                 -on_error { -cmd_name sub }
                 -next { -cmd_name forum }
               }
               update -
               delete -
               reply -
               post {
                 -validate { { forum_id int } }
                 -exec { topic_action }
                 -next { -cmd_name topic }
                 -on_error { -cmd_name topic -ctx_name edit }
               }
               edit.msg {
                 -validate { { forum_id int } }
                 -exec { msg_edit }
                 -on_error { -cmd_name topic -ctx_name view }
               }
               edit {
                 -validate { { forum_id int } }
                 -exec { topic_edit }
                 -on_error { -cmd_name topic -ctx_name view }
               }
               topic {
                 -validate { { forum_id int } { topic_id int } }
                 -exec { topic_view }
                 -on_error { -cmd_name forum }
               }
               forum {
                 -validate { { forum_id int } }
                 -exec { forum_view }
                 -on_error { -cmd_name view }
               }
               sub {
                 -validate { { forum_id int } }
                 -forms { form_subscribe }
                 -exec { forum_sub }
                 -on_error { -cmd_name view }
               }
               error {
               }
               search {
                 -exec { forum_search }
                 -on_error { -cmd_name view }
               }
               default {
                 -exec { forum_list }
                 -on_error { -cmd_name view }
               }
             }

