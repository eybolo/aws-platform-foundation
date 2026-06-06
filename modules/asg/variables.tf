variable "vpc_id" {
  description = "The target VPC ID where the Aurora DB cluster and its security group will be provisioned."
  type        = string
}

variable "subnet_private" {
  description = "List of private subnets in the VPC"
  type        = list(string)
}

variable "arn_target_group" {
  description = "ASG needs ARN the target group for ALB"
  type        = string
}

variable "security_group_id_alb" {
  description = "ASG needs id security group for ALB"
  type        = list(string)
}

variable "security_group_id_aurora" {
  description = "ASG needs id security group for AURORA"
  type        = list(string)
}

variable "instance_type" {
  description = "Type instance ec2"
  type        = string
}

variable "asg_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group."
  type        = number
}

variable "asg_min_size" {
  description = "The minimum size of the Auto Scaling Group."
  type        = number
}

variable "asg_max_size" {
  description = "The maximum size of the Auto Scaling Group."
  type        = number
}

variable "instance_volume_size" {
  description = "Volume size disk for instance ec2"
  type        = number
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}
