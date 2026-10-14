{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsPullRequest",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": ${jsonencode(oidc_subjects)}
        }
      }
    }
  ]
}
