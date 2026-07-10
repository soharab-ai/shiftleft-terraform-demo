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
          "ec2:DescribeVolumes",
          "s3:GetObject",
          "s3:ListBucket",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = [
          "arn:aws:s3:::specific-bucket-name",
          "arn:aws:s3:::specific-bucket-name/*",
          "arn:aws:ec2:us-east-1:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:us-east-1:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:cloudwatch:*:${data.aws_caller_identity.current.account_id}:*"
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

