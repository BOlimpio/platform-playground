# =============================================================================
# VARIABLES - Production Environment
# =============================================================================

# -----------------------------------------------------------------------------
# General Settings
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "terraform-ci-playground"
}

# -----------------------------------------------------------------------------
# VPC & Networking
# -----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.2.0.0/16" # Different CIDR from dev/staging
}

variable "availability_zones" {
  description = "List of availability zones (use 3 for production)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"] # 3 AZs for HA
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------

variable "force_destroy_s3" {
  description = "Allow S3 buckets to be destroyed even if they contain objects. NEVER set true in real production. Only used by apply tests to ensure proper teardown."
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS on static bucket"
  type        = list(string)
  default     = ["https://example.com", "https://www.example.com"]
}

# -----------------------------------------------------------------------------
# SQS Queue
# -----------------------------------------------------------------------------

variable "sqs_visibility_timeout" {
  description = "Visibility timeout for SQS messages in seconds"
  type        = number
  default     = 300 # 5 minutes for production workloads
}

variable "sqs_message_retention" {
  description = "Number of seconds to retain SQS messages"
  type        = number
  default     = 1209600 # 14 days maximum
}

variable "sqs_dlq_max_receive_count" {
  description = "Max times a message is received before going to DLQ"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

variable "lambda_memory_size" {
  description = "Memory in MB for the Lambda function"
  type        = number
  default     = 512 # Higher memory for production throughput
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300 # 5 minutes
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda (-1 = unreserved)"
  type        = number
  default     = 10 # Cap concurrency in production
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log retention in days for Lambda"
  type        = number
  default     = 90
}
