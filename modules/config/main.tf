data "aws_caller_identity" "current" {}

resource "aws_iam_role" "this" {
  name        = local.role_name
  description = "Role assumed by AWS Config to monitor, record, and audit resource configurations."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "this" {
  name = local.role_policy_name
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Action = [
          "s3:GetBucketAcl"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.this.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_s3_bucket" "this" {
  bucket = local.config_bucket_name
  tags   = local.common_tags
}

resource "aws_config_configuration_recorder" "this" {
  name     = local.config_recorder
  role_arn = aws_iam_role.this.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  name           = local.config_delivery_channel
  s3_bucket_name = aws_s3_bucket.this.bucket
  depends_on     = [aws_config_configuration_recorder.this]
  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency
  }
}

resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_config_config_rule" "this" {
  for_each = { for rule in var.config_rules : rule.name => rule }

  name = "${local.config_rule}-${each.value.name}"

  source {
    owner             = "AWS"
    source_identifier = each.value.name
  }

  input_parameters = length(each.value.parameters) > 0 ? jsonencode(each.value.parameters) : null

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-old-logs"
    status = var.log_retention_days > 0 ? "Enabled" : "Disabled"

    filter {}

    dynamic "expiration" {
      for_each = var.log_retention_days > 0 ? [1] : []
      content {
        days = var.log_retention_days
      }
    }
  }
}