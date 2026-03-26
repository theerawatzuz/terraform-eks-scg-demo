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

variable "namespace" {
  description = "Kubernetes namespace for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "Version of cert-manager Helm chart"
  type        = string
  default     = "v1.16.2"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS-01 challenge (optional, can be set later)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "domain_name" {
  description = "Domain name for TLS certificates"
  type        = string
  default     = "thebrainsurf.site"
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
  default     = "admin@thebrainsurf.site"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
