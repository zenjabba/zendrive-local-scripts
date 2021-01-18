#!/bin/bash
find /opt/plex_db_backups/* -mtime +12 -exec rm {} \;
