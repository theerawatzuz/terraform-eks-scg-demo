# cert-manager Configuration

## Cloudflare API Token Secret

**IMPORTANT:** The Cloudflare API token secret is NOT stored in Git for security reasons.

### Creating the Secret

```bash
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="YOUR_CLOUDFLARE_API_TOKEN" \
  -n cert-manager
```

### Verifying

```bash
kubectl get secret cloudflare-api-token -n cert-manager
```

## Files

- `clusterissuer.yaml` - Let's Encrypt ClusterIssuer with Cloudflare DNS-01 solver
- `README.md` - This file

## Note

The secret must be created manually before applying the ClusterIssuer.
