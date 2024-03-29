{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream20141101",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream"
      ],
      "Resource": [
        "arn:aws:logs:${region}:${account_id}:log-group:${log_group_name}:log-stream:${account_id}_CloudTrail_${region}*"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents20141101",
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${region}:${account_id}:log-group:${log_group_name}:log-stream:${account_id}_CloudTrail_${region}*"
      ]
    }
  ]
}
