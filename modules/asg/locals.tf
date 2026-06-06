locals {
  common_tags = {
    "Project"     = "aws-platform-foundation"
    "Environment" = var.environment
    "ManagedBy"   = "terraform"
    "Owner"       = "platform-team"
  }

  name_prefix = "${local.common_tags.Project}-${var.environment}"

  security_group_name      = "${local.name_prefix}-asg-sg"
  launch_template_name     = "${local.name_prefix}-asg-template"
  autoscaling_group_name   = "${local.name_prefix}-asg-group"
  iam_role_name            = "${local.name_prefix}-asg-iam-role"
  iam_instace_profile_name = "${local.name_prefix}-asg-iam-instance-profile"
}