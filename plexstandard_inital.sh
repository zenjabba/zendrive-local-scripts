#!/bin/bash
#
#   ENTER INFO HERE
function usage {
  echo ""
  echo "Usage: $0 \"Access and Secret Keys\" "
  echo ""
  echo "How to find your keys:"
  echo "    Head over to https://dashboard.zenjabba.com/ and you will find your access and secret keys listed in your services"
  echo "    They will look somthing like:"
  echo "    AABBCCDDEEFFGGHH IIJJKKLLMMNNOOPPQQRRSSTT "
  echo "    Re-run $0 with \"$0 Access_Key Secret_Key\" "
  echo ""
  exit 1
}
if [ -z "$1" ]; then
  echo "    Re-run $0 with \"$0 Access_Key Secret_Key\"
  usage
fi


ACCESS_KEY_ID="$1"       
SECRET_ACCESS_KEY="$2"   


##Shell Setup
sudo apt install -y apache2-utils bwm-ng cifs-utils git htop intel-gpu-tools iotop iperf3 ncdu nethogs nload psmisc python3-pip python-pip screen sqlite3 tmux tree unrar-free vnstat wget zsh
sudo apt remove mlocate -y
#sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

## Kernel Things
wget -O /usr/local/bin/ https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
chmod +x /usr/local/bin/ubuntu-mainline-kernel.sh
sudo /usr/local/bin/ubuntu-mainline-kernel.sh -i

## Folder Setup
sudo mkdir /mnt/{local,sharedrives,unionfs}
sudo mkdir /opt/{plex,scripts,logs,plex_db_backups,traefik,docker}
sudo mkdir /opt/scripts/{installers,media_processing,setup_files}
sudo sed -i 's|http://nl.|http://|g' /etc/apt/sources.list

## User Setup
sudo useradd -m seed
sudo usermod -aG sudo seed
password=$(date +%s | sha256sum | base64 | head -c 12)
echo -e "$password\n$passwd" | passwd seed

##Docker Setup
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
  
## and a systemd override for docker to wait for mergerfs
cat > /etc/systemd/system/docker.service.d/override.conf << "_EOF_"
[Unit]
After=mergerfs.service
[Service]
ExecStartPre=/bin/sleep 15
_EOF_

## Script Setup
curl https://rclone.org/install.sh | sudo bash -s beta
wget https://github.com/trapexit/mergerfs/releases/download/2.30.0/mergerfs_2.30.0.ubuntu-bionic_amd64.deb -P /opt/scripts/installers
sudo dpkg -i /opt/scripts/installers/mergerfs_2.30.0.ubuntu-bionic_amd64.deb
git clone https://github.com/blacktwin/JBOPS /opt/scripts/JBOPS
git clone https://github.com/zenjabba/scanfolder /opt/scripts/scanfolder
git clone https://github.com/zenjabba/zendrive-local-scripts/ /opt/scripts/zendrive-local-scripts
git clone https://github.com/zenjabba/ZenDRIVE-Poller-Binary /opt/scripts/Poller
chmod +x /opt/scripts/poller/zenlocalpoller

echo 'seed ALL=(ALL) NOPASSWD: ALL' >>/tmp/seed
sudo chown root:root /tmp/seed
sudo mv /tmp/seed /etc/sudoers.d/

### Configure Support Files
uid=$(id -u seed)
gid=$(id -g seed)

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


sudo touch /media/docker-volume.img
sudo chattr +C /media/docker-volume.img
sudo fallocate -l 40G /media/docker-volume.img
sudo mkfs -t ext4 /media/docker-volume.img
sudo rm -rf /var/lib/docker/*
sudo echo "/media/docker-volume.img /var/lib/docker ext4 defaults 0 0" >> /etc/fstab
sudo mount -a


## copy docker-compose.yml, .env, and dynamic.yml to their appropriate spots
sudo cp /opt/scripts/zendrive-local-scripts/docker-compose*.yml /opt/docker
sudo cp /opt/scripts/zendrive-local-scripts/.env /opt/docker
sudo cp /opt/scripts/zendrive-local-scripts/dynamic.yml /opt/traefik
sudo chown -R seed:seed /opt

echo "Please Reboot your Box, and hold your butt while we hope all this worked"
echo ""
echo "seed password is $password"
echo ""
echo "When your box returns edit /opt/docker/docker-compose.yml & .env to your liking"
echo " Extras are in the /opt/docker/docker-compose-extras.yml"
echo "Once you are satified, cd /opt/docker && docker-compose up -d"
echo ""
echo "you are welcome :) "
