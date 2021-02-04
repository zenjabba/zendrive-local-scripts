#/bin/bash
echo "deb https://download.ceph.com/debian-octopus/ bionic main" >> /etc/apt/sources.list.d/ceph.list
wget https://download.ceph.com/keys/release.asc
sudo apt-key add release.asc
rm release.asc
sudo apt update
sudo apt remove ceph-common -y
sudo apt install ceph-common -y
