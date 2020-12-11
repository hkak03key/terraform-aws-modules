{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3BucketOperation",
            "Effect": "Allow",
            "Action": [
                "s3:List*",
                "s3:Get*"
            ],
            "Resource": "arn:aws:s3:::${bucket}"
        },
        {
            "Sid": "S3ObjectOperation",
            "Effect": "Allow",
            "Action": "${access_type == "full" ? "s3:*" : "s3:Get*"}",
            "Resource": "arn:aws:s3:::${bucket}/*"
        }
    ]
}
