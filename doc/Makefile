-include ../Makefile.ossweb

install:
	${install_dir} ${doc_dir}
	-if [ -e html/files/toc.html ]; then \
	   if [ ! -e ${doc_dir}/toc.html ]; then \
	     $(call install_file,html/*,${doc_dir}); \
	   fi; \
	   $(call install_file,html/files/*,${doc_dir}/files); \
        fi

build: clean
	${install_dir} html
	mv src/.svn ./.svn-src
	(cd src && \
	echo -n '[keywords ' > keywords.man && \
	egrep '\[(section|subsection)' ossweb.man |sed 's/\(\]\|subsection\|section\|sub\)//g'|sed 's/\[//g'|awk '{printf "%s ",$$0}' >> keywords.man && \
	grep '\[cmd' ossweb.man |sed 's/\]//g'|awk  '{printf "%s ",$$3}' >> keywords.man && \
	echo ']' >> keywords.man && \
	dtplite -o ../html -style man.css html .)
	mv .svn-src src/.svn
	

cleanup:
	rm -rf src/*~
