#!/bin/bash
#
# Please only run this after you run preinstall and create your config file
# get variables
. /opt/scripts/zendrive/config.conf

### pre-check
precheck() {
    echo "Checking if Preinstall has been ran"
    if [ ! -e "/opt/scripts/zendrive/.preinstall" ]; then
        echo "Preinstall has not been run ..." 
        exit 1
    else
        echo "Preinstall has been run ..."
        echo "Check for config file ..."
        if [ ! -e "/opt/scripts/zendrive/config.conf" ]; then
            echo "Config file does not exist. please create ..." 
            exit 1
        else
            echo "Config file exists ..."
        fi
    fi
}


### script things
scriptsetup() {
    echo 'seed ALL=(ALL) NOPASSWD: ALL' >>/tmp/seed
    sudo chown root:root /tmp/seed
    sudo mv /tmp/seed /etc/sudoers.d/
}

### S3 backup rclone conf
backuprclone() {
    echo 'Backup Rclone Setup'
    ## CREATE S3 BACKUP RCLONE CONF
    cat > /home/seed/.config/rclone/rclone.conf << "_EOF_"
[zenstorage]
type = s3
provider = Minio
region = us-east-1
chunk_size = 256M
disable_http2 = true
access_key_id = ${ACCESS_KEY_ID}
secret_access_key = ${SECRET_ACCESS_KEY}
endpoint = https://zendrives3.digitalmonks.org/
_EOF_
    cat >> /home/seed/.config/rclone/rclone.conf << "_EOF_"
[zenstorage-metadata]
type = s3
provider = Minio
region = us-east-1
chunk_size = 256M
disable_http2 = true
access_key_id = ${ACCESS_KEY_ID}
secret_access_key = ${SECRET_ACCESS_KEY}
endpoint = https://zendrives3-metadata.digitalmonks.org/
_EOF_
    cat >> /home/seed/.config/rclone/rclone.conf << "_EOF_"
[zenstorage-small]
type = s3
provider = Minio
region = us-east-1
chunk_size = 256M
disable_http2 = true
access_key_id = ${ACCESS_KEY_ID}
secret_access_key = ${SECRET_ACCESS_KEY}
endpoint = https://zendrives3-small.digitalmonks.org/
_EOF_
}

### Configure Support Files
uid=$(id -u seed)
gid=$(id -g seed)

### docker setup
dockersetup() {
    echo 'Docker Setup'
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
}

### service file setup
servicefilesetup() {
    echo 'Service File Setup'
    ## SYMLINK the Service Files ##
    ln -s /opt/scripts/zendrive/services/mergerfs.service /etc/systemd/system/mergerfs.service
    ln -s /opt/scripts/zendrive/services/zd-storage.service /etc/systemd/system/zd-storage.service
    ln -s /opt/scripts/zendrive/services/zd-storage-small.service /etc/systemd/system/zd-storage-small.service
    ln -s /opt/scripts/zendrive/services/zd-storage-metadata.service /etc/systemd/system/zd-storage-metadata.service
    ln -s /opt/scripts/zendrive/zendrive-local/scripts/primeunion.sh /opt/scripts/primeunion.sh
    chmod +x /opt/scripts/primeunion.sh
    cp /home/seed/.config/rclone/rclone.conf /root/.config/rclone/rclone.conf
    sudo systemctl daemon-reload
    sudo systemctl enable mergerfs.service
    sudo systemctl enable zd-storage.service
    sudo systemctl enable zd-storage-small.service
    sudo systemctl enable zd-storage-metadata.service
}

### message
message() {
    echo "Please Reboot your Box, and hold your butt while we hope all this worked"
    echo ""
    echo "When your box returns edit /opt/docker/docker-compose.yml & .env to your liking"
    echo " Extras are in the /opt/docker/docker-compose-extras.yml"
    echo "Once you are satified, cd /opt/docker && docker-compose up -d"
    echo "CloudBox can suck it, we have evolved."
    echo "This is the way :) " 
    touch /opt/scripts/zendrive/.preinstall
}

main() {
    precheck
    scriptsetup
    backuprclone
    dockersetup
    servicefilesetup
    message
}