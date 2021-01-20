#!/bin/bash

# install JQ if not installed
if hash jq 2> /dev/null; then echo "OK, you have jq installed. We’ll use that."; else sudo apt install jq -y; fi
#
# point this to where your poller log sits
logfile=/var/log/poller.log
#
#
checkfor="using custom autoscan trigger"

d1=$(date -d '$1 hour ago' "+%Y/%m/%d:%H:%M:%S")
d1=$(date -d $d1 +%s)

for log in $logfile
do
   check=$(echo "$log" |  jq -r  '.message')
   if [[ $log == *"${checkfor}"* ]]; then
      #d2=$(echo "$var" |  jq -r  '.time')
      #d2=$(date -d $d2 +%s)
      #if [ $d2 > $d1 ]; then
      var=$(echo "$log" |  jq -r  '.path')
      varlist=("${var}")
      echo "${var}"
   fi
done
#IFS=$'\n'
#readarray -t uniq < <(printf '%s\n' "${varlist[@]}" | sort -u)
#unset IFS
#for i2 in "${uniq[@]}"; 
#do 
#   val=${i2//\"/}
#   /opt/scripts/ascan.sh "/mnt/unionfs${val}/"
#   sleep 5
#done