# ---------------------------------------------------------------------------------------------------------------------
# BUCKET OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "bucket_name" {
  description = "The bucket name."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_id" {
  description = "The ID of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "bucket_region" {
  description = "The AWS region this bucket resides in."
  value       = aws_s3_bucket.this.region
}

# ---------------------------------------------------------------------------------------------------------------------
# ENCRYPTION OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "encryption_enabled" {
  description = "Whether server-side encryption is enabled."
  value       = var.enable_encryption
}

output "encryption_type" {
  description = "The type of server-side encryption used."
  value       = var.enable_encryption ? var.encryption_type : null
}

# ---------------------------------------------------------------------------------------------------------------------
# VERSIONING OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "versioning_enabled" {
  description = "Whether versioning is enabled on the bucket."
  value       = var.enable_versioning
}

# ---------------------------------------------------------------------------------------------------------------------
# PUBLIC ACCESS OUTPUTS
# ---------------------------------------------------------------------------------------------------------------------

output "public_access_blocked" {
  description = "Whether public access is blocked on the bucket."
  value       = var.block_public_access
}

output "force_destroy" {
  description = "Whether the bucket can be destroyed even if it contains objects."
  value       = var.force_destroy
}
