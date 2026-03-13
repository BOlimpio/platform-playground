# AWS S3 Bucket Module

Terraform module for creating secure S3 buckets with encryption, versioning, and access controls.

## Features

- ✅ Server-side encryption (SSE-S3 or SSE-KMS)
- ✅ Bucket versioning
- ✅ Public access block
- ✅ Access logging (optional)
- ✅ Lifecycle rules (optional)
- ✅ CORS configuration (optional)
- ✅ Object lock (optional)
- ✅ Input validation

## Usage

### Basic Example

```hcl
module "s3" {
  source = "../../modules/aws/s3"

  bucket_name = "my-secure-bucket"
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### With Access Logging

```hcl
module "logs_bucket" {
  source = "../../modules/aws/s3"

  bucket_name       = "my-logs-bucket"
  enable_versioning = true
  
  tags = {
    Environment = "production"
  }
}

module "data_bucket" {
  source = "../../modules/aws/s3"

  bucket_name              = "my-data-bucket"
  enable_access_logging    = true
  logging_target_bucket_id = module.logs_bucket.bucket_id
  logging_target_prefix    = "access-logs/"
  
  tags = {
    Environment = "production"
  }
}
```

### With KMS Encryption

```hcl
module "s3" {
  source = "../../modules/aws/s3"

  bucket_name     = "my-kms-encrypted-bucket"
  encryption_type = "aws:kms"
  kms_key_id      = aws_kms_key.example.arn
  
  tags = {
    Environment = "production"
  }
}
```

### With Lifecycle Rules

```hcl
module "s3" {
  source = "../../modules/aws/s3"

  bucket_name = "my-bucket-with-lifecycle"
  
  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      prefix  = "logs/"
      
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      
      expiration = {
        days = 365
      }
      
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]
  
  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket. Must be globally unique. | `string` | n/a | yes |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |
| enable_versioning | Enable versioning on the bucket | `bool` | `true` | no |
| enable_encryption | Enable server-side encryption | `bool` | `true` | no |
| encryption_type | Type of encryption: AES256 or aws:kms | `string` | `"AES256"` | no |
| kms_key_id | KMS key ARN for encryption (required if encryption_type is aws:kms) | `string` | `null` | no |
| bucket_key_enabled | Enable S3 Bucket Key for KMS | `bool` | `true` | no |
| block_public_access | Block all public access | `bool` | `true` | no |
| enable_access_logging | Enable access logging | `bool` | `false` | no |
| logging_target_bucket_id | Target bucket for access logs | `string` | `null` | no |
| logging_target_prefix | Prefix for access log objects | `string` | `"logs/"` | no |
| force_destroy | Allow bucket to be destroyed with objects inside | `bool` | `false` | no |
| lifecycle_rules | Lifecycle rules configuration | `list(any)` | `[]` | no |
| cors_rules | CORS rules configuration | `list(any)` | `[]` | no |
| enable_object_lock | Enable object lock (requires versioning) | `bool` | `false` | no |
| object_lock_mode | Object lock retention mode | `string` | `"GOVERNANCE"` | no |
| object_lock_days | Object lock retention days | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The bucket domain name |
| bucket_regional_domain_name | The bucket regional domain name |

## Security Considerations

1. **Encryption**: All buckets have encryption enabled by default (AES256)
2. **Public Access**: All public access is blocked by default
3. **Versioning**: Enabled by default for data protection
4. **Access Logging**: Should be enabled for audit requirements
5. **Object Lock**: Enable for WORM (Write Once Read Many) compliance

## Testing

```bash
# Run native Terraform tests
terraform test

# Run compliance tests
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
terraform-compliance -f ../../compliance/features -p tfplan.json
```
