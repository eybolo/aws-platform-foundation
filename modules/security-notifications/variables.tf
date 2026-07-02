variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment value must be one of: dev, staging, or prod."
  }
}

variable "sns_topic_arn" {
  description = "the arn of the sns topic used for sending infrastructure notifications and alerts."
  type        = string
}

variable "minimum_severity" {
  description = "The minimum severity level (1 to 10) for GuardDuty findings to be processed or alerted upon."
  type        = number

  validation {
    condition     = var.minimum_severity >= 1 && var.minimum_severity <= 10
    error_message = "The value must be a number between 1 and 10 (inclusive)."
  }
}