#!/bin/bash
# AUTOSCAN ZENSTORAGE FOLDERS
# $1 = section type 
# $2 = days to look back
# 
#
if [ "${1}" == "tv" ]; then
## TV ##
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/20s tv tv_20s.log "${2}" > /opt/logs/tv_20s.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/10s tv tv_10s.log "${2}" > /opt/logs/tv_10s.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/00s tv tv_00s.log "${2}" > /opt/logs/tv_00s.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/90s tv tv_90s.log "${2}" > /opt/logs/tv_90s.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/80s tv tv_80s.log "${2}" > /opt/logs/tv_80s.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/70s tv tv_70s.log "${2}" > /opt/logs/tv_70s.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/4k tv tv_4k.log "${2}" > /opt/logs/tv_4k.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/anime tv tv_anime.log "${2}" > /opt/logs/tv_anime.log 2>&1
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv/anime-dub tv tv_anime_dub.log "${2}" > /opt/logs/tv_anime_dub.log 2>&1
fi
## Movies ##
if [ "${1}" == "movie" ]; then
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/20s movie movie_20s.log "${2}" > /opt/logs/movie_20s.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/10s movie movie_10s.log "${2}" > /opt/logs/movie_10s.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/00s movie movie_00s.log "${2}" > /opt/logs/movie_00s.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/90s movie movie_90s.log "${2}" > /opt/logs/movie_90s.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/80s movie movie_80s.log "${2}" > /opt/logs/movie_80s.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/70s movie movie_70s.log "${2}" > /opt/logs/movie_70s.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/4k-dv movie movie_4k_dv.log "${2}" > /opt/logs/movie_4k_dv.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies/4k movie movie_4k.log "${2}" > /opt/logs/movie_4k.log 2>&1
fi
## Special ##
if [ "${1}" == "special" ]; then
/opt/scripts/zendrive/plex-scripts/update_libraries.sh audiobooks/Audiobooks_English music audiobooks_english.log "${2}" > /opt/logs/audiobooks_english.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh courses/masterclass tv courses_masterclass.log "${2}" > /opt/logs/courses_masterclass.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh courses/plex_courses tv courses_plex_courses.log "${2}" > /opt/logs/courses_plex_courses.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh courses/exercise tv courses_exercise.log "${2}"  > /opt/logs/courses_exercise.log 2>&1 && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh sports/sportsdb tv sports_sportsdb.log "${2}" > /opt/logs/sports_sportsdb.log 2>&1
fi
## German ##
if [ "${1}" == "german" ]; then
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv_non-english/German/tv tv tv_german.log "${2}" > /opt/logs/tv_german.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies-non-english/German/movies movie movies_german.log "${2}"  > /opt/logs/movies_german.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies-non-english/German/4k movie movies_4k_german.log "${2}" > /opt/logs/movies_4k_german.log 2>&1
fi
## asian ##
if [ "${1}" == "asian" ]; then
/opt/scripts/zendrive/plex-scripts/update_libraries.sh tv_non-english/asian tv tv_asian.log "${2}" > /opt/logs/tv_asian.log 2>&1  && \
/opt/scripts/zendrive/plex-scripts/update_libraries.sh movies-non-english/Bollywood movie movies_bollywood.log "${2}"  > /opt/logs/movies_bollywood.log 2>&1
fi
