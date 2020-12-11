locals {
  resource_prefix = "${var.account_name}-cloudtrail${var.resource_suffix != null ? "-${var.resource_suffix}" : ""}"
}

data "aws_caller_identity" "self" {}

data "aws_region" "current" {}
