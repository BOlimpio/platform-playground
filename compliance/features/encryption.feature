@encryption
Feature: AWS Resources must have encryption enabled
  All data at rest must be encrypted to meet security requirements.

  @s3
  Scenario: S3 buckets must have encryption enabled
    Given I have aws_s3_bucket_server_side_encryption_configuration defined
    Then it must contain rule
    And it must contain apply_server_side_encryption_by_default

  @sqs
  Scenario: SQS queues must have server-side encryption enabled
    Given I have aws_sqs_queue defined
    Then it must contain sqs_managed_sse_enabled
    And its value must be true
