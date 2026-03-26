variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for EKS cluster"
  type        = string
}

variable "replica_count" {
  description = "Number of Nginx Ingress Controller replicas"
  type        = number
  default     = 2
}

variable "namespace" {
  description = "Kubernetes namespace for Nginx Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "chart_version" {
  description = "Version of ingress-nginx Helm chart"
  type        = string
  default     = "4.11.3"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
