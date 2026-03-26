# Root Module Outputs
# This file exposes key infrastructure information for cluster access and configuration

# ============================================================================
# EKS Cluster Information
# ============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint URL for the EKS cluster API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster (used for IRSA)"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks.oidc_provider_arn
}

# ============================================================================
# VPC Network Information
# ============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.vpc.nat_gateway_ids
}

# ============================================================================
# Cluster Access Configuration
# ============================================================================

output "kubectl_config_command" {
  description = "Command to configure kubectl for cluster access"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ap-southeast-1 --profile default"
}

output "cluster_access_instructions" {
  description = "Instructions for accessing the EKS cluster"
  value       = <<-EOT
    To configure kubectl access to the cluster, run:
    
    aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ap-southeast-1 --profile default
    
    Then verify access with:
    
    kubectl get nodes
    kubectl get pods -A
  EOT
}

# ============================================================================
# Nginx Ingress Controller Information
# ============================================================================

output "nginx_ingress_namespace" {
  description = "Namespace where Nginx Ingress Controller is deployed"
  value       = module.nginx_ingress.namespace
}

output "nginx_ingress_class_name" {
  description = "Ingress class name for Nginx Ingress Controller"
  value       = module.nginx_ingress.ingress_class_name
}

output "nginx_alb_dns_instructions" {
  description = "Instructions to get ALB DNS name created by Nginx LoadBalancer service"
  value       = <<-EOT
    To get the ALB DNS name created by Nginx Ingress Controller:
    
    kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    Then create a CNAME record in Cloudflare:
    - Name: *.${var.domain_name} (or specific subdomain)
    - Target: <ALB DNS name from above>
    - Proxy status: Proxied or DNS only (both work as TLS terminates at Nginx)
  EOT
}

# ============================================================================
# cert-manager Information
# ============================================================================

output "cert_manager_namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = module.cert_manager.namespace
}

output "cert_manager_setup_instructions" {
  description = "Instructions for completing cert-manager setup"
  value       = module.cert_manager.setup_instructions
}

output "clusterissuer_ready" {
  description = "Whether ClusterIssuer is ready to use"
  value       = module.cert_manager.clusterissuer_created
}

# ============================================================================
# Domain and DNS Configuration
# ============================================================================

output "domain_name" {
  description = "Domain name configured for TLS certificates"
  value       = var.domain_name
}

output "tls_setup_instructions" {
  description = "Instructions for TLS certificate setup with cert-manager"
  value       = <<-EOT
    TLS Certificate Setup with cert-manager:

    1. Get the ALB DNS name:
       kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

    2. Create CNAME record in Cloudflare pointing *.${var.domain_name} to the ALB DNS name

    3. Apply ClusterIssuer for Let's Encrypt (see kubernetes/apps/cert-manager/clusterissuer.yaml)

    4. Create Ingress resources with cert-manager annotation:
       cert-manager.io/cluster-issuer: "letsencrypt-prod"
       
    5. cert-manager will automatically request and manage TLS certificates using Cloudflare DNS-01 challenge
  EOT
}

# ============================================================================
# IAM Role ARNs
# ============================================================================

output "cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = module.eks.cluster_role_arn
}

output "node_role_arn" {
  description = "ARN of the IAM role used by the EKS nodes"
  value       = module.eks.node_role_arn
}

output "ebs_csi_driver_role_arn" {
  description = "ARN of the IAM role used by the EBS CSI driver"
  value       = module.eks.ebs_csi_driver_role_arn
}

# ============================================================================
# Cost Optimization Information
# ============================================================================

output "cost_optimization_summary" {
  description = "Summary of cost optimization configurations"
  value       = <<-EOT
    Cost Optimization Configuration:
    
    - NAT Gateway: Single NAT Gateway (saves ~$32/month per additional NAT)
    - Node Instance Type: t3.small (2 vCPU, 2GB RAM)
    - Node Count: Min=1, Desired=1, Max=3
    - Node Storage: 20GB gp3 volumes
    - Control Plane Logging: Disabled
    
    Estimated Monthly Cost: $150-166
    
    To reduce costs further:
    - Scale down nodes during off-hours
    - Use Spot instances for non-production workloads
    - Monitor and right-size node instance types based on actual usage
  EOT
}
