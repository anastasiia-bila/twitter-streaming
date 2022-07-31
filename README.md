# twitter-streaming
Streams tweets from Twitter API with direct PUT into Kinesis Firehose to AWS Opensearch

```
docker build . -t tweeter:0.0.1
docker run --env-file=.env tweeter:0.0.1
```

where .env contains 3 rows with AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION.
