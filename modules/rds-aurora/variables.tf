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

variable "subnets_ids_data" {
  type        = list(string)
  description = "IDS subnet data for using rds aurora"
}

variable "subnets_cidrs_private" {
  type        = list(string)
  description = "CIDRs subnet private for using rds aurora"
}

variable "vpc_id" {
  type        = string
  description = "The target VPC ID where the Aurora DB cluster and its security group will be provisioned."
}

variable "key_arn" {
  type        = string
  description = "The KMS key ARN used to encrypt the Aurora cluster storage."
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)"
}

variable "instance_class" {
  type        = string
  description = " Instance class to use. For details on CPU and memory,"
}

variable "instance_count" {
  type        = number
  description = "instance number in the cluster"
}
