#!/bin/bash
#
#   ENTER INFO HERE
ACCESS_KEY_ID=""       # enter your ID here
SECRET_ACCESS_KEY=""   # enter KEY here
RESTORE_PATH=""        #  provide the path to your S3 backup
#



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
sudo mkdir /opt/{plex,scripts,logs}
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
ExecStartPre=/bin/sleep 60
_EOF_

## Script Setup
curl https://rclone.org/install.sh | sudo bash -s beta
wget https://github.com/trapexit/mergerfs/releases/download/2.30.0/mergerfs_2.30.0.ubuntu-bionic_amd64.deb -P /opt/scripts/installers
sudo dpkg -i /opt/scripts/installers/mergerfs_2.30.0.ubuntu-bionic_amd64.deb
git clone https://github.com/blacktwin/JBOPS /opt/scripts/JBOPS
git clone https://github.com/zenjabba/scanfolder /opt/scripts/scanfolder

echo 'seed ALL=(ALL) NOPASSWD: ALL' >>/tmp/seed
sudo chown root:root /tmp/seed
sudo mv /tmp/seed /etc/sudoers.d/

### Configure Support Files
uid=$(id -u seed)
gid=$(id -g seed)

## CREATE S3 BACKUP RCLONE CONF
cat > /home/seed/.config/rclone/rclone.conf << "_EOF_"
[zd-backup]
type = s3
provider = Minio
region = us-east-1
chunk_size = 256M
disable_http2 = true
access_key_id = ${ACCESS_KEY_ID}
secret_access_key = ${SECRET_ACCESS_KEY}
endpoint = https://zenhosting-backup.zenterprise.org/
_EOF_

## BEGIN RESTORE
#
ID=${ACCESS_KEY_ID:0:48}
rclone COPY zd-backup:${ID}/${RESTORE_PATH}/ /opt/ -P
wait
#
# Extract backup Tars
cd /opt
tar -xvf *.tar
wait
rm *.tar
sudo chown -R seed:seed /opt
wait
cd /opt/setup_files
FILE=/opt/setup_files/.bashrc
if [ -f "$FILE" ]; then sudo cp .bashrc /home/seed/; fi
FILE=/opt/setup_files/limits.conf
if [ -f "$FILE" ]; then sudo cp limits.conf /etc/security/; fi
sudo cp *.service /etc/systemd/system/
sudo systemctl daemon-reload
FILE=/opt/setup_files/zd-storage-metadata.service
if [ -f "$FILE" ]; then sudo systemctl enable zd-storage-metadata.service; fi
FILE=/opt/setup_files/zd-storage-small.service
if [ -f "$FILE" ]; then sudo systemctl enable zd-storage-small.service; fi
FILE=/opt/setup_files/zd-storage.service
if [ -f "$FILE" ]; then sudo systemctl enable zd-storage.service; fi
FILE=/opt/setup_files/mergerfs.service
if [ -f "$FILE" ]; then sudo systemctl enable mergerfs.service; fi
FILE=/opt/setup_files/poller.service
if [ -f "$FILE" ]; then sudo systemctl enable poller.service; fi
sudo systemctl daemon-reload
# end service files
FILE=/opt/setup_files/rclone.conf
if [ -f "$FILE" ]; then /bin/cp /opt/setup_files/rclone.conf /home/seed/.config/rclone/; fi
FILE=/opt/setup_files/config.yml
if [ -f "$FILE" ]; then /bin/cp /opt/setup_files/config.yml /home/seed/.config/plexapi/; fi

echo "Please Reboot your Box, and hold your butt while we hope all this worked"
echo ""
echo "seed password is $password"
echo ""
