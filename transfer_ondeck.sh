#!/bin/bash
set -x
#coffee_keeper script to keep playlist/on-deck
#NOTE: playlist and on-deck only work when transferring between db's with the same scan base.
#move your old db into the plexbase Databases folder but named as keep.db


cp com.plexapp.plugins.library.db plexbase.db
rm *.sql

#keep.db has the watch-data and playlist-data (and accounts/devices/etc) you want to keep
#com.plexapp.plugins.library.db has the database and libraries you want to use
#clear com.plexapp.plugins.library.db
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_views;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_settings;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_bandwidth;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_media;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_resources;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM accounts;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM devices;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM play_queue_generators;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_accounts;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_items WHERE metadata_type = 15;"
sqlite3 com.plexapp.plugins.library.db "DROP INDEX index_title_sort_naturalsort;"

#save from keep.db
echo ".dump metadata_item_settings" | sqlite3 keep.db | grep -v TABLE | grep -v INDEX > metadata_item_settings.sql
echo ".dump accounts" | sqlite3 keep.db | grep -v TABLE | grep -v INDEX > accounts.sql
echo ".dump devices" | sqlite3 keep.db | grep -v TABLE | grep -v INDEX > devices.sql
echo ".dump play_queue_generators" | sqlite3 keep.db | grep -v TABLE | grep -v INDEX > 1playqueue.sql
echo ".dump metadata_item_accounts" | sqlite3 keep.db | grep -v TABLE | grep -v INDEX > 1metadata_item_accounts.sql
sqlite3 keep.db ".mode insert metadata_items" ".output 1metadata_list.sql" "SELECT id, library_section_id, parent_id, metadata_type, guid, media_item_count, title, title_sort, original_title, studio, rating, rating_count, tagline, summary, trivia, quotes, content_rating, content_rating_age, \"index\", absolute_index, duration, user_thumb_url, user_art_url, user_banner_url, user_music_url, user_fields, tags_genre, tags_collection, tags_director, tags_writer, tags_star, originally_available_at, available_at, expires_at, refreshed_at, year, added_at, created_at, updated_at, deleted_at, tags_country, extra_data, hash, audience_rating, changed_at, resources_changed_at, remote FROM metadata_items WHERE metadata_type = 15;"
sleep 5

#find next row_id for metadata_items
echo `sqlite3 com.plexapp.plugins.library.db "SELECT MAX(id) FROM metadata_items;"` > lastrow.txt
i=($(cat lastrow.txt))
i=$((i+1))
k=0

#create db for find-replace
old=(1 2 5)
new=(1 2 5)
echo `sqlite3 keep.db "SELECT id FROM metadata_items WHERE metadata_type = 15;"` > db.txt
old=($(cat db.txt))
for j in "${old[@]}"
do
   echo $j
   new[$k]="$i"
   ((i=i+1))
   ((k=k+1))
done

#run find-replace in files
until [ $l -gt $k ]
do
  ((m=l-1))
  sed -i "s/${old[$m]}/${new[$m]}/" "1metadata_list.sql"
  sed -i "s/${old[$m]}/${new[$m]}/" "1playqueue.sql"
  sed -i "s/${old[$m]}/${new[$m]}/" "1metadata_item_accounts.sql"
  ((l=l+1))
done

sleep 10

cp com.plexapp.plugins.library.db com.plexapp.plugins.library.db.bak
#clear com.plexapp.plugins.library.db
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_views;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_settings;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_bandwidth;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_media;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM statistics_resources;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM accounts;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM devices;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM play_queue_generators;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_item_accounts;"
sqlite3 com.plexapp.plugins.library.db "DELETE FROM metadata_items WHERE metadata_type = 15;"
sqlite3 com.plexapp.plugins.library.db "DROP INDEX index_title_sort_naturalsort;"

#replace with data from keep.db
cat metadata_item_settings.sql | sqlite3 com.plexapp.plugins.library.db
cat accounts.sql | sqlite3 com.plexapp.plugins.library.db
#cat devices.sql | sqlite3 com.plexapp.plugins.library.db
cat 1playqueue.sql | sqlite3 com.plexapp.plugins.library.db
cat 1metadata_item_accounts.sql | sqlite3 com.plexapp.plugins.library.db
cat 1metadata_list.sql | sqlite3 com.plexapp.plugins.library.db

echo "New database imported. Previous accounts and watch data has been kept"
sleep 5

rm *.sql
rm db.txt
rm lastrow.txt