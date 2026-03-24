# cert-manager Module

This module installs and configures cert-manager for automatic TLS certificate management using Let's Encrypt with Cloudflare DNS-01 challenge.

## Features

- Installs cert-manager via Helm chart from jetstack repository
- Creates dedicated cert-manager namespace
- Configures Cloudflare API token secret for DNS-01 challenge
- Creates ClusterIssuer for Let's Encrypt production environment
- Supports wildcard certificates for the configured domain

## Usage

```hcl
module "cert_manager" {
  source = "./modules/cert-manager"

  cluster_name          = "my-eks-cluster"
  domain_name           = "thebrainsurf.site"
  cloudflare_api_token  = var.cloudflare_api_token
  letsencrypt_email     = "admin@thebrainsurf.site"
  chart_version         = "v1.13.3"

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name       | Version        |
| ---------- | -------------- |
| terraform  | >= 1.5.0       |
| helm       | >= 2.12, < 3.0 |
| kubernetes | >= 2.20        |

## Providers

| Name       | Version        |
| ---------- | -------------- |
| helm       | >= 2.12, < 3.0 |
| kubernetes | >= 2.20        |

## Inputs

| Name                 | Description                                                    | Type          | Default               | Required |
| -------------------- | -------------------------------------------------------------- | ------------- | --------------------- | :------: |
| cluster_name         | Name of the EKS cluster                                        | `string`      | n/a                   |   yes    |
| domain_name          | Domain name for certificate management (managed by Cloudflare) | `string`      | `"thebrainsurf.site"` |    no    |
| cloudflare_api_token | Cloudflare API token for DNS-01 challenge                      | `string`      | n/a                   |   yes    |
| letsencrypt_email    | Email address for Let's Encrypt certificate notifications      | `string`      | n/a                   |   yes    |
| chart_version        | Version of the cert-manager Helm chart                         | `string`      | `"v1.13.3"`           |    no    |
| tags                 | Tags to apply to all resources                                 | `map(string)` | `{}`                  |    no    |

## Outputs

| Name                | Description                                 |
| ------------------- | ------------------------------------------- |
| namespace           | Namespace where cert-manager is installed   |
| release_name        | Name of the Helm release                    |
| cluster_issuer_name | Name of the ClusterIssuer for Let's Encrypt |

## Resources Created

- Kubernetes namespace: `cert-manager`
- Helm release: cert-manager with CRDs
- Kubernetes secret: Cloudflare API token
- ClusterIssuer: `letsencrypt-prod` for Let's Encrypt production

## Post-Deployment

After deploying this module, you can create Certificate resources to request TLS certificates:

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

Or use the cert-manager annotation in Ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - app.thebrainsurf.site
      secretName: app-tls
```

## Cloudflare API Token Requirements

The Cloudflare API token must have the following permissions:

- Zone - DNS - Edit
- Zone - Zone - Read

For the specific zone: `thebrainsurf.site`

## Notes

- cert-manager uses Cloudflare DNS-01 challenge, not Route53
- No IAM roles or AWS permissions are required for cert-manager
- Certificates are automatically renewed before expiration
- Wildcard certificates are supported
- TLS termination occurs at Kubernetes level, not at ALB
