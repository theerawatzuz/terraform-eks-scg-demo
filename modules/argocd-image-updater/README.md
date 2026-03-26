# ArgoCD Image Updater IAM Module

Module นี้สร้าง IAM role และ policy สำหรับ ArgoCD Image Updater เพื่อให้สามารถดึง image จาก Amazon ECR ได้

## Permissions

IAM role นี้มี permissions ดังนี้:

### ECR Authorization

- `ecr:GetAuthorizationToken` - ดึง token สำหรับ authenticate กับ ECR

### ECR Repository Access

- `ecr:BatchCheckLayerAvailability` - ตรวจสอบ image layers
- `ecr:GetDownloadUrlForLayer` - ดึง URL สำหรับ download layers
- `ecr:BatchGetImage` - ดึง image metadata
- `ecr:DescribeImages` - ดูรายละเอียด images
- `ecr:ListImages` - list images ใน repository
- `ecr:DescribeRepositories` - ดูรายละเอียด repositories

## Usage

```hcl
module "argocd_image_updater" {
  source = "./modules/argocd-image-updater"

  cluster_name            = module.eks.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn

  tags = local.common_tags
}
```

## ServiceAccount Annotation

หลังจากสร้าง IAM role แล้ว ต้อง annotate ServiceAccount:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-image-updater
  namespace: argocd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/CLUSTER_NAME-argocd-image-updater
```

## Outputs

- `iam_role_arn` - ARN ของ IAM role
- `iam_role_name` - ชื่อของ IAM role
