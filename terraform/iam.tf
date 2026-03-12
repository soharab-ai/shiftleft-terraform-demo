resource "aws_iam_user" "user" {
  name          = "${local.resource_prefix.value}-user"
  force_destroy = true

  tags = {
    Name        = "${local.resource_prefix.value}-user"
    Environment = local.resource_prefix.value
  }

}

resource "aws_iam_access_key" "user" {
  user = aws_iam_user.user.name
}

resource "aws_iam_user_policy" "userpolicy" {
  name = "restricted_policy"
  user = aws_iam_user.user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = [
          "arn:aws:s3:::specific-bucket-name",
          "arn:aws:s3:::specific-bucket-name/*",
          "arn:aws:ec2:*:*:volume/*",
          "arn:aws:ec2:*:*:security-group/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "sts:GetFederationToken",
          "sts:GetSessionToken",
          "sts:AssumeRole",
          "sts:AssumeRoleWithSAML",
          "ec2:GetPasswordData",
          "ec2:GetConsoleOutput",
          "ec2:DescribeInstances",
          "lambda:*",
          "iam:GetUser",
          "iam:GetUserPolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListAccessKeys",
          "iam:ListUserPolicies",
          "iam:ListAttachedUserPolicies",
          "iam:ListAttachedRolePolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetLoginProfile",
          "iam:SimulatePrincipalPolicy",
          "iam:CreateAccessKey",
          "iam:UpdateAccessKey",
          "iam:PassRole",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "kms:Decrypt",
          "rds:DownloadDBLogFilePortion",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::specific-bucket-name/*credentials*",
          "arn:aws:s3:::specific-bucket-name/*secrets*",
          "arn:aws:s3:::specific-bucket-name/*.pem",
          "arn:aws:s3:::specific-bucket-name/*.key",
          "arn:aws:s3:::specific-bucket-name/*password*"
        ]
      }
    ]
  })
}

EOF
}

output "username" {
  value = aws_iam_user.user.name
}

output "secret" {
  value = aws_iam_access_key.user.encrypted_secret
}

