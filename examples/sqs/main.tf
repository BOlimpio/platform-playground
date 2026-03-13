# =============================================================================
# Example: SQS Queue with Dead-Letter Queue
# =============================================================================
# Demonstrates how to deploy an SQS queue with DLQ for reliable message
# processing. Unprocessable messages (after maxReceiveCount retries) are
# automatically routed to the DLQ for inspection and reprocessing.
#
# Usage:
#   terraform init
#   terraform plan
#   terraform apply
# =============================================================================

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "work_queue" {
  source = "../../modules/aws/sqs"

  queue_name                 = "example-work-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days
  enable_dlq                 = true
  dlq_max_receive_count      = 5 # Retry up to 5 times before DLQ

  tags = {
    Environment = "example"
    Purpose     = "Background Job Queue"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "queue_url" {
  description = "URL of the SQS queue"
  value       = module.work_queue.queue_url
}

output "queue_arn" {
  description = "ARN of the SQS queue"
  value       = module.work_queue.queue_arn
}

output "dlq_arn" {
  description = "ARN of the Dead-Letter Queue"
  value       = module.work_queue.dlq_arn
}
