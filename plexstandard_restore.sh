#!/bin/bash
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
sudo mkdir /opt/{plexdocker,scripts,logs}
sudo mkdir /opt/scripts/{installers,media_processing}
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
  ExecStartPre=/bin/sleep 120
  _EOF_

## Script Setup
curl https://rclone.org/install.sh | sudo bash -s beta
wget https://github.com/trapexit/mergerfs/releases/download/2.30.0/mergerfs_2.30.0.ubuntu-bionic_amd64.deb -P /opt/scripts/installers
sudo dpkg -i /opt/scripts/installers/mergerfs_2.30.0.ubuntu-bionic_amd64.deb
git clone https://github.com/blacktwin/JBOPS /opt/scripts/JBOPS
git clone https://github.com/zenjabba/scanfolder /opt/scripts/scanfolder

## Networking
# get back comma delimited AK,SK which I will push into an array and do variable replacement in rclone.conf
cat >/etc/sysctl.conf <<"_EOF_"
net.ipv4.tcp_window_scaling=1
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 87380 33554432
net.ipv4.tcp_congestion_control=bbr
fs.file-max=100000
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=10
net.core.somaxconn=1024
net.core.netdev_max_backlog=100000
net.ipv4.tcp_max_syn_backlog=30000
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_adv_win_scale=2
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.udp_rmem_min=8192
net.ipv4.udp_wmem_min=8192
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.core.default_qdisc=fq
fs.inotify.max_user_watches=131072
net.core.netdev_budget=50000
net.core.netdev_budget_usecs=5000
_EOF_

## Service File Setup
cat >/etc/systemd/system/mergerfs.service <<"_EOF_"
[Unit]
Description=MergerFS Mount
After=network-online.target zd-storage.service zd-tv.service

[Service]
Type=forking
GuessMainPID=no
ExecStartPre=-/usr/bin/sudo /bin/mkdir -p /mnt/unionfs
ExecStartPre=-/usr/bin/sudo /bin/chmod -R 775 /mnt/unionfs
ExecStartPre=-/usr/bin/sudo /bin/chown -R root:root /mnt/unionfs
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/mergerfs \
  -o category.create=ff,async_read=false \
  -o dropcacheonclose=true,use_ino,minfreespace=0 \
  -o xattr=nosys,statfs_ignore=ro,allow_other,umask=002,noatime \
  /mnt/local/=RW:/mnt/sharedrives/zd-storage/zd-*=RO:/mnt/sharedrives/zd-td/=RO /mnt/unionfs
ExecStop=/bin/fusermount -u /mnt/unionfs

[Install]
WantedBy=default.target
_EOF_

cat >/etc/systemd/system/zd-storage.service <<"_EOF_"
[Unit]
Description=ZenStorage Mount
After=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStartPre=-/usr/bin/sudo /bin/mkdir -p /mnt/sharedrives/zd-storage
ExecStartPre=-/usr/bin/sudo /bin/chmod -R 775 /mnt/sharedrives/zd-storage
ExecStartPre=-/usr/bin/sudo /bin/chown -R root:root /mnt/sharedrives/zd-storage
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/rclone mount \
 --config=/root/.config/rclone/rclone.conf \
  --allow-other \
  --allow-non-empty \
  --async-read=true \
  --s3-chunk-size=256M \
  --rc \
  --rc-addr=localhost:5590 \
  --buffer-size=64M \
  --dir-cache-time 8760h \
  --attr-timeout 8760h
  --timeout=10m \
  --umask=002 \
  --log-file=/var/log/rclone-union.log \
  zd-storage: /mnt/sharedrives/zd-storage
ExecStop=/bin/fusermount -uz /mnt/sharedrives/zd-storage
Restart=on-abort
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=default.target
_EOF_

cat >/etc/systemd/system/zd-td.service <<"_EOF_"
[Unit]
Description=ZenTD Mount
After=network-online.target

[Service]
Type=notify
User=root
Group=root
ExecStartPre=-/usr/bin/sudo /bin/mkdir -p /mnt/sharedrives/zd-td
ExecStartPre=-/usr/bin/sudo /bin/chmod -R 775 /mnt/sharedrives/zd-td
ExecStartPre=-/usr/bin/sudo /bin/chown -R root:root /mnt/sharedrives/zd-td
ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/rclone mount \
  --config=/root/.config/rclone/rclone.conf \
  --exclude 'movies/10s/**' \
  --exclude 'movies/20s/**' \
  --exclude 'movies/4k/**' \
  --exclude 'movies/4k-dv/**' \
  --exclude 'tv/70s/**' \
  --exclude 'tv/80s/**' \
  --exclude 'tv/90s/**' \
  --exclude 'tv/00s/**' \
  --allow-other \
  --allow-non-empty \
  --rc \
  --rc-addr=localhost:5591 \
  --vfs-read-ahead=128M \
  --vfs-read-chunk-size=64M \
  --vfs-read-chunk-size-limit=2G \
  --vfs-cache-mode=full \
  --vfs-cache-max-age=24h \
  --vfs-cache-max-size=100G \
  --buffer-size=64M \
  --dir-cache-time=1h \
  --timeout=10m \
  --umask=002 \
  -v \
  zd-td: /mnt/sharedrives/zd-td
ExecStop=/bin/fusermount -uz /mnt/sharedrives/zd-td
Restart=on-abort
RestartSec=5
#StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=default.target
_EOF_

mkdir -p /root/.config/rclone/
cat >>/root/.config/rclone/rclone.conf <<"_EOF_"
[zd-storage]
type = s3
provider = Minio
disable_http2 = true
endpoint = https://zendrives3.digitalmonks.org/
access_key_id = ABCD
secret_access_key = EFGH
_EOF_

echo 'seed ALL=(ALL) NOPASSWD: ALL' >>/tmp/seed
sudo chown root:root /tmp/seed
sudo mv /tmp/seed /etc/sudoers.d/

systemctl start mergerfs.service
systemctl enable mergerfs.service
systemctl start zd-storage.service
systemctl enable zd-storage.service

### Configure Support Files
uid=$(id -u seed)
gid=$(id -g seed)

echo ""
echo "seed password is $password"
echo ""
