variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment value must be one of: dev, staging, or prod."
  }
}

variable "config_rules" {
  description = "A list of AWS Config rules configuration objects, each containing a rule name and its specific parameter key-value pairs"
  type = list(object({
    name       = string
    parameters = map(string)
  }))
}

variable "log_retention_days" {
  description = "Specify number day for retention log in environment (dev, staging, prod), using 0 for never delete"
  type        = number

  validation {
    condition     = var.log_retention_days >= 0
    error_message = "The log retention days must be a positive number or 0 (for infinite retention)."
  }
}

variable "delivery_frequency" {
  description = "The frequency with which AWS Config recurringly delivers configuration snapshots"
  type        = string

  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.delivery_frequency)
    error_message = "The delivery_frequency value must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }
}