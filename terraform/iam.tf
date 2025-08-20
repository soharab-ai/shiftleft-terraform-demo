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
  user = "${aws_iam_user.user.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*",
        "s3:Get*",
        "s3:List*",
        "lambda:Get*",
        "lambda:List*",
        "cloudwatch:Get*",
        "cloudwatch:Describe*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::allowed-bucket-1/*",
        "arn:aws:s3:::allowed-bucket-2/*",
        "arn:aws:ec2:*:*:instance/*",
        "arn:aws:lambda:*:*:function:allowed-function-*",
        "arn:aws:cloudwatch:*:*:alarm:critical-*",
        "arn:aws:logs:*:*:log-group:app-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": ["us-west-1", "us-east-1"]
        },
        "Bool": {
          "aws:SecureTransport": "true",
          "aws:MultiFactorAuthPresent": "true"
        },
        "IpAddress": {
          "aws:SourceIp": ["10.0.0.0/24", "192.168.1.0/24"]
        }
      }
    },
    {
      "Effect": "Deny",
      "Action": [
        "s3:PutObject*",
        "s3:GetObject*",
        "lambda:InvokeFunction",
        "ec2:CreateSnapshot*",
        "ec2:CopySnapshot*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": ["us-west-1", "us-east-1"]
        }
      }
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

