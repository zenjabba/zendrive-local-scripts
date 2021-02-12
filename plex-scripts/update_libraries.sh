#!/bin/bash
# make sure you edit scanfolder.conf, it now has some
# variables in it.  This makes it easier to do a git pull
. /opt/scripts/zendrive/plex-scripts/scanfolder.conf
source=$1
trigger=$2
LOGNAME=$3
DAYS=$4
mkdir -p /opt/logs
/usr/bin/truncate -s 0 /opt/logs/"$LOGNAME"
/bin/bash /opt/scripts/zendrive/scanfolder/scanfolder.sh -s "$source" -c "$container" -t "$trigger" -u "$URL" -o "$NAME" -w "$WAIT" -d "$DAYS" 
