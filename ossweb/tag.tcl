# Author: Vlad Seryakov vlad@crystalballinc.com
# August 2001
#
# $Id: tag.tcl 2927 2007-01-31 00:07:29Z vlad $

# Information proc
proc ossweb::tag::info { type } {

    switch -- $type {
     border {
        # Return all supported styles
        return "none class div shadow curved curved2 curved3 curved4 curved5 curved6 white gray table"
     }

     formtab {
        # all supported styles
        return "blue text ebay square oval oval2 default"
     }
    }
}

# Generic wrapper for registered tag handlers.
proc ossweb::tag::create { name args body } {

    if { [llength $args] == 2 } {
      set chunk chunk
      set endtag /$name
    } else {
      set chunk ""
      set endtag ""
    }
    eval "
    proc tag_$name { $chunk params } {
        set data \[ns_adp_dump\]
        regsub -all {\[\]\[\"\\\$\]} \$data {\\\\&} data
        ossweb::adp::AppendData \$data
        ns_adp_trunc
        $body
        return {}
    }
    ns_register_adptag $name $endtag ossweb::tag::tag_$name"
}

if { [ns_config ns/server/[ns_info server]/ossweb DisableFilters] == 1 } {
  return
}

# Common proc for rows
proc ossweb::tag::rowtag { chunk params type } {

   set class [ns_set iget $params class]
   set type [ns_set iget $params type $type]
   set skip_tags [ns_set iget $params skip]
   lappend skip_tags type class underline onmouseoverclass url html open skip
   set tag ""
   set code ""
   # Setup coor for each row type
   switch -exact $type {
     first {
       append code "ossweb::conn -set table_row:color_index 1"
       append tag "CLASS=\[ossweb::nvl $class osswebFirstRow\] "
     }
     section {
       append tag "CLASS=\[ossweb::nvl $class osswebSectionRow\] "
     }
     last {
       append tag "CLASS=\[ossweb::nvl $class osswebLastRow\] "
     }
     row {
       if { $class == "" } {
         set class "osswebRow\$index"
         append code "set index \[ossweb::nvl \[ossweb::conn table_row:color_index\] 1\]\n"
         append code "ossweb::conn -set table_row:color_index \[expr 3-\$index\]"
         append tag "CLASS=$class "
       } else {
         append tag "CLASS=$class "
       }
       set onOver [ns_set iget $params onMouseOverClass]
       if { $onOver != "" } {
         append tag "onMouseOver=\\\"this.className='$onOver'\\\" onMouseOut=\\\"this.className='$class'\\\" "
       }
       set url [ns_set iget $params url]
       if { $url != "" } {
         append tag "onClick=\\\"\[ossweb::html::js_url $url\]\\\" "
       }
     }
     plain {
     }
   }
   ossweb::adp::AppendCode $code
   ossweb::adp::AppendData "<TR $tag [ossweb::convert::set_to_attributes $params -quotes {\"} -skip $skip_tags] [ns_set iget $params html]>"
   if { $chunk != "" } {
     ossweb::adp::Parse $chunk
   }
   if { [ns_set iget $params open] == "" } {
     ossweb::adp::AppendData "</TR>"
   }
   # Add 1 pixel line after the row
   if { [set underline [ns_set iget $params underline]] != "" } {
     # Calculate number of TD
     set colspan [ns_set iget $params colspan [llength [regexp -all -inline -nocase {</TD>} $chunk]]]
     ossweb::adp::AppendCode "
       if { $underline == 1 } {
         ossweb::adp::Write \"<TR><TD COLSPAN=$colspan HEIGHT=1>\[ossweb::html::image misc/graypixel.gif -height 1 -width 100%]</TD></TR>\"
       }"
   }
}

# Command proc for if and esleif
proc ossweb::tag::iftag { params } {

    set condition ""
    set args ""
    set size [ns_set size $params]
    for { set i 0 } { $i < $size } { incr i } {
      append args [ns_set key $params $i] " "
    }
    set size [llength $args]
    for { set i 0 } { $i < $size } {} {
      set arg1 "\"[lindex $args $i]\""
      incr i
      set op [lindex $args $i]
      if { $op == "not" } {
        append condition "!"
        incr i
        set op [lindex $args $i]
      }
      incr i
      switch $op {
        gt {
          append condition "($arg1 > \"[lindex $args $i]\")"
          incr i
        }
        ge {
          append condition "($arg1 >= \"[lindex $args $i]\")"
          incr i
        }
        lt {
          append condition "($arg1 < \"[lindex $args $i]\")"
          incr i
        }
        le {
          append condition "($arg1 <= \"[lindex $args $i]\")"
          incr i
        }
        eq {
          append condition "(\[string equal $arg1 \"[lindex $args $i]\"\])"
          incr i
        }
        ne {
          append condition "(!\[string equal $arg1 \"[lindex $args $i]\"\])"
          incr i
        }
        match {
          append condition "(\[string match $arg1 \"[lindex $args $i]\"\])"
          incr i
        }
        regexp {
          append condition "(\[regexp -nocase $arg1 \"[lindex $args $i]\"\])"
          incr i
        }
        in {
          append condition "(\[lsearch -exact {[lrange $args $i end]} $arg1\] > -1)"
          set i $size
        }
        nil {
          regsub {@([a-zA-z0-9_]+)\.([a-zA-z0-9_:]+)@} $arg1 {\1(\2)} arg1
          regsub {@([a-zA-z0-9_:]+)@} $arg1 {\1} arg1
          append condition "(!\[ossweb::exists $arg1\])"
        }
        odd {
          append condition "(\[expr $arg1 % 2\])"
        }
        even {
          append condition "(!\[expr $arg1 % 2\])"
        }
        mod {
          append condition "(\[expr $arg1 % [lindex $args $i]\])"
          incr i
        }
        true {
          append condition "(\[ossweb::true $arg1\])"
        }
        default {
          error "Unknown operator '$op' in <IF> tag: $args"
        }
      }
      if { $i >= $size } { break }
      switch [lindex $args $i] {
        and { append condition " && " }
        or { append condition " || " }
        default { error "Unknown junction '[lindex $args $i]' in <IF> tag: '$args'" }
      }
      incr i
    }
    return $condition
}

# To be used for urls and links
proc ossweb::tag::urltag { params } {

    set args ""
    for { set i 0 } { $i < [ns_set size $params] } { incr i } {
      if { [set name [ns_set key $params $i]] != "" } {
        switch -regexp -- $name {
         {^".+"$} -
         {^\[.+\]$} -
         {^[^ ]+$} {
           append args [string map { [ "\[" ] "\]" } $name] " "
         }
         default {
           append args "\"" [string map { [ "\[" ] "\]" } $name] "\" "
         }
        }
      }
    }
    return $args
}

# Special control header for internal use
ossweb::tag::create ossweb:header { params } {

    ossweb::adp::AppendCode "ossweb::html::include /js/ossweb.js"
    ossweb::adp::AppendCode "ossweb::html::include /css/\[ossweb::project style ossweb\].css"
    ossweb::adp::AppendCode "ossweb::adp::Write \"\[ossweb::conn html:head\]\""
}

# Special control tag for internal use
ossweb::tag::create ossweb:footer { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::conn html:foot\]"
}

# Global error message
ossweb::tag::create ossweb:msg { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \"<SPAN ID=osswebMsg CLASS=osswebMsg>\[ossweb::conn -msg\]</SPAN>\""
}

# Title with header
ossweb::tag::create ossweb:title { chunk params } {

    ossweb::adp::AppendData "<SPAN CLASS=osswebTitle>"
    ossweb::adp::AppendCode "
      if { \[ossweb::conn title\] == {} } {
        ossweb::conn -set title \[ns_striphtml \[subst {$chunk}\]\]
      }
    "
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendData "</SPAN>"
}

ossweb::tag::create ossweb:url { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::html::url [ossweb::tag::urltag $params]\]"
}

ossweb::tag::create ossweb:link { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::html::link [ossweb::tag::urltag $params]\]"
}

ossweb::tag::create ossweb:image { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::html::image [ossweb::tag::urltag $params]\]"
}

