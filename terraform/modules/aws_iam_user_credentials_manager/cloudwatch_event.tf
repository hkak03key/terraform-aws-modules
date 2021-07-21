resource "aws_cloudwatch_event_rule" "aws_iam_event" {
  name        = local.name
  description = "auto configure iam credentials"
  provider = aws.us_east_1
  event_pattern = jsonencode(
    {
      "source" = [
        "aws.iam"
      ],
      "detail-type" = [
        "AWS API Call via CloudTrail"
      ],
      "detail" = {
        "eventSource" : [
          "iam.amazonaws.com"
        ],
        "eventName" = [
          "CreateUser",
          "DeleteLoginProfile",
          "DeleteAccessKey",
          "TagUser",
          "UntagUser",
        ]
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "aws_iam_event" {
  rule      = aws_cloudwatch_event_rule.default.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.default.arn
  provider = aws.us_east_1
}

resource "aws_sns_topic" "default" {
  name = local.name
  provider = aws.us_east_1
}

resource "aws_sns_topic_subscription" "aws_iam" {
  topic_arn = aws_sns_topic.default.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.default.arn
  provider = aws.us_east_1
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.default.arn
  provider = aws.us_east_1
  policy = jsonencode({
    Version = "2008-10-17",
    Statement = [
      {
        Sid = "__default_statement_ID",
        Effect = "Allow",
        Principal = {
          Service = ["events.amazonaws.com"]
        },
        Action = [
          "SNS:Publish",
          "SNS:RemovePermission",
          "SNS:SetTopicAttributes",
          "SNS:DeleteTopic",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes",
          "SNS:Receive",
          "SNS:AddPermission",
          "SNS:Subscribe"
        ],
        Resource = aws_sns_topic.default.arn,
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.self.account_id
          }
        }
      }
    ]
  })
}
