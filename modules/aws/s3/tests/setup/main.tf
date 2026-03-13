# ---------------------------------------------------------------------------------------------------------------------
# TEST SETUP MODULE
# Generates unique identifiers for test resources to ensure global uniqueness
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

# Generate a random suffix for bucket names (S3 bucket names must be globally unique)
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

output "suffix" {
  description = "Random suffix for test resource naming"
  value       = random_string.suffix.result
}
