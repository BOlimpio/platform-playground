@backup
Feature: Data resources must have backup and recovery configured
  Ensure data persistence and disaster recovery capabilities.

  @s3
  Scenario: S3 buckets should have versioning enabled
    Given I have aws_s3_bucket_versioning defined
    Then it must contain versioning_configuration

  @sqs
  Scenario: SQS queues should have a Dead-Letter Queue configured
    Given I have aws_sqs_queue defined
    When it has redrive_policy
    Then it must contain redrive_policy
