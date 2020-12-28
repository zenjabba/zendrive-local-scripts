#!/bin/bash
# Helper script for manual scans with Cloudbox autoscan

function usage {
  echo ""
  echo "Usage: ascan \"Path to media\" mediaType"
  echo ""
  echo "Examples:"
  echo "    ascan \"/mnt/unionfs/Media/TV/Series/Season 1/Episode 01.mkv\" tv"
  echo "    ascan \"/mnt/unionfs/Media/Movies/Movie Folder/Movie.mkv\" movie"
  exit 1
}

if [ -z "$1" ]; then
  echo "Media path parameter is empty!"
  usage
fi

case $2 in
  movie)
      arrType="radarr"
      folderPath=$(dirname "$1")
      relativePath=$(basename "$1")
      jsonData='{"eventType": "Download", "movie": {"folderPath": "'"$folderPath"'"}, "movieFile": {"relativePath": "'"$relativePath"'"}}'
      ;;
  tv|television|series)
      arrType="sonarr"
      folderPath=$(dirname "$(dirname "$1")")
      relativePath="$(basename "$(dirname "$1")")/$(basename "$1")"
      jsonData='{"eventType": "Download","episodeFile": {"relativePath": "'"$relativePath"'"},"series": {"path": "'"$folderPath"'"}}'
      ;;
  '')
      echo "Media type parameter is empty"
      usage
      ;;
  *)
      echo "Media type specified unknown"
      usage
      ;;
esac

curl -d "$jsonData" -H "Content-Type: application/json" http://127.0.0.1:3030/triggers/$arrType -u username:password > /dev/null
if [ $? -ne 0 ]; then echo "Unable to reach autoscan ERROR: $?";fi
echo "$1 added to your autoscan queue!"
