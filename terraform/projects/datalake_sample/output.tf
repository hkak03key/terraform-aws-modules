output "s3_read_bucket_iam_policies" {
  value = {
    for b in [
      aws_s3_bucket.default,
    ] :
    trimprefix(trimprefix(b.bucket, local.resource_prefix), "-") => aws_iam_policy.s3_read_bucket_iam_policies[b.bucket]
  }
}

output "s3_buckets" {
  value = {
    for b in [
      aws_s3_bucket.default,
    ] :
    trimprefix(trimprefix(b.bucket, local.resource_prefix), "-") => b
  }
}
