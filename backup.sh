#!/bin/bash
# assumes your user as write access to /mnt/local
# $1 = folder where your docker-compose.yml is stored
# $2 = name of source snapshot folder
# $3 = name of destination snapshot folder
# $4 = Name of the Google Remote to use for upload
# $5 = if your BTFS is at / and not /opt then set this to 1, otherwise leave empty
# 
# sample if you use BTRFS for /opt - 
# ./backup.sh /opt/docker/ /opt /opt/snapshot GOOGLE
#
# sample if you use BTRFS for / -
# ./backup.sh /opt/docker/ / /opt/snapshot GOOGLE 1
#
#   Make sure folders exist
#
mkdir -p /mnt/local/backup/
mkdir -p /opt/setup_files/
#
# copy systemd files & rclone.conf under /opt
#
sudo /bin/cp /etc/systemd/system/zd-storage-small.service /opt/setup_files/
sudo /bin/cp /etc/systemd/system/zd-storage.service /opt/setup_files/
sudo /bin/cp /etc/systemd/system/mergerfs.service /opt/setup_files/
/bin/cp ~/.config/rclone/rclone.conf /opt/setup_files/
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
# create tar files of each folder under /opt
#
if [ "$5" -eq "1" ]; then
        cd $3/opt
else
        cd $3
fi
/usr/bin/find . -maxdepth 1 -mindepth 1 -type d -exec tar cvf /mnt/local/backup/{}.tar {}  \;
wait
#
# delete snapshot
#
sudo btrfs subvolume delete $3
#
# upload to GDrive
# 
rclone move /mnt/local/backup/ $4:/Backups/$(date +"%Y-%m-%d")/ --transfers=50 -vvP
wait
