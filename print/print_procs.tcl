# Author: Vlad Seryakov vlad@crystalballinc.com
# September 2003

namespace eval print {

  variable version "Print version 1.2"
  variable lpr_bin ""
  variable pdf_bin ""
  variable office_bin ""
  variable office_home /home/nobody/.openoffice/
  variable office_display :0

  namespace eval google {}
}

namespace eval ossweb {
  namespace eval html {
    namespace eval toolbar {}
  }
}

ossweb::register_init print::init

# Printer subsystem initialization
proc print::init {} {

    variable lpr_bin
    variable pdf_bin
    variable office_bin

    nsv_set ossweb:print id 0

    if { [set lpr_bin [glob -nocomplain /usr/bin/lpr]] == "" } {
      set lpr_bin [glob -nocomplain /usr/ucb/bin/lpr]
    }

    if { [set pdf_bin [glob -nocomplain /usr/local/bin/pdftops]] == "" &&
         [set pdf_bin [glob -nocomplain /usr/bin/pdftops]] == "" } {
      set pdf_bin [glob -nocomplain /usr/local/bin/pdftops]
    }

    if { [set office_bin [glob -nocomplain /usr/bin/soffice]] == "" } {
      set office_bin [glob -nocomplain /usr/local/bin/soffice]
    }
    if { $office_bin == "" } {
      set local [glob -nocomplain /usr/local/*]
      if { [regexp -nocase {(/usr/local/openoffice[^ ]+)} $local d office_dir] } {
        set office_bin [glob -nocomplain $office_dir/program/soffice]]
      }
    }
    ossweb::file::register_download_proc print ::print::download
    ns_log Notice print::init: using '$lpr_bin' for text files
    ns_log Notice print::init: using '$pdf_bin' for PDF files
    ns_log Notice print::init: using '$office_bin' for MS Word/Excel files
}

# Link to print from the toolbar
proc ossweb::html::toolbar::print {} {

    if { [ossweb::conn::check_acl -acl *.print.print.view.*] } { return }
    return [ossweb::html::link -image /img/toolbar/print.gif -mouseover /img/toolbar/print_o.gif -hspace 6 -status print -alt print -app_name print print]
}

# File download handler, used by ossweb::file::download for file download verification
proc print::download { params } {

    ns_set update $params file:path pqueue/[ns_set get $params printer]
    return file_return
}

# Submit file to the printing queue
proc print::submit { args } {

    ns_parseargs { {-printer lp} {-text ""} {-files ""} {-keep f} {-debug f} {-queue t} } $args

    if { $text != "" } {
      set tmp_file /tmp/[nsv_incr ossweb:print id].txt
      ossweb::write_file $tmp_file $text
      lappend files $tmp_file {}
    }
    ns_log Notice print::submit: [ossweb::conn user_id 0]: $printer: $files
    # Submit files to the queue
    foreach { file name } $files {
      if { ![file exists $file] || ![file size $file] } { continue }
      if { $name == "" } { set name $file }
      if { $queue == "t" } { append name .@@@ }
      set name [lindex [split $name "\\/"] end]
      ossweb::file::rename $file $name -path pqueue/$printer -unique t
    }
    return
}

# Sends file to the printer from the queue
proc print::send { name } {

    if { ![string match *.@@@ $name] } { return }
    if { [catch { file rename -force -- $name [string range $name 0 end-4] } errmsg] } {
      ns_log Error print::send: $name: $errmsg
    }
}

# Print schedule for processing queue
proc print::schedule {} {

    foreach printer [ossweb::file::list -path pqueue -types d -dirname f] {
      set files ""
      foreach file [ossweb::file::list -path pqueue/$printer] {
        if { ![string match *.@@@ $file] } { lappend files $file "" }
      }
      if { $files != "" } {
        print::print $files -printer $printer -keep f
      }
    }
}

# Perform actual printing
proc print::print { files args } {

    variable lpr_bin
    variable pdf_bin
    variable office_bin
    variable office_home
    variable office_display

    ns_parseargs { {-printer lp} {-keep f} {-debug f} } $args

    set pdf_files ""
    set text_files ""
    set office_files ""

    foreach { file name } $files {
      if { ![file exists $file] || ![file size $file] } { continue }
      if { $name == "" } { set name $file }
      switch -regexp -- [string tolower $name] {
       {\.(doc|xls|rtf)$} {
         append office_files "\"$file\" "
       }
       {\.pdf$} {
         lappend pdf_files $file
       }
       default {
        append text_files "\"$file\" "
       }
      }
    }
    # Printing through local LPD
    if { $text_files != "" } {
      if { $lpr_bin != "" } {
        catch { eval exec -- $lpr_bin -P $printer $text_files } errmsg
        if { $errmsg != "" } { ns_log Error print::print: $errmsg }
        ns_log Notice print::print: txt: $text_files
      }
      if { $keep == "f" } { eval file delete $text_files }
    }
    # Printing through OpenOffice
    if { $office_files != "" } {
      if { $office_bin != "" } {
        catch { eval exec -- $office_bin -display $office_display -userid=$office_home -pt $printer $office_files } errmsg
        if { $errmsg != "" } { ns_log Error print::print: $errmsg }
        ns_log Notice print::print: office: $office_files
      }
      if { $keep == "f" } { eval file delete $office_files }
    }
    # Printing PDF files
    if { $pdf_files != "" } {
      if { $pdf_bin != "" && $lpr_bin != "" } {
        foreach file $pdf_files {
          catch { eval exec -- $pdf_bin \"$file\" - | $lpr_bin -P $printer } errmsg
          if { $errmsg != "" } { ns_log Error print::print: $errmsg }
        }
        ns_log Notice print::print: pdf: [join $pdf_files]
      }
      if { $keep == "f" } { foreach file $pdf_files { file delete $file } }
    }
}

