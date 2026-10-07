{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DataRead",
      "Effect": "Allow",
      "Action": [
        "rds:Describe*",
        "rds:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "StateList",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${state_bucket}",
      "Condition": {
        "StringLike": {
          "s3:prefix": "infra/${environment}/*"
        }
      }
    },
    {
      "Sid": "StateReadWrite",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${state_bucket}/infra/${environment}/*"
    },
    {
      "Sid": "RdsNamed",
      "Effect": "Allow",
      "Action": "rds:*",
      "Resource": [
        "arn:aws:rds:${region}:${account_id}:db:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:cluster:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:subgrp:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:pg:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:cluster-pg:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:og:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:snapshot:${name_prefix}-*",
        "arn:aws:rds:${region}:${account_id}:cluster-snapshot:${name_prefix}-*"
      ]
    },
    {
      "Sid": "RdsDefaultGroups",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBInstance",
        "rds:ModifyDBInstance",
        "rds:CreateDBCluster",
        "rds:ModifyDBCluster"
      ],
      "Resource": [
        "arn:aws:rds:${region}:${account_id}:pg:default.*",
        "arn:aws:rds:${region}:${account_id}:cluster-pg:default.*",
        "arn:aws:rds:${region}:${account_id}:og:default:*"
      ]
    },
    {
      "Sid": "RdsProxyCreateTagged",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBProxy",
        "rds:AddTagsToResource"
      ],
      "Resource": "arn:aws:rds:${region}:${account_id}:db-proxy:*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "RdsProxyManageOwn",
      "Effect": "Allow",
      "Action": "rds:*",
      "Resource": [
        "arn:aws:rds:${region}:${account_id}:db-proxy:*",
        "arn:aws:rds:${region}:${account_id}:db-proxy-endpoint:*",
        "arn:aws:rds:${region}:${account_id}:target-group:*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "SecretsNamed",
      "Effect": "Allow",
      "Action": "secretsmanager:*",
      "Resource": "arn:aws:secretsmanager:${region}:${account_id}:secret:${name_prefix}-*"
    },
    {
      "Sid": "RdsManagedSecretCreate",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:TagResource"
      ],
      "Resource": "arn:aws:secretsmanager:${region}:${account_id}:secret:rds!*"
    },
    {
      "Sid": "RdsManagedSecretOwn",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:RotateSecret"
      ],
      "Resource": "arn:aws:secretsmanager:${region}:${account_id}:secret:rds!*",
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/aws:rds:primaryDBInstanceArn": "arn:aws:rds:${region}:${account_id}:db:${name_prefix}-*"
        }
      }
    }
  ]
}
