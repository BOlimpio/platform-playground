# ---------------------------------------------------------------------------------------------------------------------
# S3 BUCKET
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  # Object lock must be enabled at bucket creation (use top-level argument, not deprecated block)
  object_lock_enabled = var.enable_object_lock

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# VERSIONING
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# SERVER-SIDE ENCRYPTION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.enable_encryption ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = [
      {
        sse_algorithm      = var.encryption_type
        kms_master_key_id  = var.encryption_type == "aws:kms" ? var.kms_key_id : null
        bucket_key_enabled = var.encryption_type == "aws:kms" ? var.bucket_key_enabled : null
      }
    ]

    content {
      apply_server_side_encryption_by_default {
        sse_algorithm     = rule.value.sse_algorithm
        kms_master_key_id = rule.value.kms_master_key_id
      }
      bucket_key_enabled = rule.value.bucket_key_enabled
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# PUBLIC ACCESS BLOCK
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_public_access_block" "this" {
  count = var.block_public_access ? 1 : 0

  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------------------------------------------------
# ACCESS LOGGING
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_logging" "this" {
  count = var.enable_access_logging ? 1 : 0

  bucket = aws_s3_bucket.this.id

  target_bucket = var.logging_target_bucket_id
  target_prefix = var.logging_target_prefix
}

# ---------------------------------------------------------------------------------------------------------------------
# LIFECYCLE RULES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filter (AWS provider requires exactly one of: filter OR prefix)
      dynamic "filter" {
        # Always create a filter block:
        # - If prefix is provided, set it
        # - If not, create an empty filter {} (applies to all objects)
        for_each = [1]

        content {
          prefix = lookup(rule.value, "prefix", null)
        }
      }

      # Transitions
      dynamic "transition" {
        for_each = lookup(rule.value, "transition", [])

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration", null) != null ? [rule.value.expiration] : []

        content {
          days = expiration.value.days
        }
      }

      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_version_expiration", null) != null ? [rule.value.noncurrent_version_expiration] : []

        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_version_transition", [])

        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Abort incomplete multipart upload
      dynamic "abort_incomplete_multipart_upload" {
        for_each = lookup(rule.value, "abort_incomplete_multipart_upload_days", null) != null ? [1] : []

        content {
          days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
        }
      }
    }
  }

  # Must have versioning enabled/suspended first
  depends_on = [aws_s3_bucket_versioning.this]
}

# ---------------------------------------------------------------------------------------------------------------------
# CORS CONFIGURATION
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_cors_configuration" "this" {
  count = length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "cors_rule" {
    for_each = var.cors_rules

    content {
      allowed_headers = lookup(cors_rule.value, "allowed_headers", null)
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# OBJECT LOCK CONFIGURATION (Default Retention)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_s3_bucket_object_lock_configuration" "this" {
  count = var.enable_object_lock ? 1 : 0

  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = [
      {
        mode = var.object_lock_mode
        days = var.object_lock_days
      }
    ]

    content {
      default_retention {
        mode = rule.value.mode
        days = rule.value.days
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}
