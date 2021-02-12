#!/bin/bash
# /path/scanfolder/scanfolder.sh -s tv/10s -c /mnt/unionfs/ -t tv -u http://autoscan.TDL:3030 -p usernamepassword -o plex -z '/path to plex db/' -w 10 
#-w = second to wait between sends to autoscan
#-d = integer for number of days
#-h = integer for number of hours
#-l = path to autoscan.db /your/path/
# do not use both -d & -h - please just one

while getopts s:c:t:u:p:o:z:w:d:h:l: option; do 
    case "${option}" in
        s) SOURCE_FOLDER=${OPTARG};;
        c) CONTAINER_FOLDER=${OPTARG};;
        t) TRIGGER=${OPTARG};;
        u) URL=${OPTARG};;
        p) USERPASS=${OPTARG};;
        o) DOCKERNAME=${OPTARG};;
        z) PLEXDB=${OPTARG};;
        w) WAIT=${OPTARG};;
        d) DAYS=${OPTARG};;
        h) HOURS=${OPTARG};;
        l) ASCAN=${OPTARG};;
     esac
done

get_files ()
{
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
    filelist=($(find ${CONTAINER_FOLDER}${SOURCE_FOLDER} -maxdepth "${depth}" -mtime +"${DAYS}" -type f -printf "%p|%TY-%Tm-%Td %TH:%TM:%TS\n" | sort))
    unset IFS
    MAXAGE=1
  fi
  if [ -z "${DAYS}" ] && [ ! -z "${HOURS}" ]; then
    HOURS=$((HOURS/24)) ;
    IFS=$'\n' 
    filelist=($(find ${CONTAINER_FOLDER}${SOURCE_FOLDER}  -maxdepth "${depth}" -mtime +"${HOURS}" -type f -printf "%p|%TY-%Tm-%Td %TH:%TM:%TS\n" | sort))
    unset IFS
    MAXAGE=1
  fi
  if [ -z ${MAXAGE+x} ]; then
    IFS=$'\n' 
    filelist=($(find ${CONTAINER_FOLDER}${SOURCE_FOLDER} -maxdepth "${depth}"  -type f -printf "%p|%TY-%Tm-%Td %TH:%TM:%TS\n" | sort))
    unset IFS
  fi
  for i in "${filelist[@]}"
  do
     FOO=$(basename "${i}")     
     FOO="$(echo -e "${FOO}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
     FOO=${#FOO}  
     i2=${i%|*} 
     F2=1
     if [ "$FOO" -gt "$F2" ]; then
        if [[ ! "${i2}" =~ ".nfo" ]] && [[ ! "${i2}" =~ ".srt" ]] && [[ ! "${i2}" =~ ".bin" ]] && [[ ! "${i2}" =~ ".txt" ]] && [[ ! "${i2}" =~ ".jpg" ]] && [[ ! "${i2}" =~ ".iso" ]]; then
           d1=${i##*|}
           d2=$(date -d"${d1}" +%s)
           file_list+=("${i2}|${d2}")
        fi
     fi
  done
}

get_db_items ()
{ 
         cmd="select p.file,p.created_at from media_items m inner join media_parts p on m.id=p.media_item_id WHERE p.file LIKE '%$SOURCE_FOLDER/%'"
         if [ ! -z "$PLEXDB" ]
         then
             plex="${PLEXDB}com.plexapp.plugins.library.db"
         else
             plex="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
         fi
         db_list=()
         IFS=$'\n'
         fqry=(`sqlite3 "$plex" "$cmd"`)
         unset IFS
         for f in "${fqry[@]}"; do
           d1=${f##*|}
           d2=$(date -d"${d1}" +%s)
           f2=${f%|*} 
           db_list+=("${f2}|${d2}")
         done
}

process_autoscan () {
                          
        unset up
        if [ -z "$USERPASS" ]; then up=""; else up="-u $USERPASS"; fi
        curl -G --request POST --url "${URL}/triggers/manual" --data-urlencode "dir=${1}" $up > /dev/null    
        if [[ $? -ne 0 ]]; then
                echo $1 >> /tmp/failedscans.txt
                echo "Unable to reach autoscan ERROR: $?"
        else
          echo "$(date +"%F %T,%3N"): $1 added to your autoscan queue!" 
          if [ -z "$WAIT" ]
          then
              sleep 10
          else
              sleep "$WAIT"
          fi
        fi
}

autoscan_check ()
{
         i3="${g//\'/''}"
         sql="SELECT EXISTS(SELECT 1 FROM scan WHERE folder like '%$i3%' LIMIT 1)"
         if [ -z "$ASCAN" ] 
         then
                scan="/opt/autoscan/autoscan.db"
         else
                scan="${ASCAN}autoscan.db"
         fi
         check=0
         FOO="$(echo -e "${g}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
         FOO=${#FOO}  
         F2=1
         if [ "`sqlite3 "$scan" "$sql"`" != "0" ] && [ "$FOO" -gt "$F2" ]
         then
            check=1
         fi
}

get_files
[[ ${#file_list[@]} -eq 0 ]] && { echo "No new media to process"; exit; }
get_db_items
IFS=$'\n'
mapfile -t missing_files < <( comm -13 --nocheck-order <(printf '%s\n' "${db_list[@]}" | LC_ALL=C sort) <(printf '%s\n' "${file_list[@]}" | LC_ALL=C sort) )
unset IFS
declare -a farray
for i in "${missing_files[@]}"; 
do
  f=("$(cut -d '|' -f1 <<< "$i")");
  f=${f//[$'\t\r\n']}
  if [ $TRIGGER == "music" ]; then
    echo "skip"
    farray+=("${f}")
  else
    farray+=("$(dirname "${f}")")
  fi
done
IFS=$'\n'
readarray -t uniq < <(printf '%s\n' "${farray[@]}" | sort -u)
unset IFS
c=1
for i2 in "${uniq[@]}"; 
do 
  g=${i2//[$'\t\r\n']}
  if [ ! -z "$g" ]; then
     if [ "${g}" != "${CONTAINER_FOLDER}${SOURCE_FOLDER}" ]; then
        autoscan_check
        if [ "$check" -eq "0" ]; then
           process_autoscan "${g}";
           c=$[$c +1]
        fi
     fi
  fi
done
echo "${c} files processed"
