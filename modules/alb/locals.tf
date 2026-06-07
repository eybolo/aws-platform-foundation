locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }
  name_prefix = "${local.common_tags.Project}-${var.environment}"

  lb_name             = "${local.name_prefix}-lb"
  lb_target_group     = "${local.name_prefix}-lb-tg"
  security_group_name = "${local.name_prefix}-lb-sg"
  access_logs_name    = "${local.name_prefix}-lb-logs"
}