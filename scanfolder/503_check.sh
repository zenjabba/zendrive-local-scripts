#!/bin/bash
# /path/scanfolder/503_check.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -p usernamepassword -o plex -z '/path to plex db/' -w 10 -r zendrive -a zd-tv2 -j 5577 
#-w = second to wait between sends to autoscan
#-r = RCLONE mount, like zendrive or zd_storage
#-a = the folder name at the base of the mount: zd-movies,zd-tv1,zd-tv2,zd-tv3
#-d = integer for number of days
#-h = integer for number of hours
#-l = path to autoscan.db /your/path/
# do not use both -d & -h - please just one
#-j thr rclone rc port number you use

while getopts s:c:t:u:p:o:z:w:r:a:d:h:l:j:k: option; do 
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
        l) ASCAN=${OPTARG};;
        j) RCPORT=${OPTARG};;               
               
     esac
done

get_files ()
{
  rclone_refresh "$RCPORT" "$ZDTD/$SOURCE_FOLDER"  
     
  case $TRIGGER in
          movie)
                  depth=2
                  ;;
          tv|television|series)
                  depth=3
                  ;;
           music)
                  depth=3
                  ;;
          '')
                  echo "Media type parameter is empty, please check configuration options"
                  exit;
                  ;;
          *)
                  echo "Media type specified is unknown"
                  exit;
                  ;;
  esac
  unset MAXAGE
  if [ ! -z "${DAYS}" ] && [ ! -z "${HOURS}" ]; then 
     echo "Please no not use the DAYS & HOURS options together, you filthy animal";
  fi
  if [ ! -z "${DAYS}" ] && [ -z "${HOURS}" ]; then
    IFS=$'\n' 
    filelist=($(rclone lsf --files-only --absolute --max-age "${DAYS}d" --max-depth "$depth" --format pt --separator "|" "$RCLONEMOUNT:$ZDTD/$SOURCE_FOLDER"))
    unset IFS
    MAXAGE=1
  fi
  if [ -z "${DAYS}" ] && [ ! -z "${HOURS}" ]; then
    IFS=$'\n' 
    filelist=($(rclone lsf --files-only --absolute --max-age "${HOURS}h" --max-depth "$depth" --format pt --separator "|" "$RCLONEMOUNT:$ZDTD/$SOURCE_FOLDER"))
    unset IFS
    MAXAGE=1
  fi
  if [ -z ${MAXAGE+x} ]; then
     IFS=$'\n' 
    filelist=($(rclone lsf --files-only --absolute --max-depth "$depth" --format pt --separator "|" "$RCLONEMOUNT:$ZDTD/$SOURCE_FOLDER"))
    unset IFS
  fi
  check_string="code: 503"
  for i in "${filelist[@]}"
  do
     if [[ "$i" == *"$check_string"* ]]; then
        echo "${i}"        
     fi
  done
}

rclone_refresh ()
{
#set recurse = false for selected folder
echo "begining vfs/refresh recursive=false of ${2}"
VAR=$(/usr/bin/rclone rc vfs/refresh --rc-addr=localhost:"$1" _async=true recursive=false dir="$2" | grep "jobid")
JID=${VAR#*:}
JID=$(echo -e "${JID}" | tr -d '[:space:]')
VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
value=${VAR2#*:}
value=$(echo -e "${value}" | tr -d '[:space:]')
while [ "$value" != "true" ]; do
  VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
  value=${VAR2#*:}
  value=$(echo -e "${value}" | tr -d '[:space:]')
  sleep 1
done

# if recursive false retuns OK, then continue with recursive true
CHECK=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "$2")
CHECK=${CHECK:(-4)}
CHECK=${CHECK//\"/}
if [ "$CHECK" = "OK" ]; then
   echo "vfs/refresh recursive=false of ${2} completed"
   echo "beginning vfs/refresh recursive=true of ${2}"
   VAR=$(/usr/bin/rclone rc vfs/refresh --rc-addr=localhost:"$1" _async=true recursive=true dir="$2" | grep "jobid")
   JID=${VAR#*:}
   JID=$(echo -e "${JID}" | tr -d '[:space:]')
   VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
   value=${VAR2#*:}
   value=$(echo -e "${value}" | tr -d '[:space:]')
   while [ "$value" != "true" ]; do
     VAR2=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "success")
     value=${VAR2#*:} 
     value=$(echo -e "${value}" | tr -d '[:space:]')
     sleep 1
   done
   CHECK=$(/usr/bin/rclone rc --rc-addr=:"$1" job/status jobid=${JID} | grep "$2")
   CHECK=${CHECK:(-4)}
   CHECK=${CHECK//\"/}
   if [ "$CHECK" = "OK" ]; then
    echo "vfs/refresh recursive=true of ${2} completed"
   else
     echo "vfs/refresh recursive=true of ${2} failed, exiting script"
     exit
   fi
else
   echo "vfs/refresh recursive=false of ${2} failed, exiting script"
   exit
fi
}
get_files
