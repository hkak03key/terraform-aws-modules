#=================================
# iam policy
#=================================
resource "aws_iam_policy" "s3_read_bucket_iam_policies" {
  for_each = toset([
    aws_s3_bucket.default.bucket,
  ])

  name        = "s3-read-${replace(each.value, "*", "@")}"
  path        = "/"
  description = "s3 read access to ${replace(each.value, "*", "@")}${replace(each.value, "*", "") != each.value ? ". @=asterisk" : ""}"
  policy = templatefile(
    "${path.module}/../../templates/s3_access_to_bucket_iam_policy.json.tpl",
    {
      access_type = "read"
      bucket      = each.value
    }
  )
}

#=================================
# cloudwatch role
#=================================
#---------------------------------
# iam role
resource "aws_iam_role" "cloudwatch_role" {
  name               = "${local.resource_prefix}-cloudwatch-role"
  description        = "cloudwatch role for ${local.resource_prefix}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role_policy.json
}

data "aws_iam_policy_document" "cloudtrail_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_role" {
  name = "${aws_iam_role.cloudwatch_role.name}-cloudwatch-policy"
  role = aws_iam_role.cloudwatch_role.name

  policy = templatefile(
    "${path.module}/templates/cloudwatch_log_iam_policy.json.tpl",
    {
      account_id     = data.aws_caller_identity.self.account_id
      region         = data.aws_region.current.name
      log_group_name = aws_cloudwatch_log_group.default.name
    }
  )
}

