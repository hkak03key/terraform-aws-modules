resource "aws_cloudwatch_log_group" "default" {
  name              = local.resource_prefix
  retention_in_days = var.cloudwatch_retention_in_days
}
