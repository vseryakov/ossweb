# Wikitext markup to HTML rendering - Oct 2001, by Jean-Claude Wippler
#
# Wiki formatting rules
#
# References:
#
#    1. You can refer to another page by putting its name in square brackets like this: [PAGE]
#    2. URLs will be automatically recognized and underlined: http://your.site/contents.html
#    3. If you put URL's in square brackets, they'll be shown as a tiny reference [1] instead, or
#       as inline images if they have the extension .gif or .jpg
#
# Adding highlights:
#
#    * Surround text by pairs of single quotes to make it display in italic
#    * Surround text by triples of single quotes to make it display in bold
#
# Adding structure to your text:
#
#    * Lines of text are normally joined, with empty lines used to delineate paragraphs
#    * Lines starting with three spaces, a "*", and another space are shown as bulleted items.
#      The entire item must be entered as one line (possibly wrapping)
#    * To create a numbered list, replace the "*" by "1."
#    * To create a tagged list, use: three spaces, item tag, ":", three spaces, item text
#
#    All other lines starting with white space are shown as is.
#
#    * Put four or more dashes on a line to get a horizontal separator,
#

namespace eval wiki {

}

# get a new unused page number
proc wiki::pagenum {} {

    variable versions
    set n 0
    foreach x [array names versions] {
      if { $x >= $n } {
        set n [incr x]
      }
    }
    return $n
}

# convert internal page reference to a link
proc wiki::pageref { text } {

    set t [string tolower $text]
    set exists [file exists [ns_info home]/modules/wiki/$t]
    if { $exists } {
      set page [lindex $t 0]
    } else {
      set page [pagenum]
    }
    return [list $page $exists]
}

# apply basic html ampersand substitutions
proc wiki::htmlize {s} {

    regsub -all {&} $s {\&amp;} s
    regsub -all {<} $s {\&lt;} s
    regsub -all {>} $s {\&gt;} s
    regsub -all {"} $s {\&quot;} s ; # "
    regsub -all {&amp;(#\d+;)} $s {\&\1} s
    return $s
}

# transform "[title]" page reference to relative links
proc wiki::refs { t } {

    regsub -all {\[\[} $t {\&!} t
    set re {(.*?)\[([^\]:]*)]}
    set x [regexp -all -inline $re "$t\[]"]
    if { [llength $x] > 3 } {
      set t ""
      foreach { a b c } $x {
	append t $b
	set c [string trim $c]
	if { $c != "" } {
	  foreach { url exists } [pageref [list $c]] {}
	  set head "<A HREF=\"$url\">"
	  set tail "</A>"
	  if { $exists } {
	    append t $head $c $tail
	  } else {
	    append t $head {[} $tail $c $head {]} $tail
	  }
	}
      }
    }
    regsub -all {&!} $t {[[} t
    return $t
}

# transform everything that looks like an URL into a link
proc wiki::links { text } {

    set re {\m(https?|ftp|news|mailto):(\S+[^\]\)\s\.,!\?;:'``"">])}
    regsub -all $re $text {<A HREF="\1:\2">\1:\2</A>} text
    return $text
}

# fixup "[<link>]" to show as a numbered external reference
# this version re-uses the same number for duplicate urls
proc wiki::urls { t xrefmap } {

    upvar 1 $xrefmap xrmap

    regsub -all {\[\[} $t {\&!} t
    set re {(.*?)\[<A HREF="(.*?)">\2</A>]}
    set x [regexp -all -inline $re "$t\[<A HREF=\"\"></A>]"]
    if { [llength $x] > 3 } {
      set t ""
      foreach { a b c } $x {
	append t $b
	set url [string trim $c]
	if { $url != "" } {
          if { [regexp -nocase {\.(png|gif|jpg)$} $url] } {
            append t "<IMG SRC=\"$url\">"
          } else {
            if { ![info exists xrmap($url)] } {
              set xrmap($url) [expr {[array size xr]+1}]
            }
            append t "\[<A HREF=\"$url\">$xrmap($url)</A>]"
	  }
        }
      }
    }
    regsub -all {&!} $t {[[} t
    return $t
}

# list "[[" as "[" and "]]" as "]"
proc wiki::brackets { t } {

    regsub -all {\[\[} $t {[} t
    regsub -all {]]} $t {]} t
    return $t
}

# convert '''bold''' and ''italic'' markup
proc wiki::hilites { t } {

    regsub -all {'''(.+?)'''} $t {<B>\1</B>} t
    regsub -all {''(.+?)''} $t {<I>\1</I>} t
    return $t
}

# categorize a line of wiki text based on indentation and prefix
proc wiki::linetype { line } {

    set line [string trimright $line]
    regsub -all "\t" $line "    " line
    foreach { tag re } {
          UL {^(   + {0,2})(\*) (\S.*)$}
          OL {^(   + {0,2})(\d)\. (\S.*)$}
          DL {^(   + {0,2})([^:]+): (\S.*)$}
    } {
      if { [regexp $re $line - pfx aux txt] } {
        return [list $tag [expr {[string length $pfx]/3}] $txt $aux]
      }
    }
    switch -- [string index $line 0] {
     " " - "\t" {
        return [list PRE 1 $line]
     }

     "-" {
       if { [regexp {^-{4,}$} $line] } {
         return [list HR 0 $line]
        }
     }
    }
    return [list STD 0 $line]
}

# convert wiki markup text to html
proc wiki::render { page } {

    set currdepth 0
    set lasttag ""
    set reset ""
    set out ""

    foreach line [split "[string trim $page]\n-----" "\n"] {
      foreach { tag depth txt aux } [linetype $line] {}
      set html [htmlize $txt]
      set d 0

      # empty lines should not reset lists etc.
      if { $tag == "STD" && $txt == "" } {
	set tag $lasttag
	set depth $currdepth
      }

      # repeated styles are treated as a run
      if { $tag == $lasttag && $depth > 0 } {
	set d $depth
      }

      # unnest levels as needed
      while { $d < $currdepth } {
	set lastout [lindex $out end]
	append lastout $reset
	set out [lreplace $out end end $lastout]
	incr currdepth -1
      }
      if { $depth > 0 } {
        set d $depth
      }
      set p ""

      # nest levels as needed
      while { $d > $currdepth } {
	if { $tag == "PRE" } {
	  set html "<PRE>$html"
	  set reset "</PRE>"
	} else {
	  set p "<$tag>$p"
	}
	incr currdepth
      }

      # don't reset lists when there is an empty line
      if { $txt == "" && $tag != "PRE" } {
	set html "<P>"
      } else {
	switch $tag {
	  HR {
	    set n [expr {[string length $txt]-3}]
	    set html "<HR NOSHADE SIZE=$n>"
	  }
	  UL -
	  OL {
	    set html "<LI>$html"
	    set reset "</$tag>"
	  }
	  DL {
	    set html "<DT>[htmlize $aux]<DD>$html"
	    set reset "</DL>"
	  }
	}
      }
      append p $html

      # in verbatim text, only URL underlining may be applied,
      # it is the only markup which does not alter the text shown
      if { $tag == "PRE" } {
	set p [links $p]
      } else {
	set p [refs $p]
	set p [links $p]
	set p [urls $p xrefmap]
	set p [brackets $p]
	set p [hilites $p]
      }
      lappend out $p
      set lasttag $tag
    }
    return [join $out "\n"]
}
