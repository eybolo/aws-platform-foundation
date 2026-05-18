data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]
  tags = local.common_tags
}

resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:eybolo/aws-platform-foundation:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "github-actions-policy"
  description = "Policy for GitHub Actions to access AWS resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:CreateRole",
          "iam:GetRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:TagRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-role"
      }
    ]
  })

  tags = local.common_tags
}
resource "aws_iam_role_policy_attachment" "github_actions_role_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}