# ---------------------------------------------------------------------------------------------------------------------
# S3 MODULE TESTS
# 4 plan tests (no AWS resources) + 2 apply tests (real bucket creation).
# ---------------------------------------------------------------------------------------------------------------------

provider "random" {}

run "setup_unique_suffix" {
  command = apply

  module {
    source = "./tests/setup"
  }
}

# =============================================================================
# PLAN TESTS (4) — fast, no real AWS resources created
# =============================================================================

run "plan_default_values" {
  command = plan

  variables {
    bucket_name = "tcip-dev-s3-defaults-${run.setup_unique_suffix.suffix}"
  }

  assert {
    condition     = aws_s3_bucket.this.force_destroy == false
    error_message = "Force destroy should be false by default"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled by default"
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.this) == 1
    error_message = "Encryption should be enabled by default"
  }

  assert {
    condition     = length(aws_s3_bucket_public_access_block.this) == 1
    error_message = "Public access block should be enabled by default"
  }
}

run "plan_versioning_disabled" {
  command = plan

  variables {
    bucket_name       = "tcip-dev-s3-noversion-${run.setup_unique_suffix.suffix}"
    enable_versioning = false
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Suspended"
    error_message = "Versioning should be suspended when disabled"
  }
}

run "plan_encryption_aes256" {
  command = plan

  variables {
    bucket_name     = "tcip-dev-s3-aes256-${run.setup_unique_suffix.suffix}"
    encryption_type = "AES256"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this[0].rule).apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Encryption algorithm should be AES256"
  }
}

run "plan_tags_applied" {
  command = plan

  variables {
    bucket_name = "tcip-dev-s3-tags-${run.setup_unique_suffix.suffix}"
    tags = {
      Environment = "test"
      Project     = "platform-playground"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Environment"] == "test"
    error_message = "Environment tag should be applied"
  }

  assert {
    condition     = aws_s3_bucket.this.tags["Name"] == "tcip-dev-s3-tags-${run.setup_unique_suffix.suffix}"
    error_message = "Name tag should be set to bucket name"
  }
}

# =============================================================================
# APPLY TESTS (2) — create real AWS resources to verify computed attributes
# =============================================================================

run "apply_basic_bucket" {
  command = apply

  variables {
    bucket_name   = "tcip-dev-s3-basic-${run.setup_unique_suffix.suffix}"
    force_destroy = true
    tags = {
      Environment = "integration-test"
    }
  }

  assert {
    condition     = aws_s3_bucket.this.id == "tcip-dev-s3-basic-${run.setup_unique_suffix.suffix}"
    error_message = "Bucket ID should match bucket name"
  }

  assert {
    condition     = can(regex("^arn:aws:s3:::tcip-dev-s3-basic-", aws_s3_bucket.this.arn))
    error_message = "Bucket ARN should be in correct format"
  }

  assert {
    condition     = length(aws_s3_bucket.this.region) > 0
    error_message = "Bucket region should be set"
  }
}

run "apply_full_secure_config" {
  command = apply

  variables {
    bucket_name         = "tcip-dev-s3-secure-${run.setup_unique_suffix.suffix}"
    enable_versioning   = true
    enable_encryption   = true
    encryption_type     = "AES256"
    block_public_access = true
    force_destroy       = true
    tags = {
      Environment = "integration-test"
    }
  }

  assert {
    condition     = length(aws_s3_bucket.this.id) > 0
    error_message = "Bucket should be created"
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning should be enabled"
  }

  assert {
    condition     = length(aws_s3_bucket_server_side_encryption_configuration.this) == 1
    error_message = "Encryption should be configured"
  }

  assert {
    condition     = length(aws_s3_bucket_public_access_block.this) == 1
    error_message = "Public access block should be configured"
  }
}
