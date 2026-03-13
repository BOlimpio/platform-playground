# =============================================================================
# SQS QUEUE MODULE
# =============================================================================
# Creates an SQS queue with:
# - SSE encryption using SQS-managed keys (no KMS required)
# - Optional Dead-Letter Queue (DLQ) for unprocessable messages
# - Configurable visibility timeout, retention, and polling
# =============================================================================

# Dead-Letter Queue (receives messages that exceed maxReceiveCount)
resource "aws_sqs_queue" "dlq" {
  count = var.enable_dlq ? 1 : 0

  name = "${var.queue_name}-dlq"

  message_retention_seconds = var.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = true

  tags = var.tags
}

# Main queue
resource "aws_sqs_queue" "this" {
  name = var.queue_name

  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  sqs_managed_sse_enabled = true

  redrive_policy = var.enable_dlq ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
    maxReceiveCount     = var.dlq_max_receive_count
  }) : null

  tags = var.tags
}
