#=================================
# iam policy
#=================================
resource "aws_iam_policy" "s3_full_bucket_iam_policies" {
  for_each = toset([
    aws_s3_bucket.etl.bucket,
    aws_s3_bucket.workfiles.bucket,
  ])

  name        = "s3-full-${replace(each.value, "*", "@")}"
  path        = "/"
  description = "s3 full access to ${replace(each.value, "*", "@")}${replace(each.value, "*", "") != each.value ? ". @=asterisk" : ""}"
  policy = templatefile(
    "${path.module}/../../templates/s3_access_to_bucket_iam_policy.json.tpl",
    {
      access_type = "full"
      bucket      = each.value
    }
  )
}

resource "aws_iam_policy" "s3_read_bucket_iam_policies" {
  for_each = toset([
    aws_s3_bucket.etl.bucket,
    aws_s3_bucket.workfiles.bucket,
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
# databricks role
#=================================
#---------------------------------
# iam role
resource "aws_iam_role" "databricks_role" {
  name               = "${local.resource_prefix}-databricks-role"
  description        = "databricks cluster role for ${local.name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

#---------------------------------
# iam instance profile
resource "aws_iam_instance_profile" "databricks_role" {
  name = aws_iam_role.databricks_role.name
  path = "/"
  role = aws_iam_role.databricks_role.name
}

#---------------------------------
# iam policy attachment
resource "aws_iam_role_policy_attachment" "databricks_role" {
  for_each = {
    for p in flatten([
      aws_iam_policy.s3_full_bucket_iam_policies[aws_s3_bucket.etl.bucket],
      aws_iam_policy.s3_full_bucket_iam_policies[aws_s3_bucket.workfiles.bucket],
      # tf 0.12.21: lookupで書こうとするとエラーになる
      contains(keys(var.external_policies), "databricks_role") ? var.external_policies["databricks_role"] : []
    ]) :
    p.name => p.arn
  }
  role       = aws_iam_role.databricks_role.name
  policy_arn = each.value
}

#=================================
# redash user
#=================================
#---------------------------------
# iam role
# notice: secretは手動作成
resource "aws_iam_user" "redash_user" {
  name = "${local.resource_prefix}-redash-user"
}

#---------------------------------
# iam policy attachment
resource "aws_iam_user_policy_attachment" "redash_user" {
  for_each = {
    for p in flatten([
      aws_iam_policy.s3_read_bucket_iam_policies[aws_s3_bucket.etl.bucket],
      # tf 0.12.21: lookupで書こうとするとエラーになる
      contains(keys(var.external_policies), "redash_user") ? var.external_policies["redash_user"] : []
    ]) :
    p.name => p.arn
  }
  user       = aws_iam_user.redash_user.name
  policy_arn = each.value
}

