# EKS Module

This module creates an Amazon EKS (Elastic Kubernetes Service) cluster with managed node groups, essential add-ons, and IRSA (IAM Roles for Service Accounts) configuration.

## Features

- EKS cluster with configurable Kubernetes version (default: 1.28)
- Managed node group with auto-scaling (default: t3.small, min=1, desired=1, max=3)
- IAM roles for cluster and nodes with required policies
- OIDC provider for IRSA support
- Essential EKS add-ons: vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver
- Launch template with gp3 encrypted volumes (20GB)
- IMDSv2 required for enhanced security
- gp3 storage class for cost-optimized persistent storage
- Both public and private endpoint access enabled

## Cost Optimization

- t3.small instance type (50% savings vs t3.medium)
- Minimal node count (min=1, desired=1)
- gp3 volumes instead of gp2
- Control plane logging disabled
- 20GB disk size

## Usage

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-eks-cluster"
  cluster_version = "1.28"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  # Node group configuration
  node_group_name     = "general"
  node_instance_types = ["t3.small"]
  node_desired_size   = 1
  node_min_size       = 1
  node_max_size       = 3
  node_disk_size      = 20

  # Add-ons
  enable_vpc_cni        = true
  enable_coredns        = true
  enable_kube_proxy     = true
  enable_ebs_csi_driver = true

  # Access configuration
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name                            | Description                                          | Type         | Default      | Required |
| ------------------------------- | ---------------------------------------------------- | ------------ | ------------ | -------- |
| cluster_name                    | Name of the EKS cluster                              | string       | -            | yes      |
| cluster_version                 | Kubernetes version for EKS cluster                   | string       | "1.28"       | no       |
| vpc_id                          | VPC ID where EKS cluster will be deployed            | string       | -            | yes      |
| subnet_ids                      | List of subnet IDs for EKS cluster (private subnets) | list(string) | -            | yes      |
| node_group_name                 | Name of the EKS node group                           | string       | "general"    | no       |
| node_instance_types             | List of instance types for node group                | list(string) | ["t3.small"] | no       |
| node_desired_size               | Desired number of nodes                              | number       | 1            | no       |
| node_min_size                   | Minimum number of nodes                              | number       | 1            | no       |
| node_max_size                   | Maximum number of nodes                              | number       | 3            | no       |
| node_disk_size                  | Disk size in GB for node instances                   | number       | 20           | no       |
| enable_vpc_cni                  | Enable VPC CNI add-on                                | bool         | true         | no       |
| enable_coredns                  | Enable CoreDNS add-on                                | bool         | true         | no       |
| enable_kube_proxy               | Enable kube-proxy add-on                             | bool         | true         | no       |
| enable_ebs_csi_driver           | Enable EBS CSI driver add-on                         | bool         | true         | no       |
| cluster_endpoint_public_access  | Enable public access to cluster endpoint             | bool         | true         | no       |
| cluster_endpoint_private_access | Enable private access to cluster endpoint            | bool         | true         | no       |
| tags                            | Tags to apply to all resources                       | map(string)  | {}           | no       |

## Outputs

| Name                               | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| cluster_id                         | EKS cluster ID                                             |
| cluster_name                       | EKS cluster name                                           |
| cluster_endpoint                   | EKS cluster endpoint URL                                   |
| cluster_version                    | EKS cluster Kubernetes version                             |
| cluster_certificate_authority_data | Base64 encoded certificate data for cluster authentication |
| cluster_security_group_id          | Security group ID attached to the EKS cluster              |
| node_group_id                      | EKS node group ID                                          |
| node_group_status                  | Status of the EKS node group                               |
| cluster_oidc_issuer_url            | OIDC issuer URL for the cluster (used for IRSA)            |
| oidc_provider_arn                  | ARN of the OIDC provider for IRSA                          |
| cluster_role_arn                   | ARN of the IAM role used by the EKS cluster                |
| node_role_arn                      | ARN of the IAM role used by the EKS nodes                  |
| ebs_csi_driver_role_arn            | ARN of the IAM role used by the EBS CSI driver             |

## IAM Roles

### Cluster Role

- AmazonEKSClusterPolicy
- AmazonEKSVPCResourceController

### Node Role

- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly
- AmazonSSMManagedInstanceCore

### EBS CSI Driver Role

- Custom policy with EBS volume management permissions
- Uses IRSA for secure access from Kubernetes service account

## Security Features

- IMDSv2 required on all nodes
- Encrypted EBS volumes (gp3)
- Security group with minimal required rules
- IRSA for pod-level IAM permissions
- SSM access for secure node management

## Storage

The module creates a `gp3` storage class with the following configuration:

- Volume type: gp3 (cost-optimized)
- Encryption: enabled
- Filesystem: ext4
- Reclaim policy: Delete
- Volume binding mode: WaitForFirstConsumer

## Prerequisites

- VPC with private subnets across multiple availability zones
- Terraform >= 1.5.0
- AWS provider configured
- Kubernetes provider configured (for storage class)

## Post-Deployment

After the cluster is created, configure kubectl access:

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region> --profile <profile>
```

Verify cluster access:

```bash
kubectl get nodes
kubectl get storageclass
```

## Notes

- Control plane logging is disabled for cost optimization
- Nodes are distributed across multiple availability zones
- The cluster supports both public and private endpoint access
- Maximum 1 node can be unavailable during updates
