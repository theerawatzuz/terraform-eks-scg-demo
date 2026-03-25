# Certificate Setup Guide

## Prerequisites

1. Cloudflare API Token with DNS edit permissions
2. Your email for Let's Encrypt notifications

## Step 1: Create Cloudflare API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Edit zone DNS" template
4. Zone Resources: Include > Specific zone > thebrainsurf.site
5. Copy the token

## Step 2: Update Secret

Edit `kubernetes/apps/cert-manager/cloudflare-secret.yaml`:

```yaml
stringData:
  api-token: "YOUR_ACTUAL_TOKEN_HERE"
```

## Step 3: Update ClusterIssuer Email

Edit `kubernetes/apps/cert-manager/clusterissuer.yaml`:

```yaml
email: your-actual-email@example.com
```

## Step 4: Apply Configuration

```bash
# Apply secret
kubectl apply -f kubernetes/apps/cert-manager/cloudflare-secret.yaml

# Apply ClusterIssuer
kubectl apply -f kubernetes/apps/cert-manager/clusterissuer.yaml

# Verify
kubectl get clusterissuer
```

## Step 5: Deploy ArgoCD Ingress

```bash
kubectl apply -f kubernetes/apps/argocd/ingress.yaml
```

## Step 6: Configure DNS

Get NLB DNS:

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Create wildcard CNAME in Cloudflare:

- Type: CNAME
- Name: `*` (wildcard)
- Target: [NLB DNS from above]
- Proxy: DNS only (grey cloud)

## Step 7: Verify Certificate

```bash
# Check certificate status
kubectl get certificate -n argocd

# Check certificate details
kubectl describe certificate argocd-tls -n argocd

# Wait for Ready status (may take 1-2 minutes)
```

## Access ArgoCD

- URL: https://argocd.thebrainsurf.site
- Username: `admin`
- Password: Get with:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
  ```

## Troubleshooting

### Certificate not issuing

```bash
# Check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager

# Check certificate events
kubectl describe certificate argocd-tls -n argocd

# Check challenge
kubectl get challenge -n argocd
```

### Common issues

1. Wrong Cloudflare API token permissions
2. DNS not propagated yet (wait 2-3 minutes)
3. Email not updated in ClusterIssuer
