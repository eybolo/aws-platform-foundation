locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }
  name_prefix       = "${local.common_tags.Project}-${var.environment}"
  name_prefix_short = "aws-plt-fnd-${var.environment}"

  lb_name             = "${local.name_prefix}-lb"
  lb_target_group     = "${local.name_prefix_short}-lb-tg"
  security_group_name = "${local.name_prefix}-lb-sg"
}
