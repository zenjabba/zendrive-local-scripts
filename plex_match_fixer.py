#!/usr/bin/env python3


# This needs a specific fork+branch of plexapi till it's merged upstream:
# pip3 install --force -U --user
# git+git://github.com/darthShadow/python-plexapi@temp-guids-split


import re
import time
import logging
import multiprocessing
from urllib.parse import urlparse

import plexapi
import plexapi.server
import plexapi.exceptions


PLEX_REQUESTS_SLEEP = 0
PLEX_URL = "http://<plex_ip>:32400"
PLEX_TOKEN = "<plex_token>"
NFO_PATH_MAPPING = ""
SKIP_SECTIONS = {
    "Movies": False,
    "Movies - 4K": False,
    "Movies - 4K DV": False,
    "Movies - Anime": False,
    "TV Shows": False,
    "TV Shows - 4K": False,
    "TV Shows - Asian": False,
    "TV Shows - Anime": False,
    "Audiobooks": True,
    "Courses": True,
    "Fitness": True,
    "Sports": True,
}


MOVIE_SECTIONS = [
    "Movies",
    "Movies - 4K",
    "Movies - 4K DV",
    "Movies - Anime",
]
TV_SECTIONS_1 = [
    "TV Shows",
]
TV_SECTIONS_2 = [
    "TV Shows - 4K",
    "TV Shows - Anime",
    "TV Shows - Asian",
]
MISC_SECTIONS = [
    "Audiobooks",
    "Courses",
    "Sports",
]
TV_ID_REGEX = r"^(?P<title>.*?)\[?(?P<imdb_id>tt[0-9]+)?\]?\[?(?P<tvdb_id>[" \
              r"0-9]+)?\]?$"
MOVIE_ID_REGEX = r"^(?P<title>.*?)\[?(?P<imdb_id>tt[0-9]+)\]?\/?(?P<file>.*)$"
AGENT_ID_REGEX = {
    "Movies": MOVIE_ID_REGEX,
    "Movies - 4K": MOVIE_ID_REGEX,
    "Movies - 4K DV": MOVIE_ID_REGEX,
    "TV Shows - Anime": TV_ID_REGEX,
}
TV_GUID_REGEX = r".*?(?P<tvdb_id>[0-9]+).*?"


LOG_FORMAT = \
    "[%(name)s][%(process)05d][%(asctime)s][%(levelname)-8s][%(funcName)-15s]"\
    " %(message)s"
LOG_DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
LOG_LEVEL = logging.INFO
LOG_FILE = "/home/<username>/scripts/plex-match-fixer.log"


plexapi.server.TIMEOUT = 3600
plexapi.server.X_PLEX_CONTAINER_SIZE = 500
logger = logging.getLogger("PlexMatchFixer")


def _fix_item_match(item, item_agent, item_agent_id, sleep_interval):
    item_matches = item.matches(agent=item_agent, title=item_agent_id)

    if len(item_matches) <= 0:
        logger.warning(f"No Agent Matches : {item.title} "
                       f"({item.year}) : {item_agent_id}")
        return

    if len(item_matches) > 2:
        logger.warning(f"Multiple Agent Matches : {item.title} "
                       f"({item.year}) : {item_agent_id}")
        for match in item_matches:
            logger.warning('-----')
            logger.warning(
                f"Match : {match.name} ({match.year}) :"
                f" {match.score} : {match.guid}")
            logger.warning('-----')
        return

    try:
        item.fixMatch(searchResult=item_matches[0], auto=False)
        item.refresh()
    except Exception:
        logger.exception(f"Matching & Refreshing Item : {item.title} ("
                         f"{item.year})")

    time.sleep(PLEX_REQUESTS_SLEEP)
    time.sleep(sleep_interval)


