# =============================================================================
# VARIABLES - Lambda Module
# =============================================================================

variable "function_name" {
  description = "Unique name for the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Lambda runtime identifier"
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Function entrypoint in your code (file.function)"
  type        = string
  default     = "handler.handler"
}

variable "memory_size" {
  description = "Amount of memory in MB for the Lambda function"
  type        = number
  default     = 128
}

variable "timeout" {
  description = "Maximum execution time in seconds"
  type        = number
  default     = 30
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions (-1 = unreserved)"
  type        = number
  default     = -1
}

variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "dead_letter_queue_arn" {
  description = "ARN of the SQS queue (or SNS topic) for failed invocations"
  type        = string
  default     = null
}

variable "enable_dlq_policy" {
  description = "Create an IAM policy granting sqs:SendMessage on the DLQ. Set to true when dead_letter_queue_arn is an SQS queue computed from another resource (its ARN is known only after apply, so count cannot use it directly)."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
