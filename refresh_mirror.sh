#!/bin/bash

BACKUP_DIR=${1:-/home/app/backup/goldrush/backup}
GOLDRUSH_HOME=${2:-/home/app/goldrush_mirror}
DB_USER=${3:-grmirror}
DB_PASSWD=${3:-grmirror}
DB_NAME=${3:-grmirror}

if [[ ! -d $BACKUP_DIR ]];then
  echo "No dir BACKUP_DIR: $BACKUP_DIR"
  exit 1
fi

if [[ ! -f $GOLDRUSH_HOME/config/database.yml ]];then
  echo "No dir GOLDRUSH_HOME or database.yml: $GOLDRUSH_HOME"
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

SQL_FILE=$(ls $BACKUP_DIR/dump*|tail -1)

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
  $ZCAT $SQL_FILE|mysql -u $DB_USER --password=$DB_PASSWD $DB_NAME
  mysql -u $DB_USER --password=$DB_PASSWD $DB_NAME <<EOS
update bp_pics set email1 = concat('test+', replace(email1, '@', '_at_'), '@dev.applicative.jp');
update users set encrypted_password = '\$2a\$10\$W5krc143CqKeXiJ1MtiOgOKaJoYy6GSAVhUmv8mhMTMdKObO.fiSe';
delete from sys_configs where config_section = 'business_partners' and config_key = 'prodmode';
EOS

else
  echo "SQL: Target file not found. in $BACKUP_DIR"
  exit 1
fi

FILES=$(cd $BACKUP_DIR;ls `pwd`/files*|tail -1)

if [[ $FILES ]];then
  echo "Update attachment files."
  cd $GOLDRUSH_HOME
  rm -rf files
  tar xzf $FILES
else
  echo "FILES: Target file not found. in $BACKUP_DIR"
  exit 1
fi

echo "git pull"
git pull

echo "passenger restart"
touch tmp/restart.txt

echo "Finish!"

