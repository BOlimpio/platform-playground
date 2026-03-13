# =============================================================================
# PLAN TESTS - PRODUCTION ENVIRONMENT
# =============================================================================
# Fast validation without creating resources.
# Runs automatically on every push/PR via terraform-ci.yml.
#
# PRODUCTION-SPECIFIC: VPC CIDR 10.2.0.0/16, 3 AZs, 512 MB Lambda, reserved concurrency
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
    environment = "prod"
    vpc_cidr    = "10.2.0.0/16"
  }

  # Verify VPC is created with correct CIDR (production uses 10.2.0.0/16)
  assert {
    condition     = aws_vpc.main.cidr_block == "10.2.0.0/16"
    error_message = "VPC CIDR should be 10.2.0.0/16 for production"
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
# PLAN TEST: Subnet Configuration (Production uses 3 AZs)
# -----------------------------------------------------------------------------

run "plan_subnet_configuration" {
  command = plan

  variables {
    environment        = "prod"
    availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  }

  # Verify public subnets are created (production uses 3 AZs for HA)
  assert {
    condition     = length(aws_subnet.public) == 3
    error_message = "Should create 3 public subnets for production HA"
  }

  # Verify private subnets are created
  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "Should create 3 private subnets for production HA"
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
    environment        = "prod"
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
    environment        = "prod"
    enable_nat_gateway = false
  }

  # Verify NAT Gateway is NOT created
  assert {
    condition     = length(aws_nat_gateway.main) == 0
    error_message = "NAT Gateway should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: S3 Buckets Configuration (Production settings)
# -----------------------------------------------------------------------------

run "plan_s3_buckets" {
  command = plan

  variables {
    environment = "prod"
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
# PLAN TEST: S3 Production Safety Settings
# -----------------------------------------------------------------------------

run "plan_s3_production_safety" {
  command = plan

  variables {
    environment = "prod"
  }

  # Production S3 buckets should NOT have force_destroy enabled by default
  assert {
    condition     = module.logs_bucket.force_destroy == false
    error_message = "Production logs bucket should have force_destroy=false"
  }

  assert {
    condition     = module.data_bucket.force_destroy == false
    error_message = "Production data bucket should have force_destroy=false"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: SQS Queue Configuration (Production)
# -----------------------------------------------------------------------------

run "plan_sqs_queue" {
  command = plan

  variables {
    environment            = "prod"
    sqs_visibility_timeout = 300
    sqs_message_retention  = 1209600
  }

  # Verify the main queue is planned with production settings
  assert {
    condition     = module.event_queue.queue_name != ""
    error_message = "SQS event queue should be planned"
  }
}

# -----------------------------------------------------------------------------
# PLAN TEST: Lambda Function Configuration (Production)
# -----------------------------------------------------------------------------

run "plan_lambda_function" {
  command = plan

  variables {
    environment                 = "prod"
    lambda_memory_size          = 512
    lambda_timeout              = 300
    lambda_reserved_concurrency = 10
  }

  # Verify Lambda function is planned with production config
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
    environment  = "prod"
    project_name = "test-project"
  }

  # Verify VPC has correct tags
  assert {
    condition     = aws_vpc.main.tags["Environment"] == "prod"
    error_message = "VPC should have Environment tag set to prod"
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
