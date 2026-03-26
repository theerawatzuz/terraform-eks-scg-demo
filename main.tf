# Terraform configuration
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12, < 3.0"
    }
  }
}

# ============================================================================
# Validation and Local Values
# ============================================================================

locals {
  # Validate node scaling parameters relationships
  validate_node_scaling = (
    var.node_min_size >= 1 &&
    var.node_desired_size >= var.node_min_size &&
    var.node_desired_size <= var.node_max_size &&
    var.node_max_size >= var.node_min_size
  ) ? true : tobool("ERROR: Invalid node scaling configuration. Ensure: node_min_size >= 1, node_min_size <= node_desired_size <= node_max_size")

  # Common tags applied to all resources
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Project     = "EKS-Infrastructure"
    },
    var.tags
  )
}

# AWS Provider Configuration
# Configured for ap-southeast-1 region with "default" profile
provider "aws" {
  region  = "ap-southeast-1"
  profile = "default"
}

# Kubernetes Provider Configuration
# This provider connects to the EKS cluster using AWS CLI authentication
# Note: This configuration will be functional after the EKS cluster is created
provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      try(module.eks.cluster_name, ""),
      "--region",
      "ap-southeast-1",
      "--profile",
      "default"
    ]
  }
}

# Helm Provider Configuration
# This provider connects to the EKS cluster using AWS CLI authentication
# Note: This configuration will be functional after the EKS cluster is created
provider "helm" {
  kubernetes {
    host                   = try(module.eks.cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        try(module.eks.cluster_name, ""),
        "--region",
        "ap-southeast-1",
        "--profile",
        "default"
      ]
    }
  }
}

# ============================================================================
# Module Calls
# ============================================================================

# VPC Module
# Creates VPC with public and private subnets, NAT Gateway, and Internet Gateway
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = var.cluster_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = var.enable_single_nat_gateway
  enable_nat_gateway = true

  tags = local.common_tags
}

# EKS Module
# Creates EKS cluster, managed node group, OIDC provider, and add-ons
module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_disk_size      = var.node_disk_size

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  enable_vpc_cni        = var.enable_vpc_cni
  enable_coredns        = var.enable_coredns
  enable_kube_proxy     = var.enable_kube_proxy
  enable_ebs_csi_driver = var.enable_ebs_csi_driver

  tags = local.common_tags

  depends_on = [module.vpc]
}

# Nginx Ingress Controller Module
# Deploys Nginx Ingress Controller with ALB for application routing
module "nginx_ingress" {
  source = "./modules/nginx-ingress"

  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  replica_count = var.nginx_replica_count
  namespace     = "ingress-nginx"

  tags = local.common_tags

  depends_on = [module.eks]
}

# cert-manager Module
# Manages TLS certificates with Let's Encrypt and Cloudflare DNS-01
module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_name                       = module.eks.cluster_name
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  namespace            = "cert-manager"
  domain_name          = var.domain_name
  cloudflare_api_token = var.cloudflare_api_token
  letsencrypt_email    = var.letsencrypt_email

  tags = local.common_tags

  depends_on = [module.eks]
}

# External Secrets Operator Module
# Manages secrets from AWS Secrets Manager
module "external_secrets" {
  source = "./modules/external-secrets"

  cluster_name            = module.eks.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn

  tags = local.common_tags

  depends_on = [module.eks]
}

# Cluster Autoscaler Module
# Automatically scales EKS nodes based on pod resource requests
module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"

  cluster_name            = module.eks.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn

  namespace = "kube-system"

  tags = local.common_tags

  depends_on = [module.eks]
}
