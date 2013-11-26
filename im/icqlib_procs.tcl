#  ICQ client library
#  Copyright (C) Ihar Viarheichyk 2001-2004

#  This library gives ability to use ICQ v8 protocol (OSCAR) in tcl programs.
#  Protocol description and some ideas in implementattion were taken from 
#  ICQ2000.pm and ICQ2000_Easy.pm perl modules by
#  Robin Fisher <robin@phase3solutions.com> and vICQ program by 
#  Alexander Timoshenko

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
	       
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#
# Modified to be used under NaviServer 
# by Vlad Seryakov vlad@crystalballinc.com
#

namespace eval icq {
	variable delim [binary format c 0xFE]
	variable glue <...>
	variable maxlen 100
        variable loginTLV ""
	array set timeout {
		connect		5000
		host		5000
		disconnect	idle
		unaligned	idle
		error		idle
		rate		600000
		ping		idle
		proxy		10000
	}
	variable Defaults {	
		-server		login.icq.com	-port		5190
		-reconnect	0		-event		""
		-keepalive	0		-ping		0
		-roster		1		roster_granted	0
		-proxy		{}		-glue-timeout	600000
		-capabilities	{ICQ RELAY UTF8}
		-auto-away	{}		-auto-occ	{}
		-auto-dnd	{}		-auto-ffc	{}
		-auto-na	{}
		uin		0		password	{}
		list_all	{}		list_visible	{}
		list_invisible	{}
		Flags		0x100		current_status	offline
		-dcinfo		{}
		unicode		0		status		offline
		relay		-1		
		maxvisible	200		maxinvisible	200	
		SeqNum		3412		counter		0xFFFF
	}

array set ListCmd {all,add 2:3:4 visible,add 2:9:5 invisible,add 2:9:7
	all,delete 2:3:5 visible,delete 2:9:6 invisible,delete 2:9:8}

# Tlv format specification. Only non-string fields given
array set tlvSpec { 1:20 I 1:22 S 1:23 S 1:24 S 1:25 S 1:26 S 4:8 S
        2:1 S 2:2 I 2:3 I 2:4 S 2:6 I 2:8 S 2:10 I 2:15 I 2:18 S msg:10 S
	roster:202 c roster:200 S*}

# Alias table: map tlv, status etc codes to names
array set alias {
	1:1 uin 1:2 password 1:3 ClientProfile 1:5 UserInfo 1:6 Cookie
	1:14 Country 1:15 Language 1:20 BuildMin 1:22 ClientType
	1:23 VersionMaj 1:24 VersionMin 1:25 IcqNumber 1:26 BuildMaj
	2:1 UserClass 2:2 SignupDate 2:3 SignonDate 2:4 Port 2:5 EncodedMsg
	2:6 Status 2:8 ErrCode 2:10 IP 2:11 WebAddr 2:12 LanDetails
	2:13 Capabilities 2:15 TimeOnline 2:18 Unk1 4:1 UIN 4:4 HtmlAddr
	4:5 ServerAndPort 4:6 Cookie 4:8 ErrCode 4:9 DisconnectCode

	info:1 encodingType info:2 profile info:3 encoding info:4 message

	roster:202 visibility roster:305 Alias roster:200 ids roster:205 icqtic
	roster:200 members roster:102 auth roster:314 mobile
	rtype:0 contact rtype:1 group rtype:4 visibility rtype:9 icqtic
	raction:add 2:19:8 raction:update 2:19:9 raction:delete 2:19:10
	
	status:0 online status:1 away status:2 dnd status:4 na status:5 na
	status:16 occ status:17 occ status:19 dnd status:32 ffc 
	status:256 invisible

	dctype:0 disabled dctype:1 https dctype:2 socks dctype:4 normal
	dctype:6 web

	cap:094613444c7f11d18222444553540000 ICQ
	cap:094613494c7f11d18222444553540000 RELAY
	cap:0946134e4c7f11d18222444553540000 UTF8
	cap:97b12751243c4334ad22d6abf73f1492 RTF
	cap:a0e93f374c7f11d18222444553540000 STR_2001
	cap:10cf40d14c7f11d18222444553540000 STR_2002
	cap:2e7a6475fadf4dc8886fea3595fdb6df IS_2001
	cap:094913494c7f11d18222444553540000 LICQ
	cap:563fc8090b6f41bd9f79422609dfa2f3 WEB
	cap:f2e7c7f4fead4dfbb23536798bdf0000 TRILL_CRYPT
	cap:97b12751243c4334ad22d6abf73f1409 TRILL_UNK
	cap:094613434c7f11d18222444553540000 AIM_SENDFILE
	cap:094613484c7f11d18222444553540000 AIM_GETFILE
	cap:094613414c7f11d18222444553540000 AIM_VOICE
	cap:748f2420628711d18222444553540000 AIM_CHAT
	cap:094613464c7f11d18222444553540000 AIM_ICON
	cap:094613454c7f11d18222444553540000 AIM_IMAGE
	cap:094613474c7f11d18222444553540000 AIM_STOCKS
	cap:0946134A4C7F11D18222444553540000 AIM_GAMES
	cap:0946134B4C7F11D18222444553540000 AIM_BUD
	cap:0946134d4c7f11d18222444553540000 AIM_INTEROPERATE
	cap:97b12751243c4334ad22d6abf73f14?? Sim08
	cap:53494d20636c69656e742020???????? Sim
	cap:6d49435120a920522e4b2e20???????? mICQ
	
	cli:ffffffff Miranda cli:ffffff8f StrICQ cli:ffffff42 mICQ	
	cli:ffffff7f &RQ cli:ffffffab YSM cli:ffffffbe Alicq

	type:3 File type:4 {Send Web Page Address (URL)} type:19 Contacts
	type:2 {Send / Start ICQ Chat} 
}

# Reverse alias table
foreach {key val} [array get alias] { 
	foreach {tag id} [split $key :] break
	set alias($tag:$val) $id
}

proc log {cmd level str} { event $cmd Log $level $str }

proc event {cmd event args} {
	upvar #0 $cmd data
	if {![string equal $data(-event) ""]} {
		catch {eval $data(-event) [list $event] $args}
	}
}

proc icq {uin password args} {
        init
	set cmd uin-$uin
	upvar #0 [namespace current]::$cmd data
	if {[llength [info commands $cmd]]} {
		return -code error "Command for UIN $uin already exists"
	}
	array set data $icq::Defaults
	eval sub_configure [namespace current]::$cmd $args
	set data(uin) $uin
	set data(encoding) [encoding system]
	if {$uin=="new"} {
		set data(password) $password
		after idle [nc Connect icq::$cmd $data(-server) $data(-port)]
		#after 30000 [nc event [namespace current]::$cmd Registered 100 $password]
	} else {
		if {![string is integer $uin]} {
			return -code error "ICQ UIN should be integer number"
		}
		set data(password) [EncryptPassword $password]
	}
	interp alias {} $cmd {} icq::icqproc $cmd
}

proc icqproc {cmd sub args} {
	if {[llength [info commands sub_$sub]]} {
		eval [list sub_$sub [namespace current]::$cmd] $args
	} else {
		set subs [list]
		foreach c [info commands sub_*] {
			lappend subs [string range [namespace tail $c] 4 end]
		}
		return -code error "Invalid icq subcommand $sub. Valid subcommands are [join [lsort $subs] {, }]."
	}
}

# change icq options
proc sub_configure {cmd args} {
	upvar #0 $cmd data
	set options [lsort [array names data -*]]
	foreach {option value} $args {
		if {[lsearch -exact $options $option]==-1} {
			return -code error "Unknown option \"$option\""
		}
		if {[llength [info commands valid$option]] && 
		    ![valid$option $cmd $value]} {
			return -code error "Invalid value of $option: $value"
		} else { set data($option) $value }
	}
}

proc valid-proxy {cmd value} {
	if {[lsearch -exact [::proxy::enum] $value]==-1} { return 0 }
	return 1
}

proc valid-dcinfo {cmd value} {
	upvar #0 $cmd data
	set len [llength $value]
	if {$len!=3 && $len} { return 0}
	if {$data(current_status)!="offline"} {after idle [nc SetStatus $cmd]}
	return 1
}

proc Timer {type cmd value} {
	if {[string is integer $value]} {
		foreach x [list cancel $value] { after $x [nc $type $cmd] }
		return 1
	} else { return 0 }
}

# get icq option
proc sub_cget {cmd key} {
	upvar #0 $cmd data
	if {[string match -* $key]} {
		if {[info exists data($key)]} { return $data($key)}
	}
	return -code error "Unknown option $key"
}

proc sub_delete {cmd} {
	interp alias {} [namespace tail $cmd] {}
	CloseConnection $cmd
	if {[info exists ${cmd}-sent]} {unset ${cmd}-sent}
	unset $cmd
}

# set or query personal status
proc sub_status {cmd {status query}} {
	upvar #0 $cmd data
	if {$status!={query}} {
		set status [alias status $status]
		if {![string is integer $status]&&$status!="offline"} {
			variable alias
			set list [list] 
			foreach x [array names alias {status:[a-z]*}] {
				lappend list [lindex [split $x :] 1]
			}
			return -code error "Wrong status $status. Status can be one of: [join $list {, }]"
		}
		if {$status==$data(status)} { return $status }
		if {$status=="offline" && $data(status)!="offline"} {
			CloseConnection $cmd
		} elseif {$data(status)=="offline" && $status!="offline"} {
			Connect $cmd $data(-server) $data(-port) 
		}
		set data(status) $status
		if {$data(current_status)!="offline"} { SetStatus $cmd }
	}
	set data(current_status)
}

# send ICQ messages of differnet types
proc sub_send {cmd type uin message {msgid ""}} {
	upvar #0 $cmd data
	if {![llength [info commands send_$type]]} {
		return -code error "Can not send message of type $type" 
	}
	if {$msgid==""} { set msgid [msgid] }
	event $cmd Outgoing $type $uin [clock seconds] $message $msgid
	after idle [nc Spool $cmd spooler [list $msgid $type $uin $message 0]]
	set msgid
}

# Calculate unique message-id
proc msgid {} { format %08x:%08x [clock seconds] [clock clicks] }

# upload or query contact lists
proc sub_contacts {cmd list args} {
	upvar #0 $cmd data
	set action add
	switch -exact -- [llength $args] {
		0 {}
		1 {set items [lindex $args 0]}
		2 {foreach {action items} $args break }
	  default {return -code error "Wrong number of arguments."}
	}
	if {[lsearch {add delete} $action]==-1} {
		return -code error "Invalid action. Should be add or delete."
	}
	if {![info exists data(list_$list)]} {
		foreach x [array names data list_*] { 
			lappend v [string range $x 5 end]
		}
		if {[info exists v]} {
			return -code error "Invalid list type $list. Valid types: [join $v {, }]"
		} else {
			return -code error "No lists supported."
		}
	}
	if {$action=="add"} { 
		set max end
		if {[info exists data(max$list)]} {set max $data(max$list)}
		set lst [concat $data(list_$list) $items]
		set data(list_${list}) [lrange $lst 0 $max]
		if {[llength $lst]!=[llength $data(list_${list})]} {
			event $name 1 "Limit for list $type reached, list is truncated."
		}
			
	} else {
		foreach x $items {
			if {[set pos [lsearch $data(list_${list}) $x]]!=-1} {
				set data(list_${list}) [lreplace\
					$data(list_${list}) $pos $pos]
			}
		}
	}
	if {$data(current_status)!="offline" && (
	    ($list=="visible" && $data(status)==0x100) ||
	    ($list=="invisible" && $data(status)!=0x100) ||
	    $list=="all")} {
		UploadList $cmd $list $action $items
	}
	set data(list_${list})
}

# get info on uin
proc sub_info {cmd uin {ref 0}} {
	SrvMessage $cmd 2000 [lword 1202][ldword $uin] $ref
	#SrvMessage $cmd 2000 [lword 1210][ldword $uin] $ref`
}

# query or change personal info
proc sub_personal {cmd {info {}}} {
	upvar #0 $cmd data
	if {[llength $info]} {
		UpdateInfo $cmd $info
	} else { sub_info $cmd $data(uin) }
}

# search in whitepages by filter
proc sub_search {cmd filter {ref 0}} {
	Search $cmd $filter $ref
}

# server-side roster operations
proc sub_roster {cmd args} {
	upvar #0 $cmd data
	if {!$data(roster_granted)} {
		return -code error "Operations with server-side roster is not permitted."
	}
	UpdateRoster $cmd $args
}

# query or change global or contact encoding
proc sub_encoding {cmd {encoding ""} {uins {}}} {
	upvar #0 $cmd data
	if {[string equal $encoding ""]} {
		set res $data(encoding)
	} else {
		if {[llength $uins]} {
			foreach uin $uins { set data($uin-encoding) $encoding }
			set res $encoding
		} else { set res [set data(encoding) $encoding] }
	}
}

# Change personal password
proc sub_password {cmd password {ref 0}} {
	SrvMessage $cmd 2000 [lword 1070][lntsz $password] $ref
}

proc ReadData {name} {
	variable timeout
	upvar #0 $name data
	if {[catch { set chunk [read $data(socket) $data(Length)] }]} {
		log $name {error network} "Host is unreachable"
		CloseConnection $name $timeout(connect)
		return
	}
	append data(packet) $chunk
	if {$chunk=={}} {
		CloseConnection $name $timeout(disconnect)
	} elseif {![incr data(Length) -[string length $chunk]]} {
		if {$data(wantBody)} {
			binary scan $data(packet) H* hex
			log $name {debug dump} "<- $hex"
			ParsePacket $name $data(packet)
			set data(packet) {}
			set data(Length) 6
		} else {
			binary scan $data(packet) c@4S Id data(Length)
			if {$Id != 42} {
				log $name error "Unaligned data: $Id!"
				CloseConnection $name $timeout(unaligned)
				return
			}
		}
		set data(wantBody) [expr $data(wantBody)^1]
	}
}

proc WriteData {name} {
	upvar #0 $name data
	set x [lindex $data(queue) 0] 
	binary scan $x H* hex
	log $name {debug dump} "-> $hex"
	if {[catch { puts -nonewline $data(socket) $x } v]} {
		event $name Error connection $v
	}
	set data(queue) [lrange $data(queue) 1 end]
	if {![llength $data(queue)]} {
		fileevent $data(socket) writable {}
		unset data(queue)
	}
}

# Toplevel packet handler
proc ParsePacket {name packet} {
	upvar #0 $name data
	set data(mark) 1
	icq::match $packet {{byte _ channel} 4 {* other}}
	set handler $channel:0:0 
	if {$channel!=1 && $channel!=4} { 
		match $other {{bword family subID} {* other}}
		set handler $channel:$family:$subID
	}
	if {[llength [info commands $handler]]} {
		if {[catch {$handler $name $other} reason]} {
			event $name Error:Protocol $handler $reason $packet
		}
	} else { 
		binary scan $packet H* hex
		log $name warning "There is no handler for message $handler\n$hex" 
	}
}
# These are handlers for server messages 

# Login negotiation
proc 1:0:0 {name packet} {
	variable loginTLV
	upvar #0 $name data
	log $name notice "Got login invitation, logging in"
	if {$data(uin)=="new"} { 
		Register $name $data(password)
	} else {
		if {[info exists data(Cookie)]} {
			log $name info "Using cookie"
			set cmd [TLV 1 Cookie $data(Cookie)]
			unset data(Cookie) 
		} else { set cmd [TLV 1 uin $data(uin)\
				password $data(password)][set loginTLV]
		}
		Packet $name 1 [bdword 1]$cmd
	}
}
array set error { 24	{rate "Connection rate exceeded"}
		  29 	{rate "Sending rate exceeded"}
		  5	{auth "Wrong password"} }

# Disconnect negotiation
proc 4:0:0 {name packet} {
	upvar #0 $name data
	variable timeout
	variable error
	
	log $name notice "Disconnect command"
	array set TLV [lindex [scanTLV $packet 4 4] 0]
	if { [info exists TLV(Cookie)] && [info exists TLV(ServerAndPort)] } {
		set data(Cookie) $TLV(Cookie)
		log $name notice "Server wants us to reconnect to $TLV(ServerAndPort)"
		CloseConnection $name
		after idle [nc Connect $name] [split $TLV(ServerAndPort) :]
	} else {
		set code error
		if {[info exists TLV(ErrCode)]} {
			if {[info exists error($TLV(ErrCode))]} {
				foreach {code descr} $error($TLV(ErrCode)) {}
			} else { set descr unknown }
			log $name error "Reason: $TLV(ErrCode): $code, $descr"
			event $name Error:$code $descr
		} else { log $name warning "Disconnected by server: reason unknown." }
		set to ""
		if {[info exists timeout($code)]} {set to $timeout($code)}
		CloseConnection $name $to
	}
}
# My status
proc 2:1:15 {name packet} {
	upvar #0 $name data 

	match $packet {6 {buin User} {bword WarningLevel} {TLV tlvs}}
	array set TLV $tlvs
	if {[info exists TLV(Status)]} {
		set data(current_status) [expr $TLV(Status)&0xFFFF]
		if {$data(current_status)>256} { set data(current_status) 256 }
		event $name MyStatus [alias status $data(current_status)]
	}
	if {[info exists TLV(IP)]} {
		set data(remote_ip) [IP $TLV(IP)]
		event $name MyIP $data(local_ip) $data(remote_ip)
	}
}

# Server Ready 
proc 2:1:3 {name args} {
	Command $name 2:1:23 [bword 1 3 2 1 3 1 21 1 4 1 6 1 9 1 10 1]
}
# Rate info answer
proc 2:1:7 {name packet args} {
	#Rate info ack
	binary scan $packet H* hex
	match $packet {6 {bword cnt} {* packet}}
	if {!$cnt} return 
	# Get list of limit classes
	for {set i 0} {$i<$cnt} {incr i} {
		match $packet {{bword id} {bdword a(win) a(clear)\
			a(alert) a(limit) a(disconnect) a(current)\
			a(max) a(ltime)}
			{byte a(state)} {* packet}}
		set classes($id) [array get a]
	}
	unset a
	# Map falily/subfamily to internal spooling classes
	array set pools { 4:6 spooler 21:2 srv 19:17 roster 2:5 extinfo}
	set now [clock seconds]
	for {set i 0} {$i<$cnt} {incr i} {
		match $packet {{bword id amount} {* packet}}
		append res [bword $id]
		set pairs [list]
		for {set j 0} {$j<$amount} {incr j} {
			match $packet {{bword fam sub} {* packet}}
			if {[info exists pools($fam:$sub)]} {
				upvar $name-$pools($fam:$sub) pool
				array set pool $classes($id)
				set pool(ltime) [list\
					[expr $now-$pool(ltime)/1000]\
					[expr $pool(ltime)%1000]]
			}
		}
	}
	unset pools
	Command $name 2:1:8 $res
}

# Sending too fast
proc 2:1:10 {name packet args} {
	upvar #0 $name-spooler pool
	log $name notice "Sending messages too fast, rescheduling for $pool(clear)"
	schedule $name $pool(clear) spooler
}

# Process additional user info
proc 2:2:6 {name packet args} { 
	upvar #0 $name data 
	# Skip fixed part
	match $packet {6 {buin UIN} word {TLV tlvs} {* other}}
	array set tlv [scanTLV $other 3 info]
	log $name {debug ext} "Ext info $UIN: [array get tlv]"
}

proc extinfo {name UIN} {
	log $name notify "Requiest away message from $UIN"
	Command $name 2:2:5 [word 3][buin $UIN]
	return 1
}

# Conact online
proc 2:3:11 {name packet args} {
	upvar #0 $name data 
	variable alias

	match $packet {6 {buin UIN} word {TLV tlvs} {* other}}
	if {$other!=""} {
		binary scan $packet H* hex
		log $name {warning notice} "Ext info for $UIN: $hex"
	}
	array set TLV $tlvs
	if {[info exists TLV(Status)]} {
		set status [alias status [expr $TLV(Status)&65535]]
		if {[string is integer $status]} {
			 log $name error "Unknonw status $status"
		} else { event $name Status $UIN $status }
		if {[info exists TLV(IP)]} { event $name IP $UIN [IP $TLV(IP)] }
		if {$TLV(Status)&0x80000} { event $name Birthday $UIN }
		if {$TLV(Status)&0x20000} { event $name ShowIp $UIN }
		# Request away message
		if {0 && $status!="online"} {
			Spool $name extinfo $UIN
		}
	}
	# Check capabilities
	if {[info exists TLV(Capabilities)]} {
		set data($UIN-unicode) 0
		set ver 0
		set lcaps [list]
		set str $TLV(Capabilities)
		while {$str!={}} {
			foreach {cap str} [cap.get $str] break
			lappend lcaps $cap
		}
		# Determine client
		foreach {mask client} [list [alias cap Sim8] Sim8\
			[alias cap Sim] Sim WEB ICQ-Lite\
			*TRILL* Trillian UTF8 ICQ2002 IS_2001 ICQ2001\
			[alias cap mICQ] mICQ _ unknown] {
			 if {[lsearch $lcaps $mask]!=-1} break
		}
		set data($UIN-relay) 0
		if {[lsearch $lcaps RELAY]!=-1 && [lsearch $lcaps ICQ]!=-1} {
			set data($UIN-relay) 1 
		}
		if {[lsearch $lcaps UTF8]!=-1 && $client!="Trillian" && 
			$client!="Sim8"} { set data($UIN-unicode) 1 }
		if {$client=={ICQ-Lite} && [lsearch $lcaps ICQ]==-1} {
			set client ICQ2go
			#set data($UIN-unicode) 0
		} elseif {$client=={Sim8}} {
			set p [lindex $lcaps [lsearch $lcaps [alias cap Sim8]]]
			set p 0x[string range $p end-1 end]
			set client "Sim [expr $p/64-1].[expr $p&63]"

		} elseif {$client=="Sim"} {
			set p [lindex $lcaps [lsearch $lcaps [alias cap Sim]]]
			set grt 0x[string range $p end-7 end-6]
			set maj 0x[string range $p end-5 end-4]
			set min 0x[string range $p end-3 end-2]
			set client [format "%s %d.%d.%d" $client $grt $maj $min]
		}
		event $name Capabilities $UIN $lcaps
	}
	if [info exists TLV(LanDetails)] {
		binary scan $TLV(LanDetails) IIcSIIIIII addr port type\
			ver cookie webport futures stamp1 stamp2 stamp3
		event $name LanDetails $UIN [alias dctype $type] [IP $addr]\
			$port $cookie $ver
		if {[expr { ($stamp1>>24)==0x7d }]} {
			set client Licq
			if {[expr {$stamp1&0x00800000}]} {append client "/SSL"}
			set v [expr $stamp1&0x007FFFFF]
			append client " [expr $v/1000].[expr $v%1000/10].[expr $v%10]"
		} else {
		   set x [format %x $stamp1]
		   if [info exists alias(cli:$x)] {set client $alias(cli:$x)}
		}	
		if {[info exists client] &&\
		    [lsearch {Alicq mICQ Miranda &RQ} $client]!=-1} {
			append client " [expr ${stamp2}>>24].[expr (${stamp2}>>16)&0xFF].[expr (${stamp2}>>8)&0xFF]"
			if {[set l [expr $stamp2&0xFF]]} { append client ".$l" }
		}
	}
	# Check signup and signon dates
	foreach x {SignupDate SignonDate} {
		if {[info exists TLV($x)]} { event $name $x $UIN $TLV($x) }
	}
	if {[info exists client] && [info exists ver]} {
		event $name Client $UIN $ver $client\
			[expr $data($UIN-unicode)&&$data($UIN-relay)]
	}
}

# Contact offline
proc 2:3:12 {name packet args} {
	upvar #0 $name data
	match $packet {6 {buin UIN}}
	# Unicode is not supported in offline mode
	set data($UIN-unicode) 0
	set data($UIN-relay) -1
	event $name Status $UIN offline
}

# Server services version hanlder
# Here we can send a lot of commands at once, and handle only those replies
# we can handle
proc 2:1:24 {name packet} {
	upvar #0 $name data

	# Determine local IP address (take server connection as base)
	set data(local_ip) [lindex [fconfigure $data(socket) -sockname] 0]
	
	set lst [list 1:6 2:2 3:2 9:2]
	if {![string is false $data(-roster)]} {lappend lst 19:2}
	foreach cmd $lst { Command $name 2:$cmd {}}
	
	# upload lists
	#foreach x {all visible invisible} { UploadList $name $x }
	SendCaps $name
	Command $name 2:4:2 [bword 0][bdword 3][bword 8000 999 999 0 0]
	#after idle [nc Command $name 2:4:4 {}]
	SetStatus $name 
	# Set idle time
	#Command $name 2:1:17 [word 0 0]
	#Client ready
	Command $name 2:1:2 [byte 0 1 0 3 1 16 2 138 0 2 0 1 1 1 2 138 0 3 0 1\
			1 16 2 138 0 21 0 1 1 16 2 138 0 4 0 1 1 16 2 183 \
			0 6 0 1 1 16 2 183 0 9 0 1 1 16 2 183 0 10 0 1 1 16\
			2 183]

	Command $name 2:4:4 {}
	# Offline messages request
	SrvMessage $name 60 {}
}

# Client service parameters request
proc 2:2:3 {name packet} {
}

# Requested parameters info
proc 2:4:5 {name packet} {
	upvar #0 $name data
	match $packet {6 {bword channel} {bdword flags} 
	    {bword data(maxsize) sendLevel recvLevel interval unk}} 
	log $name notice "Channel $channel, Max size: $data(maxsize)" 
}

proc 2:9:3 {name packet} {
	match $packet {2 {bword req} {* packet}}
	if {$req==100} return
	upvar #0 $name data
	match $packet {{bword _ _ _ data(maxvisible) _ _ data(maxinvisible)}}
}

proc 2:3:1 {name packet} {
	match $packet {6 {bword reason}}
	log $name error "Error notification: $reason" 
}
# Buddy request
proc 2:3:3 {name packet} { 
	match $packet {6 {bword _ _ data(maxall)}}
	log $name info "Maximum number of contacts: $data(maxall)"
	UploadList $name all
}

# List service granted, request roster from server
proc 2:19:3 {name args} {
	upvar #0 $name data
	set data(roster_granted) 1
	if {[string is true $data(-roster)]} {
		Command $name 2:19:4 {} 
	} else {
		foreach {t c} $data(-roster) break
		if {[string is integer -strict $t]&&[string is integer $c]} {
			log $name debug "Request roster: [list $t $c]"
			Command $name 2:19:5 [bdword $t][bword $c]
		} else {
			return -code error "Time and count should be integer."
		}
	}
}

# Server-side roster matches local one
proc 2:19:15 {name packet} {
	match $packet {6 {bdword timestamp} {bword size}}
	event $name Roster:OK $timestamp $size
	log $name {info roster} "Roster is not changed: [list $timestamp $size]"
	# Request status of roster items after checking roster
	Command $name 2:19:7 {}
}

# Parse incoming server-side roster
proc 2:19:6 {name packet} {
	upvar #0 $name data
	match $packet {6 byte {bword count} {* packet}}
	set roster [list]
	for {} {$count>0} {incr count -1} {
		match $packet {{pstr item} {bword gid id type}
			{pstr tlv} {* packet}}
		set aux [lindex [scanTLV $tlv 100 roster] 0]
		if {!$type} {
			lappend aux group $gid
		} elseif {$type==1} { set id $gid }
		lappend roster [list [alias rtype $type] $id $item $aux]
	}
	match $packet {{bdword time}}
	# Update -roster parameter to avoid unneeded roster fetch next time
	set data(-roster) [list $time [llength $roster]]
	event $name Roster:Items [encoding convertfrom utf-8 $roster] $time
	log $name {debug roster} "Now roster is [list $data(-roster)]"
	log $name {info roster} "Roster was updated: [clock format $time -format {%x %X}]"
	# Request status of roster items after checking roster
	Command $name 2:19:7 {}
}
# Roster update ACK
proc 2:19:14 {name packet} {
	match $packet {6 {bword status}}
	event $name Roster:Update $status
}

proc 2:19:27 {name packet} {
	match $packet {{buin uin} {byte flag}}
	event $name Incoming authorization $uin [clock seconds]\
		[expr {($flag)?"granted":"denied"}]
}

proc 2:19:28 {name packet} {
	match $packet {{buin uin}}
	event $name Incoming included $uin [clock seconds] {}
}

# Error message
proc 2:1:1 {name args} { [set ::${name}(-event)] Error 2:0 }

array set miss_reasons {
	1 "Invalid SNAC header"
	2 "Server rate limit exceeded"
	3 "Client rate limit exceeded"
	3 "Recipient is not logged in"
	10 "Refused by client"
	11 "Reply too big"
	14 "Incorrect SNAC format"
	16 "Recipient is blocked"
	19 "Contact temporary unavailable"

}
# Error sending message to client
proc 2:4:1 {name packet} {
	match $packet {6 {bword code}}
	# Check if message should be re-sent
	if {[lsearch -exact {2 3 4} $code]!=-1} {
		upvar #0 $name-sent sent
		upvar #0 $name-spooler pool
		set msgid $pool(lastsent)
		if {[info exists sent($msgid)]} {
			log $name {error message} "Error $code when sending $msgid, re-send"
			foreach {type uin msg ack} $sent($msgid) break
			unset sent($msgid)
			Spool $name spooler [list $msgid $type $uin $msg\
				[expr $ack-2]] head
		}
	} else { 
		variable miss_reasons
		if {[info exists miss_reasons($code)]} {
			set reason $miss_reasons($code)
		} else { set reason "No decsription" }
		event $name Error message:$code $reason
	}
}

# Message Received
proc 2:4:7 {name packet} {
	match $packet {14 {bword Type} {buin Sender} word {TLV tlvs} {* other}}
	array set TLV $tlvs
	log $name {debug message} "Incoming message of type $Type from $Sender"
	if {[info exists TLV(EncodedMsg)]} { 
		Incoming $name $Sender [clock seconds] 13\
			[query $name encoding $Sender] $TLV(EncodedMsg) ""
		return
	} 
	match $other {{bword pref} {pstr rest} {* other}}
	if {$pref==4} {match $other {{bword pref} {pstr rest}}}
	set cmd [lindex [info level 0] 0]:$Type
	if {[llength [info procs $cmd]]} { $cmd $name $rest $Sender
	} else {log $name {warning message} "Unknown message type: $Type"}
}

# Message Received - Type 1
proc 2:4:7:1 {name packet uin} {
	match $packet {word pstr word {pstr msg}}
	match $msg {{bword flags flags2} {* msg}}
	log $name {debug message} "Type-1 message flags: $flags/$flags2"
	if {$flags==2 && $flags2==0} {
		set enc unicode
		set msg [swab $msg]
	} elseif {$flags=="3a" && $flags2==0} { set enc iso8859-1
	} else {set enc [query $name encoding $uin]}
	Incoming $name $uin [clock seconds] 1 $enc $msg ""
}

# Message Received - Type 4: service messages
proc 2:4:7:4 {name RawMessage uin} {
	match $RawMessage {4 {lword Sub} {lntsz msg} {* rest}}
	Incoming $name $uin [clock seconds] $Sub [query $name encoding $uin] $msg $rest
}

# Message Received - Type 5: new ICQ messages
proc 2:4:7:2 {name packet uin} {
	match $packet {{word ack} {dword time rid} {* rest}}
	if {$ack} {
		log $name {debug message} "Got ack from $uin in 2:4:7:2"
		return
	} else {match $rest {{cap c} {* rest}} }	
	array set TLV [lindex [scanTLV $rest 100 msg] 0]

	if {[string length $TLV(10001)]==27} {
		log $name {notice message} "Unknown message from $uin"
		return
	}
	match $TLV(10001) {{lnts aux1} {lword sign seq} 12 
		{lword type status prio} {lntsz msg} {* other}}
	if {$sign==18 && $msg==""} { 
		log $name {notice message} "Some kind of service message"
		return
	} 

	log $name {debug message} "Special type: $type, cap=[alias cap $c]"
	set acktype [Incoming $name $uin [clock seconds] $type \
	            [query $name encoding $uin] $msg $other FormatMessageAdv]
	# Shedule ACK
	if {[set ack [AutoACK $name $uin $seq $acktype]]==""} { 
		if {$acktype!=""} return
		set ack $TLV(10001) 
	}
	set ack [dword $time $rid][bword 2][buin $uin][lword 3]$ack
	Spool $name spooler [list $ack] head
}

array set autotypes {away 1000 busy 1001 na 1002 dnd 1003 ffc 1004 }

proc AutoACK {name uin seq {type ""}} {
	upvar #0 $name data
	variable autotypes
	if {$type==""} { set type [alias status $data(current_status)] }

	log $name {debug auto} "Check auto-message of type $type: [info exists autotypes($type)] [info exists data(-auto-$type)]"
	if {![info exists autotypes($type)] || 
	    ![info exists data(-auto-$type)] ||
	    $data(-auto-$type)==""} { return "" }
	log $name {debug auto} "Found"

	set ack [lnts [lword 8][dword 0 0 0 0][word 0][ldword 3][byte 0][lword $seq]]
	log $name {debug auto} "generate auto-$type message: $data(-auto-$type)"
	set enc [wireencoding $name $uin]
	append ack [MessageAdv $autotypes($type) 0 0 $seq\
		[ToWire $data(-auto-$type) $enc] [bdword 0 0xffffff00] $enc]
}

# Missed message
proc 2:4:10 {name packet} {
	variable miss_reasons
	match $packet {6 {* packet}}
	while {$packet!=""} {
		match $packet {{bword type} {buin uin} {word level} {TLV tlvs}
			{bword channel reason} {* packet} }
		if {[info exists miss_reasons($reason)]} {
			set reason $miss_reasons($reason)
		}
		event $name Missed $uin $reason $channel
	}
}

# Client acknowledgement
proc 2:4:11 {name packet} { 
	foreach {uin rest} [Acknowledgement $name client $packet] break
	# Check if this is auto message
	match $rest {{word reason} {lntsz aux1} {byte sign} 15 {lword type}
		{word status priority} {lntsz msg} {* other}}
	log $name {debug auto} "Ack message has type $type"	
	if {$type>=1000} {
		log $name {debug auto} "Got auto message from $uin"
		Incoming $name $uin [clock seconds] $type\
			[query $name encoding $uin] $msg $other FormatAuto
	}
}

# Server acknowledgement
proc 2:4:12 {name packet} { Acknowledgement $name server $packet}

proc Acknowledgement {name class packet} {
	match $packet {6 {ldword time rid} {bword type} {buin uin} {* other}}
	set msgid [format %08x:%08x $time $rid]
	log $name {debug message} "$class acknowledgement on $msgid from $uin"
	if {[clear $name $msgid]} { event $name ACK $class $uin $msgid }
	list $uin $other
}

# All ICQ-specific stuff not fitting to original OSCAR
proc 2:21:3 {name packet} {
	match $packet {{bword _ Ref} 8 {ldword MyUIN} 
		{lword MessageType} {* RawMessage}}
	switch -exact -- $MessageType {
		65 {  match $RawMessage {{bword flags} {ldword UIN} {lword Y} 
	       	         {byte M D H Mi Type _} {lntsz msg} {* rest}}
		      Incoming $name $UIN [clock scan "$M/$D/$Y $H:$Mi"\
		      	-gmt 1] $Type [query $name encoding $UIN] $msg $rest
		   }
		66 {  SrvMessage $name 62 {} 0
		      log $name {notice message} "Offline messages complete"
		      # Schedule re-transmit of unacknowledged messages
		      re-send $name
		      schedule $name idle spooler
		   }
	      2010 { 2:21:3:2010 $name $RawMessage $MyUIN $Ref}	
	   default { binary scan $RawMessage H* hex
	   	     log $name {error message} "UNKNOWN MESSAGE TYPE -----> $MessageType\n$hex"
		   }
	}
}

proc 2:21:3:2010 {name RawMessage MyUIN Ref} {
	upvar #0 $name data
	match $RawMessage {word {lword SubType} {byte result} {* RawMessage} }
	switch -glob -- $SubType:$result {
		*:50 { event $name SearchResults $Ref {}}
		*:20 { event $name SearchResults $Ref {}}
	      100:10 { event $name PersonalInfoUpdated $Ref Main}
	      120:10 { event $name PersonalInfoUpdated $Ref More}
	      130:10 { event $name PersonalInfoUpdated $Ref About}
	      170:10 { event $name PasswordChanged $Ref }
	      260:10 { log $name {info wp} "Short user info"
		       match $RawMessage {{lntsz i:Nick i:FirstName
			      i:LastName i:email}}
		     }
	      200:10 {	match $RawMessage {{lntsz i:Nick i:FirstName
			   i:LastName i:email i:City i:State i:Phone i:Fax 
			   i:Address i:Mobile i:Zip}
			   {lword i:Country} {byte i:TimeZone}}
		     }
	      235:10 {	match $RawMessage {{byte cnt} {* str}}
			for {set i 1} {$i<=$cnt} {incr i} {
				match $str [list byte [list lntsz i:email$i]\
			     			{* str}]
			}
			log $name {debug wp} "Extra emails: $cnt"
		     }
	      210:10 {	log $name {info wp} "User info work" }	     
	      220:10 {	match $RawMessage {{lword i:Age} {byte i:Sex} 
				{lntsz i:Homepage} {lword i:Year} 
				{byte i:Month i:Day i:Lang1 i:Lang2 i:Lang3}}
		     }
	      230:10 {	log $name {info wp} "User info about" 
	      		match $RawMessage {{lntsz i:About}}
	      }
	      240:10 {	log $name {info wp} "Personal interests"}
	      250:10 {	log $name {info wp} "Past interests"}
	  4[123]0:10 {	match $RawMessage {{lnts packet}}
	  		match $packet {{ldword i:UIN} {lntsz i:Nick
			  i:FirstName i:LastName i:email} {byte i:AuthRq}
			  {lword i:Status}}
			if {[info exists i:Status]} {
				set i:Status [lindex {offline online invisible}\
					${i:Status}]
			}
		     }
	      480:10 {	log $name {info wp} "User info unknown"}
	     2210:10 {	log $name {info xp} "XML" }
	        1:70 {  event $name Error meta $RawMessage }
	     default {  log $name {warning wp} "Unknown meta type $SubType:$result" }
	}
	set info [list]
	foreach x [info locals i:*] {
		lappend info [lindex [split $x :] 1] [FromWire [set $x] $data(encoding)]
	}
	if {[llength $info]} {
		switch -glob -- [expr $SubType/100] {
		   2 { event $name Info $Ref $info }
		   4 { event $name SearchResults $Ref $info }
		}     
	}
	# Send empty result to indicate end of search
	if {$SubType==430} { event $name SearchResults $Ref {} }
}

proc 2:23:1 {name packet} { 
	event $name RegistrationRefused 
}

proc 2:23:5 {name packet} {
	upvar #0 $name data
	binary scan $packet H* hex; log $name {error dump} "23:5: $hex"
	match $packet {10 {lnts content}}
	match $content {{ldword _ _ port ip _ _ _ _ _ _ uin}}
	CloseConnection $name
	event $name Registered $uin $data(password)
}

array set msgCodes {
	1 text 4 URL 5 authrequest 19 contacts
	6 authrequest 7 authorization 8 authorization
	12 included 13 web 1000 away 1001 busy 1002 na
	1003 dnd 1004 ffc
}
proc Incoming {name uin time code enc msg rest {formatter FormatMessage}} {
	foreach {type message} [$formatter $code $msg $rest $enc] break
	if {$type=="error"} {
		log $name {error message} "ERROR: $message"
	} elseif {$type=="autorequest"} {
		log $name {debug message} "$type message request via server"
		return $message
	} elseif {$type=="service"} {
		log $name {debug message} "$type message request via server, skipping"
	} else {
		log $name {debug message} "Message of subtype $code ($type)"
		log $name {debug message} "Data: $message"
		if {$type=="text"} { 
			set message [glue $name $message $uin]
		}
		event $name Incoming $type $uin $time $message
	}
	return ""
}

proc FormatMessage {code msg other enc} {
	if {![info exists icq::msgCodes($code)]} { 
		return [list error "Unknown message code $code"]
	}
	if {$code!=1} { set msg [split $msg $icq::delim] }
	set msg [FromWire $msg $enc]
	if {$code==8} {set msg "granted"}
	if {$code==7} {set msg "denied"}
	if {$code==13} {
		foreach {nick _ _ mail _ msg} $msg break
		set msg [split $msg "\n"]
		set ip [string trim [lindex [split [lindex $msg 0] :] 1]]
		set uin [list $nick $mail $ip]
		set msg [join [lrange $msg 1 end] "\n"]
	}
	if {$code==19} { set msg [lrange $msg 1 end-1] }
	if {$code>=1000} {
		 list autorequest $icq::msgCodes($code)
	} else { list $icq::msgCodes($code) $msg }
}

proc FormatMessageAdv {type msg other enc} {
	set type [expr {$type & 0x7FFF}]
	if {$type==26} {
		variable alias
		match $other {{lnts header} {dstr content}}
		match $header {16 {word mtype} {dstr descr}}
		match $content {{dstr msg}}
		if {[info exists alias(type:$descr)]} {
			set type $alias(type:$descr)
			return [FormatMessage $type $msg "" utf-8]
		} else {
			return [list error "Unknown ext message type: $descr"]
		}	
	} elseif {$msg!={}} {
		if {$type==1} { match $other {{dword fg bg} {* other}} }
		if {[string length $other]>14 } {
			match $other {{dstr guid}}
			match $guid {{guid c}}
			if {$c=={UTF8}} {set enc utf-8}
		} elseif {$other!=""} { return [list service $msg] }
	}	
	FormatMessage $type $msg "" $enc
}

# Formatter of auto messages: treat message as text, return auto status always
proc FormatAuto {type msg other enc} {
	foreach {type msg} [FormatMessageAdv 1 $msg $other $enc] break
	list auto $msg
}

proc glue {name msg uin} {
	upvar #0 $name data
	variable glue
	set len [string length $glue]
	set prev ""
	if [info exists data(inc:$uin)] {set prev $data(inc:$uin) }
	if [string match ${glue}* $msg] {
		set msg ${prev}[string range $msg $len end]
	} elseif {$prev!=""} {
		log $name {warning message} "Incomplete complex message from $uin"
		event $name Incoming text $uin [clock seconds] $prev
	}
	if [string match *${glue} $msg] {
		set data(inc:$uin) [string range $msg 0 end-$len]
		set command [nc glue_outdated $name $uin]
		after cancel $command
		after $data(-glue-timeout) $command
		return -code return
	} 
	if [info exists data(inc:$uin)] { unset data(inc:$uin) }
	set msg 
}

proc glue_outdated {name uin} {
	upvar #0 $name data
	if [info exists data(inc:$uin)] {
		log $name {warning message} "Outdated complex message from $uin"
		event $name Incoming text $uin [clock seconds] $data(inc:$uin) 
		unset data(inc:$uin)
	}
}
# End of server messages handlers 

# Client commands
proc Register {name password} {
	set sequence [byte 0 0 0 0 0x28 0 3 0 0 0 0 0 0 0 0 0 0x9e 0x27 0 0\
		0x9e 0x27 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\
		0 0][lntsz $password][byte 0x9e 0x27 0 0 0 0 0 0 3 2]
	Packet $name 1 [bdword 1]
	Command $name 2:23:4 [bword 1][pstr $sequence]
}

proc message {type cmd msgid uin val} {
	# Map type to corresponding code
	set fmt [expr {([query $cmd relay $uin]==1)?2:4}]
	set enc utf-8
	if {$fmt==4 || ![query $cmd unicode $uin]} {
		set enc [query $cmd encoding $uin]
	}
	log $cmd {info message} "Message $msgid to $uin: format $fmt, enc: $enc"
	if {$fmt==4 && $type==1} {set fmt 1}
	# Add length and empty field for contacts list
	if {$type==19} { set val [concat [expr [llength $val]/2] $val {{}}] }
	set val [ToWire $val $enc]
	if {$type!=1} { set val [join $val $icq::delim] }
	
	foreach {time click} [split $msgid :] break
	set id [ldword 0x${time} 0x${click}]
	Command $cmd 2:4:6 [set id][bword $fmt][buin $uin][message$fmt\
		$cmd $type $val $id $enc][bword 6 0]
}

# Type 1: Simple message
proc message1 {cmd type msg args} { 
	TLV msg 2 [byte 5 1 0 1 1 1 1][pstr [dword 0]$msg] 
}
# Type 4: Different kinds of messages
proc message4 {cmd type msg args} {
	upvar #0 $cmd data
	TLV msg 5 [ldword $data(uin)][lword $type][lntsz $msg]]
}
# Type 2: Different kinds of messages, UTF-8
proc message2 {cmd type msg id enc} {
	upvar #0 $cmd data
	set seq [incr data(counter) -1]
	if {!$data(counter)} { set data(counter) 0xFFFF }
	set header [word 0][set id]
	if {$type==1} { set ext [bdword 0 0xffffff00] } else { set ext "" }
	set aux [lnts [lword 8][dword 0 0 0 0][word 0][ldword 3][byte 0][lword $seq]]
	append aux [MessageAdv $type 0 0 $seq $msg $ext $enc]
	TLV msg 5 ${header}[cap RELAY][TLV msg 10 1 15 {} 10001 $aux]
}

