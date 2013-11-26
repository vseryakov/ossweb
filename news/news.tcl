# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2002


ossweb::conn::callback view {} {

    ossweb::db::multirow news sql:news.read
}

ossweb::conn::callback create_form_news {} {

    ossweb::widget form_news.refresh -type submit -name cmd -label Refresh
}

set columns { category const ""
              news:rowcount const 0 }

ossweb::conn::process \
     -columns $columns \
     -forms form_news \
     -on_error index \
     -default view
