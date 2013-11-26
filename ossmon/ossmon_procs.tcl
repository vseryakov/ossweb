# Author: Vlad Seryakovossweb::coalesce vlad@crystalballinc.com
# August 2001
#
# $Id: ossmon_procs.tcl 3296 2007-02-21 21:23:36Z vlad $

# OSSMON system
namespace eval ossmon {

    variable version {OSSMON 2.2 $Revision: 3296 $}
    variable ossmon_level 0
    variable operators { {= =}
                         {> >}
                         {< <}
                         {!= !=}
                         {>= >=}
                         {<= <=}
                         {contains contains}
                         {match match}
                         {regexp regexp}
                         {"not contains" !contains}
                         {"not match" !match}
                         {"not regexp" !regexp}
                         {"gmatch" gmatch}
                         {"gregexp" gregexp}
                         {"not gmatch" !gmatch}
                         {"not gregexp" !gregexp}
    }

    variable title "OSSMON GLobal"

    # General purpose properties
    variable properties {
       { ossmon:url {OSSMON object details URL} {URL to access OSSMON object details page} {} }
       { ossmon:user_id {OSSMON User ID} {ID of the user from which OSSMON will generate events} {-type userselect } }
       { ossmon:thread:max {Thread Max} {Max number of threads to be used for polling} {-type numberselect  -end 100} }
       { ossmon:thread:threshold {Thread Threshold} {Number of children for the object on the level 2 to fire separate thread for polling instead of doing polling inside one thread one by one.} {-type numberselect -end 100} }
       { ossmon:collect:interval:check {Collect Checker Interval} {Interval between checking if collecting module working properly} {-type intervalselect } }
       { ossmon:collect:history:time {Collect History} {for how long to keep collected data} {-type intervalselect } }
       { ossmon:console:alerts {Console Alerts} {Number of alerts to show on the console} {-type numberselect  -end 25} }
       { ossmon:console:icons {Console Icons} {If set little icons will be used in console maps} {} }
       { ossmon:console:refresh {Console Refresh} {Interval between console refreshes} {-type intervalselect } }
       { ossmon:console:sound {Console Sound} {Sound to play on error} {} }
       { ossmon:console:width {Console Row Width} {Number of icons in the console row} {-type numberselect  -end 25} }
       { ossmon:console:x {Console Map Left Corner} {Default left coordinate for maps} {} }
       { ossmon:console:y {Console Map Top corner} {Default top coordinate for maps} {} }
       { ossmon:debug {OSSMON Debbuging} {Enables OSSMON debug logging} {-type numberselect  -end 10 -start 0} }
       { ossmon:syslog:host {Syslog Host} {} {} }
       { ossmon:syslog:facility {Syslog Facility} {} {-type select -options {kern user mail daemon auth intern print news uucp clock security authpriv ftp local0 local1 local2 local3 local4 local5 local6 local7}} }
       { ossmon:syslog:severity {Syslog Severity} {} {-type select -options {emergency, alert, critical, error, warning, notice, info, or debug}} }
       { ossmon:trap:enterprise {SNMP Trap Enterprise} {} {} }
       { ossmon:trap:host {SNMP Trap Host} {} {} }
       { ossmon:trap:oid {SNMP Trap ID} {} {} }
       { ossmon:trap:port {SNMP Trap Port} {} {-datatype integer -size 5} }
       { ossmon:trap:var {SNMP Trap Var} {} {} }
    }

    # OSSMON objects that perform actual device polling, each namespace for
    # separate object. title is required, the rest of variables are optional and
    # can be inherited if using superclass declaration
    namespace eval object {

      variable title "OSSMON Object"

      variable properties {
         { ossmon:columns {Object Columns} {List of fields representing a row in the object. Usually objects have predefined structure but for SNMP table,group object types it is possible to define which variable to fetch instead of retriving the whole subtree} {} }
         { ossmon:filter {Filter} {Generic filter for different objects} {-type textarea -resize -html { cols 35 rows 2 wrap off}} }
         { ossmon:filter:ignore {Ignore Filter} {} {} }
         { ossmon:auth:user {Auth Username} {Username to be used for authentication} {} }
         { ossmon:auth:password {Auth Password} {Password to be used for authentication} {} }
         { ossmon:auth:secretkey {Auth Secret Key} {} {} }
         { ossmon:hrProcessList {Process List} {List of required processes for hrSWRunTable} {} }
         { ossmon:eval {OSSMON Script} {Script to be executed for every object row received} {-type textarea -resize -html { cols 35 rows 2 wrap off}} }
         { ossmon:ping {Ping Before Poll} {} {-type boolean} }
         { ossmon:chart:title {Object Chart Title} {Title for statistics charts} {} }
         { ossmon:chart:scale {Chart Scale for Bandwidth} {Bandwidth scale factor, devider for bytes/sec} {-type select -options { Mbits Kbits } } }
         { ossmon:charts:interval {Charts Interval} {Interval between saving realtime charts in seconds} {-type intervalselect } }
         { ossmon:admin:email {OSSMON Admin Email} {Email where to send administrative emails} {-datatype email} }
         { ossmon:alert:subject {Alert Subject} {Subject for alerts} {} }
         { ossmon:alert:critical {Alert Critical Pattern} {Regexp defiens keywords to consider alert critical} {} }
         { ossmon:alert:email {Alert Email} {Email where to send alerts} {-datatype email} }
         { ossmon:alert:email:cc {Alert Email CC:} {Also CC alert email to} {} }
         { ossmon:alert:email:error {Alert Email on Error} {Email where to send alerts} {-datatype email} }
         { ossmon:alert:email:noResponse {Alert Email on noResponse} {Email where to send alerts} {-datatype email} }
         { ossmon:alert:email:noConnectivity {Alert Email on noConnectivity} {Email where to send alerts} {-datatype email} }
         { ossmon:alert:exec {Alert Exec Alert Program} {Program to be run on alert} {} }
         { ossmon:alert:exec:closed {Alert Exec Close Program} {Program to be run when alert is about to be closed} {} }
         { ossmon:alert:threshold {Alert Threshold} {Number of alerts after which system stops sending new alerts} {-type numberselect } }
         { ossmon:alert:threshold:noResponse {Alert Threshold for noResponse} {Number of alerts after which system stops sending new alerts} {-type numberselect } }
         { ossmon:alert:threshold:noConnectivity {Alert Threshold for noConnectivity} {Number of alerts after which system stops sending new alerts} {-type numberselect } }
         { ossmon:alert:threshold:period {Alert Threshold Period} {Defines alert threshold for any given period of time, format: start_time duration threshold ...} {} }
         { ossmon:alert:interval {Alert Interval} {Minimum interval between alerts in seconds} {-type intervalselect } }
         { ossmon:alert:interval:noResponse {Alert Interval for noResponse} {Minimum interval between alerts in seconds} {-type intervalselect } }
         { ossmon:alert:interval:noConnectivity {Alert Interval for noConnectivity} {Minimum interval between alerts in seconds} {-type intervalselect } }
         { ossmon:alert:interval:active {Alert Interval Active} {Inactivity period after which active alert will become pending} {-type intervalselect } }
         { ossmon:alert:interval:pending {Alert Interval Pending} {Inactivity period after which pending alert will be closed} {-type intervalselect } }
         { ossmon:alert:interval:period {Alert Interval Period} {Defines alert interval for any given period of time, format: start_time duration interval ...} {} }
         { ossmon:alert:log:dump {Alert Log Dump} {Log object attributes dump in the log record} {} }
         { ossmon:alert:problem:closed:notes {Alert Closed Problem Notes} {Message to be used for closed problems} {} }
         { ossmon:alert:problem:closed:skip {Alert Closed Problem Skip} {Skip closing problem on close alert} {-type boolean} }
         { ossmon:alert:problem:closed:status {Alert Closed Problem Status} {Status to be used for problem when alert is closed} {-type select  -sql sql:problem.status.select.read} }
         { ossmon:alert:problem:notes {Alert Problem Notes} {If true add notes to existing problem, otherwise create new problem record} {-type boolean} }
         { ossmon:alert:problem:project {Alert Problem Project} {Problem project id to be used for OSSMON generated problems} {-type select  -sql sql:problem.project.select.read} }
         { ossmon:alert:problem:status {Alert Problem Status} {} {-type select  -sql sql:problem.status.select.read} }
         { ossmon:alert:problem:type {Alert Problem Type} {} {-type select  -sql sql:problem.type.select.read} }
      }

      namespace eval root {
        variable title "Root Object"
        variable format table
        variable charts collect
        variable reports {
           { "IP Node Failures" ip_node_failure }
           { "IP Node Availability" ip_node_avail }
        }
        variable properties {
           { ossmon:collect {Collect Statistics} {Collect statistics for an object, Yes for high level objects like ifTable, ping, nat or name/value pairs of object attributes. Example: prNames prCount} {-type textarea -resize -html { cols 35 rows 2 wrap off}} }
           { ossmon:collect:interval {Collect Interval} {Interval between saving collected statistics in seconds} {-type intervalselect } }
           { ossmon:poll:interval {Polling Interval} {Interval between polling} {-type intervalselect } }
           { ossmon:poll:skip:period {Poll Skip Period} {Period when not to perform polling} {} }
        }
      }

      namespace eval snmp {
        variable title "SNMP Object"
        variable superclass root
        variable features "snmp"
        variable properties {
           { ossmon:snmp:threshold {SNMP Threshold} {Generic threshold to be used in SNMP variables} {} }
           { ossmon:snmp:bulk {SNMP Bulk Amount} {Number of SNMP variables in one packet for bulk replies} {-type numberselect -end 100} }
           { ossmon:snmp:community {SNMP Community} {SNMP community for read access} {} }
           { ossmon:snmp:fix:name {SNMP Fix Name/Index} {Index or name of the process from the prTable to be fixed on error} {} }
           { ossmon:snmp:interface:index {Interface Index} {Retrieve only interfaces with specified indexes} {} }
           { ossmon:snmp:interface:speed {Interface Speed} {Speed of the interface in case of wrong speed or broken SNMP implementation} {} }
           { ossmon:snmp:oid {SNMP Oid} {SNMP Oid or MIB variable to be monitored} {-info [ossmon::object::get_mibs [ossweb::coalesce obj_type]]} }
           { ossmon:snmp:port {SNMP Port} {Port to be used for SNMP requests} {-size 5 -datatype integer} }
           { ossmon:snmp:retries {SNMP Retries} {SNMP request retries} {-type numberselect -end 10} }
           { ossmon:snmp:timeout {SNMP Timeout} {Timeout for SNMP requests in seconds} {-type intervalselect } }
           { ossmon:snmp:version {SNMP Version} {SNMP protocol version} {-type numberselect -end 2} }
           { ossmon:snmp:writecommunity {SNMP Write Community} {SNMP community for write access} {} }
        }
      }

      namespace eval table {
        variable title "SNMP Table"
        variable superclass snmp
        variable features snmp
        variable properties {
           { disk:used:threshold {Disk Usage Threshold} {Disk threshold in bytes of used space} {} }
        }
      }

      namespace eval ifTable {
        variable title "Interface Table"
        variable superclass snmp
        variable features "noConnectivity cache snmp"
        variable charts "if_load if_rate if_trans if_drop collect"
        variable columns {
           sysUpTimeInstance ifIndex ifDescr ifType ifMtu ifSpeed ifAdminStatus ifOperStatus \
           ifInOctets ifOutOctets ifInDiscards ifOutDiscards ifInErrors ifOutErrors
        }
        variable properties {
           { interface:utilization:threshold {Utilization Threshold} {Utilization threshold in percentages} {-type numberselect -start 0 -end 100} }
           { interface:rate:in:threshold {Input Rate Threshold} {Threshold for input transfer rate in bytes/sec} {} }
           { interface:rate:out:threshold {Output Rate Threshold} {Threshold for output transfer rate in bytes/sec} {} }
        }
        # Interface full duplex types
        variable fullDuplex { regular1822|hdh1822|ddnX25|rfc877x25|lapb|sdlc|e1|basicISDN|primaryISDN|propPointToPointSerial|ppp|slip|ds0|ds1|ds3|sip|frameRelay|ethernetCsmacd|hssi }
      }

      namespace eval prTable {
        variable title "Process Table"
        variable superclass table
      }

      namespace eval dskTable {
        variable title "Disk Table"
        variable superclass table
        variable properties {
           { disk:threshold {Disk Usage Threshold} {Disk threshold in percentage of used space} {-type numberselect -start 0 -end 100} }
        }
      }

      namespace eval laTable {
        variable title "Load Average Table"
        variable superclass table
      }

      namespace eval group {
        variable title "SNMP Group"
        variable superclass snmp
      }

      namespace eval walk {
        variable title "SNMP Walk"
        variable superclass snmp
        variable format var
      }

      namespace eval var {
        variable title "SNMP Variable"
        variable superclass snmp
        variable format var
      }

      namespace eval syslog {
        variable title "Syslog Table"
        variable superclass snmp
        variable features "cache snmp"
        variable columns { syslogMsg }
      }

      namespace eval uptime {
        variable title "Uptime"
        variable superclass var
      }

      namespace eval exec {
        variable title "Exec"
        variable superclass root
        variable features "cache"
        variable columns { execData }
      }

      namespace eval pop3 {
        variable title "POP3"
        variable superclass root
        variable format table
        variable columns { pop3Host pop3Status }
        variable properties {
           { ossmon:pop3:port {POP3 Port} {Port to be used for POP3 requests} {-datatype integer} }
           { ossmon:pop3:timeout {POP3 Timeout} {Timeout to be used for POP3 requests} {-type intervalselect } }
           { ossmon:auth:password {Auth Password} {Password to be used for authentication} {} }
           { ossmon:auth:user {Auth Username} {Username to be used for authentication} {} }
        }
      }

      namespace eval imap {
        variable title "IMAP4"
        variable superclass root
        variable columns { imapHost imapStatus }
        variable properties {
           { ossmon:imap:port {IMAP Port} {Port to be used for IMAP requests} {} }
           { ossmon:imap:timeout {IMAP Timeout} {Timeout to be used for IMAP requests} {-type intervalselect } }
           { ossmon:interval {OSSMON Polling Interval} {Interval between polling in seconds} {-type intervalselect } }
           { ossmon:auth:password {Auth Password} {Password to be used for authentication} {} }
           { ossmon:auth:user {Auth Username} {Username to be used for authentication} {} }
        }
      }

      namespace eval smtp {
        variable title "SMTP"
        variable superclass root
        variable columns { smtpHost smtpStatus }
        variable properties {
           { ossmon:smtp:mail_from {SMTP Mail From} {SMTP Mail From address used by SMTP monitor} {} }
           { ossmon:smtp:port {SMTP Port} {Port to be used for SMTP requests} {-datatype integer} }
           { ossmon:smtp:rcpt_to {SMTP Rcpt To} {SMTP Rcpt To address used by SMTP monitor} {} }
           { ossmon:smtp:timeout {SMTP Timeout} {Timeout to be used for SMTP requests} {-type intervalselect } }
        }
      }

      namespace eval http {
        variable title "HTTP"
        variable superclass root
        variable columns { httpHost httpStatus httpTime }
        variable properties {
           { ossmon:http:port {HTTP Port} {Port to be used for HTTP requests} {-datatype integer} }
           { ossmon:http:timeout {HTTP Timeout} {Timeout to be used for HTTP requests} {-type intervalselect } }
           { ossmon:http:url {HTTP Url} {Url for HTTP monitoring} {} }
        }
      }

      namespace eval ping {
        variable title "Ping"
        variable superclass root
        variable format var
        variable features "noConnectivity icmp"
        variable charts "ping collect"
        variable columns { pingSent pingReceived pingLoss pingRttMin pingRttAvg pingRttMax }
        variable properties {
           { ossmon:ping:count {PING Count} {Number of ICMP requests to send} {} }
           { ossmon:ping:size {PING Size} {Size of the ICMP request packet} {} }
           { ossmon:ping:timeout {PING Timeout} {Timeout for ICMP requests in seconds} {-type intervalselect } }
        }
      }

      namespace eval mailbox {
        variable title "Mailbox"
        variable superclass root
        variable columns { mailboxFrom mailboxTo mailboxSubject mailboxBody mailboxText mailboxFiles }
        variable properties {
           { ossmon:mailbox:name {Mailbox file name} {Name of the file with emails} {} }
           { ossmon:mailbox:path:map {Mailbox Address to Path mapping} {List of address to path mapping in format: Filter Path Email ...} {} }
        }
      }

      namespace eval file {
        variable title "File"
        variable format table
        variable columns fileLine
      }

      namespace eval tcp {
        variable title "TCP"
        variable format table
        variable columns { tcpHost tcpRequest tcpReply tcpTime }
        variable properties {
           { ossmon:tcp:data {TCP Request Data} {} {} }
           { ossmon:tcp:port {TCP Port} {} {-datatype integer -size 5} }
           { ossmon:tcp:size {TCP Reply Size} {} {-datatype integer -size 5} }
           { ossmon:tcp:timeout {TCP Timeout} {} {-type intervalselect} }
        }
      }

      namespace eval udp {
        variable title "UDP"
        variable format table
        variable columns { udpHost udpRequest udpReply udpTime }
        variable properties {
           { ossmon:udp:data {UDP Request Data} {} {} }
           { ossmon:udp:port {UDP Port} {} {-datatype integer -size 5} }
           { ossmon:udp:retries {UDP Retries} {} {-type numberselect -end 5} }
           { ossmon:udp:timeout {UDP Timeout} {} {-type intervalselect } }
        }
      }

      namespace eval ftp {
        variable title "FTP"
        variable columns { ftpHost ftpStatus }
        variable properties {
           { ossmon:ftp:port {FTP Port} {} {-datatype integer -size 5} }
           { ossmon:ftp:timeout {FTP Timeout} {} {-type intervalselect} }
        }
      }

      namespace eval radius {
        variable title "RADIUS"
        variable columns { radiusHost radiusStatus }
        variable properties {
           { ossmon:radius:port {RADIUS Port} {} {-datatype integer -size 5} }
           { ossmon:radius:retries {RADIUS Retry} {} {-type numberselect  -end 5} }
           { ossmon:radius:timeout {RADIUS Timeout} {} {-type intervalselect } }
           { ossmon:auth:secretkey {Auth Secret Key} {} {} }
        }
      }

      namespace eval dns {
        variable title "DNS"
        variable columns { dnsHost dnsType dnsStatus }
        variable defaults {
           port 53 timeout 5 protocol tcp status "" server localhost type A class IN opcode 0 recursive 1
        }
        variable properties {
           { ossmon:dns:hosts {DNS Hosts} {List of hosts to be used for monitoring} {} }
           { ossmon:dns:timeout {DNS Timeout} {Timeout for DNS requests in seconds} {-type intervalselect } }
        }
      }

      namespace eval dnstcp {
        variable title "DNS over TCP"
        variable superclass dns
        variable columns { dnsHost dnsIpaddr dnsStatus }

        variable id 0
        array set types {
           A 1 NS 2 MD 3 MF 4 CNAME 5 SOA 6 MB 7 MG 8 MR 9 NULL 10 WKS 11 PTR 12 HINFO 13 MINFO 14 MX 15 TXT 16 AXFR 252 MAILB 253 MAILA 254 * 255
        }
        array set Types {
           1 A 2 NS 3 MD 4 MF 5 CNAME 6 SOA 7 MB 8 MG 9 MR 10 NULL 11 WKS 12 PTR 13 HINFO 14 MINFO 15 MX 16 TXT 252 AXFR 253 MAILB 254 MAILA 255 *
        }
        array set classes { IN 1 CS 2 CH 3 HS 4 * 255}
        array set Classes { 1 IN 2 CS 3 CH 4 HS 255 * }
      }
    }

    # Each alert action shoudl have separate namespace with title
    # declared and exec proc  defined
    namespace eval alert {
      namespace eval html {}
      namespace eval process {}

      namespace eval action {

        namespace eval email {
          variable title Email
        }

        namespace eval problem {
          variable title Problem
        }

        namespace eval ticket {
          variable title Ticket
        }

        namespace eval alert {
          variable title Alert
        }

        namespace eval syslog {
          variable title Syslog
        }

        namespace eval exec {
          variable title Exec
        }

        namespace eval trap {
          variable title Trap
        }
      }
    }

    namespace eval action {
      namespace eval process {}
    }

    namespace eval report {
      namespace eval schedule {}
    }

    namespace eval cache {}
    namespace eval device {}
    namespace eval poll {}
    namespace eval trap {}
    namespace eval rule {}
    namespace eval schedule {}
    namespace eval util {}
    namespace eval template {}

    namespace eval mib {
      variable types
      set types { Counter32 Counter64 Integer32 IpAddress "OCTET STRING" Opaque TimeTicks Unsigned32 }
    }

    namespace eval chart {
      array set types {
         if_load "Interface Utilization"
         if_rate "Interface Transfer Rates"
         if_trans "Interface Transfer Amount"
         if_pkt "Interface Packet Rates"
         if_drop  "Interface Drop Rates"
         ping "ICMP Round Trip Time"
         collect "Statistics"
      }
    }

    # Build object hierarchy
    foreach nm [namespace children ::ossmon::object] {
      variable ${nm}::hierarchy
      set ${nm}::hierarchy $nm
      set type [namespace tail $nm]
      while { [info exists ::ossmon::object::${type}::superclass] } {
        set type [set ::ossmon::object::${type}::superclass]
        lappend ${nm}::hierarchy ::ossmon::object::${type}
      }
      lappend ${nm}::hierarchy ::ossmon::object
    }

    # Build dynamic properties
    foreach nm [namespace children ::ossmon::object] {
      set type [namespace tail $nm]
      lappend ::ossmon::object::properties [list ossmon:alert:email:$type "Alert Email for $type" {Email where to send alerts} {}]
    }

    # Build properties cache by id
    foreach nm "::ossmon ::ossmon::object [namespace children ::ossmon::object]" {
      if { [info exists ${nm}::properties] } {
        set i -1
        variable ${nm}::properties_cache
        foreach rec [set ${nm}::properties] {
          set ${nm}::properties_cache([lindex $rec 0]) [incr i]
        }
      }
    }
}

ossweb::register_init ossmon::init

# Link to OSSMON from the toolbar
proc ossweb::html::toolbar::ossmon {} {

    if { [ossweb::conn::check_acl -acl *.ossmon.console.view.*] } { return }
    return [ossweb::html::link -image ossmon.gif -hspace 6 -status OSSMON -alt OSSMON -app_name ossmon ossmon]
}

# OSSMON scheduled weekly tasks
proc ossweb::schedule::weekly::ossmon {} {

    ossmon::report::schedule::weekly
}

# OSSMON scheduled monthly tasks
proc ossweb::schedule::monthly::ossmon {} {

}

# OSSMON scheduled daily tasks
proc ossweb::schedule::daily::ossmon {} {

    ossweb::db::exec sql:ossmon.schedule.cleanup.nat
    ossweb::db::exec sql:ossmon.schedule.cleanup.mac
    ossweb::db::exec sql:ossmon.schedule.cleanup.ping
    ossweb::db::exec sql:ossmon.schedule.cleanup.iftable
    ossweb::db::exec sql:ossmon.schedule.cleanup.collect
    ossweb::db::exec sql:ossmon.schedule.cleanup.alert_log
    ossweb::db::exec sql:ossmon.schedule.cleanup.alerts
}

# OSSMON scheduled hourly tasks
proc ossweb::schedule::hourly::ossmon {} {

    ossmon::schedule::collection
    ossmon::schedule::polling
}

# OSSMON initialization, called before each scheduled OSSMON poll
proc ossmon::init {} {

    ossmon::mib::init

    # Local caches for runtime structures
    ossweb::cache::create ossmon:poll
    ossweb::cache::create ossmon:cache -timeout 3600
    ossweb::cache::create ossmon:alert -expires 3600
    ossmon::property session:refresh

    if { [ossweb::true [ossweb::param ossmon:stop]] } {
      ns_log Error ossmon::init: ossmon:stop is set, no scheduling enabled
      return
    }

    # Max number of threads
    set maxthreads [ossweb::config ossmon:thread:max 16]
    ns_job create ossmon $maxthreads
    ns_thread begindetached ossmon::schedule::poller
    ns_thread begindetached ossmon::schedule::charts
    ns_log Notice ossmon: initialized, $maxthreads threads
}

proc ossmon::version {} {

    variable version
    return $version
}

# Returns OSSMON global level where all objects are allocated
proc ossmon::level {} {

    variable ossmon_level
    return $ossmon_level
}

