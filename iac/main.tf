provider "aws" {
  region      = var.region
  profile     = var.profile
  max_retries = 2
}

##################################################################
# S3 STATE BUCKET
##################################################################

terraform {
  required_providers {
    aws = {
      #version = "~> 3.0"
    }
  }
  required_version = ">= 0.12"

  backend "s3" {
    # This was created manually first
    # Unable to use variables here because the initialization proccess happens before terraform loads the variables
    # and for the following issues:
    # https://github.com/hashicorp/terraform/pull/20428
    # https://github.com/hashicorp/terraform/issues/17288#issuecomment-462899292
    bucket = "coop-state-bucket-1"
    key    = "state"
    region = "eu-west-2"

  }
}


###########################################################
# BACKUP S3 BUCKET
###########################################################

resource "aws_s3_bucket" "data_bucket" {
  bucket        = "${var.stage}-backup-tweets-089"
  force_destroy = true
}

# Cognito
module "cognito" {
  source = "./modules/cognito"
}

# Elasticsearch
module "es" {
  source                       = "./modules/es"
  user_pool_id                 = module.cognito.user_pool_id
  identity_pool_id             = module.cognito.identity_pool_id
  cognito_depends              = [module.cognito.user_pool_id, module.cognito.identity_pool_id]
  cognito_access               = module.cognito.auth_role

  depends_on = [module.cognito]
}

# Kinesis Firehose
module "firehose" {
  source                       = "./modules/firehose"
  stream_name                  = var.stream_name
  es_arn                       = module.es.es_arn
  es_index_name                = var.es_index_name
  s3_backup_mode               = var.s3_backup_mode
  s3_backup_arn                = aws_s3_bucket.data_bucket.arn

  depends_on = [
    module.es,
    aws_s3_bucket.data_bucket,
  ]
}