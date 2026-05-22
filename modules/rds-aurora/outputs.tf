output "endpoint" {
  description = "ASG needs endpoint connect aurora"
  value       = aws_rds_cluster.this.endpoint
}

output "security_group_id" {
  description = "ASG needs ID security group aurora"
  value       = aws_security_group.this.id
}

output "secretsmanager_secret_arn" {
  description = "ASG needs the secret ARN name for ec2 instances"
  value       = aws_secretsmanager_secret.this.arn
}
