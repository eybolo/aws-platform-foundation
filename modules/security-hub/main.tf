resource "aws_securityhub_account" "this" {
  enable_default_standards = false
  auto_enable_controls     = false
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each      = toset(var.standards_arn)
  standards_arn = each.value
  depends_on    = [aws_securityhub_account.this]
}
