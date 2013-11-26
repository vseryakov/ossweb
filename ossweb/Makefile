-include ../Makefile.ossweb

install:	install_ossweb

install_copy:
	$(call copy_files,*.tcl,${ossweb_dir})
	$(call copy_files,*.xql,${xql_dir})

export:
	cat init.tcl > ossweb_procs.tcl
	for f in *.tcl; do \
		if [ "$$f" != "init.tcl" ]; then \
			cat $$f >> ossweb_procs.tcl; \
		fi; \
	done
