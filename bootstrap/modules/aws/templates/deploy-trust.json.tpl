{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubActionsEnvironment",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "${oidc_subject_prefix}:environment:${environment}"
        }
      }
    }
  ]
}
