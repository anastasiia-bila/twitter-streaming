import json
import os
import sys

import boto3

sys.path.insert(0, os.path.abspath('src'))

from utils.utils import AWS_REGION

# STREAM_NAME = "PUT_Opensearch"
STREAM_NAME = "PUT-with-location"

aws_kinesis_client = None

def kinesis_client():
    global aws_kinesis_client
    if aws_kinesis_client is None:
        aws_kinesis_client = boto3.client('firehose', AWS_REGION)
    return aws_kinesis_client

def send_to_firehose(tweet_data):
    print(tweet_data)
    kinesis_client().put_record(
        DeliveryStreamName=STREAM_NAME,
        Record={
            'Data': json.dumps(tweet_data)
        })