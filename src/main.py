from fetch_tweets import listen_tweets
from es import delete_index
from loguru import logger
from utils.utils import twitter_credentials, ES_ENDPOINT


if __name__ == '__main__':
    logger.info("Starting to listen tweets")
    listen_tweets(twitter_credentials)

    # delete_index(ES_ENDPOINT, ES_ENDPOINT)
