data "aws_partition" "current" {}

# IAM policy for External Secrets Operator
data "aws_iam_policy_document" "external_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:secretsmanager:*:*:secret:eks/*"
    ]
  }
}

# IAM role for External Secrets Operator (IRSA)
resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:external-secrets-system:external-secrets"
        }
      }
    }]
  })

  tags = var.tags
}

# IAM policy
resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets"
  description = "IAM policy for External Secrets Operator"
  policy      = data.aws_iam_policy_document.external_secrets.json

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "external_secrets" {
  policy_arn = aws_iam_policy.external_secrets.arn
  role       = aws_iam_role.external_secrets.name
}
