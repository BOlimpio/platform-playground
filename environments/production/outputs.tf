# =============================================================================
# OUTPUTS - Production Environment
# =============================================================================

# -----------------------------------------------------------------------------
# VPC & Networking
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = var.enable_nat_gateway ? aws_eip.nat[0].public_ip : null
}

# -----------------------------------------------------------------------------
# S3 Buckets
# -----------------------------------------------------------------------------

output "logs_bucket_id" {
  description = "ID of the logs bucket"
  value       = module.logs_bucket.bucket_id
}

output "logs_bucket_arn" {
  description = "ARN of the logs bucket"
  value       = module.logs_bucket.bucket_arn
}

output "data_bucket_id" {
  description = "ID of the data bucket"
  value       = module.data_bucket.bucket_id
}

output "data_bucket_arn" {
  description = "ARN of the data bucket"
  value       = module.data_bucket.bucket_arn
}

output "static_bucket_id" {
  description = "ID of the static assets bucket"
  value       = module.static_bucket.bucket_id
}

output "static_bucket_arn" {
  description = "ARN of the static assets bucket"
  value       = module.static_bucket.bucket_arn
}

# -----------------------------------------------------------------------------
# SQS Queue
# -----------------------------------------------------------------------------

output "event_queue_url" {
  description = "URL of the event SQS queue"
  value       = module.event_queue.queue_url
}

output "event_queue_arn" {
  description = "ARN of the event SQS queue"
  value       = module.event_queue.queue_arn
}

output "event_queue_dlq_arn" {
  description = "ARN of the event queue Dead-Letter Queue"
  value       = module.event_queue.dlq_arn
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

output "lambda_function_arn" {
  description = "ARN of the event processor Lambda function"
  value       = module.event_processor.function_arn
}

output "lambda_function_name" {
  description = "Name of the event processor Lambda function"
  value       = module.event_processor.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM execution role"
  value       = module.event_processor.role_arn
}

output "lambda_log_group" {
  description = "CloudWatch log group name for Lambda"
  value       = module.event_processor.log_group_name
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

output "environment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = aws_vpc.main.id
    s3_buckets = {
      logs   = module.logs_bucket.bucket_id
      data   = module.data_bucket.bucket_id
      static = module.static_bucket.bucket_id
    }
    sqs_queue       = module.event_queue.queue_url
    lambda_function = module.event_processor.function_name
  }
}
