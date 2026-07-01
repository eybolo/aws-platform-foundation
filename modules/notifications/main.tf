resource "aws_sns_topic" "this" {
  name = local.sns_topic
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "this" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email_sns
}
