# =============================================================================
# APPLY TESTS - PRODUCTION ENVIRONMENT
# =============================================================================
# Integration tests that create real AWS resources and verify them.
# Only runs when run_apply_tests=true in terraform-consumer.yml.
# Resources are automatically destroyed after each test run.
#
# PRODUCTION-SPECIFIC: VPC CIDR 10.2.0.0/16, 3 AZs, 512 MB Lambda, reserved concurrency
#
# Test naming convention:
# - apply_* : Creates real resources (terraform apply)
# =============================================================================

# -----------------------------------------------------------------------------
# APPLY TEST: VPC and Networking Stack (Production - 3 AZs)
# -----------------------------------------------------------------------------

run "apply_vpc_networking" {
  command = apply

  variables {
    environment        = "prod"
    project_name       = "tcip-test"
    vpc_cidr           = "10.2.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    enable_nat_gateway = false # Disable to reduce cost and time
    force_destroy_s3   = true  # Required for teardown: S3 buckets receive access logs during test
  }

  # Verify VPC was created with correct CIDR
  assert {
    condition     = aws_vpc.main.cidr_block == "10.2.0.0/16"
    error_message = "VPC should have CIDR 10.2.0.0/16 for production"
  }

  # Verify subnets were created (3 AZs for production)
  assert {
    condition     = length(aws_subnet.public) == 3
    error_message = "Should have 3 public subnets for production HA"
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "Should have 3 private subnets for production HA"
  }

  # Verify Internet Gateway
  assert {
    condition     = aws_internet_gateway.main.vpc_id == aws_vpc.main.id
    error_message = "Internet Gateway should be attached to VPC"
  }
}

# -----------------------------------------------------------------------------
# APPLY TEST: S3 Buckets (Production naming)
# -----------------------------------------------------------------------------

run "apply_s3_buckets" {
  command = apply

  variables {
    environment        = "prod"
    project_name       = "tcip-test"
    enable_nat_gateway = false
    force_destroy_s3   = true # Required for teardown: S3 buckets receive access logs during test
  }

  # Verify all buckets were created with production naming
  assert {
    condition     = can(regex("^tcip-prod-logs$", module.logs_bucket.bucket_id))
    error_message = "Logs bucket should be created with correct production name"
  }

  assert {
    condition     = can(regex("^tcip-prod-data$", module.data_bucket.bucket_id))
    error_message = "Data bucket should be created with correct production name"
  }

  assert {
    condition     = can(regex("^tcip-prod-static$", module.static_bucket.bucket_id))
    error_message = "Static bucket should be created with correct production name"
  }

  # Verify outputs
  assert {
    condition     = output.logs_bucket_arn != null
    error_message = "Logs bucket ARN should be output"
  }

  assert {
    condition     = output.data_bucket_arn != null
    error_message = "Data bucket ARN should be output"
  }

  assert {
    condition     = output.static_bucket_arn != null
    error_message = "Static bucket ARN should be output"
  }
}

# -----------------------------------------------------------------------------
# APPLY TEST: SQS Queue (Production)
# -----------------------------------------------------------------------------

run "apply_sqs_queue" {
  command = apply

  variables {
    environment        = "prod"
    project_name       = "tcip-test"
    enable_nat_gateway = false
    force_destroy_s3   = true
  }

  # Verify queue was created
  assert {
    condition     = output.event_queue_url != null
    error_message = "Event queue URL should be output"
  }

  assert {
    condition     = output.event_queue_arn != null
    error_message = "Event queue ARN should be output"
  }

  # Verify DLQ was created
  assert {
    condition     = output.event_queue_dlq_arn != null
    error_message = "Dead-letter queue ARN should be output"
  }
}

# -----------------------------------------------------------------------------
# APPLY TEST: Lambda Function (Production)
# -----------------------------------------------------------------------------

run "apply_lambda_function" {
  command = apply

  variables {
    environment                 = "prod"
    project_name                = "tcip-test"
    enable_nat_gateway          = false
    force_destroy_s3            = true
    lambda_reserved_concurrency = 10
  }

  # Verify Lambda function was created
  assert {
    condition     = output.lambda_function_arn != null
    error_message = "Lambda function ARN should be output"
  }

  assert {
    condition     = output.lambda_function_name != null
    error_message = "Lambda function name should be output"
  }

  # Verify IAM role was created
  assert {
    condition     = output.lambda_role_arn != null
    error_message = "Lambda IAM role ARN should be output"
  }
}

# -----------------------------------------------------------------------------
# APPLY TEST: Full Stack
# -----------------------------------------------------------------------------

run "apply_full_stack" {
  command = apply

  variables {
    environment        = "prod"
    project_name       = "tcip-test"
    vpc_cidr           = "10.2.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
    enable_nat_gateway = false
    force_destroy_s3   = true # Required for teardown: S3 buckets receive access logs during test
  }

  # Verify environment summary output
  assert {
    condition     = output.environment_summary.environment == "prod"
    error_message = "Environment should be prod"
  }

  assert {
    condition     = output.environment_summary.sqs_queue != null
    error_message = "SQS queue should be in summary"
  }

  assert {
    condition     = output.environment_summary.lambda_function != null
    error_message = "Lambda function should be in summary"
  }

  # Verify VPC output
  assert {
    condition     = output.vpc_id != null
    error_message = "VPC ID should be output"
  }

  # Verify S3 buckets in summary
  assert {
    condition     = output.environment_summary.s3_buckets.logs != null
    error_message = "Logs bucket should be in summary"
  }
}
