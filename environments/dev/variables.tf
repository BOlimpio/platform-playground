# =============================================================================
# VARIABLES - Development Environment
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
  default     = "dev"

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
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------

variable "cors_allowed_origins" {
  description = "Allowed origins for CORS on static bucket"
  type        = list(string)
  default     = ["https://*.example.com"]
}

# -----------------------------------------------------------------------------
# SQS Queue
# -----------------------------------------------------------------------------

variable "sqs_visibility_timeout" {
  description = "Visibility timeout for SQS messages in seconds"
  type        = number
  default     = 30
}

variable "sqs_message_retention" {
  description = "Number of seconds to retain SQS messages"
  type        = number
  default     = 345600 # 4 days
}

variable "sqs_dlq_max_receive_count" {
  description = "Max times a message is received before going to DLQ"
  type        = number
  default     = 3
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

variable "lambda_memory_size" {
  description = "Memory in MB for the Lambda function"
  type        = number
  default     = 128
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_log_retention_days" {
  description = "CloudWatch log retention in days for Lambda"
  type        = number
  default     = 14
}
