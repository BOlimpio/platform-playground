# =============================================================================
# UNIT TESTS - Lambda Module
# =============================================================================

# -----------------------------------------------------------------------------
# TEST: Basic Lambda function creation
# -----------------------------------------------------------------------------

run "lambda_basic_creation" {
  command = plan

  variables {
    function_name = "test-function"
    description   = "Test Lambda function"
  }

  assert {
    condition     = aws_lambda_function.this.function_name == "test-function"
    error_message = "Function name should match input"
  }

  assert {
    condition     = aws_lambda_function.this.runtime == "python3.12"
    error_message = "Default runtime should be python3.12"
  }

  assert {
    condition     = aws_lambda_function.this.handler == "handler.handler"
    error_message = "Default handler should be handler.handler"
  }

  assert {
    condition     = aws_lambda_function.this.memory_size == 128
    error_message = "Default memory should be 128 MB"
  }

  assert {
    condition     = aws_lambda_function.this.timeout == 30
    error_message = "Default timeout should be 30 seconds"
  }
}

# -----------------------------------------------------------------------------
# TEST: Custom configuration
# -----------------------------------------------------------------------------

run "lambda_custom_config" {
  command = plan

  variables {
    function_name                  = "custom-function"
    memory_size                    = 512
    timeout                        = 120
    reserved_concurrent_executions = 10
    log_retention_days             = 30
    environment_variables = {
      ENV = "production"
      LOG = "debug"
    }
  }

  assert {
    condition     = aws_lambda_function.this.memory_size == 512
    error_message = "Memory should be 512 MB"
  }

  assert {
    condition     = aws_lambda_function.this.timeout == 120
    error_message = "Timeout should be 120 seconds"
  }

  assert {
    condition     = aws_lambda_function.this.reserved_concurrent_executions == 10
    error_message = "Reserved concurrent executions should be 10"
  }

  assert {
    condition     = aws_cloudwatch_log_group.lambda.retention_in_days == 30
    error_message = "Log retention should be 30 days"
  }
}

# -----------------------------------------------------------------------------
# TEST: Dead-letter queue configuration
# -----------------------------------------------------------------------------

run "lambda_with_dlq" {
  command = plan

  variables {
    function_name         = "dlq-function"
    dead_letter_queue_arn = "arn:aws:sqs:us-east-1:123456789012:my-dlq"
  }

  assert {
    condition     = length(aws_lambda_function.this.dead_letter_config) == 1
    error_message = "DLQ config block should be present when ARN is provided"
  }

  assert {
    condition     = aws_lambda_function.this.dead_letter_config[0].target_arn == "arn:aws:sqs:us-east-1:123456789012:my-dlq"
    error_message = "DLQ target ARN should match provided value"
  }
}

# -----------------------------------------------------------------------------
# TEST: No dead-letter queue when not configured
# -----------------------------------------------------------------------------

run "lambda_without_dlq" {
  command = plan

  variables {
    function_name = "no-dlq-function"
  }

  assert {
    condition     = length(aws_lambda_function.this.dead_letter_config) == 0
    error_message = "DLQ config should be absent when no ARN is provided"
  }
}

# -----------------------------------------------------------------------------
# TEST: IAM role naming
# -----------------------------------------------------------------------------

run "lambda_iam_role" {
  command = plan

  variables {
    function_name = "iam-test-function"
  }

  assert {
    condition     = aws_iam_role.lambda.name == "iam-test-function-role"
    error_message = "IAM role name should be function_name + '-role'"
  }
}
