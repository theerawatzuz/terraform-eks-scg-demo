# EKS Terraform Infrastructure

Production-ready, cost-optimized Amazon EKS infrastructure deployed using Terraform in the ap-southeast-1 (Singapore) region.

## Overview

Production-ready EKS infrastructure on AWS with cost-optimized configuration, deployed in ap-southeast-1 region.

---

## 🏗️ Complete Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    INTERNET                                      │
│                                  (Users/Traffic)                                 │
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │
                                     │ HTTPS/HTTP
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CLOUDFLARE DNS                                      │
│                          (thebrainsurf.site)                                     │
│                                                                                  │
│  DNS Records (CNAME):                                                           │
│  • *.thebrainsurf.site → ALB DNS Name                                          │
│  • prometheus.thebrainsurf.site → ALB                                          │
│  • grafana.thebrainsurf.site → ALB                                             │
│  • argocd.thebrainsurf.site → ALB                                              │
│  • weather-app.thebrainsurf.site → ALB                                         │
│  • weather-api.thebrainsurf.site → ALB                                         │
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │
                                     │ DNS Resolution
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS REGION                                        │
│                              ap-southeast-1                                      │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         APPLICATION LOAD BALANCER (ALB)                    │ │
│  │              (Created by AWS Load Balancer Controller)                     │ │
│  │                                                                            │ │
│  │  • Type: Application Load Balancer (ALB)                                  │ │
│  │  • Scheme: internet-facing                                                │ │
│  │  • Target Type: IP (direct to pods)                                       │ │
│  │  • Health Check: HTTP /healthz:10254                                      │ │
│  │  • Listener: 80 (HTTP only - TLS at Nginx)                               │ │
│  │  • DNS: k8s-ingressn-nginxing-f2e4afe79e-*.elb.amazonaws.com             │ │
│  └──────────────────────────────────┬─────────────────────────────────────────┘ │
│                                     │                                            │
│                                     │ Forward Traffic                            │
│                                     ▼                                            │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                          VPC (10.0.0.0/16)                                 │ │
│  │                                                                            │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    AVAILABILITY ZONE A                                │ │ │
│  │  │                                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Public Subnet (10.0.0.0/24)                                    │ │ │ │
│  │  │  │                                                                 │ │ │ │
│  │  │  │  ┌──────────────────┐                                          │ │ │ │
│  │  │  │  │  NAT Gateway     │ ← Elastic IP                            │ │ │ │
│  │  │  │  │  (Single NAT)    │                                          │ │ │ │
│  │  │  │  └────────┬─────────┘                                          │ │ │ │
│  │  │  │           │                                                     │ │ │ │
│  │  │  │           │ Internet Gateway                                    │ │ │ │
│  │  │  └───────────┼─────────────────────────────────────────────────────┘ │ │ │
│  │  │              │                                                       │ │ │
│  │  │  ┌───────────▼───────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Private Subnet (10.0.10.0/24)                                │ │ │ │
│  │  │  │                                                               │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────────────────┐ │ │ │ │
│  │  │  │  │         EKS CLUSTER (Kubernetes 1.32)                   │ │ │ │ │
│  │  │  │  │                                                         │ │ │ │ │
│  │  │  │  │  ┌───────────────────────────────────────────────────┐ │ │ │ │ │
│  │  │  │  │  │  Managed Node Group                               │ │ │ │ │ │
│  │  │  │  │  │  • Instance Type: t3.small                        │ │ │ │ │ │
│  │  │  │  │  │  • Min: 1, Desired: 1, Max: 8                     │ │ │ │ │ │
│  │  │  │  │  │  • Disk: 20GB gp3 (encrypted)                     │ │ │ │ │ │
│  │  │  │  │  │  • IMDSv2: Required                               │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  Components:                                      │ │ │ │ │ │
│  │  │  │  │  │  • Nginx Ingress (TLS Termination)                │ │ │ │ │ │
│  │  │  │  │  │  • cert-manager (Let's Encrypt)                   │ │ │ │ │ │
│  │  │  │  │  │  • ArgoCD (GitOps)                                │ │ │ │ │ │
│  │  │  │  │  │  • Prometheus + Grafana (Monitoring)              │ │ │ │ │ │
│  │  │  │  │  │  • Loki + Promtail (Logging)                      │ │ │ │ │ │
│  │  │  │  │  │  • Tempo (Tracing)                                │ │ │ │ │ │
│  │  │  │  │  │  • External Secrets Operator                      │ │ │ │ │ │
│  │  │  │  │  │  • Cluster Autoscaler                             │ │ │ │ │ │
│  │  │  │  │  │  • EBS CSI Driver                                 │ │ │ │ │ │
│  │  │  │  │  └───────────────────────────────────────────────────┘ │ │ │ │ │
│  │  │  │  └─────────────────────────────────────────────────────────┘ │ │ │ │
│  │  │  └───────────────────────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                            │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    AVAILABILITY ZONE B                                │ │ │
│  │  │  • Public Subnet (10.0.1.0/24)                                        │ │ │
│  │  │  • Private Subnet (10.0.11.0/24)                                      │ │ │
│  │  │  • EKS Worker Nodes (distributed across AZs)                          │ │ │
│  │  └──────────────────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Traffic Flow

```
User Request
    │
    ▼
Cloudflare DNS (thebrainsurf.site)
    │
    ▼
Application Load Balancer (ALB)
    │ (HTTP - Port 80)
    ▼
Nginx Ingress Controller (TLS Termination with cert-manager)
    │
    ├─► Prometheus (prometheus.thebrainsurf.site)
    ├─► Grafana (grafana.thebrainsurf.site)
    ├─► ArgoCD (argocd.thebrainsurf.site)
    ├─► Weather App Frontend (weather-app.thebrainsurf.site)
    └─► Weather API Backend (weather-api.thebrainsurf.site)
```

---

## 🔐 Certificate Management Flow

```
cert-manager
    │
    ├─► Let's Encrypt (ACME)
    │       │
    │       ▼
    │   DNS-01 Challenge
    │       │
    │       ▼
    │   Cloudflare API
    │       │
    │       ▼
    │   Certificate Issued
    │
    └─► Kubernetes Secret (TLS)
            │
            ▼
        Nginx Ingress (TLS Termination)
```

---

## 💰 Cost Optimization Features

1. **Single NAT Gateway**: Shared across all AZs (~$32/month savings)
2. **t3.small Instances**: Right-sized for workload (min=1, max=8)
3. **Cluster Autoscaler**: Auto-scale nodes based on demand
4. **Single ALB**: One ALB for all applications via Nginx (~$16/month for ALB)
5. **gp3 Volumes**: Cost-effective storage with better performance
6. **No Control Plane Logging**: Disabled for cost savings
7. **Minimal Resource Requests**: Optimized CPU/memory for all pods
8. **Auto Scale-Down**: Remove underutilized nodes after 10 minutes
9. **HPA for Applications**: Scale pods based on CPU/memory (backend: 2-10, frontend: 1-5)
10. **NodePort Service**: Nginx uses NodePort instead of LoadBalancer (saves ~$16/month)

**Estimated Monthly Cost**: ~$150-200 (scales with load)

- EKS Control Plane: $73/month
- EC2 Nodes (t3.small): ~$15-60/month (1-4 nodes)
- ALB: ~$16/month
- NAT Gateway: ~$32/month
- EBS Volumes (gp3): ~$10-20/month
- Data Transfer: ~$5-10/month

---

## 🎯 Key Features

### High Availability

- Multi-AZ deployment (2 availability zones)
- Auto-scaling node group (1-8 nodes)
- Cluster Autoscaler for dynamic scaling
- Distributed workload across AZs

### Security

- Private subnets for EKS nodes
- IMDSv2 required for enhanced security
- Encrypted EBS volumes (gp3)
- IRSA for fine-grained IAM permissions
- Security groups for cluster isolation
- TLS certificates from Let's Encrypt

### Observability

- **Prometheus**: Metrics collection and alerting
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Promtail**: Log collection from all pods
- **Tempo**: Distributed tracing

### GitOps

- **ArgoCD**: Continuous deployment
- Auto-sync and self-healing
- Declarative application management
- Git as single source of truth

---

## 🌐 Accessible URLs

| Service          | URL                                   | Status     | TLS      |
| ---------------- | ------------------------------------- | ---------- | -------- |
| Prometheus       | https://prometheus.thebrainsurf.site  | ✅ Running | ✅ Valid |
| Grafana          | https://grafana.thebrainsurf.site     | ✅ Running | ✅ Valid |
| ArgoCD           | https://argocd.thebrainsurf.site      | ✅ Running | ✅ Valid |
| Weather Frontend | https://weather-app.thebrainsurf.site | ✅ Running | ✅ Valid |
| Weather Backend  | https://weather-api.thebrainsurf.site | ✅ Running | ✅ Valid |

---

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
└── kubernetes/
    ├── apps/                   # Application manifests
    ├── argocd-apps/            # ArgoCD Application definitions
    └── bootstrap/              # Bootstrap resources
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