proc MessageAdv {type status flags seq msg ext enc} {
	set res [lnts [lword $seq][dword 0 0 0]][lword\
		$type $status $flags][lntsz $msg][set ext]
	if {$enc=="utf-8"} {append res [dstr [guid UTF8]]}
	set res
}

proc send_authorization {cmd msgid uin msg} {
	array set auth {deny 0 grant 1}
	if {![info exists auth($msg)]} {
		return -code error "Wrong authorization message"
	}
	Command $cmd 2:19:26 [buin $uin][byte $auth($msg) 0 0 0 0]
}
proc send_authrequest {cmd msgid uin message} {
	Command $cmd 2:19:24 [buin $uin][pstr [ToWire\
		$message [query $cmd encoding $uin]]][word 0]
}

proc send_futureauth {cmd msgid uin message} {
	Command $cmd 2:19:20 [buin $uin][pstr [ToWire\
		$message [query $cmd encoding $uin]]][word 0]
}

proc send_SMS {cmd msgid recipient msg} {
	upvar #0 $cmd data
	set time [clock format [clock seconds] -format "%a, %d %b %Y %H:%M:%S GMT"\
		-gmt yes]
	set message "<icq_sms_message>
			<destination>${recipient}</destination>
			<text>[encoding convertto utf-8 $msg]</text>
			<codepage>utf-8</codepage>
			<senders_UIN>${data(uin)}</senders_UIN>
			<senders_name>Alicq</senders_name>
			<delivery_receipt>Yes</delivery_receipt>
			<time>${time}</time>
		     </icq_sms_message>"
	SrvMessage $cmd 2000 [lword 5250][bword 1 22 0 0 0 0 0 0 0 0 0][lntsz\
		$message] 101
}

