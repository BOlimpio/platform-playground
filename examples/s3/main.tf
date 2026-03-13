# =============================================================================
# Example: Secure S3 Bucket
# =============================================================================
# This example shows a production-ready S3 bucket configuration.
# Used by the compliance pipeline as the terraform plan target.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "s3_bucket" {
  source = "../../modules/aws/s3"

  bucket_name         = "my-example-secure-bucket"
  enable_versioning   = true
  enable_encryption   = true
  encryption_type     = "AES256"
  block_public_access = true

  lifecycle_rules = [
    {
      id      = "expire-old-versions"
      enabled = true
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]

  tags = {
    Environment = "example"
    Project     = "platform-playground"
    ManagedBy   = "terraform"
  }
}