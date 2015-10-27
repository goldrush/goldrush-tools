#!/bin/sh

cd /var
rsync -a --delete goldrush app@dev.applicative.jp:~/backup

