import boto3
import json

from utils.utils import AWS_REGION

# STREAM_NAME = "PUT-OpenSearch"
STREAM_NAME = "PUT_Opensearch_2"

# STREAM_NAME = "PUT-OPS-2OHNo"

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