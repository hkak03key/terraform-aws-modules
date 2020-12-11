resource "aws_cloudtrail" "default" {
  name                          = local.resource_prefix
  s3_bucket_name                = aws_s3_bucket.default.bucket
  s3_key_prefix                 = ""
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.default.arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudwatch_role.arn : null

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = formatlist(
        "arn:aws:s3:::%s/",
        var.s3_object_level_logging_buckets
      )
    }
  }
}
