# =============================================================================
# PLAN TESTS - STAGING ENVIRONMENT
# =============================================================================
# Fast validation without creating resources.
# Runs automatically on every push/PR via terraform-ci.yml.
#
# STAGING-SPECIFIC: VPC CIDR 10.1.0.0/16, 2 AZs, 256 MB Lambda
#
# Test naming convention:
# - plan_*  : Validation only (terraform plan)
# =============================================================================

# -----------------------------------------------------------------------------
# PLAN TEST: VPC Configuration
# -----------------------------------------------------------------------------

run "plan_vpc_configuration" {
  command = plan

  variables {
    environment = "staging"
    vpc_cidr    = "10.1.0.0/16"
  }

  # Verify VPC is created with correct CIDR (staging uses 10.1.0.0/16)
  assert {
    condition     = aws_vpc.main.cidr_block == "10.1.0.0/16"
    error_message = "VPC CIDR should be 10.1.0.0/16 for staging"
  }

  # Verify DNS settings
  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "VPC should have DNS hostnames enabled"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_support == true
    error_message = "VPC should have DNS support enabled"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: Subnet Configuration
# -----------------------------------------------------------------------------

run "plan_subnet_configuration" {
  command = plan

  variables {
    environment        = "staging"
    availability_zones = ["us-east-1a", "us-east-1b"]
  }

  # Verify public subnets are created (staging uses 2 AZs)
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets for staging"
  }

  # Verify private subnets are created
  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets for staging"
  }

  # Verify public subnets have public IP mapping
  assert {
    condition     = aws_subnet.public[0].map_public_ip_on_launch == true
    error_message = "Public subnets should map public IP on launch"
  }

  # Verify private subnets do NOT have public IP mapping
  assert {
    condition     = aws_subnet.private[0].map_public_ip_on_launch == false
    error_message = "Private subnets should not map public IP on launch"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: NAT Gateway Configuration
# -----------------------------------------------------------------------------

run "plan_nat_gateway_enabled" {
  command = plan

  variables {
    environment        = "staging"
    enable_nat_gateway = true
  }

  # Verify NAT Gateway is created
  assert {
    condition     = length(aws_nat_gateway.main) == 1
    error_message = "NAT Gateway should be created when enabled"
  }

  # Verify EIP is created
  assert {
    condition     = length(aws_eip.nat) == 1
    error_message = "EIP should be created for NAT Gateway"
  }
}

run "plan_nat_gateway_disabled" {
  command = plan

  variables {
    environment        = "staging"
    enable_nat_gateway = false
  }

  # Verify NAT Gateway is NOT created
  assert {
    condition     = length(aws_nat_gateway.main) == 0
    error_message = "NAT Gateway should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: S3 Buckets Configuration
# -----------------------------------------------------------------------------

run "plan_s3_buckets" {
  command = plan

  variables {
    environment = "staging"
  }

  # Verify all three buckets are planned (bucket_name is known at plan time)
  assert {
    condition     = module.logs_bucket.bucket_name != ""
    error_message = "Logs bucket should be planned"
  }

  assert {
    condition     = module.data_bucket.bucket_name != ""
    error_message = "Data bucket should be planned"
  }

  assert {
    condition     = module.static_bucket.bucket_name != ""
    error_message = "Static bucket should be planned"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: SQS Queue Configuration
# -----------------------------------------------------------------------------

run "plan_sqs_queue" {
  command = plan

  variables {
    environment            = "staging"
    sqs_visibility_timeout = 60
    sqs_message_retention  = 604800
  }

  # Verify the main queue is planned
  assert {
    condition     = module.event_queue.queue_name != ""
    error_message = "SQS event queue should be planned"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: Lambda Function Configuration
# -----------------------------------------------------------------------------

run "plan_lambda_function" {
  command = plan

  variables {
    environment        = "staging"
    lambda_memory_size = 256
    lambda_timeout     = 60
  }

  # Verify Lambda function is planned with staging config
  assert {
    condition     = module.event_processor.function_name != ""
    error_message = "Lambda function should be planned"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: Resource Tagging
# -----------------------------------------------------------------------------

run "plan_resource_tagging" {
  command = plan

  variables {
    environment  = "staging"
    project_name = "test-project"
  }

  # Verify VPC has correct tags
  assert {
    condition     = aws_vpc.main.tags["Environment"] == "staging"
    error_message = "VPC should have Environment tag set to staging"
  }

  assert {
    condition     = aws_vpc.main.tags["Project"] == "test-project"
    error_message = "VPC should have Project tag"
  }

  assert {
    condition     = aws_vpc.main.tags["ManagedBy"] == "terraform"
    error_message = "VPC should have ManagedBy tag"
  }
}
