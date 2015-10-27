#!/bin/sh

if [ -z "$1" ];then
  echo "error!! not apply dir path"
  exit 1
fi

cd $1

find . -ctime +2 -delete

