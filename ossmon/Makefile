-include ../Makefile.ossweb

install_links:
	@ln -fs ../admin/reftable2.adp device_types.adp
	@ln -fs ../admin/reftable2.tcl device_types.tcl
	@ln -fs ossmon.adp index.adp
	${install_dir} ${modules_dir}/charts ${modules_dir}/reports ${project_dir}/${app_name}/doc
	${install_link} ${modules_dir}/charts ${project_dir}/${app_name}/charts
	${install_link} ${modules_dir}/reports /${project_dir}/${app_name}/reports
	${install_link} ${modules_dir}/files/maps /${project_dir}/${app_name}/maps
	${call install_file,doc/*,/${project_dir}/ossmon/doc}
	${call install_file,etc/*.conf,${conf_dir}}
	${call install_file,etc/ossmon.tcl,${bin_dir}}

cleanup:
	rm -rf etc/*~ doc/*~	

install:        install_module


