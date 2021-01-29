#!/bin/bash
#
#
function usage {
  echo ""
  echo "Usage: vfs_refresh.sh \"PORT\" \"AREA TO REFRESH\" \"Y or N\" for VFSRefresh "
  echo ""
  echo "Choose from the list below:"
  echo "    vfs_refresh.sh \"5590\" \"TV\" "
  echo "    vfs_refresh.sh \"5590\" \"TV4K\" "
  echo "    vfs_refresh.sh \"5590\" \"TVANIME\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIES\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIES4K\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIES3D\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIESANIME\" "
  echo "    vfs_refresh.sh \"5590\" \"AUDIOBOOKS\" "
  echo "    vfs_refresh.sh \"5590\" \"MASTERCLASSES\" "
  echo "    vfs_refresh.sh \"5590\" \"COURSES\" "
  echo "    vfs_refresh.sh \"5590\" \"SPORTS\" "
  echo ""
  echo "    ---NON-ENGLISH CONTENT---"
  echo "    vfs_refresh.sh \"5590\" \"TVDANISH\" "
  echo "    vfs_refresh.sh \"5590\" \"TVDUTCH\" "
  echo "    vfs_refresh.sh \"5590\" \"TVGERMAN\" "  
  echo "    vfs_refresh.sh \"5590\" \"TVNORWEGIAN\" "
  echo "    vfs_refresh.sh \"5590\" \"TVASIAN\" "
  echo "    vfs_refresh.sh \"5590\" \"AUDIODANISH\" "
  echo "    vfs_refresh.sh \"5590\" \"AUDIODUTCH\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIESDANISH\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIESDUTCH\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIESGERMAN\" "  
  echo "    vfs_refresh.sh \"5590\" \"MOVIESSWEDISH\" "
  echo "    vfs_refresh.sh \"5590\" \"MOVIESNORDIC4K\" "  
  exit 1
}

if [ -z "$1" ] && [ -z "$2" ] && [ -z "$3" ]; then
  echo "please provide a port number and Media type and if you want VFS/REFRESH Done"
  usage
fi

if [ -z "$1" ]; then
  echo "please provide a port number"
  usage
fi

if [ -z "$2" ]; then
  echo "please provide an area to refresh"
  usage
fi

if [ -z "$3" ]; then
  echo "please use Y or N "
  echo "to indicate if you want to use VFS Refresh"
  echo "you generally want Y for TV"
  usage
fi

rclone_refresh ()
{
#set recurse = false for selected folder
echo "beginning vfs/refresh recursive=false of ${2}"
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
   if [ "$USEVFS" != "1" ]; then
    echo "No VFS Cache so NO recursive=true"
   else
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
    fi
else
   echo "vfs/refresh recursive=false of ${2} failed, exiting script"
   exit
fi
}

if [ "${3}" = "Y" ]; then USEVFS="1"; else USEVFS=""; fi

if [ "$2" = "TV" ]; then
    #TV 
    rclone_refresh "${1}" "zd-tv2/tv/20s" &
    rclone_refresh "${1}" "zd-tv2/tv/10s" &
    rclone_refresh "${1}" "zd-tv1/tv/00s" &
    rclone_refresh "${1}" "zd-tv1/tv/90s" &
    rclone_refresh "${1}" "zd-tv1/tv/80s" &
    rclone_refresh "${1}" "zd-tv1/tv/70s" &
fi

if [ "$2" = "TV4K" ]; then
    #4K TV
    rclone_refresh "${1}" "zd-tv3/tv/4k" &
fi

if [ "$2" = "TVANIME" ]; then
    #TV Anime
    rclone_refresh "${1}" "zd-anime/tv/anime" &
    rclone_refresh "${1}" "zd-anime/tv/anime-dub" & 
fi

if [ "$2" = "AUDIOBOOKS" ]; then
    #Audiobooks
    rclone_refresh "${1}" "zd-audiobooks/audiobooks/Audiobooks_English" &
fi

