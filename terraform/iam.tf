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
  user = "${aws_iam_user.user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "s3:GetObject",
        "s3:ListBucket",
        "lambda:GetFunction",
        "lambda:ListFunctions",
        "cloudwatch:GetMetricData",
        "cloudwatch:DescribeAlarms"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::specific-bucket-name",
        "arn:aws:s3:::specific-bucket-name/*",
        "arn:aws:lambda:*:*:function:specific-function-name",
        "arn:aws:ec2:*:*:instance/*",
        "arn:aws:cloudwatch:us-east-1:*:alarm:specific-alarm-name"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "10.0.0.0/24"
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        },
        "NumericLessThan": {
          "s3:max-keys": "100"
        }
      }
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:PutObjectAcl",
        "s3:PutBucketPolicy",
        "lambda:UpdateFunctionCode",
        "ec2:CreateSnapshot",
        "ec2:CreateImage",
        "s3:ReplicateObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

EOF
}

output "username" {
  value = aws_iam_user.user.name
}

output "secret" {
  value = aws_iam_access_key.user.encrypted_secret
}

