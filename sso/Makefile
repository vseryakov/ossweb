-include ../Makefile.ossweb

install:
	-${install_dir} ${ossweb_dir} ${pages_dir}/sso
	-$(call install_file,${procs_files},${ossweb_dir})
	-$(call install_file,sso.tcl,${pages_dir}/sso)

install_copy:
	$(call copy_files,*_procs.tcl,${ossweb_dir})
	$(call copy_files,sso.tcl,${pages_dir}/sso)