proc UpdateRoster {name params} {
	if {![llength $params]} return
	# Start update of server-side roster
	Spool $name roster [list 2:19:17 {}]
	# Proceed arguments as action-item pairs
	foreach {action x} [encoding convertto utf-8 $params] {
		foreach {type id item aux} $x break
		set t [alias rtype $type]
		if {![string is integer $t]} {
			log $name {error roster} "skipping - wrong type"
			continue
		}
		set c [alias raction $action]
		if {$c==$action} {
			log $name {error roster} "skipping - wrong action $action"
			continue
		}
		set group 0
		# For buddy extract group from aut info and exclude it
		# from aux list. For group record id is group actually.
		if {!$t} {
			if {[set pos [lsearch $aux group]]!=-1} {
				set group [lindex $aux [expr $pos+1]]
				set aux [lreplace $aux $pos [expr $pos+1]]
			}
		} elseif {$t==1} {
			set group $id
			set id 0
		}

		set cmd [pstr $item][bword $group $id $t][pstr\
			[eval TLV roster $aux]]
		Spool $name roster [list $c $cmd]
	}
	# Update is finished
	Spool $name roster [list 2:19:18 {}]
}

proc roster {name item} {
	foreach {cmd val} $item break
	Command $name $cmd $val
	return 1
}

