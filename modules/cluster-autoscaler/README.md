# Cluster Autoscaler Module

This module deploys the Kubernetes Cluster Autoscaler on Amazon EKS using Helm. The Cluster Autoscaler automatically adjusts the number of nodes in your cluster when pods fail to schedule or when nodes are underutilized.

## Features

- Automatic node scaling based on pod resource requests
- IRSA (IAM Roles for Service Accounts) for secure AWS API access
- Auto-discovery of node groups
- Configurable scale-down behavior
- Balance similar node groups for even distribution

## How It Works

1. **Scale Up**: When pods cannot be scheduled due to insufficient resources, Cluster Autoscaler adds nodes
2. **Scale Down**: When nodes are underutilized (< 50% by default) for 10 minutes, they are removed
3. **Auto-Discovery**: Automatically discovers node groups tagged with the cluster name

## Configuration

### Scale Down Settings

- `scale-down-delay-after-add`: Wait 10 minutes after adding a node before considering scale down
- `scale-down-unneeded-time`: Node must be unneeded for 10 minutes before removal
- `scale-down-utilization-threshold`: Remove nodes below 50% utilization

### Node Group Requirements

Your EKS node group must have:

- `min_size`: Minimum number of nodes (e.g., 1)
- `max_size`: Maximum number of nodes (e.g., 8)
- `desired_size`: Initial number of nodes (e.g., 3)

## Usage

```hcl
module "cluster_autoscaler" {
  source = "./modules/cluster-autoscaler"

  cluster_name            = "my-eks-cluster"
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn       = module.eks.oidc_provider_arn

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Inputs

| Name                    | Description                                  | Type        | Default       | Required |
| ----------------------- | -------------------------------------------- | ----------- | ------------- | -------- |
| cluster_name            | Name of the EKS cluster                      | string      | -             | yes      |
| cluster_oidc_issuer_url | OIDC issuer URL of the EKS cluster           | string      | -             | yes      |
| oidc_provider_arn       | ARN of the OIDC provider                     | string      | -             | yes      |
| namespace               | Kubernetes namespace for Cluster Autoscaler  | string      | "kube-system" | no       |
| chart_version           | Version of the Cluster Autoscaler Helm chart | string      | "9.37.0"      | no       |
| tags                    | Tags to apply to AWS resources               | map(string) | {}            | no       |

## Outputs

| Name                 | Description                                    |
| -------------------- | ---------------------------------------------- |
| iam_role_arn         | ARN of the IAM role for Cluster Autoscaler     |
| service_account_name | Name of the Kubernetes service account         |
| namespace            | Namespace where Cluster Autoscaler is deployed |

## Monitoring

Check Cluster Autoscaler logs:

```bash
kubectl logs -f deployment/cluster-autoscaler -n kube-system
```

Check scaling events:

```bash
kubectl get events -n kube-system --sort-by='.lastTimestamp' | grep cluster-autoscaler
```

## IAM Permissions

The module creates an IAM role with permissions to:

- Describe Auto Scaling groups and instances
- Set desired capacity of Auto Scaling groups
- Terminate instances in Auto Scaling groups
- Describe EC2 instance types and launch templates
- Describe EKS node groups

## Best Practices

1. Set appropriate `min_size` to ensure minimum availability
2. Set `max_size` based on budget and maximum expected load
3. Use `balance-similar-node-groups` for even distribution across AZs
4. Monitor costs as autoscaling can increase expenses
5. Set pod resource requests accurately for proper scaling decisions

## Cost Optimization

- Nodes scale down after 10 minutes of being underutilized
- Utilization threshold set to 50% to balance cost and availability
- Use Spot instances for non-critical workloads to reduce costs further

## Troubleshooting

### Pods not scheduling

- Check if max_size limit is reached
- Verify pod resource requests are reasonable
- Check Cluster Autoscaler logs for errors

### Nodes not scaling down

- Ensure pods have PodDisruptionBudgets configured
- Check if system pods are blocking scale down
- Verify utilization is below threshold

### Permission errors

- Verify IRSA role is correctly configured
- Check IAM policy has required permissions
- Ensure OIDC provider is properly set up
