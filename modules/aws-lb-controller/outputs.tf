output "iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "iam_role_name" {
  description = "Name of the IAM role for AWS Load Balancer Controller"
  value       = aws_iam_role.aws_load_balancer_controller.name
}

output "service_account_name" {
  description = "Name of the Kubernetes service account for AWS Load Balancer Controller"
  value       = "aws-load-balancer-controller"
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account for AWS Load Balancer Controller"
  value       = "kube-system"
}

output "helm_release_name" {
  description = "Name of the Helm release for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}

output "helm_release_namespace" {
  description = "Namespace of the Helm release for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.namespace
}

output "helm_release_status" {
  description = "Status of the Helm release for AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.status
}
