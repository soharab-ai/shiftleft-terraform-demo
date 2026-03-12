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
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::specific-allowed-bucket",
          "arn:aws:s3:::specific-allowed-bucket/*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          IpAddress = {
            "aws:SourceIp" = ["203.0.113.0/24", "198.51.100.0/24"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/AccessLevel" = "authorized"
          }
          IpAddress = {
            "aws:SourceIp" = ["203.0.113.0/24", "198.51.100.0/24"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunction"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/AccessLevel" = "authorized"
          }
          IpAddress = {
            "aws:SourceIp" = ["203.0.113.0/24", "198.51.100.0/24"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = ["AWS/EC2", "AWS/Lambda"]
          }
          IpAddress = {
            "aws:SourceIp" = ["203.0.113.0/24", "198.51.100.0/24"]
          }
        }
      },
      {
        Effect = "Deny"
        Action = [
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutObjectAcl",
          "s3:PutBucketAcl",
          "s3:PutReplicationConfiguration",
          "s3:PutLifecycleConfiguration",
          "ec2:ModifySnapshotAttribute",
          "ec2:ModifyImageAttribute",
          "ec2:CreateInstanceExportTask",
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:AddPermission",
          "lambda:CreateEventSourceMapping",
          "rds:CopyDBSnapshot",
          "rds:ModifyDBSnapshotAttribute",
          "kms:CreateGrant",
          "kms:PutKeyPolicy",
          "iam:CreateAccessKey",
          "iam:CreateUser",
          "glacier:InitiateJob"
        ]
        Resource = "*"
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

