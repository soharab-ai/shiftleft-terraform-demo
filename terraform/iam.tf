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
  name = "least_privilege_policy"
  user = aws_iam_user.user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVolumes"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Environment" = "production"
            "ec2:ResourceTag/Project"     = "MyApplication"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::specific-bucket-name",
          "arn:aws:s3:::specific-bucket-name/*"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp" = ["10.0.0.0/8", "172.16.0.0/12"]
          }
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "2024-12-31T23:59:59Z"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction"
        ]
        Resource = [
          "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:specific-function-name"
        ]
        Condition = {
          IpAddress = {
            "aws:SourceIp" = ["10.0.0.0/8", "172.16.0.0/12"]
          }
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "2024-12-31T23:59:59Z"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "MyApplication"
          }
          StringLike = {
            "cloudwatch:dimension/FunctionName" = "specific-function-*"
          }
          IpAddress = {
            "aws:SourceIp" = ["10.0.0.0/8", "172.16.0.0/12"]
          }
        }
      }
    ]
  })
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


output "username" {
  value = aws_iam_user.user.name
}

output "secret" {
  value = aws_iam_access_key.user.encrypted_secret
}

