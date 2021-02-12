#!/bin/bash
#
# Please only run this after you run preinstall and create your config file
# get variables

### Configure Support Files
uid=$(id -u seed)
gid=$(id -g seed)

### shell setup
shellsetup() {
    echo 'Shell Setup'
    ##Shell Setup
    sudo apt install -y apache2-utils bwm-ng cifs-utils git htop intel-gpu-tools iotop iperf3 ncdu nethogs nload psmisc python3-pip python-pip screen sqlite3 tmux tree unrar-free vnstat wget zsh
    sudo apt remove mlocate -y
    ## Kernel Things
    wget -O /usr/local/bin/ https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
    chmod +x /usr/local/bin/ubuntu-mainline-kernel.sh
    sudo /usr/local/bin/ubuntu-mainline-kernel.sh -i 5.10.1
}

### install-ceph

installceph () {
mkdir -p /etc/ceph
mkdir -p /mnt/sharedrives/zd-storage-ceph
echo "deb https://download.ceph.com/debian-octopus/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/ceph.list
echo "[global]
        fsid = ae0bd11a-6639-11eb-9fa4-0050569051a7
        mon_host = [v2:10.10.3.22:3300/0,v1:10.10.3.22:6789/0] [v2:10.10.3.11:3300/0,v1:10.10.3.11:6789/0] [v2:10.10.3.12:3300/0,v1:10.10.3.12:6789/0] [v2:10.10.3.13:3300/0,v1:10.10.3.13:6789/0] [v2:10.10.3.14:3300/0,v1:10.10.3.14:6789/0]" > /etc/ceph/ceph.conf
echo "[client.guest]
        key = AQBWHhxgeRcTBRAAeLsjFI134LB6ZnZCoWQNKw==" > /etc/ceph/ceph.client.guest.keyring
echo ":/ /mnt/sharedrives/zd-storage-ceph ceph name=guest,noatime,_netdev 0 2" >> /etc/fstab
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
sudo apt update -y
sudo apt remove ceph-common -y
sudo apt install ceph-common -y
}

### folder setup
foldersetup() {
    echo 'Folder Setup'
    sudo mkdir /mnt/{local,unionfs}
    sudo mkdir /opt/{plex,scripts,logs,plex_db_backups,traefik,docker}
    sudo mkdir /opt/scripts/installers
}
### repo setup
reposetup() {
    echo 'Repo Setup'
    git clone https://github.com/zenjabba/zendrive-local-scripts/ /opt/scripts/zendrive
    git clone https://github.com/blacktwin/JBOPS /opt/scripts/JBOPS
    sudo sed -i 's|http://nl.|http://|g' /etc/apt/sources.list
}

### user setup
usersetup() {
    echo 'User Setup'
    sudo useradd -m seed
    sudo usermod -aG sudo seed
    password=$(date +%s | sha256sum | base64 | head -c 12)
    echo -e "$password\n$passwd" | passwd seed
    #sudo chown seed:seed /opt/{plex,scripts,logs,plex_db_backups,traefik,docker}
}

### docker setup
dockersetup() {
    echo 'Docker Setup'
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io -y
    sudo usermod -aG docker seed
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    sudo apt-get upgrade -y 
    # create pseudo file-system for docker
    sudo touch /media/docker-volume.img
    sudo chattr +C /media/docker-volume.img
    sudo fallocate -l 20G /media/docker-volume.img
    sudo mkfs -t ext4 /media/docker-volume.img
    sudo rm -rf /var/lib/docker/*
    sudo echo "/media/docker-volume.img /var/lib/docker ext4 defaults 0 0" >> /etc/fstab
    sudo mount -a

    ## copy docker-compose.yml, .env, and dynamic.yml to their appropriate spots
    sudo cp /opt/scripts/zendrive/docker-compose*.yml /opt/docker
    sudo cp /opt/scripts/zendrive/.env /opt/docker
    sudo cp /opt/scripts/zendrive/dynamic.yml /opt/traefik
    sudo chown -R seed:seed /opt

### copy sample files but not overwrite
samplesetup() {
    cd /opt/scripts/zendrive
    rsync -a -v --ignore-existing config.conf.sample config.conf
    rsync -a -v --ignore-existing .env.sample .env
    rsync -a -v --ignore-existing backup-restore/backupbtrfs_files.txt.sample backup-restore/backupbtrfs_files.txt
    rsync -a -v --ignore-existing backup-restore/backupbtrfs.conf.sample backup-restore/backupbtrfs.conf
    rsync -a -v --ignore-existing plex-scripts/scanfolder.conf.sample plex-scripts/scanfolder.conf
    rsync -a -v --ignore-existing backup-restore/plexstandard_restore.conf.sample backup-restore/plexstandard_restore.conf

}

### script things
scriptsetup() {
    echo 'seed ALL=(ALL) NOPASSWD: ALL' >>/tmp/seed
    sudo chown root:root /tmp/seed
    sudo mv /tmp/seed /etc/sudoers.d/
}


### message
message() {
    echo "Please Reboot your Box, and hold your butt while we hope all this worked"
    echo ""
    echo "When your box returns edit /opt/docker/docker-compose.yml & .env to your liking"
    echo "Extras are in the /opt/docker/docker-compose-extras.yml"
    echo "Once you are satified, cd /opt/docker && docker-compose up -d"
    echo "CloudBox can suck it, we have evolved."
    echo "This is the way :) " 
    echo "@@@@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@
@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@
@@@@@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@
@@@@@@@@@@(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@
@@@@@@@@#(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@
@@@@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%@@@@@@
@@@@@@(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@
@@@@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((&@@@
@@@(((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@
@((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,*@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@#,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((((((((((((((((((((((((((((((((((((((
@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((((((((((((((((((((((((((((((((((((((((@
@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(((((((((((((((((((((((((((((((((((((((((@@@
@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,/((((((((((((((((((((((((((((((((((((((((((@@@@
@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,((((((((((((((((((((((((((((((((((((((((((((@@@@@
@@@@@@@@,,,,,,,,,,,,,,,,,,,,(((((((((((((((((((((((((((((((((((((((((((((@@@@@@@
@@@@@@@@@@,,,,,,,,,,,,,,,(((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@
@@@@@@@@@@@,,,,,,,,,,,((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@
@@@@@@@@@@@@@,,,,,,((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@
@@@@@@@@@@@@@@,,(((((((((((((((((((((((((((((((((((((((((((((((((((&@@@@@@@@@@@@"
}

main() {
    shellsetup
    foldersetup
    installceph
    usersetup
    reposetup
    samplesetup
    scriptsetup
    dockersetup
    message
}
