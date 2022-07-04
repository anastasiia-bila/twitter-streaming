import json

from datetime import datetime
from send_to_firehose import send_to_firehose
from twython import TwythonStreamer

def process_tweet(tweet):
    """Extract message from tweet."""
    # print('Tweet', tweet)
    
    tweet_data = {}

    date_time_str = tweet['created_at']
    date_time_obj = datetime.strptime(date_time_str, '%a %b %d %H:%M:%S %z %Y')
    formatted_datetime = date_time_obj.isoformat()

    user_created_at_str = tweet['user']['created_at']
    user_created_at_obj = datetime.strptime(user_created_at_str, '%a %b %d %H:%M:%S %z %Y')
    formatted_user_created_at = user_created_at_obj.isoformat()


    if 'retweeted_status' in tweet:
        if 'extended_tweet' in tweet['retweeted_status']:
            tweet_data['text'] = tweet['retweeted_status']['extended_tweet']['full_text']
            tweet_data['created_at'] = formatted_datetime
            tweet_data['username'] = tweet['user']['screen_name']
            tweet_data['location'] = tweet['user'].get('location')
            tweet_data['user_created_at'] = formatted_user_created_at
        else:
            tweet_data['text'] = tweet['retweeted_status']['text']
            tweet_data['created_at'] = formatted_datetime
            tweet_data['username'] = tweet['user']['screen_name']
            tweet_data['location'] = tweet['user'].get('location')
            tweet_data['user_created_at'] = formatted_user_created_at
    elif 'extended_tweet' in tweet:
        tweet_data['text'] = tweet['extended_tweet']['full_text']
        tweet_data['created_at'] = formatted_datetime
        tweet_data['username'] = tweet['user']['screen_name']
        tweet_data['location'] = tweet['user'].get('location')
        tweet_data['user_created_at'] = formatted_user_created_at
    else:
        tweet_data['text'] = tweet['text']
        tweet_data['created_at'] = formatted_datetime
        tweet_data['username'] = tweet['user']['screen_name']
        tweet_data['location'] = tweet['user'].get('location')
        tweet_data['user_created_at'] = formatted_user_created_at

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