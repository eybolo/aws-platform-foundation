variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment value must be one of: dev, staging, or prod."
  }
}

variable "email_sns" {
  description = "Email using to notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.email_sns))
    error_message = "The provided email address is not valid. Please enter a valid email format (e.g., user@example.com)."
  }
}