# Bootstrap Instructions

## Prerequisites

- EKS cluster running
- kubectl configured
- Git repository with this code

## Step 1: Install ArgoCD

```bash
kubectl apply -k kubernetes/bootstrap
```

## Step 2: Wait for ArgoCD

```bash
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## Step 3: Update Git Repository URLs

Edit these files and replace `YOUR_USERNAME/YOUR_REPO`:

- `kubernetes/argocd-apps/root.yaml`
- `kubernetes/argocd-apps/argocd.yaml`

```bash
# Example:
# repoURL: https://github.com/yourusername/SCG-DEMO.git
```

## Step 4: Deploy App of Apps

```bash
kubectl apply -f kubernetes/argocd-apps/root.yaml
```

## Step 5: Get ArgoCD Admin Password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## Step 6: Get ALB DNS

```bash
kubectl get ingress argocd-server -n argocd
```

## Step 7: Configure Cloudflare DNS

Create CNAME record:

- Name: `argocd`
- Target: [ALB DNS from step 6]
- Proxy: DNS only (grey cloud)

## Step 8: Access ArgoCD

- URL: https://argocd.thebrainsurf.site
- Username: `admin`
- Password: [from step 5]

## Done!

ArgoCD is now managing itself via GitOps. Any changes to `kubernetes/` will auto-sync.

## Adding New Application

1. Copy template:

```bash
cp -r kubernetes/apps/_template kubernetes/apps/myapp
```

2. Update all `APP_NAME` placeholders in the files

3. Create ArgoCD Application:

```bash
cp kubernetes/argocd-apps/_template.yaml kubernetes/argocd-apps/myapp.yaml
# Edit myapp.yaml and replace APP_NAME
```

4. Commit and push:

```bash
git add kubernetes/
git commit -m "Add myapp"
git push
```

5. ArgoCD will auto-deploy within 3 minutes (or click Sync in UI)

6. Configure DNS: `myapp.thebrainsurf.site` -> ALB DNS
