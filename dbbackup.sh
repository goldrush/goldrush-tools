#!/bin/sh

MYSQLDUMP=/usr/bin/mysqldump
GZIP=/bin/gzip

if [ -z "$1" ];then
  echo "error!! not apply dir path"
  exit 1
fi

cd $1

$MYSQLDUMP -u gr --password=gr gr --default-character-set=binary | $GZIP > dump.`date +%Y%m%d_%H%M%S`.sql.gz

