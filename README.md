# EKS Terraform Infrastructure

Production-ready, cost-optimized Amazon EKS infrastructure deployed using Terraform in the ap-southeast-1 (Bangkok) region.

## Overview

This infrastructure provides:

- **VPC Networking**: Isolated network with public and private subnets across multiple availability zones
- **EKS Cluster**: Managed Kubernetes cluster with t3.small nodes (min=1, max=3)
- **AWS Load Balancer Controller**: Automatic ALB provisioning for Kubernetes Ingress resources
- **cert-manager**: Automatic TLS certificate management with Let's Encrypt and Cloudflare DNS-01 challenge
- **EBS CSI Driver**: Persistent storage using gp3 volumes
- **Remote State**: S3 backend with DynamoDB locking for team collaboration

### Architecture

```
Cloudflare DNS
     |
     v
Application Load Balancer (TLS Passthrough)
     |
     v
EKS Cluster (ap-southeast-1)
     |
     +-- VPC (10.0.0.0/16)
     |    +-- Public Subnets (AZ-A, AZ-B)
     |    +-- Private Subnets (AZ-A, AZ-B)
     |    +-- NAT Gateway (single for cost optimization)
     |
     +-- Node Group (t3.small, min=1, max=3)
     |
     +-- Add-ons: VPC CNI, CoreDNS, kube-proxy, EBS CSI
     |
     +-- cert-manager (Let's Encrypt + Cloudflare DNS-01)
```

## Prerequisites

- **Terraform**: Version >= 1.5.0
- **kubectl**: Version matching your EKS cluster version
- **AWS CLI**: Configured with profile "default"
- **Cloudflare API Token**: With Zone:DNS:Edit permissions for your domain

## Deployment

### 1. Initialize Backend

First, create the backend infrastructure (S3 bucket and DynamoDB table):

```bash
cd modules/backend
terraform init
terraform apply
```

### 2. Initialize Root Module

```bash
cd ..
terraform init -backend-config="key=eks/<cluster-name>/terraform.tfstate"
```

### 3. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Or use environment-specific configurations:

```bash
# Development
cp environments/dev/terraform.tfvars terraform.tfvars

# Staging
cp environments/staging/terraform.tfvars terraform.tfvars

# Production
cp environments/prod/terraform.tfvars terraform.tfvars
```

### 4. Plan and Apply

```bash
terraform plan
terraform apply
```

## Post-Deployment

### Configure kubectl

```bash
aws eks update-kubeconfig --name <cluster-name> --region ap-southeast-1 --profile default
```

### Verify Cluster Access

```bash
kubectl get nodes
kubectl get pods -A
```

### Cloudflare DNS Setup

1. After deploying an Ingress, get the ALB DNS name:

   ```bash
   kubectl get ingress <ingress-name> -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

2. In Cloudflare dashboard, create a CNAME record:
   - Name: `subdomain` (e.g., `app`)
   - Content: ALB DNS name
   - Proxy status: DNS only (gray cloud)

3. cert-manager will automatically request TLS certificates using DNS-01 challenge.

## Cost Optimization

This configuration uses cost-optimized settings:

- **NAT Gateway**: Single NAT Gateway (saves ~$32/month per additional NAT)
- **Node Instance Type**: t3.small (2 vCPU, 2GB RAM)
- **Node Count**: Min=1, Desired=1, Max=3
- **Node Storage**: 20GB gp3 volumes
- **Control Plane Logging**: Disabled

**Estimated Monthly Cost**: $150-166

## Troubleshooting

### Common Issues

1. **State Lock Timeout**: Wait for the lock to release or manually delete from DynamoDB
2. **EKS Cluster Creation Timeout**: Check CloudWatch logs for EKS cluster status
3. **Node Group Failed**: Verify IAM roles and security group rules
4. **DNS-01 Challenge Failed**: Verify Cloudflare API token permissions

### Debug Commands

```bash
# Check EKS cluster status
aws eks describe-cluster --name <cluster-name> --region ap-southeast-1

# Check node group status
aws eks describe-node-group --cluster-name <cluster-name> --node-group-name <node-group-name> --region ap-southeast-1

# Check cert-manager logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager

# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Module Structure

```
.
├── main.tf              # Root module orchestration
├── variables.tf         # Input variables with validation
├── outputs.tf           # Output values
├── backend.tf           # S3 backend configuration
├── terraform.tfvars.example  # Example variables
├── README.md            # This file
├── modules/
│   ├── vpc/                    # VPC networking module
│   ├── eks/                    # EKS cluster module
│   ├── aws-lb-controller/      # ALB controller module
│   ├── cert-manager/           # cert-manager module
│   └── backend/                # Backend state infrastructure
└── environments/
    ├── dev/                    # Development configuration
    ├── staging/                # Staging configuration
    └── prod/                   # Production configuration
```

## Requirements

| Name       | Version        |
| ---------- | -------------- |
| terraform  | >= 1.5.0       |
| aws        | >= 5.0         |
| kubernetes | >= 2.20        |
| helm       | >= 2.12, < 3.0 |

## License

MIT License - See LICENSE file for details.
