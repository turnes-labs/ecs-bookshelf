{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NetworkRead",
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "elasticloadbalancing:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Ec2CreateTagged",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:CreateSubnet",
        "ec2:CreateInternetGateway",
        "ec2:AllocateAddress",
        "ec2:CreateNatGateway",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateVpcEndpoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Environment": "${environment}"
        },
        "Null": {
          "aws:ResourceTag/Environment": "true"
        }
      }
    },
    {
      "Sid": "Ec2ManageOwn",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSubnet",
        "ec2:CreateNatGateway",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:DeleteSubnet",
        "ec2:ModifySubnetAttribute",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:ReleaseAddress",
        "ec2:DisassociateAddress",
        "ec2:DeleteNatGateway",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:ReplaceRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:ModifySecurityGroupRules",
        "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
        "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
        "ec2:ModifyVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Environment": "${environment}"
        }
      }
    },
    {
      "Sid": "Ec2TagOnCreate",
      "Effect": "Allow",
      "Action": "ec2:CreateTags",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/Environment": "${environment}"
        },
        "Null": {
          "ec2:CreateAction": "false"
        }
      }
    },
    {
      "Sid": "DenyEnvironmentRetag",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ],
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "aws:TagKeys": "Environment"
        },
        "Null": {
          "ec2:CreateAction": "true"
        }
      }
    },
    {
      "Sid": "LoadBalancer",
      "Effect": "Allow",
      "Action": "elasticloadbalancing:*",
      "Resource": [
        "arn:aws:elasticloadbalancing:${region}:${account_id}:loadbalancer/app/${name_prefix}-*",
        "arn:aws:elasticloadbalancing:${region}:${account_id}:targetgroup/${name_prefix}-*",
        "arn:aws:elasticloadbalancing:${region}:${account_id}:listener/app/${name_prefix}-*",
        "arn:aws:elasticloadbalancing:${region}:${account_id}:listener-rule/app/${name_prefix}-*"
      ]
    }
  ]
}
