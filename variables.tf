# Root Module Variables
# This file defines all input variables for the EKS Terraform Infrastructure
# with validation rules and cost-optimized default values

# ============================================================================
# AWS Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "ap-southeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., ap-southeast-1)"
  }
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

# ============================================================================
# EKS Cluster Configuration
# ============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster (lowercase letters, numbers, and hyphens only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only lowercase letters, numbers, and hyphens"
  }

  validation {
    condition     = length(var.cluster_name) >= 1 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 1 and 100 characters"
  }
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "environment" {
  description = "Environment name (dev, staging, or prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

# ============================================================================
# VPC Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block"
  }
}

variable "availability_zones" {
  description = "List of availability zones for high availability (minimum 2 required)"
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability"
  }
}

variable "enable_single_nat_gateway" {
  description = "Use single NAT Gateway for cost optimization (true = single NAT, false = NAT per AZ)"
  type        = bool
  default     = true
}

# ============================================================================
# Node Group Configuration (Cost-Optimized Defaults)
# ============================================================================

variable "node_instance_types" {
  description = "EC2 instance types for worker nodes"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_desired_size >= 1
    error_message = "node_desired_size must be at least 1"
  }
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_min_size >= 1
    error_message = "node_min_size must be at least 1"
  }
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.node_max_size >= 1
    error_message = "node_max_size must be at least 1"
  }
}

variable "node_disk_size" {
  description = "EBS volume size for worker nodes (in GB)"
  type        = number
  default     = 20

  validation {
    condition     = var.node_disk_size >= 20 && var.node_disk_size <= 1000
    error_message = "node_disk_size must be between 20 and 1000 GB"
  }
}

# ============================================================================
# Cluster Access Configuration
# ============================================================================

variable "cluster_endpoint_public_access" {
  description = "Enable cluster endpoint public access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable cluster endpoint private access"
  type        = bool
  default     = true
}

# ============================================================================
# EKS Add-ons Configuration
# ============================================================================

variable "enable_vpc_cni" {
  description = "Enable VPC CNI add-on for pod networking"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS add-on for cluster DNS resolution"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy add-on for service networking"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver add-on for persistent storage"
  type        = bool
  default     = true
}

# ============================================================================
# Domain and TLS Configuration
# ============================================================================

variable "domain_name" {
  description = "Domain name for TLS certificates (self-signed)"
  type        = string
  default     = "thebrainsurf.site"
}

# ============================================================================
# Helm Chart Versions
# ============================================================================

variable "alb_controller_chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.6.2"
}

# ============================================================================
# Resource Tagging
# ============================================================================

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Project     = "EKS-Infrastructure"
    Environment = "dev"
  }
}
