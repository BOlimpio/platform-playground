# =============================================================================
# UNIT TESTS - SQS Module
# =============================================================================

# -----------------------------------------------------------------------------
# TEST: Basic SQS queue creation with DLQ
# -----------------------------------------------------------------------------

run "sqs_basic_with_dlq" {
  command = plan

  variables {
    queue_name = "test-queue"
  }

  assert {
    condition     = aws_sqs_queue.this.name == "test-queue"
    error_message = "Queue name should match input"
  }

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled == true
    error_message = "SSE should be enabled by default"
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 1
    error_message = "DLQ should be created by default"
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].name == "test-queue-dlq"
    error_message = "DLQ name should be queue_name + '-dlq'"
  }
}

# -----------------------------------------------------------------------------
# TEST: SQS without DLQ
# -----------------------------------------------------------------------------

run "sqs_without_dlq" {
  command = plan

  variables {
    queue_name = "no-dlq-queue"
    enable_dlq = false
  }

  assert {
    condition     = length(aws_sqs_queue.dlq) == 0
    error_message = "DLQ should not be created when disabled"
  }
}

# -----------------------------------------------------------------------------
# TEST: Custom queue settings
# -----------------------------------------------------------------------------

run "sqs_custom_settings" {
  command = plan

  variables {
    queue_name                 = "custom-queue"
    visibility_timeout_seconds = 60
    message_retention_seconds  = 86400 # 1 day
    delay_seconds              = 5
    receive_wait_time_seconds  = 20
  }

  assert {
    condition     = aws_sqs_queue.this.visibility_timeout_seconds == 60
    error_message = "Visibility timeout should be 60"
  }

  assert {
    condition     = aws_sqs_queue.this.message_retention_seconds == 86400
    error_message = "Message retention should be 86400"
  }

  assert {
    condition     = aws_sqs_queue.this.delay_seconds == 5
    error_message = "Delay should be 5 seconds"
  }

  assert {
    condition     = aws_sqs_queue.this.receive_wait_time_seconds == 20
    error_message = "Long polling wait should be 20 seconds"
  }
}

# -----------------------------------------------------------------------------
# TEST: DLQ SSE is also enabled
# -----------------------------------------------------------------------------

run "sqs_dlq_sse" {
  command = plan

  variables {
    queue_name = "sse-queue"
    enable_dlq = true
  }

  assert {
    condition     = aws_sqs_queue.dlq[0].sqs_managed_sse_enabled == true
    error_message = "DLQ should also have SSE enabled"
  }
}
