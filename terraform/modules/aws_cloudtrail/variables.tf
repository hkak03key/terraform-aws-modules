
# account name. using as resource name prefix.
variable "account_name" {
  type = string
}

# using as resource name suffix.
variable "resource_suffix" {
  type    = string
  default = null
}

# if true, cloudwatch group will create and cloudtrail logs will be delivered.
variable "enable_cloudwatch_logs" {
  type = bool
}

# s3 bucket names for enabling data event logging.
variable "s3_object_level_logging_buckets" {
  type    = list(string)
  default = []
}

# cloudwatch log retention in days.
# If enable_cloudwatch_logs is false this option is ignored.
variable "cloudwatch_retention_in_days" {
  type    = number # or null
  default = 7
}
