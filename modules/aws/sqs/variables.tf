# =============================================================================
# VARIABLES - SQS Module
# =============================================================================

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for messages in seconds"
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Number of seconds to retain messages (60 to 1209600)"
  type        = number
  default     = 345600 # 4 days
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024 to 262144)"
  type        = number
  default     = 262144 # 256 KB
}

variable "delay_seconds" {
  description = "Delay in seconds before messages become available"
  type        = number
  default     = 0
}

variable "receive_wait_time_seconds" {
  description = "Wait time for long polling in seconds (0 = short polling)"
  type        = number
  default     = 0
}

variable "enable_dlq" {
  description = "Enable a Dead-Letter Queue for failed message processing"
  type        = bool
  default     = true
}

variable "dlq_max_receive_count" {
  description = "Number of times a message can be received before going to DLQ"
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "Number of seconds to retain messages in DLQ"
  type        = number
  default     = 1209600 # 14 days
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
