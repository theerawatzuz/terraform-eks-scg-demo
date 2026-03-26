output "iam_role_arn" {
  description = "ARN of the IAM role for ArgoCD Image Updater"
  value       = aws_iam_role.argocd_image_updater.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for ArgoCD Image Updater"
  value       = aws_iam_role.argocd_image_updater.name
}
