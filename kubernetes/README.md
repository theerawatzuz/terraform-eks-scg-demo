# Kubernetes GitOps

GitOps repository structure for EKS cluster using ArgoCD.

## Structure

```
kubernetes/
├── bootstrap/           # Initial ArgoCD installation (manual apply once)
├── apps/               # Application manifests
│   ├── argocd/        # ArgoCD self-management
│   └── <app-name>/    # Other applications
└── argocd-apps/       # ArgoCD Application definitions (App of Apps)
```

## Pattern

Each application follows this structure:

```
apps/<app-name>/
├── namespace.yaml      # Namespace definition
├── deployment.yaml     # Application deployment
├── service.yaml        # Service definition
└── ingress.yaml        # Ingress with subdomain
```

## Bootstrap (One-time setup)

```bash
# 1. Install ArgoCD
kubectl apply -k kubernetes/bootstrap

# 2. Wait for ArgoCD
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 3. Deploy App of Apps
kubectl apply -f kubernetes/argocd-apps/root.yaml

# 4. Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## Adding New Application

1. Create app directory: `kubernetes/apps/<app-name>/`
2. Add manifests (namespace, deployment, service, ingress)
3. Create ArgoCD Application: `kubernetes/argocd-apps/<app-name>.yaml`
4. Commit and push - ArgoCD will auto-sync

## DNS Pattern

All applications use subdomain pattern:

- ArgoCD: `argocd.thebrainsurf.site`
- App: `<app-name>.thebrainsurf.site`

Configure CNAME in Cloudflare pointing to ALB DNS.
