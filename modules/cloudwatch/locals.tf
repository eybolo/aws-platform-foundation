locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }
  name_prefix = "${local.common_tags.Project}-${var.environment}"

  asg_cpu         = "${local.name_prefix}-asg-cpu-alarm"
  alb_5xx         = "${local.name_prefix}-alb-5xx-alarm"
  rds_connections = "${local.name_prefix}-rds-connections-alarm"
  rds_storage     = "${local.name_prefix}-rds-storage-alarm"
  dashboard       = "${local.name_prefix}-dashboard"
}


