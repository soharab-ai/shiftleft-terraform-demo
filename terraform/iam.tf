data "aws_caller_identity" "current" {}

resource "aws_iam_user_policy" "userpolicy" {
  name = "least_privilege_policy"
  user = aws_iam_user.user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:ec2:*:*:instance/*"
        ]
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = ["us-east-1", "us-west-2"]
          }
        }
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::my-application-bucket",
          "arn:aws:s3:::my-application-bucket/*"
        ]
      },
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunction"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:lambda:*:*:function:my-application-*"
        ]
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:cloudwatch:us-east-1:${data.aws_caller_identity.current.account_id}:metric:MyApplication/Metrics/*",
          "arn:aws:cloudwatch:us-west-2:${data.aws_caller_identity.current.account_id}:metric:MyApplication/Metrics/*"
        ]
      }
    ]
  })
}
