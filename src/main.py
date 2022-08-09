import os
import sys

sys.path.insert(0, os.path.abspath('src'))

from loguru import logger

from es import delete_index
from fetch_tweets import listen_tweets
from utils.utils import ES_ENDPOINT, ES_INDEX, twitter_credentials

if __name__ == '__main__':
    logger.info("Starting to listen tweets")
    listen_tweets(twitter_credentials)

    # delete_index(ES_ENDPOINT, ES_INDEX)
