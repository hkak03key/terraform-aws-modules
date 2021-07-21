locals {
  name = "aws-iam-user-credentials-manager"
}

data "aws_caller_identity" "self" {}
