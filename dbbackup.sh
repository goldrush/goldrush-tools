#!/bin/bash

MYSQLDUMP=/usr/bin/mysqldump
GZIP=/bin/gzip

if [ -z "$1" ];then
  echo "error!! not apply dir path"
  exit 1
fi

ping -c 1 $2 > /dev/null
if [[ $? -ne 0 ]]
then
  echo "ping timeout $2" >&2
  exit 2
fi

cd $1

$MYSQLDUMP -u gr --password=gr -h $2 gr --default-character-set=binary | $GZIP > dump.`date +%Y%m%d_%H%M%S`.sql.gz

