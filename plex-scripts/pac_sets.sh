#!/bin/bash
#  this will use pac.sh and a list of yml files to automate running them one after another
#  ./pac_sets.sh <port #>
#
input="/opt/scripts/zendrive/plex-scripts/pac_files.txt"
while IFS= read -r line
do
  sets+=("${line}")
done < "$input"

for i in "${sets[@]}"
do
  /bin/bash /opt/scripts/zendrive/plex-scripts/pac.sh "${i}" "${1}" &&
  cid=$(docker ps -q -f name=pac)
  while [ "$(docker ps -q -f name=pac)" = "${cid}" ]; do
    cid=$(docker ps -q -f name=pac)
    sleep 1
  done
done
