# twitter-streaming
Streams tweets from Twitter API with direct PUT into Kinesis Firehose to AWS Opensearch

### Code structure

[`iac`](iac) folder contains terraform code with modules for the AWS infrastructure

[`src`](src) folder is the main Python twitter app. It listens to Twitter stream and pushes messages further down the line

[`tests`](tests) folder contains tests for processing tweets. It doesn't cover all the details, only for "business" functionality

[`pyproject.toml`](pyproject.toml) - dependencies :-P


### How to build and run docker

```
docker build . -t twitter:0.0.1
docker run --env-file=.env twitter:0.0.1
```

where `.env` contains 3 rows with AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and AWS_DEFAULT_REGION.

### Upcoming

Architecture diagram (visual presentation)
