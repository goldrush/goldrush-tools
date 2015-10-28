#!/bin/bash

if [[ "$#" < "3" ]]
then
  echo "$0 FROM_DIR REMOTE_IP REMOTE_DIR" >&2
  exit 1
fi

if [[ ! -d $1 ]]
then
  echo "$1 is not dir"
  exit 1
fi

ping -c 1 $2 > /dev/null
if [[ $? -ne 0 ]]
then
  echo "ping timeout $2" >&2
  exit 2
fi

ssh $2 "ls $3" > /dev/null
if [[ $? -ne 0 ]]
then
  echo "$3 is not remote dir" >&2
  exit 3
fi

cd
rsync -a $1 $2:$3

