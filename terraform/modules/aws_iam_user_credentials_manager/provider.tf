provider "archive" {}

provider "aws" {}

provider "aws" {
  alias  = "us_east_1"
}
