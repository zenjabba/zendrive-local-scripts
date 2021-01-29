#!/bin/bash
# /path/scanfolder/diff_copy.sh -a 5 -b /mnt/unionfs/mymovies/ -c myrclone:mypath -d zdinbound:some_path -e (tv or movie) -p '/path to plex db/'
while getopts a:b:c:d:e:p: option; do 
    case "${option}" in
        a) SECID=${OPTARG};;
        b) YOURMEDIA=${OPTARG};;
        c) YOURRCLONE=${OPTARG};;
        d) ZDRCLONE=${OPTARG};; 
        e) MEDIATYPE=${OPTARG};; 
        p) PLEXDB=${OPTARG};; 
     esac
done

send_to_rclone ()
{
          PUSH=$(rclone copy --files-from "${1}" "${YOURRCLONE}" "${ZDRCLONE}" -vP --stats=10s --drive-use-trash=false --transfers 16 --checkers=16 --tpslimit 4 --tpslimit-burst 32)
}

process_diff ()
{
        if [ ! -z "$PLEXDB" ]
         then
             plex="${PLEXDB}com.plexapp.plugins.library.db"
         else
             plex="/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
        fi
        unset cmd
        case $MEDIATYPE in
          movie)
cmd="SELECT \
p.file \
FROM metadata_items md \
inner join media_items m ON m.metadata_item_id=md.id \
inner join media_parts p on m.id=p.media_item_id \
WHERE md.library_section_id = '$SECID' and md.guid NOT IN \
( \
SELECT \
md2.guid \
FROM metadata_items md2 \
inner join media_items m2 ON m2.metadata_item_id=md2.id \
inner join media_parts p2 on m2.id=p2.media_item_id \
WHERE md2.library_section_id = '$SECID' AND p2.file NOT LIKE '%$YOURMEDIA%' \
)"                 
                  ;;
          tv|television|series)
          cmd="SELECT \
          DISTINCT p.file AS TVSHOW \
          FROM metadata_items md \
          inner join media_items m ON m.metadata_item_id=md.id \
          inner join media_parts p on m.id=p.media_item_id \
          WHERE md.library_section_id = '$SECID' and md.guid NOT IN \
          ( \
          SELECT \
          md2.guid \
          FROM metadata_items md2 \
          inner join media_items m2 ON m2.metadata_item_id=md2.id \
          inner join media_parts p2 on m2.id=p2.media_item_id \
          WHERE md2.library_section_id = '$SECID' AND p2.file NOT like '%$YOURMEDIA%' \
          ) \
          ORDER BY TVSHOW"
          ;;
          '')
                  echo "Media type parameter is empty"
                  exit;
                  ;;
          *)
                  echo "Media type specified unknown"
                  exit;
                  ;;
        esac
        db_list=()
        IFS=$'\n'
        fqry=(`sqlite3 "$plex" "$cmd"`)
        unset IFS
        for f in "${fqry[@]}"; do
          f=${f//[$'\t\r\n']}
          db_list+=("${f}")
        done
}

process_diff
printf '%s\n' "${db_list[@]}"
IFS=$'\n'
readarray -t uniq < <(printf '%s\n' "${db_list[@]}" | sort -u)
unset IFS
tmpfile=$(mktemp)
for i2 in "${uniq[@]}";
do 
  fname=$(basename "${i2}")
  path=$(dirname "${i2}")
  path=$(basename "${path}")  
  f1="${path}/${fname}" 
  f2="${i2#*/*/*/*/*/}" 
  if [ -f "$tmpfile" ]
  then
    case $MEDIATYPE in
        movie)
            echo "$f1" >> "$tmpfile"
            ;;
        tv|television|series)
            echo "$f2" >> "$tmpfile"
            ;;
        '')
            echo "Media type parameter is empty"
            exit;
            ;;
        *)
            echo "Media type specified unknown"
            exit;
            ;;
    esac          
  fi
done
send_to_rclone "$tmpfile"
rm "$tmpfile"
