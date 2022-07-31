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


# ########################################################
# ELASTICSEARCH SETUP
# #########################################################

resource "aws_elasticsearch_domain" "es" {
  domain_name           = "${var.app_name}-${var.stage}-june"
  elasticsearch_version = "OpenSearch_1.2"

  cluster_config {
    instance_type = var.instance_type
  }
  encrypt_at_rest {
    enabled = true
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  cognito_options {
    enabled          = true
    user_pool_id     = aws_cognito_user_pool.twitter_user_pool.id
    identity_pool_id = aws_cognito_identity_pool.twitter_id_pool.id
    role_arn         = aws_iam_role.aws_cognito_role.arn 
  }
  
}

resource "aws_iam_role" "aws_cognito_role" {
  name = "${var.app_name}CognitoAccessForAmazonES"
  assume_role_policy = data.aws_iam_policy_document.cognito_trust.json
}


resource "aws_iam_role_policy_attachment" "cognito_trust" {
  role       = aws_iam_role.aws_cognito_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonESCognitoAccess"
}


data "aws_iam_policy_document" "cognito_trust" {

  statement {
    actions = ["sts:AssumeRole"]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_elasticsearch_domain_policy" "elasticsearch" {
  domain_name = aws_elasticsearch_domain.es.domain_name
  access_policies = <<POLICIES
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/twitter-user"
          ]
      },
      "Action": [
        "es:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${aws_iam_role.cognito_auth.arn}"
          ]
      },
      "Action": [
        "es:*"
      ],
      "Resource": [
        "${aws_elasticsearch_domain.es.arn}",
        "${aws_elasticsearch_domain.es.arn}/*"
      ]
    }
  ]
}
POLICIES
}


#####################################################
# COGNITO USER POOL
#####################################################

resource "aws_cognito_user_pool" "twitter_user_pool" {
  name = var.app_name

  # auto_verified_attributes = ["email"]
  admin_create_user_config  {
    allow_admin_create_user_only = true
  }

  password_policy {
    minimum_length = 6
    require_numbers = true
    require_uppercase = true
    require_symbols = true
  }
}

resource "aws_cognito_user_pool_domain" "twitter_domain_user_pool" {
  domain = "${var.app_name}-domain"
  user_pool_id = aws_cognito_user_pool.twitter_user_pool.id
}


#####################################################
# COGNITO IDENTITY POOL
#####################################################

resource "aws_cognito_identity_pool" "twitter_id_pool" {
  identity_pool_name               = replace(var.app_name, "-", " ")
  allow_unauthenticated_identities = false

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "id_pool_roles" {
  identity_pool_id = aws_cognito_identity_pool.twitter_id_pool.id

  roles = {
    "authenticated" = aws_iam_role.cognito_auth.arn
    "unauthenticated" = aws_iam_role.cognito_unauth.arn
  }
}

##################################################################
# AUTH CONGNITO ROLE
##################################################################

data "aws_iam_policy_document" "cognito_auth_assume" {

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values = [aws_cognito_identity_pool.twitter_id_pool.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values = ["authenticated"]
    }
    }
}

data "aws_iam_policy_document" "cognito_auth" {

  statement {
    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*",
      "cognito-identity:*"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "cognito_auth" {
  name = "${var.app_name}_cognito_auth_role"
  assume_role_policy = data.aws_iam_policy_document.cognito_auth_assume.json
}

resource "aws_iam_policy" "cognito_auth" {
  name   = "cognito_kibana_auth_${var.app_name}"
  policy = data.aws_iam_policy_document.cognito_auth.json
}

resource "aws_iam_role_policy_attachment" "cognito_auth" {
  role       = aws_iam_role.cognito_auth.name
  policy_arn = aws_iam_policy.cognito_auth.arn
}


##################################################################
# UNAUTH CONGNITO ROLE
##################################################################

data "aws_iam_policy_document" "cognito_unauth_assume" {

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"

    principals {
      type = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values = [aws_cognito_identity_pool.twitter_id_pool.id]
    }
    condition {
        test     = "ForAnyValue:StringLike"
        variable = "cognito-identity.amazonaws.com:amr"
      values = ["unauthenticated"]
  }
}
}

data "aws_iam_policy_document" "cognito_unauth" {

  statement {
    actions = [
      "mobileanalytics:PutEvents",
      "cognito-sync:*",
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cognito_unauth" {
  role       = aws_iam_role.cognito_unauth.name
  policy_arn = aws_iam_policy.cognito_unauth.arn
}


resource "aws_iam_policy" "cognito_unauth" {
  name   = "cognito_kibana_unauth_${var.app_name}"
  policy = data.aws_iam_policy_document.cognito_auth.json
}

resource "aws_iam_role" "cognito_unauth" {
  name = "${var.app_name}_cognito_unauth_role"
  assume_role_policy = data.aws_iam_policy_document.cognito_unauth_assume.json
}


# Kinesis Firehose
module "firehose" {
  source                       = "./modules/firehose"
  stream_name                  = var.stream_name
  es_arn                       = aws_elasticsearch_domain.es.arn
  es_index_name                = var.es_index_name
  s3_backup_mode               = var.s3_backup_mode
  s3_backup_arn                = aws_s3_bucket.data_bucket.arn

  depends_on = [
    aws_elasticsearch_domain.es,
    aws_s3_bucket.data_bucket
  ]
}