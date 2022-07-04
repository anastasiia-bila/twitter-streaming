variable "profile" {
  type        = string
  description = "AWS profile to use for deployment"
  default     = "default"
}

variable "region" {
  type        = string
  description = "Region to deploy the resources"
  default     = "eu-west-2"
}

variable "stage" {
  type        = string
  default     = "default"
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "force_destroy" {
  type        = bool
  default     = true
  description = "Force destroy the CI/CD S3 bucket even if it's not empty"
}

variable "app_name" {
  type        = string
  description = "The name of your application"
  default     = "coop-tweets"
}

variable "instance_type" {
  type        = string
  description = "Type of instance"
  default     = "t3.small.elasticsearch"
}


# Firehose

variable "stream_name" {
  type        = string
  description = "Kinesis Firehose Stream Name"
  default     = "PUT_Opensearch_2"
}

variable "es_buffering_interval" {
  type        = string
  description = "Elasticsearch buffering interval. The higher interval allows more time to collect data and the size of data may be bigger."
  default     = 60
}

variable "es_buffering_size" {
  type        = string
  description = "Elasticsearch buffering size. The lower buffer size will be faster in delivery with higher cost and less latency."
  default     = 1
}

variable "es_arn" {
  type        = string
  description = "Elasticsearch ARN"
}

variable "es_index_name" {
  type        = string
  description = "Elasticsearch index name"
  default     = "tweets2"
}

variable "s3_backup_mode" {
  type        = string
  description = "S3 backup mode"
  default     = "FailedDocumentsOnly"
}

variable "s3_backup_arn" {
  type        = string
  description = "S3 for backup"
}