# Definition of table inside the table tag which implements
# black border around the table.
ossweb::tag::create border { chunk params } {

    if { [set id [ns_set iget $params id]] != "" } {
      set id "ID=$id"
    }
    set style [ns_set iget $params style [ossweb::config server:style:border]]
    ns_set idelkey $params style
    ns_set idelkey $params id

    # Use system configuration for default border
    switch -- $style {
     none {
       ossweb::adp::Parse $chunk
     }

     class {
       set class [ns_set iget $params class osswebTable]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS }]
       ossweb::adp::AppendData "<TABLE $id CLASS=$class $html >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "</TABLE>"
     }

     div {
       set class [ns_set iget $params class osswebBorder]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS }]
       ossweb::adp::AppendData "<DIV $id CLASS=$class $html >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "</DIV>"
     }

     shadow {
       set class [ns_set iget $params class osswebBorderShadow]
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 0]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData "
          <DIV CLASS=$class><DIV CLASS=${class}2>
          <TABLE $id WIDTH=$width BORDER=0 CELLSPACING=$cellsp CELLPADDING=$cellpd $html >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "</TABLE></DIV></DIV>\n"
     }

     curved {
       set class [ns_set iget $params class osswebBorderCurved]
       set img "[ossweb::config server:path:images "/img"]/border/curved"
       set border [ns_set iget $params border 0]
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 0]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS BORDER WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData "
          <TABLE ALIGN=CENTER WIDTH=$width BORDER=0 CELLPADDING=$cellsp CELLSPACING=$cellpd CLASS=$class $html >
          <TR ALIGN=CENTER>
            <TD WIDTH=20 HEIGHT=20><IMG SRC=$img/0.gif WIDTH=20 BORDER=0></TD>
            <TD WIDTH=100% BACKGROUND=$img/1.gif>&nbsp;</TD>
            <TD WIDTH=20 HEIGHT=20><IMG SRC=$img/2.gif BORDER=0></TD>
          </TR>
          <TR VALIGN=TOP>
            <TD WIDTH=20 BACKGROUND=$img/7.gif>&nbsp;</TD>
            <TD WIDTH=100%>
              <TABLE $id WIDTH=100% CLASS=$class CELLSPACING=0 CELLPADDING=0>\n"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
              </TABLE>
            </TD>
            <TD WIDTH=20 BACKGROUND=$img/3.gif>&nbsp;</TD>
          </TR>
          <TR ALIGN=CENTER>
            <TD WIDTH=20><IMG SRC=$img/6.gif></TD>
            <TD BACKGROUND=$img/5.gif>&nbsp;</TD>
            <TD WIDTH=20><IMG SRC=$img/4.gif></TD>
          </TR>
          </TABLE>\n"
     }

     curved3 {
       set class [ns_set iget $params class osswebBorderCurved3]
       set img "[ossweb::config server:path:images "/img"]/border/curved3/"
       set title [ns_set iget $params title]
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 0]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS TITLE WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData "
         <TABLE WIDTH=$width BORDER=0 CELLSPACING=0 CELLPADDING=0 $html >
         <TR>
         <TD WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
         <TD WIDTH=7><IMG SRC=${img}sp.gif WIDTH=7 HEIGHT=1></TD>
         <TD COLSPAN=3><IMG SRC=${img}sp.gif WIDTH=100% HEIGHT=1></TD>
         <TD WIDTH=7><IMG SRC=${img}sp.gif WIDTH=7 HEIGHT=1></TD>
         <TD WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
         </TR>
         <TR CLASS=$class >
         <TD COLSPAN=2 WIDTH=9 ALIGN=LEFT VALIGN=TOP><IMG SRC=${img}tl.gif WIDTH=9 HEIGHT=9 BORDER=0></TD>
         <TD COLSPAN=3 WIDTH=100% ALIGN=CENTER>$title</TD>
         <TD COLSPAN=2 WIDTH=10 ALIGN=RIGHT VALIGN=TOP><img src=${img}tr.gif WIDTH=10 HEIGHT=9 BORDER=0></TD>
         </TR>"
       # Separator between title bar and content table
       if { [ns_set iget $params separator1] != "" } {
         ossweb::adp::AppendData "
           <TR CLASS=$class>
           <TD WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
           <TD COLSPAN=5><IMG SRC=${img}sp.gif HEIGHT=5></TD>
           <TD WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
           </TR>"
       }
       ossweb::adp::AppendData "
         <TR VALIGN=TOP>
         <TD CLASS=$class WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
         <TD COLSPAN=5>
            <TABLE $id WIDTH=100% BORDER=0 CELLSPACING=$cellsp CELLPADDING=$cellpd >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
            </TABLE>
         </TD>
         <TD CLASS=$class WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1 BORDER=0></TD>
         </TR>"
       # Separator between content table and bottom line
       if { [ns_set iget $params separator2] != "" } {
         ossweb::adp::AppendData "
           <TR CLASS=$class>
           <TD WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
           <TD COLSPAN=5><IMG SRC=${img}sp.gif HEIGHT=5></TD>
           <TD WIDTH=2><IMG SRC=${img}sp.gif WIDTH=2 HEIGHT=1></TD>
           </TR>"
       }
       # Bottom line can be curved or straight
       switch [ns_set iget $params bottom] {
        curved {
          ossweb::adp::AppendData "
            <TR CLASS=$class>
            <TD COLSPAN=2 HEIGHT=6 WIDTH=9 ALIGN=LEFT VALIGN=TOP><IMG SRC=${img}bl.gif WIDTH=9 HEIGHT=6 BORDER=0></TD>
            <TD COLSPAN=3 HEIGHT=6><IMG SRC=${img}sp.gif HEIGHT=6></TD>
            <TD COLSPAN=2 HEIGHT=6 WIDTH=10 ALIGN=RIGHT VALIGN=TOP><IMG SRC=${img}br.gif WIDTH=10 HEIGHT=6 BORDER=0></TD>
            </TR>"
        }
        default {
          ossweb::adp::AppendData "
            <TR>
            <TD COLSPAN=7 CLASS=$class HEIGHT=2><IMG SRC=${img}sp.gif HEIGHT=2></TD>"
        }
       }

       ossweb::adp::AppendData "
         </TABLE>"
     }

     white {
       set class [ns_set iget $params class osswebBorderWhite]
       set img "[ossweb::config server:path:images "/img"]/border/white/"
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData "
          <TABLE BORDER=0 WIDTH=$width CLASS=$class CELLSPACING=0 CELLPADDING=0>
          <TR>
            <TD WIDTH=16><IMG SRC=${img}tlt.gif HEIGHT=16 WIDTH=16 BORDER=0></TD>
            <TD><IMG SRC=${img}tln.gif HEIGHT=16 WIDTH=100% BORDER=0></TD>
            <TD WIDTH=23><IMG SRC=${img}trt.gif HEIGHT=16 WIDTH=23 BORDER=0></TD>
          </TR>
          <TR VALIGN=TOP>
            <TD WIDTH=16 BACKGROUND=${img}l.gif><IMG SRC=${img}l.gif WIDTH=16 HEIGHT=100% BORDER=0></TD>
            <TD><TABLE $id WIDTH=100% BORDER=0 CELLSPACING=$cellsp CELLPADDING=$cellpd $html >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
                </TABLE>
            </TD>
            <TD WIDTH=23 BACKGROUND=${img}r.gif><IMG SRC=${img}r.gif WIDTH=23 HEIGHT=100% BORDER=0></TD>
          </TR>
          <TR>
            <TD WIDTH=16><IMG SRC=${img}blt.gif HEIGHT=16 WIDTH=16 BORDER=0></TD>
            <TD><IMG SRC=${img}bln.gif HEIGHT=16 WIDTH=100% BORDER=0></TD>
            <TD WIDTH=23><IMG SRC=${img}brt.gif HEIGHT=16 WIDTH=23 BORDER=0></TD>
          </TR>
          </TABLE>"
     }

     gray {
       set class [ns_set iget $params class osswebBorderGray]
       set img "[ossweb::config server:path:images "/img"]/border/gray/"
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData "
          <TABLE WIDTH=$width BORDER=0 CELLSPACING=0 CELLPADDING=0 CLASS=$class $html >
          <TR>
          <TD BACKGROUND=${img}tl.gif><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=15 BORDER=0 ALT=''></TD>
          <TD BACKGROUND=${img}t.gif VALIGN=BOTTOM><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=15 BORDER=0 ALT=''></TD>
          <TD BACKGROUND=${img}tr.gif><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=15 BORDER=0 ALT=''></TD>
          </TR>

          <TR VALIGN=TOP>
          <TD BACKGROUND=${img}l.gif><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=100% BORDER=0 ALT=''></TD>
          <TD WIDTH=100% VALIGN=TOP>
             <TABLE $id WIDTH=100% BORDER=0 CELLSPACING=$cellsp CELLPADDING=$cellpd [ns_set iget $params params] >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
             </TABLE>
          </TD>
          <TD BACKGROUND=${img}r.gif VALIGN=TOP><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=100% BORDER=0 ALT=''></TD>
          </TR>
          <TR>
          <TD BACKGROUND=${img}bl.gif><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=15 BORDER=0 ALT=''></TD>
          <TD BACKGROUND=${img}b.gif><IMG SRC=${img}p.gif WIDTH=1 HEIGHT=15 BORDER=0 ALT=''></TD>
          <TD BACKGROUND=${img}br.gif><IMG SRC=${img}p.gif WIDTH=15 HEIGHT=15 BORDER=0 ALT=''></TD>
          </TR>
          </TABLE>"
     }

     table {
       set class1 "CLASS=[ns_set iget $params class1 osswebBorder1]"
       set class2 "CLASS=[ns_set iget $params class2 osswebBorder2]"
       set border1 [ns_set iget $params border1 1]
       set border2 [ns_set iget $params border2 0]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       set width [ns_set iget $params width 100%]
       if { [set height [ns_set iget $params params]] != "" } { set height "HEIGHT=$height" }
       if { [set bg [ns_set iget $params background]] != "" } { set bg "BACKGROUND=$bg" }
       if { [set color1 [ns_set iget $params color1]] != "" } { set class1 "BGCOLOR=$color1" }
       if { [set color2 [ns_set iget $params color2]] != "" } { set class2 "BGCOLOR=$color2" }
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CELLSPACING CELLPADDING WIDTH }]

       if { $border1 > 0 } {
         ossweb::adp::AppendData "
          <TABLE $class1 WIDTH=$width $height BORDER=$border1 CELLSPACING=0 CELLPADDING=0 $html ><TR VALIGN=TOP><TD>\
          <TABLE $id $class2 WIDTH=100% $bg HEIGHT=100% BORDER=$border2 CELLSPACING=$cellsp CELLPADDING=$cellpd [ns_set iget $params params]>"
       } else {
         ossweb::adp::AppendData "
          <TABLE $id $class2 WIDTH=$width $bg $height BORDER=$border2 CELLSPACING=$cellsp CELLPADDING=$cellpd [ns_set iget $params params]>"
       }
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "</TABLE>\n"
       if { $border1 > 0 } { ossweb::adp::AppendData "</TD></TR></TABLE>\n" }
     }

     curved4 {
       set class [ns_set iget $params class osswebBorderCurved4]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       set width [ns_set iget $params width 100%]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData  "
         <DIV CLASS=$class STYLE=\\\"width:$width\\\"><DIV CLASS=${class}_tl><DIV CLASS=${class}_tr><DIV CLASS=${class}_br><DIV CLASS=${class}_bl>
         <TABLE $id WIDTH=100% BORDER=0 CELLSPACING=$cellsp CELLPADDING=$cellpd $html >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
         </TABLE>
         </DIV></DIV></DIV></DIV></DIV>"
     }

     curved5 {
       set width [ns_set iget $params width 100%]
       set title [ns_set iget $params title [ns_set iget $params border_title]]
       set img "[ossweb::config server:path:images "/img"]/border/curved5/"
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { TITLE WIDTH CELLSPACING CELLPADDING }]
       if { $title != "" } {
         set title_lt glt
         set title_rt grt
         set title_t gt.gif
       } else {
         set title_lt lt
         set title_rt rt
         set title_t t.gif
       }

       ossweb::adp::AppendData "
         <TABLE WIDTH=$width HEIGHT=46 CELLPADDING=0 CELLSPACING=0 BORDER=0>
         <TR>
           <TD COLSPAN=2 WIDTH=5 BACKGROUND=${img}${title_lt}.gif><IMG SRC=/img/blank.gif WIDTH=5 HEIGHT=5 BORDER=0 ></TD>
           <TD VALIGN=TOP ALIGN=CENTER WIDTH=100% BACKGROUND=${img}${title_t} HEIGHT=5 NOWRAP>$title</TD>
           <TD COLSPAN=2 WIDTH=5  BACKGROUND=${img}${title_rt}.gif><IMG SRC=/img/blank.gif WIDTH=5 HEIGHT=5 BORDER=0 ></TD>
         </TR>
         <TR VALIGN=TOP>
           <TD WIDTH=1 BGCOLOR=#CCCCCC><IMG SRC=/img/blank.gif WIDTH=1 HEIGHT=5 ></TD>
           <TD WIDTH=4><IMG SRC=/img/blank.gif WIDTH=4 HEIGHT=5 ></TD>
           <TD VALIGN=MIDDLE ALIGN=CENTER WIDTH=100%>
             <TABLE WIDTH=100% BORDER=0 CELLSPACING=$cellsp CELLPADDING=$cellpd $html >"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
             </TABLE>
           </TD>
           <TD WIDTH=4><IMG SRC=/img/blank.gif WIDTH=4 HEIGHT=5 ></TD>
           <TD WIDTH=1 BGCOLOR=#CCCCCC><IMG SRC=/img/blank.gif WIDTH=1 HEIGHT=5 ></TD>
         </TR>
         <TR>
           <TD COLSPAN=2 WIDTH=5 HEIGHT=5><IMG SRC=${img}lb.gif WIDTH=5 HEIGHT=5 BORDER=0></TD>
           <TD WIDTH=100% HEIGHT=5 BACKGROUND=${img}b.gif><IMG SRC=/img/blank.gif WIDTH=1 HEIGHT=5 ></TD>
           <TD COLSPAN=2 WIDTH=5 HEIGHT=5><IMG SRC=${img}rb.gif WIDTH=5 HEIGHT=5 BORDER=0 ></TD>
         </TR>
         </TABLE>"
     }

     fieldset {
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       if { [set class [ns_set iget $params class]] != "" } { set class "CLASS=$class" }
       if { [set align [ns_set iget $params align]] != "" } { set align "ALIGN=$align" }
       set legend [ns_set iget $params title [ns_set iget $params border_title]]
       if { $legend != "" } {
          set legend "<LEGEND $align>\[ossweb::html::title {$legend}\]</LEGEND>"
       }
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS ALIGN TITLE WIDTH CELLSPACING CELLPADDING }]
       ossweb::adp::AppendData "
         <FIELDSET $class [ns_set iget $params html]>$legend
         <TABLE $id $class BORDER=0 WIDTH=$width CELLSPACING=$cellsp CELLPADDING=$cellpd $html>"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
         </TABLE>
         </FIELDSET>"
     }

     curved6 {
         set width [ns_set iget $params width 100%]
         set title [ns_set iget $params title [ns_set iget $params border_title]]
         set img "[ossweb::config server:path:images "/img"]/border/curved6/"
         set width [ns_set iget $params width 100%]
         set cellsp [ns_set iget $params cellspacing 0]
         set cellpd [ns_set iget $params cellpadding 2]
         set border [ns_set iget $params border 0]
         set class [ns_set iget $params class osswebBorderCurved6]

         ossweb::adp::AppendData "
         <TABLE WIDTH=$width BORDER=0 CELLSPACING=0 CELLPADDING=0>
         <TR>
           <TD WIDTH=6 ALIGN=LEFT VALIGN=TOP><IMG SRC=${img}lt.gif WIDTH=6 HEIGHT=19></TD>
           <TD ALIGN=LEFT VALIGN=TOP BACKGROUND=${img}ttl.gif>
           <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
               <TR>
                 <TD WIDTH=1><IMG SRC=${img}t.gif WIDTH=12 HEIGHT=19></TD>
                 <TD STYLE=PADDING-LEFT:6PX><B>$title</B></TD>
               </TR>
             </TABLE></TD>
           <TD WIDTH=6 ALIGN=RIGHT VALIGN=TOP><IMG SRC=${img}rt.gif WIDTH=6 HEIGHT=19></TD>
         </TR>
         <TR VALIGN=TOP>
           <TD ALIGN=LEFT VALIGN=TOP BACKGROUND=${img}ltl.gif><IMG SRC=${img}ltl.gif WIDTH=6 HEIGHT=2></TD>
           <TD ALIGN=LEFT VALIGN=TOP>
           <TABLE $id BORDER=$border CLASS=$class WIDTH=100% CELLSPACING=$cellsp CELLPADDING=$cellpd>"
         ossweb::adp::Parse $chunk
         ossweb::adp::AppendData "
           </TABLE>
           </TD>
           <TD ALIGN=RIGHT VALIGN=TOP BACKGROUND=${img}rtl.gif><IMG SRC=${img}rtl.gif WIDTH=6 HEIGHT=3></TD>
         </TR>
         <TR>
           <TD ALIGN=LEFT VALIGN=BOTTOM><IMG SRC=${img}lb.gif WIDTH=6 HEIGHT=6></TD>
           <TD BACKGROUND=${img}btl.gif><IMG SRC=${img}btl.gif WIDTH=5 HEIGHT=6></TD>
           <TD ALIGN=RIGHT VALIGN=BOTTOM><IMG SRC=${img}rb.gif WIDTH=6 HEIGHT=6></TD>
         </TR>
         </TABLE>"
     }

     curved2 -
     default {
       set class [ns_set iget $params class osswebBorderCurved2]
       set class2 [ns_set iget $params class2 $class]
       set img "[ossweb::config server:path:images "/img"]/border/curved2/"
       set width [ns_set iget $params width 100%]
       set cellsp [ns_set iget $params cellspacing 0]
       set cellpd [ns_set iget $params cellpadding 2]
       set border1 [ns_set iget $params border1 0]
       set border2 [ns_set iget $params border2 0]
       set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { CLASS WIDTH CELLSPACING CELLPADDING }]

       ossweb::adp::AppendData "
         <TABLE BORDER=$border1 CLASS=$class WIDTH=$width CELLSPACING=0 CELLPADDING=0 $html >
         <TR ALIGN=LEFT VALIGN=TOP>\
           <TD HEIGHT=10 WIDTH=10><IMG SRC=${img}t_tl.jpg WIDTH=10 HEIGHT=10></TD>
           <TD COLSPAN=2 BACKGROUND=${img}t_tm.jpg ALIGN=RIGHT><IMG SRC=${img}t_tr.jpg WIDTH=141 HEIGHT=10></TD>
         </TR>
         <TR ALIGN=LEFT VALIGN=TOP>
           <TD BACKGROUND=${img}t_ml.jpg><IMG SRC=${img}t_ml.jpg WIDTH=10 HEIGHT=1></TD>
           <TD BACKGROUND=${img}t_bg.jpg ALIGN=LEFT VALIGN=TOP WIDTH=100%>
             <TABLE $id BORDER=$border2 CLASS=$class2 WIDTH=100% CELLSPACING=$cellsp CELLPADDING=$cellpd>"
       ossweb::adp::Parse $chunk
       ossweb::adp::AppendData "
             </TABLE>
           </TD>
           <TD BACKGROUND=${img}t_mr.jpg HEIGHT=1><IMG SRC=${img}t_mr.jpg WIDTH=10 HEIGHT=1></TD>
         </TR>
         <TR ALIGN=LEFT VALIGN=TOP>
           <TD HEIGHT=10 WIDTH=10><IMG SRC=${img}t_bl.jpg WIDTH=10 HEIGHT=10></TD>
           <TD BACKGROUND=${img}t_bm.jpg ALIGN=RIGHT VALIGN=BOTTOM COLSPAN=2><IMG SRC=${img}t_br.jpg WIDTH=10 HEIGHT=10></TD>
         </TR>
         </TABLE>"
     }
    }
}