proc UploadList {name type {action add} {items {}}} {
	upvar #0 $name data
	set pkg ""
	if {![llength $items]} { set items $data(list_$type) }
	foreach x $items { append pkg [buin $x] }
	if {$pkg!=""} { Command $name $icq::ListCmd($type,$action) $pkg }
}

proc SetStatus {name} {
	upvar #0 $name data
	set flags [expr {[llength $data(-dcinfo)]?0x2000:0x100}]
	set status [expr ($flags<<16)+$data(status)]
	# Check for invisible mode change. In this case proper lists should
	# be re-loaded
	if {$data(status)==0x100 && $data(current_status)!=0x100} {
		UploadList $name visible
	} elseif {$data(current_status)==0x100 && $data(status)!=0x100 ||
		  $data(current_status)=="offline"} {
		UploadList $name invisible
	}
	Command $name 2:1:30 [TLV 2 Status $status ErrCode 0\
		LanDetails [LanDetails $data(local_ip) $data(-dcinfo)]]
}
# Calculate LanDetails TLV for extended status
proc LanDetails {ip dcinfo} {
	if {[llength $dcinfo]} {
		foreach {port cookie version} $dcinfo break
		set addr 0
		foreach octet [split $ip .] {set addr [expr $addr*256+$octet] }
		set type 2
	} else { 
		foreach x {addr port cookie type} { set $x 0 } 
		set version 8
	}
	foreach {vmaj vmin vrel} [split [package present icq] .] break
	binary format IIcSISSSSIIIS $addr $port $type $version $cookie 0 0x50 0\
		3 0xffffffbe 0x[format %02x%02x%02x%02x $vmaj $vmin $vrel 0] 0 0
}

