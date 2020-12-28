#!/bin/bash
# script uses the pooster folder in zd-inbound
# pass either movies.yml or tv.yml
/usr/bin/docker run --rm -it -d --network="docker_default" -v /opt/Plex-Auto-Collections/config:/config -v /mnt/unionfs/inbound/librarybase/collections/posters:/config/posters -e PLEXAPI_PLEXAPI_TIMEOUT=60 mza921/plex-auto-collections -u -c /config/$1
