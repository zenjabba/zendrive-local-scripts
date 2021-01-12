#!/bin/bash
# assumes your user as write access to /mnt/local
# $1 = folder where your docker-compose.yml is stored
# $2 = name of source snapshot folder
# $3 = name of destination snapshot folder
# $4 = Name of the Google Remote to use for upload
# $5 = folder path for remote backup
# $6 = if your BTFS is at / and not /opt then set this to 1, otherwise leave empty
# 
# sample if you use BTRFS for /opt - 
# ./backup.sh /opt/docker/ /opt /opt/snapshot GOOGLE Backups
#
# sample if you use BTRFS for / -
# ./backup.sh /opt/docker/ / /opt/snapshot GOOGLE Backups 1
#
#   Make sure folders exist
#
mkdir -p /mnt/local/backup/
mkdir -p /opt/setup_files/
#
# copy systemd files & rclone.conf under /opt
#
FILE=~/.bashrc
if [ -f "$FILE" ]; then sudo /bin/cp ~/.bashrc /opt/setup_files/; fi
FILE=/etc/security/limits.conf
if [ -f "$FILE" ]; then sudo /bin/cp /etc/security/limits.conf /opt/setup_files/; fi
FILE=/etc/sysctl.conf
if [ -f "$FILE" ]; then sudo /bin/cp /etc/sysctl.conf /opt/setup_files/; fi
FILE=/etc/systemd/system/zd-storage-metadata.service
if [ -f "$FILE" ]; then sudo /bin/cp /etc/systemd/system/zd-storage-metadata.service /opt/setup_files/; fi
FILE=/etc/systemd/system/zd-storage-small.service
if [ -f "$FILE" ]; then sudo /bin/cp /etc/systemd/system/zd-storage-small.service /opt/setup_files/; fi
FILE=/etc/systemd/system/zd-storage.service
if [ -f "$FILE" ]; then sudo /bin/cp /etc/systemd/system/zd-storage.service /opt/setup_files/; fi
FILE=/etc/systemd/system/mergerfs.service
if [ -f "$FILE" ]; then sudo /bin/cp /etc/systemd/system/mergerfs.service /opt/setup_files/; fi
FILE=/etc/systemd/system/poller.service
if [ -f "$FILE" ]; then sudo /bin/cp /etc/systemd/system/poller.service /opt/setup_files/; fi
FILE=~/.config/rclone/rclone.conf
if [ -f "$FILE" ]; then /bin/cp ~/.config/rclone/rclone.conf /opt/setup_files/; fi
FILE=~/.config/plexapi/config.yml
if [ -f "$FILE" ]; then /bin/cp ~/.config/plexapi/config.yml /opt/setup_files/; fi
#
#  backup user crontab
#
crontab -l > /opt/etup_files/my-crontab
#
#
# stop poller
#
sudo systemctl stop poller.service
#
# Down running dockers
#
cd $1
/usr/bin/docker-compose down
#
#  Create btrfs snapshot
#
sudo btrfs subvolume delete $3
sudo btrfs subvolume snapshot $2 $3
#
#  Bring Docker back up
#
/usr/bin/docker-compose up -d
#
# start poller
#
sudo systemctl start poller.service
#
#
#   prepare plex for compression
#
#
if [ -z ${6+x} ]; then basedir="${3}" else basedir="${3}/opt"; fi
plexdir="${basedir}/plex"
plexdbdir="${plexdir}/Library/Application Support/Plex Media Server/Plug-in Support/Databases"

# Clean Up
rm "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml
rm -rf "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Cache/PhotoTranscoder/*
rm -rf "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Cache/Transcode/*
rdfind -makehardlinks true "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Metadata/

# DB TIME
cd "${plexdbdir}" || exit
cp com.plexapp.plugins.library.db com.plexapp.plugins.library.db.optimize
## remove stupid shit
sqlite3 com.plexapp.plugins.library.db "DROP index 'index_title_sort_naturalsort'"
sqlite3 com.plexapp.plugins.library.db "DELETE from schema_migrations where version='20180501000000'"
## pump and dump
sqlite3 com.plexapp.plugins.library.db .dump > dump.sql
rm com.plexapp.plugins.library.db
sqlite3 com.plexapp.plugins.library.db "pragma page_size=32768; vacuum;"
sqlite3 com.plexapp.plugins.library.db "pragma page_size"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size = 20000000; vacuum;"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size"
sqlite3 com.plexapp.plugins.library.db < dump.sql
sqlite3 com.plexapp.plugins.library.db "pragma page_size"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size"
sqlite3 com.plexapp.plugins.library.db "vacuum"
sqlite3 com.plexapp.plugins.library.db "pragma page_size"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size"
sqlite3 com.plexapp.plugins.library.db "pragma optimize"
sqlite3 com.plexapp.plugins.library.db "pragma page_size"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size"
## extra clean up
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_views;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_settings;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_bandwidth;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_media;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_resources;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM accounts;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM devices;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM play_queue_generators;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_accounts;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_items WHERE metadata_type = 15;"
## fix messed up dates and reown
sqlite3 com.plexapp.plugins.library.db "UPDATE metadata_items SET added_at = DATETIME('now') WHERE DATETIME(added_at) > DATETIME('now');;;"
sqlite3 com.plexapp.plugins.library.db "UPDATE metadata_items SET added_at = originally_available_at WHERE added_at <> originally_available_at AND originally_available_at IS NOT NULL;;"

# create tar files of each folder under /opt
#
if [ -z ${6+x} ]; then cd $3 else cd $3/opt; fi
/usr/bin/find . -maxdepth 1 -mindepth 1 -type d -exec tar cvf /mnt/local/backup/{}.tar {}  \;
wait
#
# delete snapshot
#
sudo btrfs subvolume delete $3
#
# upload to GDrive
# 
rclone move /mnt/local/backup/ $4:$5/$(date +"%Y-%m-%d")/ --ignore-case --multi-thread-streams=1 --drive-chunk-size=256M --transfers=20 --checkers=40 -vP --drive-use-trash --track-renames --use-mmap --timeout=1m --fast-list --tpslimit=8 --tpslimit-burst=16 --size-only --refresh-times
wait