proc SendCaps {name} {
	upvar #0 $name data
	foreach x $data(-capabilities) {
		if {![catch {set x [cap $x]}]} { append caps $x }
	}
	Command $name 2:2:4 [TLV 1 UserInfo $caps]
}

proc Search {name SearchList {id 204}} {
	upvar #0 $name data
	array set Attrs $SearchList
	set en $data(encoding)
	set sub 1331
	foreach {formatter item} {lntsz FirstName lntsz LastName
			lntsz Nick lntsz Email lword MinAge lword MaxAge
			byte Sex byte Language lntsz City lntsz State
			lword Country lntsz CompanyName lntsz CompanyDep 
			lntsz CompanyPos byte CompanyOcc bword PastInfoCat
			lntsz Interests lword OrgCat lntsz OrgDesc
			bword HomepageCat lntsz Homepage byte OnlineOnly} {
		if {![info exists Attrs($item)]} {set Attrs($item) {}}
		if {$formatter=="lntsz"} {
			append search_rq [$formatter [ToWire $Attrs($item) $en]]
			if {[string first "*" $Attrs($item)]!=-1} {set sub 1361}
		} else { 
			if {$Attrs($item)=={}} {set Attrs($item) 0}
			append search_rq [$formatter $Attrs($item)]
		}
	}
	SrvMessage $name 2000 [lword $sub]$search_rq $id
	unset Attrs search_rq
}

