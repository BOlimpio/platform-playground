@tagging
Feature: All AWS resources must be tagged appropriately
  Tags are required for cost allocation, ownership tracking, and compliance.

  @s3
  Scenario: S3 buckets must have required tags
    Given I have aws_s3_bucket defined
    Then it must contain tags

  @sqs
  Scenario: SQS queues must have required tags
    Given I have aws_sqs_queue defined
    Then it must contain tags

  @lambda
  Scenario: Lambda functions must have required tags
    Given I have aws_lambda_function defined
    Then it must contain tags
