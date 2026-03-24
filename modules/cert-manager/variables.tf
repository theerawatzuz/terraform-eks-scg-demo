variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "domain_name" {
  description = "Domain name for certificate management (managed by Cloudflare)"
  type        = string
  default     = "thebrainsurf.site"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS-01 challenge"
  type        = string
  sensitive   = true
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}

variable "chart_version" {
  description = "Version of the cert-manager Helm chart"
  type        = string
  default     = "v1.13.3"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
