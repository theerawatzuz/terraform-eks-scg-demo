# Infrastructure Architecture Diagram

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
└────────────────────────────────────┬────────────────────────────────────────────┘
                                     │
                                     │ DNS Resolution
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                AWS REGION                                        │
│                              ap-southeast-1                                      │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         APPLICATION LOAD BALANCER                          │ │
│  │                    (Created by Nginx LoadBalancer Service)                 │ │
│  │                                                                            │ │
│  │  • Type: Network Load Balancer (NLB)                                      │ │
│  │  • Scheme: internet-facing                                                │ │
│  │  • Health Check: HTTP /healthz:10254                                      │ │
│  │  • Listeners: 80 (HTTP), 443 (HTTPS passthrough)                         │ │
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
│  │  │  │  │         EKS CLUSTER (Kubernetes 1.28)                   │ │ │ │ │
│  │  │  │  │                                                         │ │ │ │ │
│  │  │  │  │  ┌───────────────────────────────────────────────────┐ │ │ │ │ │
│  │  │  │  │  │  Managed Node Group                               │ │ │ │ │ │
│  │  │  │  │  │  • Instance Type: t3.small                        │ │ │ │ │ │
│  │  │  │  │  │  • Min: 1, Desired: 1, Max: 3                     │ │ │ │ │ │
│  │  │  │  │  │  • Disk: 20GB gp3 (encrypted)                     │ │ │ │ │ │
│  │  │  │  │  │  • IMDSv2: Required                               │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  ┌─────────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  INGRESS LAYER                              │ │ │ │ │ │ │
│  │  │  │  │  │  │                                             │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐│ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Nginx Ingress Controller              ││ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Namespace: ingress-nginx              ││ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Replicas: 2-3                         ││ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • TLS Termination                     ││ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • HTTP/HTTPS Routing                  ││ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Health Check Endpoint: /healthz     ││ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────┬───────────────────────┘│ │ │ │ │ │ │
│  │  │  │  │  │  └───────────────────┼──────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  │                      │                            │ │ │ │ │ │
│  │  │  │  │  │  ┌───────────────────▼──────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  CERTIFICATE MANAGEMENT                      │ │ │ │ │ │ │
│  │  │  │  │  │  │                                              │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  cert-manager                          │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Namespace: cert-manager               │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Let's Encrypt (Production)          │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Cloudflare DNS-01 Challenge         │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Wildcard Cert: *.thebrainsurf.site  │ │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘ │ │ │ │ │ │ │
│  │  │  │  │  │  └──────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  ┌───────────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  GITOPS & DEPLOYMENT                          │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  ArgoCD                                │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Namespace: argocd                     │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Continuous Deployment               │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Auto-sync Applications              │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Self-healing                        │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  └───────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  ┌───────────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  MONITORING STACK                             │ │ │ │ │ │ │
│  │  │  │  │  │  │  Namespace: monitoring                        │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Prometheus                            │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Metrics Collection                  │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Storage: 10Gi gp3                   │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Retention: 7 days                   │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • URL: prometheus.thebrainsurf.site   │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Grafana                               │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Visualization & Dashboards          │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Storage: 5Gi gp3                    │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • URL: grafana.thebrainsurf.site      │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Loki                                  │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Log Aggregation                     │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Storage: 10Gi gp3                   │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Promtail                              │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Log Collection (DaemonSet)          │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  Tempo                                 │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Distributed Tracing                 │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Storage: 10Gi gp3                   │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  └───────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  ┌───────────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  SECRETS MANAGEMENT                           │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  External Secrets Operator             │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • AWS Secrets Manager Integration     │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • IRSA Authentication                 │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  └───────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  ┌───────────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  STORAGE                                      │ │ │ │ │ │ │
│  │  │  │  │  │  │                                               │ │ │ │ │ │ │
│  │  │  │  │  │  │  ┌────────────────────────────────────────┐  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  EBS CSI Driver                        │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • Dynamic Volume Provisioning         │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • gp3 Storage Class (encrypted)       │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  │  • IRSA Role for AWS API               │  │ │ │ │ │ │ │
│  │  │  │  │  │  │  └────────────────────────────────────────┘  │ │ │ │ │ │ │
│  │  │  │  │  │  └───────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  │                                                   │ │ │ │ │ │
│  │  │  │  │  │  ┌───────────────────────────────────────────────┐ │ │ │ │ │ │
│  │  │  │  │  │  │  CORE ADD-ONS                                 │ │ │ │ │ │ │
│  │  │  │  │  │  │  • vpc-cni (Pod Networking)                   │ │ │ │ │ │ │
│  │  │  │  │  │  │  • coredns (DNS Resolution)                   │ │ │ │ │ │ │
│  │  │  │  │  │  │  • kube-proxy (Service Networking)            │ │ │ │ │ │ │
│  │  │  │  │  │  └───────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  │  └───────────────────────────────────────────────────┘ │ │ │ │ │ │
│  │  │  │  └─────────────────────────────────────────────────────────┘ │ │ │ │ │
│  │  │  └───────────────────────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────────────────────────┘ │ │
│  │                                                                            │ │
│  │  ┌──────────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    AVAILABILITY ZONE B                                │ │ │
│  │  │                                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Public Subnet (10.0.1.0/24)                                    │ │ │ │
│  │  │  │  • Route to NAT Gateway in AZ-A (shared)                        │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────┘ │ │ │
│  │  │                                                                       │ │ │
│  │  │  ┌─────────────────────────────────────────────────────────────────┐ │ │ │
│  │  │  │  Private Subnet (10.0.11.0/24)                                  │ │ │ │
│  │  │  │  • EKS Worker Nodes (distributed across AZs)                    │ │ │ │
│  │  │  └─────────────────────────────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                         IAM & SECURITY                                     │ │
│  │                                                                            │ │
│  │  • OIDC Provider (IRSA - IAM Roles for Service Accounts)                  │ │
│  │  • EKS Cluster Role (AmazonEKSClusterPolicy)                              │ │
│  │  • Node Group Role (Worker, CNI, Registry, SSM policies)                  │ │
│  │  • EBS CSI Driver Role (Volume management permissions)                    │ │
│  │  • External Secrets Role (Secrets Manager access)                         │ │
│  │  • Security Groups (Cluster communication)                                │ │
│  │  • IMDSv2 Required (Enhanced security)                                    │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                      TERRAFORM STATE MANAGEMENT                            │ │
│  │                                                                            │ │
│  │  • S3 Bucket: Encrypted state storage                                     │ │
│  │  • DynamoDB Table: State locking                                          │ │
│  │  • Backend: S3 with encryption enabled                                    │ │
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
Application Load Balancer (NLB)
    │
    ▼
