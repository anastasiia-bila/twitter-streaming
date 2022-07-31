output "es_arn" {
  description = "OpenSearch ARN"
  value       = aws_elasticsearch_domain.es.arn
}