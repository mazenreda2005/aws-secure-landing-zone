# Account-wide guardrails that cost nothing and close common gaps.

# Block public S3 access for the whole account, not just one bucket.
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Every new EBS volume in this region is encrypted automatically.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

# Strong password policy for IAM users (CIS AWS Foundations 1.8-1.9).
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  max_password_age               = 90
}

# Threat detection: flags crypto-mining, credential theft, recon, etc.
resource "aws_guardduty_detector" "this" {
  # checkov:skip=CKV2_AWS_3: Single-account landing zone; org-wide GuardDuty needs AWS Organizations.
  count                        = var.enable_guardduty ? 1 : 0
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
