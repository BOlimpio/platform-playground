# =============================================================================
# TERRAFORM CONFIGURATION - Production Environment
# =============================================================================

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Remote state in S3 — S3 native locking (no DynamoDB, requires Terraform >= 1.10).
  # Bucket created by platform-bootstrap.
  backend "s3" {
    bucket       = "platform-playground-shared-state"
    key          = "environments/production/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  # For multi-account setup, uncomment and configure:
  # assume_role {
  #   role_arn = "arn:aws:iam::PRODUCTION_ACCOUNT_ID:role/GitHubActionsRole"
  # }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "terraform"
    }
  }
}

provider "archive" {}
