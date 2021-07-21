#=================================
# iam policy
#=================================
data "aws_iam_policy" "aws_managed_policies" {
  for_each = toset([
    "service-role/AWSLambdaBasicExecutionRole",
  ])
  arn = "arn:aws:iam::aws:policy/${each.value}"
}

#=================================
# lambda role
#=================================
#---------------------------------
# iam role
resource "aws_iam_role" "lambda_role" {
  name = "${local.name}-lambda-role"

  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Principal = {
            Service = "lambda.amazonaws.com"
          }
          Effect = "Allow"
          Sid    = ""
        }
      ]
    }
  )
}

#---------------------------------
# iam policy attachment
resource "aws_iam_role_policy_attachment" "lambda_role" {
  for_each = {
    for p in [
      data.aws_iam_policy.aws_managed_policies["service-role/AWSLambdaBasicExecutionRole"],
    ] :
    p.name => p.arn
  }
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}

#---------------------------------
# iam role policy
resource "aws_iam_role_policy" "lambda_role_collect_user_info_policy" {
  name = "${aws_iam_role.lambda_role.name}-collect-user-info-policy"
  role = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "IamActions",
        Effect = "Allow",
        Action = [
          "iam:GetUser",
          "iam:*LoginProfile",
          "iam:*AccessKey*",
          "iam:ListUserTags",
          "iam:TagUser",
          "iam:UntagUser",
        ],
        Resource = "arn:aws:iam::356321864013:user/*"
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_role_send_email_policy" {
  name = "${aws_iam_role.lambda_role.name}-send-email-policy"
  role = aws_iam_role.lambda_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "SesActions",
        Effect = "Allow",
        Action = "ses:Send*Email",
        # Resource = aws_ses_email_identity.default.arn,
        Resource = "*",
      },
      {
        Sid = "StsActions",
        Effect = "Allow",
        Action = "sts:GetCallerIdentity",
        Resource = "*",
      },
    ]
  })
}

