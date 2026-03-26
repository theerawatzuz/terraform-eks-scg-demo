# Nginx Ingress Controller Module

This module deploys Nginx Ingress Controller to an EKS cluster using Helm. The controller is exposed via a single Application Load Balancer (ALB) that routes traffic to Nginx pods, which handle TLS termination and application routing.

## Architecture

```
Internet → ALB (LoadBalancer Service) → Nginx Ingress Controller → Backend Services
```

## Features

- Deploys Nginx Ingress Controller via Helm chart
- Creates a single ALB for all applications (cost-optimized)
- Configures HTTP health checks on /healthz endpoint
- Supports 2-3 replicas for high availability
- TLS termination at Nginx level (not ALB)
- No IRSA role required (Nginx doesn't need AWS permissions)

## Usage

```hcl
module "nginx_ingress" {
  source = "./modules/nginx-ingress"

  cluster_name                       = "my-eks-cluster"
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  replica_count = 2
  namespace     = "ingress-nginx"

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name                               | Description                                       | Type        | Default         | Required |
| ---------------------------------- | ------------------------------------------------- | ----------- | --------------- | -------- |
| cluster_name                       | Name of the EKS cluster                           | string      | -               | yes      |
| cluster_endpoint                   | Endpoint for EKS cluster                          | string      | -               | yes      |
| cluster_certificate_authority_data | Base64 encoded certificate data for EKS cluster   | string      | -               | yes      |
| replica_count                      | Number of Nginx Ingress Controller replicas       | number      | 2               | no       |
| namespace                          | Kubernetes namespace for Nginx Ingress Controller | string      | "ingress-nginx" | no       |
| chart_version                      | Version of ingress-nginx Helm chart               | string      | "4.11.3"        | no       |
| tags                               | Tags to apply to resources                        | map(string) | {}              | no       |

## Outputs

| Name               | Description                                          |
| ------------------ | ---------------------------------------------------- |
| namespace          | Namespace where Nginx Ingress Controller is deployed |
| release_name       | Helm release name for Nginx Ingress Controller       |
| release_status     | Status of the Helm release                           |
| ingress_class_name | Name of the ingress class (nginx)                    |

## Notes

- The ALB is created automatically by Kubernetes when the LoadBalancer service is created
- Use `ingressClassName: nginx` in your Ingress resources
- TLS certificates should be managed by cert-manager
- The ALB DNS name will be available after deployment via `kubectl get svc -n ingress-nginx`
- Health checks are performed on port 10254 at /healthz endpoint

## Cost Optimization

- Single ALB for all applications saves $16-20/month per additional app
- Resource limits configured for t3.small nodes
- 2 replicas by default (can scale to 3 for production)

## Example Ingress Resource

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
