output "namespace" {
  description = "Namespace where cert-manager is installed"
  value       = kubernetes_namespace_v1.cert_manager.metadata[0].name
}

output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.cert_manager.name
}

output "cluster_issuer_name" {
  description = "Name of the ClusterIssuer for Let's Encrypt"
  value       = kubernetes_manifest.letsencrypt_prod.manifest.metadata.name
}
