resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name        = var.stream_name
  destination = "elasticsearch"

  elasticsearch_configuration {
    buffering_interval = 60
    buffering_size     = 1
    domain_arn         = var.es_arn
    index_name         = var.es_index_name
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    s3_backup_mode     = var.s3_backup_mode
  }

  s3_configuration {
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    bucket_arn         = var.s3_backup_arn

  }

}

resource "aws_iam_role" "firehose_delivery_role" {
  name = "firehose-delivery-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "firehose_s3_delivery_policy" {
  name        = "firehose-delivery-policy"
  path        = "/"
  description = "Kinesis Firehose delivery policy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${var.s3_backup_arn}",
                "${var.s3_backup_arn}/*"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "firehose_s3" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose_s3_delivery_policy.arn
}

resource "aws_iam_policy" "firehose_es_delivery_policy" {
  name        = "firehose-es-delivery-policy"
  path        = "/"
  description = "Kinesis Firehose delivery policy"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "es:*"
            ],
            "Resource": [
                "${var.es_arn}",
                "${var.es_arn}/*"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "firehose_es" {
  role       = aws_iam_role.firehose_delivery_role.name
  policy_arn = aws_iam_policy.firehose_es_delivery_policy.arn
}