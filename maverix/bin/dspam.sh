#!/bin/bash

dspam=/usr/local/aolserver/modules/dspam

case "$1" in
  vacuum)
     find $dspam/data -name "*.sdb" -exec echo 'vacuum;' \| sqlite {} \;
     ;;

  *)
     sql=$dspam/sqlite.sql
     echo "delete from dspam_token_data where (innocent_hits*2) + spam_hits < 5 and date('now')-date(last_hit) > 30;"> $sql
     echo "delete from dspam_token_data where innocent_hits + spam_hits = 1 and date('now')-date(last_hit) > 15;">> $sql
     echo "delete from dspam_token_data where date('now')-date(last_hit) > 90;">> $sql
     echo "delete from dspam_signature_data where date('now')-date(created_on) > 14;">> $sql
     find $dspam/data -name "*.sdb" -exec sqlite {} < $sql \;
     rm -rf $sql
     ;;
esac