def _fix_movie_section_match(section):
    skip_section = SKIP_SECTIONS.get(section, False)
    if skip_section:
        return

    agent_id_regex = AGENT_ID_REGEX.get(section, "")
    if agent_id_regex == "":
        return

    plex = plexapi.server.PlexServer(PLEX_URL, PLEX_TOKEN, timeout=300)
    items = plex.library.section(section).all()
    unmatched_items = dict()
    mismatched_items = dict()

    for item_index, item in enumerate(items):

        logger.debug(f"{item.title} ({item.year}) : {item.guid}")

        if len(item.locations) <= 0:
            logger.warning(f"No Locations for Item : "
                           f"{item.title} ({item.year})")
            continue

        item_location = item.locations[0]
        item_agent_id_match = re.match(agent_id_regex, item_location)
        if item_agent_id_match is None or item_agent_id_match.group(
                "imdb_id") is None:
            logger.warning(f"Failed to match Agent ID : {item.title} "
                           f"({item.year}) : {item_location}")
            continue

        try:
            item_agent_id = item_agent_id_match.group("imdb_id")

            if len(item.locations) > 1:
                logger.debug(f"Multiple Locations for Item : "
                             f"{item.title} ({item.year}) : "
                             f"{', '.join(item.locations)}")

                item_agent_ids = set()
                item_agent_ids.add(item_agent_id)

                for item_location in item.locations[1:]:
                    location_agent_id_match = re.match(
                        agent_id_regex, item_location)
                    if (location_agent_id_match is None or
                            location_agent_id_match.group("imdb_id") is None):
                        logger.warning("Failed to match Agent ID : "
                                       f"{item.title} ({item.year}) : "
                                       f"{item_location}")
                        continue

                    location_agent_id = location_agent_id_match.group(
                        "imdb_id")
                    item_agent_ids.add(location_agent_id)

                if len(item_agent_ids) > 1:
                    logger.warning(f"Multiple Agent ID(s) for Item : "
                                   f"{item.title} ({item.year}) : "
                                   f"{', '.join(item_agent_ids)} : "
                                   f"{', '.join(item.locations)}")
                    item.split()
                    continue

            if urlparse(item.guid).scheme == 'local':
                logger.info(f"Unmatched Item : {item.title}"
                            f" ({item.year}) : {item_agent_id} :"
                            f" {item.guid}")
                unmatched_items[item_agent_id] = item

            elif len(item.guids) == 0:
                logger.info(f"Unmatched Item : {item.title}"
                            f" ({item.year}) : {item_agent_id} :"
                            f" {item.guid} : {item.guids}")
                unmatched_items[item_agent_id] = item

            else:
                item_guids = [guid.id for guid in item.guids]
                if f"imdb://{item_agent_id}" not in item_guids:
                    logger.info(f"Mismatched Item : {item.title}"
                                f" ({item.year}) : {item_agent_id} :"
                                f" {item.guid} : {', '.join(item_guids)}")
                    mismatched_items[item_agent_id] = item
        except plexapi.exceptions.BadRequest:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.NotFound:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.PlexApiException:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except Exception:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")

        finally:
            time.sleep(PLEX_REQUESTS_SLEEP)

    total_items = len(items)
    total_unmatched_items = len(unmatched_items.keys())
    total_mismatched_items = len(mismatched_items.keys())
    logger.info(f"Section : {section} | Total Items : {total_items} | "
                f"Unmatched Items : {total_unmatched_items} | "
                f"Mismatched Items : {total_mismatched_items}")

    logger.info(f"Section : {section} | Fixing Unmatched Items")

    for item_index, item_agent_id in enumerate(unmatched_items.keys()):
        item = unmatched_items[item_agent_id]

        logger.info(
            f"[ {item_index + 1: >5} / {total_unmatched_items: >5} ] "
            f"Section : {section} | Title : {item.title} "
            f"({item.year}) : {item_agent_id} | Matching"
        )

        _fix_item_match(item, "movie", item_agent_id, 5)

    logger.info(f"Section : {section} | Fixing Mismatched Items")

    for item_index, item_agent_id in enumerate(mismatched_items.keys()):
        item = mismatched_items[item_agent_id]

        logger.info(
            f"[ {item_index + 1: >5} / {total_mismatched_items: >5} ] "
            f"Section : {section} | Title : {item.title} "
            f"({item.year}) : {item_agent_id} | Matching"
        )

        _fix_item_match(item, "movie", item_agent_id, 5)


