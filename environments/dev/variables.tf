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

variable "engine_version" {
  type        = string
  description = "The database engine version to use for the Aurora cluster (e.g., 3.05.2)."
}

variable "database_name" {
  type        = string
  description = "The name for the initial database to be created when the cluster is provisioned."
}

variable "master_username" {
  type        = string
  description = "The login username for the master administrative user of the cluster."
}

variable "instance_class" {
  type        = string
  description = " Instance class to use. For details on CPU and memory,"
}

variable "instance_count" {
  type        = number
  description = "instance number in the cluster"
}

variable "certificate_arn" {
  description = "The ARN of the ACM SSL/TLS certificate used to secure the Load Balancer HTTPS listener."
  type        = string
}

variable "access_logs_s3" {
  type        = string
  description = "Access logs for buckets s3"
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