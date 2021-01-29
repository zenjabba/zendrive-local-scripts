#!/bin/bash
# updated for the new and improved scanfolder.sh
. /opt/scripts/zendrive/plex-scripts/scanfolder.conf
source=$1
trigger=$2
ZDTD=$3
LOGNAME=$4
DAYS=$5
USEVFS=$6
mkdir -p /opt/logs
/usr/bin/truncate -s 0 /opt/logs/"$LOGNAME"
/bin/bash /opt/scripts/zendrive/scanfolder/scanfolder.sh -s "$source" -c "$container" -t "$trigger" -u "$URL" -o "$NAME" -w "$WAIT" -r "$RCLONE" -a "$ZDTD" -d "$DAYS" -j "$RCPORT" -v "$USEVFS"