# Returns global OSSMON property value
proc ossmon::property { name args } {

    ns_parseargs { {-default ""} {-column ""} {-type ::ossmon} } $args

    variable ${type}::properties
    variable ${type}::properties_cache

    set value ""
    switch -- $name {
     session:refresh -
     session:timestamp {
       if { $name == "session:refresh" } {
         ossweb::db::cache flush OSSMON:TIMESTAMP
       }
       return [ossweb::db::value sql:ossmon.timestamp -cache OSSMON:TIMESTAMP]
     }

     product:name {
       return OSSMON
     }

     product:version {
       return $::ossmon::version
     }

     operators {
        return $::ossmon::operators
     }

     property:all {
        set result ""
        foreach nm "::ossmon ::ossmon::object [namespace children ::ossmon::object]" {
          set title [set ${nm}::title]
          foreach item [ossmon::property property:list -type $nm] {
            foreach { id name descr widget } $item {}
            append widget " -section {$title}"
            lappend result [list $id $name $descr $widget]
          }
        }
        return $result
     }

     property:list {
        if { [info exists ${type}::properties] } {
          return [set ${type}::properties]
        }
     }

     property:options {
        if { [info exists ${type}::properties] } {
          set options ""
          foreach item [set ${type}::properties] {
            lappend options [list [lindex $item 1] [lindex $item 0]]
          }
          return $options
        }
     }

     default {
        if { [info exists properties_cache($name)] } {
          set value [lindex $properties $properties_cache($name)]
        }
        if { $value != "" } {
          switch -- $column {
           widget {
              set value [lindex $value 3]
           }

           descr {
              set value [lindex $value 2]
           }

           title {
              set value [lindex $value 1]
           }

           defvalue {
              set value [lindex $value 4]
           }
          }
          if { $value != "" } {
            return $value
          }
        }
     }
    }
    return $default
}

# Restart scheduler
proc ossmon::schedule::restart {} {

    ossweb::set_config ossmon:stop 1
    ns_sleep [ossweb::date duration [ossweb::config ossmon:poll:interval 300]]
    ossweb::set_config ossmon:stop ""
    ns_thread begindetached ossmon::schedule::poler
    ns_thread begindetached ossmon::schedule::charts
}

# SNMP poller
proc ossmon::schedule::poller {} {

    ns_thread name -ossmon:schedule-

    set start_time [ns_time]
    while { ![ossweb::true [ossweb::config ossmon:stop]] } {
      if { [catch {
        # Discover the minimum polling interval
        set interval1 [ossweb::date duration [ossweb::nvl [ossweb::db::value sql:ossmon.poll.interval.min] 300]]
        set interval2 [ossweb::date duration [ossweb::config ossmon:interval 300]]
        set interval [expr $interval1 > $interval2 ? $interval2 : $interval1]
        if { $interval <= 0 } {
          set interval 300
        }
        # Minimum time to sleep between polls
        set sleep_time [ossweb::date duration [ossweb::config ossmon.poll.interval.sleep 30]]
        if { [set sleep [expr $interval/2-([ns_time]-$start_time)]] < $sleep_time } {
          set sleep $sleep_time
        }
        ossweb::db::release
        ns_sleep $sleep
        # Now do the poll
        set start_time [ns_time]
        # Check if we have sane cache and not disabled
        if { [ossweb::config ossmon:config] != "" } {
          ossmon::property session:refresh
          if { [ossweb::true [ossweb::config ossmon:pinger]] } {
            ossmon::poll::pinger
          }
          ossmon::poll::queue
          ossmon::alert::schedule
        }
      } errmsg] } {
        ns_log Error ossmon::schedule::poller: $errmsg
      }
    }
}

# Real-time charts generator
proc ossmon::schedule::charts {} {

    ns_thread name -ossmon:schedule:charts-
    while { ![ossweb::true [ossweb::config ossmon:stop]] } {
      ossweb::db::release
      ns_sleep [ossweb::date duration [ossweb::config ossmon:poll:interval 300]]
      foreach obj [ossweb::db::multilist sql:ossmon.object.list.charts] {
        foreach { obj_id interval } $obj {}
        if { $interval == "" } {
          set interval [ossweb::date duration [ossweb::config ossmon:charts:interval 86400]]
        }
        ossmon::chart::exec $obj_id "" \
           -cache f \
           -title ":[ossweb::date uptime $interval]" \
           -width 300 \
           -height 180 \
           -legendy 140 \
           -hardheight 100 \
           -file_count 1 \
           -file_name "$obj_id:" \
           -start_date [expr [ns_time]-$interval]
      }
    }
}

# Verification of collecting module
proc ossmon::schedule::collection {} {

    if { [set email [ossweb::config ossmon:admin:email]] == "" } { return }

    set interval [ossweb::config ossmon:collect:interval:check 3600]
    set count 0
    set report "The following [ossmon::property product:name] objects are configured to collect statistics but
                did not receive it for the last [ossweb::date uptime $interval]:\n\n"
    set ossmon_link [ossweb::config ossmon:url]

    ossweb::db::foreach sql:ossmon.schedule.collect {
      if { $collect_interval <= $interval || $collect_interval > $interval+7200 } { continue }
      append report "--------------------\n"
      append report "ID: $obj_id\n"
      if { $ossmon_link != "" } {
        append report "LINK: ${ossmon_link}&obj_id=$obj_id\n"
      }
      append report "Name: ${obj_name}($obj_host)/$obj_type\n"
      append report "Device: $device_name\n"
      append report "Last Polled: $poll_time\n"
      append report "Last Collected: $collect_time, ([ossweb::date uptime $collect_interval] ago,$collect_interval secs)\n"
      append report "Last Updated: $update_time\n\n"
      if { $alert_count > 0 } {
        append report "Alert Time: $alert_time\n"
        append report "Alert Type: $alert_name/$alert_type/$alert_count\n"
      }
      incr count
    }
    # Send all messages from local queue
    if { $count > 0 } {
      ossweb::sendmail $email ossmon "[ossmon::property product:name]: Collection Report" $report
    }
}

# Verification of polling module
proc ossmon::schedule::polling {} {

    if { [set email [ossweb::config ossmon:admin:email]] == "" } { return }

    set interval [ossweb::config poll::interval:check 14400]
    set count 0
    set report "The following [ossmon::property product:name] objects are configured to be monitored but
                have not been polled for the last [ossweb::date uptime $interval]:\n\n"
    set ossmon_link [ossweb::config ossmon:url]

    ossweb::db::foreach sql:ossmon.schedule.polling {
      if { $poll_interval <= $interval || $poll_interval > $interval+7200 } { continue }
      append report "--------------------\n"
      append report "ID: $obj_id\n"
      if { $ossmon_link != "" } {
        append report "LINK: ${ossmon_link}&obj_id=$obj_id\n"
      }
      append report "Name: ${obj_name}($obj_host)/$obj_type\n"
      append report "Device: $device_name\n"
      append report "Last Polled: $poll_time ([ossweb::date uptime $poll_interval] ago,$poll_interval secs)\n"
      append report "Last Updated: $update_time\n\n"
      if { $alert_count > 0 } {
        append report "Alert Time: $alert_time\n"
        append report "Alert Type: $alert_name/$alert_type/$alert_count\n"
      }
      incr count
    }
    # Send all messages from local queue
    if { $count > 0 } {
      ossweb::sendmail $email ossmon "[ossmon::property product:name]: Monitoring Report" $report
    }
}

# Perform polling of all registreted objects
proc ossmon::poll::queue {} {

    set pings ""
    # First pass, put all non-ping objects into the queue
    ossweb::db::foreach sql:ossmon.poll.objects {
      switch -- $obj_type {
       ping {
         set pings [linsert $pings 0 $obj_id]
       }

       default {
         if { ![ns_job exists ossmon $obj_id] } {
           if { [catch { ns_job queue -detached -jobid $obj_id ossmon "ossmon::poll::object $obj_id" } errmsg] } {
             ns_log Error ossmon::poll::queue: $obj_id: $errmsg
           }
         }
       }
      }
    }
    # Second pass, put pings at the beginning of the queue
    foreach obj_id $pings {
      if { ![ns_job exists ossmon $obj_id] } {
        if { [catch { ns_job queue -head -detached -jobid $obj_id ossmon "ossmon::poll::object $obj_id" } errmsg] } {
          ns_log Error ossmon::poll::queue: $obj_id: $errmsg
        }
      }
    }
}

# Performs bulk pinging, ping all objects at once and update cache with most recent
# session timestamp, so regular poller will pickup that cache and do processing
proc ossmon::poll::pinger {} {

    set timestamp [ossmon::property session:timestamp]
    set timeout [ossweb::config ping:timeout 2]
    set count [ossweb::config ping:count 3]
    set size [ossweb::config ping:size 56]
    set obj_type ping
    set hosts ""

    foreach obj_id [ossweb::db::list sql:ossmon.poll.objects -colname obj_id] {
      ossmon::object obj -create obj:id $obj_id
      lappend hosts [ossmon::object obj obj:host] \
                          -name [ossmon::object obj -key] \
                          -count [ossmon::object obj ping:count -default $count] \
                          -timeout [ossmon::object obj ping:timeout -default $timeout]
    }
    if { $hosts != "" } {
      foreach ping [eval ns_ping -alert 0 -count $count -timeout $timeout -size $size $hosts] {
        set key [lindex $ping 0]
        ossweb::cache::put ossmon:cache $key:timestamp $timestamp
        ossweb::cache::put ossmon:cache $key [lrange $ping 1 end]
      }
    }
}

# Perform pollig one object
proc ossmon::poll::object { obj_id } {

    set name O$obj_id

    # Create ossmon object, read record from the database
    ossmon::object $name -create obj:id $obj_id

    set now [ossmon::object $name time:now]
    set device_id [ossmon::object $name device:id]
    set timestamp [ossmon::object $name ossmon:timestamp]
    set interval [ossweb::date duration [ossmon::object $name ossmon:interval -config 300]]
    set poll_time [expr $now - [ossmon::object $name time:poll -default 0]]

    # Do not poll same device if it is marked as down, objects from this device will not
    # be called but this will not affect any other devices and objects
    if { [ossweb::cache::exists ossmon:alert $device_id:noConnectivity] } {
      ossmon::object $name -set poll:noConnectivity 1
      ossmon::object $name -log 1 ossmon::poll::object device is down
      # For objects that do not check connectivity we skip, others that do pings
      # will clear this flag as soon as device is up again
      if { ![ossmon::object $name -feature noConnectivity] } {
        ossmon::object $name -destroy
        ossweb::db::release
        return
      }
    }

    # Check poll interval, skip if too early
    if { $interval != "" && $poll_time < $interval } {
      ossmon::object $name -log 3 ossmon::poll::object polled $poll_time secs ago, should be $interval
      ossmon::object $name -destroy
      ossweb::db::release
      return
    }

    # Do not poll if within skip period
    if { [ossmon::util::period $name ossmon:poll:skip:period -novalue t] != "" } {
      ossmon::object $name -log 3 ossmon::poll::object skip period matched
      ossmon::object $name -destroy
      ossweb::db::release
      return
    }

    # Skip polling session for the current one if some thread is still polling
    set poll [ossweb::cache::run ossmon:poll $name {
       return [list $now $timestamp]
    }]
    set max_time [ossweb::config ossmon:poll:max 900]
    set poll_time [expr $now - [lindex $poll 0]]
    if { $poll_time > 0 && $poll_time < $max_time } {
      ossmon::object $name -log 1 ossmon::poll::object still polling [ossweb::date uptime $poll_time]
      ossmon::object $name -destroy
      ossweb::db::release
      return
    }
    if { $poll_time > $max_time } {
      ossmon::object $name -log Error ossmon::poll::object still polling more than $max_time seconds
    }

    # Flush local object's cache with every new session
    if { [ossmon::object $name -feature cache] == 1 } {
      set key [ossmon::object $name -key]
      if { [ossweb::cache::get ossmon:cache $key:timestamp] != $timestamp } {
        # Assign current timestamp
        ossweb::cache::put ossmon:cache $key:timestamp $timestamp
        # Flush cached data
        ossweb::cache::flush ossmon:cache $key
      }
    }

    ossmon::log 1 ossmon::poll::object polling started...

    # Start polling session
    if { [catch { ossmon::object $name -poll } errmsg] } {
      set errmsg [ossmon::util::parseError $errmsg]
      ossmon::object $name -set ossmon:type error ossmon:status $errmsg ossmon:trace $::errorInfo
    }

    # Preprocess result status and any special actions per type
    switch -glob -- [string trim [ossmon::object $name ossmon:status]] {
     noConnectivity* {
        ossmon::object $name -set ossmon:type noConnectivity
        # Check if our parent has noConnectivity error
        if { [ossmon::object $name -info:noconnectivity] } {
          # Set alert threshold high so we will not generate any alert actions but only keep alert alive
          ossmon::object $name -set alert:threshold 9999999
          ossmon::object $name -log 1 ossmon::poll::object keep alert alive
        }
        # Mark as down
        ossweb::cache::incr ossmon:alert $device_id:noConnectivity
     }

     noResponse* {
        ossmon::object $name -set ossmon:type noResponse
        # Restart failed process if configured
        if { [catch { ossmon::object $name -fix } errmsg] } {
          ossmon::object $name -set ossmon:type error ossmon:status $errmsg ossmon:trace $::errorInfo
        }
        # Check if our parent has noConnectivity error or device is not responsive
        if { [ossmon::object $name -info:noconnectivity] ||
             [ossweb::cache::exists ossmon:alert $device_id:noResponse:$timestamp] } {
          # Set alert threshold high so we will not generate any alert actions but only keep alert alive
          ossmon::object $name -set alert:threshold 9999999
          ossmon::object $name -log 1 ossmon::poll::object keep alert alive
        }
        # Mark as not responsive in this session
        ossweb::cache::incr ossmon:alert $device_id:noResponse:$timestamp
     }

     noResources* {
        # No enough system resources, do not report as an alert
        ossmon::log 0 ossmon::poll::object [ossmon::object $name ossmon:status]
        ossmon::object $name -shutdown
        ossweb::db::release
        return
     }

     default {
        # If object can throw noConnectivity alerts and in this session no alerts happened that
        # means we have connectivity with the device
        if { [ossmon::object $name -feature noConnectivity] } {
          # Show mesage on connectivity changes only
          if { [ossmon::object $name poll:noConnectivity] == 1 } {
            ossmon::object $name -log 1 ossmon::poll::object device is up
          }

          # Clear status
          ossweb::cache::flush ossmon:alert $device_id:noResponse
          ossweb::cache::flush ossmon:alert $device_id:noConnectivity

          # Convert active alerts immediately into pending status
          foreach alert_id [ossweb::db::multilist sql:ossmon.device.alert.noconnectivity] {
            ossmon::alert::schedule -alert_id $alert_id -active_time 0
          }
        }
     }
    }
    # Run action/alert handlers for the object
    if { [catch { ossmon::poll::process $name } errmsg] } {
      ossmon::object $name -set ossmon:type error ossmon:status $errmsg ossmon:trace $::errorInfo
    }
    # Update status of each object
    ossweb::db::exec sql:ossmon.object.update.status

    # Final result
    set result [ossmon::object $name ossmon:type]

    ossmon::log 1 ossmon::poll::object polling stopped with result $result: [ossmon::object $name ossmon:status]
    ossmon::object $name -logdump 7 ossmon::poll::object

    # Special cases for some results
    switch -- $result {
     error {
       # Show runtime errors
       ns_log Error ossmon::poll::object: [ossmon::object $name -name]: error: [ossmon::object $name ossmon:status]: [ossmon::object $name ossmon:trace]
     }
    }
    # Destroy the object, ignore any errors at this point
    ossmon::object $name -shutdown
    ossweb::db::release
    return
}

# Returns the list with all currently polled objects
proc ossmon::poll::report {} {

    set result ""
    foreach name [ossweb::cache::keys ossmon:poll] {
      if { [set var [ossweb::cache::get ossmon:poll $name]] != "" } {
        lappend result $name $var
      }
    }
    return $result
}

# Executes Tcl code for a given object which can be table,group or var.
# for table object, code will be executed for each row with
# all row's columns being available as array elements.
# for group and var Tcl code will be executed only once.
# Returns -1 on error.
proc ossmon::poll::process { name args } {

    switch [ossmon::object $name -info:format] {
     array -
     table {
        set obj_type [ossmon::object $name obj:type]
        set rowcount [ossmon::object $name obj:rowcount]
        # Call hanlders even if we do not have any rows
        if { $rowcount == 0 } {
          ::ossmon::action::process $name before
          ::ossmon::alert::process $name alert
          ::ossmon::action::process $name after
          ossmon::object $name -eval
        } else {
          set columns [ossmon::object $name ossmon:columns]
          # Otherwise call handler(s) for each row
          for { set i 1 } { $i <= $rowcount } { incr i } {
            set row [ossmon::object $name obj:$i]
            ossmon::object $name -log 5 ossmon::poll::process: ROW $i: $row
            ossmon::object $name -set obj:rownum $i
            switch [ossmon::object $name -info:format] {
             array {
               ossmon::object $name -unset "^$obj_type:"
               foreach { key value } $row {
                 ossmon::object $name -set $obj_type:$key $value
               }
             }
             default {
               for { set j 0 } { $j < [llength $columns] } { incr j } {
                 ossmon::object $name -set [lindex $columns $j] [lindex $row $j]
               }
             }
            }
            ::ossmon::action::process $name before
            ::ossmon::alert::process $name alert
            ::ossmon::action::process $name after
            ossmon::object $name -eval
            # Stop in case of fatal errors
            switch [ossmon::object $name ossmon:type] {
             error -
             ossmon:stop -
             noConnectivity -
             noResponse {
                break
             }
            }
          }
        }
     }

     default {
        ::ossmon::action::process $name before
        ::ossmon::alert::process $name alert
        ::ossmon::action::process $name after
        ossmon::object $name -eval
     }
    }
    # Final status update/final status handlers
    ::ossmon::alert::process $name final
    ::ossmon::action::process $name final
}

# OSSMON logger
proc ossmon::log { level prefix args } {

    if { $level == "Error" || $level <= [ossweb::config ossmon:debug 0] } {
      eval ns_log Notice $prefix{[ossmon::property session:timestamp]} $args
    }
}

