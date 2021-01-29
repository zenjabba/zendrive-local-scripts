#!/bin/bash
sudo pkill -9 docker
sudo service docker stop
cd /opt/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/
cp com.plexapp.plugins.library.db com.plexapp.plugins.library.db.original
sqlite3 com.plexapp.plugins.library.db "DROP index 'index_title_sort_naturalsort'"
sqlite3 com.plexapp.plugins.library.db "DELETE from schema_migrations where version='20180501000000'"
sqlite3 com.plexapp.plugins.library.db .dump > dump.sql
rm com.plexapp.plugins.library.db
sqlite3 com.plexapp.plugins.library.db "pragma page_size=32768; vacuum;"
sqlite3 com.plexapp.plugins.library.db "pragma default_cache_size = 20000000; vacuum;"
sqlite3 com.plexapp.plugins.library.db <dump.sql
sqlite3 com.plexapp.plugins.library.db "vacuum"
sqlite3 com.plexapp.plugins.library.db "pragma optimize"
cd ~/
sudo service docker start
/opt/docker/docker-compose down
/opt/docker docker-compose up -d
