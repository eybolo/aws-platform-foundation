variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment value must be one of: dev, staging, or prod."
  }
}

variable "finding_publishing_frequency" {
  description = "The frequency with which AWS GuardDuty publishes findings. Valid values are: FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  type        = string

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "The finding_publishing_frequency value must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}

variable "s3_data_events" {
  description = "Controls whether GuardDuty monitors S3 data events as a data source to detect potential threats within your S3 buckets."
  type        = bool
}

variable "ebs_malware_protection" {
  description = "Controls whether GuardDuty Malware Protection is enabled to automatically scan EBS volumes for potential malware when suspicious behavior is detected."
  type        = bool
}