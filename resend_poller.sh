#!/bin/bash
# install jq if not there
if hash jq 2> /dev/null; then echo "OK, you have JQ installed. We ^`^yll use that."; else sudo apt install jq -y; fi
#
# point this to where your poller log sits
logfile=/var/log/poller.log
#
#
mydatexpr="using custom autoscan trigger"
hourago="$1"
d1=$(date -d '$1 hour ago' "+%Y/%m/%d:%H:%M:%S")
d1=$(date -d $d1 +%s)
cond=$(date -d 2014-08-19 +%s)

if [ $todate -ge $cond ];
then
    break

echo "${hoursago}"

for log in $logfile
do
   var=$(egrep "$mydatexpr" $log)
   d2=$(echo "$var" |  jq -r  '.time')
   d2=$(date -d $d2 +%s)
   if [ $d2 > $d1 ]; then
      var=$(echo "$var" |  jq -r  '.path')
      var=$(echo "$var" | sed 's/zd-movies//g')
      var=$(echo "$var" | sed 's/zd-anime//g')
      var=$(echo "$var" | sed 's/zd-tv1//g')
      var=$(echo "$var" | sed 's/zd-tv2//g')
      var=$(echo "$var" | sed 's/zd-tv3//g')
      var=$(echo "$var" | sed 's/zd-movies-non-english//g')
      var=$(echo "$var" | sed 's/zd-audiobooks//g')
      var=$(echo "$var" | sed 's/zd-tv-non-english//g')
      var=$(echo "$var" | sed 's/zd-audiobooks-non-english//g')   
      varlist=("${var}")
   fi
done
IFS=$'\n'
readarray -t uniq < <(printf '%s\n' "${varlist[@]}" | sort -u)
unset IFS
printf '%s\n' "${uniq[@]}"
#for i2 in "${uniq[@]}"; 
#do 
#   val=${i2//\"/}
#   /opt/scripts/ascan.sh "/mnt/unionfs${val}/"
#   sleep 5
#done