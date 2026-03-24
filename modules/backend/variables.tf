# Backend Module Variables

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, and hyphens, and must start and end with a letter or number"
  }
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string

  validation {
    condition     = length(var.dynamodb_table_name) >= 3 && length(var.dynamodb_table_name) <= 255
    error_message = "DynamoDB table name must be between 3 and 255 characters"
  }
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Common tags to apply to all backend resources"
  type        = map(string)
  default     = {}
}
