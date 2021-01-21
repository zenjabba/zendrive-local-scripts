#!/bin/bash
#
function usage {
  echo ""
  echo "Usage: resend_poller.sh 5 "
  echo ""
  echo "will send the last 5 hours of poller data to autoscan"
  exit 1
}

if [ -z "$1" ]; then
  echo "please provide a value for hours ago"
  usage
fi

# install JQ if not installed
if hash jq 2> /dev/null; then echo "OK, you have jq installed. We will use that."; else sudo apt install jq -y; fi
#
# point this to where your poller log sits
logfile=/var/log/poller.log
#
#   get the hours ago value from $1
hoursago="${1} hours ago"
d1=$(date -d "${hoursago}" "+%Y-%m-%dT%H:%M:%SZ")
d1=$(date -d "${d1}" +%s)
#
declare -a values
declare -a valuelist
mapfile -t values <<< $(jq -r '. | select(.message|test("custom."))' "$logfile")
for i in "${values[@]}"
do
    d2=$(echo "${i}" |  jq -r  '.time')
    d2=$(date -d "${d2}" +%s)
    if [[ ${d2} -ge ${d1} ]]; then
       var=$(echo "${i}" |  jq -r  '.path')
       var=${var#*/}
       var="$(echo -e "${var}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
       file_list+=("${var}")
    fi 
done
IFS=$'\n'
readarray -t uniq < <(printf '%s\n' "${file_list[@]}" | sort -u)
unset IFS
for i2 in "${uniq[@]}"; 
do 
   val=${i2//\"/}
   curl -G --request POST --url "http://127.0.0.1:3030/triggers/manual" --data-urlencode "dir=${val}"
   if [ $? -ne 0 ]; then echo "Unable to reach autoscan ERROR: $?";fi
   if [ $? -eq 0 ]; then echo "${val} added to your autoscan queue!";fi
   sleep 5
done