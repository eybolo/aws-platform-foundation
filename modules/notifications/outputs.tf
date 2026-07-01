output "sns_topic_arn" {
  description = "the arn of the sns topic used for sending infrastructure notifications and alerts."
  value       = aws_sns_topic.this.arn
}
