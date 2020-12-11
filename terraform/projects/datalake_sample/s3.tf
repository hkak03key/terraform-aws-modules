#---------------------------------
# etl
resource "aws_s3_bucket" "default" {
  bucket = local.resource_prefix
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

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.default.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
