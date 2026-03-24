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
# AWS Load Balancer Controller Information
# ============================================================================

output "alb_controller_iam_role_arn" {
  description = "ARN of the IAM role for AWS Load Balancer Controller"
  value       = module.aws_lb_controller.iam_role_arn
}

output "alb_controller_service_account" {
  description = "Kubernetes service account for AWS Load Balancer Controller"
  value       = "${module.aws_lb_controller.service_account_namespace}/${module.aws_lb_controller.service_account_name}"
}

# ============================================================================
# cert-manager Information
# ============================================================================

output "cert_manager_namespace" {
  description = "Namespace where cert-manager is installed"
  value       = module.cert_manager.namespace
}

output "cert_manager_cluster_issuer" {
  description = "Name of the ClusterIssuer for Let's Encrypt"
  value       = module.cert_manager.cluster_issuer_name
}

# ============================================================================
# Domain and DNS Configuration
# ============================================================================

output "domain_name" {
  description = "Domain name configured for TLS certificates"
  value       = var.domain_name
}

output "cloudflare_dns_setup_instructions" {
  description = "Instructions for configuring Cloudflare DNS records"
  value       = <<-EOT
    Cloudflare DNS Setup Instructions:
    
    1. After deploying an Ingress resource, the AWS Load Balancer Controller will create an ALB
    2. Get the ALB DNS name from the Ingress:
       kubectl get ingress <ingress-name> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    3. In Cloudflare dashboard for domain ${var.domain_name}:
       - Create a CNAME record pointing your subdomain to the ALB DNS name
       - Example: subdomain.${var.domain_name} -> <alb-dns-name>
       - Set Proxy status to "DNS only" (gray cloud) for TLS passthrough
    
    4. cert-manager will automatically request and manage TLS certificates using DNS-01 challenge
    
    5. Verify certificate issuance:
       kubectl get certificate -A
       kubectl describe certificate <certificate-name> -n <namespace>
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
