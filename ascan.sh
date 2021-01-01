
#!/bin/bash
# Helper script for manual scans with Cloudbox autoscan 1.0 OR above
# uses the new manual scan function
function usage {
  echo ""
  echo "Usage: ascan.sh \"Path to media\" "
  echo ""
  echo "Examples:"
  echo "    ascan.sh \"/mnt/unionfs/Media/TV/Series/Season 1/Episode 01.mkv\" "
  echo "    ascan.sh \"/mnt/unionfs/Media/Movies/Movie Folder/Movie.mkv\" "
  exit 1
}
if [ -z "$1" ]; then
  echo "Media path parameter is empty!"
  usage
fi
curl -G --request POST --url "http://127.0.0.1:3030/triggers/manual" --data-urlencode "dir=${1}"
if [ $? -ne 0 ]; then echo "Unable to reach autoscan ERROR: $?";fi
if [ $? -eq 0 ]; then echo "$1 added to your autoscan queue!";fi