proc UpdateInfo {name Info {id 205}} {
	upvar #0 $name data
	array set Attrs $Info
	set en $data(encoding)
	foreach {formatter var item} { lntsz main Nick lntsz main FirstName 
		lntsz main LastName lntsz main email lntsz main City 
		lntsz main State lntsz main Phone lntsz main Fax 
		lntsz main Street lntsz main Mobile lntsz main Zip 
		lword main Country byte main TimeZone byte main PublishEmail
		byte more Age byte more Unk byte more Sex lntsz more Homepage
		lword more Year byte more Month byte more Day byte more Lang1
		byte more Lang2 byte more Lang3 lntsz about About} {
		if {![info exists Attrs($item)]} {set Attrs($item) {}}
		if {$formatter=={lntsz}} {
			append info($var) [$formatter [ToWire $Attrs($item) $en]]
		} else { 
			if {$Attrs($item)=={}} {set Attrs($item) 0}
			append info($var) [$formatter $Attrs($item)]
		}
	}
	foreach {item cmd} {main 1002 more 1021 about 1030} {
		SrvMessage $name 2000 [lword $cmd]$info($item) $id
	}	
	unset Attrs
}

proc SrvMessage {name cmd packet {id 2}} { 
	upvar #0 $name data
	Command $name 2:21:2 [TLV srv 1 [lnts [ldword $data(uin)][lword $cmd][lword $id]$packet]] $id 
}

