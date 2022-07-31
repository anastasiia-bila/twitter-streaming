import json
import os.path as path
import sys

from src import fetch_tweets

sys.path.insert(0, path.abspath('src'))

class TestTweets:

    TWEETS_BASE_PATH = path.join('tests', 'tweets')

    def __load_tweet(self, filename):
        with open(path.join(self.TWEETS_BASE_PATH, filename), 'r') as json_tweet:
            return json.load(json_tweet)

    def test_long_message(self):
        tweet = self.__load_tweet('original_long_tweet.json')
        assert fetch_tweets.process_tweet(tweet) == {
            'text': 'Cool step by step guide to Machine Learning 🤓 Thanks for Share '
                'Python Flux #python #programming #coding #webdevelopment '
                '#MachineLearning #BigData',
            'created_at': '2019-12-01T20:57:06+00:00',
            'location': 'Neuruppin',
            'user_created_at': '2019-03-27T12:43:23+00:00',
            'username': 'timbiernoth',
        }


    def test_short_message(self):
        tweet = self.__load_tweet('original_short_tweet.json')
        assert fetch_tweets.process_tweet(tweet) == {
            'text': 'Ros2 Crystal support required https://t.co/uiBJub74L3 #github #C++ '
             '#CMake #Python #Shell #Dockerfile',
            'created_at': '2019-12-01T20:57:05+00:00',
            'location': '127.0.0.1',
            'user_created_at': '2018-12-29T12:34:28+00:00',
            'username': 'first_issues',
        }

    def test_retweeted_long(self):
        tweet = self.__load_tweet('retweeted_original_long_tweet.json')
        assert fetch_tweets.process_tweet(tweet) == {
            'text': 'Unifying #MachineLearning and #QuantumChemistry with a Deep Neural '
                'Network. #BigData #Analytics #DataScience #AI #DeepLearning #IoT '
                '#IIoT #Python #RStats #Java #JavaScript #ReactJS #GoLang '
                '#CloudComputing #Serverless #DataScientist #Linux #QuantumComputing\n'
                'https://t.co/ys6qnPhg13 https://t.co/plDGBzB7xd',
            'created_at': '2019-12-01T20:58:12+00:00',
            'location': 'Los Angeles',
            'user_created_at': '2008-05-15T15:22:57+00:00',
            'username': 'zixiciv'
        }

    def test_retweeted_short(self):
        tweet = self.__load_tweet('retweeted_original_short_tweet.json')
        assert fetch_tweets.process_tweet(tweet) == {
            'text': 'How to retrieve object that a different object is linked to in '
            'template? Django https://t.co/gtEdGZDIhr #python',
            'created_at': '2019-12-01T20:58:10+00:00',
            'location': 'None',
            'user_created_at': '2017-08-24T10:49:03+00:00',
            'username': 'digitalsphere33'
        }
