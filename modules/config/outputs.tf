output "s3_bucket_arn" {
  description = "The arn of the S3 bucket used by AWS Config"
  value       = aws_s3_bucket.this.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role utilized by AWS Config"
  value       = aws_iam_role.this.arn
}

output "config_rules_names" {
  description = "The names of the AWS Config rules created"
  value       = [for rule in aws_config_config_rule.this : rule.name]
}