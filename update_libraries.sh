#!/bin/bash
# updated for the new and improved scanfolder.sh
source=$1
container="/mnt/unionfs/"
trigger=$2
URL="http://127.0.0.1:3030"
NAME="plex"
WAIT="10"
ZDTD=$3
LOGNAME=$4
RCLONE="zenstorage"
DAYS=$5
RCPORT=5590
USEVFS=$6
mkdir -p /opt/logs
/usr/bin/truncate -s 0 /opt/logs/"$LOGNAME"
/bin/bash /opt/scripts/scanfolder/scanfolder.sh -s "$source" -c "$container" -t "$trigger" -u "$URL" -o "$NAME" -w "$WAIT" -r "$RCLONE" -a "$ZDTD" -d "$DAYS" -j "$RCPORT" -v "$USEVFS"
