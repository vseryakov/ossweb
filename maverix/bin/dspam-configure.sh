#!/bin/bash

export CFLAGS=-DTHREADSAFE
export LDFLAGS=-lpthread

./configure --with-dspam-home=/usr/local/aolserver/modules/dspam \
            --with-dspam-home-mode=775 \
            --enable-virtual-users \
            --enable-domain-scale \
            --disable-user-logging \
            --disable-system-logging \
            --with-storage-driver=sqlite_drv \
            --with-sqlite-includes=/usr/include \
            --with-sqlite-libraries=/usr/lib
