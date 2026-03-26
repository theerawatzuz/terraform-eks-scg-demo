output "iam_role_arn" {
  description = "ARN of the IAM role for Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = "cluster-autoscaler"
}

output "namespace" {
  description = "Namespace where Cluster Autoscaler is deployed"
  value       = var.namespace
}
