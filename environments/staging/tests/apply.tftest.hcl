# =============================================================================
# APPLY TESTS - STAGING ENVIRONMENT
# =============================================================================
# Integration tests that create real AWS resources and verify them.
# Only runs when run_apply_tests=true in terraform-consumer.yml.
# Resources are automatically destroyed after each test run.
#
# STAGING-SPECIFIC: VPC CIDR 10.1.0.0/16, 2 AZs, 256 MB Lambda
#
# Test naming convention:
# - apply_* : Creates real resources (terraform apply)
# =============================================================================

# -----------------------------------------------------------------------------
# APPLY TEST: VPC and Networking Stack
# -----------------------------------------------------------------------------

run "apply_vpc_networking" {
  command = apply

  variables {
    environment        = "staging"
    project_name       = "tcip-test"
    vpc_cidr           = "10.1.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
    enable_nat_gateway = false # Disable to reduce cost and time
  }

  # Verify VPC was created with correct CIDR
  assert {
    condition     = aws_vpc.main.cidr_block == "10.1.0.0/16"
    error_message = "VPC should have CIDR 10.1.0.0/16 for staging"
  }

  # Verify subnets were created
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should have 2 public subnets"
  }

  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should have 2 private subnets"
  }

  # Verify Internet Gateway
  assert {
    condition     = aws_internet_gateway.main.vpc_id == aws_vpc.main.id
    error_message = "Internet Gateway should be attached to VPC"
  }
}

# -----------------------------------------------------------------------------
# APPLY TEST: S3 Buckets
# -----------------------------------------------------------------------------

run "apply_s3_buckets" {
  command = apply

  variables {
    environment        = "staging"
    project_name       = "tcip-test"
    enable_nat_gateway = false
  }

  # Verify all buckets were created
  assert {
    condition     = can(regex("^tcip-staging-logs$", module.logs_bucket.bucket_id))
    error_message = "Logs bucket should be created with correct name"
  }

  assert {
    condition     = can(regex("^tcip-staging-data$", module.data_bucket.bucket_id))
    error_message = "Data bucket should be created with correct name"
  }

  assert {
    condition     = can(regex("^tcip-staging-static$", module.static_bucket.bucket_id))
    error_message = "Static bucket should be created with correct name"
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
# APPLY TEST: SQS Queue
# -----------------------------------------------------------------------------

run "apply_sqs_queue" {
  command = apply

  variables {
    environment        = "staging"
    project_name       = "tcip-test"
    enable_nat_gateway = false
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
# APPLY TEST: Lambda Function
# -----------------------------------------------------------------------------

run "apply_lambda_function" {
  command = apply

  variables {
    environment        = "staging"
    project_name       = "tcip-test"
    enable_nat_gateway = false
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
    environment        = "staging"
    project_name       = "tcip-test"
    vpc_cidr           = "10.1.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
    enable_nat_gateway = false
  }

  # Verify environment summary output
  assert {
    condition     = output.environment_summary.environment == "staging"
    error_message = "Environment should be staging"
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
