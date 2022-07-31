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