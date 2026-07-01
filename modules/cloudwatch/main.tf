resource "aws_cloudwatch_metric_alarm" "asg_cpu" {
  alarm_name          = local.asg_cpu
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.asg_cpu
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = local.alb_5xx
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 120
  statistic           = "Sum"
  threshold           = var.lb_5XX
  dimensions = {
    LoadBalancer = var.lb_arn_suffix
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = local.rds_connections
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = var.rds_connections
  dimensions = {
    DBClusterIdentifier = var.rds_cluster_identifier
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = local.rds_storage
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 120
  statistic           = "Average"
  threshold           = var.rds_storage_free * 1024 * 1024 * 1024
  dimensions = {
    DBClusterIdentifier = var.rds_cluster_identifier
  }
  alarm_actions = [var.sns_topic_arn]
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = local.dashboard
  dashboard_body = jsonencode({
  })
}