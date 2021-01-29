# scanfolder

this will compare the contents of a folder against your plex database and add any missing content to AUTOSCAN

```
# /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -p usernamepassword -o plex -z '/path to plex db/' -w 10 -r zendrive -a zd-tv2
#-w = second to wait between sends to autoscan
#-r = RCLONE mount, like zendrive or zd_storage
#-a = the folder name at the base of the mount: zd-movies,zd-tv1,zd-tv2,zd-tv3
#-d = integer for number of days
#-h = integer for number of hours
# do not use both -d & -h
#
#
while getopts s:c:t:u:p:o:z:w:r:a:d:h: option; do 
    case "${option}" in
        s) SOURCE_FOLDER=${OPTARG};;
        c) CONTAINER_FOLDER=${OPTARG};;
        t) TRIGGER=${OPTARG};;
        u) URL=${OPTARG};;
        p) USERPASS=${OPTARG};;
        o) DOCKERNAME=${OPTARG};;
        z) PLEXDB=${OPTARG};;
        w) WAIT=${OPTARG};;
        r) RCLONEMOUNT=${OPTARG};;
        a) ZDTD=${OPTARG};;
        d) DAYS=${OPTARG};;
        h) HOURS=${OPTARG};;
done
```
SOURCE_FOLDER = the folder you want scanfolder to look at "/tv/10s" or "/movies/10s" 

CONTAINER_FOLDER = the base folder of your union "/mnt/unionfs/"

TRIGGER = this will be either "tv" or "movie"

URL = this is your autoscan URL "http://autoscan:3030"

USERPASS = for the autoscan URL (if used) in the form of username:password

DOCKERNAME = the container name of your plex

PLEXDB = complete path to your plex DB, note, if using Cloudbox you can skip defining it

WAIT = the number of seconds to wait between sending to autoscan

RCLONEMOUNT = RCLONE mount, like zendrive or zd_storage

ZDTD = the folder name at the base of the mount: zd-movies,zd-tv1,zd-tv2,zd-tv3

DAYS = max days to go back

HOURS = max hours to go back

UPDATE:  LIDARR is now supported
your -s & -a & -t flags should like something like
```
-s audiobooks/Audiobooks_English
-a zd-audiobooks
-t music
```

So for TV it would look like:
```
seed@superplex:$ /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -d 2 -p usernamepassword -o plex -z '/path to plex db/' -w 10 -r zendrive -a zd-tv2
```
And for MOVIES it would look like:
```
seed@superplex:$/path/scanfolder/scanfolder.sh -s movies/10s -c /mnt/unionfs/ -t movie -u http://autoscan.TDL:3030 -p usernamepassword -o plex -z '/path to plex db/' -w 10 -r zendrive -a zd-movies
```

#NOTE:

the script assumes the triggers in your config.yml are sonarr & radarr

and finally a shout out to "m1lkman" for coming up with the code for the process_autoscan function
https://discord.com/channels/381077432285003776/738466261473951804/769287309123387433
