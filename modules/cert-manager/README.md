# cert-manager Module

This module deploys cert-manager to an EKS cluster using Helm. cert-manager automates TLS certificate issuance and renewal using Let's Encrypt with Cloudflare DNS-01 challenge.

## Features

- Deploys cert-manager via Helm chart from Jetstack
- Installs Custom Resource Definitions (CRDs)
- Optionally creates Cloudflare API token secret
- Optionally creates ClusterIssuer for Let's Encrypt production
- Supports wildcard certificates via DNS-01 challenge
- Automatic certificate renewal before expiration

## Usage

### Basic Installation (without ClusterIssuer)

```hcl
module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_name                       = "my-eks-cluster"
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  namespace   = "cert-manager"
  domain_name = "thebrainsurf.site"

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Full Installation (with ClusterIssuer)

```hcl
module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_name                       = "my-eks-cluster"
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  namespace             = "cert-manager"
  domain_name           = "thebrainsurf.site"
  cloudflare_api_token  = var.cloudflare_api_token
  letsencrypt_email     = "admin@thebrainsurf.site"

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name                               | Description                                     | Type        | Default                   | Required |
| ---------------------------------- | ----------------------------------------------- | ----------- | ------------------------- | -------- |
| cluster_name                       | Name of the EKS cluster                         | string      | -                         | yes      |
| cluster_endpoint                   | Endpoint for EKS cluster                        | string      | -                         | yes      |
| cluster_certificate_authority_data | Base64 encoded certificate data for EKS cluster | string      | -                         | yes      |
| namespace                          | Kubernetes namespace for cert-manager           | string      | "cert-manager"            | no       |
| chart_version                      | Version of cert-manager Helm chart              | string      | "v1.16.2"                 | no       |
| cloudflare_api_token               | Cloudflare API token for DNS-01 challenge       | string      | ""                        | no       |
| domain_name                        | Domain name for TLS certificates                | string      | "thebrainsurf.site"       | no       |
| letsencrypt_email                  | Email address for Let's Encrypt notifications   | string      | "admin@thebrainsurf.site" | no       |
| tags                               | Tags to apply to resources                      | map(string) | {}                        | no       |

## Outputs

| Name                  | Description                                    |
| --------------------- | ---------------------------------------------- |
| namespace             | Namespace where cert-manager is deployed       |
| release_name          | Helm release name for cert-manager             |
| release_status        | Status of the Helm release                     |
| clusterissuer_created | Whether ClusterIssuer was created              |
| setup_instructions    | Instructions for completing cert-manager setup |

## Post-Deployment Setup

### If Cloudflare API token was not provided during deployment:

1. Create Cloudflare API token with Zone:DNS:Edit permissions
2. Create Kubernetes secret:
   ```bash
   kubectl create secret generic cloudflare-api-token \
     --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN \
     -n cert-manager
   ```
3. Apply ClusterIssuer:
   ```bash
   kubectl apply -f kubernetes/apps/cert-manager/clusterissuer.yaml
   ```

### Verify Installation

```bash
# Check cert-manager pods
kubectl get pods -n cert-manager

# Check ClusterIssuer
kubectl get clusterissuer

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

## Example Certificate Resource

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-cert
  namespace: default
spec:
  secretName: wildcard-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - "*.thebrainsurf.site"
    - "thebrainsurf.site"
```

## Example Ingress with cert-manager

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-app
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.thebrainsurf.site
      secretName: app-tls
  rules:
    - host: app.thebrainsurf.site
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: example-app
                port:
                  number: 80
```

## Troubleshooting

### Certificate not issuing

```bash
# Check certificate status
kubectl describe certificate <cert-name>

# Check certificate request
kubectl describe certificaterequest <cert-name>

# Check challenge
kubectl describe challenge <challenge-name>

# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager
```

### DNS-01 challenge failing

- Verify Cloudflare API token has Zone:DNS:Edit permissions
- Verify API token secret exists: `kubectl get secret cloudflare-api-token -n cert-manager`
- Check ClusterIssuer configuration: `kubectl describe clusterissuer letsencrypt-prod`

## Cost Optimization

- Resource limits configured for t3.small nodes
- Minimal CPU/memory requests (10m CPU, 32Mi memory)
- No additional AWS resources required (uses Cloudflare DNS)

## Notes

- cert-manager uses DNS-01 challenge for wildcard certificates
- Certificates are automatically renewed 30 days before expiration
- Let's Encrypt production has rate limits (50 certificates per domain per week)
- Use Let's Encrypt staging for testing: https://acme-staging-v02.api.letsencrypt.org/directory
