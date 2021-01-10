#!/usr/bin/env python3


# This needs a specific fork+branch of plexapi till it's merged upstream:
# pip3 install --force -U --user
# git+git://github.com/darthShadow/python-plexapi@temp-guids-split


import time
import logging
import multiprocessing

import plexapi
import plexapi.server
import plexapi.exceptions

BATCH_SIZE = 100
PLEX_URL = "http://<plex_ip>:32400"
PLEX_TOKEN = "<plex_token>"
PLEX_REQUESTS_SLEEP = 0
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


LOG_FORMAT = \
    "[%(name)s][%(process)05d][%(asctime)s][%(levelname)-8s][%(funcName)-15s]"\
    " %(message)s"
LOG_DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
LOG_LEVEL = logging.INFO
LOG_FILE = "/home/<username>/scripts/plex-missing-metadata-refresher.log"


plexapi.server.TIMEOUT = 3600
plexapi.server.X_PLEX_CONTAINER_SIZE = 500


# refresh_queue = multiprocessing.Manager().Queue()
logger = logging.getLogger("PlexMetadataRefresher")


def _item_iterator(plex_section, start, batch_size):

    items = plex_section.search(
        container_start=start,
        maxresults=batch_size,
    )

    for item in items:
        item.reload(checkFiles=True)
        yield item


def _batch_get(plex_section, batch_size):

    start = 0

    while True:
        if start >= plex_section.totalSize:
            break

        yield from _item_iterator(plex_section, start, batch_size)

        start = start + 1 + batch_size


def _refresh_items(section, missing_metadata_items,
                   total_missing_metadata_items, analyze=True):

    logger.info(f"Section : {section} | Refreshing Items with Missing "
                "Metadata")

    for item_index, item in enumerate(missing_metadata_items):

        logger.info(f"[ {item_index + 1: >5} / "
                    f"{total_missing_metadata_items: >5} ] "
                    f"Section : {section} | Title : {item.title} | Refreshing")

        try:

            item.refresh()

            if analyze:
                item.analyze()

        except plexapi.exceptions.BadRequest:
            logger.exception(f"Refreshing Item : {item.title} ({item.year})")
        except plexapi.exceptions.NotFound:
            logger.exception(f"Refreshing Item : {item.title} ({item.year})")
        except plexapi.exceptions.PlexApiException:
            logger.exception(f"Refreshing Item : {item.title} ({item.year})")
        except Exception:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")

        finally:
            time.sleep(PLEX_REQUESTS_SLEEP)
            time.sleep(60)


def _refresh_missing_movie_section(section):

    skip_section = SKIP_SECTIONS.get(section, False)
    if skip_section:
        return

    plex = plexapi.server.PlexServer(PLEX_URL, PLEX_TOKEN, timeout=300)
    plex_section = plex.library.section(section)
    total_items = plex_section.totalSize

    missing_metadata_items = []

    for item in _batch_get(plex_section, BATCH_SIZE):

        try:

            if not item.thumb or len(item.guids) == 0 or len(item.media) == 0 \
                    or item.media[0].bitrate == 0:
                logger.info(f"Metadata Missing for Item : {item.title}"
                            f" ({item.year})")
                missing_metadata_items.append(item)

        except plexapi.exceptions.BadRequest:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
            missing_metadata_items.append(item)
        except plexapi.exceptions.NotFound:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.PlexApiException:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except Exception:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")

        finally:
            time.sleep(PLEX_REQUESTS_SLEEP)

    total_missing_metadata_items = len(missing_metadata_items)
    logger.info(
        f"Section : {section} | Total Items : {total_items} | "
        f"Items with Missing Metadata : {total_missing_metadata_items}"
    )

    _refresh_items(section, missing_metadata_items,
                   total_missing_metadata_items)

    time.sleep(900)