if [ "$2" = "MASTERCLASSES" ]; then
    #Master Classes
    rclone_refresh "${1}" "zd-courses/courses/masterclass" &
fi

if [ "$2" = "COURSES" ]; then
    #Courses
    rclone_refresh "${1}" "zd-courses/courses/plex_courses" &
fi

if [ "$2" = "EXERCISE" ]; then
    #Exercise
    rclone_refresh "${1}" "zd-courses/courses/exercise" &
fi

if [ "$2" = "SPORTS" ]; then
    #Sports
    rclone_refresh "${1}" "zd-sports/sports/sportsdb" &
fi

## NON-English TV##
if [ "$2" = "TVDANISH" ]; then
    rclone_refresh "${1}" "zd-tv-non-english/tv_non-english/Danish" &
fi
if [ "$2" = "TVDUTCH" ]; then
    rclone_refresh "${1}" "zd-tv-non-english/tv_non-english/Dutch" &
fi
if [ "$2" = "TVGERMAN" ]; then
    rclone_refresh "${1}" "zd-tv-non-english/tv_non-english/German" &
fi
if [ "$2" = "TVNORWEGIAN" ]; then
    rclone_refresh "${1}" "zd-tv-non-english/tv_non-english/Norwegian" &
fi
if [ "$2" = "TVSWEDISH" ]; then
    rclone_refresh "${1}" "zd-tv-non-english/tv_non-english/Swedish" &
fi
if [ "$2" = "TVASIAN" ]; then
    rclone_refresh "${1}" "zd-tv-non-english/tv_non-english/asian" &
fi

## NON-English AUDIOBOOKS##
if [ "$2" = "AUDIODANISH" ]; then
    rclone_refresh "${1}" "zd-audiobooks-non-english/audiobooks/Audiobooks_Danish" &
fi
if [ "$2" = "AUDIOGERMAN" ]; then
    rclone_refresh "${1}" "zd-audiobooks-non-english/audiobooks/Audiobooks_German" &
fi


if [ "$2" = "MOVIES" ]; then
    #Movies
    rclone_refresh "${1}" "zd-movies/movies/20s" &
    rclone_refresh "${1}" "zd-movies/movies/10s" &
    rclone_refresh "${1}" "zd-movies/movies/00s" &
    rclone_refresh "${1}" "zd-movies/movies/90s" &
    rclone_refresh "${1}" "zd-movies/movies/80s" &
    rclone_refresh "${1}" "zd-movies/movies/70s" &
fi

## NON-English Movies##
if [ "$2" = "MOVIESDANISH" ]; then
    rclone_refresh "${1}" "zd-movies-non-english/movies-non-english/Danish" &
fi
if [ "$2" = "MOVIESDUTCH" ]; then
    rclone_refresh "${1}" "zd-movies-non-english/movies-non-english/Dutch" &
fi
if [ "$2" = "MOVIESGERMAN" ]; then
    rclone_refresh "${1}" "zd-movies-non-english/movies-non-english/German" &
fi
if [ "$2" = "MOVIESSWEDISH" ]; then
    rclone_refresh "${1}" "zd-movies-non-english/movies-non-english/Swedish" &
fi
if [ "$2" = "MOVIESNORDIC4K" ]; then
    rclone_refresh "${1}" "zd-movies-non-english/movies-non-english/Movies-4k-Nordic" &
fi

if [ "$2" = "MOVIES4K" ]; then
    #Movies 4K
    rclone_refresh "${1}" "zd-movies/movies/4k" &
    rclone_refresh "${1}" "zd-movies/movies/4k-dv" &
fi

if [ "$2" = "MOVIES3D" ]; then
    #Movies 3d
    rclone_refresh "${1}" "zd-movies/movies/3d" &
fi

if [ "$2" = "MOVIESANIME" ]; then
    #Movies Anime
    rclone_refresh "${1}" "zd-anime/movies/anime" &    
fi

wait
echo ""
echo ""
echo "all mount vfs/refreshes for ${2} have finished"
