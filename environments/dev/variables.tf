variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnet_public" {
  description = "List of public subnets in the VPC"
  type        = list(string)
}

variable "subnet_private" {
  description = "List of private subnets in the VPC"
  type        = list(string)
}

variable "subnet_data" {
  description = "List of data subnets in the VPC"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones for the VPC"
  type        = list(string)
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}
