-include Makefile.ossweb

# Core required modules
core_modules = ossweb js css index images styles pub main admin bin \
	       conf doc

# Modules with Web interface
web_modules = calendar contact bookmarks problem weather webmail forum \
	      album news ossmon shopping tvguide print currency webcam \
	      movie music radio timesheet reports

# Modules without Web interface
other_modules = sso im mstream wiki external

# Versions of PostgreSQL and Tcl for automatic installs
pg_ver = 8.2.4
tcl_ver = 8.4.14

dbname ?= ossweb

modules ?= $(core_modules) $(web_modules) $(other_modules)

all:

cleanup:
	rm -rf tmp
	for d in ${modules}; do ${MAKE} -C $$d clean; done

links:
	-if [ -d ${pwd}/index ]; then ${install_link} index/index.adp; fi
	for d in ${modules}; do ${MAKE} -C $$d install_links; done

install_db:
	for d in ${modules}; do ${MAKE} -C $$d install_sql dbname=$(dbname); done

install:
	for d in ${modules}; do ${MAKE} -C $$d install dbname=$(dbname); done

install_copy:
	for d in ${modules}; do ${MAKE} -C $$d install_copy; done

copy:
	for d in ${modules}; do ${MAKE} -C $$d install_copy; done

convert:
	for d in ${modules}; do (cd $$d && ../bin/osswebconv.sh $(from) $(to)); done

propset:
	for d in ${modules}; do (cd $$d && svn propset svn:keywords "Id Rev" *.tcl); done

install_world:  install_nsd create_db install_db install

install_core_world:  install_nsd create_db install_core

install_core:
	for d in ${core_modules}; do ${MAKE} -C $$d install_sql dbname=$(dbname); done
	for d in ${core_modules}; do ${MAKE} -C $$d install dbname=$(dbname); done

install_nsd:
	cvs -d:pserver:anonymous@naviserver.cvs.sourceforge.net:/cvsroot/naviserver login
	cvs -z3 -d:pserver:anonymous@naviserver.cvs.sourceforge.net:/cvsroot/naviserver co -P naviserver modules && \
	cp -f doc/src/* naviserver/doc/src && \
	(cd naviserver && ./autogen.sh --prefix $(prefix) --enable-symbols --disable-tclvfs $(configure) && make install); \
	(cd modules && make install)

install_tcl:
	wget -c ftp://ftp.tcl.tk/pub/tcl/tcl8_4/tcl${tcl_ver}-src.tar.gz
	tar -xzf tcl${tcl_ver}-src.tar.gz
	cd tcl${tcl_ver}/unix; \
	./configure --enable-threads --prefix=$(prefix); \
	make install

install_pgsql:
	wget -c ftp://ftp.postgresql.org/pub/latest/postgresql-${pg_ver}.tar.gz; \
	tar -xzf postgresql-${pg_ver}.tar.gz; \
	cd postgresql-${pg_ver}; \
	./configure --prefix=$(prefix) --with-tcl --enable-thread-safety; \
	make install; \
	cd contrib; \
	make install; \
	cd $(prefix); \
	mkdir -p db logs; \
	bin/initdb -D db; \
	bin/pg_ctl -D db -l logs/postgresql.log start

tar:
	tar -czf ../ossweb.tgz *

dist:	clean_links
	make -C doc build
	(cd .. && tar --exclude ossweb/.svn --exclude ossweb/Makefile.local -czf ossweb.tar.gz ossweb)

