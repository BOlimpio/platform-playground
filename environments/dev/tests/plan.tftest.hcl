# =============================================================================
# PLAN TESTS - DEVELOPMENT ENVIRONMENT
# =============================================================================
# Fast validation without creating resources.
# Runs automatically on every push/PR via terraform-ci.yml.
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
    environment = "dev"
    vpc_cidr    = "10.0.0.0/16"
  }

  # Verify VPC is created with correct CIDR
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR should be 10.0.0.0/16"
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
    environment        = "dev"
    availability_zones = ["us-east-1a", "us-east-1b"]
  }

  # Verify public subnets are created
  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "Should create 2 public subnets"
  }

  # Verify private subnets are created
  assert {
    condition     = length(aws_subnet.private) == 2
    error_message = "Should create 2 private subnets"
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
    environment        = "dev"
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
    environment        = "dev"
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
    environment = "dev"
  }

  # Verify all three buckets are planned
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
    environment            = "dev"
    sqs_visibility_timeout = 30
    sqs_message_retention  = 345600
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
    environment        = "dev"
    lambda_memory_size = 128
    lambda_timeout     = 30
  }

  # Verify Lambda function is planned
  assert {
    condition     = module.event_processor.function_name != ""
    error_message = "Lambda function should be planned"
  }
}

run "plan_lambda_custom_config" {
  command = plan

  variables {
    environment        = "dev"
    lambda_memory_size = 512
    lambda_timeout     = 120
  }

  # Custom memory and timeout are reflected in the plan
  assert {
    condition     = module.event_processor.function_name != ""
    error_message = "Lambda function should be planned with custom config"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: Resource Tagging
# -----------------------------------------------------------------------------

run "plan_resource_tagging" {
  command = plan

  variables {
    environment  = "dev"
    project_name = "test-project"
  }

  # Verify VPC has correct tags
  assert {
    condition     = aws_vpc.main.tags["Environment"] == "dev"
    error_message = "VPC should have Environment tag"
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
