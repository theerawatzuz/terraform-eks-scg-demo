# Terraform Backend Configuration
# This file configures S3 backend for remote state storage with DynamoDB locking
# 
# IMPORTANT: Before using this backend configuration, you must first create the
# backend infrastructure (S3 bucket and DynamoDB table) by running:
#   cd modules/backend
#   terraform init
#   terraform apply
#
# After the backend resources are created, initialize this root module with
# the cluster-specific state file path:
#   terraform init -backend-config="key=eks/<cluster-name>/terraform.tfstate"
#
# For example, if your cluster name is "my-eks-cluster":
#   terraform init -backend-config="key=eks/my-eks-cluster/terraform.tfstate"
#
# This approach allows multiple environments/clusters to use the same S3 bucket
# with isolated state files as required by Requirement 20.4.
#
# Requirements: 8.6, 8.7, 8.8, 20.4

terraform {
  backend "s3" {
    # S3 bucket for state storage (must be created first using backend module)
    bucket = "eks-terraform-state-ap-southeast-1"

    # State file path using cluster name for environment isolation
    # Format: eks/${cluster_name}/terraform.tfstate
    # This key should be overridden during terraform init using:
    #   -backend-config="key=eks/<your-cluster-name>/terraform.tfstate"
    # Default key if not overridden:
    key = "eks/default-cluster/terraform.tfstate"

    # AWS region for backend resources
    region = "ap-southeast-1"

    # Enable server-side encryption for state files
    encrypt = true

    # DynamoDB table for state locking (must be created first using backend module)
    dynamodb_table = "eks-terraform-state-lock"

    # AWS profile for authentication
    profile = "default"
  }
}