# MIB initialization
proc ossmon::mib::init {} {

    # Warning about absence of MIB entries
    if { [ns_mib oid sysDescr] == "sysDescr" } {
      ns_log Error ossmon::mib::init MIB entries are not installed
    }
    if { [ns_mib oid sysDescr] == "sysDescr" } {
      ns_log Error ossmon::mib::init: MIB entries are not installed
      ns_mib set 1.3 RFC1155-SMI org {} {}
      ns_mib set 1.3.6 RFC1155-SMI dod {} {}
      ns_mib set 1.3.6.1 RFC1155-SMI internet {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.1 RFC1155-SMI directory {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.2 RFC1155-SMI mgmt {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.2.1 SNMPv2-SMI mib-2 {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.2.1.1 SNMPv2-MIB system {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.2.1.1.1 SNMPv2-MIB sysDescr {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.2.1.1.2 SNMPv2-MIB sysObjectID {OBJECT IDENTIFIER} {}
      ns_mib set 1.3.6.1.2.1.1.3 SNMPv2-MIB sysUpTime {TimeTicks} {}
      ns_mib set 1.3.6.1.2.1.1.3.0 DISMAN-EVENT-MIB sysUpTimeInstance {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.2.1.1.4 SNMPv2-MIB sysContact {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.2.1.1.5 SNMPv2-MIB sysName {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.2.1.1.6 SNMPv2-MIB sysLocation {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.2.1.1.7 SNMPv2-MIB sysServices {Integer32} {}
      ns_mib set 1.3.6.1.2.1.1.8 SNMPv2-MIB sysORLastChange {TimeTicks} {}
      ns_mib set 1.3.6.1.2.1.1.9 SNMPv2-MIB sysORTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.2.1.1.9.1 SNMPv2-MIB sysOREntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.2.1.1.9.1.1 SNMPv2-MIB sysORIndex {Integer32} {}
      ns_mib set 1.3.6.1.2.1.1.9.1.2 SNMPv2-MIB sysORID {OBJECT IDENTIFIER} {}
      ns_mib set 1.3.6.1.2.1.1.9.1.3 SNMPv2-MIB sysORDescr {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.2.1.1.9.1.4 SNMPv2-MIB sysORUpTime {TimeTicks} {}
      ns_mib set 1.3.6.1.2.1.2 IF-MIB interfaces {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.2.1.2.1 IF-MIB ifNumber {Integer32} {}
      ns_mib set 1.3.6.1.2.1.2.2 IF-MIB ifTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.2.1.2.2.1 IF-MIB ifEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.1 IF-MIB ifIndex {Integer32} {d}
      ns_mib set 1.3.6.1.2.1.2.2.1.2 IF-MIB ifDescr {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.2.1.2.2.1.3 IF-MIB ifType {Integer32} {} \
           other(1) regular1822(2) hdh1822(3) ddnX25(4) rfc877x25(5) ethernetCsmacd(6) iso88023Csmacd(7) iso88024TokenBus(8) iso88025TokenRing(9) iso88026Man(10) starLan(11) proteon10Mbit(12) proteon80Mbit(13) hyperchannel(14) fddi(15) lapb(16) sdlc(17) ds1(18) e1(19) basicISDN(20) primaryISDN(21) propPointToPointSerial(22) ppp(23) softwareLoopback(24) eon(25) ethernet3Mbit(26) nsip(27) slip(28) ultra(29) ds3(30) sip(31) frameRelay(32) \
           rs232(33) para(34) arcnet(35) arcnetPlus(36) atm(37) miox25(38) sonet(39) x25ple(40) iso88022llc(41) localTalk(42) smdsDxi(43) frameRelayService(44) v35(45) hssi(46) hippi(47) modem(48) aal5(49) sonetPath(50) sonetVT(51) smdsIcip(52) propVirtual(53) propMultiplexor(54) ieee80212(55) fibreChannel(56) hippiInterface(57) frameRelayInterconnect(58) aflane8023(59) aflane8025(60) cctEmul(61) fastEther(62) isdn(63) v11(64) v36(65) \
           g703at64k(66) g703at2mb(67) qllc(68) fastEtherFX(69) channel(70) ieee80211(71) ibm370parChan(72) escon(73) dlsw(74) isdns(75) isdnu(76) lapd(77) ipSwitch(78) rsrb(79) atmLogical(80) ds0(81) ds0Bundle(82) bsc(83) async(84) cnr(85) iso88025Dtr(86) eplrs(87) arap(88) propCnls(89) hostPad(90) termPad(91) frameRelayMPI(92) x213(93) adsl(94) radsl(95) sdsl(96) vdsl(97) iso88025CRFPInt(98)
      ns_mib set 1.3.6.1.2.1.2.2.1.4 IF-MIB ifMtu {Integer32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.5 IF-MIB ifSpeed {Unsigned32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.6 IF-MIB ifPhysAddress {OCTET STRING} {1x:}
      ns_mib set 1.3.6.1.2.1.2.2.1.7 IF-MIB ifAdminStatus {Integer32} {} up(1) down(2) testing(3)
      ns_mib set 1.3.6.1.2.1.2.2.1.8 IF-MIB ifOperStatus {Integer32} {} up(1) down(2) testing(3) unknown(4) dormant(5) notPresent(6) lowerLayerDown(7)
      ns_mib set 1.3.6.1.2.1.2.2.1.9 IF-MIB ifLastChange {TimeTicks} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.10 IF-MIB ifInOctets {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.11 IF-MIB ifInUcastPkts {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.12 IF-MIB ifInNUcastPkts {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.13 IF-MIB ifInDiscards {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.14 IF-MIB ifInErrors {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.15 IF-MIB ifInUnknownProtos {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.16 IF-MIB ifOutOctets {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.17 IF-MIB ifOutUcastPkts {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.18 IF-MIB ifOutNUcastPkts {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.19 IF-MIB ifOutDiscards {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.20 IF-MIB ifOutErrors {Counter32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.21 IF-MIB ifOutQLen {Unsigned32} {}
      ns_mib set 1.3.6.1.2.1.2.2.1.22 IF-MIB ifSpecific {OBJECT IDENTIFIER} {}

      ns_mib set 1.3.6.1.4.1.2021 UCD-SNMP-MIB ucdavis {MODULE-IDENTITY} {}
      ns_mib set 1.3.6.1.4.1.2021.2 UCD-SNMP-MIB prTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1 UCD-SNMP-MIB prEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.1 UCD-SNMP-MIB prIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.2 UCD-SNMP-MIB prNames {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.2.1.3 UCD-SNMP-MIB prMin {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.4 UCD-SNMP-MIB prMax {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.5 UCD-SNMP-MIB prCount {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.100 UCD-SNMP-MIB prErrorFlag {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.101 UCD-SNMP-MIB prErrMessage {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.2.1.102 UCD-SNMP-MIB prErrFix {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.2.1.103 UCD-SNMP-MIB prErrFixCmd {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.4 UCD-SNMP-MIB memory {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.4.1 UCD-SNMP-MIB memIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.2 UCD-SNMP-MIB memErrorName {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.4.3 UCD-SNMP-MIB memTotalSwap {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.4 UCD-SNMP-MIB memAvailSwap {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.5 UCD-SNMP-MIB memTotalReal {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.6 UCD-SNMP-MIB memAvailReal {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.7 UCD-SNMP-MIB memTotalSwapTXT {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.8 UCD-SNMP-MIB memAvailSwapTXT {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.9 UCD-SNMP-MIB memTotalRealTXT {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.10 UCD-SNMP-MIB memAvailRealTXT {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.11 UCD-SNMP-MIB memTotalFree {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.12 UCD-SNMP-MIB memMinimumSwap {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.13 UCD-SNMP-MIB memShared {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.14 UCD-SNMP-MIB memBuffer {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.15 UCD-SNMP-MIB memCached {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.100 UCD-SNMP-MIB memSwapError {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.4.101 UCD-SNMP-MIB memSwapErrorMsg {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.8 UCD-SNMP-MIB extTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.4.1.2021.8.1 UCD-SNMP-MIB extEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.4.1.2021.8.1.1 UCD-SNMP-MIB extIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.8.1.2 UCD-SNMP-MIB extNames {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.8.1.3 UCD-SNMP-MIB extCommand {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.8.1.100 UCD-SNMP-MIB extResult {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.8.1.101 UCD-SNMP-MIB extOutput {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.8.1.102 UCD-SNMP-MIB extErrFix {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.8.1.103 UCD-SNMP-MIB extErrFixCmd {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.9 UCD-SNMP-MIB dskTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1 UCD-SNMP-MIB dskEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.1 UCD-SNMP-MIB dskIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.2 UCD-SNMP-MIB dskPath {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.9.1.3 UCD-SNMP-MIB dskDevice {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.9.1.4 UCD-SNMP-MIB dskMinimum {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.5 UCD-SNMP-MIB dskMinPercent {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.6 UCD-SNMP-MIB dskTotal {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.7 UCD-SNMP-MIB dskAvail {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.8 UCD-SNMP-MIB dskUsed {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.9 UCD-SNMP-MIB dskPercent {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.10 UCD-SNMP-MIB dskPercentNode {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.100 UCD-SNMP-MIB dskErrorFlag {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.9.1.101 UCD-SNMP-MIB dskErrorMsg {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.10 UCD-SNMP-MIB laTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.4.1.2021.10.1 UCD-SNMP-MIB laEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.4.1.2021.10.1.1 UCD-SNMP-MIB laIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.10.1.2 UCD-SNMP-MIB laNames {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.10.1.3 UCD-SNMP-MIB laLoad {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.10.1.4 UCD-SNMP-MIB laConfig {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.10.1.5 UCD-SNMP-MIB laLoadInt {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.10.1.6 UCD-SNMP-MIB laLoadFloat {OCTET STRING} {}
      ns_mib set 1.3.6.1.4.1.2021.10.1.100 UCD-SNMP-MIB laErrorFlag {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.10.1.101 UCD-SNMP-MIB laErrMessage {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.11 UCD-SNMP-MIB systemStats {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.11.1 UCD-SNMP-MIB ssIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.2 UCD-SNMP-MIB ssErrorName {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.11.3 UCD-SNMP-MIB ssSwapIn {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.4 UCD-SNMP-MIB ssSwapOut {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.5 UCD-SNMP-MIB ssIOSent {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.6 UCD-SNMP-MIB ssIOReceive {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.7 UCD-SNMP-MIB ssSysInterrupts {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.8 UCD-SNMP-MIB ssSysContext {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.9 UCD-SNMP-MIB ssCpuUser {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.10 UCD-SNMP-MIB ssCpuSystem {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.11.11 UCD-SNMP-MIB ssCpuIdle {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.12 UCD-SNMP-MIB ucdInternal {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.13 UCD-SNMP-MIB ucdExperimental {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.15 UCD-SNMP-MIB fileTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.4.1.2021.15.1 UCD-SNMP-MIB fileEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.4.1.2021.15.1.1 UCD-SNMP-MIB fileIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.15.1.2 UCD-SNMP-MIB fileName {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.15.1.3 UCD-SNMP-MIB fileSize {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.15.1.4 UCD-SNMP-MIB fileMax {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.15.1.100 UCD-SNMP-MIB fileErrorFlag {Integer32} {} true(1) false(2)
      ns_mib set 1.3.6.1.4.1.2021.15.1.101 UCD-SNMP-MIB fileErrorMsg {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.100 UCD-SNMP-MIB version {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.100.1 UCD-SNMP-MIB versionIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.100.2 UCD-SNMP-MIB versionTag {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.100.3 UCD-SNMP-MIB versionDate {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.100.4 UCD-SNMP-MIB versionCDate {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.100.5 UCD-SNMP-MIB versionIdent {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.100.6 UCD-SNMP-MIB versionConfigureOptions {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.100.10 UCD-SNMP-MIB versionClearCache {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.100.11 UCD-SNMP-MIB versionUpdateConfig {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.100.12 UCD-SNMP-MIB versionRestartAgent {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.100.20 UCD-SNMP-MIB versionDoDebugging {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.101 UCD-SNMP-MIB snmperrs {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.101.1 UCD-SNMP-MIB snmperrIndex {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.101.2 UCD-SNMP-MIB snmperrNames {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.101.100 UCD-SNMP-MIB snmperrErrorFlag {Integer32} {}
      ns_mib set 1.3.6.1.4.1.2021.101.101 UCD-SNMP-MIB snmperrErrMessage {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.102 UCD-SNMP-MIB mrTable {SEQUENCE OF} {}
      ns_mib set 1.3.6.1.4.1.2021.102.1 UCD-SNMP-MIB mrEntry {SEQUENCE} {}
      ns_mib set 1.3.6.1.4.1.2021.102.1.1 UCD-SNMP-MIB mrIndex {OBJECT IDENTIFIER} {}
      ns_mib set 1.3.6.1.4.1.2021.102.1.2 UCD-SNMP-MIB mrModuleName {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.2021.250 UCD-SNMP-MIB ucdSnmpAgent {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.1 UCD-SNMP-MIB hpux9 {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.2 UCD-SNMP-MIB sunos4 {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.3 UCD-SNMP-MIB solaris {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.4 UCD-SNMP-MIB osf {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.5 UCD-SNMP-MIB ultrix {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.6 UCD-SNMP-MIB hpux10 {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.7 UCD-SNMP-MIB netbsd1 {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.8 UCD-SNMP-MIB freebsd {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.9 UCD-SNMP-MIB irix {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.10 UCD-SNMP-MIB linux {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.11 UCD-SNMP-MIB bsdi {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.12 UCD-SNMP-MIB openbsd {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.250.255 UCD-SNMP-MIB unknown {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.251 UCD-SNMP-MIB ucdTraps {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.2021.251.1 UCD-SNMP-MIB ucdStart {NOTIFICATION-TYPE} {}
      ns_mib set 1.3.6.1.4.1.2021.251.2 UCD-SNMP-MIB ucdShutdown {NOTIFICATION-TYPE} {}
    }
    # Add OSSMON-MIB variables
    if { [ns_mib oid ossmon] == "ossmon" } {
      ns_mib set 1.3.6.1.4.1.19804 OSSMON-MIB ossmon {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1 OSSMON-MIB exec {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1.1 OSSMON-MIB emptyTable {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1.2 OSSMON-MIB psTable {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1.3 OSSMON-MIB netstatTable {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1.4 OSSMON-MIB tailTable {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1.5 OSSMON-MIB syslogTable {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.1.6 OSSMON-MIB pingTable {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.2 OSSMON-MIB kill {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.3 OSSMON-MIB event {VALUE-ASSIGNEMENT} {}
      ns_mib set 1.3.6.1.4.1.19804.3.1 OSSMON-MIB tailFile {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.19804.3.2 OSSMON-MIB killProcess {OCTET STRING} {255a}
      ns_mib set 1.3.6.1.4.1.19804.3.3 OSSMON-MIB fixProcess {OCTET STRING} {}
      ns_mib set 1.3.6.1.4.1.19804.3.4 OSSMON-MIB pingHost {OCTET STRING} {}
      ns_mib set 1.3.6.1.4.1.19804.3.5 OSSMON-MIB ossmonAlert {OCTET STRING} {}
      ns_mib set 1.3.6.1.4.1.19804.3.6 OSSMON-MIB ossmonTrap {OCTET STRING} {}
      ns_mib set 1.3.6.1.4.1.19804.9 OSSMON-MIB local {VALUE-ASSIGNEMENT} {}
    }
}

# Returns OID for MIB node
proc ossmon::mib::oid { name } {

    return [ns_mib oid $name]
}

# Returns full name for MIB node
proc ossmon::mib::name { oid } {

    return [ns_mib name $oid]
}

# Returns label for MIB node
proc ossmon::mib::label { oid } {

    return [ns_mib label $oid]
}

# Returns syntax for MIB node
proc ossmon::mib::syntax { oid } {

    return [ns_mib syntax $oid]
}

# Returns full MIB node information
proc ossmon::mib::info { oid } {

    return [ns_mib info $oid]
}

# Returns resolved value
proc ossmon::mib::value { oid value } {

    return [ns_mib value $oid $value]
}

# Initialize actions sub-system, load action rules from database
# and store them in local cache. Re-read database every poll interval.
proc ossmon::action::rules {} {

    return [ossweb::cache::run ossmon:cache action:rules {
      set action_rules [list]
      set rlist [ossweb::db::multilist sql:ossmon.action_rule.active]
      foreach item $rlist {
        foreach { rule_id rule_name mode } $item {}
        set match_rules [ossweb::db::multilist sql:ossmon.action_rule.match]
        if { $match_rules == "" } { continue }
        set match [ossmon::util::match_rules $match_rules]
        set script_rules [ossweb::db::list sql:ossmon.action_rule.script]
        if { $match == "" || $script_rules == "" } { continue }
        lappend action_rules "if { \[string equal -nocase $mode \[ossmon::object \$name action:process:mode\]\] && ([join $match " "]) } { [join $script_rules "\n"] }"
      }
      ossmon::log 9 ossmon::action:init $action_rules
      return $action_rules
    }]
}

# Refresh rules cache
proc ossmon::action::refresh {} {

    ossweb::cache::flush ossmon:cache action:rules
}

# Process all registered rules for a given object
proc ossmon::action::process { name mode } {

    ossmon::object $name -set action:process:mode $mode
    set object "$mode.[::ossmon::object $name ossmon:type].[::ossmon::object $name obj:type].[::ossmon::object $name obj:data]"
    set procs [lsort -decreasing [eval "namespace eval ::ossmon::action::process { info procs }"]]
    foreach proc $procs {
      set lproc [split $proc "."]
      if { ![string match -nocase "[lindex $lproc 0].[lindex $lproc 1].[lindex $lproc 2].[lindex $lproc 3]" $object] } { continue }
      ossmon::object $name -log 5 ossmon::action::process:$mode '$proc' ...
      if { [catch { ::ossmon::action::process::$proc $name } errmsg] } {
        global errorInfo
        ns_log Error ossmon::action::process:$mode: $name: '$proc': $errmsg: $errorInfo
      }
    }
}

# Executes action rules from database
proc ossmon::action::process::*.*.*.*.ActionRules { name args } {

    foreach rule [ossmon::action::rules] { eval $rule }
}

# Writes into status file about object monitoring event
proc ossmon::action::process::after.*.*.*.ActionStatus { name args } {

}

# Generic statistics collector
proc ossmon::action::process::before.poll.*.*.CollectStatistics { name args } {

    if { [set collect [ossmon::object $name ossmon:collect]] == "" ||
         [ossmon::object $name obj:rowcount] == 0 } { return }

    foreach { key value } $collect {
      set key [ossmon::object $name $key]
      if { [string first @ $value] > -1 } {
        set value [expr [subst [ossmon::template::compile $name $value]]]
      } else {
        set value [ossmon::object $name $value]
      }
      if { $key == "" || $value == "" } { continue }
      # Check collect interval
      if { [ossmon::util::interval $name $name:$key] != "" } { return }
      ossmon::object $name -set time:collect [ns_time]
      ossweb::db::exec sql:ossmon.collect.create
    }
}

# Initialize alerts sub-system, load alert rules from database
# and store them in local cache. Re-read database every poll interval.
proc ossmon::alert::rules {} {

    return [ossweb::cache::run ossmon:cache alert:rules {
      set alert_rules [list]
      set rlist [ossweb::db::multilist sql:ossmon.alert_rule.list -vars "status Active"]
      foreach item $rlist {
        foreach { rule_id rule_name precedence level threshold interval mode ossmon_type run_rules } $item {}
        set match_rules [ossweb::db::multilist sql:ossmon.alert_rule.match]
        if { $match_rules == "" } {
          continue
        }
        set match [ossmon::util::match_rules $match_rules]
        if { $run_rules == "" } {
          continue
        }
        set action [list]
        foreach { alert_type template_id template_name } $run_rules {
          lappend action "ossmon::alert::exec \$name {$ossmon_type} {$rule_name} {$alert_type} {$level} {$template_id} {$threshold} {$interval}"
        }
        lappend action "return stop"
        lappend alert_rules "if { \[string equal -nocase $mode \[ossmon::object \$name alert:process:mode\]\] && ([join $match " "]) } { [join $action "\n"] }"
      }
      ossmon::log 9 ossmon::alert:init $alert_rules
      return $alert_rules
    }]
}

# Refresh rules cache
proc ossmon::alert::refresh {} {

    ossweb::cache::flush ossmon:cache alert:rules
}

# Match alert rules against an object
# Each rule proc should consist from 4 parts:
#   mode.alert_status.ossmon_type.object_name.rule_name
proc ossmon::alert::process { name mode } {

    ossmon::object $name -set alert:process:mode $mode
    set object "$mode.[::ossmon::object $name alert:status].[::ossmon::object $name ossmon:type].[::ossmon::object $name obj:type].[::ossmon::object $name obj:data]"
    set procs [lsort -decreasing [eval "namespace eval ::ossmon::alert::process { info procs }"]]
    foreach proc $procs {
      set lproc [split $proc "."]
      if { ![string match -nocase "[lindex $lproc 0].[lindex $lproc 1].[lindex $lproc 2].[lindex $lproc 3].[lindex $lproc 4]" $object] } {
        continue
      }
      ossmon::log 5 ossmon::alert::process:$mode $name '$proc' ...

      switch [catch { set rc [::ossmon::alert::process::$proc $name] } errmsg] {
       0 {
         if { $rc == "stop" } {
           break
         }
       }
       default {
         global errorInfo
         ns_log Error ossmon::alert::process:$mode $name: '$proc': $errmsg: $errorInfo: [ossmon::object $name -dump -sep ", "]
       }
      }
    }
}

# Save alert data into cache and/or database
proc ossmon::alert::log { name log_data args } {

    ns_parseargs { {-log_alert ""} {-log_status ""} } $args

    if { $log_alert == "" } {
      if { [set log_alert [ossmon::object $name alert:id]] == "" } { return }
    }
    if { $log_status == "" } {
      set log_status [ossmon::object $name ossmon:status]
    }
    # Object attributes in the alert log
    if { [ossweb::true [ossmon::object $name ossmon:alert:log:dump -config]] } {
      append log_data "\n\nObject Dump:\n [ossmon::object $name -dump]"
    }
    ossweb::db::exec sql:ossmon.alert.log.create
}

# Add/Update alert property
proc ossmon::alert::property { name property_id value args } {

    ns_parseargs { {-new f} } $args

    # Save property in the ossmon object
    ossmon::object $name -set alert:$property_id $value
    # Try to save property in the database
    set alert_id [ossmon::object $name alert:id]
    if { $alert_id == "" } {
      return
    }
    if { $new != "t" } {
      ossweb::db::exec sql:ossmon.alert.property.update
    }
    if { $new == "t" || (![ossweb::db::rowcount] && $value != "") } {
      ossweb::db::exec sql:ossmon.alert.property.create
    }
}

# Executes alert for specified object
proc ossmon::alert::exec { name ossmon_type alert_name alert_type alert_level template_id threshold interval } {

    set now [ossmon::object $name time:now]
    set device_id [ossmon::object $name device:id]
    set ossmon_type [ossweb::nvl $ossmon_type [ossmon::object $name ossmon:type]]
    set cache [ossmon::object $name ossmon:timestamp]:$device_id:$alert_type:$alert_name

    ossmon::object $name -set ossmon:type $ossmon_type
    ossmon::object $name -set alert:cache $cache
    ossmon::object $name -set alert:name $alert_name
    ossmon::object $name -set alert:type $alert_type
    ossmon::object $name -set alert:level $alert_level
    ossmon::object $name -set template:id $template_id
    ossmon::object $name -incr obj:alertnum

    # Priority: 1. Alert and monitor type specific
    #           2. Alert specific
    #           3. Rule specific
    #           4. Global
    #           5. Global datetime specific
    if { [ossmon::object $name alert:threshold] == "" } {
      ossmon::object $name -set alert:threshold \
           [ossmon::object $name ossmon:alert:threshold:$ossmon_type:$alert_type \
               -config [ossmon::object $name ossmon:alert:threshold:$ossmon_type \
                   -config [ossweb::nvl $threshold \
                       [ossmon::object $name ossmon:alert:threshold -config 1]]]]
    }
    ossmon::object $name -set alert:interval \
         [ossmon::object $name ossmon:alert:interval:$ossmon_type:$alert_type \
               -config [ossmon::object $name ossmon:alert:interval:$ossmon_type \
                  -config [ossweb::nvl $interval \
                       [ossmon::object $name ossmon:alert:interval -config 600]]]]

    # Date/time specific threshold and interval settings
    ossmon::util::period $name ossmon:alert:interval:period -key alert:interval
    ossmon::util::period $name ossmon:alert:threshold:period -key alert:threshold
    # Now see what we have configured for this alert on current date time
    set threshold [ossmon::object $name alert:threshold]
    set interval [ossmon::object $name alert:interval]
    set result [ossmon::object $name alert:$cache]
    switch -regexp -- $result {
     {[0-9] [0-9]+} {
       # We have already been here, coming here again
       # means we process different table rows of the same monitor.
       foreach { result alert_id } $result {}
       ossmon::object $name -set alert:id $alert_id
     }

     default {
       # Read alert record, perform threshold and time verification
       set alert_data [ossweb::cache::run ossmon:alert $cache {
          if { ![ossweb::db::multivalue sql:ossmon.alert.read.count] } {
            # Increase alert count only first time when we read this alert record which
            # means it is increased with every new poll session only. Miltiple alerts
            # within the same poll session are counted as one alert event.
            incr alert_count
          } else {
            set alert_count 1
            set alert_time $now
            set alert_object [ossmon::object $name obj:id]
            set alert_id [ossweb::db::nextval ossmon_alert]
            # No alert record, create a new one
            ossweb::db::exec sql:ossmon.alert.create
          }
          return "alert:id $alert_id alert:count $alert_count alert:time $alert_time [array get properties]"
       }]
       # Update the object with alert information
       eval ossmon::object $name -set $alert_data
       set alert_id [ossmon::object $name alert:id]
       set alert_level [ossmon::object $name alert:level]
       set alert_count [ossmon::object $name alert:count -default 1]
       set alert_time [ossmon::object $name alert:time -default $now]
       ossweb::db::foreach sql:ossmon.alert.property.read_all {
         ossmon::object $name -set alert:$property_id $value
       }
       # Verify action threshold and interval, if number of issued alerts is equal
       # to configured initial threshold or interval between last alert and now is
       # greater than configured interval then generate alert
       if { ($now-$alert_time < $interval && $alert_count == $threshold) ||
            ($now-$alert_time >= $interval && $alert_count > $threshold) } {
         # Send notifications
         set result 1
         # Time of the last alert notification
         set alert_time $now
       } else {
         set result 0
         # Keep it as warning until threshold is reached
         if { $alert_count < $threshold } {
           set alert_level Critical
         }
       }
       ossmon::object $name -set alert:time $alert_time
       # Finally we can update the counter in the database
       ossweb::db::exec sql:ossmon.alert.update.count
       ossmon::object $name -set alert:$cache [list $result $alert_id]
       # Save for subsequent requests
       ossmon::object $name -log 0 ossmon::alert::exec $alert_name/$alert_type/$alert_level: Count=$alert_count:$threshold, Time=[expr $now-$alert_time]:$interval, Row=[ossmon::object $name obj:rownum], Result=$result
     }
    }
    # Flag about most recent alert result
    ossmon::object $name -set alert:result $result
    # Generate the message from template
    set body [ossmon::template::process $name [lindex [ossmon::template $template_id] 1]]
    # Queue alert data for actual delivery/logging which will be done by final handler
    ossmon::object $name -lappend alert:queue:$result:$alert_id:$alert_type:$alert_name $body
    return $result
}

# Update alert status
proc ossmon::alert::schedule { args } {

    ns_parseargs { {-alert_id ""} {-active_time ""} {-pending_time ""} } $args

    foreach alert [ossweb::db::multilist sql:ossmon.alert.read.active] {
      foreach { alert_id alert_type alert_status alert_count device_id interval } $alert {}
      set name ossmon::alert:$alert_id
      ossmon::object $name -create \
           ossmon:type alert \
           obj:data $alert_id \
           alert:id $alert_id \
           alert:count $alert_count \
           alert:type $alert_type \
           alert:status $alert_status \
           device:id $device_id
      set active_interval [ossweb::nvl $active_time [ossmon::object $name ossmon:alert:interval:active -config 600]]
      set pending_interval [ossweb::nvl $pending_time [ossmon::object $name ossmon:alert:interval:pending -config 900]]
      switch -- $alert_status {
       Active {
         # Active alert becomes pending
         if { $interval < $active_interval } {
           continue
         }
         set alert_status Pending
         ossweb::db::exec sql:ossmon.alert.update.status
         # Add device OK marker for immediate alert update
         if { $active_interval == 0 } {
           ossmon::alert::log $name "Device is OK" -log_alert $alert_id -log_status OK
         }
       }

       Pending {
         # Pending alert becomes closed
         if { $interval < $pending_interval } {
           continue
         }
         set alert_status Closed
         ossweb::db::exec sql:ossmon.alert.update.status
       }
      }
      # Update with new status and properties
      ossmon::object $name -set alert:status $alert_status
      ossweb::db::foreach sql:ossmon.alert.property.read_all {
        ossmon::object $name -lappend alert:$property_id $value
      }
      # Run status handlers
      ossmon::alert::process $name status
    }
    return
}

proc ossmon::alert::html::info { args } {

    ns_parseargs { {-row2 "</TR><TR>"}
                   {-alert_id ""}
                   {-alert_type ""}
                   {-alert_status ""}
                   {-obj_type ""}
                   {-alert_level ""}
                   {-alert_count ""}
                   {-alert_name ""}
                   {-alert_time ""}
                   {-winopts "menubar=0,width=800,height=600,location=0,scrollbars=1" } } $args

    switch -- $alert_level {
     Critical { set class ARST }
     Warning { set class AWST }
     Advise { set class AAST }
     default { set class AEST }
    }
    return "<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0>
            <TR><TD CLASS=$class>
                   #$alert_id: $alert_time ($obj_type/$alert_type/$alert_count)
                </TD>
                <TD ROWSPAN=2 VALIGN=MIDDLE>
                [ossweb::lookup::link -image alert.gif -alt "Alert Info" -window Alert -winopts $winopts alerts cmd info alert_id $alert_id lookup:mode 2]
                </TD>
            $row2
                <TD CLASS=$class>
                $alert_name ($alert_level/ $alert_status)
                </TD>
            </TR>
            </TABLE>"
}

# Returns list of all supported alert actions
proc ossmon::alert::action::get_types {} {

    variable types
    set options ""
    foreach type [namespace children ::ossmon::alert::action] {
      lappend options [list [set ${type}::title] [namespace tail $type]]
    }
    return $options
}

# Return object type title by type
proc ossmon::alert::action::get_title { type } {

    if { [info exists ::ossmon::alert::action::${type}::title] } {
      return [set ::ossmon::alert::action::${type}::title]
    }
    return $type
}

# Create alert log entry
proc ossmon::alert::action::alert::exec { name subject body } {

    ossmon::alert::log $name $body
}

# Create email message about a OSSMON object
proc ossmon::alert::action::email::exec { name subject body } {

    # See if there are any time specific emails configured
    if { [set email [ossmon::util::period $name ossmon:alert:email:period]] == "" } {
      # Default global alert email
      set email [ossmon::object $name ossmon:alert:email -config]
    }
    # Check if there are any additional email addresses
    foreach key { cc ossmon:type obj:type obj:data alert:level } {
      # For special key its value should be retrieved from the object
      if { [string first : $key] > 0 } {
        set key [ossmon::object $name $key]
      }
      if { [set data [ossmon::object $name ossmon:alert:email:$key -config]] != "" } {
        append email ",$data"
      }
    }
    if { $email != "" } {
      ::ossweb::sendmail $email ossmon $subject $body -direct t
      set body "Sent to: $email\n$body"
    }
    # Create log entry about this event
    ossmon::alert::log $name $body

}

# Create developer problem record for a OSSMON object
proc ossmon::alert::action::problem::exec { name subject body } {

    set project_id [ossmon::object $name ossmon:alert:problem:project -config]
    if { $project_id == "" } {
      ns_log Error "ossmon::alert::action::problem: $name: No Alert Project configured: $subject"
      return
    }
    set count 0
    if { [ossweb::true [ossmon::object $name ossmon:alert:problem:notes -config t]] } {
      # Add notes to existing problem
      foreach problem_id [ossmon::object $name alert:problem:id] {
        if { $problem_id <= 0 } {
          continue
        }
        ossweb::db::exec sql:ossmon.alert.problem.notes
        incr count
      }
    }
    if { !$count } {
      # Create new problem ticket
      set problem_id [ossweb::db::value sql:ossmon.alert.problem.create]
      if { $problem_id != "" } {
        ossmon::alert::property $name problem:id $problem_id -new t
        set body "Problem ID: $problem_id\n\n$body"
      }
    }
    # Create log entry about this event
    ossmon::alert::log $name $body
}

# To be run on alert close, shoudl take care about problem alert
proc ossmon::alert::action::problem::status.Closed { name args } {

    set skip [ossmon::object $name ossmon:alert:problem:closed:skip -config f]
    foreach problem_id [ossmon::object $name alert:problem:id] {
      if { $problem_id > 0 && ![ossweb::true $skip] && [ossweb::db::value sql:ossmon.alert.problem.active] == "1" } {
        ossweb::db::exec sql:ossmon.alert.problem.close
      }
    }
}

# Executes external program
proc ossmon::alert::action::exec::exec { name subject body } {

    set exec [ossmon::util::period $name ossmon:alert:exec]
    if { $exec == "" } {
      ns_log Error "ossmon::alert::action::exec: $name: No Alert Exec configured: $subject"
      return
    }
    # Pass body to standard input of the external program
    set tmpfile /tmp/ossmon[ossmon::object $name alert:id][ossmon::object $name session:timestamp]
    ossweb::write_file $tmpfile $body
    if { [catch { ::exec /bin/sh -c "cat $tmpfile | $exec" } errmsg] } {
      ns_log Error ossmon::alert::action::exec: $name: $exec: $errmsg
      append body "\n" $errmsg
    }
    catch { file delete -force $tmpfile }
    # Create log entry about this event
    ossmon::alert::log $name $body
}

# To be run on alert close, run on close program to posibly unset alert condition
proc ossmon::alert::action::exec::status.Closed { name args } {

    set exec [ossmon::util::period $name ossmon:alert:exec:closed]
    if { $exec != "" } {
      if { [catch { ::exec /bin/sh -c "$exec" } errmsg] } {
        ns_log Error ossmon::alert::action::exec.Closed: $name: $exec: $errmsg
      }
    }
}

# Log alert via syslog
proc ossmon::alert::action::syslog::exec { name subject body } {

    set host [ossmon::object $name ossmon:syslog:host -config /dev/log]
    set facility [ossmon::object $name ossmon:syslog:facility -config local7]
    set severity [ossmon::object $name ossmon:syslog:severity -config alert]

    ns_syslogd -host $host -facility $facility -severity $priority "ossmon: $subject"
    foreach line [split $body "\n"] {
      if { [set line [string trim $line]] == "" } { continue }
      ns_syslogd -host $host -facility $facility -severity $severity "ossmon: $line"
    }
}

# Send SNMP trap with alert info
proc ossmon::alert::action::trap::exec { name subject body } {

    if { [set host [ossmon::object $name ossmon:trap:host -config]] == "" } {
      return
    }
    set port [ossmon::object $name ossmon:trap:port -config 162]
    set oid [ossmon::mib::oid [ossmon::object $name ossmon:trap:oid -config ossmonAlert]]
    set enterprise [ossmon::mib::oid [ossmon::object $name ossmon:trap:enterprise -config ossmon]]
    set var [ossmon::mib::oid [ossmon::object $name ossmon:trap:var -config ossmonTrap]]
    if { [catch {
      set fd [ns_snmp create $host -port $port]
      ns_snmp trap $fd $oid $enterprise $var s $subject $var s $body
      ns_snmp destroy $fd
    } errmsg] } {
      catch { ns_snmp destroy $fd }
    }
}

# Global handler to apply alert rules
proc ossmon::alert::process::alert.*.*.*.*.ruleHandler { name args } {

    global errorInfo

    foreach rule [ossmon::alert::rules] {
      switch [catch { eval $rule } errmsg] {
       0 - 3 - 4 {}
       2 { return $errmsg }
       default {
         ns_log Error ossmon::alert::process: $rule: $errmsg: $errorInfo
       }
      }
    }
}

# Global handler to be run after all processing to do actual alerts delivery
proc ossmon::alert::process::final.*.*.*.*.alertHandler { name args } {

    if { [set subject [ossmon::object $name ossmon:alert:subject]] == "" } {
      set subject "[ossmon::property product:name]: [ossmon::object $name obj:host]: [ossmon::object $name device:name]"
    }
    # Deliver alert per alert type and alert name
    foreach { alert body } [ossmon::object $name -match {^alert:queue:[0-9]:[0-9]+:[^:]+:}] {
      set alert [split $alert :]
      set result [lindex $alert 2]
      set alert_id [lindex $alert 3]
      set alert_type [lindex $alert 4]
      set alert_name [join [lrange $alert 5 end] :]
      # Ignore empty bodies, nothing to say do not bother to send
      if { [set body [join $body "\n"]] == "" } {
        continue
      }
      # Setup alert data before calling alert handler
      ossmon::object $name -set \
           alert:id $alert_id \
           alert:type $alert_type \
           alert:name $alert_name \
           alert:data $body

      switch -- $result {
       0 {
         ossmon::alert::log $name $body
       }

       1 {
         ossmon::alert::action::${alert_type}::exec $name "$subject: $alert_name" $body
       }
      }
    }
}

# Global handler for alerts, called on alert close, run all registered onClose handlers for
# each alert type, it is up to the handler to decide what to do
proc ossmon::alert::process::status.Closed.*.*.*.alertHandler { name args } {

    foreach type [namespace children ::ossmon::alert::action] {
      if { [info proc ${type}::status.closed] != "" } {
        if { [catch { ${type}::status.Closed $name } errmsg] } {
          ns_log Error ossmon::alert::process::status.Closed.*.*.*.alertHandler: $proc: $errmsg
        }
      }
    }
}

# Returns list of all supported chart types suitable for use in select boxes
proc ossmon::chart::get_types {} {

    variable types
    set options ""
    foreach { type title } $types {
      lappend [list $title $type]
    }
    return $options
}

# Return chart title by type
proc ossmon::chart::get_title { type } {

    variable types

    if { [info exists types($type)] } {
      return $types($type)
    }
    return $type
}

# Generate chart for given monitor, return image name
# -start_date and -end_date are timestamps in seconds since epoch.
proc ossmon::chart::exec { obj_id type args } {

    ns_parseargs { {-start_date {=$expr [ns_time]-86400}}
                   {-end_date {=$ns_time}}
                   {-path modules/charts}
                   {-url charts}
                   {-bgcolor 0xf2f5fa}
                   {-gridcolor 0x3c4e5e}
                   {-color2 0x1441c9}
                   {-color1 0x3cc945}
                   {-format "%m/%d/%y %H:%M"}
                   {-chart_type linearea}
                   {-cache t}
                   {-file_name ""}
                   {-file_count 0}
                   {-layer_count 2}
                   {-filter ""}
                   {-debug f}
                   {-type_name ""}
                   {-small f}
                   {-width 450}
                   {-height 250}
                   {-legendy 210}
                   {-hardheight 170}
                   {-hide f}
                   {-trend f}
                   {-title ""}
                   {-onoff ""}
                   {-yaxis ""}
                   {-mkdir f} } $args

    if { $obj_id == "" } {
      ns_log Error ossmon::chart: obj_id should be specified
      return
    }
    # Create object for features and properties
    ossmon::object obj -create obj:id $obj_id

    # Use first chart type from the supported charts
    if { $type == "" } {
      set type [ossmon::object obj obj:charts -default [lindex [ossmon::object obj -info:charts] 0]]
    }

    # Determine chart title
    if { $type_name == "" } {
      set type_name [ossmon::object obj ossmon:chart:title -default [ossmon::chart::get_title $type]]
    }
    # Dynamic average type
    if { $onoff == "" } {
      set onoff [ossmon::object obj ossmon:chart:sno:onoff]
    }
    # Y axis title
    if { $yaxis == "" } {
      set yaxis [ossmon::object obj ossmon:chart:yaxis -default Value]
    }
    # Scale for bit rates
    switch -- [set scale_name [ossmon::object obj ossmon:chart:scale -default Mbits]] {
     Kbits {
       set scale_rate 1025
     }

     Mbits -
     default {
       set scale_rate 1024*1024
     }
    }

    set images ""
    set property_id ""
    # Round to nearest 5 minutes
    set start_date [expr $start_date - ($start_date % 10)]
    set end_date [expr $end_date - ($end_date % 10)]
    if { $title == "" } {
      set title "$type_name [ns_fmttime $start_date "%Y-%m-%d %H:%M"]:[ns_fmttime $end_date "%Y-%m-%d %H:%M"]"
    } else {
      set title "$type_name $title"
    }
    # Generate unique image name
    if { $file_name == "" } {
      set file_name [ns_fmttime $start_date "%Y%m%d%H%M"]:[ns_fmttime $end_date "%Y%m%d%H%M"]:${hide}:${obj_id}:${type}:
    }
    # Make it absolute path
    if { [string index $path 0] != "/" } {
      set path "[ns_info home]/$path"
    }
    # Check if we already have such images
    if { $cache == "t" } {
      foreach image [glob -nocomplain $path/$file_name*] {
        lappend images $url/[file tail $image]
      }
      if { $images != "" } {
        ns_log Notice ossmon::chart: found: $images
        return $images
      }
    }

    switch $type {
     collect {
      set column_value1 "TO_NUMBER(value::TEXT,'999999999.99')"
      set column_value2 "TO_NUMBER(value2::TEXT,'999999999.99')"
      set column_name1 name
      set column_name2 name2
      set column_name name
      set table ossmon_collect
     }

     ping {
      set column_value1 "TO_NUMBER(rtt_max::TEXT,'999999999.99')"
      set column_value2 "TO_NUMBER(rtt_min::TEXT,'999999999.99')"
      set column_name1 "'ICMP MAX. RTT'"
      set column_name2 "'ICMP MIN. RTT'"
      set column_name host
      set table ossmon_ping
      set yaxis "miliseconds"
     }

     if_load {
      set column_value1 "TO_NUMBER(utilization::TEXT,'999.99')"
      set column_value2 "NULL"
      set column_name1 name
      set column_name2 "NULL"
      set column_name name
      set table ossmon_iftable
      set yaxis "Percentage"
      set property_id interface:filter
     }

     if_drop {
      set column_value1 "TO_NUMBER(ROUND(((in_drop*8)/($scale_rate))::NUMERIC,2)::TEXT,'9999999999.99')"
      set column_value2 "TO_NUMBER(ROUND(((out_drop*8)/($scale_rate))::NUMERIC,2)::TEXT,'9999999999.99')"
      set column_name1 "'Input: '||name"
      set column_name2 "'Output: '||name"
      set column_name name
      set table ossmon_iftable
      set yaxis "$scale_name/sec"
      set property_id interface:filter
     }

     if_rate {
      set column_value1 "TO_NUMBER(ROUND(((in_rate*8)/($scale_rate))::NUMERIC,2)::TEXT,'9999999999.99')"
      set column_value2 "TO_NUMBER(ROUND(((out_rate*8)/($scale_rate))::NUMERIC,2)::TEXT,'9999999999.99')"
      set column_name1 "'Input: '||name"
      set column_name2 "'Output: '||name"
      set column_name name
      set table ossmon_iftable
      set yaxis "$scale_name/sec"
      set property_id interface:filter
     }

     if_pkt {
      set column_value1 "TO_NUMBER(in_pkt::TEXT,'99999999')"
      set column_value2 "TO_NUMBER(out_pkt::TEXT,'99999999')"
      set column_name1 "'Input: '||name"
      set column_name2 "'Output: '||name"
      set column_name name
      set table ossmon_iftable
      set yaxis "Pkts/sec"
      set property_id interface:filter
     }

     if_trans {
      set column_value1 "TO_NUMBER((in_trans/1024)::TEXT,'9999999999.99')"
      set column_value2 "TO_NUMBER((out_trans/1024)::TEXT,'9999999999.99')"
      set column_name1 "'Input: '||name"
      set column_name2 "'Output: '||name"
      set column_name name
      set table ossmon_iftable
      set yaxis "KBytes"
      set property_id interface:filter
     }

     default {
       error "OSSWEB: Unknown chart type $type"
     }
    }
    # Object filter
    if { $filter == "" && $property_id != "" } {
      set filter [ossweb::db::value sql:ossmon.object.property.value]
    }
    set name $filter
    # Setup format for time
    if { $end_date - $start_date < 86400+60 } {
      set format "%H:%M"
    } elseif { $end_date - $start_date < 86400*31 } {
      set format "%m/%d %H:%M"
    }
    # Read data series
    set sno 0
    set smax 0
    ossweb::db::foreach sql:ossmon.chart.read {
      foreach { name value } [list $name1 $value1 $name2 $value2] {
        if { $name == "" || $value == "" } {
          continue
        }
        if { ![info exists series($name)] } {
          incr sno
          set series($name) $sno
          if { $onoff == $sno } {
            set datasets($sno) [list $name 0 0 0]
          } else {
            set datasets($sno) [list $name $value $value 0]
          }
        }
        set sno $series($name)
        set timestamps($timestamp) ""
        # On/off type, calculate percent of 1 and 0
        if { $onoff == $sno } {
          foreach { name on off count } $datasets($sno) {}
          if { $value > 0 } {
            incr on
          } else {
            incr off
          }
          set datasets($sno) [list $name $on $off [incr count]]
        } else {
          foreach { name max sum count } $datasets($sno) {}
          if { $max < $value } {
            set max $value
          }
          set datasets($sno) [list $name $max [expr $value+$sum] [incr count]]
        }
        set values(${sno}:${timestamp}) $value
      }
      # Total maximum
      if { $smax < $max } {
        set smax $max
      }
    } -debug $debug
    if { $sno == 0 } {
      if { $debug == "t" } {
        ns_log Notice ossmon::chart: $type: $obj_id, no data for $start_date/$end_date
      }
      return
    }
    # Build labels
    set count 0
    set labels ""
    set dates [lsort -integer [array names timestamps]]
    foreach timestamp $dates {
      lappend labels [ns_fmttime $timestamp $format]
    }
    # Support for dynamic on/off charts, keep it at the middle
    if { $onoff != "" } {
      set smax [expr $smax/2]
    }
    # Build chart(s)
    set chart ""
    set images ""
    set layer 0
    set files 0
    set lastValue *
    foreach sno [lsort -integer [array names datasets]] {
      # Generate multiple charts if we have too many series
      if { $chart == "" || $layer == $layer_count } {
        if { $chart != "" } {
          if { $file_count > 0 && $files == $file_count } {
            break
          }
          ns_gdchart setcolors $chart "$color1 $color2"
          ns_gdchart save $chart $path/$file_name$files.png
          ns_gdchart destroy $chart
          lappend images $url/$file_name$files.png
        }
        incr files
        set layer 0
        set lastValue *
        set chart [ns_gdchart create \
                      type $chart_type \
                      title $title \
                      ytitle $yaxis \
                      ylabelfmt %.1f \
                      xtitle Time \
                      xaxisangle 0 \
                      width $width \
                      height $height \
                      bgcolor $bgcolor \
                      gridcolor $gridcolor \
                      gridontop 1 \
                      linecolor 0x000000 \
                      legend right \
                      legendx 5 \
                      legendy $legendy \
                      hardheight $hardheight]
        ns_gdchart setlabels $chart $labels
      }
      set val $datasets($sno)
      # Chart type specific actions
      if { $onoff == $sno } {
        foreach { name on off count } $val {}
        set name "$name, On=[format "%.2f" [expr $on*100.0/$count]]%, Off=[format "%.2f" [expr $off*100.0/$count]]%"
      } else {
        foreach { name max sum count } $val {}
        if { $hide == "t" } {
          set name "DataSet$layer"
        }
        set name "$name, Max=[format "%.2f" $max], Avg=[format "%.2f" [expr $sum/$count]]"
      }
      set data ""
      foreach time $dates {
        if { [info exists values(${sno}:${time})] } {
          set lastValue $values(${sno}:${time})
        }
        # Special on/off type
        if { $onoff == $sno } {
          if { $lastValue > 0 } {
            set lastValue $smax
          }
        }
        lappend data $lastValue
      }
      ns_gdchart setdata $chart $name $data
      incr layer
    }
    if { $mkdir == "t" && ![file exists $path] } {
      file mkdir $path
    }
    ns_gdchart setcolors $chart "$color1 $color2"
    ns_gdchart save $chart $path/$file_name$files.png
    ns_gdchart destroy $chart
    lappend images $url/$file_name$count.png
    if { $debug == "t" } {
      ns_log Notice ossmon::chart: [lsort -integer [array names datasets]]: $images
    }
    return $images
}

# Templates initialization
proc ossmon::template { template_id } {

    return [ossweb::cache::run ossmon:cache template:$template_id {
      if { ![ossweb::db::multivalue sql:ossmon.template.read] } {
        return [list $template_name $template_actions]
      }
      return
    }]
}

# Flush template memory
proc ossmon::template::flush {} {

    foreach name [ossweb::cache::keys ossmon:cache] {
      switch -glob -- $name {
       template:* {
         ossweb::cache::flush ossmon:cache $name
       }
      }
    }
}

# Performs placeholder substituion
proc ossmon::template::compile { name template args } {

    while {[regsub -all {@([a-zA-Z0-9_: \|-]+)\^([^@]+)@} $template "\[ossmon::object $name \\1 -config \\2\]" template]} {}
    while {[regsub -all {@([a-zA-Z0-9_: \|-]+)@} $template "\[ossmon::object $name \\1\]" template]} {}
    return $template
}

# Process template for a given object
proc ossmon::template::process { name template } {

    ossweb::adp::Reset
    ossweb::adp::Buffer init
    # We call template processor which will handle regular template tags
    set template [ossweb::adp::Compile $template 0]
    # substitute placeholders with ossmon object calles
    set template [ossmon::template::compile $name $template]
    if { [catch {
      eval $template
      set result [ossweb::adp::Buffer get output]
    } errmsg] } {
      ns_log Error ossmon::template::process $name: $errmsg: Template: $template: [ossmon::object $name -dump -sep ", "]
      return ""
    }
    return $result
}

proc ossmon::trap::process {} {

    set ipaddr [ns_trap address]
    set oid [ossmon::mib::label [ns_trap oid]]
    set enterprise [ossmon::mib::label [ns_trap enterprise]]
    set uptime [ns_trap uptime]
    set data [ns_trap vb]

    # Create OSSMON object
    set name "trap.$ipaddr.$oid.$enterprise"
    ossmon::object $name -create \
         ossmon:type trap \
         obj:name $oid \
         obj:data $oid \
         obj:host $ipaddr \
         obj:type trap

    # Log the trap
    set vars [list]
    set trapvars [list]
    foreach vb $data {
      set oid [lindex $vb 0]
      set label [ossmon::mib::label $oid]
      set value [string map { "\n" {} "\r" {} "\t" {} } [ossmon::mib::value $oid [lindex $vb 2]]]
      ossmon::object $name -set $label $value
      lappend vars "${label}([lindex $vb 1]) = $value"
      lappend trapvars $label
    }

    # Update object trap info
    ossmon::object $name -set \
         trap:type [ns_trap type] \
         trap:oid $oid \
         trap:enterprise $enterprise \
         trap:uptime $uptime \
         trap:vars $trapvars

    # Try to find device
    if { ![ossmon::device::resolve $name $ipaddr] } {
      ns_log Notice TRAP: From: $ipaddr, Enterprise: $enterprise, OID: $oid, Uptime: $uptime, $vars
      return
    }

    # Show trap contents in the log if needed
    ossmon::object $name -log 1 TRAP From: $ipaddr: [ossmon::object $name -array]

    # Process rules
    ossmon::poll::process $name
    ossmon::object::shutdown $name -destroy t

    # Update status of the object
    if { [set obj_id [ossmon::object $name obj:id]] != "" } {
      ossweb::db::exec sql:ossmon.object.update.status
    }
}

# Reformats MAC address
proc ossmon::util::macaddr { macaddr { type "" } } {

    set m [string tolower [string map { . {} : {} { } {} - {} _ {} } $macaddr]]
    switch -- $type {
     cisco {
       return [string range $m 0 3].[string range $m 4 7].[string range $m 8 11]
     }
     default {
       return [string range $m 0 1]:[string range $m 2 3]:[string range $m 4 5]:[string range $m 6 7]:[string range $m 8 9]:[string range $m 10 11]
     }
    }
}

# Converts string IP address into binary representation
proc ossmon::util::inet_addr { ipaddr } {

    set addr [binary format c4 [split $ipaddr .]]
    binary scan $addr i bin
    return $bin
}

# Converts binary IP address into string
proc ossmon::util::inet_ntoa { ipaddr } {

    set bin [binary format i $ipaddr]
    binary scan $bin cccc a b c d
    set a [expr { ($a + 0x100) % 0x100 }]
    set b [expr { ($b + 0x100) % 0x100 }]
    set c [expr { ($c + 0x100) % 0x100 }]
    set d [expr { ($d + 0x100) % 0x100 }]
    return "$a.$b.$c.$d"
}

# Returns Tcl list with matching rules. Each item of the list
# contains Tcl code which should be used within if statement.
# Rules list contains following elements: name operator value ...
proc ossmon::util::match_rules { rules } {

    set match {}
    foreach item $rules {
      set prefix ""
      set suffix ""
      set name [lindex $item 0]
      set oper [lindex $item 1]
      if { [string index $name 0] == "(" } {
        append prefix "("
        set name [string range $name 1 end]
      }
      set value [lindex $item 2]
      if { [string index $value end] == ")" } {
        append suffix ")"
        set value [string range $value 0 end-1]
      }
      set name [string trim $name { \"\{\}}]; #"
      set name [ossmon::template::compile \$name $name]
      set value [string trim $value { \"\{\}}]; #"
      set value [ossmon::template::compile \$name $value]
      if { ![regexp {[\[\+\-\/\*]} $value] } {
        set value "{$value}"
      }
      set mode [lindex $item 3]
      if { [string index $oper 0] == "!" } {
        append prefix "!"
        set oper [string range $oper 1 end]
      }
      switch -- $oper {
       gmatch { set expr "${prefix}(\[ossmon::object \$name -gmatch $name $value\])$suffix" }
       gregexp { set expr "${prefix}(\[ossmon::object \$name -gregexp $name $value\])$suffix" }
       match { set expr "$prefix\[string match -nocase $value $name\]$suffix" }
       regexp - contains { set expr "${prefix}\[regexp -nocase $value $name\]$suffix" }
       "=" - "==" { set expr "$prefix\[string equal $name $value\]$suffix" }
       ">" - "<" - ">=" - "<=" { set expr "${prefix}($name $oper $value)$suffix" }
       default {
         ns_log Notice ossmon::util::match_rules: unrecognised operation: $item
         continue
       }
      }
      if { $match != {} } {
        switch $mode {
         "OR" { set expr "|| $expr" }
         "NOT AND" { set expr "&& !($expr)" }
         "NOT OR" { set expr "|| !($expr)" }
         default { set expr "&& $expr" }
        }
      }
      lappend match $expr
    }
    return $match
}

# Parses network errors
proc ossmon::util::parseError { errmsg } {

    switch -regexp -- $errmsg {
     "couldn't open \".+\":" -
     "couldn't open socket" -
     "error flushing" -
     "host is unreachable" -
     "could not connect" -
     "can't connect" -
     "connection refused" {
       set errmsg "noResponse: $errmsg"
     }
     fork - "not enough memory" {
       ns_log Error ossmon::util::parseError: $errmsg
       ns_shutdown 1
     }
    }
    return $errmsg
}

# Parses time and converts it into seconds.
# Allowed format: Mm Ss HhMm Hh Mm Ss
#    where M is minutes
#          H is hours
#          S is seconds
#          m,h,s reserved works for minutes,hours and second respectively
proc ossmon::util::parseTime { value } {

    if { [regexp {([0-9]+h)} $value match hours] } {
      set hours [ossweb::nvl [string range $hours 0 end-1] 0]
    } else {
      set hours 0
    }
    if { [regexp {([0-9]+m)} $value match minutes] } {
      set minutes [ossweb::nvl [string range $minutes 0 end-1] 0]
    } else {
      set minutes 0
    }
    if { [regexp {([0-9]+s)} $value match seconds] } {
      set seconds [ossweb::nvl [string range $seconds 0 end-1] 0]
    } else {
      set seconds 0
      if { !$hours && !$minutes } {
        set seconds $value
      }
    }
    if { [catch { set value [expr $hours*60*60+$minutes*60+$seconds] } errmsg] } {
      return ""
    }
    return $value
}

# Parses time period, returns 1 if currenty time falls inside any of the specified periods
# Allowed format: [[dow] [mm/dd/yy]] hh:mm - [[dow] [mm/dd/yy]] hh:mm,.....
proc ossmon::util::parseTimePeriod { period } {

    set now [ns_time]
    set dow [ns_fmttime $now "%w"]
    array set week { SUN 0 MON 1 TUE 2 WED 3 THU 4 FRI 5 SAT 6 }

    foreach period [split $period ","] {
      # Initialize local variables
      foreach { dow1 dow2 date1 date2 time1 time2 } { "" "" "" "" "" 23:59:59 } {}
      set period [split $period -]
      set period1 [string trim [lindex $period 0]]
      set period2 [string trim [lindex $period 1]]
      # Parse each part of the period
      if { ![regexp {^([0-9]+\/[0-9]+\/[0-9]+)[ ]+([0-9]+\:[0-9]+)$} $period1 d date1 time1] &&
           ![regexp {^([a-zA-z]+)[ ]+([0-9]+\:[0-9]+)$} $period1 d dow1 time1] &&
           ![regexp {^([0-9]+\:[0-9]+)$} $period1 d time1] } {
        ns_log Notice Error ossmon::util::parseTimePeriod: invalid period $period1
        continue
      }
      if { ![regexp {^([0-9]+\/[0-9]+\/[0-9]+)[ ]+([0-9]+\:[0-9]+)$} $period2 d date2 time2] &&
           ![regexp {^([a-zA-z]+)[ ]+([0-9]+\:[0-9]+)$} $period2 d dow2 time2] &&
           ![regexp {^([0-9]+\:[0-9]+)$} $period2 d time2] } {
        ns_log Notice Error ossmon::util::parseTimePeriod: invalid period $period2
        continue
      }
      if { [catch { set time1 [clock scan "$date1 $time1"] }] ||
           [catch { set time2 [clock scan "$date2 $time2"] }] } {
        continue
      }
      set dow1 [ossweb::coalesce week([string toupper $dow1])]
      set dow2 [ossweb::coalesce week([string toupper $dow2])]
      if { $dow1 != "" && $dow2 != "" } {
        if { !($dow >= $dow1 && $dow <= $dow2) } { continue }
      } else {
        if { $dow1 != "" && $dow != $dow1 } { continue }
        if { $dow2 != "" && $dow != $dow2 } { continue }
      }
      if { $now >= $time1 && $now <= $time2 } { return 1 }
    }
    return 0
}

# OSSMON related log file with the latest status snapshot
proc ossmon::util::status { data { mode a } } {

    set path "[ns_info pageroot]/[ossweb::config server:project]/ossmon/status.txt"
    if { [catch {
        set fd [::open $path $mode]
        ::puts $fd $data
        close $fd
    } errMsg] } {
      ns_log Error ossmon::util::status: mode=$mode, $errMsg
    }
}

# Opens TCP connectin
proc ossmon::util::open { host port args } {

    ns_parseargs { {-timeout 30} } $args

    set fd [ns_sockopen -nonblock $host $port]
    ::close [lindex $fd 1]
    return [lindex $fd 0]
}

# Reads one line from the socket
proc ossmon::util::gets { fd args } {

    ns_parseargs { {-timeout 30} {-error t} {-ascii t} {-size 0} } $args

    set done 0
    set bytes 0
    set line ""
    set now [ns_time]
    while { !$done && [ns_sockcheck $fd] } {
      if { [set bytes [ns_socknread $fd]] == 0 } {
        if { [lindex [ns_sockselect -timeout $timeout $fd {} {}] 0] == "" ||
             [set bytes [ns_socknread $fd]] == 0 && [ns_time]-$now > $timeout*2 } {
          if { $error == "t" } {
            error "noResponse: read timeout"
          }
          return $line
        }
      }
      while { $bytes > 0 } {
        if { [set char [::read $fd 1]] == "\n" } {
          set done 1
          break
        }
        incr bytes -1
        switch -- $char {
         "\r" {}
         default {
           if { $ascii == "t" } {
             if { ![string is ascii $char] || ![string is print $char] } {
               continue
             }
           }
           append line $char
         }
        }
        # Check for max limit
        if { $size > 0 && [string length $line] >= $size } {
          set done 1
          break
        }
      }
    }
    return $line
}

# Writes text to the socket
proc ossmon::util::puts { fd str args } {

    ns_parseargs { {-timeout 30} {-error t} {-nonewline f} } $args

    if { [lindex [ns_sockselect -timeout $timeout {} $fd {}] 1] == "" } {
      if { $error == "t" } {
        error "noResponse: write timeout"
      }
    }
    if { $nonewline == "t" } {
      ::puts -nonewline $fd $str
    } else {
      ::puts $fd $str
    }
    ::flush $fd
}

# Verify interval between polling, returns empty string if
# interval elapsed or last cached time if not
proc ossmon::util::interval { name key } {

    set time [ns_time]
    set time2 [ossweb::cache get collect:$key:time 0]
    set count [ossweb::cache get collect:$key:count 0]
    set interval [ossweb::date duration \
                       [ossmon::object $name ossmon:collect:interval \
                             -config [ossmon::object $name ossmon:poll:interval -config 60]]]

    if { $time2 > 0 && [expr $time-$time2] < $interval } {
      incr count
      if { $count > 2 } {
        ossmon::object $name -log 3 ossmon::util::interval Key=$key, Interval=$interval, Count=$count, Time=[ns_fmttime $time2]([expr $time-$time2])
      }
      ossweb::cache set collect:$key:count $count
      return $time2
    }
    ossweb::cache set collect:$key:time $time
    ossweb::cache set collect:$key:count 0
    return
}

# Regexp filter
proc ossmon::util::filter { filter value } {

    if { [string index $filter 0] == "!" } {
      return [expr 1-[regexp [string range $filter 1 end] $value]]
    }
    return [regexp $filter $value]
}

# Parameter 'config' contains period descriptors, if current time mathes any of
# periods then set monitor's 'key' with value and return it
# Period format:
#  "datetime;duration;value" ...
#    where datetime can be any {HH:MI} or {MM/DD/YYYY HH:MI} or {Sun|...|Sat HH:MI}
#          duration is number of seconds or NNh for hours or NNm for minutes
# Example: "12:00;3600;1" "Sun 1:0;7200;2" "2004/01/01 0:0;3600;3"
proc ossmon::util::period { name config args } {

    ns_parseargs { {-key ""} {-novalue f} } $args

    switch -- $novalue {
     f {
       foreach period [ossmon::object $name $config -config] {
         if { [llength [set period [split $period ";"]]] != 3 } { continue }
         foreach { period duration value } $period {}
         if { [ossweb::date period $period $duration] } {
           if { $key != "" } { ossmon::object $name -set $key $value }
           return $value
         }
       }
     }

     t {
       foreach period [ossmon::object $name $config -config] {
         if { [llength [set period [split $period ";"]]] != 2 } { continue }
         foreach { period duration } $period {}
         if { [ossweb::date period $period $duration] } { return 1 }
       }
     }
    }
    return
}

# Returns 1 if given propetty is sensitive and should not be displayed
proc ossmon::util::sensitive { name args } {

    if { [regexp -nocase {password|passwd|community|secret} $name] &&
         [ossweb::conn::check_acl -acl "*.*.*.update.*" ] } {
      return 1
    }
    return 0
}

# Resolves device by IP address, updates device info in the given OSSMON object
# if device is found. Returns found device_id or 0.
proc ossmon::device::resolve { name device_host } {

    # Check for custom resolver for the device
    if { [info proc ::ossmon::device::resolve::$device_host] != "" } {
      return [::ossmon::device::resolve::$device_host $name]
    }

    if { [ossweb::db::multivalue sql:ossmon.device.search.by.ipaddr] } {
      return 0
    }

    ossmon::object $name -set \
         device:id $device_id \
         device:name $device_name \
         device:type $device_type \
         device:description $description \
         location:name $location_name

    # Take first object to assign trap to
    ossweb::db::foreach sql:ossmon.device.list.children {
      foreach { _t _obj_id _obj_type _obj_name } $_device_objects {}
      ossmon::object $name -set obj:id $_obj_id obj:name $_obj_name
      break
    } -prefix _

    return [ossmon::object $name device:id]
}

# Returns icon for the device or object
proc ossmon::device::icon { device_vendor device_type args } {

    ns_parseargs { {-device_id ""} } $args

    if { [set icon [contact::company::icon $device_vendor]] != "" } {
      return $icon
    }
    if { [set icon [ossweb::image_exists $device_type /img/ossmon]] != "" } {
      return $icon
    }
    return /img/ossmon/computer.gif
}

proc ossmon::device::type_add { type_id } {

    if { $type_id != "" && [ossweb::db::value sql:ossmon.device.type.read] == "" } {
      set type_name $type_id
      ossweb::db::exec sql:ossmon.device.type.create
    }
    return $type_id
}

proc ossmon::device::vendor_add { device_vendor } {

    # Already given vednor id
    if { [string is integer -strict $device_vendor] } {
      return $device_vendor
    }
    # Resolve by name
    if { $device_vendor != "" } {
      return [ossweb::db::value sql:ossmon.device.vendor.create]
    }
    return
}

proc ossmon::device::model_add { device_type device_vendor device_model } {

    set model_id ""
    if { $device_model != "" } {
      ossweb::db::foreach sql:ossmon.device.vendor.model.list {}
      if { $model_id == "" && $device_vendor != "" && $device_model != "" } {
        ossweb::db::exec sql:ossmon.device.vendor.model.create
        set model_id [ossweb::db::currval ossmon_model]
      }
    }
    return $model_id
}

# Returns supported report types
proc ossmon::report::types { { type "" } } {

    # Collect all reports from the objects
    foreach obj [namespace children ::ossmon::object] {
      if { [info exists ${obj}::reports] } {
        foreach r [set ${obj}::reports] {
          lappend types $r
        }
      }
    }
    set types [lsort -index 0 $types]
    if { $type != "" } {
      foreach item $types {
        if { [lindex $item 1] == $type } { return [lindex $item 0] }
      }
      return
    }
    return $types
}

# Static weekly reports about network performance
proc ossmon::report::schedule::weekly { args } {

    ns_parseargs { {-end_date ""} {-skip ""} {-debug f} } $args

    # Which reports should be run on weekly basis
    set report_types { ip_node_failure ip_node_avail ip_trunk_util }

    # Path to the report directory, create if does not exist
    set report_path [ossweb::config ossmon:path:report:pages /[ossweb::conn project_name]/ossmon/reports/Pages]
    if { ![file exists [ns_info pageroot]$report_path] } {
      file mkdir [ns_info pageroot]$report_path
    }

    # Date range for the report
    set end_date [ossweb::nvl $end_date [ossweb::date now]]
    set start_date [ossweb::date -set "" clock [expr [ossweb::date clock $end_date]-86400*7]]
    set dates [ossweb::date pretty_date $start_date]-[ossweb::date pretty_date $end_date]

    # Folder under which we put our report
    set category_id Weekly$dates
    set category_name "Weekly Report $dates"
    set category_parent 0Weekly

    # Generate report output for the specified dates
    set report_type $category_id
    set report_name "Network Performance $dates"
    set report_file $report_path/NetworkPerformance[string map { / - } $dates].html
    set xql_id [ossweb::conn::hostname]$report_file
    set html_file [ossmon::report::generate \
                        -types $report_types \
                        -start_date $start_date \
                        -end_date $end_date \
                        -master index/index.title \
                        -skip $skip \
                        -width 600 \
                        -debug $debug \
                        -title $report_name]
    ossweb::write_file [ns_info pageroot]/$report_file $html_file

    # Create new report category if doesn't exist
    if { [ossweb::db::value sql:ossmon.report.category.read] == "" } {
      ossweb::db::exec sql:ossmon.report.category.create
    }

    # Create new report record if doesn't exist
    if { [ossweb::db::value sql:ossmon.report.read] == "" } {
      ossweb::db::exec sql:ossmon.report.create
    }

    # Keep only 4 last weeks, delete old categories from Weekly parent
    ossweb::db::exec sql:ossmon.report.category.delete.old
}

# Wrapper around all report procedures
proc ossmon::report { type args } {

    if { [info proc ::ossmon::report::$type] != "" } {
      set proc ::ossmon::report::$type
    } else {
      set proc ossmon::report::run
    }
    uplevel "$proc -type $type $args"
}

proc ossmon::report::run { args } {

    ns_parseargs { {-type ""}
                   {-eval ""}
                   {-start_date ""}
                   {-end_date ""}
                   {-hourly ""}
                   {-daily ""}
                   {-weekly ""}
                   {-monthly ""}
                   {-obj_id ""}
                   {-device_id ""}
                   {-chart ""}
                   {-skip ""}
                   {-debug f}
                   {-level {=$expr [info level] - 1}} } $args

    if { $type != "" } {
      ossweb::db::multirow report sql:$type -eval $eval -debug $debug -maxrows 9999 -level [expr [info level]-1]
    }
}

# Generates report(s) and returns report output as HTML text
proc ossmon::report::generate { args } {

    ns_parseargs { {-level {=$expr [info level] - 1}}
                    {-start_date ""}
                    {-end_date ""}
                    {-hourly ""}
                    {-daily ""}
                    {-weekly ""}
                    {-monthly ""}
                    {-debug f}
                    {-width 100%}
                    {-nodata "No data available"}
                    {-th.params "ALIGN=LEFT"}
                    {-header 1}
                    {-border1 0}
                    {-border2 0}
                    {-color1 ""}
                    {-color2 ""}
                    {-cellspacing 1}
                    {-cellpadding 2}
                    {-norow 1}
                    {-underline 1}
                    {-obj_id ""}
                    {-device_id ""}
                    {-chart 1}
                    {-master ""}
                    {-evals ""}
                    {-types ""}
                    {-title ""}
                    {-preface ""}
                    {-skip ""}
                    {-templates ""} } $args

    ossweb::conn -append html:head "<BASE HREF=[ossweb::conn::hostname]>"
    # Default output options
    set defaults {
       report:start {[ossweb::date pretty_date $start_date]}
       report:end {[ossweb::date pretty_date $end_date]}
       report:eval ""
       report:text ""
       report:data ""
       report:columns ""
       report:norow $norow
       report:rowcount 0
       report:border1 $border1
       report:border2 $border2
       report:cellspacing $cellspacing
       report:cellpadding $cellpadding
       report:color1 $color1
       report:color2 $color2
       report:width $width
       report:header $header
       report:nodata $nodata
       report:underline $underline
       report:options(th.params) ${th.params}
       report:title {[ossmon::report::types $type]}
       report:template {
            <P>
            <SPAN CLASS=osswebTitle><P>@report:title@ for @report:start@ - @report:end@</SPAN>
            <BR>
            <if @report:rowcount@ le 0 and @report:data@ eq "">
              <B>@report:nodata@</B>
              <return>
            </if>
            @report:text@
            <if @report:rowcount@ gt 0>
              <border border1=@report:border1@
                      border2=@report:border2@
                      width=@report:width@
                      cellspacing=@report:cellspacing@
                      cellpadding=@report:cellpadding@
                      color1=@report:color1@
                      color2=@report:color2@>
              <multirow name=report header=@report:header@ norow=@report:norow@ underline=@report:underline@></multirow>
              </border>
            </if>
            @report:data@}
    }
    set result ""
    # Use project's directory as current template directory
    ossweb::adp::File [ossweb::config server:path:root [ns_info pageroot]]/[ossweb::conn project_name]/index
    for { set i 0 } { $i < [llength $types] } { incr i } {
      set type [lindex $types $i]
      # Initialize output parameters
      foreach { name value } $defaults {
        set $name [subst $value]
      }
      if { [lindex $templates $i] != "" } { set report:template [lindex $templates $i] }
      if { [lindex $evals $i] != "" } { set report:eval [lindex $evals $i] }
      ossmon::report $type \
          -start_date $start_date \
          -end_date $end_date \
          -hourly $hourly \
          -daily $daily \
          -weekly $weekly \
          -monthly $monthly \
          -chart $chart \
          -skip $skip \
          -obj_id $obj_id \
          -device_id $device_id \
          -debug $debug
      # Insert global title and master
      if { $i == 0 } {
        if { $title != "" } {
          ossweb::conn -set title $title
          set report:template "<CENTER><H2>$title</H2></CENTER><P>$preface${report:template}"
        }
        if { $master != "" } {
          set report:template "<master src=$master>${report:template}"
        }
      }
      append result [ossweb::adp::Evaluate ${report:template}]
    }
    return $result
}

proc ossmon::report::ip_node_avail  { args } {

    ns_parseargs { {-type ""}
                   {-eval ""}
                   {-start_date ""}
                   {-end_date ""}
                   {-hourly ""}
                   {-daily ""}
                   {-weekly ""}
                   {-monthly ""}
                   {-obj_id ""}
                   {-device_id ""}
                   {-chart ""}
                   {-debug f}
                   {-skip ""}
                   {-interval {=$ossweb::config ossmon:report:failure:interval 0}}
                   {-level {=$expr [info level] - 1}} } $args

    set periodmin 0
    set periodmax 0
    ossweb::multirow -level $level create report Device Availability
    set period [expr [ossweb::date clock $end_date]-[ossweb::date clock $start_date]]

    ossweb::db::foreach sql:ossmon.device.list { set total($_device_name) 0 } -prefix _
    ossweb::db::multirow data sql:ossmon.report.ip.node.failure -debug $debug -eval {
       set device $row(Device)
       if { $skip != "" && [regexp $skip $device] } { continue }
       switch -- $row(_log_status) {
        OK -
        Closed {
          # Mark end of failure
          if { [set time1 [ossweb::coalesce start($device)]] != "" } {
            set time1 [lindex $time1 0]
            incr total($device) [expr $row(timestamp) - $time1]
            unset start($device)
          }
          set periodmax $row(timestamp)
        }
        default {
          # Mark start of failure
          if { [set time1 [ossweb::coalesce start($device)]] == "" } {
            set start($device) "$row(timestamp) $row(_alert_timestamp)"
          }
          if { $periodmin == 0 } { set periodmin $row(timestamp) }
        }
       }
    }
    # Add still in progress failures
    foreach { device time1 } [array get start] {
      set time2 [ossweb::nvl [lindex $time1 1] [ns_time]]
      set time1 [lindex $time1 0]
      incr total($device) [expr $time2 - $time1]
    }
    if { $period == 0 } { set period [expr $periodmax - $periodmix] }
    foreach device [lsort [array names total]] {
      set ttotal $total($device)
      ossweb::multirow -level $level append report $device [expr 100-(($ttotal*100)/$period)]%
    }
    return
}

proc ossmon::report::ip_node_failure { args } {

    ns_parseargs { {-type ""}
                   {-eval ""}
                   {-start_date ""}
                   {-end_date ""}
                   {-hourly ""}
                   {-daily ""}
                   {-weekly ""}
                   {-monthly ""}
                   {-obj_id ""}
                   {-device_id ""}
                   {-chart ""}
                   {-debug f}
                   {-skip ""}
                   {-interval {=$ossweb::config ossmon:report:failure:interval 0}}
                   {-level {=$expr [info level] - 1}} } $args

    uplevel { set report:nodata None }
    ossweb::multirow -level $level create report Device "Time Failed" "Failure Period"

    ossweb::db::multirow data sql:ossmon.report.ip.node.failure -debug $debug -eval {
       set device $row(Device)
       if { $skip != "" && [regexp $skip $device] } { continue }
       switch -- $row(_log_status) {
        OK -
        Closed {
         # Mark end of failure
         if { [set time1 [ossweb::coalesce start($device)]] != "" } {
           set time1 [lindex $time1 0]
           lappend total($device) $time1 $row(timestamp)
           unset start($device)
         }
        }
        default {
         # Mark start of failure
         if { ![info exists start($device)] } {
           set start($device) "$row(timestamp) $row(_alert_timestamp)"
         }
        }
       }
    }
    # Add still in progress failures
    foreach { device time1 } [array get start] {
      set time2 [ossweb::nvl [lindex $time1 1] [ns_time]]
      set time1 [lindex $time1 0]
      append total($device) "$time1 [expr $time2-$time1]"
    }
    foreach device [lsort [array names total]] {
      set period $total($device)
      set ttime 0
      foreach { time1 time2 } $period {
         set time2 [expr $time2 - $time1]
         set ttime [expr $time2 + $ttime]
         ossweb::multirow -level $level append report \
              $device \
              [ns_fmttime $time1 "%Y-%m-%d %H:%M:%S"] \
              [ossweb::date uptime $time2]
      }
      ossweb::multirow -level $level append report \
           "" "<B>TOTAL</B>" "<B>[ossweb::date uptime $ttime]</B>"
    }
    return
}

proc ossmon::report::nat_lifetime { args } {

    ns_parseargs { {-type ""}
                   {-eval ""}
                   {-start_date ""}
                   {-end_date ""}
                   {-hourly ""}
                   {-daily ""}
                   {-weekly ""}
                   {-monthly ""}
                   {-obj_id ""}
                   {-device_id ""}
                   {-chart ""}
                   {-debug f}
                   {-skip ""}
                   {-interval {=$ossweb::config ossmon:report:failure:interval 0}}
                   {-level {=$expr [info level] - 1}} } $args

    ossweb::multirow -level $level create report Lifetime(mins) Start Private Public1 End Public2 Flows

    ossweb::db::foreach sql:ossmon.report.nat.lifetime {
      if { ![info exists nat($private_ip)] } {
        set nat($private_ip) $timestamp
        set natip($private_ip) $public_ip
      }
      if { $natip($private_ip) != $public_ip } {
        if { [set secs [expr $timestamp - $nat($private_ip)]] < 1800 } {
          ossweb::multirow -level $level append report \
               [expr $secs/60] \
               [ns_fmttime $nat($private_ip) "%Y-%m-%d %H:%M:%S"] \
               $private_ip \
               $natip($private_ip) \
               [ns_fmttime $timestamp "%Y-%m-%d %H:%M:%S"] \
               $public_ip \
               $flows
        }
        set nat($private_ip) $timestamp
        set natip($private_ip) $public_ip
      }
    }
}

# Access to object's properties, for non-existed properties
# it tries to retrieve the same property from global config
proc ossmon::object { name args } {

    upvar #[ossmon::level] $name object

    set command [lindex $args 0]
    switch -exact -- $command {

     -exec {
       # Executes Tcl code for a given obj which can be table,group or var.
       # For table and array obj, code will be executed for each row with
       # all row's columns being available as array elements.
       # For group and var Tcl code will be executed only once.
       set result ""
       set initscript [lindex $args 1]
       set rowscript [lindex $args 2]
       set finalscript [lindex $args 3]
       # Start processing
       if { $initscript != "" } {
         eval $initscript
       }
       switch [ossmon::object $name -info:format] {
        array -
        table {
           set obj_type [ossmon::object $name obj:type]
           set rowcount [ossmon::object $name obj:rowcount]
           # Call hanlders even if we do not have any rows
           if { $rowcount == 0 } {
             if { $rowscript != "" } {
               eval $rowscript
             }
           } else {
             set columns [ossmon::object $name ossmon:columns]
             # Otherwise call handler(s) for each row
             for { set i 1 } { $i <= $rowcount } { incr i } {
               set row [ossmon::object $name obj:$i]
               ossmon::object $name -log 5 ossmon::object::eval: ROW $i: $row
               ossmon::object $name -set obj:rownum $i
               switch [ossmon::object $name -info:format] {
                array {
                  ossmon::object $name -unset "^$obj_type:"
                  foreach { key value } $row {
                    ossmon::object $name -set $obj_type:$key $value
                  }
                }
                default {
                  for { set j 0 } { $j < [llength $columns] } { incr j } {
                    ossmon::object $name -set [lindex $columns $j] [lindex $row $j]
                  }
                }
               }
               if { $rowscript != "" } {
                 eval $rowscript
               }
               # Stop in case of fatal errors
               switch [ossmon::object $name ossmon:type] {
                error -
                noConnectivity -
                noResponse {
                   break
                }
               }
             }
           }
        }

        default {
           if { $rowscript != "" } {
             eval $rowscript
           }
        }
       }
       # Final status update/final status handlers
       if { $finalscript != "" } {
         eval $finalscript
       }
       return $result
     }

     -gmatch {
       # Returns 1 if matched values from all rows
       if { [set gname [string trimleft [lindex $args 1] "-"]] == "" } {
         return
       }
       ossmon::object $name -set gmatch:name $gname]
       ossmon::object $name -set gmatch:value [lindex $args 2]
       return [ossmon::object $name -exec {
         set result 0
         set gname [ossmon::object $name gmatch:name]
         set gvalue [ossmon::object $name gmatch:value]
       } {
         set value [ossmon::object $name $gname]
         if { [string match -nocase $gvalue $value] } {
           set result 1
         }
       }]
     }

     -gregexp {
       # Returns 1 if matched values from all rows
       if { [set gname [string trimleft [lindex $args 1] "-"]] == "" } {
         return
       }
       ossmon::object $name -set gmatch:name $gname
       ossmon::object $name -set gmatch:value [lindex $args 2]
       return [ossmon::object $name -exec {
         set result 0
         set gname [ossmon::object $name gmatch:name]
         set gvalue [ossmon::object $name gmatch:value]
       } {
         set value [ossmon::object $name $gname]
         if { [regexp -nocase -- $gvalue $value] } { set result 1 }
       }]
     }

     -find {
       set param [lindex $args 0]
       set value [lindex $args 1]
       foreach name [uplevel #[ossmon::level] { info vars ossmon:* }] {
         if { [regexp $value [ossmon::object $name $param]] } {
           return $name
         }
       }
     }

     -alert:update {
       # Update alert to keep it active
       set alert_status Active
       set alert_name [lindex $args 2]
       set device_id [ossmon::object $name device:id]
       foreach alert_id [ossweb::db::list sql:ossmon.alert.search1] {
         set alert_status [ossweb::nvl [lindex $args 1] Active]
         ossweb::db::exec sql:ossmon.alert.update.status
         ossmon::object $name -log 0 Notice ossmon::object: Keepalive alert $alert_id
       }
     }

     -alert:close {
       # Close active alerts
       set alert_status Active
       set alert_name [lindex $args 2]
       set device_id [ossmon::object $name device:id]
       foreach alert_id [ossweb::db::list sql:ossmon.alert.search1] {
         set alert_status [ossweb::nvl [lindex $args 1] Pending]
         ossweb::db::exec sql:ossmon.alert.update.status
         ossmon::object $name -log 0 Notice ossmon::object: Closing alerts $alert_id
       }
     }

     -poll {
       # Initialize only once
       if { [ossmon::object $name poll:init] == "" && [ossmon::object $name -init] < 0 } {
         return -1
       }
       # Polling the device
       set rc [ossmon::object::call_proc $name poll -default 0]
       # Optional on finish callback
       ossmon::object::call_proc $name finish
       # Mark object's poll time
       ossmon::object $name -set poll:time [ns_time]
       return $rc
     }

     -init {
       if { [ossmon::object::call_proc $name init -default 0] < 0 } {
         return -1
       }
       # Find first SNMP object for this device and use it
       ns_parseargs { {-snmp f} -- args } [lrange $args 1 end]

       if { $snmp == "t" && [ossmon::object $name snmp:fd] == "" } {
         set device_id [ossmon::object $name device:id]
         foreach id [ossweb::db::list sql:ossmon.device.list.objects -colname obj_id] {
           ossmon::object _obj -create obj:id $id
           if { [ossmon::object _obj -init] != -1 && [ossmon::object _obj snmp:fd] != "" } {
             ossmon::object $name -set snmp:fd [ossmon::object _obj snmp:fd]
             ossmon::object _obj -destroy
             break
           }
         }
       }
       set object(poll:init) 1
       return 0
     }

     -feature {
       # Returns 1 if this object supports given feature
       set features [ossmon::object $name -info:features]
       foreach key [lrange $args 1 end] {
         if { [lsearch -exact $features $key] > -1 } {
           return 1
         }
       }
       return 0
     }

     -info:format {
       # Returns object's output format
       return [::ossmon::object::get_var $name format]
     }

     -info:charts {
       # Returns object's supported charts
       return [::ossmon::object::get_var $name charts]
     }

     -info:features {
       # Returns object's supported features
       return [::ossmon::object::get_var $name features]
     }

     -info:reports {
       # Returns object's supported reports
       return [::ossmon::object::get_var $name reports]
     }

     -info:name {
       # Returns object's name, i.e. distinctive variable that uniquely
       # identifies the object like ifDescr for interface table row
       return [::ossmon::object::call_proc $name name]
     }

     -info:devices {
       # Returns parent devices up to the top
       set devices [list]
       foreach dev [split [ossmon::object $name device:path] /] {
         set dev [string trim $dev 0]
         if { $dev != "" } {
           set devices [linsert $devices 0 $dev]
         }
       }
       return $devices
     }

     -info:noconnectivity {
       # Returns 1 if there is any noConnectivity alert active in any of the parent devices
       foreach dev [ossmon::object $name -info:devices] {
         if { [ossweb::cache::exists ossmon:alert $dev:noConnectivity] } {
           return 1;
         }
       }
       return 0;
     }

     -info:object -
     -object:info {
       append result "Object: [ossmon::object $name obj:name]/[ossmon::object $name obj:type]\n"
       append result "Device: [ossmon::object $name device:name], [ossmon::object $name location:name]\n"
       append result "Alert Time: [ns_fmttime [ossmon::object $name alert:time -default [ns_time]]]\n"
       set url [ossweb::config ossmon:url [ossweb::html::url -app_name ossmon -host t objects cmd edit]]
       append result "Link: $url&obj_id=[ossmon::object $name obj:id]\n"
       return $result
     }

     -attrcheck {
       # Check for attributes on monitor create/update
       return [::ossmon::object::call_proc $name attrcheck]
     }

     -fix {
       # Fix failed process
       return [::ossmon::object::call_proc $name fix]
     }

     -exists {
       return [array exists object]
     }

     -create {
       if { [info exists object] } {
         unset object
       }
       array set object [list obj:rowcount 0 \
                              obj:rownum 0 \
                              obj:level 0 \
                              obj:type var \
                              obj:alertnum 0 \
                              ossmon:columns "" \
                              ossmon:status "" \
                              ossmon:type poll \
                              ossmon:timestamp 0 \
                              device:id "" \
                              time:now [ns_time]]

       foreach { key value } [lrange $args 1 end] {
         set object($key) $value
       }
       if { $object(ossmon:timestamp) <= 0 } {
         set object(ossmon:timestamp) [ossmon::property session:timestamp]
       }
       # Read object record
       if { [set obj_id [ossweb::coalesce object(obj:id)]] != "" &&
            ![ossweb::db::multivalue sql:ossmon.object.read] } {
         set object(obj:name) $obj_name
         set object(obj:host) [string trim $obj_host]
         set object(obj:type) $obj_type
         set object(obj:level) [expr [llength [split $device_path /]]-2]
         set object(obj:charts) $charts_flag
         set object(parent:id) $obj_parent
         set object(parent:name) $obj_parent_name
         set object(type:name) [ossmon::object::get_title $obj_type]
         set object(time:now) $now
         set object(time:poll) $poll_secs
         set object(time:alert) $alert_secs
         set object(time:update) $update_secs
         set object(info:alert:id) $alert_id
         set object(info:alert:data) $alert_data
         set object(info:alert:name) $alert_name
         set object(info:alert:count) $alert_count
         set object(info:alert:time) $alert_time
         set object(device:id) $device_id
         set object(device:path) $device_path
         set object(device:name) $device_name
         set object(device:type) $device_type
         set object(device:vendor) $device_vendor_name
         set object(device:description) $device_descr
         set object(location:name) $location_name
         foreach { key value } $device_properties { set object($key) $value }
         foreach { key value } $obj_properties { set object($key) $value }
       } else {
         if { [set device_id [ossweb::coalesce object(device:id)]] != "" &&
              ![ossweb::db::multivalue sql:ossmon.device.read] } {
           set object(obj:name) $device_name
           set object(obj:host) [string trim $device_host]
           set object(obj:type) root
           set object(obj:level) [expr [llength [split $device_path /]]-2]
           set object(time:now) $now
           set object(device:id) $device_id
           set object(device:path) $device_path
           set object(device:name) $device_name
           set object(device:type) $device_type
           set object(device:vendor) $device_vendor_name
           set object(device:description) $description
           set object(location:name) $location_name
           foreach { key value } $device_properties { set object($key) $value }
         }
       }
       # Initialize object subsystem
       ::ossmon::object $name -setup
     }

     -setup {
       # Setup object definition variables
       foreach var { superclass format columns charts hierarchy } {
         set object(ossmon:$var) ""
         if { [info exists ::ossmon::object::$object(obj:type)::$var] } {
           set object(ossmon:$var) [set ::ossmon::object::$object(obj:type)::$var]
         }
       }
       # Call object specific constructor
       ::ossmon::object::call_proc $name create
     }

     -open {
       # Protocol initialization, open socket and etc
       ns_parseargs { {-host ""} {-port ""} {-timeout 30} {-exec ""} -- args } [lrange $args 1 end]

       # Socket-based protocol
       if { $host != "" && $port != "" } {
         set fd [ossmon::util::open $host $port -timeout $timeout]
         set object(socket:fd) $fd
         return $fd
       }
       # Command shell execution
       if { $exec != "" } {
         set fd [::open $exec]
         set object(socket:fd) $fd
         return $fd
       }
       # Protocol specific open handler
       return [::ossmon::object::call_proc $name open -params $args]
     }

     -close {
       # Destroys object session, closes all open sockets
       if { [info exists object(socket:fd)] } {
         catch { ::close $object(socket:fd) }
         unset object(socket:fd)
       }
       # Protocol specific close handler
       return [::ossmon::object::call_proc $name close -default 0]
     }

     -destroy {
       catch { unset object }
     }

     -shutdown {
       # Clear polling flag so next thread can start polling this monitor
       ossweb::cache::flush ossmon:poll $name
       # Close the object session
       ossmon::object $name -close
       # Destroy the object, cleanup memory
       catch { unset object }
     }

     -array {
       return [array get object]
     }

     -dump -
     -dumpall {
       ns_parseargs { {-skip ""} {-include ""} {-sep "\n"} } [lrange $args 1 end]

       set result ""
       foreach name [lsort [array names object]] {
         if { ($skip != "" && [regexp $skip $name]) ||
              ($include != "" && ![regexp $include $name]) ||
              [ossmon::util::sensitive $name] ||
              ($command == "-dump" && [regexp {^queue:} $name]) } {
           continue
         }
         append result $name = $object($name) $sep
       }
       return $result
     }

     -reset {
       set object(ossmon:columns) ""
       set object(obj:rowcount) 0
       set object(ossmon:status) ""
       set object(ossmon:trace) ""
     }

     -set {
       set value ""
       foreach { key value } [lrange $args 1 end] {
         set object($key) $value
       }
       return $value
     }

     -set:property {
       set value ""
       foreach { key value } [lrange $args 1 end] {
         ossmon::object::set_property $name $key $value
       }
       return $value
     }

     -save {
       set value ""
       set obj_id [ossmon::object $name obj:id]
       foreach { property_id value } [lrange $args 1 end] {
         set object($property_id) $value
         if { $obj_id == "" } {
           continue
         }
         if { $value == "" } {
           ossweb::db::exec sql:ossmon.object.property.delete
         } else {
           ossweb::db::exec sql:ossmon.object.property.update
           if { [ossweb::db::rowcount] == 0 } {
             ossweb::db::exec sql:ossmon.object.property.create
           }
         }
       }
       return $value
     }

     -key {
       return ossmon:$object(obj:type):$object(device:id)
     }

     -unset {
       if { [set filter [lindex $args 1]] == "" } {
         return
       }
       foreach key [array names object] {
         if { [regexp -nocase $filter $key] } {
           unset object($key)
         }
       }
     }

     -match {
       set result ""
       if { [set filter [lindex $args 1]] == "" } {
         return
       }
       foreach key [array names object] {
         if { [regexp $filter $key] } {
           lappend result $key $object($key)
         }
       }
       return $result
     }

     -update {
       foreach { key value } [lrange $args 1 end] {
         if { $value != "" } {
           set object($key) $value
         }
       }
     }

     -append {
       if { [set key [lindex $args 1]] == "" } {
         return
       }
       if { ![info exists object($key)] } {
         set object($key) ""
       }
       foreach value [lrange $args 2 end] {
         append object($key) $value
       }
     }

     -lappend {
       if { [set key [lindex $args 1]] == "" } {
         return
       }
       if { ![info exists object($key)] } {
         set object($key) ""
       }
       foreach value [lrange $args 2 end] {
         lappend object($key) $value
       }
     }

     -incr {
       set key [lindex $args 1]
       if { ![info exists object($key)] } {
         set object($key) 0
       }
       if { [string is integer -strict $object($key)] } {
         return [eval incr object($key) [lindex $args 2]]
       }
     }

     -subject {
       if { [set subject [ossmon::object $name ossmon:alert:subject]] != "" } {
         return $subject
       }
       return "[ossmon::property product:name]: [ossmon::object $name obj:host]: [ossmon::object $name device:name]"
     }

     -name {
       return "[ossmon::object $name obj:name]([ossmon::object $name obj:host]/[ossmon::object $name obj:type]/[ossmon::object $name -info:name])"
     }

     -device {
       return "[ossmon::object $name device:name]([ossmon::object $name device:type]/[ossmon::object $name location:name])"
     }

     -title {
       return "[ossmon::object $name -name]: [ossmon::object $name -device]"
     }

     -log {
       # ossmon::object $name -log Level Prefix Data
       set level [lindex $args 1]
       set prefix [lindex $args 2]
       if { $level == "Error" || $level <= [ossmon::object $name ossmon:debug -config "" -default 0] } {
         ns_log Notice $prefix{[ossmon::object $name ossmon:timestamp]} $name, [ossmon::object $name -title]: [join [lrange $args 3 end]]
       }
     }

     -eval {
       if { [set script [ossmon::object $name ossmon:eval -config]] != "" } {
         if { [catch { eval $script } errmsg] } {
           ossmon::object $name -log Error ossmon:eval: $errmsg
         }
       }
     }
     default {
       set suffix ""
       set time_flag ""
       # Constant name, return as is
       if { [string index $command 0] == "'" && [string index $command end] == "'" } {
         return [string range $command 1 end-1]
       }
       set value [ossweb::coalesce object($command)]
       foreach { key val } [lrange $args 1 end] {
         switch -- $key {
          -config {
             if { $value == "" } {
               set value [::ossweb::config $command $val]
             }
          }
          -default {
             if { $value == "" } { set value $val }
          }
          -double {
             append value .0
          }
          -quote {
             set value [ossweb::sql::quote $value]
          }
          -time {
             if { [string is integer -strict $value] } {
               set value [ns_fmttime $value $val]
             }
          }
        }
       }
       switch -- $command {
        obj:type {
          if { $value == "" } {
            set value unknown
          }
        }
       }
       return $value
     }
    }
    return
}

# Call object's method, search through object hierarchy
proc ossmon::object::call_proc { name proc args } {

    ns_parseargs { {-default ""} -type {-params ""} } $args

    if { ![info exists type] } {
      set type [ossmon::object $name obj:type]
    }
    if { [info proc ::ossmon::object::${type}::$proc] != "" } {
      return [eval ::ossmon::object::${type}::$proc $name $params]
    }
    if { [info exists ::ossmon::object::${type}::superclass] } {
      return [ossmon::object::call_proc $name $proc -type [set ::ossmon::object::${type}::superclass] -default $default -params $params]
    }
    return $default
}

# Perform network connectivity testing using ICMP pings
proc ossmon::object::call_ping { name args } {

    ns_parseargs { {-host ""} {-count ""} {-timeout ""} {-size ""} {-exec f} } $args

    # Ping configuration
    if { $count == "" } {
      set count [ossmon::object $name ossmon:ping:count -config 5]
    }
    if { $timeout == "" } {
      set timeout [ossmon::object $name ossmon:ping:timeout -config 5]
    }
    if { $size == "" } {
      set size [ossmon::object $name ossmon:ping:size -config 56]
    }
    if { $host == "" } {
      set host [ossmon::object $name obj:host]
    }
    set result ""

    if { $exec == "f" && [info command ns_icmp] != "" && [ns_icmp sockets] > 0 } {
      set result [ns_ping -size $size -count $count -timeout $timeout $host]
    } else {
      foreach v { sent received loss min avg max } { set $v 0 }
      catch { exec /bin/ping -q -s $size -c $count -w $timeout $host } data
      if { ![regexp {([0-9]+) packets transmitted, ([0-9]+) received,} $data d sent received] } {
        error "Runtime error, /bin/ping produced no results"
      }
      if { $sent > 0 && $received == 0 } {
        error noConectivity
      }
      regexp {rtt min/avg/max/mdev = ([0-9.]+)/([0-9.]+)/([0-9.]+)/} $data d min avg max
      set loss [expr $received > 0 ? 100 - (($received * 100) / $sent) : $sent == 0 ? 0 : 100]
      set result [list $sent $received $loss $min $avg $max]
    }
    return $result
}

# Returns list of all supported object types suitable for use in select boxes
proc ossmon::object::get_types {} {

    variable types
    set options ""
    foreach type [namespace children ::ossmon::object] {
      lappend options [list [set ${type}::title] [namespace tail $type]]
    }
    return [lsort -index 0 $options]
}

# Return object type title by type
proc ossmon::object::get_title { type } {

    if { [info exists ::ossmon::object::${type}::title] } {
      return [set ::ossmon::object::${type}::title]
    }
    return $type
}

# Return object's variable, search through object hierarchy
proc ossmon::object::get_var { name var args } {

    ns_parseargs { {-default ""} -type } $args

    if { ![info exists type] } {
      set type [ossmon::object $name obj:type]
    }
    if { [info exists ::ossmon::object::${type}::$var] } {
      return [set ::ossmon::object::${type}::$var]
    }
    if { [info exists ::ossmon::object::${type}::superclass] } {
      return [ossmon::object::get_var $name $var -type [set ::ossmon::object::${type}::superclass] -default $default]
    }
    return $default
}


# Returns local object's cache
proc ossmon::object::get_cache { name script } {

    set key [ossmon::object $name -key]
    return [uplevel "ossweb::cache::run ossmon:cache $key {$script}"]
}

# Flushes cahes
proc ossmon::object::flush_cache { name args } {

    set key [ossmon::object $name -key]
    ossweb::cache::flush ossmon:cache $key
    ossweb::cache::flush ossmon:cache $key:timestamp
}

# Return object property definitions
proc ossmon::object::get_property { name property args } {

    ns_parseargs { {-default ""} {-column ""} {-all f} {-global f} {-base f} } $args

    set hierarchy [ossmon::object $name ossmon:hierarchy]

    # By default search object specific namespaces only, -base t will enable searching in
    # ::ossmon::object namespace and -global t will enable ::ossmon as well
    if { $base == "f" } {
      set hierarchy [lrange $hierarchy 0 end-1]
    }
    if { $global == "t" } {
      lappend hierarchy ::ossmon
    }

    # Look for matching property
    set values ""
    foreach type $hierarchy {
      set value [ossmon::property $property -type $type -default $default -column $column]
      if { $value != "" } {
        # Return list with all values
        if { $all == "t" } {
          foreach value $value {
            lappend values $value
          }
          continue
        }
        return $value
      }
    }
    if { $values != "" } {
      return $values
    }
    return $default
}

# Save object propetty in the database
proc ossmon::object::set_property { name property_id value } {

    ossmon::object $name -set $property_id $value
    set obj_id [ossmon::object $name obj:id]

    if { $obj_id != "" } {
      ossweb::db::exec sql:ossmon.object.property.update
      if { ![ossweb::db::rowcount] } {
        ossweb::db::exec sql:ossmon.object.property.create
      }
    }
    return $value
}

# Generates HTML code for specified object
proc ossmon::object::get_html { name args } {

    ns_parseargs { {-url ""}
                   {-html ""}
                   {-format {-info:format}}
                   {-columns ossmon:columns}
                   {-prefix obj}
                   {-border 1} } $args

    array set urlMap $url
    array set htmlMap $html

    set result "<TABLE BORDER=$border CELLSPACING=0 CELLPADDING=3>"

    set columns [ossmon::object $name $columns]

    switch [ossmon::object $name $format] {
     array {
        append result "<TR CLASS=osswebFirstRow>"
        foreach var $columns { append result "<TH>$var</TH>" }
        append result "</TR>"
        # Otherwise call handler(s) for each row
        for { set i 1 } { $i <= [ossmon::object $name $prefix:rowcount] } { incr i } {
          set row [ossmon::object $name $prefix:$i]
          append result "<TR>"
          foreach { colname value } $row {
            set value [ossweb::nvl [ns_quotehtml $value] "&nbsp;"]
            if { [info exists urlMap($colname)] } {
              set value [ossweb::html::link -text $value \
                              -html [ossweb::coalesce htmlMap($colname)] \
                              -url "$urlMap($colname)&index=$i&$colname=[ns_urlencode $value]"]
            }
            append result "<TD>$colname: $value</TD>"
          }
          append result "</TR>"
        }
     }
     table {
        append result "<TR CLASS=osswebFirstRow>"
        foreach var $columns { append result "<TH>$var</TH>" }
        append result "</TR>"
        # Otherwise call handler(s) for each row
        for { set i 1 } { $i <= [ossmon::object $name $prefix:rowcount] } { incr i } {
          set row [ossmon::object $name $prefix:$i]
          append result "<TR>"
          for { set j 0 } { $j < [llength $columns] } { incr j } {
            set value [ossweb::nvl [ns_quotehtml [lindex $row $j]] "&nbsp;"]
            set colname [lindex $columns $j]
            if { [info exists urlMap($colname)] } {
              set value [ossweb::html::link -text $value \
                              -html [ossweb::coalesce htmlMap($colname)] \
                              -url "$urlMap($colname)&index=$i&$colname=[ns_urlencode $value]"]
            }
            append result "<TD>$value</TD>"
          }
          append result "</TR>"
        }
     }

     default {
        foreach var $columns {
          set value [ns_quotehtml [ossmon::object $name $var]]
          if { [info exists urlMap($var)] } {
            set value [ossweb::html::link -text $value \
                            -html [ossweb::coalesce htmlMap($var)] \
                            -url "$urlMap($var)&$var=[ns_urlencode $value]"]
          }
          append result "<TR><TD>$var</TD><TD>$value</TD></TR>"
        }
     }
    }
    append result "</TABLE>"
    return $result
}

# Common SNMP MIB labels
proc ossmon::object::get_mibs { type } {

    return "<A HREF=javascript:; CLASS=osswebLink TITLE=\"List of MIBs\" onClick=\"window.open('[ossweb::html::url objects cmd mibs obj_type $type]','MIBS','menuvar=0,location=0,width=500,height=600,scrollbars=1')\">Mibs</A>"
}

# Returns icon for the device or object
proc ossmon::object::get_icon { obj_type { device_vendor "" } { device_type "" } } {

    if { [set icon [ossweb::image_exists $obj_type /img/ossmon]] != "" } {
      return $icon
    }
    return [ossmon::device::icon $device_vendor $device_type]
}

# DNS handler
proc ossmon::object::dns::poll { name args } {

    set server [ossmon::object $name obj:host]
    set timeout [ossmon::object $name ossmon:dns:timeout]

    foreach host [ossmon::object $name ossmon:dns:hosts] {
      set result [ns_dns resolve $host -server $server -timeout $timeout]
      set answer [lindex $result 0]
      if { $answer == "" } {
        ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host "" noResponse]
      } else {
        foreach rr $answer {
          set host [lindex $rr 0]
          set type [lindex $rr 1]
          set status [lindex $rr 2]
          ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $type $status]
        }
      }
    }
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::dns::name { name args } {

    return "[ossmon::object $name dnsHost] [ossmon::object $name dnsStatus]"
}

proc ossmon::object::dns::create { name args } {

    variable defaults

    foreach { key value } $defaults {
      ossmon::object $name -set $key $value
    }
    return 0
}

# TCP DNS handler
proc ossmon::object::dnstcp::poll { name args } {

    set hosts [ossmon::object $name ossmon:dns:hosts]

    foreach host $hosts {
      if { [set status [ossmon::object::dnstcp::resolve $name $host]] == "" } { set status OK }
      ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host [lindex [ossmon::object::dnstcp::get $name A] 0] $status]
    }

    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::dnstcp::name { name args } {

    return "[ossmon::object $name dnsHost] [ossmon::object $name dnsStatus]"
}

# Perform DNS query, create DNS object and returns its name
proc ossmon::object::dnstcp::resolve { name host } {

    eval ossmon::object $name -set host $host status {{}} QD {{}} AN {{}} NS {{}} AR {{}}
    switch [ossmon::object $name protocol] {
     tcp { tcpsend $name }
    }
    return [ossmon::object $name status]
}

#  Return a records from the reply
proc ossmon::object::dnstcp::get { name { type A } } {

    switch $type {
     NAME - A - CNAME - PTR - MX { set reply [ossmon::object $name AN] }
     NS { set reply [ossmon::object $name NS] }
     default { return }
    }
    set r {}
    foreach answer $reply {
      array set rec $answer
      switch $type {
       NAME {
         if { $rec(name) != "" } { lappend r $rec(name) }
       }
       default {
         if { $rec(type) == $type } { lappend r $rec(rdata) }
       }
      }
    }
    return $r
}

#  Contruct a DNS query packet.
proc ossmon::object::dnstcp::build { name args } {

    variable id
    variable types
    variable classes

    set req [binary format SSSSSS \
                    [ossmon::object $name -set id [incr id]] \
                    [expr ([ossmon::object $name opcode]<<11)|([ossmon::object $name recursive]<<8)] \
                    1 0 0 0]

    switch [ossmon::object $name type] {
     A {
       foreach part [split [string trim [ossmon::object $name host] .] .] {
         set label [binary format c [string length $part]]
         append req $label $part
       }
       append req [binary format cSS 0 $types(A) $classes(IN)]
     }
    }
    return $req
}

#  Transmit a DNS request over a tcp connection.
proc ossmon::object::dnstcp::tcpsend { name args } {

    # For TCP the message must be prefixed with a 16bit length field.
    set request [build $name]
    set req [binary format S [string length $request]]
    append req $request

    set fd [ossmon::object::open $name -open -host [ossmon::object $name obj:host] -port [ossmon::object $name port] -timeout [ossmon::object $name timeout]]
    fconfigure $fd -blocking 0 -translation binary -buffering none
    if { [lindex [ns_sockselect -timeout [ossmon::object $name timeout] {} $fd {}] 1] == "" } {
      error "noResponse: write timeout"
    }
    ::puts -nonewline $fd $req
    if { [lindex [ns_sockselect -timeout [ossmon::object $name timeout] $fd {} {}] 0] == "" } {
      error "noResponse: read timeout"
    }
    set result [::read $fd]
    ossmon::object $name -close
    # Strip off packet length
    if { [binary scan $result S length] == 1 } {
      ossmon::object $name -set length $length
      decode $name [string range $result 2 end]
    } else {
      ossmon::object $name -set status "Packet length error"
    }
    return
}

#  Decode a DNS packet (either query or response).
proc ossmon::object::dnstcp::decode { name payload } {

    set id ""
    set flags 0
    if { [binary scan $payload SS id flags] != 2 ||
         [expr {$id & 0xFFFF}] != [ossmon::object $name id] } {
      ossmon::object $name -set status "Packet format error: [ossmon::object $name id]:$id, $flags, [ossmon::object $name length]:[string length $payload]"
      return
    }
    set status [expr {$flags & 0x000F}]
    if { $status != 0 } {
      switch -- $status {
       1 { ossmon::object $name -set status "Format error" }
       2 { ossmon::object $name -set status "Server failure" }
       3 { ossmon::object $name -set status "Name Error" }
       4 { ossmon::object $name -set status "Not implemented" }
       5 { ossmon::object $name -set status "Refused" }
       default { ossmon::object $name -set status "unrecognised error code: $err" }
      }
      return
    }
    if { [binary scan $payload SSSSSSc* mid hdr nQD nAN nNS nAR data] != 7 ||
         [catch {
      set ndx 12
      ossmon::object $name -set QD [parse $nQD $payload ndx 1]
      ossmon::object $name -set AN [parse $nAN $payload ndx 0]
      ossmon::object $name -set NS [parse $nNS $payload ndx 0]
      ossmon::object $name -set AR [parse $nAR $payload ndx 0]
    } errmsg] } {
      ossmon::object $name -set status "Parse error: $errmsg"
    }
}

# Parses a record inside DNS message.
proc ossmon::object::dnstcp::parse { count data index_ref query } {

    variable Types
    variable Classes

    upvar $index_ref index
    set result {}

    for { set i 0 } { $i < $count } { incr i } {
      set r {}
      lappend r name [parseName data $index offset]
      incr index $offset
      # Read off TYPE and CLASS, for answer also TTL and RDLENGTH
      switch $query {
       1 {
          binary scan [string range $data $index [expr $index+3]] SS type class
          set type [ossweb::coalesce Types([expr $type & 0xFFFF]) $type]
          set rdlength 0
          set rdata {}
          set ttl 0
          incr index 4
       }
       default {
          binary scan [string range $data $index end] SSIS type class ttl rdlength
          set type [ossweb::coalesce Types([expr $type & 0xFFFF]) $type]
          set ttl [expr $ttl & 0xFFFFFFFF]
          set rdlength [expr $rdlength & 0xFFFF]
          incr index 10
          set rdata [string range $data $index [expr {$index + $rdlength - 1}]]
          switch $type {
           A {
              binary scan $rdata c* d
              set l {}
              foreach c $d { lappend l [expr {$c & 0xFF}] }
              set rdata [join $l "."]
           }
           NS - CNAME - PTR {
              set rdata [parseName data $index offset]
           }
           MX {
              binary scan $rdata S preference
              set exchange [parseName data [expr $index + 2] offset]
              set rdata [list $preference $exchange]
           }
          }
          incr index $rdlength
       }
      }
      set class [ossweb::coalesce Classes($class) $class]
      lappend r type $type class $class ttl $ttl rdlength $rdlength rdata $rdata
      lappend result $r
    }
    return $result
}


# Read off the NAME or QNAME element. This reads off each label in turn,
# dereferencing pointer labels until we have finished. The length of data
# used is passed back using the usedvar variable.
proc ossmon::object::dnstcp::parseName { data_ref index offset_ref } {

    upvar $data_ref data
    upvar $offset_ref offset
    set startindex $index

    set r {}
    set len 1
    set max [string length $data]

    while { $len != 0 && $index < $max } {
      # Read the label length (and preread the pointer offset)
      binary scan [string range $data $index end] cc len lenb
      set len [expr $len & 0xFF]
      incr index
      if { $len != 0 } {
        if { [expr $len & 0xc0] } {
          binary scan [binary format cc [expr $len & 0x3f] [expr $lenb & 0xff]] S offset
          incr index
          lappend r [parseName data $offset junk]
          set len 0
        } else {
          lappend r [string range $data $index [expr $index + $len - 1]]
          incr index $len
        }
      }
    }
    set offset [expr $index - $startindex]
    return [join $r .]
}


# Exec handler
proc ossmon::object::exec::poll { name args } {

    set fd ""
    set filter [ossmon::object $name ossmon:filter:ignore]
    # Retrieve script output
    set data [ossmon::object::get_cache $name {
      set fd [ossmon::object $name -open -exec "|/usr/local/snmp/bin/[ossmon::object $name obj:name]"]
      set data [::read $fd]
      ossmon::object $name -close
      if { [string match -nocase "noResponse*" $data] } { error $data }
      return $data
    }]
    set obj_rowcount 0
    foreach line [split $data "\n"] {
      if { [string trim $line] == "" } { continue }
      if { $filter != "" && [regexp -nocase $filter $line] } { continue }
      ossmon::object $name -set obj:[incr obj_rowcount] [list $line]
    }
    ossmon::object $name -set obj:rowcount $obj_rowcount
    return $obj_rowcount
}

# HTTP handler
proc ossmon::object::http::poll { name args } {

    set host [ossmon::object $name obj:host]
    set port [ossmon::object $name ossmon:http:port -config 80]
    set url [ossmon::object $name ossmon:http:url -default /]
    set timeout [ossmon::object $name ossmon:http:timeout -config 30]
    set status ""

    set start_time [clock clicks -milliseconds]
    # Open async connection and send our request
    set fd [ossmon::object $name -open -host $host -port $port -timeout $timeout]
    ossmon::util::puts $fd "GET $url HTTP/1.0\r\n\r" -timeout $timeout
    # Read the response, we need only first status line
    set status [ossmon::util::gets $fd -timeout $timeout]
    set time [expr [clock clicks -milliseconds]-$start_time]
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $status $time]
    return [ossmon::object $name obj:rowcount]
}

# SMTP handler
proc ossmon::object::smtp::poll { name args } {

    set timeout [ossmon::object $name ossmon:smtp:timeout -config 30]
    set port [ossmon::object $name ossmon:smtp:port -config 25]
    set host [ossmon::object $name obj:host]
    set protocol [list "" 220 \
                   "HELO [ns_info hostname]" 250 \
                   "MAIL FROM: <[ossmon::object $name ossmon:smtp:mail_from -config "ossmon@[ns_info hostname]"]>" 250 \
                   "RCPT TO: <[ossmon::object $name ossmon:smtp:rcpt_to]>" 250]
    set line ""
    set status "OK"
    set fd [ossmon::object $name -open -host $host -port $port -timeout $timeout]

    foreach { msg code } $protocol {
      # Send request data
      if { $msg != "" } { ossmon::util::puts $fd "$msg\r" -timeout $timeout }
      # Read the response, smtp can produce more than one line using '250-' format
      while { 1 } {
        set line [ossmon::util::gets $fd -timeout $timeout]
        if { [string range $line 0 2] != $code } {
          if { $line == "" && ![ns_sockcheck $fd] } {
            if { [catch { set line [fconfigure $fd -peername] }] } {
              set line "noResponse, sent '$msg', expected '$code'"
            }
          }
          set status $line
          break
        }
        if { [string index $line 3] != "-" } { break }
      }
      if { $status != "OK" } { break }
    }
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $status]
    return [ossmon::object $name obj:rowcount]
}

# IMAP handler
proc ossmon::object::imap::poll { name args } {

    set user [ossmon::object $name ossmon:auth:user]
    set password [ossmon::object $name ossmon:auth:password]
    set timeout [ossmon::object $name ossmon:imap:timeout -config 30]
    set port [ossmon::object $name ossmon:imap:port -config 143]
    set host [ossmon::object $name obj:host]
    set fd [ossmon::object $name -open -host $host -port $port -timeout $timeout]
    set protocol [list "" "\\* OK" "a1 LOGIN $user $password" "a1 OK" "a1 LOGOUT" ""]
    set line ""
    set status "OK"

    foreach { msg code } $protocol {
      # Send request data
      if { $msg != "" } { ossmon::util::puts $fd "$msg\r" -timeout $timeout }
      # Read response line
      set line [ossmon::util::gets $fd -timeout $timeout]
      if { $code != "" && ![regexp "^$code" $line] } {
        if { $line == "" && ![ns_sockcheck $fd] } {
          if { [catch { set line [fconfigure $fd -peername] }] } { set line noResponse }
        }
        set status $line
        break
      }
    }
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $status]
    return [ossmon::object $name obj:rowcount]
}

# PO3 handler
proc ossmon::object::pop3::poll { name args } {

    set user [ossmon::object $name ossmon:auth:user]
    set password [ossmon::object $name ossmon:auth:password]
    set timeout [ossmon::object $name ossmon:pop3:timeout -config 30]
    set port [ossmon::object $name ossmon:pop3:port -config 110]
    set host [ossmon::object $name obj:host]
    set protocol [list "" "+OK" "USER $user" "+OK" "PASS $password" "+OK"]
    set line ""
    set status "OK"
    set fd [ossmon::object $name -open -host $host -port $port -timeout $timeout]

    foreach { msg code } $protocol {
      # Send request data
      if { $msg != "" } { ossmon::util::puts $fd "$msg\r" -timeout $timeout }
      # Read response line
      set line [ossmon::util::gets $fd -timeout $timeout]
      if { [string range $line 0 2] != $code } {
        set status $line
        break
      }
    }
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $status]
    return [ossmon::object $name obj:rowcount]
}

# Mailbox handler
proc ossmon::object::mailbox::close { name args } {

    if { [set fd [ossmon::object $name ossmon:mailbox:fd]] != "" } { catch { ns_imap close $fd } }
    ossmon::object $name -unset ossmon:mailbox:fd
}

proc ossmon::object::mailbox::decode { name id msgid { bodyid "" } { bodystruct "" } { file_path "" } } {

    if { $bodystruct != "" } {
      array set struct $bodystruct
    } else {
      if { [catch { ns_imap struct $id $msgid -array struct } errmsg] } {
        ns_log Error "ossmon::object::mailbox::decode: $id: $msgid: $errmsg"
        return
      }
    }
    set body ""
    if { $struct(type) == "multipart" } {
      for { set i 1 } { $i <= $struct(part.count) } { incr i } {
        array unset part
        array set part $struct(part.$i)
        if { $bodyid != "" } { set partid "$bodyid.$i" } else { set partid $i }
        if { $part(type) == "multipart" } {
          append body [ossmon::object::mailbox::decode $name $id $msgid $partid $struct(part.$i) $file_path]
          continue
        }
        if { [info exists part(body.name)] || [info exists part(disposition.filename)] } {
          if { [set filename [ossweb::coalesce part(body.name)]] == "" } {
            set filename $part(disposition.filename)
          }
          # Make filename unique
          if { [file exists $file_path/$filename] } {
            set filename "[ns_fmttime [ns_time] %Y%m%d%H%M]-$msgid.$partid-$filename"
          }
          append body "File: $filename $part(type)/$part(subtype) [ossweb::coalesce part(bytes) 0]bytes\n"
          ossmon::object $name -append mailbox:files $filename
          if { $file_path != "" } {
            ns_imap body $id $msgid $partid -file $file_path/$filename
          }
        } else {
          set pbody [ns_imap body $id $msgid $partid -decode]
          switch $struct(subtype) {
           HTML { append body [ns_imap striphtml $pbody] }
           default { append body [ossweb::util::wrap_text [ns_quotehtml $pbody]] }
          }
        }
      }
    } else {
      if { $bodyid != "" } { set partid "$bodyid.1" } else { set partid 1 }
      set body [ns_imap body $id $msgid $partid -decode]
      switch $struct(subtype) {
       HTML { set body [ns_imap striphtml $body] }
       default { set body [ossweb::util::wrap_text [ns_quotehtml $body]] }
      }
    }
    return $body
}

proc ossmon::object::mailbox::poll { name args } {

    set count 0
    set filter [ossmon::object $name ossmon:filter]
    set mailbox [ossmon::object $name ossmon:mailbox:name -default]
    set pos [ossweb::config ossmon:mailbox:position:$mailbox 0]
    # Something wrong with DB connection or cache
    if { [ossweb::config ossmon:config] == "" } {
      return
    }
    set id [ns_imap open -mailbox $mailbox]
    ossmon::object $name -set ossmon:mailbox:fd $id
    # Mailbox shrunk, start from first message
    if { [set msgs [ns_imap n_msgs $id]] < $pos } { set pos 0 }
    while { $pos < $msgs } {
      incr pos
      incr count
      set to [ns_imap header $id $pos to]
      set from [ns_imap header $id $pos from]
      set body [ns_imap text $id $pos]
      set subject [ns_imap header $id $pos subject]
      # Decode subject
      if { [set b [string first "=?" $subject]] >= 0 && [set b [string first "?" $subject [expr $b+2]]] > 0 } {
        set e [string first "?=" $subject $b]
        if { $e == -1 } { set e end } else { incr e -1 }
        switch [string index $subject [expr $b+1]] {
         Q { set subject [ns_imap decode qprint [string range $subject [expr $b+3] $e]] }
         B { set subject [ns_imap decode base64 [string range $subject [expr $b+3] $e]] }
        }
      }
      # General purpose filter
      foreach f $filter {
        if { [regexp -nocase $f "To: $to"] ||
             [regexp -nocase $f "From: $from"] ||
             [regexp -nocase $f "Subject: $subject"] } {
          # Decode body and files
          ossmon::object $name -set mailbox:files ""
          set row [list $from \
                        $to \
                        $subject \
                        $body \
                        [ossmon::object::mailbox::decode $name $id $pos]
                        [ossmon::object $name mailbox:files]]
          ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] $row
          break
        }
      }

      # Parse mail and save attachments in the specified directory
      foreach { filter path email } [ossmon::object $name mailbox:path:map -default] {
        if { [regexp -nocase $filter "To: $to"] ||
             [regexp -nocase $filter "From: $from"] ||
             [regexp -nocase $filter "Subject: $subject"] } {
          # Decode and save files
          ossmon::object::mailbox::decode $name $id $pos "" "" $path
          # Go through files and combine same path
          if { [set files [ossmon::object $name mailbox:files]] != "" } {
            set flist ""
            foreach frec [ossmon::object $name mailbox:files:email] {
              if { $path == [lindex $frec 1] } {
                eval lappend files [lindex $frec 2]
              } else {
                lappend flist $frec
              }
            }
            lappend flist [list $email $path $files $subject $from $to]
            ossmon::object $name -set mailbox:files:email $flist
          }
          ossmon::object $name -set mailbox:files ""
          break;
        }
      }

      # Hook for additional mailbox processing engine
      if { [info proc ::ossmon::object::mailbox::process] != "" } {
        ossmon::object::mailbox::process $name $id $pos $from $to $subject $body
      }
    }
    ossweb::set_config ossmon:mailbox:position:$mailbox $pos 1

    # Finish mailbox provisioning, send emails about uploaded files
    foreach { email path files subject from to } [ossmon::object $name mailbox:files:email] {
      # Custom Tcl callback can be used
      if { [string match tcl:* $email] } {
        if { [catch { [string range $email 4 end] $path $files $subject $from $to } errmsg] } {
          ns_log Error ossmon::object::mailbox: $email: $errmsg
        }
      } else {
        # Or just send email notification
        if { $email != "" } {
          set body "The following files have been posted:\n\n"
          append body "[ossweb::conn::hostname]/[ossweb::conn project_name]/ossmon/[file tail $path]/\n\n"
          foreach file $files {
            append body " - $file\n"
          }
          ossweb::sendmail $email ossmon $subject $body
        }
      }
      ossmon::object $name -log Notice mailbox: parsed files $files
    }

    return [ossmon::object $name obj:rowcount]
}

# ICMP ping requests
proc ossmon::object::ping::poll { name args } {

    set i 0

    # Exception can be fired
    ossmon::object::call_ping $name

    # Fire no connectivity here if no packets received, check 2 fields to be sure this is correct ping reply format
    if { [lindex $result 0] > 0 && [lindex $result 1] == 0 && [lindex $result 2] == 100 } {
      error "noConnectivity: no reply from [ossmon::object $name obj:host]"
    }
    # Position of reply fields correspond columns
    foreach key [ossmon::object $name ossmon:columns] {
      ossmon::object $name -set $key [lindex $result $i]
      ossmon::object $name -set obj:rowcount [incr i]
    }
    return [ossmon::object $name obj:rowcount]
}

# Save ICMP ping statistics
proc ossmon::action::process::before.poll.ping.*.ICMPStatistics { name args } {

    if { [ossmon::object $name ossmon:collect] == "" ||
         [ossmon::object $name obj:rowcount] == 0 } {
      return
    }

    # Check collect interval
    if { [ossmon::util::interval $name $name:ping] != "" } { return }

    set sent [ossmon::object $name pingSent]
    if { $sent == "" } { return }
    set received [ossmon::object $name pingReceived]
    set loss [ossmon::object $name pingLoss]
    set rttMin [ossmon::object $name pingRttMin]
    set rttAvg [ossmon::object $name pingRttAvg]
    set rttMax [ossmon::object $name pingRttMax]
    # Save values into the object
    ossmon::object $name -set ping:sent $sent \
                              ping:received $received \
                              ping:loss $loss \
                              ping:rttMin $rttMin \
                              ping:rttAvg $rttAvg \
                              ping:rttMax $rttMax \
                              obj:stats "rttMax=[format %.2f $rttMax]ms"
    # Save values into database
    ossmon::object $name -set time:collect [ns_time]
    ossweb::db::exec sql:ossmon.ping.create
}

# Special action handler for process table, try to fix failed process
proc ossmon::action::process::before.poll.*.prTable.ProcessFix { name args } {

    if { [ossmon::object $name prErrorFlag] != 1 } { return }

    set prIndex [ossmon::object $name prIndex]
    set prNames [ossmon::object $name prNames]
    ossmon::log 5 ossmon::action::handler::poll.prTable.ProcessFix $name: $prNames: prErrFix.$prIndex
    if { [ossmon::object::snmp::update $name prErrFix.$prIndex i 1] } {
      ossmon::object $name -log Error ossmon::action::poll.prTable.ProcessFix [ossmon::object $name -dump -sep ", "]
    }
    ns_sleep 5
    # Retrieve flag for fixed process
    if { [ossmon::object::snmp::get $name prErrorFlag.$prIndex -value t] == 0 } {
      set msg "Process '$prNames' has been fixed succesfully."
    } else {
      set msg "Process '$prNames' has NOT been fixed."
    }
    # Save values into the object
    ossmon::object $name -set fixMessage $msg
}

# Initialize SNMP session
proc ossmon::object::snmp::init { name args } {

    ossmon::object $name -set obj:data [ossmon::object $name ossmon:snmp:oid]
    set host [ossmon::object $name obj:host]
    set port [ossmon::object $name ossmon:snmp:port -config 161]
    set timeout [ossmon::object $name ossmon:snmp:timeout -config 2]
    set community [ossmon::object $name ossmon:snmp:community -config public]
    set writecommunity [ossmon::object $name ossmon:snmp:writecommunity -config $community]
    set version [ossmon::object $name ossmon:snmp:version -config 2]
    set retries [ossmon::object $name ossmon:snmp:retries -config 2]
    set bulk [ossmon::object $name ossmon:snmp:bulk -config 10]
    if { [catch {
      set fd [ns_snmp create $host -community $community \
                                   -writecommunity $writecommunity \
                                   -port $port \
                                   -timeout $timeout \
                                   -retries $retries \
                                   -bulk $bulk \
                                   -version $version]
    } errmsg] } {
      ossmon::object $name -set ossmon:status $errmsg
      ns_log Error ossmon::object::init: [ossmon::object obj:type]: $name: Host=$host:$port, Community=$community: $errmsg
      return -1
    }
    # Save SNMP descriptor and IP address, it may be used in handlers
    ossmon::object $name -set snmp:fd $fd \
                              obj:ipaddr [ns_snmp config $fd -address] \
                              snmp:community $community \
                              snmp:writecommunity $writecommunity \
                              snmp:timeout $timeout \
                              snmp:version $version \
                              snmp:bulk $bulk \
                              snmp:retries $retries \
                              snmp:port $port
    return 0
}

# Object's name
proc ossmon::object::snmp::name { name args } {

    return [ossmon::object $name ossmon:snmp:oid]
}

# SNMP session close
proc ossmon::object::snmp::close { name args } {

    if { [set fd [ossmon::object $name snmp:fd]] != "" } {
      catch { ns_snmp destroy $fd }
      ossmon::object $name -unset snmp:fd
    }
}

# Perform SNMP SET operation
proc ossmon::object::snmp::update { name oid type value } {

    set fd [ossmon::object $name snmp:fd]
    if { $fd != "" && [catch { ns_snmp set $fd [ossmon::mib::oid $oid] $type $value } errmsg] } {
      ns_log Notice ossmon::object::update $name: $oid: $errmsg
      ossmon::object $name -set ossmon:status $errmsg
      return -1
    }
    return 0
}

# Perform SNMP GET operation
proc ossmon::object::snmp::get { name oid args } {

    ns_parseargs { {-value t} } $args

    if { [catch { set rc [ns_snmp get [ossmon::object $name snmp:fd] [ossmon::mib::oid $oid]] } errmsg] } {
      ns_log Notice ossmon::object::get $name: $oid: $errmsg
      ossmon::object $name -set ossmon:status $errmsg
      return -1
    }
    if { $value == "t" } {
      set value ""
      foreach var $rc { lappend value [ossmon::mib::value [lindex $var 0] [lindex $var 2]] }
      return $value
    }
    return $rc
}

# Perform ping via SNMP, ping is being executed from
# object's host to the given host, not from the client
proc ossmon::object::snmp::ping { name host } {

    ossmon::object $name -set ping:rowcount 0 ping:format table ping:columns { Ping }
    if { [catch {
      ns_snmp set [ossmon::object $name snmp:fd] [ossmon::mib::oid pingHost] s $host
      ns_snmp walk [ossmon::object $name snmp:fd] [ossmon::mib::oid pingTable.101] var {
        ossmon::object $name -lappend ping:[ossmon::object $name -incr ping:rowcount] [lindex $var 2]
      }
    } errmsg] } {
      ossmon::object $name -set ossmon:status $errmsg
      return -1
    }
    return [ossmon::object $name ping:rowcount]
}

# Perform tail via SNMP
proc ossmon::object::snmp::tail { name str } {

    ossmon::object $name -set tail:rowcount 0 tail:format table tail:columns { Line }
    if { [catch {
      ns_snmp set [ossmon::object $name snmp:fd] [ossmon::mib::oid tailFile] s $host
      ns_snmp walk [ossmon::object $name snmp:fd] [ossmon::mib::oid tailTable.101] var {
        ossmon::object $name -lappend tail:[ossmon::object $name -incr tail:rowcount] [lindex $var 2]
      }
    } errmsg] } {
      ossmon::object $name -set ossmon:status $errmsg
      return -1
    }
    return [ossmon::object $name tail:rowcount]
}

# Perform SNMP FIX operation
proc ossmon::object::snmp::fix { name { prIndex "" } } {

    if { $prIndex == "" && [set prIndex [ossmon::object $name ossmon:snmp:fix:name]] == "" } {
      return -1
    }

    set rc -1
    set fixname $name:fix
    eval ossmon::object $fixname -set [ossmon::object $name -array]
    ossmon::object $fixname -set obj:type snmp
    ossmon::object $fixname -setup

    if { [ossmon::object $name snmp:fd] == "" && [ossmon::object $fixname -init -snmp t] == -1 } {
      return -1
    }
    # No SNMP support for this device
    if { [ossmon::object $fixname snmp:fd] == "" } {
      ossmon::object $fixname -log Error ossmon::object::snmp::fix: $prIndex: no SNMP objects
      return
    }
    # Fix by process index from prTable
    if { [string is integer $prIndex] } {
      if { ![ossmon::object::snmp::update $fixname prErrFix.$prIndex i 1] } {
        ossmon::object $fixname -log Error ossmon::object::snmp::fix: $prIndex: [ossmon::object $fixname -dump -sep ", "]
      } else {
        ns_sleep 5
        set rc [ossmon::object::snmp::get $fixname prErrorFlag.$prIndex -value t]
      }
    } else {
      # Fix by name using fixProcess OSSMON MIB variable
      set rc [ossmon::object::snmp::update $fixname fixProcess s $prIndex]
    }
    ossmon::alert::log $fixname "Attempt to fix process $prIndex, rc=$rc"
    ossmon::object $name -set ossmon:fixstatus [ossmon::object $fixname ossmon:status]
    ossmon::object $fixname -shutdown
    return $rc
}

# Retrieves the whole SNMP table and stors it into Tcl array.
# Array attributes:
# rowcount - contains number of rows,
# columns - contains row column names
# 1..n - actual records which are Tcl lists
# Returns -1 on error or number of rows retrieved.
proc ossmon::object::table::poll { name args } {

    set oid [ossmon::object $name ossmon:snmp:oid]
    if { [ossmon::mib::syntax $oid] != "SEQUENCE OF" } {
      ossmon::object $name -set ossmon:status "Invalid OID: $oid"
      return -1
    }
    # Allowed table columns, if specified we get only these fields, not the whole table
    set columns [ossmon::object $name ossmon:columns]

    ns_snmp walk [ossmon::object $name snmp:fd] [ossmon::mib::oid $oid] var {
      set oid [lindex $var 0]
      set index [lindex [split $oid "."] end]
      if { ![info exists map($index)] } {
        ossmon::object $name -incr obj:rowcount
        set map($index) [ossmon::object $name obj:rowcount]
        ossmon::object $name -set $map($index) ""
      }
      set id $map($index)
      set label [ossmon::mib::label $oid]
      if { $columns == "" } {
        if { $index == 1 } {
          ossmon::object $name -lappend ossmon:columns $label
        }
      } else {
        if { [lsearch -exact $columns $label] == -1 } {
          continue
        }
      }
      ossmon::object $name -lappend obj:$id [ossmon::mib::value $oid [lindex $var 2]]
    }
    return [ossmon::object $name obj:rowcount]
}

# Retrieve SNMP group of variables, like system subtree.
# Stores variables as array elements.
# rowcount - contains number of variables
# columns - contains variable names
# Returns -1 on error or number of variables retrieved.
proc ossmon::object::group::poll { name args } {

    set oid [ossmon::object $name ossmon:snmp:oid]
    if { [ossmon::mib::syntax $oid] != "VALUE-ASSIGNEMENT" } {
      ossmon::object $name -set ossmon:status "Invalid OID: $oid"
      return -1
    }
    # Variables to be retrieved may be provided as a parameter
    set columns [ossmon::object $name ossmon:columns]

    if { [catch {
      ns_snmp walk [ossmon::object $name snmp:fd] [ossmon::mib::oid $oid] var {
        set oid [lindex $var 0]
        set label [ossmon::mib::label $oid]
        if { $columns == "" } {
          ossmon::object $name -lappend ossmon:columns $label
        } else {
          if { [lsearch -exact $columns $label] == -1 } {
            continue
          }
        }
        ossmon::object $name -set $label [ossmon::mib::value $oid [lindex $var 2]]
        ossmon::object $name -incr obj:rowcount
      }
    } errmsg] } {
      global errorInfo
      ossmon::object $name -set ossmon:status $errmsg ossmon:trace $errorInfo
      return -1
    }

    return [ossmon::object $name obj:rowcount]
}

# Retrieves one SNMP variable or list of SNMP variables
proc ossmon::object::var::poll { name args } {

    set vars [ossmon::mib::oid [ossmon::object $name ossmon:snmp:oid]]

    if { [catch {
      foreach v [ossmon::object $name obj:data] {
        set oid [ossmon::mib::oid $v]
        if { [lsearch -exact $vars $oid] == -1 } { lappend vars $oid }
      }
      set rec [eval ns_snmp get [ossmon::object $name snmp:fd] $vars]
      foreach var $rec {
        set oid [lindex $var 0]
        set label [ossmon::mib::label $oid]
        ossmon::object $name -set $label [ossmon::mib::value $oid [lindex $var 2]]
        ossmon::object $name -lappend ossmon:columns $label
        ossmon::object $name -incr obj:rowcount
      }
    } errmsg] } {
      global errorInfo
      ossmon::object $name -set ossmon:status $errmsg ossmon:trace $errorInfo
      return -1
    }
    return [ossmon::object $name obj:rowcount]
}

# SNMP walk
proc ossmon::object::walk::poll { name args } {

    set oid [ossmon::object $name ossmon:snmp:oid]

    if { [catch {
      ns_snmp walk [ossmon::object $name snmp:fd] [ossmon::mib::oid $oid] var {
        set oid [lindex $var 0]
        set label [ossmon::mib::label $oid]
        ossmon::object $name -set $label [ossmon::mib::value $oid [lindex $var 2]]
        ossmon::object $name -lappend ossmon:columns $label
        ossmon::object $name -incr obj:rowcount
      }
    } errmsg] } {
      global errorInfo
      ossmon::object $name -set ossmon:status $errmsg ossmon:trace $errorInfo
      return -1
    }
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::ifTable::name { name args } {

    return "[ossmon::object $name ifDescr] [ossmon::object $name ifType]"
}

proc ossmon::object::ifTable::poll { name args } {

    set fd [ossmon::object $name snmp:fd]
    # List of interface indexes to retrieve, the reason is that sometimes like
    # on RiverStone routers interface row has invalid entries, if interface got disabled
    # RS snmp returns ObjectNotFound on ifMtu, ifOctet and other realtime columns.
    # Currently SNMP++ returns global error when it sees ObjectNotFound in SNMP_GET
    # with multiple variables.
    set ifIndex [ossmon::object $name ossmon:snmp:interface:index -config]

    # Filter to exclude unnecessary interfaces
    set filter [ossmon::object $name ossmon:filter -config]

    # Interface columns to retrieve
    set columns [ossmon::object $name ossmon:columns]

    # Do connectivity test first
    if { [ossweb::true [ossmon::object $name ossmon:ping -config 1]] } {
      ossmon::object::call_ping $name -count 1
    }
    set max_time [ossmon::object $name ossmon:poll:max -config 900]
    set start_time [ns_time]
    # Retrieve whole interface table into the cache
    set cache [ossmon::object::get_cache $name {
      # Get all interface indexes if not specified
      if { $ifIndex == "" } {
        ns_snmp walk $fd [ossmon::mib::oid ifIndex] var {
          set index [lindex [split [lindex $var 0] "."] end]
          lappend ifIndex $index
        }
      }
      # For each interface receive data columns
      foreach index $ifIndex {
        set vars ""
        array unset pos
        ossmon::object $name -set ossmon:ifIndex $index
        set idx 0
        set $index ""
        for { set idx 0 } { $idx < [llength $columns] } { incr idx } {
          set col [lindex $columns $idx]
          set var [ossmon::mib::oid $col]
          if { [string range $col 0 1] == "if" } { append var ".$index" }
          lappend vars $var
          lappend $index ""
          set pos($var) $idx
        }
        if { [catch {
          foreach var [eval ns_snmp get $fd $vars] {
            set idx $pos([lindex $var 0])
            lset $index $idx [ossmon::mib::value [lindex $var 0] [lindex $var 2]]
          }
        } errmsg] } {
          if { $errmsg != "SNMP: Variable does not exist" } {
            error $errmsg
          }
        }
        if { [ns_time] - $start_time > $max_time } {
          error "noResponse: too slow SNMP access"
        }
      }
      set ifList ""
      foreach index $ifIndex {
        if { [info exists $index] } { lappend ifList [subst \$$index] }
      }
      return $ifList
    }]
    foreach row $cache {
      # Apply filter if specified
      if { $filter != "" && ![ossmon::util::filter $filter [lindex $row 2]] } { continue }
      ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] $row
    }
    return [ossmon::object $name obj:rowcount]
}

# Calculate the interface utilization. This is done using the formula
#   util = (8*(delta(ifInOctets,t1,t0)+delta(ifOutOctets,t1,t0))/(t1-t0))/ifSpeed
# This formula returns incorrect results for full-duplex point to point
# links. In this case, the following formula should be used:
#   util = (8*max(delta(ifInOctets,t1,t0),delta(ifOutOctets,t1,t0))/(t1-t0))/ifSpeed
# See Simple Times, 1(5), November/December, 1992 for more details.
proc ossmon::action::process::before.poll.ifTable.*.InterfaceUtilization { name args } {

    if { [ossmon::object $name ossmon:collect] == "" ||
         [ossmon::object $name obj:rowcount] == 0 } { return }

    set ifIndex [ossmon::object $name ifIndex]
    set ifType [ossmon::object $name ifType]
    set ifDescr [ossmon::object $name ifDescr]
    set ifOperStatus [ossmon::object $name ifOperStatus]
    set key "$name:$ifIndex"
    set prefix "ossmon::action::process::poll.ifTable.InterfaceUtilization: $ifDescr:$ifType:$ifIndex"

    # Skip inactive interfaces
    switch $ifOperStatus {
     up - dormant - notPresent {}
     default { return }
    }

    # For broken or misconfigured SNMP interfaces
    set ifSpeed [ossmon::object $name ossmon:snmp:interface:speed -default [ossmon::object $name ifSpeed].0]
    # New values from the object
    set sysUpTime [ossmon::object $name sysUpTimeInstance]
    set ifInOctets [ossmon::object $name ifInOctets -default 0]
    set ifOutOctets [ossmon::object $name ifOutOctets -default 0]
    set ifInDiscards [ossmon::object $name ifInDiscards -default 0]
    set ifOutDiscards [ossmon::object $name ifOutDiscards -default 0]
    set ifInErrors [ossmon::object $name ifInErrors -default 0]
    set ifOutErrors [ossmon::object $name ifOutErrors -default 0]
    set ifInUcastPkts [ossmon::object $name ifInUcastPkts -default 0]
    set ifOutUcastPkts [ossmon::object $name ifOutUcastPkts -default 0]

    # Values from cache
    set sysUpTime2 [ossweb::cache get $key:sysUpTime 0]
    set ifInOctets2 [ossweb::cache get $key:ifInOctets 0]
    set ifOutOctets2 [ossweb::cache get $key:ifOutOctets 0]
    set ifInDiscards2 [ossweb::cache get $key:ifInDiscards 0]
    set ifOutDiscards2 [ossweb::cache get $key:ifOutDiscards 0]
    set ifInErrors2 [ossweb::cache get $key:ifInErrors 0]
    set ifOutErrors2 [ossweb::cache get $key:ifOutErrors 0]
    set ifInUcastPkts2 [ossweb::cache get $key:ifInUcastPkts 0]
    set ifOutUcastPkts2 [ossweb::cache get $key:ifOutUcastPkts 0]

    # Save values for next iteration
    ossweb::cache set $key:sysUpTime $sysUpTime
    ossweb::cache set $key:ifInOctets $ifInOctets
    ossweb::cache set $key:ifOutOctets $ifOutOctets
    ossweb::cache set $key:ifInDiscards $ifInDiscards
    ossweb::cache set $key:ifOutDiscards $ifOutDiscards
    ossweb::cache set $key:ifInErrors $ifInDiscards
    ossweb::cache set $key:ifOutErrors $ifOutDiscards
    ossweb::cache set $key:ifInUcastPkts $ifInUcastPkts -1
    ossweb::cache set $key:ifOutUcastPktss $ifOutUcastPkts -1

    # Check collect interval
    if { $sysUpTime2 == 0 || [ossmon::util::interval $name $key] != "" } { return }

    # See if counters have been reset, then just ignore this poll
    if { ($ifInOctets2 > 0 && $ifInOctets < $ifInOctets2) ||
         ($ifOutOctets2 > 0 && $ifOutOctets < $ifOutOctets2) } { return }

    # Time delta between pools
    if { [catch { expr $sysUpTime/100 - $sysUpTime2/100 } deltaUp] } { set deltaUp 0 }

    if { $deltaUp > 0 && $ifSpeed > 0 } {
      # Interface utiulization as percentage
      if { [catch { expr $ifInOctets - $ifInOctets2 } deltaIn] } {
        ossmon::object $name -log Error $prefix deltaIn=$deltaIn, ifInOctets=$ifInOctets, ifInOctets2=$ifInOctets2
        set deltaIn 0
      }
      if { [catch { expr $ifOutOctets - $ifOutOctets2 } deltaOut] } {
        ossmon::object $name -log Error $prefix deltaOut=$deltaOut, ifOutOctets=$ifOutOctets, ifOutOctets2=$ifOutOctets2
        set deltaOut 0
      }
      if { [regexp -nocase [set ::ossmon::object::ifTable::fullDuplex] $ifType] } {
        set delta [expr $deltaIn > $deltaOut ? $deltaIn : $deltaOut]
      } else {
        set delta [expr $deltaIn + $deltaOut]
      }
      set util [expr (8.0 * $delta / $deltaUp) / $ifSpeed * 100]

      if { $util < 0 } { set util 0 }
      if { $util > 100 } {
        ossmon::object $name -log Error $prefix Speed=$ifSpeed, Utilization=$util, Delta=$delta, DeltaUp=$deltaUp ($sysUpTime/$sysUpTime2), DeltaIn=$deltaIn ($ifInOctets/$ifInOctets2), DeltaOut=$deltaOut ($ifOutOctets/$ifOutOctets2)
        set util 100
      }
      # Bytes rates
      if { [set inRate [expr $deltaIn/$deltaUp]] < 0 } { set inRate 0 }
      if { [set outRate [expr $deltaOut/$deltaUp]] < 0 } { set outRate 0 }
      # Packet rates
      if { [catch { expr $ifInUcastPkts - $ifInUcastPkts2 } deltaPktIn] } { set deltaPktIn 0 }
      if { [catch { expr $ifOutUcastPkts - $ifOutUcastPkts2 } deltaPktOut] } { set deltaPktOut 0 }
      if { [set inPkt [expr $deltaPktIn/$deltaUp]] < 0 } { set inPkt 0 }
      if { [set outPkt [expr $deltaPktOut/$deltaUp]] < 0 } { set outPkt 0 }
      # Drop rates
      if { [catch { expr $ifInDiscards - $ifInDiscards2 } deltaDropIn] } { set deltaDropIn 0 }
      if { [catch { expr $ifOutDiscards - $ifOutDiscards2 } deltaDropOut] } { set deltaDropOut 0 }
      if { [set inDrop [expr $deltaDropIn/$deltaUp]] < 0 } { set inDrop 0 }
      if { [set outDrop [expr $deltaDropOut/$deltaUp]] < 0 } { set outDrop 0 }
      # Error rates
      if { [catch { expr $ifInErrors - $ifInErrors2 } deltaErrIn] } { set deltaErrIn 0 }
      if { [catch { expr $ifOutErrors - $ifOutErrors2 } deltaErrOut] } { set deltaErrOut 0 }
      if { [set inErr [expr $deltaErrIn/$deltaUp]] < 0 } { set inErr 0 }
      if { [set outErr [expr $deltaErrOut/$deltaUp]] < 0 } { set outErr 0 }
      # Transfer rates
      if { [catch { expr $deltaIn >= 0 ? $deltaIn : $ifInOctets } inTrans] } {
        ossmon::object $name -log Error $prefix inTrans=$inTrans, deltaIn=$deltaIn, ifInOctets=$ifInOctets
        set inTrans 0
      }
      if { [catch { expr $deltaOut >= 0 ? $deltaOut : $ifOutOctets } outTrans] } {
        ossmon::object $name -log Error $prefix outTrans=$outTrans, deltaOu=$deltaOut, ifOutOctets=$ifOutOctets
        set outTrans 0
      }
    } else {
      set util 0
      set inRate 0
      set outRate 0
      set inDrop 0
      set outDrop 0
      set inErr 0
      set outErr 0
      set inTrans 0
      set inPkt 0
      set outPkt 0
      set outTrans 0
      set deltaIn 0
      set deltaOut 0
      ossmon::log 6 $prefix $name: [ossmon::object $name -title]: IFSPEED=$ifSpeed, SYSUPTIME=$sysUpTime/$sysUpTime2, DELTAUP=$deltaUp
    }
    # Save calcualted values into the object
    ossmon::object $name -set interface:time:delta $deltaUp \
                           interface:utilization $util \
                           interface:rate:in $inRate \
                           interface:rate:out $outRate \
                           interface:rate:in:drop $inDrop \
                           interface:rate:out:drop $outDrop \
                           interface:rate:in:pkt $inPkt \
                           interface:rate:out:pkt $outPkt \
                           interface:rate:in:error $inErr \
                           interface:rate:out:error $outErr \
                           interface:rate:in:transfer $inDrop \
                           interface:rate:out:transfer $outDrop \
                           obj:stats "ifUtil=[format %.2f $util]%"

    # Save values into database
    if { $util > 0 || $inRate > 0 || $outRate > 0 } {
      ossmon::object $name -set time:collect [ns_time] obj:stats "ifUtil=[format %.2f $util]%"
      ossweb::db::exec sql:ossmon.ifTable.create
    }
}

proc ossmon::object::dskTable::create { name args } {

    ossmon::object $name -set ossmon:snmp:oid dskTable
}

proc ossmon::object::dskTable::name { name args } {

    return "[ossmon::object $name dskPath] [ossmon::object $name dskDevice] [ossmon::object $name dskAvail]"
}

proc ossmon::object::laTable::create { name args } {

    ossmon::object $name -set ossmon:snmp:oid laTable
}

proc ossmon::object::laTable::name { name args } {

    return "[ossmon::object $name laNames] [ossmon::object $name laLoad]"
}

proc ossmon::object::prTable::create { name args } {

    ossmon::object $name -set ossmon:snmp:oid prTable
}

proc ossmon::object::prTable::name { name args } {

    return [ossmon::object $name prNames]
}

proc ossmon::object::syslog::poll { name args } {

    set cache [ossmon::object::get_cache $name {
      ns_snmp walk [ossmon::object $name snmp:fd] [ossmon::mib::oid syslogTable].101 var {
        lappend cache [list [lindex $var 2]]
      }
    }]
    foreach row $cache {
      ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] $row
    }
    return [ossmon::object $name obj:rowcount]
}

# RADIUS handler
proc ossmon::object::radius::poll { name args } {

    set user [ossmon::object $name ossmon:auth:user]
    set password [ossmon::object $name ossmon:auth:password]
    set timeout [ossmon::object $name ossmon:radius:timeout -config 30]
    set port [ossmon::object $name ossmon:radius:port -config 1842]
    set timeout [ossmon::object $name ossmon:radius:timeout -config 5]
    set retries [ossmon::object $name ossmon:radius:retries -config 2]
    set secretkey [ossmon::object $name ossmon:auth:secretkey]
    set host [ossmon::object $name obj:host]
    set status [ns_radius send $host $port $secretkey User-Name $user User-Password $password]
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $status]
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::radius::fix { name args } {

    return [ossmon::object::snmp::fix $name]
}

# File handler
proc ossmon::object::file::init { name args } {

    set fd [::open [ossmon::object $name obj:name]]
    ossmon::object $name -set socket:fd $fd
    return 0
}

proc ossmon::object::file::poll { name args } {

    set fd [ossmon::object $name socket:fd]
    set file [ossmon::object $name obj:name]
    set filter [ossmon::object $name ossmon:filter]
    set ignore [ossmon::object $name ossmon:filter:ignore]
    set pos [ossmon::object $name ossmon:position:$file -default 0]

    set size [::file size $file]
    if { $size < $pos } { set pos 0 }
    if { $size - $pos > 1000000 } { set pos [expr $size - 1000000] }
    seek $fd $pos
    while { ![eof $fd] } {
      if { [set line [string trim [gets $fd]]] == "" ||
           ($ignore != "" && [regexp -nocase $ignore $line]) } {
        continue
      }
      if { [regexp -nocase $filter $line] } {
        ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $line]
      }
      if { [ossmon::object $name obj:rowcount] > 255 } { break }
    }
    ossmon::object $name -save ossmon:position:$file [::tell $fd]
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::file::fix { name args } {

    return [ossmon::object::snmp::fix $name]
}

# TCP generic handler
proc ossmon::object::tcp::init { name args } {

    set host [ossmon::object $name obj:host]
    set port [ossmon::object $name ossmon:tcp:port]
    set timeout [ossmon::object $name ossmon:tcp:timeout -config 30]
    set fd [ossmon::object $name -open -host $host -port $port -timeout $timeout]
    ossmon::object $name -set socket:fd $fd
    return 0
}

proc ossmon::object::tcp::poll { name args } {

    set fd [ossmon::object $name socket:fd]
    set host [ossmon::object $name obj:host]
    set data [ossmon::object $name ossmon:tcp:data]
    set size [ossmon::object $name ossmon:tcp:size -config 100]
    set timeout [ossmon::object $name ossmon:tcp:timeout -config 30]
    set reply ""
    # Send request data
    set start_time [clock clicks -milliseconds]
    if { $data != "" } {
      ossmon::util::puts $fd $data -timeout $timeout -nonewline t
    }
    if { $size > 0 } {
      set reply [ossmon::util::gets $fd -timeout $timeout -size $size]
    }
    set time [expr [clock clicks -milliseconds]-$start_time]
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $data $reply $time]
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::tcp::fix { name args } {

    return [ossmon::object::snmp::fix $name]
}

# UDP generic handler
proc ossmon::object::udp::poll { name args } {

    set host [ossmon::object $name obj:host]
    set port [ossmon::object $name ossmon:udp:port]
    set timeout [ossmon::object $name ossmon:udp:timeout -config 30]
    set retries [ossmon::object $name ossmon:udp:retries -config 0]
    set data [ossmon::object $name ossmon:udp:data]

    set start_time [clock clicks -milliseconds]
    set reply [ns_udp $host $port $data -timeout $timeout -retries $retries]
    set time [expr [clock clicks -milliseconds]-$start_time]
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $data $reply $time]
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::udp::fix { name args } {

    return [ossmon::object::snmp::fix $name]
}

# FTP handler
proc ossmon::object::ftp::init { name args } {

    set host [ossmon::object $name obj:host]
    set port [ossmon::object $name ossmon:ftp:port -config 21]
    set timeout [ossmon::object $name ossmon:ftp:timeout -config 30]
    set fd [ossmon::object $name -open -host $host -port $port -timeout $timeout]
    ossmon::object $name -set socket:fd $fd
    return 0
}

proc ossmon::object::ftp::poll { name args } {

    set fd [ossmon::object $name socket:fd]
    set user [ossmon::object $name ossmon:auth:user]
    set password [ossmon::object $name ossmon:auth:password]
    set host [ossmon::object $name obj:host]
    set timeout [ossmon::object $name ossmon:ftp:timeout -config 30]
    set protocol [list "" "220" "USER $user" "331" "PASS $password" "230" "QUIT" ""]
    set line ""
    set status "OK"

    foreach { msg code } $protocol {
      # Send request data
      if { $msg != "" } { ossmon::util::puts $fd "$msg\r" -timeout $timeout }
      # Read response line
      set line [ossmon::util::gets $fd -timeout $timeout]
      if { $code != "" && [string range $line 0 2] != $code } {
        if { $line == "" && ![ns_sockcheck $fd] } {
          if { [catch { set line [fconfigure $fd -peername] }] } { set line noResponse }
        }
        set status $line
        break
      }
    }
    ossmon::object $name -set obj:[ossmon::object $name -incr obj:rowcount] [list $host $status]
    return [ossmon::object $name obj:rowcount]
}

proc ossmon::object::ftp::fix { name args } {

    return [ossmon::object::snmp::fix $name]
}

proc ossmon::object::uptime::create { name args } {

    ossmon::object $name -set ossmon:snmp:oid sysUpTimeInstance \
                              ossmon:chart:title Uptime/PowerOn \
                              ossmon:chart:yaxis Minutes \
                              ossmon:chart:sno:onoff 2 \
                              ossmon:collect ""
}

proc ossmon::object::uptime::poll { name args } {

    return [eval ossmon::object::var::poll $name args]
}

# Save uptime statistics
proc ossmon::action::process::before.*.uptime.*.UptimeStatistics { name args } {

    # We do not care about alerts, just ignore them
    ossmon::object $name -set ossmon:type poll

    set key Uptime
    set user_id [ossmon::object $name ossmon:user_id -config 0]
    set now [ossmon::object $name time:now]
    # Uptime is in miliseconds, make it minutes
    set value [expr [ossmon::object $name sysUpTimeInstance -default 0]/100/60]
    # Keep second set as indicatior of power on
    if { $value > 0 } {
      set key2 PowerOn
      set value2 1
    }
    ossweb::db::exec sql:ossmon.collect.create

    # Use persistent properties in case of reboot
    set old_time [ossmon::object $name old:time -default 0]
    set old_value [ossmon::object $name old:value -default 0]
    set down_time [ossmon::object $name down:time -default 0]

    # If device lost power between polls insert records that indicate that
    if { $value > 0 && $value < $old_value } {
      # Create record when it went down, this is the time when we got first connectivity alarm
      if { $old_time < $down_time } {
        ossmon::object $name -set time:now $down_time
        ossweb::db::exec sql:ossmon.collect.create -vars "value 0 value2 0"
      }

      # Create record when down period ended, use 1 second before actual boot time
      ossmon::object $name -set time:now [expr $now-$value*60-1]
      ossweb::db::exec sql:ossmon.collect.create -vars "value 0 value2 0"

      # Create record when it was up again
      ossmon::object $name -incr time:now
      ossweb::db::exec sql:ossmon.collect.create
    }

    # Mark when we got last non-zero uptime
    if { $value > 0 } {
      # Clear because we got more than one non-zero uptime value
      if { $old_value > 0 } {
        set down_time 0
      }
      set old_time $now
      set old_value $value
    } else {
      # Mark when it first went down
      if { $down_time == 0 } {
        set down_time $now
      }
    }
    # Save in properties
    ossmon::object $name -set:property old:time $old_time old:value $old_value down:time $down_time
    # Update time when we did collection
    ossmon::object $name -set time:collect [ns_time]
}

