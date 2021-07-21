variable "email_address" {
  type    = string
}

/*
it needs to put us_east_1 provider on root as follow:
# provider "aws" {
#   region = "us-east-1"
#   alias  = "us_east_1"
# }

and call this module with providers args as follow:
# providers = {
#   aws = aws
#   aws.us_east_1 = aws.us_east_1
# }
*/
