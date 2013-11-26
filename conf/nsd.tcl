# All commented modules are required by OSSMON
ns_section      ns/server/ossweb/modules
ns_param        nsdb            	nsdb.so
ns_param        nscp            	nscp.so
ns_param        nssock          	nssock.so
ns_param        nslog           	nslog.so
ns_param        nscgi			nscgi.so
#ns_param        nsgdchart		nsgdchart.so
#ns_param        nsexpat           	nsexpat.so
#ns_param        nsdns           	nsdns.so
#ns_param        nsimap			nsimap.so
#ns_param        nssnmp			nssnmp.so
#ns_param        nsicmp			nsicmp.so
#ns_param        nsudp			nsudp.so
#ns_param        nssys			nssys.so
ns_param        ossweb			Tcl

ns_section      ns/server/ossweb/ossweb
ns_param	server:database		ossweb
ns_param	security:filter:list	"/ossweb/* secure"
ns_param	server:development	t
ns_param	server:debug		t

ns_section	ns/parameters
ns_param	user			nobody
ns_param	group			nobody
ns_param	logdebug		false
ns_param	logroll			true
ns_param	jobtimeout		300
ns_param	smtphost		localhost
ns_param	smtptimeout		180

ns_section	ns/threads
ns_param	stacksize		[expr 256*1024]

ns_section	ns/mimetypes
ns_param	default         	text/plain
ns_param	noextension     	text/plain

ns_section	ns/db/drivers
ns_param        postgres        	nsdbpg.so

ns_section	ns/db/pools
ns_param	ossweb			"OSSWEB Database"

ns_section      ns/db/pool/ossweb
ns_param        driver          	postgres
ns_param        connections     	64
ns_param	user			postgres
ns_param        datasource      	"::ossweb"
ns_param	verbose			Off
ns_param	logsqlerrors		On
ns_param	extendedtableinfo	On
ns_param        maxidle                 31536000
ns_param        maxopen                 31536000

ns_section	ns/servers
ns_param	ossweb			"OSSWEB"

ns_section	ns/server/ossweb
ns_param	globalstats     	true
ns_param	urlstats        	true
ns_param	maxurlstats     	1000
ns_param        checkmodifiedsince      true
ns_param	maxthreads		100
ns_param	maxconnections		100
ns_param	threadtimeout		1800

ns_section	ns/server/ossweb/db
ns_param	pools			*

ns_section	ns/server/ossweb/fastpath
ns_param	pagedir			pages
ns_param	directoryfile		"index.adp index.tcl index.html index.htm"
ns_param	directoryproc   	_ns_dirlist
ns_param	directorylisting 	fancy

ns_section	ns/server/ossweb/adp
ns_param	map             	"/*.adp"
ns_param	enableexpire    	false
ns_param	enabledebug     	false
ns_param	enabletclpages  	true
ns_param	cache			false

ns_section	ns/server/ossweb/tcl
ns_param	debug			false
ns_param	nsvbuckets		16

ns_section      ns/server/ossweb/vhost
ns_param        enabled                 false
ns_param        hostprefix              ""
ns_param        hosthashlevel           0
ns_param        stripport               true
ns_param        stripwww                true

ns_section      ns/server/ossweb/module/nscgi
ns_param        map                     "GET  /cgi-bin /usr/local/ns/cgi-bin"
ns_param        map                     "POST /cgi-bin /usr/local/ns/cgi-bin"
ns_param        interps                 interps

ns_section	ns/server/ossweb/module/nslog
ns_param	file			access.log
ns_param	rolllog         	true
ns_param	rollonsignal    	false
ns_param	rollhour        	0
ns_param	maxbackup       	7

ns_section      ns/server/ossweb/module/nssock
ns_param        port                    8080
ns_param	address			0.0.0.0
ns_param        hostname                [ns_info hostname]

ns_section      ns/server/ossweb/module/nsudp
ns_param        port                    8080
ns_param	address			0.0.0.0

ns_section      ns/server/ossweb/module/nscp
ns_param        port            	2080
ns_param        address         	127.0.0.1

ns_section 	ns/server/ossweb/module/nscp/users
ns_param        user            	"::"

ns_section      ns/server/ossweb/module/nsdns
ns_param        port                    0

ns_section      ns/server/ossweb/module/nssnmp
ns_param        trap_port               1162
ns_param        trap_address            0.0.0.0
ns_param        trap_proc               ossmon::trap::process

ns_section      ns/server/ossweb/module/nsicmp
ns_param	sockets			10

