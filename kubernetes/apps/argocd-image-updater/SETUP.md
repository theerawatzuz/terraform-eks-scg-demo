# ArgoCD Image Updater Setup Guide

## 1. สร้าง GitHub Personal Access Token

ไปที่ GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)

สร้าง token ใหม่ด้วย permissions:

- `repo` (Full control of private repositories)

หรือถ้าเป็น Fine-grained tokens:

- Repository access: เลือก repo นี้
- Permissions:
  - Contents: Read and write
  - Metadata: Read-only

## 2. ติดตั้ง Git Credentials

### วิธีที่ 1: ใช้ HTTPS (แนะนำสำหรับเริ่มต้น)

```bash
# สร้าง secret ด้วย GitHub token
kubectl create secret generic git-creds \
  --from-literal=username=git \
  --from-literal=password=YOUR_GITHUB_TOKEN \
  -n argocd

# หรือแก้ไขไฟล์ git-credentials-secret.yaml แล้ว apply
kubectl apply -f kubernetes/apps/argocd-image-updater/git-credentials-secret.yaml
```

### วิธีที่ 2: ใช้ SSH Key (แนะนำสำหรับ production)

```bash
# สร้าง SSH key
ssh-keygen -t ed25519 -C "argocd-image-updater" -f argocd-image-updater-key

# เพิ่ม public key ไปที่ GitHub
# Settings → SSH and GPG keys → New SSH key
cat argocd-image-updater-key.pub

# สร้าง secret ด้วย private key
kubectl create secret generic git-creds \
  --from-file=sshPrivateKey=argocd-image-updater-key \
  -n argocd
```

## 3. อัพเดท IAM Role ARN

หลัง terraform apply แล้ว ให้อัพเดท ServiceAccount:

```bash
# ดู IAM role ARN
terraform output -json | jq -r '.argocd_image_updater_iam_role_arn.value'

# แก้ไข kubernetes/bootstrap/argocd-image-updater.yaml
# เปลี่ยน ACCOUNT_ID และ CLUSTER_NAME เป็นค่าจริง
```

## 4. ตรวจสอบการติดตั้ง

```bash
# ตรวจสอบ pod
kubectl get pods -n argocd -l app=argocd-image-updater

# ดู logs
kubectl logs -n argocd -l app=argocd-image-updater -f

# ตรวจสอบ ServiceAccount annotation
kubectl get sa argocd-image-updater -n argocd -o yaml
```

## 5. ทดสอบด้วย Application ตัวอย่าง

สร้าง ArgoCD Application พร้อม image updater annotations:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-app
  namespace: argocd
  annotations:
    # ระบุ image ที่ต้องการ track
    argocd-image-updater.argoproj.io/image-list: myapp=ACCOUNT_ID.dkr.ecr.ap-southeast-1.amazonaws.com/myapp

    # Update strategy
    argocd-image-updater.argoproj.io/myapp.update-strategy: latest
    # หรือใช้ semver: argocd-image-updater.argoproj.io/myapp.update-strategy: semver:~1.2

    # Write-back method (แนะนำ: git)
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main

    # Pull secret สำหรับ ECR (ไม่จำเป็นถ้าใช้ IRSA)
    # argocd-image-updater.argoproj.io/myapp.pull-secret: pullsecret:default/ecr-secret
spec:
  project: default
  source:
    repoURL: https://github.com/theerawatzuz/terraform-eks-scg-demo.git
    targetRevision: main
    path: kubernetes/apps/test-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## 6. ตรวจสอบการทำงาน

```bash
# ดู logs ของ image updater
kubectl logs -n argocd -l app=argocd-image-updater -f

# ตรวจสอบ application annotations
kubectl get app test-app -n argocd -o yaml | grep -A 10 annotations

# ดู git commits (ถ้าใช้ git write-back)
git log --oneline
```

## Troubleshooting

### ไม่สามารถดึง image จาก ECR

```bash
# ตรวจสอบ IAM role
kubectl describe sa argocd-image-updater -n argocd

# ทดสอบ ECR access
kubectl run test --rm -it --image=amazon/aws-cli --serviceaccount=argocd-image-updater -n argocd -- \
  ecr describe-repositories --region ap-southeast-1
```

### ไม่สามารถ push กลับไปที่ Git

```bash
# ตรวจสอบ git credentials secret
kubectl get secret git-creds -n argocd

# ดู logs
kubectl logs -n argocd -l app=argocd-image-updater | grep -i git
```

### Image ไม่ถูก update

```bash
# ตรวจสอบ annotations
kubectl get app -n argocd <app-name> -o yaml | grep argocd-image-updater

# ดู image updater logs
kubectl logs -n argocd -l app=argocd-image-updater | grep <app-name>
```

## Update Strategies

### Latest Tag

```yaml
argocd-image-updater.argoproj.io/myapp.update-strategy: latest
```

### Semantic Versioning

```yaml
argocd-image-updater.argoproj.io/myapp.update-strategy: semver:~1.2
argocd-image-updater.argoproj.io/myapp.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
```

### Digest-based

```yaml
argocd-image-updater.argoproj.io/myapp.update-strategy: digest
```

## Write-back Methods

### Git (แนะนำ)

```yaml
argocd-image-updater.argoproj.io/write-back-method: git
argocd-image-updater.argoproj.io/git-branch: main
```

### ArgoCD (default)

```yaml
argocd-image-updater.argoproj.io/write-back-method: argocd
```

## Security Best Practices

1. ใช้ SSH key แทน HTTPS token สำหรับ production
2. ใช้ Fine-grained tokens แทน Classic tokens
3. จำกัด permissions ของ token ให้น้อยที่สุด
4. Rotate credentials เป็นประจำ
5. ใช้ External Secrets Operator เพื่อจัดการ secrets
