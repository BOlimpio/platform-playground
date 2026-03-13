# =============================================================================
# LAMBDA FUNCTION MODULE
# =============================================================================
# Creates a Lambda function with:
# - Inline Python handler (no external artifact required)
# - IAM execution role with basic CloudWatch Logs permissions
# - CloudWatch log group with configurable retention
# - Optional dead-letter queue for failed invocations
# =============================================================================

# Package the inline handler into a ZIP for Lambda deployment
data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.root}/lambda_payload.zip"

  source {
    content  = <<-PYTHON
      import json

      def handler(event, context):
          print("Event received:", json.dumps(event))
          return {
              "statusCode": 200,
              "body": json.dumps({"message": "OK", "function": context.function_name})
          }
    PYTHON
    filename = "handler.py"
  }
}

# IAM role assumed by the Lambda function
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Basic execution policy: CloudWatch Logs (write) + X-Ray (trace)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# When a DLQ is configured, Lambda needs permission to send failed invocations to it
resource "aws_iam_role_policy" "lambda_dlq" {
  count = var.enable_dlq_policy ? 1 : 0
  name  = "${var.function_name}-dlq-send"
  role  = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = var.dead_letter_queue_arn
      }
    ]
  })
}

# Pre-create the log group to control retention (Lambda auto-creates it otherwise)
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = var.runtime
  handler = var.handler
  role    = aws_iam_role.lambda.arn

  memory_size = var.memory_size
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrent_executions

  tracing_config {
    mode = "Active"
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_queue_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_queue_arn
    }
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy.lambda_dlq,
    aws_cloudwatch_log_group.lambda,
  ]
}
