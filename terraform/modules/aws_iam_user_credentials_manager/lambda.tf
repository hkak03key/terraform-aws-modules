#---------------------------------
# archive_file
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  excludes    = [
    "__pycache__",
    ".*",
    "test.py",
    "mytest.py"
  ]
  output_path = "${path.module}/.zip/lambda.zip"
}

#---------------------------------
# lambda
resource "aws_lambda_function" "default" {
  function_name    = local.name
  filename         = data.archive_file.lambda.output_path
  handler          = "aws_iam_user_credentials_manager.lambda_handler"
  runtime          = "python3.8"
  timeout          = 60
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path)
  environment {
    variables = {
      SEND_MAIL_ADDRESS = var.email_address
    }
  }
}

resource "aws_lambda_permission" "default" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.default.arn
}
