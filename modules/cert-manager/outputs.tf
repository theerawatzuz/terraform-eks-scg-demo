output "namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "release_name" {
  description = "Helm release name for cert-manager"
  value       = helm_release.cert_manager.name
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.cert_manager.status
}

output "clusterissuer_created" {
  description = "Whether ClusterIssuer was created (requires Cloudflare API token)"
  value       = var.cloudflare_api_token != "" ? true : false
}

output "setup_instructions" {
  description = "Instructions for completing cert-manager setup"
  value       = var.cloudflare_api_token == "" ? "cert-manager is installed but ClusterIssuer is not created yet. Create Cloudflare API token secret and apply ClusterIssuer from kubernetes/apps/cert-manager/clusterissuer.yaml" : "ClusterIssuer 'letsencrypt-prod' is configured and ready to use"
}
