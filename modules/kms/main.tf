data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_key" "this" {
  multi_region        = var.multi_region
  enable_key_rotation = var.enable_key_rotation
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      [for service, config in var.service_principals : {
        Sid       = "AllowUsageTo-${replace(service, ".", "")}"
        Effect    = "Allow"
        Principal = { Service = service }
        Action    = config.actions
        Resource  = "*"

        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:${var.service_name}:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }]
    ]
  })
  tags = local.common_tags
}