#/bin/bash
mkdir -p /etc/ceph
echo "deb https://download.ceph.com/debian-octopus/ bionic main" >> /etc/apt/sources.list.d/ceph.list
echo "[global]
        fsid = ae0bd11a-6639-11eb-9fa4-0050569051a7
        mon_host = [v2:10.10.3.22:3300/0,v1:10.10.3.22:6789/0] [v2:10.10.3.11:3300/0,v1:10.10.3.11:6789/0] [v2:10.10.3.12:3300/0,v1:10.10.3.12:6789/0] [v2:10.10.3.13:3300/0,v1:10.10.3.13:6789/0] [v2:10.10.3.14:3300/0,v1:10.10.3.14:6789/0]" > /etc/ceph/ceph.conf
wget https://download.ceph.com/keys/release.asc
sudo apt-key add release.asc
rm release.asc
sudo apt update
sudo apt remove ceph-common -y
sudo apt install ceph-common -y
