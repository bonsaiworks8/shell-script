#!/bin/bash

LOGFILE_NAME="/var/log/auth.log"
TMP_LOGFILE_NAME="/tmp/tmp_auth.log"
TMP_LOGFILE_BACKUP_NAME="/tmp/tmp_auth.log.bak"
TMP_LOGIN_LOGFILE_NAME="/tmp/tmp_login.log"
ACCESS_TOKEN="LINE Notifyアクセストークン"

notify_message(){
  message="$1($2)から$3ユーザーでログインがありました($4)"
  curl -s -X POST -H "Authorization: Bearer $ACCESS_TOKEN" -F "message=$message" https://notify-api.line.me/api/notify > /dev/null
}

# ログファイルが存在したら
if [ -f $LOGFILE_NAME ]; then
  # ログ抽出
  cp $LOGFILE_NAME $TMP_LOGFILE_NAME

  if [ ! -e $TMP_LOGFILE_BACKUP_NAME ]; then
    cp $LOGFILE_NAME $TMP_LOGFILE_BACKUP_NAME
  fi

  # 新しいファイル(TMP_LOGFILE_NAME)の方にある行だけ抽出
  diff --old-line-format='' --unchanged-line-format='' --new-line-format='%L' $TMP_LOGFILE_BACKUP_NAME $TMP_LOGFILE_NAME | grep "Accepted" > $TMP_LOGIN_LOGFILE_NAME

  cat $TMP_LOGIN_LOGFILE_NAME | while read line
  do
    ip=$(echo $line | cut -f 11 -d " ")
    country=$(whois $ip | grep "country:" | sort | uniq | sed -e 's/  */ /g' | cut -f 2 -d " ")
    country=$(echo $country | sed -e 's/ /,/g')
    user=$(echo $line | cut -f 9 -d " ")
    month=$(echo $line | cut -f 1 -d " ")
    day=$(echo $line | cut -f 2 -d " ")
    time=$(echo $line | cut -f 3 -d " ")
    date=$month-$day,$time
    
    notify_message $ip $country $user $date
  done
  cp $TMP_LOGFILE_NAME $TMP_LOGFILE_BACKUP_NAME
fi
