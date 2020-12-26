#!/bin/bash
plexdb="/opt/plexdocker/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
plexdocker="plex"

    docker stop "${plexdocker}"
    cp "$plexdb" "$plexdb.original"
    sqlite3 "$plexdb" "DROP index 'index_title_sort_naturalsort'"
    sqlite3 "$plexdb" "DELETE from schema_migrations where version='20180501000000'"
    sqlite3 "$plexdb" .dump > /tmp/dump.sql
    rm "$plexdb"
    sqlite3 "$plexdb" "pragma page_size=32768; vacuum;"
    sqlite3 "$plexdb" "pragma default_cache_size=20000000"
    sqlite3 "$plexdb" < /tmp/dump.sql
    chown seed:seed "$plexdb"
    docker start "${plexdocker}"