# End of client commands

# Helper functions

# Handle keepalive requests
proc keepalive {name} {
	upvar #0 $name data
	if {![info exists data] || !$data(-keepalive)} return
	if {[info exists data(socket)]} { Packet $name 5 }
	after [expr $data(-keepalive)*1000] [nc keepalive $name]
}

# Send ping requests periodically
proc ping {name} {
	variable timeout
	upvar #0 $name data
	if {![info exists data] || !$data(-ping)} return
	if {$data(current_status)!="offline"} {
		if {![info exists data(mark)]} {
			log $name {notice network} "Ping timeout, reconnecting..."
			CloseConnection $name $timeout(ping)
		} else { unset data(mark) }
		# Send privacy info request packet as ping
		Command $name 2:9:2 {} 100
	}	
	after [expr $data(-ping)*1000] [nc ping $name]
}

proc FromWire {text enc} {
	regsub -all {\r\n} [encoding convertfrom $enc $text] \n text
	set text
}
proc ToWire {text enc} {
	regsub -all {[\r\n]} [encoding convertto $enc $text] \r\n text
	set text
}

proc query {name k {uin {}}} {
	upvar #0 $name data
	if {[info exists data($uin-$k)]} {set data($uin-$k)} else {set data($k)}
}

# Detect encoding used to send message to recipient
proc wireencoding {cmd uin} {
	if {![query $cmd unicode $uin]} {
		return [query $cmd encoding $uin]
	} else { return "utf-8" }
}

proc Packet {name channel {Data {}}} {
	upvar #0 $name data
	incr data(SeqNum)
	if { $data(SeqNum)>65535 } { set data(SeqNum) 0 }
	Send $name [byte 42 $channel][bword $data(SeqNum)][pstr $Data]
}

proc Connect {name Server Port} {
	variable timeout
	upvar #0 $name data
	CloseConnection $name
	log $name {info network} "Connecting to $Server:$Port"
	if {$data(-proxy)!={}} { 
		::proxy::connect $data(-proxy) $Server $Port\
			[nc ConfigureSocket $name]\
			[nc ProxyError $name $data(-proxy)] [nc log $name]
	} elseif { [catch {
		     ConfigureSocket $name [socket -async $Server $Port]
		 }] } { 
		 	event $name Error:host "Unknown host"
			CloseConnection $name $timeout(host)
		      }
}

proc ConfigureSocket {name sock} {
	upvar #0 $name data
	set data(socket) $sock
	fconfigure $data(socket) -blocking no -translation binary -buffering none
	fileevent $data(socket) readable [nc ReadData $name]
	log $name {info network} "Host resolved, establishing connection..."
}

proc ProxyError {name proxy code descr} {
	variable timeout
	event $name Error:proxy:$code $proxy $descr
	if {$code!="auth"} { 
		CloseConnection $name $timeout(proxy) 
	} else { sub_status $name offline }
}

proc CloseConnection {name {timeout ""}} {
	upvar #0 $name data
	if {[info exists data(socket)]} {
		log $name {info network} "Closing socket"
		fileevent $data(socket) readable {}
		close $data(socket)
		unset data(socket)
	}
	if {[info exists data(packet)]} {unset data(packet) }
	if {[info exists data(mark)]} {unset data(mark)}
	set data(wantBody) 0
	set data(Length) 6
	if {$data(current_status)!="offline"} {
		set data(current_status) offline
		event $name MyStatus offline
	}
	if {[info exists data(reconnect_handle)]} {
		after cancel $data(reconnect_handle)
		unset data(reconnect_handle)
	}
	if {$timeout!=""} {
		if {[string is true $data(-reconnect)]} {
		   set data(reconnect_handle) [after $timeout\
			[nc Connect $name $data(-server) $data(-port)]]
		} else { set data(status) offline }
	}
}

# Spooler is procedure which shedules and manages sending of messages
# to receiver. 
#  ------ new version of spooler
proc Spool {cmd name item {where tail}} {
	upvar #0 $cmd-$name pool
	if {![info exists pool(queue)]} { set pool(queue) [list] }
	if {$where=="tail"} {
		lappend pool(queue) $item
	} elseif {$where=="head"} {
		set pool(queue) [concat [list $item] $pool(queue)]
	} else { return -code error "unknown point $where" }
	# If spooling is already sheduled, exit
	if {![info exists pool(after)]} { spool $cmd $name }
}

proc schedule {cmd time name} {
	upvar #0 $cmd-$name pool
	if {[info exists pool(after)]} { 
		after cancel $pool(after)
	}
	set pool(after) [after $time [nc spool $cmd $name]]
}

proc spool {cmd name} {
	upvar #0 $cmd data
	upvar #0 $cmd-$name pool
	if {[info exists pool(after)]} { 
		after cancel $pool(after)
		unset pool(after)
	}
	foreach x {queue win current alert ltime max} {
		if {![info exists pool($x)]} return
	}
	if {![llength $pool(queue)]} return

	set now [now]
	set delta [delta $cmd $name $now]
	if {$delta!="max"} {
		set safe [expr {($delta<1000)?1000:[safe $cmd $name]}]
		if {$safe>$delta} {
			set next [expr $safe-$delta]
			log $cmd debug "Re-scheduling to $next"
			schedule $cmd $next $name
			return
		}
	}

	if {![$name $cmd [lindex $pool(queue) 0]]} return
	set pool(queue) [lrange $pool(queue) 1 end]
	set pool(current) [level $cmd $name $delta]
	set pool(ltime) $now
	log $cmd debug "Current level $pool(current)"
	schedule $cmd idle $name
}

# Get current time with milliseconds precision
proc now {} { list [clock seconds] [clock clicks -milliseconds] }

proc safe {cmd name} {
	upvar #0 $cmd-$name pool
	expr ($pool(clear)-$pool(current)*($pool(win)-1)/$pool(win))*$pool(win)
}

proc level {cmd name delta} {
	upvar #0 $cmd-$name pool
	if {$delta=="max"} { return $pool(max) }
	set level [expr {$pool(current)*($pool(win)-1)/$pool(win)+$delta/$pool(win)}]
	expr {($level>$pool(max))?$pool(max):$level}
}	

proc delta {cmd name now} {
	upvar #0 $cmd-$name pool
	set major [expr {[lindex $now 0]-[lindex $pool(ltime) 0]}]
	set minor [expr {[lindex $now 1]-[lindex $pool(ltime) 1]}]
	if {$major < $pool(win)*$pool(max)/1000} { 
		expr { $major*1000+$minor%1000 }
	} else { set _ max }
}

# Perform actual spooling
proc spooler {cmd packet} {
	upvar #0 $cmd data
	upvar #0 $cmd-spooler pool
	upvar #0 ${cmd}-sent sent
	if {$data(current_status)=="offline"} { return 0 }
	# Check if it ACK
	if {[llength $packet]==1} {
		Command $cmd 2:4:11 [lindex $packet 0]
		return 1
	}
	foreach {msgid type uin msg is_rest} $packet break
	# Do not try to split messages which are being re-send after error.
	if {$is_rest<0} {
		set chunk $msg
		set msg ""
		set ack [expr $is_rest+2]
		log $cmd debug "Spool: resend $msgid with ack=$ack"
	} else { 
		foreach {chunk msg} [splitter $cmd $msg $uin $is_rest] break
		# If rest of message is being unsent, make new message id for
		# current chunk and mark it non-ACKable
		if {$msg!=""} {
			set pool(queue) [concat [list $packet [list $msgid\
				$type $uin $msg 1]] [lrange $pool(queue) 1 end]]
			set msgid [msgid]
			set ack 0
		} else { set ack 1 }
	}
	
	set pool(lastsent) $msgid
	send_$type $cmd $msgid $uin $chunk
	# All sent messages placed to sent array. Type-2 will be deleted
	# from there when they acknowledged, other - on timeout
	set sent($msgid) [list $type $uin $chunk $ack] 
	if {[query $cmd relay $uin]!=1} {
		# Dirty workaround for invisible contacts
		set mul [expr {([query $cmd relay $uin]==-1)?3:1}]
		after [expr $mul*$pool(clear)] [nc clear $cmd $msgid]
	}
	if {$ack} {event $cmd ACK sent $uin $msgid}
	return 1
}

