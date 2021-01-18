#!/bin/bash
# $1 = number of days old
# $2 = RCLONE path to check for backups to delete
# $3 = enter YESfor dry-run to test
#
# Sample NO Dry Run-
# ./purge_google 21 GOOGLE:/Backups    
#
# Sample With Dry Run-
# ./purge_google 21 GOOGLE:/Backups YES    
#
if [ -z ${3+x} ]; then DRY="-vvP"; else DRY="--dry-run -vvP"; fi
/usr/bin/rclone delete --min-age $1d $2 $DRY
