#!/bin/bash
cd /mnt/unionfs && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/20s > /opt/logs/analyze_tv_20s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/10s > /opt/logs/analyze_tv_10s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/00s > /opt/logs/analyze_tv_00s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/90s > /opt/logs/analyze_tv_90s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/80s > /opt/logs/analyze_tv_80s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/70s > /opt/logs/analyze_tv_70s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/4k > /opt/logs/analyze_tv_4k.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/anime > /opt/logs/analyze_tv_anime.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py tv/anime-dub > /opt/logs/analyze_tv_anime_dub.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/20s > /opt/logs/analyze_movies_20s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/10s > /opt/logs/analyze_movies_10s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/00s > /opt/logs/analyze_movies_00s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/90s > /opt/logs/analyze_movies_90s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/80s > /opt/logs/analyze_movies_80s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/70s > /opt/logs/analyze_movies_70s.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/4k > /opt/logs/analyze_movies_4k.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py movies/4k-dv > /opt/logs/analyze_movies_4k-dv.log 2>&1  && \
python3 /opt/scripts/scanfolder/plex-analyze-curl.py sports/sportsdb > /opt/logs/analyze_sports_sportsdb.log 2>&1