def _refresh_missing_tv_section(section):

    skip_section = SKIP_SECTIONS.get(section, False)
    if skip_section:
        return

    plex = plexapi.server.PlexServer(PLEX_URL, PLEX_TOKEN, timeout=300)
    plex_section = plex.library.section(section)
    total_items = plex_section.totalSize

    missing_metadata_items = []

    for item in _batch_get(plex_section, BATCH_SIZE):

        missing_metadata = False

        try:

            if not item.thumb:
                missing_metadata = True

            for episode in item.episodes():
                if not episode.thumb or len(episode.media) == 0 or \
                        episode.media[0].bitrate == 0:
                    missing_metadata = True
                    logger.debug(f"Metadata Missing for Episode :"
                                 f" {episode.title}")

        except plexapi.exceptions.BadRequest:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
            missing_metadata = True
        except plexapi.exceptions.NotFound:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.PlexApiException:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except Exception:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")

        finally:
            time.sleep(PLEX_REQUESTS_SLEEP)

        if missing_metadata:
            logger.info(f"Metadata Missing for Item : {item.title}"
                        f" ({item.year})")
            missing_metadata_items.append(item)

    total_missing_metadata_items = len(missing_metadata_items)
    logger.info(
        f"Section : {section} | Total Items : {total_items} | "
        f"Items with Missing Metadata : {total_missing_metadata_items}"
    )

    _refresh_items(section, missing_metadata_items,
                   total_missing_metadata_items)

    time.sleep(900)


def _refresh_missing_misc_section(section):

    skip_section = SKIP_SECTIONS.get(section, False)
    if skip_section:
        return

    plex = plexapi.server.PlexServer(PLEX_URL, PLEX_TOKEN, timeout=300)
    plex_section = plex.library.section(section)
    total_items = plex_section.totalSize

    missing_thumb_items = []

    for item in _batch_get(plex_section, BATCH_SIZE):

        try:

            if not item.thumb:
                logger.info(f"Metadata Missing for Item : {item.title}")
                missing_thumb_items.append(item)

        except plexapi.exceptions.BadRequest:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
            missing_thumb_items.append(item)
        except plexapi.exceptions.NotFound:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except plexapi.exceptions.PlexApiException:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")
        except Exception:
            logger.exception(f"Fetching Item : {item.title} ({item.year})")

        finally:
            time.sleep(PLEX_REQUESTS_SLEEP)

    total_missing_thumb_items = len(missing_thumb_items)
    logger.info(f"Section : {section} | Total Items : {total_items} | "
                f"Items with Missing Thumbs : {total_missing_thumb_items}")

    _refresh_items(section, missing_thumb_items, total_missing_thumb_items,
                   analyze=False)

    time.sleep(900)


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
        _refresh_missing_movie_section(section)


def _refresh_tv_sections_1():
    for section in TV_SECTIONS_1:
        _refresh_missing_tv_section(section)


def _refresh_tv_sections_2():
    for section in TV_SECTIONS_2:
        _refresh_missing_tv_section(section)


def _refresh_misc_sections():
    for section in MISC_SECTIONS:
        _refresh_missing_misc_section(section)
#
#
# def _metadata_refresher():
#     while True:
#         item = refresh_queue.get()
#         if item is None:
#             break
#         time.sleep(1)


def main():
    _setup_logger()

    producer_process_list = [
        multiprocessing.Process(target=_refresh_tv_sections_1, args=()),
        multiprocessing.Process(target=_refresh_tv_sections_2, args=()),
        multiprocessing.Process(target=_refresh_misc_sections, args=()),
        multiprocessing.Process(target=_refresh_movie_sections, args=()),
    ]
    #
    # consumer_process_list = [
    #     multiprocessing.Process(target=_metadata_refresher, args=()),
    # ]

    for idx, process in enumerate(producer_process_list):
        print("Started Worker ::: {0}".format(idx + 1))
        process.start()
    #
    # for idx, process in enumerate(consumer_process_list):
    #     print("Started Refresh Item Consumer ::: {0}".format(idx + 1))
    #     process.start()

    for process in producer_process_list:
        process.join()

    # refresh_queue.put(None)
    #
    # for process in consumer_process_list:
    #     process.join()


if __name__ == "__main__":
    main()
