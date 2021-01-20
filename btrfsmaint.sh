#!/bin/bash
#Clones btrfsmaintenance repo.  Copies service/timer files and enables them. 
#Change the user (seed) to match your setup
git clone https://github.com/kdave/btrfsmaintenance.git /opt/btrfsmaintenance
sudo chmod -R 775 /opt/btrfsmaintenance
sudo chown -R seed:seed /opt/btrfsmaintenance
sed -i 's/BTRFS_TRIM_MOUNTPOINTS=.*/BTRFS_TRIM_MOUNTPOINTS="auto"/g' /opt/btrfsmaintenance/sysconfig.btrfsmaintenance
sudo /opt/btrfsmaintenance/dist-install.sh
sudo cp /opt/btrfsmaintenance/*.timer /etc/systemd/system
sudo cp /opt/btrfsmaintenance/*.service /etc/systemd/system
sudo /opt/btrfsmaintenance/btrfsmaintenance-refresh-cron.sh timer
