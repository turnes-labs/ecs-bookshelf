{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EcrLogin",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "EcrPull",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "arn:aws:ecr:${region}:${account_id}:repository/${name_prefix}-*"
    },
    {
      "Sid": "Logs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${region}:${account_id}:log-group:/ecs/${name_prefix}:*",
        "arn:aws:logs:${region}:${account_id}:log-group:/ecs/${name_prefix}/*"
      ]
    },
    {
      "Sid": "SecretsNamed",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:${region}:${account_id}:secret:${name_prefix}-*"
    },
    {
      "Sid": "RdsManagedSecretOwn",
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:${region}:${account_id}:secret:rds!*",
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/aws:rds:primaryDBInstanceArn": "arn:aws:rds:${region}:${account_id}:db:${name_prefix}-*"
        }
      }
    },
    {
      "Sid": "EcsExec",
      "Effect": "Allow",
      "Action": [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      "Resource": "*"
    }
  ]
}
