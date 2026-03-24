# Backend Module

This module creates the infrastructure required for Terraform remote state management, including an S3 bucket for state storage and a DynamoDB table for state locking.

## Features

- **S3 Bucket**: Stores Terraform state files with versioning and encryption enabled
- **DynamoDB Table**: Provides state locking mechanism to prevent concurrent modifications
- **Security**: Blocks public access and enables server-side encryption
- **Cost-Optimized**: Uses PAY_PER_REQUEST billing mode for DynamoDB

## Usage

```hcl
module "backend" {
  source = "./modules/backend"

  bucket_name          = "my-terraform-state-bucket"
  dynamodb_table_name  = "my-terraform-state-lock"
  region               = "ap-southeast-1"

  tags = {
    Environment = "prod"
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

| Name                | Description                                       | Type          | Default            | Required |
| ------------------- | ------------------------------------------------- | ------------- | ------------------ | :------: |
| bucket_name         | Name of the S3 bucket for Terraform state storage | `string`      | n/a                |   yes    |
| dynamodb_table_name | Name of the DynamoDB table for state locking      | `string`      | n/a                |   yes    |
| region              | AWS region for backend resources                  | `string`      | `"ap-southeast-1"` |    no    |
| tags                | Common tags to apply to all backend resources     | `map(string)` | `{}`               |    no    |

## Outputs

| Name                | Description                                  |
| ------------------- | -------------------------------------------- |
| s3_bucket_id        | ID of the S3 bucket for Terraform state      |
| s3_bucket_arn       | ARN of the S3 bucket for Terraform state     |
| s3_bucket_region    | Region of the S3 bucket                      |
| dynamodb_table_name | Name of the DynamoDB table for state locking |
| dynamodb_table_arn  | ARN of the DynamoDB table for state locking  |

## Notes

- This module should be deployed **once** before deploying the main EKS infrastructure
- After creating the backend resources, configure the S3 backend in your root module's `backend.tf`
- The S3 bucket name must be globally unique across all AWS accounts
- The DynamoDB table uses `LockID` as the primary key (required by Terraform)
