import os
import sys

sys.path.insert(0, os.path.abspath('src'))

from datetime import datetime

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
            tweet_data[LOCATION] = tweet[USER].get(LOCATION)
            tweet_data[USER_CREATED_AT] = formatted_user_created_at
        else:
            tweet_data[TEXT] = tweet[RETWEETED_STATUS][TEXT]
            tweet_data[CREATED_AT] = formatted_datetime
            tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
            tweet_data[LOCATION] = tweet[USER].get(LOCATION)
            tweet_data[USER_CREATED_AT] = formatted_user_created_at
    elif EXTENDED_TWEET in tweet:
        tweet_data[TEXT] = tweet[EXTENDED_TWEET][FULL_TEXT]
        tweet_data[CREATED_AT] = formatted_datetime
        tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
        tweet_data[LOCATION] = tweet[USER].get(LOCATION)
        tweet_data[USER_CREATED_AT] = formatted_user_created_at
    else:
        tweet_data[TEXT] = tweet[TEXT]
        tweet_data[CREATED_AT] = formatted_datetime
        tweet_data[USERNAME] = tweet[USER][SCREEN_NAME]
        tweet_data[LOCATION] = tweet[USER].get(LOCATION)
        tweet_data[USER_CREATED_AT] = formatted_user_created_at

    return tweet_data

class MyStreamer(TwythonStreamer):
    def on_success(self, data):
        processed_tweet_data = process_tweet(data)
        send_to_firehose(processed_tweet_data)

    def on_error(self, status_code, data):
        print('ON ERROR: {}'.format(status_code))
        self.disconnect()

def listen_tweets(credentials):
    # Instantiate from our streaming class
    stream = MyStreamer(credentials['CONSUMER_KEY'], credentials['CONSUMER_SECRET'],
                        credentials['ACCESS_TOKEN'], credentials['ACCESS_SECRET'])
    # Start the stream
    stream.statuses.filter(track='python', language='en', tweet_mode='extended')
