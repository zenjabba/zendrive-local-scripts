# Plex analayze all files that are missing analyzation info using CURL calls
# Code originally from: https://github.com/ajkis/scripts/blob/master/plex/plex-analyze-curl.py
# OS: Ubunti 16.04 ( in case of other OS's make sure to change paths )
# Replace xxx with your plex token, you can get it by:
# grep -E -o "PlexOnlineToken=.{0,22}" /opt/plex/Library/Application Support/Plex Media Server/Preferences.xml
#
# Usage - complete analysis for missing files in a particular folder
# python3 plex-analyze-curl.py movies/20s
# or
# python3 plex-analyze-curl.py tv/20s

#!/usr/bin/env python3
import sys
import requests
import sqlite3

folder=sys.argv[1]
print(folder)
conn = sqlite3.connect('/opt/plex/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db')

c = conn.cursor()
c.execute("select media_items.metadata_item_id from media_items inner join media_parts on media_parts.media_item_id=media_items.id"\
          " where media_items.bitrate IS ? AND media_parts.file LIKE ?", (None, '%'+folder+'%'))
items = c.fetchall()
conn.close()

print("To analyze: " + str( len(items) ))
for row in items:
        requests.put(url='https://plex.MYDOMAIN.COM:443/library/metadata/' + str(row[0]) + '/analyze?X-Plex-Token=XXXXXXXX')
        requests.get(url='https://plex.MYDOMAIN.COM:443/library/metadata/' + str(row[0]) + '/refresh?X-Plex-Token=XXXXXXXX')
        print(str(row[0]))
