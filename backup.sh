#!/bin/bash
# assumes your user as write access to /mnt/local
# assumes your file system is -  / btrfs
# and you only want to backup the contents of the /opt folder
# and your docker compose sits in /opt/docker
#
#
#   Make sure folders exist
#
mkdir -p /mnt/local/backup/
mkdir -p /opt/setup_files/
#
# copy systemd files & rclone.conf under /opt
#
sudo /bin/cp /etc/systemd/system/zd-storage.service /opt/setup_files/
sudo /bin/cp /etc/systemd/system/mergerfs-storage.service /opt/setup_files/
/bin/cp ~/.config/rclone/rclone.conf /opt/setup_files/
#
# Down running dockers
#
cd /opt/docker/
/usr/bin/docker-compose down
#
#  Create btrfs snapshot
#
sudo btrfs subvolume delete /opt/snapshot
sudo btrfs subvolume snapshot / /opt/snapshot
#
#  Bring Docker back up
#
/usr/bin/docker-compose up -d
#
# create tar files of each folder under /opt
#
cd /opt/snapshot/opt/
/usr/bin/find . -maxdepth 1 -mindepth 1 -type d -exec tar cvf /mnt/local/backup/{}.tar {}  \;
wait
#
# delete snapshot
#
sudo btrfs subvolume delete /opt/snapshot
#
# upload to GDrive
# 
rclone move /mnt/local/backup/ GOOGLE:/backups/ --transfers=50 -vvP
wait
