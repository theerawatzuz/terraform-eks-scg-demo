# AWS Load Balancer Controller Module

This Terraform module creates the IAM role and policy required for the AWS Load Balancer Controller, and installs the controller via Helm to manage Application Load Balancers (ALB) and Network Load Balancers (NLB) in an EKS cluster using IRSA (IAM Roles for Service Accounts).

## Purpose

The AWS Load Balancer Controller enables automatic provisioning of AWS Application Load Balancers for Kubernetes Ingress resources. This module creates the necessary IAM permissions and deploys the controller using Helm.

## Features

- Creates IAM role with OIDC trust policy for IRSA
- Implements comprehensive IAM policy for ALB/NLB management
- Installs AWS Load Balancer Controller via Helm chart
- Configures service account with IRSA role annotation
- Validates service account namespace (`kube-system`) and name (`aws-load-balancer-controller`) in trust policy
- Validates OIDC audience is `sts.amazonaws.com`
- Supports TLS passthrough configuration (TLS termination at Kubernetes level)

## Usage

```hcl
module "aws_load_balancer_controller" {
  source = "./modules/aws-lb-controller"

  cluster_name            = "my-eks-cluster"
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn
  vpc_id                  = module.vpc.vpc_id
  chart_version           = "1.7.1"  # Optional, defaults to 1.7.1

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name      | Version        |
| --------- | -------------- |
| terraform | >= 1.5.0       |
| aws       | >= 5.0         |
| helm      | >= 2.12, < 3.0 |

## Providers

| Name | Version        |
| ---- | -------------- |
| aws  | >= 5.0         |
| helm | >= 2.12, < 3.0 |

## Inputs

| Name                    | Description                                            | Type          | Default   | Required |
| ----------------------- | ------------------------------------------------------ | ------------- | --------- | :------: |
| cluster_name            | Name of the EKS cluster                                | `string`      | n/a       |   yes    |
| cluster_oidc_issuer_url | OIDC issuer URL for the EKS cluster (used for IRSA)    | `string`      | n/a       |   yes    |
| oidc_provider_arn       | ARN of the OIDC provider for IRSA                      | `string`      | n/a       |   yes    |
| vpc_id                  | VPC ID where the EKS cluster is deployed               | `string`      | n/a       |   yes    |
| chart_version           | Version of the AWS Load Balancer Controller Helm chart | `string`      | `"1.7.1"` |    no    |
| tags                    | Tags to apply to all resources                         | `map(string)` | `{}`      |    no    |

## Outputs

| Name                      | Description                                                           |
| ------------------------- | --------------------------------------------------------------------- |
| iam_role_arn              | ARN of the IAM role for AWS Load Balancer Controller                  |
| iam_role_name             | Name of the IAM role for AWS Load Balancer Controller                 |
| service_account_name      | Name of the Kubernetes service account (aws-load-balancer-controller) |
| service_account_namespace | Namespace of the Kubernetes service account (kube-system)             |
| helm_release_name         | Name of the Helm release for AWS Load Balancer Controller             |
| helm_release_namespace    | Namespace of the Helm release for AWS Load Balancer Controller        |
| helm_release_status       | Status of the Helm release for AWS Load Balancer Controller           |

## Helm Configuration

The module installs the AWS Load Balancer Controller using the official Helm chart from `https://aws.github.io/eks-charts`. The following values are configured:

- **clusterName**: EKS cluster name
- **serviceAccount.create**: `true` (creates the service account)
- **serviceAccount.name**: `aws-load-balancer-controller`
- **serviceAccount.annotations**: Annotates with IAM role ARN for IRSA
- **vpcId**: VPC ID where the cluster is deployed

## IAM Permissions

The module creates an IAM policy with the following permissions:

- **EC2**: Describe VPC resources, security groups, instances, network interfaces
- **Elastic Load Balancing**: Full lifecycle management of ALB/NLB, target groups, listeners, and rules
- **ACM**: List and describe certificates for HTTPS listeners
- **WAF**: Associate/disassociate Web ACLs with load balancers
- **Shield**: Manage DDoS protection
- **Cognito**: Describe user pool clients for authentication

All permissions follow the principle of least privilege with appropriate resource-level and condition-based restrictions.

## Security Considerations

1. **IRSA Trust Policy**: The IAM role trust policy validates:
   - Service account namespace: `kube-system`
   - Service account name: `aws-load-balancer-controller`
   - OIDC audience: `sts.amazonaws.com`

2. **Resource Tagging**: Load balancers and security groups are tagged with `elbv2.k8s.aws/cluster` to ensure the controller only manages resources it created.

3. **Least Privilege**: Permissions are scoped to specific actions and resources where possible.

## Verification

After deployment, verify the controller is running:

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Next Steps

After deploying the AWS Load Balancer Controller:

1. Create Ingress resources to provision ALBs
2. Configure TLS certificates using cert-manager
3. Set up DNS records pointing to the ALB

## References

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Helm Chart Repository](https://github.com/aws/eks-charts/tree/master/stable/aws-load-balancer-controller)
- [IAM Policy Reference](https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json)
- [IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## Requirements Satisfied

This module satisfies the following requirements from the EKS Terraform Infrastructure specification:

- **Requirement 5.1**: Create IRSA role with permissions to manage Application Load Balancers
- **Requirement 5.2**: Install AWS Load Balancer Controller via Helm chart from https://aws.github.io/eks-charts
- **Requirement 5.3**: Configure the controller with cluster name and VPC ID
- **Requirement 5.4**: Create a Kubernetes service account annotated with the IRSA role ARN
- **Requirement 5.5**: Deploy the controller in kube-system namespace
- **Requirement 12.5**: Validate service account namespace and name in IAM role trust policy
- **Requirement 12.6**: Validate OIDC audience is "sts.amazonaws.com" in IAM role trust policy
