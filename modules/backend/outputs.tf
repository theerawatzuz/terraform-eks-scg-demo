# Backend Module Outputs

output "s3_bucket_id" {
  description = "ID of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.region
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_lock.arn
}
