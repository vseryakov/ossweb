CFLAGS	= -O2 -g -fPIC -DPAM_DYNAMIC

all:	pam_ossweb.so pam_pop3.so

pam_ossweb.so:	pam_ossweb.o
	gcc -shared -o $@ $<

pam_pop3.so:	pam_pop3.o
	gcc -shared -o $@ $<

clean:
	rm -f core *.o *.so *~

