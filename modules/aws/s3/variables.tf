# --------------------------------------------------------------------------------------------------------------------------------
# General variables
# --------------------------------------------------------------------------------------------------------------------------------
# variable "aws_region" {
#   description = "AWS region where the EKS cluster will be deployed."
#   type        = string
#   default     = "us-east-1"
# }

# variable "environment" {
#   description = "Deployment environment (e.g., dev, staging, prod)."
#   type        = string
#   default     = "dev"
# }

# variable "project_name" {
#   description = "Name of the project for tagging purposes."
#   type        = string
#   default     = "terraform-ci-playground"
# }

# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the S3 bucket. Must be globally unique and follow S3 naming rules."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be between 3-63 characters, start/end with lowercase letter or number, and contain only lowercase letters, numbers, hyphens, and periods."
  }

  validation {
    condition     = !can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+$", var.bucket_name))
    error_message = "Bucket name cannot be formatted as an IP address."
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ---------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

# Versioning
variable "enable_versioning" {
  description = "Enable versioning on the bucket. Recommended for data protection and recovery."
  type        = bool
  default     = true
}

# Encryption
variable "enable_encryption" {
  description = "Enable server-side encryption on the bucket."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Type of server-side encryption. Valid values: AES256 (SSE-S3) or aws:kms (SSE-KMS)."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_type)
    error_message = "Encryption type must be either 'AES256' or 'aws:kms'."
  }
}

variable "kms_key_id" {
  description = "ARN of the KMS key to use for encryption. Required if encryption_type is 'aws:kms'."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws:kms:", var.kms_key_id))
    error_message = "KMS key ID must be a valid ARN starting with 'arn:aws:kms:'."
  }
}

variable "bucket_key_enabled" {
  description = "Enable S3 Bucket Key for KMS encryption to reduce KMS costs."
  type        = bool
  default     = true
}

# Public Access
variable "block_public_access" {
  description = "Block all public access to the bucket. Highly recommended for security."
  type        = bool
  default     = true
}

# Access Logging
variable "enable_access_logging" {
  description = "Enable access logging for the bucket. Required for audit compliance."
  type        = bool
  default     = false
}

variable "logging_target_bucket_id" {
  description = "ID of the target bucket for access logs. Required if enable_access_logging is true."
  type        = string
  default     = null
}

variable "logging_target_prefix" {
  description = "Prefix for access log objects in the target bucket."
  type        = string
  default     = "logs/"
}

# Lifecycle
variable "force_destroy" {
  description = "Allow the bucket to be destroyed even if it contains objects. Use with caution."
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket. See README for structure."
  type        = any
  default     = []
}

# CORS
variable "cors_rules" {
  description = "List of CORS rules for the bucket. See README for structure."
  type        = any
  default     = []
}

# Object Lock
variable "enable_object_lock" {
  description = "Enable object lock on the bucket. Requires versioning and cannot be disabled once enabled."
  type        = bool
  default     = false
}

variable "object_lock_mode" {
  description = "Object lock retention mode. Valid values: GOVERNANCE or COMPLIANCE."
  type        = string
  default     = "GOVERNANCE"

  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.object_lock_mode)
    error_message = "Object lock mode must be either 'GOVERNANCE' or 'COMPLIANCE'."
  }
}

variable "object_lock_days" {
  description = "Number of days for object lock retention."
  type        = number
  default     = 30

  validation {
    condition     = var.object_lock_days > 0
    error_message = "Object lock days must be greater than 0."
  }
}
