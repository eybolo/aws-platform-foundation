locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }

  name_prefix = "${local.common_tags.Project}-${var.environment}"

  rds_cluster_name           = "${local.name_prefix}-aurora-cluster"
  db_subnet_group_name       = "${local.name_prefix}-db-subnet-group"
  security_group_name        = "${local.name_prefix}-aurora-sg"
  secretsmanager_secret_name = "${local.name_prefix}-aurora-db-credentials"
}