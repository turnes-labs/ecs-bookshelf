{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StateLock",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${state_bucket}/infra/*.tflock"
    },
    {
      "Sid": "DenyBootstrapState",
      "Effect": "Deny",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${state_bucket}/bootstrap/*"
    }
  ]
}
