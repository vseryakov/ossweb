#!/bin/bash

DB=ossweb

if [ "x$1" = "x" ]; then
  echo "Usage:"
  echo "       $0 email type sender_digest_flag anti_virus_flag spam_score_white spam_score_black drop_spam"
  echo
  echo "       example: adduser test@email.com VRFY f VRFY 0 10 t"
  echo "                adduser joe@email.com VRFY t PASS"
  echo "                adduser joe@email.com VRFY"
  echo
  echo "Everything except user email may not be specified"
  exit
fi
user_email="'$1'"

user_type="'PASS'"
if [ "$2" = "PASS" -o "$2" = "VRFY" ]; then 
  user_type="'$2'"
fi
sender_digest_flag=FALSE
if [ "$3" = "t" -o "$3" = "f" ]; then
  sender_digest_flag="'$3'"
fi

anti_virus_flag="'PASS'"
if [ "$4" = "PASS" -o "$4" = "VRFY" ]; then
  anti_virus_flag="'$4'"
fi

spam_score_white=NULL
if [ "x$5" != "x" ]; then
  spam_score_white="'$5'"
fi

spam_score_black=NULL
if [ "x$6" != "x" ]; then
  spam_score_black="'$6'"
fi

spam_status=NULL
if [ "$7" = "t" ]; then
  spam_status="'Spam'"
fi

sql="INSERT INTO maverix_users(user_email,user_type,sender_digest_flag,anti_virus_flag,spam_score_white,spam_score_black,spam_status) VALUES($user_email,$user_type,$sender_digest_flag,$anti_virus_flag,$spam_score_white,$spam_score_black,$spam_status)"

psql -e -q -c "$sql" $DB
