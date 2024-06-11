################################################################################
# S3 Artifacts Bucket
################################################################################

resource "aws_kms_key" "bucket_encryption_key" {
  description             = var.kms_key_name
  deletion_window_in_days = 10
  enable_key_rotation     = true
}
resource "aws_s3_bucket" "bucket" {
  #checkov:skip=CKV_AWS_18:Access log is not needed in not needed in in pipeline artifacts bucket
  #checkov:skip=CKV_AWS_144: S3 bucket has cross-region replication is not needed in in pipeline artifacts bucket
  #checkov:skip=CKV_AWS_21: Versioning not needed in pipeline artifacts bucket
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket     = aws_s3_bucket.bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.ownership_controls]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_encryption_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}