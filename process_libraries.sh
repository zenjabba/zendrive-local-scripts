#!/bin/bash
# AUTOSCAN ZENSTORAGE FOLDERS
# $1 = section type 
# $2 = days to look back
# $3 = VFS/Refresh = 1 or leave empty if not needed
#
if [ "${1}" == "tv" ]; then
## TV ##
/opt/scripts/update_libraries.sh tv/20s tv zd-tv2 tv_20s.log "${2}" "${3}" > /opt/logs/tv_20s.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/10s tv zd-tv2 tv_10s.log "${2}" "${3}" > /opt/logs/tv_10s.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/00s tv zd-tv1 tv_00s.log "${2}" "${3}" > /opt/logs/tv_00s.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/90s tv zd-tv1 tv_90s.log "${2}" "${3}" > /opt/logs/tv_90s.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/80s tv zd-tv1 tv_80s.log "${2}" "${3}" > /opt/logs/tv_80s.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/70s tv zd-tv1 tv_70s.log "${2}" "${3}" > /opt/logs/tv_70s.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/4k tv zd-tv3 tv_4k.log "${2}" "${3}" > /opt/logs/tv_4k.log 2>&1 && \
/opt/scripts/update_libraries.sh tv/anime tv zd-anime tv_anime.log "${2}" "${3}" > /opt/logs/tv_anime.log 2>&1
/opt/scripts/update_libraries.sh tv/anime-dub tv zd-anime tv_anime_dub.log "${2}" "${3}" > /opt/logs/tv_anime_dub.log 2>&1
fi
## Movies ##
if [ "${1}" == "movie" ]; then
/opt/scripts/update_libraries.sh movies/20s movie zd-movies movie_20s.log "${2}" "${3}" > /opt/logs/movie_20s.log 2>&1  && \
/opt/scripts/update_libraries.sh movies/10s movie zd-movies movie_10s.log "${2}" "${3}" > /opt/logs/movie_10s.log 2>&1  && \
/opt/scripts/update_libraries.sh movies/00s movie zd-movies movie_00s.log "${2}" "${3}" > /opt/logs/movie_00s.log 2>&1  && \
/opt/scripts/update_libraries.sh movies/90s movie zd-movies movie_90s.log "${2}" "${3}" > /opt/logs/movie_90s.log 2>&1  && \
/opt/scripts/update_libraries.sh movies/80s movie zd-movies movie_80s.log "${2}" "${3}" > /opt/logs/movie_80s.log 2>&1  && \
/opt/scripts/update_libraries.sh movies/70s movie zd-movies movie_70s.log "${2}" "${3}" > /opt/logs/movie_70s.log 2>&1  && \
/opt/scripts/update_libraries.sh movies/4k-dv movie zd-movies movie_4k_dv.log "${2}" "${3}" > /opt/logs/movie_4k_dv.log 2>&1 && \
/opt/scripts/update_libraries.sh movies/4k movie zd-movies movie_4k.log "${2}" "${3}" > /opt/logs/movie_4k.log 2>&1
fi
## Special ##
if [ "${1}" == "special" ]; then
/opt/scripts/update_libraries.sh audiobooks/Audiobooks_English music zd-audiobooks audiobooks_english.log "${2}" "${3}" > /opt/logs/audiobooks_english.log 2>&1  && \
/opt/scripts/update_libraries.sh courses/masterclass tv zd-courses courses_masterclass.log "${2}" "${3}" > /opt/logs/courses_masterclass.log 2>&1 && \
/opt/scripts/update_libraries.sh courses/plex_courses tv zd-courses courses_plex_courses.log "${2}" "${3}" > /opt/logs/courses_plex_courses.log 2>&1 && \
/opt/scripts/update_libraries.sh courses/exercise tv zd-courses courses_exercise.log "${2}" "${3}" > /opt/logs/courses_exercise.log 2>&1 && \
/opt/scripts/update_libraries.sh sports/sportsdb tv zd-sports sports_sportsdb.log "${2}" "${3}" > /opt/logs/sports_sportsdb.log 2>&1
fi
## German ##
if [ "${1}" == "german" ]; then
/opt/scripts/update_libraries.sh tv_non-english/German/tv tv zd-tv-non-english tv_german.log "${2}" "${3}" > /opt/logs/tv_german.log 2>&1  && \
/opt/scripts/update_libraries.sh movies-non-english/German/movies movie zd-movies-non-english movies_german.log "${2}" "${3}" > /opt/logs/movies_german.log 2>&1  && \
/opt/scripts/update_libraries.sh movies-non-english/German/4k movie zd-movies-non-english movies_4k_german.log "${2}" "${3}" > /opt/logs/movies_4k_german.log 2>&1
fi
## asian ##
if [ "${1}" == "asian" ]; then
/opt/scripts/update_libraries.sh tv_non-english/asian tv zd-tv-non-english tv_asian.log "${2}" "${3}" > /opt/logs/tv_asian.log 2>&1  && \
/opt/scripts/update_libraries.sh movies-non-english/Bollywood movie zd-movies-non-english movies_bollywood.log "${2}" "${3}" > /opt/logs/movies_bollywood.log 2>&1
fi
