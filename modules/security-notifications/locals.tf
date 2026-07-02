locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }
  name_prefix = "${local.common_tags.Project}-${var.environment}"

  guardduty_rule   = "${local.name_prefix}-guardduty-rule"
  securityhub_rule = "${local.name_prefix}-securityhub-rule"
}