# Help button
ossweb::tag::create helpbutton { params } {

    ossweb::adp::AppendCode \
         "ossweb::adp::Write \"<INPUT TYPE=BUTTON NAME=help VALUE=Help CLASS=osswebButton \
               TITLE=\\\"Show popup window with help\\\" \
               onMouseOver=\\\"this.className='osswebButtonOver'\\\" \
               onMouseOut=\\\"this.className='osswebButton'\\\" \
               onClick=\\\"window.open('\[ossweb::nvl \"[ns_set iget $params url]\" \
                 \[ossweb::html::url -app_name main help \
                        project_name \[ossweb::conn project_name\] \
                        app_name \[ossweb::conn app_name\] \
                        page_name \[ossweb::nvl \"[ns_set iget $params page_name]\" \[ossweb::conn page_name\]\] \
                        cmd_name \[ossweb::nvl \"[ns_set iget $params cmd_name]\" \[ossweb::conn cmd_name\]\] \
                        ctx_name \[ossweb::nvl \"[ns_set iget $params ctx_name]\" \[ossweb::conn ctx_name\]\]\]\]',\
               'HelpWindow',\
               'width=[ns_set iget $params width 800],height=[ns_set iget $params height 600],toolbar=0,menubar=0,scrollbars=1,resizable=1')\\\">\""
}

