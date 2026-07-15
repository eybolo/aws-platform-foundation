variable "vpc_id" {
  type        = string
  description = "The target VPC ID where the ALB cluster and its security group will be provisioned."
}

variable "subnets_cidrs_private" {
  type        = list(string)
  description = "CIDRs subnet private for using ALB"
}

variable "subnets_ids_public" {
  type        = list(string)
  description = "IDS subnet public for using ALB"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)"
}
