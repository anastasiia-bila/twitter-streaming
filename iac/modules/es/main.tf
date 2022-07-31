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
    user_pool_id     = var.user_pool_id
    identity_pool_id = var.identity_pool_id
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
          "${var.cognito_access}"
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