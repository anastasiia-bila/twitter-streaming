import os
import sys
from unicodedata import name

import pycountry

sys.path.insert(0, os.path.abspath('src'))

import uuid
from datetime import datetime

from geopy.geocoders import Nominatim
from loguru import logger
from twython import TwythonStreamer

from firehose_connect import send_to_firehose

RETWEETED_STATUS = 'retweeted_status'
EXTENDED_TWEET = 'extended_tweet'
CREATED_AT = 'created_at'
USER = 'user'
USER_CREATED_AT = 'user_created_at'
LOCATION = 'location'
TEXT = 'text'
USERNAME = 'username'
FULL_TEXT = 'full_text'
SCREEN_NAME = 'screen_name'

def find_country_alpha2(tweet_location):
    try:
        geolocator = Nominatim(user_agent=f"twitterapp-{uuid.uuid1()}")
        location = geolocator.geocode(tweet_location, language="en")
        logger.info(location)
        if location and location.address:
            try:
                country = location.address.split(", ")[-1]
                iso_countries = pycountry.countries.search_fuzzy(country)
                if iso_countries:   
                    if len(iso_countries) >= 1:
                        iso_country = iso_countries[0]
                        logger.debug(f"Alpha 2 code is: {iso_country.alpha_2}")
                        return iso_country.alpha_2      
            except Exception as e:
                logger.error("Fuzzy search cannot lookup the country", e)
    except Exception as _:
        logger.error("Ouch!", _)

def process_tweet(tweet):
    """Extract message from tweet.""" 
    tweet_data = {}

    date_time_str = tweet[CREATED_AT]
    date_time_obj = datetime.strptime(date_time_str, '%a %b %d %H:%M:%S %z %Y')
    formatted_datetime = date_time_obj.isoformat()

    user_created_at_str = tweet[USER][CREATED_AT]
    user_created_at_obj = datetime.strptime(user_created_at_str, '%a %b %d %H:%M:%S %z %Y')
    formatted_user_created_at = user_created_at_obj.isoformat()

    if RETWEETED_STATUS in tweet:
        if EXTENDED_TWEET in tweet[RETWEETED_STATUS]:
            tweet_data[TEXT] = tweet[RETWEETED_STATUS][EXTENDED_TWEET][FULL_TEXT]
            tweet_data[CREATED_AT] = formatted_datetime
            tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
            tweet_data[LOCATION] = find_country_alpha2(tweet[USER].get(LOCATION))
            tweet_data[USER_CREATED_AT] = formatted_user_created_at
        else:
            tweet_data[TEXT] = tweet[RETWEETED_STATUS][TEXT]
            tweet_data[CREATED_AT] = formatted_datetime
            tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
            tweet_data[LOCATION] = find_country_alpha2(tweet[USER].get(LOCATION))
            tweet_data[USER_CREATED_AT] = formatted_user_created_at
    elif EXTENDED_TWEET in tweet:
        tweet_data[TEXT] = tweet[EXTENDED_TWEET][FULL_TEXT]
        tweet_data[CREATED_AT] = formatted_datetime
        tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
        tweet_data[LOCATION] = find_country_alpha2(tweet[USER].get(LOCATION))
        tweet_data[USER_CREATED_AT] = formatted_user_created_at
    else:
        tweet_data[TEXT] = tweet[TEXT]
        tweet_data[CREATED_AT] = formatted_datetime
        tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
        tweet_data[LOCATION] = find_country_alpha2(tweet[USER].get(LOCATION))
        tweet_data[USER_CREATED_AT] = formatted_user_created_at

    return tweet_data

class MyStreamer(TwythonStreamer):
    def on_success(self, data):
        processed_tweet_data = process_tweet(data)
        send_to_firehose(processed_tweet_data)

    def on_error(self, status_code, data):
        logger.error('ON ERROR: {}'.format(status_code))
        self.disconnect()

def listen_tweets(credentials):
    # Instantiate from our streaming class
    stream = MyStreamer(credentials['CONSUMER_KEY'], credentials['CONSUMER_SECRET'],
                        credentials['ACCESS_TOKEN'], credentials['ACCESS_SECRET'])
    # Start the stream
    stream.statuses.filter(track='python', language='en', tweet_mode='extended')
