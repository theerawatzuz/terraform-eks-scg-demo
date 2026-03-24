# VPC Module

This module creates a complete VPC infrastructure for Amazon EKS, including public and private subnets across multiple availability zones, NAT Gateway for private subnet internet access, and proper routing configuration.

## Features

- VPC with configurable CIDR block (default: 10.0.0.0/16)
- DNS hostnames and DNS support enabled
- Automatic subnet CIDR calculation:
  - Public subnets: 10.0.0.0-10.0.9.255 range
  - Private subnets: 10.0.10.0-10.0.19.255 range
- Internet Gateway for public subnet internet access
- NAT Gateway for private subnet internet access (single NAT for cost optimization)
- Proper route tables and associations
- EKS-required tags for subnet discovery and load balancer integration

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = "my-eks-cluster"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true  # Cost optimization

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
    Project     = "EKS-Infrastructure"
  }
}
```

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.5.0 |
| aws       | ~> 5.0   |

## Inputs

| Name                 | Description                                                          | Type           | Default         | Required |
| -------------------- | -------------------------------------------------------------------- | -------------- | --------------- | :------: |
| cluster_name         | Name of the EKS cluster (used for resource naming and tagging)       | `string`       | n/a             |   yes    |
| vpc_cidr             | CIDR block for the VPC                                               | `string`       | `"10.0.0.0/16"` |    no    |
| availability_zones   | List of availability zones for subnet distribution                   | `list(string)` | n/a             |   yes    |
| enable_dns_hostnames | Enable DNS hostnames in the VPC                                      | `bool`         | `true`          |    no    |
| enable_dns_support   | Enable DNS support in the VPC                                        | `bool`         | `true`          |    no    |
| enable_nat_gateway   | Enable NAT Gateway for private subnet internet access                | `bool`         | `true`          |    no    |
| single_nat_gateway   | Use a single NAT Gateway for all private subnets (cost optimization) | `bool`         | `true`          |    no    |
| tags                 | Common tags to apply to all VPC resources                            | `map(string)`  | `{}`            |    no    |

## Outputs

| Name                    | Description                     |
| ----------------------- | ------------------------------- |
| vpc_id                  | ID of the VPC                   |
| vpc_cidr                | CIDR block of the VPC           |
| public_subnet_ids       | List of public subnet IDs       |
| private_subnet_ids      | List of private subnet IDs      |
| nat_gateway_ids         | List of NAT Gateway IDs         |
| internet_gateway_id     | ID of the Internet Gateway      |
| public_route_table_id   | ID of the public route table    |
| private_route_table_ids | List of private route table IDs |

## Architecture

The module creates the following resources:

1. **VPC**: Main network container with DNS support enabled
2. **Public Subnets**: Subnets with direct internet access via Internet Gateway
3. **Private Subnets**: Subnets with internet access via NAT Gateway
4. **Internet Gateway**: Provides internet access for public subnets
5. **NAT Gateway**: Provides internet access for private subnets (single NAT for cost optimization)
6. **Route Tables**: Separate route tables for public and private subnets
7. **EKS Tags**: Proper tags for EKS cluster integration and load balancer discovery

## Subnet CIDR Calculation

The module automatically calculates subnet CIDRs based on the VPC CIDR:

- **Public subnets**: Uses the first 10 /24 blocks (10.0.0.0/24, 10.0.1.0/24, ...)
- **Private subnets**: Uses the next 10 /24 blocks (10.0.10.0/24, 10.0.11.0/24, ...)

This ensures no CIDR overlap and follows the requirements specification.

## Cost Optimization

By default, the module uses a **single NAT Gateway** in the first public subnet to minimize costs. This NAT Gateway serves all private subnets across all availability zones.

For production environments requiring high availability, you can set `single_nat_gateway = false` to create one NAT Gateway per availability zone (higher cost).

## EKS Integration

The module applies the following tags required by EKS:

- **All subnets**: `kubernetes.io/cluster/${cluster_name} = owned`
- **Public subnets**: `kubernetes.io/role/elb = 1` (for external load balancers)
- **Private subnets**: `kubernetes.io/role/internal-elb = 1` (for internal load balancers)

These tags enable EKS to automatically discover subnets for load balancer provisioning.

## Examples

### Development Environment (Cost-Optimized)

```hcl
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = "dev-eks"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  single_nat_gateway = true  # Single NAT for cost savings

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Production Environment (High Availability)

```hcl
module "vpc" {
  source = "./modules/vpc"

  cluster_name       = "prod-eks"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  single_nat_gateway = false  # NAT per AZ for high availability

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

## Notes

- The module requires at least 2 availability zones for high availability
- DNS hostnames and DNS support are enabled by default for EKS requirements
- All resources are tagged with the cluster name for easy identification
- The module follows AWS best practices for VPC design
