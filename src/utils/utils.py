import boto3
from loguru import logger

AWS_REGION = "eu-west-2"


def fetch_parameter_from_ssm(name):
    """Read parameters from AWS Systems Manager Parameter Store

    Args:
        name (String): The name of the parameter

    Returns:
        String: The decrypted value of the parameter
    """
    ssm = boto3.client("ssm", region_name=AWS_REGION)
    parameter_details_dict = ssm.get_parameter(Name=name, WithDecryption=True)
    logger.debug(f"Read parameter {name} from Parameter Store")
    return parameter_details_dict["Parameter"]["Value"]

twitter_credentials = {
    "CONSUMER_KEY": fetch_parameter_from_ssm("CONSUMER_KEY"),
    "CONSUMER_SECRET": fetch_parameter_from_ssm("CONSUMER_SECRET"),
    "ACCESS_TOKEN": fetch_parameter_from_ssm("ACCESS_TOKEN"),
    "ACCESS_SECRET": fetch_parameter_from_ssm("ACCESS_SECRET")
}

ES_ENDPOINT = fetch_parameter_from_ssm("ES_ENDPOINT")
ES_INDEX = "tweets*"