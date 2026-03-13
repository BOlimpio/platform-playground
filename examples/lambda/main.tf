# =============================================================================
# Example: Lambda Function with SQS Dead-Letter Queue
# =============================================================================
# Demonstrates how to deploy a Lambda event processor that uses an SQS DLQ
# for failed invocations.
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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "archive" {}

module "dlq" {
  source = "../../modules/aws/sqs"

  queue_name = "example-lambda-dlq"
  enable_dlq = false # This IS the DLQ — no nested DLQ needed

  tags = {
    Environment = "example"
    Purpose     = "Lambda Dead-Letter Queue"
  }
}

module "event_processor" {
  source = "../../modules/aws/lambda"

  function_name         = "example-event-processor"
  description           = "Processes incoming events and routes failures to DLQ"
  memory_size           = 256
  timeout               = 60
  dead_letter_queue_arn = module.dlq.queue_arn
  enable_dlq_policy     = true
  log_retention_days    = 14

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  tags = {
    Environment = "example"
    Purpose     = "Event Processor"
  }
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = module.event_processor.function_arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = module.event_processor.function_name
}

output "dlq_arn" {
  description = "ARN of the Dead-Letter Queue"
  value       = module.dlq.queue_arn
}

output "log_group" {
  description = "CloudWatch log group for the Lambda function"
  value       = module.event_processor.log_group_name
}
