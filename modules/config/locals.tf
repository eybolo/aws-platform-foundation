locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }
  name_prefix = "${local.common_tags.Project}-${var.environment}"

  config_bucket_name      = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-config-logs"
  role_name               = "${local.name_prefix}-role-config"
  role_policy_name        = "${local.name_prefix}-role-policy-config"
  config_recorder         = "${local.name_prefix}-config-recorder"
  config_delivery_channel = "${local.name_prefix}-config-delivery-channel"
  config_rule             = "${local.name_prefix}-config-rule"
}
