@network-security
Feature: Network resources must follow security best practices
  Ensure network configurations don't expose resources unnecessarily.

  @s3
  Scenario: S3 buckets must block public access
    Given I have aws_s3_bucket_public_access_block defined
    Then it must contain block_public_acls
    And its value must be true
    And it must contain block_public_policy
    And its value must be true
    And it must contain ignore_public_acls
    And its value must be true
    And it must contain restrict_public_buckets
    And its value must be true