Nginx Ingress Controller (TLS Termination)
    │
    ├─► Prometheus (monitoring.thebrainsurf.site)
    ├─► Grafana (grafana.thebrainsurf.site)
    ├─► ArgoCD (argocd.thebrainsurf.site)
    └─► Application Services
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
2. **t3.small Instances**: Right-sized for workload (min=1, max=3)
3. **Single ALB**: One NLB for all applications via Nginx (~$80-100/month savings)
4. **gp3 Volumes**: Cost-effective storage with better performance
5. **No Control Plane Logging**: Disabled for cost savings
6. **Minimal Resource Requests**: Optimized CPU/memory for all pods

**Estimated Monthly Cost**: ~$150-200 (vs $400-500 with multiple ALBs)

---

## 🎯 Key Features

### High Availability

- Multi-AZ deployment (2 availability zones)
- Auto-scaling node group (1-3 nodes)
- Nginx Ingress with 2-3 replicas
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
- All accessible via HTTPS with valid certificates

### GitOps

- **ArgoCD**: Continuous deployment
- Auto-sync and self-healing
- Declarative application management
- Git as single source of truth

### Storage

- EBS CSI Driver with IRSA
- gp3 storage class (encrypted)
- Dynamic volume provisioning
- Persistent storage for stateful apps

### Secrets Management

- External Secrets Operator
- AWS Secrets Manager integration
- Automatic secret synchronization
- IRSA for secure access

---

## 📦 Deployed Components

### Infrastructure Layer (Terraform)

- VPC with public/private subnets
- EKS cluster (Kubernetes 1.28)
- Managed node group
- Nginx Ingress Controller
- cert-manager
- External Secrets Operator
- IAM roles and policies
- Security groups

### Application Layer (Kubernetes)

- ArgoCD (GitOps)
- Prometheus (Metrics)
- Grafana (Dashboards)
- Loki (Logs)
- Promtail (Log collector)
- Tempo (Traces)
- Ingress resources with TLS

---

## 🌐 Accessible URLs

| Service    | URL                                  | Status     |
| ---------- | ------------------------------------ | ---------- |
| Prometheus | https://prometheus.thebrainsurf.site | ✅ Running |
| Grafana    | https://grafana.thebrainsurf.site    | ✅ Running |
| ArgoCD     | https://argocd.thebrainsurf.site     | ✅ Running |

All services use:

- Valid TLS certificates from Let's Encrypt
- Cloudflare DNS-01 challenge
- Nginx Ingress for routing
- Single ALB for cost efficiency

---

## 🔧 Management Tools

- **Terraform**: Infrastructure as Code
- **kubectl**: Kubernetes CLI
- **AWS CLI**: AWS resource management
- **ArgoCD CLI**: GitOps operations
- **Helm**: Package management

---

## 📝 Configuration

- **Region**: ap-southeast-1 (Singapore)
- **AWS Profile**: default
- **Domain**: thebrainsurf.site (Cloudflare)
- **Kubernetes Version**: 1.28
- **Node Type**: t3.small
- **Storage**: gp3 (encrypted)
