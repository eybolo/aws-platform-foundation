output "key_arn" {
  description = "The Amazon Resource Name (ARN) of the KMS key. Used to associate it with resources such as RDS, S3, etc."
  value       = aws_kms_key.this.arn
}

output "key_id" {
  description = "The unique identifier (ID) of the KMS key."
  value       = aws_kms_key.this.key_id
}