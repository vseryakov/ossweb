#!/bin/bash

if [ "$1" = "" -o "$2" = "" ]; then
  exit
fi

for f in `find . -type f -name '*.tcl' -print -o -type f -name '*.adp' -print -o -type f -name '*.xql' -print -o -type f -name '*.sql' -print -o -type f -name '*akefile' -print -o -type f -name '*.c' -print -o -type f -name '*.h' -print`; do
sed -i "s/$1/$2/g" $f;
done
