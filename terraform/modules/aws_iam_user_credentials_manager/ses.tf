resource "aws_ses_email_identity" "default" {
  email = var.email_address
}
