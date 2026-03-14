# =============================================================================
# ROOT MODULE - Staging Environment
# =============================================================================
# This is the main entry point for the staging infrastructure.
# It creates all resources in a single state file with proper dependencies.
#
# Components:
# 1. VPC & Networking (subnets, routing)
# 2. S3 Buckets (logs, data, static assets)
# 3. SQS Queue (event queue with DLQ)
# 4. Lambda Function (event processor)
#
# NOTE: This environment uses the SAME modules as dev/prod for consistency.
# =============================================================================

locals {
  name_prefix = "tcip-${var.environment}"

  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Repository  = "terraform-ci-playground"
  }
}

# =============================================================================
# VPC & NETWORKING
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-${var.availability_zones[count.index]}"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-${var.availability_zones[count.index]}"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat-eip"
  })

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway for private subnet internet access
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-rt"
  })
}

# Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate Private Subnets with Private Route Table
resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# =============================================================================
# S3 BUCKETS
# Storage for logs, application data, and static assets
# =============================================================================

# Logs Bucket (for access logging)
module "logs_bucket" {
  source = "../../modules/aws/s3"

  bucket_name       = "${local.name_prefix}-logs"
  enable_versioning = true
  force_destroy     = var.environment != "prod"

  lifecycle_rules = [
    {
      id      = "expire-old-logs"
      enabled = true
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        days = 30
      }
    }
  ]

  tags = merge(local.common_tags, {
    Purpose = "Access Logs"
  })
}

# Data Bucket (with access logging enabled)
module "data_bucket" {
  source = "../../modules/aws/s3"

  bucket_name         = "${local.name_prefix}-data"
  enable_versioning   = true
  enable_encryption   = true
  block_public_access = true
  force_destroy       = var.environment != "prod"

  # Access logging
  enable_access_logging    = true
  logging_target_bucket_id = module.logs_bucket.bucket_id
  logging_target_prefix    = "data-bucket-logs/"

  lifecycle_rules = [
    {
      id      = "transition-to-ia"
      enabled = true
      prefix  = "archive/"
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = merge(local.common_tags, {
    Purpose = "Application Data"
  })
}

# Static Assets Bucket (with CORS for web access)
module "static_bucket" {
  source = "../../modules/aws/s3"

  bucket_name       = "${local.name_prefix}-static"
  enable_versioning = true
  force_destroy     = var.environment != "prod"

  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = var.cors_allowed_origins
      expose_headers  = ["ETag"]
      max_age_seconds = 3600
    }
  ]

  tags = merge(local.common_tags, {
    Purpose = "Static Assets"
  })
}

# =============================================================================
# SQS QUEUE
# Event queue for asynchronous processing
# =============================================================================

module "event_queue" {
  source = "../../modules/aws/sqs"

  queue_name                 = "${local.name_prefix}-events"
  visibility_timeout_seconds = var.sqs_visibility_timeout
  message_retention_seconds  = var.sqs_message_retention
  enable_dlq                 = true
  dlq_max_receive_count      = var.sqs_dlq_max_receive_count

  tags = merge(local.common_tags, {
    Purpose = "Event Processing"
  })
}

# =============================================================================
# LAMBDA FUNCTION
# Event processor
# =============================================================================

module "event_processor" {
  source = "../../modules/aws/lambda"

  function_name         = "${local.name_prefix}-processor"
  description           = "Processes events from the ${var.environment} event queue"
  memory_size           = var.lambda_memory_size
  timeout               = var.lambda_timeout
  dead_letter_queue_arn = module.event_queue.dlq_arn
  enable_dlq_policy     = true
  log_retention_days    = var.lambda_log_retention_days

  environment_variables = {
    ENVIRONMENT = var.environment
    QUEUE_URL   = module.event_queue.queue_url
  }

  tags = merge(local.common_tags, {
    Purpose = "Event Processor"
  })
}
