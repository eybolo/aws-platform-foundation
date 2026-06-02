output "target_group_arn" {
  description = "ASG needs ARN target group can register instance ec2"
  value = aws_lb_target_group.this.arn
}

output "security_group_id" {
  description = "Security group needs ASG for configure rule ingress"
  value = aws_security_group.this.id
}