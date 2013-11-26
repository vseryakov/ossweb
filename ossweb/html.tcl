# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001
#
# $Id: html.tcl 2933 2007-01-31 15:34:14Z vlad $

# Builds project/application url, should be used for
# urls in an application instead of direct <A HREF.
#  -project_name may be used to specify different project
#  -app_name may be used to specify different application
#  -query specifies parameters string that will be appends as is
#  -list specifies list of parameters as a list object
#  -page_name should specify application context name
#  -host tells that url should include hostname as well
# other parameters may be pairs which will be formatted as query parameter
# applicaton page may be ommited in this case current page will be taken.
# Note: file extension shouldn't be specified
# Example: ossweb::html::url -app_name main -query "id=1&msg=2" users user_id 1 cmd edit
proc ossweb::html::url { args } {

    ns_parseargs { {-url ""}
                   {-path ""}
                   {-proto "http://"}
                   {-query ""}
                   {-host f}
                   {-confirm ""}
                   {-confirmtext ""}
                   {-list ""}
                   {-extension ""}
                   {-project_name ""}
                   {-app_name ""}
                   {-page_name ""}
                   {-hash ""}
                   {-popup f}
                   {-popupdnd ""}
                   {-popupsync ""}
                   {-popupname ""}
                   {-popupshow ""}
                   {-popuprefreshwin ""}
                   {-popupdata ""}
                   {-popupclasses ""}
                   {-popupposition ""}
                   {-popupfollowcursor ""}
                   {-popupdataobj ""}
                   {-popuptop ""}
                   {-popuppost ""}
                   {-popupleft ""}
                   {-popupwidth ""}
                   {-popupheight ""}
                   {-popupbgcolor ""}
                   {-popupborder ""}
                   {-popuponclose ""}
                   {-popuponstart ""}
                   {-popuponfinish ""}
                   {-popuponemptyhide ""}
                   {-popupclose ""}
                   {-popupcloseobj ""}
                   {-popupopts ""}
                   {-popupargs ""}
                   {-lookup f}
                   {-qmark t}
                   {-track f}
                   {-caller f}
                   {-ignore ""}
                   {-disable f} -- args } $args

    if { $disable == "t" || $url == "f" } { return }

    if { [expr [llength $args] % 2] } {
      set page_name [lindex $args 0]
      set args [lrange $args 1 end]
    } else {
      set page_name [ossweb::nvl $page_name [ossweb::conn page_name]]
    }
    if { $url == "" } {
      set extension [ossweb::nvl $extension [ossweb::config server:extension "oss"]]
      set app_name [ossweb::nvl $app_name [ossweb::conn app_name]]
      set project_name [ossweb::nvl $project_name [ossweb::conn project_name]]
      # Split app/command if app is given
      regexp {^([^\.]+)\.(.+)$} $app_name d app_name page_name
      # Page can include app name optionally
      regexp {^([^\.]+)\.(.+)$} $page_name d app_name page_name
      # Final url, skip all unknown pieces
      if { $project_name != "unknown" } {
        append url /$project_name
      }
      if { $app_name != "unknown" } {
        append url /$app_name
      }
      set url [ns_normalizepath $url$path/$page_name.$extension]
      if { $host == "t" } {
        set url "[ossweb::conn::hostname $proto]$url"
      } elseif { $host != "f" && $host != "" } {
        set url $proto$host$url
      }
    } else {
      # Detect url format
      switch -glob -- $url {
       "#*" -
       /* -
       http://* -
       https://* {
         # Regular url
       }

       js:* -
       javascript:* {
         # Javascript code as is
         set qmark f
       }

       default {
         # ossweb::html::url format
         set url [eval ossweb::html::url $url]
       }
      }
    }
    # Automatic request tracking
    if { $track == "t" && [set tracking_id [ossweb::conn form:track:id]] != "" } {
      lappend args form:track:id $tracking_id
    }
    switch -- $lookup {
     t {
       # Lookup mode, popup without index, remove old parameter if exists
       if { [set idx [lsearch -exact $args lookup:mode]] > -1 } {
         set args [lreplace $args $idx [incr idx]]
       }
       lappend args lookup:mode 2
     }

     q {
       # Append current lookup mode
       append query [ossweb::lookup::property query]
     }
    }
    if { $args != "" } {
      append query [ossweb::convert::list_to_query $args]
    }
    if { $list != "" } {
      append query [ossweb::convert::list_to_query $list]
    }

    # Connection global parameters
    append query [ossweb::convert::list_to_query [ossweb::conn html:query]]

    if { $caller == "t" } {
      append query "&caller=[ossweb::conn page_name]"
    }
    if { $qmark == "t" && [string first ? $url] == -1 } {
      append url "?"
    }
    # Build query parameters only if specified
    if { $query != "" } {
      if { $qmark == "t" && [string first ? $url] == -1 } {
        append url "?"
      }
      if { [string index $query 0] != "&" } {
        append url "&"
      }
      append url $query
    }
    if { $hash != "" } {
      append url "#$hash"
    }
    # Javascript link
    if { [regexp {js:|javascript:} $proto] } {
      set url "window.location='$url';"
      if { $confirm != "" || $confirmtext != "" } {
        set url "if([ossweb::decode $confirm "" "confirm('$confirmtext')" $confirm])$url"
      }
      set url "javascript:;$url"
    }
    # Convert Javascript shortcut
    if { [string match js:* $url] } {
      set url javascript:[string range $url 3 end]
    }
    # Page popup javascript
    if { $popupposition != "" } { append popupopts ",custom:popupPosition" }
    if { $popupdnd != "" } { append popupopts ",dnd:[ossweb::true $popupdnd]" }
    if { $popuponemptyhide != "" } { append popupopts ",onemptyhide:[ossweb::true $popuponemptyhide]" }
    if { $popupsync != "" } { append popupopts ",sync:[ossweb::true $popupsync]" }
    if { $popupname != "" } { append popupopts ",name:'$popupname'" }
    if { $popuprefreshwin != "" } { append popupopts ",onclose:'window.location.reload()'" }
    if { $popupclasses != "" } { append popupopts ",classes:'$popupclasses'" }
    if { $popupfollowcursor != "" } { append popupopts ",followcursor:[ossweb::true $popupfollowcursor]" }
    if { $popuponclose != "" } { append popupopts ",onclose:[ossweb::decode [regexp {^[ ]*function} $popuponclose] 1 $popuponclose '$popuponclose']" }
    if { $popuponstart != "" } { append popupopts ",onstart:[ossweb::decode [regexp {^[ ]*function} $popuponstart] 1 $popuponstart '$popuponstart']" }
    if { $popuponfinish != "" } { append popupopts ",onfinish:[ossweb::decode [regexp {^[ ]*function} $popuponfinish] 1 $popuponfinish '$popuponfinish']" }
    if { $popupclose != "" } { append popupopts ",close:1" }
    if { $popuppost != "" } { append popupopts ",post:1" }
    if { $popupdata != "" } { append popupopts ",data:'$popupdata'" }
    if { $popupdataobj != "" } { append popupopts ",dataobj:'$popupdataobj'" }
    if { $popuptop != "" } { append popupopts ",top:$popuptop" }
    if { $popupleft != "" } { append popupopts ",left:$popupleft" }
    if { $popupwidth != "" } { append popupopts ",width:'$popupwidth'" }
    if { $popupheight != "" } { append popupopts ",height:'$popupheight'" }
    if { $popupbgcolor != "" } { append popupopts ",bgcolor:'$popupbgcolor'" }
    if { $popupborder != "" } { append popupopts ",border:'$popupborder'" }
    if { $popupargs != "" } { set popupargs "+$popupargs" }
    set popupopts [string trim $popupopts ,]

    if { $popup != "f" } {
      set url "javascript:pagePopupGet('$url'$popupargs,{$popupopts});"
    }
    if { $popupshow != "" } {
      set url "javascript:popupShow('$popupshow',{$popupopts});"
    }
    if { $popupcloseobj != "" } {
       if { $popupcloseobj == "t" } {
          set popupcloseobj ""
       } else {
          set popupcloseobj "name:'$popupcloseobj'"
       }
       set url "javascript:pagePopupClose({$popupcloseobj});"
    }
    return $url
}

# Check if the given url is javascript code, returns javascript to be used
# for window url reload
proc ossweb::html::js_url { url args } {

    ns_parseargs { {-confirm ""} } $args

    if { [string index $url 0] == "/" || [regexp {^https?://} $url] } {
      set url "window.location='$url';"
      if { $confirm != "" } { set url "if($confirm)$url" }
    }
    return $url
}

# Returns url to be used for proxy requests
proc ossweb::html::proxy_url { url args } {

    ns_parseargs { {-type ""} {-rewrite f} } $args

    return [ossweb::html::url -url /ossweb:handler cmd proxy url $url type $type rewrite $rewrite]
}

# Builds A HREF HTML tag.
#  -text text inside link
#  -project_name is name of the project
#  -app_name is application name
#  -page_name is application context for url link
#  -html any html parameters/handlers for the link
#  -image name of the image inside the link
#  -path in case of image parameter to ossweb::html::image
#  -alt in case of image parameter to ossweb::html::image
#  -align in case of image parameter to ossweb::html::image
#  -url specifies the whole url to be placed inside HREF
#  -host tells that url should include hostname as well
#  -query specifies parameters string that will be appends as is
#  -width, -height image size if -image specified, if not specified,
#              default values are used which are 16x16 for icons.
#  -window specified name of the separate window where url output will go,
#                javascript open function will be called
#  -winopts window options for separate javascript window
#  -windata html to be put into open window
#  -loading to show animated loading icon during page load
#  -class specifies style sheet class to be applied
#  -href if set to f disables HREF part of the link
#  -color specifies style color for the link
#  -onClick provides javascript handler
#  -popup specifies url to be called via pagePopupGet/AJAX
#  -popupopts are the options to the pagePopupGet function
#  -acl if security check will fail, nothing will be shown
# Other parameters are just query arguments that will form url
# Example: ossweb::html::link -text Order orders id 123 type new
#          ossweb::html::link -image edit.gif -alt Edit orders order_id 132212 service_id 333
proc ossweb::html::link { args } {

    ns_parseargs { {-query ""}
                   {-url ""}
                   {-app_name ""}
                   {-project_name ""}
                   {-page_name {}}
                   {-text ""}
                   {-html ""}
                   {-image ""}
                   {-path ""}
                   {-align ""}
                   {-css ""}
                   {-alt ""}
                   {-width 16}
                   {-height 16}
                   {-class osswebLink}
                   {-host f}
                   {-window ""}
                   {-winopts ""}
                   {-winargs ""}
                   {-confirm ""}
                   {-confirmtext ""}
                   {-imgname ""}
                   {-vspace ""}
                   {-opacity ""}
                   {-hspace ""}
                   {-title ""}
                   {-disable f}
                   {-name ""}
                   {-href t}
                   {-hash ""}
                   {-proto "http://"}
                   {-color ""}
                   {-onClick ""}
                   {-status ""}
                   {-ignore f}
                   {-qmark t}
                   {-list ""}
                   {-style ""}
                   {-mouseover ""}
                   {-onMouseOver ""}
                   {-onMouseOut ""}
                   {-popup f}
                   {-popupdnd ""}
                   {-popupsync ""}
                   {-popupname ""}
                   {-popupposition ""}
                   {-popupshow ""}
                   {-popupdata ""}
                   {-popupdataobj ""}
                   {-popuptop ""}
                   {-popupclasses ""}
                   {-popupleft ""}
                   {-popupfollowcursor ""}
                   {-popupwidth ""}
                   {-popuppost ""}
                   {-popupheight ""}
                   {-popupbgcolor ""}
                   {-popupborder ""}
                   {-popuprefreshwin ""}
                   {-popupclose ""}
                   {-popuponclose ""}
                   {-popuponstart ""}
                   {-popuponfinish ""}
                   {-popupcloseobj ""}
                   {-popuponemptyhide ""}
                   {-popupopts ""}
                   {-popupargs ""}
                   {-popupover ""}
                   {-popupoveropts ""}
                   {-acl ""}
                   {-caller f}
                   {-track f}
                   {-lookup f}
                   {-loading f}
                   {-windata ""}
                   {-form_name ""}
                   {-cmd_name ""}
                   {-head ""}
                   {-foot ""}
                   {-id ""} -- args } $args

    # Security check first
    if { $acl != "" && [ossweb::conn::check_acl -acl $acl] } { return }

    if { $ignore == "t" } {
      return
    }
    if { $disable == "t" || [ossweb::conn html:link:disabled] != "" } {
      if { $text != "" } {
        return $text
      }
      if { $image != "" } {
        return [ossweb::html::image $image -name $imgname -alt $alt -path $path -align $align -width $width -height $height]
      }
      return
    }
    set url [eval ossweb::html::url -url {$url} -query {$query} -host {$host} -page_name {$page_name} -app_name {$app_name} -project_name {$project_name} -path {$path} -hash {$hash} -qmark {$qmark} -proto {$proto} -list {$list} -confirm {$confirm} -confirmtext {$confirmtext} -caller {$caller} -track {$track} -lookup {$lookup} $args]

    foreach { key val } $css {
      append style "$key:$val;"
    }
    if { $id != "" } {
      append html " ID=\"$id\""
    }
    if { $name != "" } {
      append html " NAME=\"$name\""
    }
    if { $alt != "" } {
      append html " TITLE=\"$alt\""
    }
    if { $title != "" } {
      append html " TITLE=\"$title\""
    }
    if { $class != "" } {
      append html " CLASS=$class"
    }
    if { $color != "" } {
      append style "color:$color;"
    }
    if { $style != "" } {
      append html " STYLE=\"$style\""
    }
    if { $imgname == "" } {
      set imgname [string map { . {} : {} ; {} - {} } [file tail $image]]
    }
    # Mouse over/out popup text to show
    if { $popupover != "" } {
      set id [ns_rand 1000000]
      set popupoveropts [string trimleft "$popupoveropts,parent:this" ,]
      ossweb::html::include $id -type html -mode foot -data [ossweb::html::popup_object $id $popupover]
      set onMouseOver "$onMouseOver;popupShow('$id',{$popupoveropts});"
      set onMouseOut "$onMouseOut;popupHide('$id',{$popupoveropts});"
    }
    if { $mouseover != "" && $image != "" } {
      append html " onMouseOver=\"$onMouseOver;$imgname.src='$mouseover';\" onMouseOut=\"$onMouseOut;$imgname.src='$image';\""
    } elseif { $status != "" } {
      append html " onMouseOver=\"$onMouseOver;window.status='$status';return true;\""
      if { $onMouseOut != "" } { append html " onMouseOut=\"$onMouseOut;\"" }
    } else {
      if { $onMouseOver != "" } { append html " onMouseOver=\"$onMouseOver;\"" }
      if { $onMouseOut != "" } { append html " onMouseOut=\"$onMouseOut;\"" }
    }
    set link "<A "
    # Form submission
    if { $cmd_name != "" && $form_name != "" } {
      append onClick ";document.$form_name.cmd.value='$cmd_name';document.$form_name.submit();"
    }
    # Same window url
    if { $window == "" } {
      # AJAX style of url
      if { $popupposition != "" } { append popupopts ",custom:popupPosition" }
      if { $popuponemptyhide != "" } { append popupopts ",onemptyhide:[ossweb::true $popuponemptyhide]" }
      if { $popupdnd != "" } { append popupopts ",dnd:[ossweb::true $popupdnd]" }
      if { $popupfollowcursor != "" } { append popupopts ",followcursor:[ossweb::true $popupfollowcursor]" }
      if { $popupsync != "" } { append popupopts ",sync:[ossweb::true $popupsync]" }
      if { $popupclasses != "" } { append popupopts ",classes:'$popupclasses'" }
      if { $popupname != "" } { append popupopts ",name:'$popupname'" }
      if { $popuponstart != "" } { append popupopts ",onstart:[ossweb::decode [regexp {^[ ]*function} $popuponstart] 1 $popuponstart '$popuponstart']" }
      if { $popuponfinish != "" } { append popupopts ",onfinish:[ossweb::decode [regexp {^[ ]*function} $popuponfinish] 1 $popuponfinish '$popuponfinish']" }
      if { $popuponclose != "" } { append popupopts ",onclose:[ossweb::decode [regexp {^[ ]*function} $popuponclose] 1 $popuponclose '$popuponclose']" }
      if { $popuprefreshwin != "" } { append popupopts ",onclose:'window.location.reload()'" }
      if { $popupclose != "" } { append popupopts ",close:1" }
      if { $popuppost != "" } { append popupopts ",post:1" }
      if { $popupdata != "" } { append popupopts ",data:'$popupdata'" }
      if { $popupdataobj != "" } { append popupopts ",dataobj:'$popupdataobj'" }
      if { $popuptop != "" } { append popupopts ",top:$popuptop" }
      if { $popupleft != "" } { append popupopts ",left:$popupleft" }
      if { $popupwidth != "" } { append popupopts ",width:'$popupwidth'" }
      if { $popupheight != "" } { append popupopts ",height:'$popupheight'" }
      if { $popupbgcolor != "" } { append popupopts ",bgcolor:'$popupbgcolor'" }
      if { $popupborder != "" } { append popupopts ",border:'$popupborder'" }
      if { $popupargs != "" } { set popupargs "+$popupargs" }
      set popupopts [string trim $popupopts ,]

      if { $popup != "f" } {
        set onClick "pagePopupGet('$url'$popupargs,{$popupopts});$onClick;"
        set url "javascript:;"
      }
      if { $popupshow != "" } {
        set onClick "popupShow('$popupshow',{$popupopts});$onClick;"
        set url "javascript:;"
      }
      if { $popupcloseobj != "" } {
         if { $popupcloseobj == "t" } {
            set popupcloseobj ""
         } else {
            set popupcloseobj "name:'$popupcloseobj'"
         }
         set onClick "pagePopupClose({$popupcloseobj});$onClick;"
         set url "javascript:;"
      }
      # Confirmation popup
      if { $confirm != "" || $confirmtext != "" } {
        append html " onClick=\"if(!([ossweb::decode $confirm "" "confirm('$confirmtext')" $confirm]))return false;$onClick;\""
      } elseif { $onClick != "" } {
        append html " onClick=\"$onClick;\""
      }
      if { $href == "t" && $url != "" } {
        append link "HREF=\"$url\" "
      }
      append link "$html>"
    } else {
      # HTML to be put into open window on open
      if { $winargs != "" } {
        set winargs "+$winargs"
      }
      if { $windata != "" } {
        append onClick "w=window.open('','$window','$winopts');w.focus();w.document.write('$windata');w.location='$url'$winargs;"
      } elseif { $loading == "t" } {
        append onClick "progressLoading('$url'$winargs,'$window','$winopts');"
      } else {
        append onClick ";w=window.open('$url'$winargs,'$window','$winopts');w.focus();"
      }
      if { $confirm != "" || $confirmtext != "" } {
        set onClick "if([ossweb::decode $confirm "" "confirm('$confirmtext')" $confirm]){$onClick}"
      }
      if { $href == "t" } {
        append link "HREF=\"javascript:;\" "
      }
      append link "onClick=\"$onClick\" $html>"
    }
    if { $image != "" } {
      set text [ossweb::html::image $image -name $imgname -alt $alt -path $path -align $align -width $width -height $height -hspace $hspace -vspace $vspace -opacity $opacity]
    }
    return "$head$link$text</A>$foot"
}

# Returns link to be used in online help
proc ossweb::html::help_link { title args } {

    ns_parseargs { {-image ""}
                   {-project_name "unknown"}
                   {-app_name "unknown"}
                   {-page_name "unknown"}
                   {-cmd_name "unknown"}
                   {-ctx_name "unknown"} } $args

    return [ossweb::html::link -text $title \
                 -image $image \
                 -app_name pub \
                 help \
                 project_name $project_name \
                 app_name $app_name \
                 page_name $page_name \
                 cmd_name $cmd_name \
                 ctx_name $ctx_name]
}

# Returns title with font size and color dedicated for titles
proc ossweb::html::title { title } {

    # Set global title using first specified title only,
    # as a rule it is the main title of the page.
    if { [ossweb::conn title] == "" } { ossweb::conn -set title [ns_striphtml $title] }
    return [ossweb::html::font -class osswebTitle $title]
}

# Returns title with font size and color dedicated for form titles
proc ossweb::html::form_title { title } {

    # Set global title using first specified title only,
    # as a rule it is the main title of the page.
    if { [ossweb::conn title] == "" } {
      ossweb::conn -set title $title
    }
    return [ossweb::html::font -class osswebFormTitle $title]
}

# Returns message with font size and color dedicated for messages
#  -face font face list
#  -color font color
#  -size font size
#  -type font type, defines common color/size for each particular type
#  -close if 0 do not close <FONT tag
proc ossweb::html::font { args } {

    ns_parseargs { {-type ""} {-style ""} {-html ""} {-class ""} {-color ""} {-face ""} {-size ""} {-close 1} -- msg } $args

    switch -- $type {
     column_title { set class osswebFormLabel }
    }
    if { $class != "" } { append html " CLASS=\"$class\"" }
    if { $face != "" } { append html " FACE=\"$face\"" }
    if { $size != "" } { append html " SIZE=\"$size\"" }
    if { $color != "" } { append html " COLOR=\"$color\"" }
    if { $style != "" } { append html " STYLE=\"$style\"" }
    set result "<FONT $html>$msg"
    if { $close } {
      append result "</FONT>"
    }
    return $result
}

# Builds image HTML tag
#  -path path to be added before image name
#  -alt alternative text
#  -border border size
#  -width width of the image, default 16
#  -height height of the image, default 16
#  -align aligment of the image
# Example: ossweb::html::image -path /img -alt "Edit Form" -border 0 edit.gif
proc ossweb::html::image { img args } {

    if { $img == "" } { return }

    ns_parseargs { {-path ""}
                   {-alt ""}
                   {-vspace ""}
                   {-hspace ""}
                   {-border 0}
                   {-width ""}
                   {-height ""}
                   {-align ""}
                   {-html ""}
                   {-name ""}
                   {-style ""}
                   {-opacity ""}
                   {-id ""}
                   {-mouseover ""}
                   {-mouseout ""}
                   {-onClick ""}
                   {-title ""} } $args

    if { $opacity != "" } {
      # Workaround so Firefox will not complain about not supported css property
      if { [regexp {Windows} [ns_set iget [ns_conn headers] User-Agent]] } {
        append style "filter:alpha(opacity=[expr $opacity*100]);"
      } else {
        append style "opacity:$opacity;"
      }
    }
    if { $mouseover != "" } {
      append html " onMouseOver=\"$onMouseOver;$imgname.src='$mouseover';\" onMouseOut=\"$onMouseOut;$imgname.src='$image';\""
    }
    if { $onClick != "" } {
      append html " onClick=\"$onClick;\""
    }
    if { $id != "" } { append html " ID=\"$id\" " }
    if { $name != "" } { append html " NAME=\"$name\" " }
    if { $alt != "" } { append html " ALT=\"$alt\" TITLE=\"$alt\"" }
    if { $title != "" } { append html " TITLE=\"$title\"" }
    if { $width != "" } { append html " WIDTH=\"$width\" " }
    if { $align != "" } { append html " ALIGN=\"$align\" " }
    if { $height != "" } { append html " HEIGHT=\"$height\" " }
    if { $hspace != "" } { append html " HSPACE=\"$hspace\" " }
    if { $vspace != "" } { append html " VSPACE=\"$vspace\" " }
    if { $style != "" } { append html " STYLE=\"$style\"" }
    if { ![string match http://* $img] } {
      if { $path == "" && [string index $img 0] != "/" } {
        set path [ossweb::config server:path:images "/img"]
      }
      set img [ns_normalizepath $path/$img]
    }
    return "<IMG SRC=\"[ossweb::conn server:host:images]$img\" BORDER=$border $html>"
}

# Replaces all occurences of " to &quot;
proc ossweb::html::quote { html } {

    regsub -all "\"" [ns_quotehtml $html] \\&quot\; html
    return $html
}

# Generates HTML for element <SELECT>
proc ossweb::html::select { name options values { attributes "" } } {

    set selected 0
    set multiple 0
    foreach { n v } $attributes { if { $n == "multiple" } { set multiple 1 } }
    set output "<SELECT NAME=$name [ossweb::convert::list_to_attributes $attributes]>\n"
    ossweb::convert::list_to_array $values varray
    foreach item $options {
      # First element is item name the rest are values but only first value is used in the select box
      if { [llength $item] > 1 } {
        set values [lrange $item 1 end]
      } else {
        # No second item, use label as value then
        set values [lindex $item 0]
      }
      append output " <OPTION VALUE=\"[ossweb::html::quote [lindex $values 0]]\" "
      foreach value $values {
        if { [info exists varray($value)] && (!$selected || $multiple) } {
          append output "SELECTED"
          set selected 1
          break
        }
      }
      append output ">[lindex $item 0]</OPTION>\n"
    }
    append output "</SELECT>"
    return $output
}

# Refresh current page using META tag
proc ossweb::html::refresh { interval args } {

    ns_parseargs { {-url ""} } $args

    if { $url == "" } {
      set result "<META HTTP-EQUIV=Refresh CONTENT=\"$interval\">"
    } else {
      set result "<META HTTP-EQUIV=Refresh CONTENT=\"$interval; URL=$url\">"
    }
    ossweb::conn -append html:head $result
}

# Play sound file on page refresh
proc ossweb::html::play_sound { sound } {

    ossweb::conn::set_msg "<IFRAME SRC=\"[ossweb::config server:path:sound "/snd"]/$sound\" WIDTH=1 HEIGHT=1 FRAMEBORDER=0></IFRAME>"
}


# Generates HTML for popup object to be used with popupShow/popupHide from popup.js
proc ossweb::html::popup_object { id text args } {

    ns_parseargs { {-iframe f} {-wrap t} {-html ""} } $args

    if { $wrap == "f" } {
      append html "STYLE=\"word-wrap:normal;white-space:nowrap;\""
    }
    set text "<DIV ID=\"$id\" CLASS=osswebPopupObj $html>$text</DIV>"
    if { $iframe == "t" } {
      append text "<IFRAME ID=${id}f CLASS=osswebFrameObj SRC=\"javascript:;\" FRAMEBORDER=0 SCROLLING=0></IFRAME>"
    }
    return $text
}

# Generates HTML mouse handlers to show popup object
proc ossweb::html::popup_handlers { id args } {

    ns_parseargs { {-type popup} {-popupopts ""} {-onMouseOver ""} {-onMouseOut ""} {-text ""} } $args

    switch $type {
     popup {
       if { $text != "" } {
         ossweb::html::include $id -type html -mode foot -data [ossweb::html::popup_object $id $text]
       }
       if { $popupopts != "" } {
         append popupopts ,
       }
       append popupopts "parent:this"
       return "onMouseOver=\"$onMouseOver;popupShow('$id',{$popupopts});return false\" onMouseOut=\"$onMouseOut;popupHide('$id',{delay:200})\""
     }

     menu {
       ossweb::html::include "javascript:document.onmousedown = function(){return false};"
       return "onContextMenu=\"return false\" onMouseDown=\"$onMouseOver;popupShowMenu(event,'$id')\""
     }
    }
}

# Load specified file for the web page, cache it so it will not be included more than once
proc ossweb::html::include { name args } {

    ns_parseargs { {-return f}
                   {-type js}
                   {-data ""}
                   {-basic f}
                   {-plugins ""}
                   {-styles ""}
                   {-mode head}
                   {-css "" }
                   {-class osswebPopupObj}
                   {-host {[ossweb::conn server:host:images]}} } $args

    # Shortcut for javascript inclusion
    switch -glob -- $name {
     javascript:* {
        set mode foot
        set type javascript
        set name [string range $name 11 end]
     }

     jscript:* {
        set type javascript
        set name [string range $name 8 end]
     }

     *.js {
        set type js
     }

     *.css {
        set type css
     }
    }

    # Check if incluided this already
    if { [ossweb::conn "inc:$type:$name"] != "" && $return == "f" } {
      return
    }
    ossweb::conn -set "inc:$type:$name" 1

    switch -- $type {
     jscript -
     javascript {
         set data [ossweb::nvl $data $name]
         set data "<SCRIPT LANGUAGE=JavaScript>$data</SCRIPT>\n"
         if { $return == "t" } {
           return $data
         }
         ossweb::conn -append html:$mode $data
     }

     js {
         if { ![regexp {^https?://} $name] && $host != "" } {
           set name $host$name
         }
         set data "<SCRIPT LANGUAGE=JavaScript SRC=\"$name\"></SCRIPT>\n"
         if { $return == "t" } {
           return $data
         }
         switch -- $name {
          /js/ossweb.js {
             ossweb::conn -append html:foot {<DIV ID=pagePopupObj CLASS=osswebPopupObj></DIV>}
             ossweb::conn -append html:foot {<IFRAME ID=pagePopupObjf CLASS=osswebFrameObj FRAMEBORDER=0 SCROLLING=0></IFRAME>}
             # Always as first javascript file
             ossweb::conn -set html:head "$data[ossweb::conn html:head]"
          }
          /js/ac.js {
             ossweb::conn -append html:foot {<IFRAME ID=osswebAutocompletef CLASS=osswebFrameObj FRAMEBORDER=0 SCROLLING=0></IFRAME>}
             ossweb::conn -append html:$mode $data
          }
          default {
             ossweb::conn -append html:$mode $data
          }
         }
     }

     div {
         if { $css != "" } {
           foreach { key val } $css {
             lappend styles "$key:$val"
           }
           set css "STYLE=\"[join $styles ;]\""
         }
         ossweb::conn -append html:foot "<DIV ID=$name CLASS=$class $css></DIV>"
         ossweb::conn -append html:foot "<IFRAME ID=${name}f CLASS=osswebFrameObj FRAMEBORDER=0 SCROLLING=0></IFRAME>"
     }

     iframe {
         set data "<IFRAME ID=$name NAME=$name SRC='' WIDTH=100 HEIGHT=100 FRAMEBORDER=0 BORDER=0 SCROLLING=0></IFRAME>"
         if { $return == "t" } {
           return $data
         }
         ossweb::conn -append html:foot $data
     }

     css {
         if { ![regexp {^https?://} $name] && $host != "" } {
           set name $host$name
         }
         set data "<LINK REL=STYLESHEET TYPE=text/css HREF=\"$name\">"
         if { $return == "t" } {
           return $data
         }
         ossweb::conn -append html:$mode $data
     }
     
     refresh {
         ossweb::conn -append html:head "<META HTTP-EQUIV=Refresh CONTENT=$name>"
     }

     html {
         set data [ossweb::nvl $data $name]
         ossweb::conn -append html:$mode $data
     }

     tiny_mce {
         ossweb::html::include /js/tiny_mce/tiny_mce.js
         ossweb::conn -append html:$mode $data
         if { $basic == "f" } {
           append plugins ",plugins:'table,advlink,advimage,preview,contextmenu,paste,style,emotions,insertdatetime,style'"
           append plugins ",theme_advanced_buttons2_add:'cut,copy,paste,pastetext,search,replace,preview,styleprops,insertdate,inserttime,visualchars'"
           append plugins ",theme_advanced_buttons3_add:'tablecontrols,forecolor,backcolor,emotions'"
           append plugins ",theme_advanced_toolbar_location:'top'"
           append plugins ",theme_advanced_toolbar_align:'left'"
           append plugins ",theme_advanced_resizing:true"
           append plugins ",apply_source_formatting:true"
           append plugins ",theme_advanced_statusbar_location:'bottom'"
           if { $styles != "" } {
             # Load all classes from default stylesheet
             if { $styles == "all" } {
               set styles ""
               set cssfile /css/[ossweb::conn project_name ossweb].css
               foreach line [split [ossweb::read_file [ns_info pageroot]$cssfile] "\n"] {
                 if { [regexp {^\.([^ ]+) } $line d class] } {
                   lappend styles $class $class
                 }
               }
             }
             append plugins ",content_css:'$cssfile'"
             append plugins ",theme_advanced_styles:'[ossweb::convert::list_to_attributes $styles -quote "" -delim ";"]'"
           }
         }
         if { $plugins != "" } {
           set plugins ",[string trim $plugins ,]"
         }
         switch -- $name {
          "" {
            append data "<SCRIPT LANGUAGE=JavaScript>if(window.tinyMCE)tinyMCE.init({mode:'specific_textareas',editor_selector:'osswebRichEditor',theme:'advanced' $plugins});</SCRIPT>"
          }
          default {
            append data "<SCRIPT LANGUAGE=JavaScript>if(window.tinyMCE)tinyMCE.init({mode:'exact',elements:'$name',theme:'advanced' $plugins});</SCRIPT>"
          }
         }
         if { $return == "t" } {
           return $data
         }
         ossweb::conn -append html:$mode $data
     }
    }
    return
}

# Creates table for combobox widget as html snippets that can be assigned
# to the combobox widget name_cb
proc ossweb::html::combobox_menu { name options args } {

    ns_parseargs { {-iframe f}
                   {-html ""}
                   {-separator ""}
                   {-class osswebCombobox}
                   {-class:table ""}
                   {-onKeyUp ""}
                   {-onChange ""}
                   {-onClick formComboboxSet} } $args

    if { ${class:table} == "" } { set class:table ${class}Table }

    append output "<TABLE ID=${name}_cb
                          CLASS=${class:table}
                          onMouseOut=\"ddClear(this)\"
                          onMouseOver=\"ddKeep(this)\" $html >"
    if { $options != "" } {
      foreach item $options {
        set label [lindex $item 0]
        if { [set val [lindex $item 1]] == "" } { set val $label }
        set val [string map { ' {} } $val]
        append output "<TR><TD CLASS=${class:table}1 \
                               onClick=\"${onClick}('$name','$val');$onChange;ddToggle('${name}_cb','$name',event)\" \
                               onMouseOut=\"this.className='${class:table}1'\" \
                               onMouseOver=\"this.className='${class:table}2'\">$label</TD></TR>\n"
        if { $separator != "" } {
          append output "<TR HEIGHT=1><TD><IMG SRC=$separator WIDTH=100% HEIGHT=1></TD></TR>"
        }
      }
    }
    append output "</TABLE>"
    if { $iframe == "t" } {
      append output "<IFRAME ID=${name}_cbf CLASS=osswebFrameObj SRC='javascript:;' FRAMEBORDER=0 SCROLLING=0></IFRAME>"
    }
    return $output
}

# Creates dropdown button
proc ossweb::html::dropdown_menu { name title options args } {

    ns_parseargs { {-iframe t}
                   {-html ""}
                   {-image down5.gif}
                   {-separator ""}
                   {-url "javascript:;"}
                   {-onClick ""}
                   {-onChange ""}
                   {-class osswebDropdown}
                   {-class:table ""}
                   {-class:title ""} } $args

    if { ${class:table} == "" } {
      set class:table ${class}Table
    }
    if { ${class:title} == "" } {
      set class:title ${class}Title
    }

    append output "<TABLE ID=${name}_dd
                          CLASS=${class:table}
                          onMouseOut=\"ddClear(this)\"
                          onMouseOver=\"ddKeep(this)\"
                          onClick=\"ddHide(this)\">"
    foreach item $options {
      set label [lindex $item 0]
      set val [lindex $item 1]
      # Javascript or regular url
      if { [string match "javascript:*" $val] } {
        set val [string range $val 11 end]
      } elseif { [string index $val 0] == "/" || [ossweb::datatype::url $val] == "" } {
        set val "location.href='$val'"
      }
      set val [string map { {"} {} {"} {} } $val]
      append output "<TR CLASS=${class:table}1 \
                         onClick=\"$val\" \
                         onMouseOut=\"this.className='${class:table}1'\" \
                         onMouseOver=\"this.className='${class:table}2'\"><TD>$label</TD></TR>\n"
      if { $separator != "" } {
        append output "<TR HEIGHT=1><TD><IMG SRC=$separator WIDTH=100% HEIGHT=1></TD></TR>"
      }
    }
    append output "</TABLE>"
    append output "<TABLE ID=$name
                          CLASS=${class}1 \
                          onMouseOut=\"ddHideMenu('${name}_dd',this,event)\" \
                          onMouseOver=\"ddShowMenu('${name}_dd',this,event)\" $html>\
                   <TR><TD ID={$name}_tt NOWRAP>
                       <A HREF=\"$url\" onClick=\"$onClick;ddToggle('${name}_dd','$name',event)\" CLASS=${class:title}>$title</A>\
                       <IMG SRC=/img/$image CLASS=${class}Arrow>\
                       </TD>\
                   </TR>\
                   </TABLE>\n"
    if { $iframe == "t" } {
      append output "<IFRAME ID=${name}_ddf CLASS=osswebFrameObj SRC='javascript:;' FRAMEBORDER=0 SCROLLING=0></IFRAME>"
    }
    return $output
}

# Creates list of buttons to be used as context menu, options are list of lists
# in format { { title url javascript htmlopts } ... }
proc ossweb::html::popup_menu { name options args } {

    ns_parseargs { {-html ""}
                   {-separator ""}
                   {-class osswebPopup}
                   {-class:table ""} } $args

    if { ${class:table} == "" } {
      set class:table ${class}Table
    }

    append output "<TABLE ID=${name}_pp
                          CLASS=${class:table}
                          onMouseOut=\"ddClear(this)\"
                          onMouseOver=\"ddKeep(this)\" $html>"
    if { $options != "" } {
      foreach option $options {
        append output "<TR><TD CLASS=${class:table}1 \
                               onMouseOut=\"this.className='${class:table}1'\" \
                               onMouseOver=\"this.className='${class:table}2'\" \
                               NOWRAP>" \
                      [ossweb::html::link -text [lindex $option 0] \
                            -url [lindex $option 1] \
                            -class ${class}Link \
                            -html "onClick=\"ddHide('${name}_pp');[lindex $option 2]\" [lindex $option 3]"] \
                      "</TD></TR>\n"
        if { $separator != "" } {
          append output "<TR HEIGHT=1><TD><IMG SRC=$separator WIDTH=100% HEIGHT=1></TD></TR>"
        }
      }
    }
    append output "</TABLE>\n"
    append output "<IFRAME ID=${name}_ppf CLASS=osswebFrameObj SRC='javascript:;' FRAMEBORDER=0 SCROLLING=0></IFRAME>"
    return $output
}

# Returns size of the text in pixels, approximate calculations
proc ossweb::html::textwidth { text size } {

    array set alphabet { a -4 b -4 c -4 d -4 e -4 f -5 g -4 h -4 i -8 j -5 k -4
                         l -8 m -1 n -4 o -4 p -4 q -4 r -5 s -4 t -7 u -4 v -4
                         w -1 x -4 y -4 z -4
                         A 0 B 0 C 0 D 0 E 0 F -1 G 0 H 0 I -4 J -2 K 0
                         L -1 M 0 N 0 O 0 P 0 Q 0 R 0 S 0 T -3 U 0 V 0
                         W 1 X 0 Y 0 Z 0 }
    set width 0
    for { set i 0 } { $i < [string length $text] } { incr i } {
      set c [string index $text $i]
      incr width [expr $size + [ossweb::coalesce alphabet($c) 0]]
    }
    return $width
}

# Builds global application menu by creating multirow datasource.
# This menu canbe access in templates using <multiple> tag.
# Depending on whether user is logged in or not this function
# creates public or secure application menu.
proc ossweb::html::menu { name args } {

    ns_parseargs { {-project ""}
                   {-all f}
                   {-session f}
                   {-level {[expr [info level]-1]}}
                   {-tree t}
                   {-icons t} } $args

    ossweb::multirow -level $level create $name id image title url target selected level group_id page_name
    # Create menu only if logged in
    if { $session == "t" && [ossweb::conn session_id] == "" } {
      return
    }
    set appName [ossweb::conn app_name]
    set appContext [ossweb::conn page_name]
    set apps apps_$appName
    # For unknown projects use default directory
    set projectName [ossweb::decode [ossweb::nvl $project [ossweb::conn project_name]] \
                          "unknown" [ossweb::config server:project "unknown"]]
    # Current menu items state
    set menuState [ossweb::conn::get_property menuState -global t -cache t]
    # Multirow uses global adp::level frame by default, so
    # we should specify to query where to put new datasource.
    ossweb::db::multirow $apps sql:ossweb.apps.list -cache t -timeout 86400

    for { set i 1 } { $i <= [ossweb::multirow size $apps] } { incr i } {
       ossweb::multirow local $apps $i
       if { $project_name == "*" } { set project_name $projectName }
       # Check access restrictions for each menu item
       if { ($project_name != "*" && $project_name != $projectName) ||
            [ossweb::conn::check_acl -acl "$project_name.$app_name.$page_name"] } {
         set closed($app_id) 1
         continue
       }
       if { $condition != "" } {
        eval "if { $condition } { set condition {} }"
        if { $condition != "" } {
          continue
        }
       }
       # Check access permissions for each menu item
       # Skip this item if it is inside closed folder
       if { $all == "f" && [info exists closed($group_id)] } {
         set closed($app_id) 1
         continue
       }
       set selected 0
       set indent [expr [llength [split $tree_path "/"]] - 3]
       set image [ossweb::html::image [ossweb::nvl $image link.gif] -align absbottom]
       if { $page_name != "" } {
         # Standard application menu item
         set url [ossweb::html::url -host $host_name -project_name $project_name -app_name $app_name -path $path -query $url $page_name]
       } else {
         # Build menu item from user supplied url
         if { $url != "" } {
           set url "$path$url"
         } else {
           set url ""
         }
       }
       if { $url != "" } {
         # Menu item higlighting
         if { $project_name == $projectName && $app_name == $appName && $page_name == $appContext } {
           set selected 1
         }
       } else {
         # Check config property where we have all opened folder ids
         if { $tree == "t" } {
           if { [string first ":$app_id;" $menuState] == -1 } {
             set closed($app_id) 1
             set cmd Open
           } else {
             set cmd Close
             # Support for two predefined icons for open/close folders
             if { [string first "closed.gif" $image] > 0 } {
               set image [ossweb::html::image open.gif]
             }
           }
           # Url/image for folder with open/close commands
           set url [ossweb::html::url -project_name $projectName -app_name admin apps cmd $cmd app_id $app_id]
         }
       }
       if { $tree == "t" } {
         set image "[string repeat [ossweb::html::image b.gif] $indent]$image"
       }
       if { $icons == "f" } {
         set image ""
       }
       ossweb::multirow -level $level append $name $app_id $image $title $url $target $selected $indent $group_id $page_name
    }
    return
}

# Generates structure to be used with util_menu_generate which builds Javascript
# pulldown menus. Returns Tcl list.
proc ossweb::html::menu::js { name args } {

    ns_parseargs { {-font_size 12}
                   {-images 1}
                   {-spacing 1}
                   {-tclass osswebMenuText}
                   {-oclass osswebMenuTextSelected}
                   {-bclass osswebMenuBorder}
                   {-x 0}
                   {-y 0}
                   {-parent ""}
                   {-height 18} } $args

    set projectName [ossweb::decode [ossweb::conn project_name] \
                                    "unknown" \
                                    [ossweb::config server:project "unknown"]]
    set items [list]
    set folder_seq 0
    set menu ""

    ossweb::db::multirow $name sql:ossweb.apps.list -cache t -timeout 86400

    for { set i 1 } { $i <= [ossweb::multirow size $name] } { incr i } {
      ossweb::multirow local $name $i
      # Check access restrictions for each menu item
      if { $project_name == "*" } { set project_name $projectName }
      if { ($project_name != "*" && $project_name != $projectName) ||
           [ossweb::conn::check_acl -acl "$project_name.$app_name.$page_name"] == -1 } {
        continue
      }
      if { $condition != "" } {
        eval "if { $condition } { set condition {} }"
        if { $condition != "" } {
          continue
        }
      }
      set level [expr [llength [split $tree_path "/"]] - 3]

      if { $page_name != "" } {
        # Standard application menu item
        set url [ossweb::html::url \
                      -host $host_name \
                      -project_name $project_name \
                      -app_name $app_name \
                      -path $path \
                      -query $url $page_name]
      } else {
        # Build menu item from user supplied url
        if { $url != "" } {
          set url "$path$url"
        }
      }
      if { $group_id != "" && ![info exists _folder($group_id)] } {
        continue
      }
      set folder_id [ossweb::coalesce _folder($group_id) 0]
      set item_id [ossweb::coalesce _item($group_id) 1]
      if { $url == "" } {
        incr folder_seq
        lappend items $folder_id $item_id $title $url $folder_seq $level $group_id $image
        set _folder($app_id) $folder_seq
        set _parent($folder_seq) $folder_id
      } else {
        lappend items $folder_id $item_id $title $url 0 $level $group_id $image
      }
      set _item($group_id) [expr $item_id+1]
      # Calculate max title length, FONT SIZE is 12pt
      set len [ossweb::html::textwidth $title $font_size]
      set len1 [ossweb::coalesce _max($folder_id) 0]
      if { $len > $len1 } {
        set _max($folder_id) $len
      }
    }
    foreach { folder_id item_id title url parent_id level group_id image } $items {
      if { $item_id == 1 && $folder_id > 0 } {
        append menu "menu\[$folder_id\] = new Array();\n"
        append menu "menu\[$folder_id\]\[0\] = new Menu(true,'>',[expr ($level>1?$_max($_parent($folder_id)):0)],[expr $height+($level>1?-20:5)],$_max($folder_id),$spacing,'$tclass','$oclass','$bclass',$images);\n"
      }
      set len [expr (!$level?[expr 10+[ossweb::html::textwidth $title $font_size]]:20)]
      append menu "menu\[$folder_id\]\[$item_id\] = new menuItem('$title','$url','',$len,$spacing,$parent_id,'$image');\n"
    }
    set menu "
    <SCRIPT LANGUAGE=JavaScript SRC=/js/menu.js></SCRIPT>\n
    <SCRIPT LANGUAGE=JavaScript>\n
    var menu = new Array\();\n
    menu\[0\] = new Array();\n
    menu\[0\]\[0\] = new Menu(false,'',$x,$y,$height,0,'$tclass','$oclass','',$images,'$parent');\n
    $menu
    </SCRIPT>\n"
    return $menu
}

# Generates menu links for admin panel
proc ossweb::html::menu::admin { args } {

    if { [ossweb::conn app_name] != "admin" } { return }

    ns_parseargs { {-ignore {^help$|index|reftable}} {-table f} {-class osswebMenuAdmin} } $args

    foreach name [lsort [glob -nocomplain [ns_info pageroot]/[ossweb::conn project_name]/admin/*.tcl]] {
      set name [file rootname [file tail $name]]
      if { [regexp $ignore $name] } { continue }
      lappend result [ossweb::html::link -text [string totitle $name] -app_name admin -class $class $name]
    }
    if { $table == "t" } {
      set result "<DIV ALIGN=RIGHT CLASS=$class>[join $result " | "]</DIV><P>"
    }
    return $result
}

# Returns the list with all files starting from the given path and
# including files from each subdirectory as well.
# Returns only those files that matches specified regular expression.
proc ossweb::html::files { path match { subdir "" } } {

    set files [list]
    if { $subdir == "" } {
      lappend files { None {} }
      set dir "$path/"
    } else {
      set dir "$path/$subdir/"
    }
    # Get all possible images
    foreach file [lsort [glob -nocomplain -types {d f r} -path $dir *]] {
      if { [file isdirectory $file] } {
        foreach name [::ossweb::html::files $path $match [file tail $file]] {
          lappend files $name
        }
      } else {
        set name [file tail $file]
        if { ![regexp $match $name] } {
          continue
        }
        if { $subdir != "" } {
          set name "$subdir/$name"
        }
        lappend files [list $name $name]
      }
    }
    return $files
}

# Return the list with all images from server's image directory
proc ossweb::html::images { { path "" } } {

    return [ossweb::html::files "[ns_info pageroot]/[ossweb::config server:path:images img]" "\.gif$|\.jpg$|\.png$" $path]
}

# Return the list with all sound .wav files
proc ossweb::html::sounds { { path "" } } {

    return [ossweb::html::files "[ns_info pageroot]/[ossweb::config server:path:sound snd]" "\.wav$" $path]
}

proc ossweb::html::escape { url args } {

    ns_parseargs { {-part path} } $args

    return [string map { ' %27 } [ns_urlencode -part $part $url]]
}
