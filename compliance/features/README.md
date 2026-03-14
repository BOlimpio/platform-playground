# Terraform Compliance Features

This directory contains Gherkin feature files for [terraform-compliance](https://terraform-compliance.com/).

## Overview

terraform-compliance is a lightweight, security and compliance focused test framework against Terraform plans.

## Features

| Feature | Description |
|---------|-------------|
| `encryption.feature` | Ensures all data at rest is encrypted |
| `tagging.feature` | Validates required tags are present |
| `network_security.feature` | Validates network security settings |
| `backup.feature` | Ensures backup and versioning are configured |

## Running Compliance Tests

```bash
# Generate a Terraform plan
cd examples/modules/s3
terraform init
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json

# Run compliance tests
terraform-compliance -f ../../../compliance/features -p tfplan.json
```

## Writing New Features

1. Create a new `.feature` file in this directory
2. Use Gherkin syntax (Given/When/Then)
3. Tag scenarios for organization (@encryption, @network, etc.)
4. Reference Terraform resource types and attributes

### Example Feature

```gherkin
@security
Feature: Security Groups must have descriptions
  All security group rules should be documented.

  Scenario: Security group rules have descriptions
    Given I have aws_security_group_rule defined
    Then it must contain description
```

## Resources

- [terraform-compliance Documentation](https://terraform-compliance.com/)
- [Gherkin Syntax](https://cucumber.io/docs/gherkin/reference/)
- [terraform-compliance Steps](https://terraform-compliance.com/pages/bdd-references/)
