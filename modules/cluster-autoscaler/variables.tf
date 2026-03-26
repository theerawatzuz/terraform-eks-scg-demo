variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Cluster Autoscaler"
  type        = string
  default     = "kube-system"
}

variable "chart_version" {
  description = "Version of the Cluster Autoscaler Helm chart"
  type        = string
  default     = "9.37.0"
}

variable "tags" {
  description = "Tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
