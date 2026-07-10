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
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeImages",
          "s3:GetObject",
          "s3:ListBucket",
          "lambda:GetFunction",
          "lambda:ListFunctions",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = [
          "arn:aws:s3:::approved-bucket-*/*",
          "arn:aws:s3:::approved-bucket-*",
          "arn:aws:lambda:us-east-1:*:function:approved-function-*",
          "arn:aws:lambda:us-west-2:*:function:approved-function-*",
          "arn:aws:ec2:us-east-1:*:*",
          "arn:aws:ec2:us-west-2:*:*",
          "arn:aws:cloudwatch:us-east-1:*:*",
          "arn:aws:cloudwatch:us-west-2:*:*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "s3:PutBucketPolicy",
          "s3:PutObjectAcl",
          "s3:PutBucketAcl",
          "s3:DeleteBucketPolicy",
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:AddPermission",
          "ec2:ModifySnapshotAttribute",
          "ec2:ModifyImageAttribute",
          "ec2:CreateNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "s3:PutBucketReplication",
          "s3:ReplicateObject",
          "s3:PutBucketVersioning",
          "s3:PutBucketWebsite",
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots",
          "ec2:CopySnapshot",
          "ec2:CopyImage",
          "ec2:EnableImageDeprecation",
          "rds:CreateDBSnapshot",
          "rds:ModifyDBSnapshotAttribute"
        ]
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
        }
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