def _fix_tv_section_match(section):
    skip_section = SKIP_SECTIONS.get(section, False)
    if skip_section:
        return

    agent_id_regex = AGENT_ID_REGEX.get(section, "")
    if agent_id_regex == "":
        return

    plex = plexapi.server.PlexServer(PLEX_URL, PLEX_TOKEN, timeout=300)
    items = plex.library.section(section).all()
    unmatched_items = dict()
    mismatched_items = dict()

    for item_index, item in enumerate(items):

        logger.debug(f"{item.title} ({item.year}) : {item.guid}")

        if len(item.locations) <= 0:
            logger.warning(f"No Locations for Item : "
                           f"{item.title} ({item.year})")
            continue

        item_location = item.locations[0]
        item_agent_id_match = re.match(agent_id_regex, item_location)
        if item_agent_id_match is None or item_agent_id_match.group(
                "tvdb_id") is None:
            logger.warning(f"Failed to match Agent ID : {item.title} "
                           f"({item.year}) : {item_location}")
            continue

        try:
            item_agent_id = item_agent_id_match.group("tvdb_id")

            if len(item.locations) > 1:
                logger.debug(f"Multiple Locations for Item : "
                             f"{item.title} ({item.year}) : "
                             f"{', '.join(item.locations)}")

                item_agent_ids = set()
                item_agent_ids.add(item_agent_id)

                for item_location in item.locations[1:]:
                    location_agent_id_match = re.match(
                        agent_id_regex, item_location)
                    if (location_agent_id_match is None or
                            location_agent_id_match.group("tvdb_id") is None):
                        logger.warning("Failed to match Agent ID : "
                                       f"{item.title} ({item.year}) : "
                                       f"{item_location}")
                        continue

                    location_agent_id = location_agent_id_match.group(
                        "tvdb_id")
                    item_agent_ids.add(location_agent_id)

                if len(item_agent_ids) > 1:
                    logger.warning(f"Multiple Agent ID(s) for Item : "
                                   f"{item.title} ({item.year}) : "
                                   f"{', '.join(item_agent_ids)} : "
                                   f"{', '.join(item.locations)}")
                    item.split()
                    continue

            if urlparse(item.guid).scheme == 'local':
                logger.info(f"Unmatched Item : {item.title}"
                            f" ({item.year}) : {item_agent_id} :"
                            f" {item.guid}")
                unmatched_items[item_agent_id] = item

            else:
                item_guid_match = re.match(TV_GUID_REGEX, item.guid)
                if item_guid_match is None or item_guid_match.group(
                        "tvdb_id") is None:
                    logger.warning(f"Failed to match Agent GUID : {item.title}"
                                   f" ({item.year}) : {item.guid}")
                    continue

                item_guid = item_guid_match.group("tvdb_id")

                if item_agent_id != item_guid:
                    logger.info(f"Mismatched Item : {item.title}"
                                f" ({item.year}) : {item_agent_id} :"
                                f" {item.guid}")
                    mismatched_items[item_agent_id] = item
        except plexapi.exceptions.BadRequest:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.NotFound:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.PlexApiException:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except Exception:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")

        finally:
            time.sleep(PLEX_REQUESTS_SLEEP)

    total_items = len(items)
    total_unmatched_items = len(unmatched_items.keys())
    total_mismatched_items = len(mismatched_items.keys())
    logger.info(f"Section : {section} | Total Items : {total_items} | "
                f"Unmatched Items : {total_unmatched_items} | "
                f"Mismatched Items : {total_mismatched_items}")

    logger.info(f"Section : {section} | Fixing Unmatched Items")

    for item_index, item_agent_id in enumerate(unmatched_items.keys()):
        item = unmatched_items[item_agent_id]

        logger.info(
            f"[ {item_index + 1: >5} / {total_unmatched_items: >5} ] "
            f"Section : {section} | Title : {item.title} "
            f"({item.year}) : {item_agent_id} | Matching"
        )

        _fix_item_match(item, "thetvdb", item_agent_id, 60)

    logger.info(f"Section : {section} | Fixing Mismatched Items")

    for item_index, item_agent_id in enumerate(mismatched_items.keys()):
        item = mismatched_items[item_agent_id]

        logger.info(
            f"[ {item_index + 1: >5} / {total_mismatched_items: >5} ] "
            f"Section : {section} | Title : {item.title} "
            f"({item.year}) : {item_agent_id} | Matching"
        )

        _fix_item_match(item, "thetvdb", item_agent_id, 60)


def _setup_logger():
    logging.Formatter.converter = time.gmtime
    logging.raiseExceptions = False

    logger.setLevel(logging.DEBUG)
    logger.handlers = []
    logger.propagate = False

    detailed_formatter = logging.Formatter(fmt=LOG_FORMAT,
                                           datefmt=LOG_DATE_FORMAT)
    file_handler = logging.FileHandler(filename=LOG_FILE, mode="a+")
    file_handler.setFormatter(detailed_formatter)
    file_handler.setLevel(LOG_LEVEL)

    logger.addHandler(file_handler)


def _refresh_movie_sections():
    for section in MOVIE_SECTIONS:
        _fix_movie_section_match(section)


def _refresh_tv_sections_1():
    for section in TV_SECTIONS_1:
        _fix_tv_section_match(section)


def _refresh_tv_sections_2():
    for section in TV_SECTIONS_2:
        _fix_tv_section_match(section)


def _refresh_misc_sections():
    return


def main():
    _setup_logger()

    process_list = [
        multiprocessing.Process(target=_refresh_movie_sections, args=()),
        multiprocessing.Process(target=_refresh_tv_sections_1, args=()),
        multiprocessing.Process(target=_refresh_tv_sections_2, args=()),
        multiprocessing.Process(target=_refresh_misc_sections, args=()),
    ]

    for idx, process in enumerate(process_list):
        print("Started Worker ::: {0}".format(idx + 1))
        process.start()

    for process in process_list:
        process.join()


if __name__ == "__main__":
    main()
