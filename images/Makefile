-include ../Makefile.ossweb

install:
	${install_dir} ${images_dir}
	$(call install_file,*,${images_dir})

install_copy:
	$(call copy_all,-r *,${images_dir})

cleanup:
	rm -rf .xvpics
