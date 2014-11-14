#!/bin/sh -f

# 第1引数：rubyへのパス

RUBY=$1
shift 1
MAILBOX_PARSER=$1
shift 1
LOG_DIR=$1
shift 1

# 第2引数以降：Rubyスクリプトのパラメータ

umask 002

cd $(dirname $0)

BOUNCE_DATA=`tee -a $LOG_DIR/bounce.log | ${MAILBOX_PARSER} |tee -a $LOG_DIR/bounce_yaml.log | ${RUBY} yaml_reader.rb -k 0,recipient -k 0,reason`
BOUNCE_RECIPENT=`echo ${BOUNCE_DATA} | cut -f1 -d' '`
BOUNCE_REASON=`echo ${BOUNCE_DATA} | cut -f2 -d' '`

${RUBY} httpclient.rb $* LOG_DIR=$LOG_DIR recipient=${BOUNCE_RECIPENT} reason=${BOUNCE_REASON}

