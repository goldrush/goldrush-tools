#!/bin/sh

if [ -z "$1" ];then
  echo "error!! not apply dir path"
  exit 1
fi

cd $1

tar czf ../backup/files.`date +%Y%m%d_%H%M%S`.tar.gz files

