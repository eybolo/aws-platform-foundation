locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }
  name_prefix = "${local.common_tags.Project}-${var.environment}"

  sns_topic = "${local.name_prefix}-sns-topic"
}

