variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment value must be one of: dev, staging, or prod."
  }
}

variable "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group."
  type        = string
}

variable "asg_cpu" {
  description = "The CPU utilization threshold percentage (e.g., 80) to trigger the Auto Scaling Group alarm."
  type        = number
}

variable "lb_arn_suffix" {
  description = "The ARN suffix of the Load Balancer, primarily used for routing CloudWatch metrics and alarms."
  type        = string
}

variable "lb_target_group_arn_suffix" {
  description = "The ARN suffix of the Target Group, primarily used for routing CloudWatch metrics and alarms."
  type        = string
}

variable "lb_5XX" {
  description = "The maximum number of 5XX error responses allowed from the Load Balancer before triggering the alarm."
  type        = number
}

variable "rds_cluster_identifier" {
  description = "The cluster identifier of the RDS cluster."
  type        = string
}

variable "rds_connections" {
  description = "The maximum number of simultaneous database connections allowed to the RDS cluster before triggering the alarm."
  type        = number
}

variable "rds_storage_free" {
  description = "The minimum amount of free storage space available on the RDS cluster (gigabytes) to trigger the low storage alarm."
  type        = number
}

variable "sns_topic_arn" {
  description = "the arn of the sns topic used for sending infrastructure notifications and alerts."
  type        = string
}