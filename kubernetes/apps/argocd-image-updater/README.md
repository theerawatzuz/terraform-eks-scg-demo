# ArgoCD Image Updater

ArgoCD Image Updater เป็น tool ที่ช่วยอัพเดท image tags ของ applications ใน ArgoCD โดยอัตโนมัติ

## การใช้งาน

เพิ่ม annotations ใน ArgoCD Application:

```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: myapp=myregistry/myapp
    argocd-image-updater.argoproj.io/myapp.update-strategy: latest
```

## Update Strategies

- `latest`: ใช้ tag ล่าสุด
- `semver`: ใช้ semantic versioning (เช่น `~1.2`, `^1.2.3`)
- `digest`: ใช้ image digest

## ตัวอย่าง

### Latest Tag

```yaml
argocd-image-updater.argoproj.io/image-list: nginx=nginx
argocd-image-updater.argoproj.io/nginx.update-strategy: latest
```

### Semantic Versioning

```yaml
argocd-image-updater.argoproj.io/image-list: myapp=myregistry/myapp
argocd-image-updater.argoproj.io/myapp.update-strategy: semver:~1.2
argocd-image-updater.argoproj.io/myapp.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
```

### Private Registry

```yaml
argocd-image-updater.argoproj.io/image-list: myapp=myregistry.io/myapp
argocd-image-updater.argoproj.io/myapp.pull-secret: pullsecret:default/mysecret
```

## Write-back Methods

### Git (แนะนำ)

```yaml
argocd-image-updater.argoproj.io/write-back-method: git
argocd-image-updater.argoproj.io/git-branch: main
```

### ArgoCD (default)

อัพเดทโดยตรงใน ArgoCD parameters

## การตรวจสอบ

```bash
# ดู logs
kubectl logs -n argocd -l app=argocd-image-updater -f

# ดู annotations ของ application
kubectl get app -n argocd <app-name> -o yaml | grep argocd-image-updater
```