# Remove chunk from the sent array, returning ack flag of sent message
proc clear {cmd msgid} {
	upvar #0 ${cmd}-sent sent
	if {[info exists sent($msgid)]} {
		set ack [lindex $sent($msgid) end]
		unset sent($msgid)
	} else {set ack 0}
	#schedule $cmd idle spooler
	set ack
}

# Get chunk of the message to send
# Returns list of two elements: chunk and rest of message
proc splitter {cmd msg uin {complex 0}} {
	upvar #0 $cmd data
	variable glue
	# Detect encoding used to send message to recipient
	set enc [wireencoding $cmd $uin]
	# Detect maximal size of message in bytes allowed now for uin
	#set max [expr {[query $cmd relay $uin]?65336:400}] 
	set max [expr {$data(maxsize)-(([query $cmd relay $uin]==1)?200:100)}]
	# Get message chunk
	set chunk [encoding convertfrom $enc\
		[string range [encoding convertto $enc $msg] 0 $max]]
	set len [expr [string length $chunk]-1]
	# Check if last multibyte charatcter is complete
	if {[string index $chunk $len]!=[string index $msg $len]} {
		incr len -1
		set chunk [string range $chunk 0 end-1]
	}
	set msg [string range $msg [expr $len+1] end]
	if {$complex} { set chunk ${glue}${chunk} }
	if {$msg!=""} {append chunk $glue}
	list $chunk $msg
}

# This procedure should be invoked when changing status from offline
# It checks if unacknowledged messages exist in send array and moves them
# to the spooler again
proc re-send {cmd} {
	upvar #0 $cmd-spooler pool
	upvar #0 ${cmd}-sent sent
	if {![info exists sent]} return
	set lst [list]
	foreach msgid [lsort [array names sent]] {
		foreach {type uin msg ack} $sent($msgid) break
		lappend lst [list $msgid $type $uin $msg 0] 
		log $cmd debug "re-sending $msgid: $msg"
	}
	if {[llength $lst]} { 
		if {![info exists pool(queue)]} {set pool(queue) [list]}
		set pool(queue) [concat $lst $pool(queue)] 
	}
	unset sent
}

# end of new spooler code

proc Send {name packet} {
	upvar #0 $name data
	if {![info exists data(socket)]} return
	if 0 {
		binary scan $packet H* hex
		log $name {debug dump} "-> $hex"
		if {[catch { puts -nonewline $data(socket) $packet } v]} { 
			after idle [nc event $name Error send $v]
		} 
	} else {
		if {![info exists data(queue)]} {
			fileevent $data(socket) writable [nc WriteData $name]
		}
		lappend data(queue) $packet
	}
}

proc EncryptPassword {pwd} {
	if {$pwd==""} { return "" }
	binary scan $pwd c* pwd
	foreach x $pwd y {243 38 129 196 57 134 219 146 113 163 185 230 83\
		122 149 124} { lappend z [expr {($x!="")?($x^$y):[break]}] }
	binary format c* $z
}

# Make proper SNAC header
proc SNAC {Family Sub FlagA FlagB ReqId} {
	binary format SSccSS $Family $Sub $FlagA $FlagB $ReqId $Sub
}

proc Command {name Cmd Data {ReqId 0}} {
	foreach {ChanId Family SubFamily} [split $Cmd :] break
	Packet $name $ChanId [SNAC $Family $SubFamily 0 0 $ReqId]${Data}
}

proc nc {args} { namespace code $args }
proc alias {key val} {
	variable alias
	if {[info exists alias($key:$val)]} {set val $alias($key:$val)}
	set val
}
# UCS-2BE support appeared in Tcl 8.4 only, so handle this encoding manually
# by converting into UCS-2LE
proc swab {str} {
	binary scan $str s* str
	binary format S* $str
}
# ICQ Types 
# New typingG procs
# Generic string with length at the beginning template 
proc genstr.s {type val} {binary format ${type}a* [string length $val] $val}
proc genstr.g {type str} {
	binary scan ${str}a* $type len str
	binary scan $str ${type}a${len}a* _ res tail
	list $res $tail
}
# string with zero at the end, having length in the beginning (word)
proc lntsz.set {val} { lnts.set "$val\0" }
proc lntsz.get {str} {
	set r [lnts.get $str]
	list [string range [lindex $r 0] 0 end-1] [lindex $r 1]
}
# Intergal types (those supported by ``binary'' command) template
proc getintegral {spec str} {
	binary scan $str ${spec}a* res other
	list $res $other
}
proc integral {spec args} { binary format ${spec}* $args }
# Capability: 16-byte hex value
proc cap.get {str} { 
	binary scan $str H32a* res str
	list [alias cap $res] $str
}
proc cap.set {val} { binary format H32 [alias cap $val]}
# Capability in the 'cacnonical' form
proc guid.get {str} { alias cap [string tolower [string map {\{ {} \} {} - {}} $str]] }
proc guid.set {val} {
	set val [alias cap $val]
	string toupper "{[string range $val 0 7]-[string range $val 8 11]-[string range $val 12 15]-[string range $val 16 19]-[string range $val 20 end]}"
}

# Get TLVs of channel 2
proc TLV.get {str} {
	binary scan $str Sa* count str
	scanTLV $str $count 2
}

# Build binary packed list of TLVs
proc TLV {channel args} {
	variable tlvSpec
	set res {}
	foreach {tag value} $args {
		if {![string is integer $tag]} { set tag [alias $channel $tag]}
		if {![string is integer $tag]} continue
		if {[info exists tlvSpec($channel:$tag)]} {
			 set spec $tlvSpec($channel:$tag)
		} else { set spec a* }
		set p [binary format $spec $value]
		append res [binary format SS $tag [string length $p]]$p
	}
	set res
}

# Get list of TLVs as pair-volume list
proc scanTLV {str count channel} {
	variable tlvSpec
	for {set res [list]} {$count && $str!={}} {incr count -1} {
		binary scan $str SSa* tag len str
		binary scan $str a${len}a* value str
		if {[info exists tlvSpec($channel:$tag)]} {
			binary scan $value $tlvSpec($channel:$tag) value
		}
		lappend res [alias $channel $tag] $value
	}
	list $res $str
}

proc *.get {val} { list $val {} }

proc match {str spec} {
	foreach item $spec {
		set type [lindex $item 0]
		if {[string is integer $type]} {
			binary scan $str @${type}a* str
			continue
		}
		if {![llength [info commands ${type}.get]]} {
			return -code error "Unknown type $type"
		}
		set vars [lrange $item 1 end]
		if {![llength $vars]} { set vars [list {}] }
		foreach v $vars {
			upvar $v res
			foreach {res str} [${type}.get $str] break
		}
	}
}
# Make aliases for type creation procs
proc inject {cmd res args} {
	foreach x $args { append res [$cmd $x] }
	set res
}

proc IP {ip} {
	format "%d.%d.%d.%d" [expr ($ip>>24)&255] [expr ($ip>>16)&255] [expr ($ip>>8)&255] [expr $ip&255]
}

proc init {} {

	package provide icq 0.8.9
	foreach {type code} {text 1 URL 4 contacts 19 away 1000 occ 1001 na 1002 dnd 1003 ffc 1004 } {
		interp alias {} ::icq::send_$type {} ::icq::message $code
	}
        foreach x {ping keepalive} {
        	interp alias {} ::icq::valid-$x {} ::icq::Timer $x
        } 
	# Spawn set of aliases to represent differnet kinds of strings
	foreach {name type} {buin c lnts s pstr S dstr i} {
        	interp alias {} ::icq::${name}.set {} ::icq::genstr.s $type
	        interp alias {} ::icq::${name}.get {} ::icq::genstr.g $type
	}
	# Spawn set of aliases to simplify setting several values of same type
	foreach item [info commands *.set] {
        	interp alias {} ::icq::[string range $item 0 end-4] {} ::icq::inject $item {}
	}
	# Spawn set of aliases to represent intergal types: word, dword, byte etc
	foreach {key val} {byte c word s lword s bword S dword i ldword i bdword I} {
        	interp alias {} ::icq::$key {} ::icq::integral $val
	        interp alias {} ::icq::$key.get {} ::icq::getintegral $val
	}
	# Create template of login TLV
	foreach {key val} {
		ClientProfile {ICQ Inc. - Product of ICQ (TM).2003b.5.56.1.3916.85}
		ClientType 266 VersionMaj 5 VersionMin 56 IcqNumber 1
		BuildMaj 3916 BuildMin 85 Language en Country us} {
			append loginTLV [TLV 1 $key $val]
	}
}

}
