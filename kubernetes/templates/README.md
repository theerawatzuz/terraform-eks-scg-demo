# Templates

This directory contains templates for creating new applications.

## Creating a New Application

### 1. Copy App Template

```bash
cp -r kubernetes/templates/app-template kubernetes/apps/myapp
```

### 2. Replace Placeholders

Replace all `APP_NAME` with your actual app name in:

- `namespace.yaml`
- `deployment.yaml`
- `service.yaml`
- `ingress.yaml`

Replace `IMAGE_NAME:TAG` in `deployment.yaml` with your actual image.

### 3. Create ArgoCD Application

```bash
cp kubernetes/templates/argocd-app-template.yaml kubernetes/argocd-apps/myapp.yaml
```

Edit `myapp.yaml` and replace:

- `APP_NAME` with your app name
- Update `repoURL` if needed

### 4. Commit and Push

```bash
git add kubernetes/
git commit -m "Add myapp"
git push
```

ArgoCD will auto-sync within 3 minutes.

### 5. Configure DNS

Add CNAME record in Cloudflare:

- Name: `myapp`
- Target: [NLB DNS from ingress-nginx service]
- Proxy: DNS only

## Example

```bash
# Create new app called "demo"
cp -r kubernetes/templates/app-template kubernetes/apps/demo
sed -i '' 's/APP_NAME/demo/g' kubernetes/apps/demo/*.yaml
sed -i '' 's/IMAGE_NAME:TAG/nginx:latest/g' kubernetes/apps/demo/deployment.yaml

# Create ArgoCD Application
cp kubernetes/templates/argocd-app-template.yaml kubernetes/argocd-apps/demo.yaml
sed -i '' 's/APP_NAME/demo/g' kubernetes/argocd-apps/demo.yaml

# Commit
git add kubernetes/
git commit -m "Add demo app"
git push
```
