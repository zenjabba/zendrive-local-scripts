#!/bin/bash
# runs Plex-Auto-Collections -
# https://github.com/mza921/Plex-Auto-Collections
# script uses the poster folder in zd-inbound
# there are sample config.yml files in /mnt/unionfs/inbound/librarybase/collections/
# pass either movies.yml or tv.yml (examples)
# as in:  ./pac.sh movies.yml
# if you need/want to run this as a specific user in docker add something like --user seed:seed 
/bin/mkdir -P /opt/pac
/usr/bin/docker run --rm -it -d --network="docker_default" --name pac -v /opt/pac:/config -v /mnt/unionfs/inbound/librarybase/collections/posters:/config/posters -e PLEXAPI_PLEXAPI_TIMEOUT=60 mza921/plex-auto-collections -u -c /config/$1
