#/bin/bash
mkdir -p /etc/ceph
mkdir -p /mnt/sharedrives/zd-storage-ceph
version=$(lsb_release -a)
echo "deb https://download.ceph.com/debian-octopus/ $version main" >> /etc/apt/sources.list.d/ceph.list
echo "[global]
        fsid = ae0bd11a-6639-11eb-9fa4-0050569051a7
        mon_host = [v2:10.10.3.22:3300/0,v1:10.10.3.22:6789/0] [v2:10.10.3.11:3300/0,v1:10.10.3.11:6789/0] [v2:10.10.3.12:3300/0,v1:10.10.3.12:6789/0] [v2:10.10.3.13:3300/0,v1:10.10.3.13:6789/0] [v2:10.10.3.14:3300/0,v1:10.10.3.14:6789/0]" > /etc/ceph/ceph.conf
echo "[client.guest]
        key = AQBWHhxgeRcTBRAAeLsjFI134LB6ZnZCoWQNKw==" > /etc/ceph/ceph.client.guest.keyring
echo ":/ /mnt/sharedrives/zd-storage-ceph ceph name=guest,noatime,_netdev 0 2" >> /etc/fstab
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
sudo apt update
sudo apt remove ceph-common -y
sudo apt install ceph-common -y
