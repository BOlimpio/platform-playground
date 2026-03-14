# =============================================================================
# TFLint Configuration
# =============================================================================
# Documentation: https://github.com/terraform-linters/tflint
#
# This configuration enables:
# - AWS-specific rules and best practices
# - Naming conventions
# - Deprecated syntax detection
# =============================================================================

config {
  # Enable all available modules
  call_module_type = "all"
  
  # Continue checking even if there are errors
  force = false
  
  # Disable checking of module sources from registry
  disabled_by_default = false
}

# -----------------------------------------------------------------------------
# AWS Plugin - Provider-specific rules
# -----------------------------------------------------------------------------
plugin "aws" {
  enabled = true
  version = "0.44.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
  
  # Enable deep checking (validates resource arguments against AWS API)
  deep_check = false  # Set to true if you have AWS credentials
}

# -----------------------------------------------------------------------------
# Terraform Plugin - Core rules
# -----------------------------------------------------------------------------
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# -----------------------------------------------------------------------------
# Custom Rules
# -----------------------------------------------------------------------------

# Naming conventions
rule "terraform_naming_convention" {
  enabled = true
  
  # Use snake_case for all names
  variable {
    format = "snake_case"
  }
  
  locals {
    format = "snake_case"
  }
  
  output {
    format = "snake_case"
  }
  
  resource {
    format = "snake_case"
  }
  
  data {
    format = "snake_case"
  }
  
  module {
    format = "snake_case"
  }
}

# Require descriptions for variables and outputs
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

# Type constraints for variables
rule "terraform_typed_variables" {
  enabled = true
}

# Standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Require version constraints for providers
rule "terraform_required_providers" {
  enabled = true
}

# Require Terraform version constraint
rule "terraform_required_version" {
  enabled = true
}

# Deprecated syntax checks
rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

# Empty blocks
rule "terraform_empty_list_equality" {
  enabled = true
}

# Comment formatting
rule "terraform_comment_syntax" {
  enabled = true
}

# Module sources
rule "terraform_module_pinned_source" {
  enabled = true
  # Allow local modules (no version pin needed)
  style = "flexible"
}

# Workspace usage
rule "terraform_workspace_remote" {
  enabled = true
}

# -----------------------------------------------------------------------------
# AWS-Specific Rules
# -----------------------------------------------------------------------------

# Ensure instance types are valid
rule "aws_instance_invalid_type" {
  enabled = true
}

# Ensure AMI IDs are valid format
rule "aws_instance_invalid_ami" {
  enabled = true
}

# IAM policy validation
rule "aws_iam_policy_document_gov_friendly_arns" {
  enabled = true
}

# Elasticache node type validation
rule "aws_elasticache_cluster_invalid_type" {
  enabled = true
}

# RDS instance class validation
rule "aws_db_instance_invalid_type" {
  enabled = true
}
