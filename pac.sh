#!/bin/bash
# runs Plex-Auto-Collections -
# https://github.com/mza921/Plex-Auto-Collections
# script uses the poster folder in zd-inbound
# there are sample config.yml files in /mnt/unionfs/inbound/librarybase/collections/
# pass either movies.yml or tv.yml 
# additionally we are going to vfs/refresh inbound to make sure the posters are all refreshed
# so as the second variable please pass the rc port number of your rclone mount
# Example:  ./pac.sh movies.yml 5577
# if you need/want to run this as a specific user in docker add something like --user seed:seed 
#
#
/bin/mkdir -P /opt/pac
/usr/bin/rclone -vvv rc vfs/refresh dir=/zd-inbound/inbound/librarybase/collections recursive=false --rc-addr=localhost:$2
/usr/bin/rclone -vvv rc vfs/refresh dir=/zd-inbound/inbound/librarybase/collections recursive=true --rc-addr=localhost:$2
/usr/bin/docker run --rm -it -d --network="docker_default" --name pac -v /opt/pac:/config -v /mnt/unionfs/inbound/librarybase/collections/posters:/config/posters -e PLEXAPI_PLEXAPI_TIMEOUT=60 mza921/plex-auto-collections -u -c /config/$1
