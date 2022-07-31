output "user_pool_id" {
  value = aws_cognito_user_pool.twitter_user_pool.id
}

output "identity_pool_id" {
  value = aws_cognito_identity_pool.twitter_id_pool.id
}

output "auth_role" {
  value = aws_iam_role.cognito_auth.arn
}

output "unauth_role" {
  value = aws_iam_role.cognito_unauth.arn
}