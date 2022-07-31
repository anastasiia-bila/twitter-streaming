import os
import sys

import boto3
from elasticsearch import Elasticsearch, RequestsHttpConnection
from loguru import logger
from requests_aws4auth import AWS4Auth

sys.path.insert(0, os.path.abspath('src'))

from utils.utils import AWS_REGION


def establish_connection_to_elasticsearch(host, timeout=60):
    """ Connec to ES by host."""
    service = "es"
    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(
        credentials.access_key,
        credentials.secret_key,
        AWS_REGION,
        service,
        session_token=credentials.token,
    )

    es = Elasticsearch(
        hosts=host,
        http_auth=awsauth,
        use_ssl=True,
        verify_certs=True,
        connection_class=RequestsHttpConnection,
        timeout=timeout,
    )
    return es

def delete_index(host, index):
    """Deletes an index. Use this carefully, as once the index is deleted there is no way to recover it.

    Args:
        host (String): url to connect to the elasticsearch db
        index (String): the name of the index to remove

    Returns:
        Bool: To confirm that the deletion occured
    """
    es = establish_connection_to_elasticsearch(host)
    es.indices.delete(index=index, ignore=[400, 404])
    logger.info(f"Deleted index {index}")
    return True
