#!/bin/bash
# assumes your user as write access to /mnt/local
#
#  Sample rclone entry for the backup S3 bucket
#  [zd-backup]
#  type = s3
#  provider = Minio
#  region = us-east-1
#  chunk_size = 256M
#  disable_http2 = true
#  access_key_id = <access_key_id>
#  secret_access_key = <secret_access_key>
#  endpoint = https://zenhosting-backup.zenterprise.org/
#

# read in content of backupbtrfs.conf
#  YOU MUST EDIT THIS LINE AND PROVIDE THE PATH TO THE CONFIG FILE
#  IF IT IS DIFFERENT THAN WHAT IS SHOWN
. /opt/scripts/backupbtrfs.conf

# process user access_kay and foler path
if [ -z ${var4a+x} ]; then
   :
else
   var5a=${var5a1:0:48}         #sets bucket name to 48 character
   var5a=${var5a,,}             #sets bucket to lower case
   var5a="/${var5a}/${var5a2}/"
fi

#   Make sure folders exist
mkdir -p /mnt/local/backup/
mkdir -p /opt/setup_files/


# install rdfind if not there
if hash rdfind 2> /dev/null; then echo "OK, you have rdfind installed. We’ll use that."; else sudo apt install rdfind -y; fi

# copy files from backupbtrfs_files.txt under /opt
# read in contents of /opt/scripts/backupbtrfs_files.txt, defined in backupbtrfs.conf
while IFS= read -r line
do
  FILE="$line"
  if [ -f "$FILE" ]; then sudo /bin/cp "$line" /opt/setup_files/; fi
done < "$input"

#  backup user crontab
crontab -l > /opt/setup_files/my-crontab

# stop poller
sudo systemctl stop poller.service

# Down running dockers
cd $var1
/usr/bin/docker-compose down

#  Create btrfs snapshot (delete any existing snashots 1st)
sudo btrfs subvolume delete $var3
sudo btrfs subvolume snapshot $var2 $var3

#  Bring Docker back up
/usr/bin/docker-compose up -d

# start poller
sudo systemctl start poller.service

#   prepare plex for compression (the Jon effect)
if [ -z ${var6+x} ]; then based="${var3}"; else based="${var3}/opt"; fi
plexdir="${based}/plex"

plexdbdir="${plexdir}/Library/Application Support/Plex Media Server/Plug-in Support/Databases"

rm -rf "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Cache/PhotoTranscoder/*
rm -rf "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Cache/Transcode/*
/usr/bin/rdfind -makehardlinks true "${plexdir}"/Library/Application\ Support/Plex\ Media\ Server/Metadata/

cd "${plexdbdir}" || exit
sqlite3 com.plexapp.plugins.library.db "DROP index 'index_title_sort_naturalsort'"
sqlite3 com.plexapp.plugins.library.db "DELETE from schema_migrations where version='20180501000000'"
sqlite3 com.plexapp.plugins.library.db .dump > dump.sql
rm com.plexapp.plugins.library.db
sqlite3 com.plexapp.plugins.library.db "pragma page_size=32768; vacuum;"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size = 20000000; vacuum;"
sqlite3 com.plexapp.plugins.library.db < dump.sql
sqlite3 com.plexapp.plugins.library.db "vacuum"
sqlite3 com.plexapp.plugins.library.db "pragma optimize"

# create tar files of each folder under /opt
if [ -z ${var6+x} ]; then cd $var3; else cd $var3/opt; fi
/usr/bin/find . -maxdepth 1 -mindepth 1 -type d -exec tar cvf /mnt/local/backup/{}.tar {}  \;
wait

# delete snapshot
sudo btrfs subvolume delete $var3

# begin the upload phase
backup_done=""

# upload/copy to S3
if [ -z ${var4a+x} ]; then
   echo "you chose not to use the S3 bucket"
else
   rclone copy /mnt/local/backup/ $var4a:$var5a/$(date +"%Y-%m-%d")/ --ignore-case --multi-thread-streams=1 --drive-chunk-size=256M --transfers=20 --checkers=40 -vP --drive-use-trash --track-renames --use-mmap --timeout=1m --fast-list --tpslimit=8 --tpslimit-burst=16 --size-only --refresh-times
   wait
   backup_done="1"
fi
# upload to GDrive
if [ -z ${var4b+x} ]; then
   echo "you chose not to use the GDrive bucket"
else
   rclone move /mnt/local/backup/ $var4b:$var5b/$(date +"%Y-%m-%d")/ --ignore-case --multi-thread-streams=1 --drive-chunk-size=256M --transfers=20 --checkers=40 -vP --drive-use-trash --track-renames --use-mmap --timeout=1m --fast-list --tpslimit=8 --tpslimit-burst=16 --size-only --refresh-times
   wait
   backup_done="1"
fi

#clean up /mnt/local/backup
if [ -z ${backup_done+x} ]; then
 :
else
   rm -rf /mnt/local/backup/
fi
 
 
 
 
