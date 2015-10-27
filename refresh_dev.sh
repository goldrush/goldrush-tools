#!/bin/bash -x

BACKUP_SERVER=${1:-dev.applicative.jp}
BACKUP_USER=${2:-app}
SSH_CONNECT=${BACKUP_USER}@${BACKUP_SERVER}
BACKUP_DIR=${3:-/home/app/backup/goldrush/backup}
GOLDRUSH_HOME=${4:-/home/tamaki-t/git/goldrush}
DB_USER=${5:-grdev}
DB_PASSWD=${5:-grdev}
DB_NAME=${5:-grdev}

ssh $SSH_CONNECT "[[ -d $BACKUP_DIR ]]"
if [[ $? != 0 ]];then
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
  mysql -u $DB_USER --password=$DB_PASSWD $DB_NAME <<EOS
update bp_pics set email1 = concat('test+', replace(email1, '@', '_at_'), '@dev.applicative.jp');
update users set encrypted_password = '\$2a\$10\$W5krc143CqKeXiJ1MtiOgOKaJoYy6GSAVhUmv8mhMTMdKObO.fiSe';
delete from sys_configs where config_section = 'business_partners' and config_key = 'prodmode';
EOS

else
  echo "SQL: Target file not found. in $BACKUP_DIR"
  exit 1
fi

FILES=$(ssh $SSH_CONNECT "cd $BACKUP_DIR;ls \`pwd\`/files*|tail -1")

if [[ $FILES ]];then
  echo "Update attachment files."
  cd $GOLDRUSH_HOME
  rm -rf files
  ssh $SSH_CONNECT "cat $FILES" | tar xzf -
else
  echo "FILES: Target file not found. in $BACKUP_DIR"
  exit 1
fi

echo "git pull"
git pull

echo "passenger restart"
touch tmp/restart.txt

echo "Finish!"

