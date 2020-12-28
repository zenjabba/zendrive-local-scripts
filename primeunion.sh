#!/bin/bash
# This pre-primes the ZenDRIVE Union for instant startup of Plex
find /mnt/sharedrives/zd-storage/zd-anime  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-audiobooks  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-courses  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-movies  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-movies-non-english  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-sports  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-tv1  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-tv2  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-tv3  -type d -maxdepth 3 > /dev/null 2>&1 &
find /mnt/sharedrives/zd-storage/zd-tv-non-english  -type d -maxdepth 3 > /dev/null 2>&1 &
# we need to wait till it's all done before we hand back control
wait

while [ ! -f /mnt/unionfs/mounted.bin ]
do
  sleep 2 # or less like 0.2
done
