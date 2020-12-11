#---------------------------------
# etl
resource "aws_s3_bucket" "etl" {
  bucket = "${local.resource_prefix}-etl"
  acl    = "private"

  lifecycle_rule {
    id                                     = "delete incomplete multipart uploaded objects"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "etl" {
  bucket                  = aws_s3_bucket.etl.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#---------------------------------
# workfiles
resource "aws_s3_bucket" "workfiles" {
  bucket = "${local.resource_prefix}-workfiles"
  acl    = "private"

  lifecycle_rule {
    id                                     = "delete incomplete multipart uploaded objects"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7
  }

  lifecycle_rule {
    id      = "delete 32 days"
    enabled = true
    expiration {
      days = 32
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "workfiles" {
  bucket                  = aws_s3_bucket.workfiles.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

