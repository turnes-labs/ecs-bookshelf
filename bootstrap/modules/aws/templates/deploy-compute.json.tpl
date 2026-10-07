{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ComputeRead",
      "Effect": "Allow",
      "Action": [
        "ecs:Describe*",
        "ecs:List*",
        "ecr:DescribeRepositories",
        "logs:DescribeLogGroups",
        "cloudwatch:DescribeAlarms",
        "application-autoscaling:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EcsClusterServiceTask",
      "Effect": "Allow",
      "Action": "ecs:*",
      "Resource": [
        "arn:aws:ecs:${region}:${account_id}:cluster/${name_prefix}",
        "arn:aws:ecs:${region}:${account_id}:service/${name_prefix}/*",
        "arn:aws:ecs:${region}:${account_id}:task/${name_prefix}/*"
      ]
    },
    {
      "Sid": "EcsTaskDefinitionRegister",
      "Effect": "Allow",
      "Action": "ecs:RegisterTaskDefinition",
      "Resource": [
        "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}:*",
        "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}-*:*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "EcsTaskDefinitionTagOnCreate",
      "Effect": "Allow",
      "Action": "ecs:TagResource",
      "Resource": [
        "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}:*",
        "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}-*:*"
      ],
      "Condition": {
        "StringEquals": {
          "ecs:CreateAction": "RegisterTaskDefinition",
          "aws:RequestTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "EcsTaskDefinitionUseOwn",
      "Effect": "Allow",
      "Action": [
        "ecs:RunTask",
        "ecs:StartTask",
        "ecs:DeleteTaskDefinitions",
        "ecs:TagResource",
        "ecs:UntagResource",
        "ecs:ListTagsForResource"
      ],
      "Resource": [
        "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}:*",
        "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}-*:*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "DenyTaskDefinitionDeregister",
      "Effect": "Deny",
      "Action": "ecs:DeregisterTaskDefinition",
      "Resource": "*"
    },
    {
      "Sid": "DenyRunTaskOutsideCluster",
      "Effect": "Deny",
      "Action": [
        "ecs:RunTask",
        "ecs:StartTask"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotEquals": {
          "ecs:cluster": "arn:aws:ecs:${region}:${account_id}:cluster/${name_prefix}"
        }
      }
    },
    {
      "Sid": "DenyServiceWithForeignTaskDefinition",
      "Effect": "Deny",
      "Action": [
        "ecs:CreateService",
        "ecs:UpdateService"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotLikeIfExists": {
          "ecs:task-definition": [
            "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}:*",
            "arn:aws:ecs:${region}:${account_id}:task-definition/${name_prefix}-*:*"
          ]
        }
      }
    },
    {
      "Sid": "DenyEcsEnvironmentRetag",
      "Effect": "Deny",
      "Action": [
        "ecs:TagResource",
        "ecs:UntagResource"
      ],
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "aws:TagKeys": "Environment"
        },
        "Null": {
          "ecs:CreateAction": "true"
        }
      }
    },
    {
      "Sid": "Ecr",
      "Effect": "Allow",
      "Action": "ecr:*",
      "Resource": "arn:aws:ecr:${region}:${account_id}:repository/${name_prefix}-*"
    },
    {
      "Sid": "EcrLogin",
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    },
    {
      "Sid": "Logs",
      "Effect": "Allow",
      "Action": "logs:*",
      "Resource": [
        "arn:aws:logs:${region}:${account_id}:log-group:/ecs/${name_prefix}",
        "arn:aws:logs:${region}:${account_id}:log-group:/ecs/${name_prefix}:*",
        "arn:aws:logs:${region}:${account_id}:log-group:/ecs/${name_prefix}/*"
      ]
    },
    {
      "Sid": "Alarms",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:ListTagsForResource",
        "cloudwatch:TagResource",
        "cloudwatch:UntagResource",
        "cloudwatch:PutDashboard",
        "cloudwatch:GetDashboard",
        "cloudwatch:DeleteDashboards"
      ],
      "Resource": [
        "arn:aws:cloudwatch:${region}:${account_id}:alarm:${name_prefix}-*",
        "arn:aws:cloudwatch::${account_id}:dashboard/${name_prefix}-*"
      ]
    },
    {
      "Sid": "AutoScalingCreateTagged",
      "Effect": "Allow",
      "Action": [
        "application-autoscaling:RegisterScalableTarget",
        "application-autoscaling:TagResource"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "AutoScalingManageOwn",
      "Effect": "Allow",
      "Action": "application-autoscaling:*",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "${environment}"
        }
      }
    }
  ]
}
