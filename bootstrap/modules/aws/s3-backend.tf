locals {
  regional_bucket_name = format("${var.bucket_name}-%s-%s-an", local.account_id, local.region)
}

resource "aws_s3_bucket" "this" {
  # A sandbox state bucket: versioning already covers recovery, and every
  # reader and writer is a known role
  #checkov:skip=CKV_AWS_18:Access logs would need a second bucket; CloudTrail already records who touched the state
  #checkov:skip=CKV_AWS_144:Cross-region replication doubles cost; versioning covers accidental changes and deletes
  #checkov:skip=CKV2_AWS_62:Nothing consumes bucket events
  bucket = local.regional_bucket_name

  bucket_namespace = "account-regional"

  force_destroy = false

  lifecycle {
    prevent_destroy = true # Protects state from accidental deletion
  }
}

# Enabled bucket versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Control costs over time
resource "aws_s3_bucket_lifecycle_configuration" "state_lifecycle" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "tier_and_clean_old_state_versions"
    status = "Enabled"

    # Transition backups to cheaper storage after N days
    noncurrent_version_transition {
      noncurrent_days = var.backup_transition_days
      storage_class   = "STANDARD_IA"
    }

    # Permanently delete after N days
    noncurrent_version_expiration {
      noncurrent_days = var.backup_expiration_days
    }

    # Clean up parts of uploads that never completed
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# SSE-KMS with the AWS-managed key (alias: aws/s3)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      # Omitting kms_master_key_id uses the AWS-managed aws/s3 key
      kms_master_key_id = var.kms_master_key_id
    }

    # Enable bucket key to reduce KMS API costs
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Reject any request that doesn't use TLS
data "aws_iam_policy_document" "state_bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.state_bucket.json

  # Apply after the public access block, or S3 can reject the policy while
  # the block is still being set
  depends_on = [aws_s3_bucket_public_access_block.this]
}
