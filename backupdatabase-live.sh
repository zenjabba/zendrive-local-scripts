#/bin/bash
CLOUDBACKUPLOCATION="GOOGLE:Backups/plex/DB/"
EPOC=`date +"%d-%b-%Y-%H-%M-%S"`

#plex1
FILE="/opt/plex/Library/Application Support/Plex Media Server/Preferences.xml"
PLEX_LOCATION=https://plex.TLD
DATABASE_BACKUP_LOCATION=/mnt/local/Backups/
check_exist ()
if test -f "$FILE"; then
        :
else
        echo "$FILE doesn't exist, please check your command line options"
        exit 7
fi
check_exist
curl -o "$DATABASE_BACKUP_LOCATION/plexdbbk+$EPOC.zip" $PLEX_LOCATION/diagnostics/databases?X-Plex-Token=`cat "$FILE" | sed -e 's;^.* PlexOnlineToken=";;' | sed -e 's;".*$;;' | tail -1`
cp "/opt/plex/Library/Application Support/Plex Media Server/Preferences.xml" "/mnt/local/Backups/Preferences.xml"
