#!/bin/bash
logfile=/var/log/poller.log
mydatexpr="using custom autoscan trigger"
for log in $logfile
do
var=$(egrep "$mydatexpr" $log)
var=$(cut -d':' -f3 <<< "${var}")
var=$(cut -d',' -f1 <<< "${var}")
var=$(echo "$var" | sed 's/zd-movies//g')
var=$(echo "$var" | sed 's/zd-anime//g')
var=$(echo "$var" | sed 's/zd-tv1//g')
var=$(echo "$var" | sed 's/zd-tv2//g')
var=$(echo "$var" | sed 's/zd-tv3//g')
varlist=("${var}")
done
IFS=$'\n'
readarray -t uniq < <(printf '%s\n' "${varlist[@]}" | sort -u)
unset IFS
#printf '%s\n' "${uniq[@]}"
for i2 in "${uniq[@]}"; 
do 
   val=${i2//\"/}
   /opt/scripts/ascan.sh "/mnt/unionfs${val}/"
   sleep 5
done
