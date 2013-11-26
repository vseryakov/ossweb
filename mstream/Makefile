-include ../Makefile.ossweb

all: xpi

install: xpi
	-cp -f *.xpi ${js_dir}

xpi:
	zip -r mstream.xpi chrome* components defaults *.js *.rdf
