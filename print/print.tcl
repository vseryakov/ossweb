# Author: Vlad Seryakov vlad@crystalballinc.com
# September 2003

ossweb::conn::callback print_action {} {

    set queue t
    if { ![ossweb::conn::check_acl -acl "*.print.queue.print.*"] } { set queue f }
    print::submit \
        -queue $queue \
        -printer [ns_queryget printer] \
        -text [ns_queryget text] \
        -files [list \
                [ns_queryget file1.tmpfile] [ns_queryget file1] \
                [ns_queryget file2.tmpfile] [ns_queryget file2] \
                [ns_queryget file3.tmpfile] [ns_queryget file3]]
    ossweb::conn::set_msg "Files have been queued for printing"
    ossweb::form form_print reset
}

ossweb::conn::callback print_view {} {

}

ossweb::conn::callback create_form_print {} {

     ossweb::form form_print -title "Printing Service"
     set printers ""
     foreach { name value } [ossweb::config server:printers] {
       lappend printers [list $name $value]
     }
     ossweb::widget form_print.printer -type select -label Printer \
          -empty -- \
          -options $printers
     ossweb::form form_print -section "Type and print text"
     ossweb::widget form_print.text -type textarea -label Text \
          -html { cols 80 rows 10 } \
          -optional
     ossweb::form form_print -section "Upload and print file(s)"
     ossweb::widget form_print.file1 -type file -label "File 1" \
          -optional\
          -class_row osswebSectionRow
     ossweb::widget form_print.file2 -type file -label "File 2" \
          -optional
     ossweb::widget form_print.file3 -type file -label "File 3" \
          -optional
     ossweb::widget form_print.print -type submit -name cmd -label Print
     ossweb::widget form_print.reset -type reset -label Reset -clear
}

ossweb::conn::process \
     -forms form_print \
     -on_error index \
     -eval {
       print {
         -exec { print_action }
       }
       default {
         -exec { print_view }
       }
     }


