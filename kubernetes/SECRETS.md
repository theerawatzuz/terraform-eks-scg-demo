# Secrets Management

**IMPORTANT:** Never commit plain secrets to Git!

## Current Approach: Manual Secret Management

Secrets are created manually and NOT stored in Git.

### Creating the Cloudflare API Token Secret

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="YOUR_CLOUDFLARE_API_TOKEN" \
  -n cert-manager
```

### Verifying the Secret

```bash
kubectl get secret cloudflare-api-token -n cert-manager
```

## Future: Sealed Secrets or External Secrets Operator

For production, consider:

1. **Sealed Secrets** - Encrypt secrets that can be safely stored in Git
2. **External Secrets Operator** - Sync from AWS Secrets Manager (requires more resources)
3. **SOPS** - Encrypt secrets in Git using AWS KMS

## Adding New Secrets

1. Create secret manually with `kubectl create secret`
2. Document the secret name and namespace in this file
3. DO NOT commit the actual secret values to Git

## Secret Inventory

| Secret Name                 | Namespace    | Purpose                          | Created By |
| --------------------------- | ------------ | -------------------------------- | ---------- |
| cloudflare-api-token        | cert-manager | Cloudflare DNS for Let's Encrypt | Manual     |
| argocd-initial-admin-secret | argocd       | ArgoCD admin password            | ArgoCD     |
