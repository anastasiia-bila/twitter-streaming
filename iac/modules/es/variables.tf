variable "app_name" {
  type        = string
  description = "The name of your application"
  default     = "coop-tweets"
}

variable "stage" {
  type        = string
  default     = "default"
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "instance_type" {
  type        = string
  description = "Type of instance"
  default     = "t3.small.elasticsearch"
}

variable "user_pool_id" {
  type        = string
  default     = ""
  description = "User Pool ID"
}

variable "identity_pool_id" {
  type        = string
  default     = ""
  description = "Identity Pool ID"
}

variable "cognito_depends" {
  type        = list(string)
  default     = []
  description = "Identity Pool ID"
}

variable "cognito_access" {
  type        = string
  default     = ""
  description = "AWS ARN that can access elasticserch"
}