# Help image link
ossweb::tag::create helpimage { params } {

    ossweb::adp::AppendCode \
         "ossweb::adp::Write \"<A CLASS=osswebLink TITLE=\\\"Show popup window with help\\\" HREF=\\\"javascript:;\\\" \
               onClick=\\\"window.open('\[ossweb::nvl \"[ns_set iget $params url]\" \
                 \[ossweb::html::url -app_name main help \
                        project_name \[ossweb::conn project_name\] \
                        app_name \[ossweb::conn app_name\] \
                        page_name \[ossweb::nvl \"[ns_set iget $params page_name]\" \[ossweb::conn page_name\]\] \
                        cmd_name \[ossweb::nvl \"[ns_set iget $params cmd_name]\" \[ossweb::conn cmd_name\]\] \
                        ctx_name \[ossweb::nvl \"[ns_set iget $params ctx_name]\" \[ossweb::conn ctx_name\]\]\]\]',\
               'HelpWindow',\
               'width=[ns_set iget $params width 800],height=[ns_set iget $params height 600],toolbar=0,menubar=0,scrollbars=1,resizable=1')\\\">
               \[ossweb::html::image \[ossweb::nvl \"[ns_set iget $params image]\" help.gif\] -alt Help \]\""
}

# Title with help button
ossweb::tag::create helptitle { chunk params } {

    set title [ns_set iget $params title]
    set html [ossweb::convert::set_to_attributes $params -quotes {\"} -skip { title help }] ;# extra quote "
    if { $chunk == "" } {
      set chunk $title
    }
    ossweb::adp::AppendData "<TABLE WIDTH=100% CELLSPACING=0 CELLPADDING=0 BORDER=0><TR><TD CLASS=osswebTitle $html>"
    ossweb::adp::AppendCode "
      if { \[ossweb::conn title\] == {} } { ossweb::conn -set title \[ns_striphtml \[subst {$chunk}\]\] }
    "
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendData "</TD><TD ALIGN=RIGHT>"
    if { [ns_set iget $params help] != 0 } {
      ossweb::tag::tag_helpimage $params
    } else {
      ossweb::adp::AppendData [ns_set iget $params info]
    }
    ossweb::adp::AppendData "</TD></TR></TABLE>"
}

ossweb::tag::create tcl { chunk params } {

    if { [string index $chunk 0] == "=" } {
      ossweb::adp::AppendCode "ossweb::adp::Write [string range $chunk 1 end]"
    } else {
      ossweb::adp::AppendCode $chunk
    }
}

ossweb::tag::create join { chunk params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[join $chunk [ns_set iget $params delim]\]"
}

ossweb::tag::create decode { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[eval ossweb::decode [ossweb::convert::set_to_list $params -values t]\]"
}

# Set the master template.
ossweb::tag::create master { params } {

    switch -- [set mode [ns_set iget $params mode]] {
     lookup {
       set src "\[ossweb::lookup::master\]"
     }

     title -
     print -
     logo {
       set src index.$mode
     }

     user {
       set src "\[ossweb::conn html:master index\]"
     }

     default {
       set src [ns_set iget $params src index]
     }
    }
    ossweb::adp::AppendCode "ossweb::adp::Buffer set master \[ossweb::adp::Include $src\]"
}

# Insert the slave template
ossweb::tag::create slave { params } {

    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::adp::Buffer get slave\]"
}

# Define block of template that can be referred later
ossweb::tag::create template { chunk params } {

    set name [ns_set iget $params name]
    if { $name != "" } {
      set code [ossweb::adp::Compile $chunk 1 1]
      ::proc ::template_[ossweb::adp::File]_$name {} "uplevel #[ossweb::adp::Level] { $code }"
    }
}

# Include another template in the current template
ossweb::tag::create include { params } {

    switch -- [ns_set iget $params type] {
     file {
       set src [ns_set iget $params src]
       if { [string index $src 0] != "/" } {
         set src [ossweb::adp::DirName]/$src
       }
       ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::read_file $src\]"
     }

     template {
       set name [ns_set iget $params name]
       if { $name != "" } {
          for { set i 0 } { $i < [ns_set size $params] } { incr i } {
            set key [ns_set key $params $i]
            if { $key != "name" } { ossweb::adp::AppendCode "set $key [ns_set value $params $i]" }
          }
         ossweb::adp::AppendCode "::template_[ossweb::adp::File]_$name"
       }
     }

     default {
       set args ""
       for { set i 0 } { $i < [ns_set size $params] } { incr i } {
         set key [ns_set key $params $i]
         if { $key != "src" } { append args " $key {[ns_set value $params $i]}" }
       }
       ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::adp::Execute \[ossweb::adp::Include [ns_set iget $params src]\] {$args}\]"
     }
    }
}

ossweb::tag::create grid { chunk params } {

    set name [ns_set iget $params name]
    set underline [ns_set iget $params underline]
    set empty [ns_set iget $params empty "&nbsp;"]
    if { [set cols [ns_set iget $params cols]] <= 0 } {
      error "grid: $name: cols should be specified"
    }
    ns_set put $params open 1
    ns_set idelkey $params underline
    ns_set put $params skip "td name cols empty"
    if { [set td_opts [ns_set iget $params td]] == "" } {
      regexp {<TD ([^>]+)>} $chunk d td_opts
    }
    # Repeat chunk for each column
    ossweb::adp::AppendCode "
     set _rowcount$name \[expr ceil(\[ossweb::coalesce $name:rowcount\] / $cols.0)\]
     for { set _row$name 1 } { \$_row$name <= \$_rowcount$name } { incr _row$name } {"
       ossweb::tag::rowtag "" $params row
    ossweb::adp::AppendCode "
       for { set _col$name 1 } { \$_col$name <= $cols } { incr _col$name } {
         set _rownum$name \[expr 1 + int((\$_row$name - 1) + ((\$_col$name - 1) * \$_rowcount$name))\]
         upvar 0 $name:\$_rownum$name $name
         if { !\[info exists $name\] } {
           ossweb::adp::Write \"<TD $td_opts>$empty</TD>\"
           continue
         }"
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "
       }
       ossweb::adp::Write \"</TR>\"
       if { {$underline} == 1 } {
         ossweb::adp::Write \"<TR><TD COLSPAN=$cols HEIGHT=1>\[ossweb::html::image misc/graypixel.gif -height 1 -width 100%]</TD></TR>\"
       }"
    ossweb::adp::AppendCode "}"
}

ossweb::tag::create multirow { chunk params } {

    set name [ns_set iget $params name]
    set data [ns_set iget $params data]
    set norow [ns_set iget $params norow 0]
    set underline [ns_set iget $params underline 0]

    # Repeat chunk for each row
    if { $chunk != "" } {
      # Calculated at runtime name of the multirow array
      if { $data != "" } {
        set idx idx[ns_rand 10000]
        ossweb::adp::AppendCode "
        set data$idx $data
        set rowcount$idx \[ossweb::coalesce data$idx:rowcount\]
        for { set $idx 1 } { \$$idx <= \$rowcount$idx } { incr $idx } {
          upvar 0 \$data$idx:\$$idx $name
          set $name:rownum \$$idx
          if { !\[info exists $name\] } { continue }"
        ossweb::adp::Parse $chunk
        ossweb::adp::AppendCode "}"
      } else {
        # Constant name of multirow
        ossweb::adp::AppendCode "
        for { set _row$name 1 } { \$_row$name <= \[ossweb::coalesce $name:rowcount\] } { incr _row$name } {
          upvar 0 $name:\$_row$name $name
          set $name:rownum \$_row$name
          if { !\[info exists $name\] } { continue }"
        ossweb::adp::Parse $chunk
        ossweb::adp::AppendCode "}"
      }
      return
    }

    # Autogenerate table for rows
    set header [ns_set iget $params header 1]
    set options [ns_set iget $params options $name:options]
    ossweb::conn -set table_row:color_index 1
    ossweb::adp::AppendCode "
      if { $header == 1 } {
        ossweb::adp::Write \"<TR CLASS=osswebFirstRow \[ossweb::coalesce ${options}(header.params)\]>\"
        foreach _name \[ossweb::coalesce $name:columns\] {
          if { \[string index \$_name 0\] == \"_\" } { continue }
          set _params \[ossweb::coalesce ${options}(\$_name.params) \"\"\]
          set _params2 \[ossweb::coalesce ${options}(th.params) \"\"\]
          set _name \[ossweb::coalesce ${options}(\$_name.title) \[ossweb::util::totitle \$_name\]\]
          ossweb::adp::Write \"<TD \$_params2 \$_params><B>\$_name</B></TD>\"
        }
        ossweb::adp::Write \"</TR>\n\"
      }
      set _columns 0
      set _options \[ossweb::coalesce ${options}(tr.params) \"\"\]
      for { set _row 1 } { \$_row <= \[ossweb::coalesce $name:rowcount\] } { incr _row } {
        upvar 0 $name:\$_row $name
        if { !\[info exists $name\] } { continue }
        if { !\[info exists ${name}(bgcolor:index)\] } {
          set index \[ossweb::nvl \[ossweb::conn table_row:color_index\] 1\]
        } else {
          set index \$${name}(bgcolor:index)
        }
        if { $norow != 1 } {
          ossweb::conn -set table_row:color_index \[expr 3-\$index\]
        }
        ossweb::adp::Write \"<TR CLASS=osswebRow\$index \$_options >\"
        foreach _name \${$name:columns} {
          if { \[string index \$_name 0\] == \"_\" } { continue }
          set _params \[ossweb::coalesce ${options}(\$_name.params) \"\"\]
          set _params2 \[ossweb::coalesce ${options}(td.params) \"\"\]
          ossweb::adp::Write \"<TD \$_params2 \$_params>\$${name}(\$_name)</TD>\"
          if { \$_row == 1 } { incr _columns }
        }
        ossweb::adp::Write \"</TR>\n\"
        if { $underline == 1 } {
          ossweb::adp::Write \"<TR><TD COLSPAN=\$_columns HEIGHT=1>\[ossweb::html::image misc/graypixel.gif -height 1 -width 100%]</TD></TR>\"
        }
      }"
}

# Repeat template chunk until the column name stays the same
ossweb::tag::create group { chunk params } {

    set column [ns_set iget $params column]
    set name [ns_set iget $params name]
    ossweb::adp::AppendCode "
      while {1} {"
        ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "
        if { \$_row$name >= \${$name:rowcount} } { break }
        upvar 0 $name:\[expr \$_row$name + 1\] ${name}0
        if { \${${name}0($column)} != \$${name}($column) } { break }
        incr _row$name
        upvar 0 $name:\$_row$name $name
      }"
}

# Repeat a template chunk for each item in a list
ossweb::tag::create list { chunk params } {

    set name [ns_set iget $params name]
    ossweb::adp::AppendCode "
      for { set _row$name 0 } { \$_row$name < \[llength \$$name\] } { incr _row$name } {
        set $name:item \[lindex \$$name \$_row$name\]"
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "}"
}

# Repeat a template chunk for items in a list
ossweb::tag::create multilist { chunk params } {

    set name [ns_set iget $params name]
    ossweb::adp::AppendCode "
      for { set _row$name 0 } { \$_row$name < \[llength \$$name\] } { incr _row$name } {
        set $name:item \[lindex \$$name \$_row$name\]
        for { set _i$name 1 } { \$_i$name <= \[llength \${$name:item}\] } { incr _i$name } {
          set $name:\$_i$name \[lindex \${$name:item} \[expr \$_i$name - 1\]\]
        }"
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "}"
}

# Repeat a template chunk for each record
ossweb::tag::create foreach { chunk params } {

    set name [ns_set iget $params name]
    set query [ns_set iget $params query]
    ossweb::adp::AppendCode "
      ossweb::db::foreach $query {"
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "} -array $name -cache {[ns_set iget $params cache]}"
}

ossweb::tag::create return { params } {

    ossweb::adp::AppendCode "return"
}

ossweb::tag::create continue { params } {

    ossweb::adp::AppendCode "continue"
}

ossweb::tag::create exit { params } {

    ossweb::adp::AppendCode "ossweb::adp::Exit"
}

ossweb::tag::create if { chunk params } {

    set condition [ossweb::tag::iftag $params]
    ossweb::adp::AppendCode "if \{ $condition \} \{"
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "\}"
}

ossweb::tag::create else { params } {

    ossweb::adp::AppendCode "\} else \{"
}

ossweb::tag::create case { chunk params } {

    ossweb::adp::AppendCode "if \{0\} \{"
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "\}"
}

ossweb::tag::create when { params } {

    set condition [ossweb::tag::iftag $params]
    ossweb::adp::AppendCode "\} elseif \{ $condition \} \{"
}

# Displays form as a tabbed panel
ossweb::tag::create formtab { params } {

    set id [ns_set iget $params id]
    set style [ns_set get $params style gray]
    set cols [ns_set get $params cols 99]
    set tab_name [ns_set get $params tab tab]
    set tab_class [ns_set get $params class osswebTabLink]
    set img /img/tab/$style
    set form [ns_set get $params form]
    set width [ns_set get $params width 100%]

    if { $form == 1 } {
      ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::form $id html\]"
    }

    switch $style {
     blue {
       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           ossweb::adp::Write {}
           set _tab \[ossweb::coalesce $tab_name {}]
           set _form_tag {}
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             set _type \[ossweb::decode \$_tab \$widget_t(id) active passive]
             ossweb::widget \$widget_id set_attr STYLE {color:#E2F7FC;}
             append _form_tag \"<TD WIDTH=90 HEIGHT=20 BACKGROUND=$img/\$_type.gif>\[ossweb::widget widget_t html]</TD>\"
           }
           if { \$_form_tag != {} } {
             ossweb::adp::Write \"
             <TABLE BORDER=0 WIDTH=$width CELLSPACING=0 CELPADDING=0><TR><TD ALIGN=RIGHT>
             <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0 HEIGHT=20>
             <TR ALIGN=CENTER>
               <TD WIDTH=80 HEIGHT=20>&nbsp;</TD>
               \$_form_tag
               <TD WIDTH=10 HEIGHT=20>&nbsp;</TD>
             </TR>
             </TABLE>
             <TABLE WIDTH=100% BORDER=0 CELLSPACING=0 CELLPADDING=0>
             <TR><TD WIDTH=100% HEIGHT=5><IMG SRC=$img/top.gif WIDTH=100% HEIGHT=5 BORDER=0></TD></TR>
             </TABLE>
             </TD>
             </TR>
             </TABLE>\"
           }
         }
       "
     }

     text {
       set color [ns_set get $params color black]
       set bgcolor [ns_set get $params bgcolor #CFDFFC]
       set bgcolor2 [ns_set get $params bgcolor2 #2793D3]

       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           ossweb::adp::Write {}
           set _tab \[ossweb::coalesce $tab_name {}]
           set _form_tag {}
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             set _color \[ossweb::decode \$_tab \$widget_t(id) $bgcolor $bgcolor2]
             set widget_t(class) $tab_class
             ossweb::widget \$widget_id set_attr STYLE {color:$color; font-weight:bold}
             append _form_tag \"
                  <TD ALIGN=LEFT BGCOLOR=\$_color><IMG BORDER=0 SRC=$img/left.gif WIDTH=4 HEIGHT=18></TD>
                  <TD NOWRAP WIDTH=16% VALIGN=MIDDLE ALIGN=CENTER BGCOLOR=\$_color>\[ossweb::widget widget_t html]</TD>
                  <TD ALIGN=RIGHT BGCOLOR=\$_color><IMG BORDER=0 SRC=$img/right.gif WIDTH=4 HEIGHT=18></TD>\"
           }
           if { \$_form_tag != {} } {
             ossweb::adp::Write \"
                 <TABLE BORDER=0 WIDTH=$width CELLSPACING=0 CELLPADDING=0><TR>\$_form_tag</TR></TABLE>\"
           }
         }"
     }

     ebay {
       set color [ns_set get $params color #cccccc]
       set bgcolor [ns_set get $params bgcolor #D6DCFE]
       set bgcolor2 [ns_set get $params bgcolor2 #EEEEF8]

       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           ossweb::adp::Write {}
           set _tab \[ossweb::coalesce $tab_name {}]
           set _form_tag {}
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             set _color \[ossweb::decode \$_tab \$widget_t(id) $bgcolor $bgcolor2]
             set _mode \[ossweb::decode \$_tab \$widget_t(id) on off]
             set widget_t(class) $tab_class
             append _form_tag \"
                  <TD VALIGN=BOTTOM>
                    <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0>
                    <TR>
                      <TD ROWSPAN=2 BGCOLOR=$color><IMG SRC=$img/1.gif WIDTH=1></TD>
                      <TD VALIGN=TOP COLSPAN=2 HEIGHT=1 BGCOLOR=$color><IMG SRC=$img/1.gif></TD>
                      <TD BACKGROUND=$img/b\$_mode.gif ROWSPAN=2 VALIGN=TOP ALIGN=RIGHT><IMG SRC=$img/t\$_mode.gif ALIGN=TOP></TD>
                    </TR>
                    <TR><TD BGCOLOR=\$_color> </TD>
                      <TD ALIGN=CENTER BGCOLOR=\$_color><IMG SRC=$img/1.gif VSPACE=2><BR><FONT SIZE=-1><B>\[ossweb::widget widget_t html]</B></FONT><BR><IMG SRC=$img/1.gif VSPACE=2><BR></TD>
                    </TR>
                    </TABLE>
                  </TD>
                  <TD><IMG SRC=$img/1.gif HSPACE=1></TD>\"
           }
           if { \$_form_tag != {} } {
             ossweb::adp::Write \"
                 <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0><TR>\$_form_tag</TR></TABLE>
                 <TABLE WIDTH=$width HEIGHT=2 CELLPADDING=0 CELLSPACING=0 BORDER=0>
                 <TR BGCOLOR=$bgcolor><TD HEIGHT=5><IMG SRC=$img/home/1.gif WIDTH=1 HEIGHT=2 BORDER=0></TD></TR>
                 </TABLE>\"
           }
         }"
     }

     square {
       set class [ns_set get $params class osswebTabSquare]
       set class1 [ns_set get $params class1 osswebTabSquare1]
       set class2 [ns_set get $params class2 osswebTabSquare2]
       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           ossweb::adp::Write {}
           set _tab \[ossweb::coalesce $tab_name {}]
           set _form_tag {}
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             set _class \[ossweb::decode \$_tab \$widget_t(id) $class2 $class1]
             set widget_t(class) $tab_class
             append _form_tag \"<DIV CLASS=\$_class>\[ossweb::widget widget_t html]</DIV>\"
           }
           if { \$_form_tag != {} } { ossweb::adp::Write \"<DIV CLASS=$class>\$_form_tag</DIV>\" }
         }"
     }

     oval {
       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           ossweb::adp::Write {}
           set _tab \[ossweb::coalesce $tab_name {}]
           set _form_tag {}
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             set _type \[ossweb::decode \$_tab \$widget_t(id) 2 1]
             set widget_t(class) $tab_class
             append _form_tag \"<TD><IMG SRC=$img/left\$_type.gif WIDTH=10 HEIGHT=22 BORDER=0></TD>
                                <TD NOWRAP BACKGROUND=$img/bg\$_type.gif>\[ossweb::widget widget_t html\]</TD>
                                <TD><IMG SRC=$img/right\$_type.gif WIDTH=10 HEIGHT=22 BORDER=0></TD>\"
           }
           if { \$_form_tag != {} } {
             ossweb::adp::Write \"
                 <TABLE WIDTH=$width CELLPADDING=0 CELLSPACING=0 BORDER=0>
                 <TR><TD BACKGROUND=$img/line.gif HEIGHT=22>
                     <TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0><TR>\$_form_tag</TR></TABLE>
                     </TD>
                 </TR>
                 </TABLE>\"
           }
         }"
     }

     oval2 {
       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           ossweb::adp::Write {}
           set _tab \[ossweb::coalesce $tab_name {}]
           set _form_tag {}
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             set _class \[ossweb::decode \$_tab \$widget_t(id) c {}]
             set widget_t(class) osswebTabOval2a\$_class
             append _form_tag \"<LI CLASS=osswebTabOval2l\$_class>\[ossweb::widget widget_t html\]\"
           }
           if { \$_form_tag != {} } {
             ossweb::adp::Write \"
                 <DIV CLASS=osswebTabOval2><UL>\$_form_tag</UL></DIV>\"
           }
         }"
     }

     default {
       ossweb::adp::AppendData "
           <CENTER>
           <TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>"
       ossweb::adp::AppendCode "
         set _level \[ossweb::adp::Level\]
         upvar #\$_level $id form_t
         if { \[info exists form_t\] && \$form_t(widgets) != {} } {
           set _count 0
           set _selected 0
           set _result {}
           set _row1 {}
           set _row2 {}
           set _tab \[ossweb::coalesce $tab_name {}\]
           foreach widget_id \$form_t(widgets) {
             upvar #\$_level \$widget_id widget_t
             if { \$widget_t(type) != \"link\" } { continue }
             incr _count
             set _class \[ossweb::decode \$_tab \$widget_t(id) osswebTabSelected osswebTab]
             if { \$_class == \"osswebTabSelected\" } { set _selected \[llength \$_result\] }
             append _row1 \"
               <TD CLASS=\$_class ROWSPAN=2><IMG SRC=$img/left.gif WIDTH=6 HEIGHT=22></TD>
               <TD BGCOLOR=#000000 WIDTH=1 HEIGHT=1><IMG SRC=$img/top.gif WIDTH=1 HEIGHT=1></TD>
               <TD CLASS=\$_class ROWSPAN=2><IMG SRC=$img/right.gif WIDTH=6 HEIGHT=22></TD>\"
             set widget_t(class) $tab_class
             append _row2 \"<TD CLASS=\$_class>\[ossweb::widget widget_t html]</TD>\"
             if { \$_count == $cols} {
               lappend _result \"<TR VALIGN=TOP>\$_row1</TR><TR>\$_row2</TR>\"
               set _count 0
               set _row1 {}
               set _row2 {}
             }
           }
           if { \$_row1 != {} } {
             lappend _result \"<TR VALIGN=TOP>\$_row1</TR><TR>\$_row2</TR>\"
           }
           set _row1 \[lindex \$_result \$_selected\]
           set _result \[lreplace \$_result \$_selected \$_selected\]
           ossweb::adp::Write \[join \$_result \" \"\]
           ossweb::adp::Write \$_row1
         }"
       ossweb::adp::AppendData "</TABLE></CENTER>"
     }
    }
    if { $form == 1 } {
      ossweb::adp::AppendData "</FORM>"
    }
}

# Report a form error if one is specified, if full widget name is specified, returns just widget's error
ossweb::tag::create formerror { params } {

    set id [ns_set iget $params id]
    if { [string first . $id] == -1 } {
      ossweb::adp::AppendData "\[ossweb::html::font -class osswebError \[ossweb::form $id error\]\]"
    } else {
      ossweb::adp::AppendData "\[ossweb::html::font -class osswebError \[ossweb::widget $id error\]\]"
    }
}

# Render the HTML for the form widget
ossweb::tag::create formwidget { params } {

    set id [ns_set iget $params id]
    if { [string first . $id] == -1 } {
      set id "\[ossweb::conn form:id\].$id"
    }
    set name [ns_set iget $params name html]
    set html [string map { &lt; < &gt; > } [ns_set iget $params append]]
    ossweb::adp::AppendData "\[ossweb::widget \"$id\" $name {$html}\]"
    # Per widget HTML fragments
    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::conn -clear html:widget\]"
}

# Display form widget label
ossweb::tag::create formlabel { params } {

    set id [ns_set iget $params id]
    if { [string first . $id] == -1 } {
      set id "\[ossweb::conn form:id\].$id"
    }
    set html [string map { &lt; < &gt; > } [ns_set iget $params append]]
    ossweb::adp::AppendData "\[ossweb::widget \"$id\" html:label {$html}\]"
}

# Display form widget help
ossweb::tag::create formhelp { params } {

    set id [ns_set iget $params id]
    if { [string first . $id] == -1 } {
      set id "\[ossweb::conn form:id\].$id"
    }
    ossweb::adp::AppendCode "
      if { \[ossweb::widget \"\[ossweb::conn form:id\].$id\" help\] != {} } {
        ossweb::adp::Write \"<A NAME=I_$id  STYLE='text-decoration:none;' \[ossweb::html::popup_handlers H_$id\]>&nbsp;&nbsp;\[ossweb::html::image question.gif\]</A>\"
        ossweb::adp::Write \[ossweb::html::popup_object H_$id \[ossweb::widget \"$id\" help\]\]
      }"
}

# Render a group of form widgets
ossweb::tag::create formgroup { chunk params } {

    set id [ns_set iget $params id]
    if { [string first . $id] == -1 } { set id "\[ossweb::conn form:id\].$id" }
    ossweb::adp::AppendCode "ossweb::widget \"$id\" formgroup"
    ns_set update $params name formgroup
    ns_set update $params id formgroup
    ossweb::tag::tag_multirow $chunk $params
}

ossweb::tag::create formtemplate { chunk params } {

    set id [ns_set iget $params id]
    # Put additional parameters into form properties
    upvar #[ossweb::adp::Level] $id form
    for { set i 0 } { $i < [ns_set size $params] } { incr i } {
      append attrs "-[ns_set key $params $i] \"[ns_set value $params $i]\" "
    }
    ossweb::adp::AppendCode "ossweb::form $id $attrs"
    # Remember the form we are rendering
    ossweb::adp::AppendCode "ossweb::conn -set form:id $id"
    ossweb::adp::AppendData "\[ossweb::form $id html\]"
    if { [string trim $chunk] == "" } {
      ossweb::adp::AppendData "\[ossweb::form $id template [ns_set iget $params style]\]"
    } else {
      ossweb::adp::Parse $chunk
    }
    ossweb::adp::AppendData "</FORM>"
    # Per widget HTML fragments
    ossweb::adp::AppendCode "ossweb::adp::Write \[ossweb::conn -clear html:widget\]"
}

# Repeat a template chunk for each form widget
ossweb::tag::create formwidgets { chunk params } {

    set id [ns_set iget $params id]
    set pattern [ns_set iget $params pattern ".*"]
    set widget [ns_set iget $params widget widget]
    set type [ns_set iget $params type]
    set name [ns_set iget $params name]
    set value [ns_set iget $params value]
    ossweb::adp::AppendCode "
      set level \[ossweb::adp::Level\]
      upvar #\$level $id form
      foreach widget_id \$form(widgets) {
        upvar #\$level \$widget_id $widget
        if { !\[regexp {$pattern} \$${widget}(name)\] } { continue }
        if { {$type} != {} && !\[regexp {$type} \$${widget}(type)\] } { continue }
        if { {$name} != {} && {$value} != {} && !\[regexp {$value} \$${widget}($name)\] } { continue }
    "
    ossweb::adp::Parse $chunk
    ossweb::adp::AppendCode "}"
}

# Row family of tags that show table TR rows with special
# color palette and implements different colors for odd and even
# rows of a table.
ossweb::tag::create row { chunk params } {

   ossweb::tag::rowtag $chunk $params row
}

ossweb::tag::create rowfirst { chunk params } {

   ossweb::tag::rowtag $chunk $params first
}

ossweb::tag::create rowsection { chunk params } {

   ossweb::tag::rowtag $chunk $params section
}

ossweb::tag::create rowlast { chunk params } {

   ossweb::tag::rowtag $chunk $params last
}

# Title row with info at the right corner
ossweb::tag::create rowtitle { chunk params } {

    regsub -all {"} $chunk {\"} chunk
    set data "
     <TD COLSPAN=[ns_set iget $params colspan] VALIGN=TOP>
       <TABLE BORDER=0 WIDTH=100% CELLSPACING=0 CELLPADDING=0>
       <TR VALIGN=TOP>
         <TD CLASS=osswebTitle>[ossweb::html::font -type [ns_set iget $params font] $chunk]</TD>
         <TD ALIGN=RIGHT><B>[ns_set iget $params info]</B></TD>
       </TR>
       </TABLE>
     </TD>"
    ns_set idelkey $params colspan
    ns_set idelkey $params info
    switch [ns_set iget $params type] {
     row {
       ossweb::tag::tag_row $data $params
     }
     last {
       ossweb::tag::tag_rowlast $data $params
     }
     section {
       ossweb::tag::tag_rowsection $data $params
     }
     default {
       ossweb::tag::rowtag $data $params title
     }
    }
}

ossweb::tag::create multipage { params } {

   set name "[ns_set iget $params name]:mp"
   set query [ns_set iget $params query]
   set images [ns_set iget $params images 1]
   set width [ns_set iget $params width 100%]
   set pages [ns_set iget $params pages 10]

   ossweb::adp::AppendCode "
     if { \[array exists $name] && \[info exists ${name}(pagecount)] } {"
   if { $query != "" } {
     ossweb::adp::AppendCode "set ${name}(query) {$query}"
   }
   ossweb::adp::AppendData "<TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0 WIDTH=$width ><TR>"
   ossweb::adp::AppendCode "
     if { \${${name}(previous_page)} > 0 } {
       ossweb::adp::Write \"<TD WIDTH=5% NOWRAP>\[ossweb::html::link [ossweb::decode $images 1 "-image prev.gif -alt Prev" "-text {Prev | }"] -url \${${name}(url)} -query \${${name}(query)} \[ossweb::conn page_name\] \${${name}(cmd)} \${${name}(cmd_name)} page \${${name}(previous_page)}\]</TD>\"
     }"
   ossweb::adp::AppendData "<TD ALIGN=CENTER NOWRAP>"
   ossweb::adp::AppendCode "
     if { \${${name}(pagecount)} > 1 } {
       set offset \[expr \$page-$pages/2\]
       if { \$offset <= 0 } { set offset 1 }
       if { \$offset > 1 } {
         ossweb::adp::Write \[ossweb::html::link -text \"1 ... \" -url \${${name}(url)} -query \${${name}(query)} \[ossweb::conn page_name\] \${${name}(cmd)} \${${name}(cmd_name)} page 1\]
       }
       for { set i \$offset } { \$i < \$offset+$pages && \$i <= \${${name}(pagecount)} } { incr i } {
         if { \$i > 1 } { ossweb::adp::Write \" | \" }
         if { \$i == \$page } {
           ossweb::adp::Write \"<B>\$i</B> (\${${name}(start)} to \${${name}(end)} of \${${name}(rowcount)})\"
         } else {
           ossweb::adp::Write \[ossweb::html::link -text \$i -url \${${name}(url)} -query \${${name}(query)} \[ossweb::conn page_name\] \${${name}(cmd)} \${${name}(cmd_name)} page \$i\]
         }
       }
       if { \$i < \${${name}(pagecount)} } {
         ossweb::adp::Write \[ossweb::html::link -text \" ... \${${name}(pagecount)}\" -url \${${name}(url)} -query \${${name}(query)} \[ossweb::conn page_name\] \${${name}(cmd)} \${${name}(cmd_name)} page \${${name}(pagecount)}\]
       }
     }
     "
   ossweb::adp::AppendData "</TD>"
   ossweb::adp::AppendCode "
     if { \${${name}(next_page)} > 0 } {
       ossweb::adp::Write \"<TD ALIGN=RIGHT WIDTH=5% NOWRAP>\[ossweb::html::link [ossweb::decode $images 1 "-image next.gif -alt Next" "-text { | Next}"] -url \${${name}(url)} -query \${${name}(query)} \[ossweb::conn page_name\] \${${name}(cmd)} \${${name}(cmd_name)} page \${${name}(next_page)}\]</TD>\"
     }"
   ossweb::adp::AppendData "</TR></TABLE>"
   ossweb::adp::AppendCode "}"
}

ossweb::tag::create calendar { params } {

   set id [ns_rand]
   set type [ns_set iget $params type month]
   set dayurl [ns_set iget $params dayurl]
   set dayurltype [ns_set iget $params dayurltype]
   set moveurl [ns_set iget $params moveurl [ossweb::html::url cmd calendar]]
   set moveurltype [ns_set iget $params moveurltype]
   set moveurlargs [ossweb::nvl [ns_set iget $params moveurlargs] null]
   set date [ns_set iget $params date date]
   set datename [ns_set iget $params datename date]
   set data [ns_set iget $params data __empty]
   set selected [ns_set iget $params selected]
   set small [ns_set iget $params small]
   set day1 [ns_set iget $params day1 0]
   set day2 [ns_set iget $params day2 7]
   set align [ns_set iget $params align LEFT]
   set width [ns_set iget $params width]
   set height [ns_set iget $params height]
   set cal:html [ns_set iget $params html]
   # Moving url
   switch -- $moveurltype {
    javascript {
       set calendarMove "function calendarMove(date,type) { return ${moveurl}(date,type,$moveurlargs); }"
    }
    default {
       set calendarMove "function calendarMove(date,type) { var u='${moveurl}&type='+type+'&$datename='+date;window.location=u; }"
    }
   }
   # Calendar size
   switch $small {
    1 {
      set cal:width $width
      set cal:height $height
      set cal:short 1
    }
    default {
      set cal:width "WIDTH=100%"
      set cal:height "HEIGHT=70"
      set cal:short 0
    }
   }
   ossweb::adp::AppendCode "
     set _date \[ossweb::nvl $date \[ns_time]]
     if { \[string is integer -strict \$_date] } {
       foreach { _month _day _year } \[ns_fmttime \$_date \"%m %d %Y\"\] {}
     } else {
       foreach { _month _day _year } \[split \$_date /] {}
       set _date \[clock scan \$_date\]
     }
     foreach { _today_month _today_day _today_year } \[ns_fmttime \[ns_time\] \"%m %d %Y\"] {}
     switch -- ${type} {
      week {
        set _days \[ossweb::date weekArray \$_day \$_month \$_year\]
        set _date \[clock scan \[lindex \$_days 0\]\]
        set _title \[ns_fmttime \$_date \"Week of %B %d, %Y\"\]
        set _prev \[expr \$_date-86400*8]
        set _next \[expr \$_date+86400*8]
      }
      default {
        set _title \[ns_fmttime \$_date \"%B, %Y\"\]
        set _days \[ossweb::date monthArray \$_month \$_year\]
        set _prev \[ossweb::date prevMonth \$_month \$_year\]
        set _next \[ossweb::date nextMonth \$_month \$_year\]
      }
     }
   "
   array set obj { form:id "" id calendar name calendar notext 1 proc calendarUrl inline 1 }
   set calendar [ossweb::widget::calendar obj html]
   regsub -all {["\\]} $calendar {\\&} calendar ; # "
   # Display calendar header
   ossweb::adp::AppendData "
     <SCRIPT LANGUAGE=JavaScript>
       function calendarUrl(o,d,s) {
         calendarMove(d.getMonth()+1+'/'+d.getDate()+'/'+d.getFullYear(),'$type');
       }
       $calendarMove
     </SCRIPT>
     <TABLE CLASS=osswebCalendar BORDER=1 CELLSPACING=0 CELLPADDING=0 ${cal:width}>
     <TR CLASS=osswebLastRow VALIGN=TOP>
      <TD><A CLASS=osswebLink HREF=\\\"javascript:;\\\" onClick=\\\"return calendarMove('\$_prev','$type');\\\">&lt;&lt;</A></TD>
      <TD COLSPAN=[expr $day2-$day1-2] ALIGN=CENTER CLASS=osswebTitle>\$_title &nbsp; $calendar</TD>
      <TD ALIGN=RIGHT><A CLASS=osswebLink HREF=\\\"javascript:;\\\" onClick=\\\"return calendarMove('\$_next','$type');\\\">&gt;&gt;</A></TD>
     </TR>
     <TR CLASS=osswebCalendarTitle>
   "
   ossweb::adp::AppendCode "
     for { set i $day1 } { \$i < $day2 } { incr i } {
       ossweb::adp::Write \"<TH>\[ossweb::date weekDayName \$i ${cal:short}]</TH>\"
     }
     ossweb::adp::Write \"</TR>\"
   "
   # Display calendar days
   ossweb::adp::AppendCode "
     switch -- ${type} {
      week {
          set _opts { {} {} {} {} {} {} {} }
          set _today \[lsearch -exact \$_days \"\$_today_month/\$_today_day/\$_today_year\"\]
          if { \$_today != -1 } {
            set _opts \[lreplace \$_opts \$_today \$_today \"CLASS=osswebCalendarToday\"\]
          }
          ossweb::adp::Write \"<TR VALIGN=TOP>\"
          for { set i $day1 } { \$i < $day2 } { incr i } {
            set _date \[lindex \$_days \$i]
            if { \$_date != {} } {
              if { {$dayurl} != {} } {
                switch {$dayurltype} {
                 javascript {
                   set _entry \"<B><A CLASS=osswebLink HREF=\\\"javascript:;\\\" onClick=\\\"return ${dayurl}('\$_date','$type')\\\">\[lindex \[split \$_date /\] 1\]</A></B><BR>\"
                 }
                 default {
                   set _entry \"<B><A CLASS=osswebLink HREF=\\\"$dayurl&type=$type&$datename=\$_date\\\">\[lindex \[split \$_date /\] 1\]</A></B><BR>\"
                 }
                }
              } else {
                set _entry \"<B>\[lindex \[split \$_date /\] 1\]</B>\"
              }
              set _data \[ossweb::coalesce ${data}(\$_date)\]
              if { \$_data != {} } {
                append _entry \"<TABLE BORDER=0 WIDTH=100% ><TR><TD ALIGN=$align>\$_data</TD></TR></TABLE>\"
              }
            } else {
              set _entry {&nbsp}
            }
            ossweb::adp::Write \"<TD WIDTH=14% ${cal:html} ${cal:height} \[lindex \$_opts \$i\]>\$_entry</TD>\"
          }
          ossweb::adp::Write \"</TR>\"
      }

      default {
        for { set w 0 } { \$w < 6 } { incr w } {
          set _index \[expr \$w*7]
          set _week \[lrange \$_days \$_index \[expr \$_index+6]]
          if { \$w > 0 && \[lindex \$_week 0\] == {} } { break }
          set _opts { {} {} {} {} {} {} {} }"
   # Highlight selected day
   if { $selected == 1 } {
     ossweb::adp::AppendCode "
          set _today \[lsearch -exact \$_week \$_day\]
          if { \$_today != -1 } {
            set _opts \[lreplace \$_opts \$_today \$_today \"CLASS=osswebCalendarSelected\"\]
          }"
   }
   ossweb::adp::AppendCode "
          # Highlight today for current month only
          if { \$_year == \$_today_year && \$_month == \$_today_month } {
            set _today \[lsearch -exact \$_week \$_today_day\]
            if { \$_today != -1 } {
              set _opts \[lreplace \$_opts \$_today \$_today \"CLASS=osswebCalendarToday\"\]
            }
          }
          ossweb::adp::Write \"<TR VALIGN=TOP>\"
          for { set i $day1 } { \$i < $day2 } { incr i } {
            set _wday \[lindex \$_week \$i\]
            set _date \"\$_month/\$_wday/\$_year\"
            if { \$_wday != {} } {
              if { {$dayurl} != {} } {
                switch {$dayurltype} {
                 javascript {
                   set _entry \"<B><A CLASS=osswebLink HREF=\\\"javascript:;\\\" onClick=\\\"return ${dayurl}('\$_date','$type')\\\">\[lindex \[split \$_date /\] 1\]</A></B><BR>\"
                 }
                 default {
                   set _entry \"<B><A CLASS=osswebLink HREF=\\\"$dayurl&type=$type&$datename=\$_date\\\">\[lindex \[split \$_date /\] 1\]</A></B><BR>\"
                 }
                }
              } else {
                set _entry \"<B>\[lindex \[split \$_date /\] 1\]</B>\"
              }
              set _data \[ossweb::coalesce ${data}(\$_date)\]
              if { \$_data != {} } {
                append _entry \"<TABLE BORDER=0 WIDTH=100% ><TD><TD ALIGN=$align>\$_data</TD></TR></TABLE>\"
              }
            } else {
              set _entry {&nbsp;}
            }
            ossweb::adp::Write \"<TD WIDTH=14% ${cal:html} ${cal:height} \[lindex \$_opts \$i\]>\$_entry</TD>\"
          }
          ossweb::adp::Write \"</TR>\"
        }
      }
     }
   "
   ossweb::adp::AppendData "</TABLE>"
}

