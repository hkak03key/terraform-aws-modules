resource "aws_s3_bucket" "default" {
  bucket = local.resource_prefix
  acl    = "log-delivery-write"

  lifecycle_rule {
    id                                     = "delete incomplete multipart uploaded objects"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 7
  }

  lifecycle {
    prevent_destroy = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  policy = jsonencode(
    {
      Statement = [
        {
          Action = "s3:GetBucketAcl"
          Effect = "Allow"
          Principal : {
            Service : "cloudtrail.amazonaws.com"
          }
          Resource : "arn:aws:s3:::${local.resource_prefix}"
        },
        {
          Action = "s3:PutObject"
          Effect = "Allow"
          Principal : {
            Service : "cloudtrail.amazonaws.com"
          }
          Resource : "arn:aws:s3:::${local.resource_prefix}/AWSLogs/${data.aws_caller_identity.self.account_id}/*"
          Condition : {
            StringEquals : {
              "s3:x-amz-acl" : "bucket-owner-full-control"
            }
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
}

