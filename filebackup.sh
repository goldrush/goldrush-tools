#!/bin/sh

if [ -z "$1" ];then
  echo "error!! not apply dir path $1"
  exit 1
fi

if [ -z "$2" ];then
  echo "error!! not apply dir path $2"
  exit 2
fi

cd $1

tar czf $2/files.`date +%Y%m%d_%H%M%S`.tar.gz files

