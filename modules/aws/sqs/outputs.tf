# =============================================================================
# OUTPUTS - SQS Module
# =============================================================================

output "queue_id" {
  description = "URL of the SQS queue (used as its ID)"
  value       = aws_sqs_queue.this.id
}

output "queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.this.arn
}

output "queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.this.url
}

output "queue_name" {
  description = "Name of the SQS queue"
  value       = aws_sqs_queue.this.name
}

output "dlq_arn" {
  description = "ARN of the Dead-Letter Queue (null if DLQ is disabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "URL of the Dead-Letter Queue (null if DLQ is disabled)"
  value       = var.enable_dlq ? aws_sqs_queue.dlq[0].url : null
}
