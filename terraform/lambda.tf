resource "aws_iam_role" "iam_for_lambda" {
  name = "${local.resource_prefix.value}-analysis-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_signer_signing_profile" "lambda_signing_profile" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "${local.resource_prefix.value}-lambda-signing-profile-"

  signature_validity_period {
    value = 135
    type  = "MONTHS"
  }

  tags = {
    Name        = "${local.resource_prefix.value}-lambda-signing-profile"
    Environment = "production"
    Compliance  = "code-signing-required"
    Owner       = "security-team"
  }
}

resource "aws_signer_signing_profile" "lambda_signing_profile_backup" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "${local.resource_prefix.value}-lambda-signing-profile-backup-"

  signature_validity_period {
    value = 135
    type  = "MONTHS"
  }

  tags = {
    Name        = "${local.resource_prefix.value}-lambda-signing-profile-backup"
    Environment = "production"
    Compliance  = "code-signing-required"
    Owner       = "security-team"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lambda_code_signing_config" "lambda_code_signing" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.lambda_signing_profile.version_arn,
      aws_signer_signing_profile.lambda_signing_profile_backup.version_arn
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }

  description = "Code signing configuration for Lambda functions - Compliance: SOC2, PCI-DSS - Security Baseline: NIST 800-53"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.resource_prefix.value}-analysis"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn
}

resource "aws_lambda_function" "analysis_lambda" {
  filename      = "resources/lambda_function_payload.zip"
  function_name = "${local.resource_prefix.value}-analysis"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "exports.test"

  source_code_hash = "${filebase64sha256("resources/lambda_function_payload.zip")}"

  runtime       = "nodejs20.x"
  architectures = ["arm64"]

  reserved_concurrent_executions = 100

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_code_signing.arn

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      SECRETS_MANAGER_ARN = var.secrets_manager_arn
      PARAMETER_STORE_PATH = var.parameter_store_path
    }
  }

  depends_on = [
    aws_lambda_code_signing_config.lambda_code_signing,
    aws_cloudwatch_log_group.lambda_log_group
  ]

  lifecycle {
    prevent_destroy = true
  }
}
