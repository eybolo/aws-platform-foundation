resource "aws_cloudwatch_event_rule" "guardduty_rule" {
  name        = local.guardduty_rule
  description = "EventBridge rule to capture GuardDuty findings that meet or exceed the minimum severity threshold."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.minimum_severity] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_target" {
  target_id = "guardduty-to-sns"
  rule      = aws_cloudwatch_event_rule.guardduty_rule.name
  arn       = var.sns_topic_arn
}

resource "aws_cloudwatch_event_rule" "securityhub_rule" {
  name        = local.securityhub_rule
  description = "EventBridge rule to capture Security Hub imported findings that meet or exceed the normalized minimum severity threshold."

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      severity = [{ numeric = [">=", var.minimum_severity] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "securityhub_target" {
  target_id = "securityhub-to-sns"
  rule      = aws_cloudwatch_event_rule.securityhub_rule.name
  arn       = var.sns_topic_arn
}

