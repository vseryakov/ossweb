# Author: Vlad Seryakov vlad@crystalballinc.com
# December 2002


ossweb::conn::callback view {} {

    ossweb::db::select youtube -type "multirow youtube" category $category -orderby "rating desc" -eval {
    }
    ossweb::widget form_yt.category -type select -label Categories \
         -options [ossweb::db::select youtube -columns "{DISTINCT category}"] \
	 -onChange "window.location='[ossweb::html::url]&category='+escape(this.value)"
}

set columns { category "" top_rated
              youtube:rowcount const 0 }

ossweb::conn::process \
     -columns $columns \
     -on_error index \
     -default view
