variable "multi_region" {
  description = "Indicates whether the KMS key is a multi-Region primary key that can be replicated to other AWS Regions."
  type        = bool
  default     = false
}

variable "service_principals" {
  description = "Map of AWS Service Principals configurations authorized to use the key. Includes source ARNs to prevent confused deputy attacks."
  type = map(object({
    actions = list(string)
  }))
}

variable "service_name" {
  description = "The specific AWS service or component name that will utilize this key (e.g., 'rds', 's3', 'cloudwatch')."
  type        = string
}

variable "enable_key_rotation" {
  description = "Specifies whether AWS KMS automatically rotates the key material every year."
  type        = bool
  default     = true
}

variable "environment" {
  description = "The deployment environment target name (e.g., 'dev', 'staging', 'prod') used for resource isolation and naming conventions."
  type        = string
}