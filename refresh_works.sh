#!/bin/bash -x

BACKUP_SERVER=${1:-dev.applicative.jp}
BACKUP_USER=${2:-app}
SSH_CONNECT=${BACKUP_USER}@${BACKUP_SERVER}
BACKUP_DIR=${3:-/home/app/backup/goldrush/backup}
DB_USER=${5:-gr}
DB_PASSWD=${5:-gr}
DB_NAME=${5:-gr}

ssh $SSH_CONNECT "[[ -d $BACKUP_DIR ]]"
if [[ $? != 0 ]];then
  echo "No dir BACKUP_DIR: $BACKUP_DIR"
  exit 1
fi

echo -n "DB Conecting... "
mysql -u $DB_USER --password=$DB_PASSWD $DB_NAME <<EOS > /dev/null 2>&1
select 1 from dual;
EOS
if [[ $? != 0 ]];then
  echo "DB Connect error!"
  echo "USER: $DB_USER, PASSWD: $DB_PASSWD, DB: $DB_NAME"
  exit 1
fi

SQL_FILE=$(ssh $SSH_CONNECT "ls $BACKUP_DIR/dump*|tail -1")

echo -n "Check zcat... "
type gzcat > /dev/null 2>&1
if [[ $? != 0 ]];then
  type zcat > /dev/null 2>&1
  if [[ $? != 0 ]];then
    echo "zcat or gzcat not found."
    exit 1
  fi
  ZCAT=zcat
else
  ZCAT=gzcat
fi
echo "$ZCAT found."

if [[ $SQL_FILE ]];then
  echo "Start import SQL."
  ssh $SSH_CONNECT "cat $SQL_FILE" | $ZCAT - | mysql -u $DB_USER --password=$DB_PASSWD $DB_NAME
else
  echo "SQL: Target file not found. in $BACKUP_DIR"
  exit 1
fi

echo "Finish!"

