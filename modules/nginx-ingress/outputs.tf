output "namespace" {
  description = "Namespace where Nginx Ingress Controller is deployed"
  value       = kubernetes_namespace.ingress_nginx.metadata[0].name
}

output "release_name" {
  description = "Helm release name for Nginx Ingress Controller"
  value       = helm_release.nginx_ingress.name
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.nginx_ingress.status
}

output "ingress_class_name" {
  description = "Name of the ingress class"
  value       = "nginx"
}
